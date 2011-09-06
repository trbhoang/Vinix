/*
 *  Bootloader
 *  (C) Hoang Tran <trbhoang@gmail.com>
 */

/*
 *  We are loaded at 0x7C00 linear address. This bootloader does:
 *  - move itself to 0x90000 (to prevent overwritten by kernel code later)
 *  - enable A20 line
 *  - copy kernel code from floppy to memory location starting at 0x10000
 *  - move kernel downto memory location 0x0
 *  - goto protected mode
 *  - load global descriptor table
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

        /* enable A20 line: use BIOS routine (may try other methods as well) */
        movw    $0x2401, %ax
        int     $0x15
        
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

        
        /* load GDT */
        movw    %cs, %ax
        movw    %ax, %ds        /* dont foget to set DS properly :-) */
        lgdt    gdt_desc        /* lgdt ds:offset */

        /* enter Protected Mode */
        movl    %cr0, %eax
        orw     $1, %ax
        movl    %eax, %cr0

        /*
         * We're now in Protected Mode and kernel is at 0x0. So just jump there.
         */
        ljmp    $CODE_SEL, $0x0

        

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
        
gdt_desc:                                       /* GDT descriptor */
        .word   gdt_end - gdt - 1               /* limit */
        .word   gdt, 0x9                        /* gdt base = 0x9XXXX */

        
.org    510
.word   0xAA55          /* boot sector signature */
