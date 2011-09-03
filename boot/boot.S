        .text
        .code16
        .global _start
        
_start:
        jmp     main

/*
 * DATA
 */
        .p2align        2       /* force 4-byte alignment */
gdt:
        .word   0, 0, 0, 0

        /* code segment */
        .word   0xFFFF, 0
        .byte   0, 0x9A, 0xCF, 0

        /* data segment */
        .word   0xFFFF, 0
        .byte   0, 0x92, 0xCF, 0
gdt_end:
        
/* this is the GDT descriptor */        
gdt_desc:              
        .word   gdt_end - gdt - 1       /* limit */
        .long   gdt                     /* addr */

        
main:
        cli
        movw    $0x07C0, %ax
        movw    %ax, %ds
        movw    %ax, %es
        movw    %ax, %ds

        movw    $0x0, %ax
        movw    %ax, %ss
        movw    $0xFFFF, %sp
        sti

        /* install GDT */
        lgdt    gdt_desc

        /* stop execution */
        cli
        hlt
        


.org    510
.word   0xAA55  /* boot sector signature */
