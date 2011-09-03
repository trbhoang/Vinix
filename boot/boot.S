/*
 *  Bootloader
 *  (C) Hoang Tran <trbhoang@gmail.com>
 */

/*
 *  We are loaded at 0x7C00 linear address. This bootloader does:
 *  - enable A20 line
 *  - load kernel code at 0x10000
 *  - goto protected mode
 *  - load global descriptor table
 *  - update CS to point to code segment descriptor 
 *  - jump to the kernel
 */
        
        .file   "boot.S"
        .text
        .code16
        .global _start

        .equ    CODE_SEL, 0x08          	/* CS selector */
        .equ    DATA_SEL, 0x10          	/* DS selector */
        .equ    KERN_SEC, 0x1000        	/* segment where kernel will be placed */
        .equ    KERN_PM_OFFSET, 0x10000 	/* start address of kernel in protected mode */
        
_start:
        jmp     main

/*
 *  Global Descriptor Table 
 */        
        .p2align        2                       /* force 4-byte alignment */
gdt:
        .word   0, 0, 0, 0

        /* code segment */
        .word   0xFFFF, 0
        .byte   0, 0x9A, 0xCF, 0

        /* data segment */
        .word   0xFFFF, 0
        .byte   0, 0x92, 0xCF, 0
gdt_end:
        
gdt_desc:                                       /* GDT descriptor */
        .word   gdt_end - gdt - 1               /* limit */
        .long   gdt                             /* offset */

        
main:
        cli
        xorw    %ax, %ax
        movw    %ax, %ds
        movw    %ax, %es
        movw    %ax, %ds
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

        /* enter Protected Mode */
        movl    %cr0, %eax
        orw     $1, %ax
        movl    %eax, %cr0

        /* load GDT */
        lgdt    gdt_desc

        /*
         * Kernel is loaded at address that is out of 16-bit space (0x10000).
         * So we can only jump to the kernel by 32-bit code. 
         * And before going into 32-bit code, we must update CS properly (make it point to CS selector).
         */
        ljmp    $CODE_SEL, $startup_32

        .code32
startup_32:     
        ljmp    $CODE_SEL, $KERN_PM_OFFSET
        

.org    510
.word   0xAA55          /* boot sector signature */
