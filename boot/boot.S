/*
 *  Bootloader
 *  (C) Hoang Tran <trbhoang@gmail.com>
 */

/*
 *  We are loaded at 0x7C00 linear address. This bootloader does:
 *  - move itself to 0x90000 (to prevent overwritten by kernel code later)
 *  - copy kernel code from floppy to memory location starting at 0x10000
 *  - move kernel downto memory location 0x0
 *  - load Interrupt Descriptor Table & Global Descriptor Table
 *  - enable A20 line
 *  - reprogram interrupt controller         
 *  - goto protected mode
 *  - update CS to point to code segment descriptor 
 *  - jump to the kernel
 */
        
        .file   "boot.S"
        .text
        .code16
        .global _start

        BOOTSEG        = 0x07C0
        INITSEG        = 0X9000
        KERNSEG        = 0x1000
        KERNSIZE       = 0x8000
        
        CODE_SEL       = 0x08          	/* CS selector */
        DATA_SEL       = 0x10          	/* DS selector */
        KERN_SEC       = 0x1000        	/* segment where kernel will be placed */
        KERN_PM_OFFSET = 0x10000 	/* start address of kernel in protected mode */
        
_start:
        /* move the bootloader itself to 0x90000: copy 512 bytes (256 words) from 0x7C00 to 0x90000 */
        movw    $BOOTSEG, %ax
        movw    %ax, %ds
        movw    $INITSEG, %ax
        movw    %ax, %es
        movw    $256, %cx
        xorw    %di, %di
        xorw    %si, %si
        rep
        movsw
        ljmp    $INITSEG, $main         /* jump to next instruction at new location */
        
main:
        cli
        movw    %cs, %ax
        movw    %ax, %ds
        movw    %ax, %es
        movw    %ax, %ss
        movw    $0xFFFF, %sp
        sti

        
        /* load kernel code */
reset_fd:
        movb    $0, %ah         	/* reset floppy disk function */
        movb    $0, %dl         	/* drive number: 0 is floppy drive */
        int     $0x13           	/* BIOS 13h function */
        jc      reset_fd        	/* try again if carry flag (CF) is set (there was an error) */

        movw    $KERN_SEC, %ax          /* we are going to read sectors which contains kernel image at ES:BX */
        movw    %ax, %es        	/* ES = KERN_SEC */
        xorw    %bx, %bx        	/* clear BX */
read_fd:    
        movb    $0x02, %ah      /* read floppy sector function */
        movb    $1, %al         /* read one sector */
        movb    $0, %ch         /* we are reading the sectors past us, so it's still on track 1 (cylinder 1, note: tracks are numbered from 0) */
        movb    $2, %cl         /* start reading from the second sector (note: sectors are numbered from 1) */
        movb    $0, %dh         /* head number (floppy disk has only one 'plane', so two 'faces' or 'heads': head 0, head 1), the second sector is on head 0 */
        movb    $0, %dl         /* drive number (0 is floppy drive) */
        int     $0x13           /* BIOS 13h function */
        jc      read_fd         /* try again if error */

        
        /* now move kernel down to location 0x0 */
        cli
        xorw    %ax, %ax        /* AX = 0x0 */
        movw    %ax, %es        /* ES: destination segment */
        movw    $0x1000, %ax    /* kernel is being at location 0x10000 */
        movw    %ax, %ds        /* DS: source segment */
        cld                     /* direction = 0 (move forward) */
        xorw    %di, %di        /* DI = 0 */
        xorw    %si, %si        /* SI = 0 */
        movw    $0x8000, %cx    /* assume kernel has known size: 0x8000 * 4 bytes (512K) */
        rep
        movsl

        
        /* load IDT & GDT */
        movw    %cs, %ax
        movw    %ax, %ds        /* dont foget to set DS properly :-) */
        lidt    idt_desc
        lgdt    gdt_desc        /* lgdt ds:offset */

        
        /* enable A20 line by programming keyboard controller */
        call    empty_8042
        movb    $0xD1, %al      
        outb    %al, $0x64       /* write to port 0x64 */
        call    empty_8042
        movb    $0xDF, %al
        outb    %al, $0x60
        call    empty_8042


        /*
         * On 32-bit x86, the first 32 interrupts are reserved by Intel for special uses.
         * So before entering protected mode, we need to reprogram 8259 interrupt controller
         * to map its interrupt lines to proper interrupt entries (from entry 0x20th) in Interrupt Vector Table (Interrupt Descriptor Table).
         */
        movb    $0x11, %al              /* initialization sequence */
        outb    %al, $0x20              /* send it to 8259A-1 */
        .word   0x00eb, 0x00eb          /* jmp $+2, jmp $+2 */
        outb    %al, $0xa0              /* and to 8259A-2 */
        .word   0x00eb, 0x00eb
        movb    $0x20, %al              /* start of hardware interrupt 0 (0x20) */
        outb    %al, $0x21
        .word   0x00eb, 0x00eb
        movb    $0x28, %al              /* start of hardware interrupt 8 (0x28) */
        outb    %al, $0xa1
        .word   0x00eb, 0x00eb
        movb    $0x04, %al              /* 8259-1 is master */
        outb    %al, $0x21
        .word   0x00eb, 0x00eb
        movb    $0x02, %al              /* 8259-2 is slave */
        outb    %al, $0xa1
        .word   0x00eb, 0x00eb
        movb    $0x01, %al              /* 8086 mode for both */
        outb    %al, $0x21
        .word   0x00eb, 0x00eb
        outb    %al, $0xa1
        .word   0x00eb, 0x00eb
        movb    $0xff, %al              /* mask off all interrupts for now */
        outb    %al, $0x21
        .word   0x00eb, 0x00eb
        outb    %al, $0xa1

        
        /* enter Protected Mode */
        movl    %cr0, %eax
        orw     $1, %ax
        movl    %eax, %cr0

        
        /*
         * We're now in Protected Mode and kernel is at 0x0. So just jump there.
         */
        ljmp    $CODE_SEL, $0x0

        
/*
 * Routines 
 */

/*
 * This routine checks if the keyboard command queue is empty.
 * If not, we probably couldn't proceed anyway.
 */        
empty_8042:
        .word   0x00eb, 0x00eb
        inb     $0x64, %al              /* read value from port 0x64 to AL */
        testb   $2, %al                 /* AL & 2 (is input buffer full?) */
        jnz     empty_8042              /* Zero flag is on (yes) */
        ret
        
        
/*
 *  Global Descriptor Table 
 */        
        .p2align        2                       /* force 4-byte alignment */
gdt:
        /* null descriptor */
        .word   0, 0, 0, 0      

        /* code segment */
        .word   0xFFFF                          /* limit = FFFF (2^16 mem unit = 2^16 * 4K = 4G) */
        .word   0x0000                          /* base address = 0 */
        .word   0x9A00                          /* code, read, exec */
        .word   0x00CF                          /* granularity = 4096 (mem unit size = 4K) */

        /* data segment */
        .word   0xFFFF                          /* limit = FFFF (2^16 mem unit = 2^16 * 4K = 4G) */
        .word   0x0000                          /* base address = 0 */
        .word   0x9200                          /* data, read, write */
        .word   0x00CF                          /* granularity = 4096 (mem unit size = 4K) */
gdt_end:

idt_desc:
        .word   0                               /* IDT limit = 0 */
        .word   0, 0                            /* IDT base = 0 */
        
gdt_desc:                                       /* GDT descriptor */
        .word   gdt_end - gdt - 1               /* limit */
        .word   gdt, 0x9                        /* gdt base = 0x9XXXX */

        
.org    510
.word   0xAA55          /* boot sector signature */
