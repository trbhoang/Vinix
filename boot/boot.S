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
        .long   0x00000000, 0x00000000
        .long   0x0000FFFF, 0x00CF9A00  /* code segment */
        .long   0x0000FFFF, 0x00CF9200  /* data segment */
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
