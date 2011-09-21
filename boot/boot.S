/*
 *  Bootloader
 *  (C) Hoang Tran <trbhoang@gmail.com>
 *  Some code borrowed from Linux kernel 0.01
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

        BOOT_SEG       = 0x07C0
        INIT_SEG       = 0X9000
        KERN_SEG       = 0x1000         /* segment where kernel will be placed */
        KERN_SIZE      = 0x8000
        KERN_END_SEG   = KERN_SEG + KERN_SIZE
        
        sectors        = 18

        CODE_SEL       = 0x08          	/* CS selector */
        DATA_SEL       = 0x10          	/* DS selector */
        KERN_PM_OFFSET = 0x10000 	/* start address of kernel in protected mode */

_start:
        /* move the bootloader itself to 0x90000: copy 512 bytes (256 words) from 0x7C00 to 0x90000 */
        movw    $BOOT_SEG, %ax
        movw    %ax, %ds
        movw    $INIT_SEG, %ax
        movw    %ax, %es
        movw    $256, %cx
        xorw    %di, %di
        xorw    %si, %si
        rep
        movsw
        ljmp    $INIT_SEG, $main         /* jump to next instruction at new location */

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

        movw    $KERN_SEG, %ax          /* we are going to read sectors which contains kernel image at ES:BX */
        movw    %ax, %es        	/* ES = KERN_SEG */
        xorw    %bx, %bx        	/* clear BX */
read_fd:
        movb    $0x02, %ah      /* read floppy sector function */
        movb    $0xff, %al       /* read 255 sectors (need update to read 512K later) */
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
 *  Routines
 */

/*
 *  This routine checks if the keyboard command queue is empty.
 *  If not, we probably couldn't proceed anyway.
 */
empty_8042:
        .word   0x00eb, 0x00eb
        inb     $0x64, %al              /* read value from port 0x64 to AL */
        testb   $2, %al                 /* AL & 2 (is input buffer full?) */
        jnz     empty_8042              /* Zero flag is on (yes) */
        ret

/*
 *  This routine loads the system at address 0x10000, making sure no 64K boundaries
 *  are crossed. We try to load it as fast as possible, loading whole tracks whenever we can.
 *  in: ES - starting address segment (normally 0x1000)
 *  
 *  This routine has to be recompiled to fit another drive type,
 *  just change the "sectors" variable at the start of the file
 *  (originally 18, for a 1.44M drive)
 *  
 *  Floppy disk structure:
 *    - 2 heads or faces: front side and back side (0, 1)
 *    - 64 tracks
 *    - 18 sectors per track, each sector is 512-byte length
 */
sread:  .word 1         /* sectors read of current track */
head:   .word 0         /* current head */
track:  .word 0         /* current track */
read_it:
        movw    %es, %ax
        test    $0x0fff, %ax    /* AX & 0x0fff */
die:    jne     die             /* jump if not equal (ZF = 0) --> ES = 0xX000 (ES must be at 64K boundary) */
        xorw    %bx, %bx        /* BX is starting address within segment */
rp_read:
        movw    %es, %ax
        cmp     $KERN_END_SEG, %ax
        jb      ok1_read        /* jump if below */
        ret
ok1_read:       
        movw    $sectors, %ax
        subw    sread, %ax      /* AX now contains remaining unread sectors  */
        movw    %ax, %cx        /* CX = AX */        
        shl     $9, %cx         /* CX = CX * 512 */
        addw    %bx, %cx        /* CX = CX + BX */
        jnc     ok2_read        /* jump if not carry */
        je      ok2_read        /* jump if equal */
        xorw    %ax, %ax
        subw    %bx, %ax
        shr     $9, %ax         /* AX = AX / 512 */
ok2_read:
        call    read_track
        movw    %ax, %cx
        addw    sread, %ax
        cmp     $sectors, %ax
        jne     ok3_read
        movw    $1, %ax
        subw    head, %ax
        jne     ok4_read
        incw    track
ok4_read:
        movw    %ax, head
        xorw    %ax, %ax
ok3_read:
        movw    %ax, sread      /* update num of read sectors */
        shl     $9, %cx
        addw    %cx, %bx
        jnc     rp_read
        movw    %es, %ax
        addw    $0x1000, %ax
        movw    %ax, %es
        xorw    %bx, %bx
        jmp     rp_read

read_track:
        push    %ax
        push    %bx
        push    %cx
        push    %dx
        movw    track, %dx
        movw    sread, %cx      /* CL contains 'sector' number */
        incw    %cx
        movb    %dl, %ch        /* CH contains 'track' number */        
        movw    head, %dx       
        movb    %dl, %dh        /* DH contains 'head' number */
        movb    $0, %dl         /* drive number (floppy: 0) */
        and     $0x0100, %dx    /* bit-masking DX */
        movb    $2, %ah         /* INT 13h AH=02h: read sectors from drive */
        int     $0x13
        jc      bad_rt  
        pop     %dx
        pop     %cx
        pop     %bx
        pop     %ax
        ret
bad_rt:
        movw    $0, %ax
        movw    $0, %dx
        int     $0x13
        pop     %dx
        pop     %cx
        pop     %bx
        pop     %ax
        jmp     read_track

/*
 * This routine turns off the floppy drive motor,
 * so that we enter the kernel in a known state, and
 * don't have to worry about it later. 
 */
/* kill_motor:
        push    %dx
        movw    $0x3f2, %dx
        movb    $0, %al
        outb
        pop     dx
        ret
*/        
        
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
