/*
 *  (C) Hoang Tran <trbhoang@gmail.com>
 *  Modified from Linux kernel 0.01
 */

/*
 *  head.S contains 32-bit startup code
 *  Startup happens at absolute address 0x00000000, it's also where
 *  the page directory will exist. The startup code will be over written
 *  by the page directory. 
 */        
        
	.file	"head.S"
	.text
	.global	_idt, _gdt, _pg_dir

_pg_dir:
startup_32:
        movl    $0x10, %eax
        movw    %ax, %ds
        movw    %ax, %es
        movw    %ax, %fs
        movw    %ax, %gs
#        lss     stack_start, %esp
#        call    setup_idt
#        # call    setup_gdt
        
        /*
         * Reload all the segment registers after changing GDT. CS was
         * already reloaded in 'setup_gdt'. 
         */
#        movl    $0x10, %eax             
#        movw    %ax, %ds
#        movw    %ax, %es
#        movw    %ax, %fs
#        movw    %ax, %gs
#        lss     stack_start, %esp
#        xorl    %eax, %eax
#        

/*
 *  setup_idt
 *        
 *  sets up an IDT with 256 entries pointing to ignore_idt, interrupt gates.
 *  It then loads IDT. Everything that wants to install itself in the idt-table
 *  may do so themselves. Interrupts are enabled elsewhere, when we can be relatively
 *  sure everything is ok. This routine will be over written by the page tables.
 */
#setup_idt:
#        lea     ignore_int, %edx        /* load effective address (absolute address where ignore_int located at runtime) to EDX */
#        movl    $0x00080000, %eax       /* selector = 0x0008 which is CS descriptor */
#        movw    %dx, %ax
#        movw    $0x8E00, %dx
#        lea     _idt, %edi
#        movl    $256, %ecx
#rp_sidt:
#        movl    %eax, (%edi)            /* move value in EAX to memory at location (EDI). Note the form: base_addr(offset, index, size) */
#        movl    %edx, 4(%edi)           /* move value at EDX to memory at location (4 + EDI) */
#        addl    $8, %edi
#        dec     %ecx
#        jne     rp_sidt
#        lidt    idt_desc
#        ret
#
#/* This is the default interrupt "handler" :-) */
#.align  2
#ignore_int:
#        /* put something on the screen so that we know something happened */
#        incb    0xb8000+160             /* 0xb8000 is start of video memory */
#        movb    $2, 0xb8000+161
#        iret    
#        
#.align  2
#.word   0
#idt_desc:
#        .word   256 * 8 - 1             /* IDT contains 256 entries */
#        .long   _idt
#        
#_idt:
#        .fill   256, 8, 0               /* IDT is uninitialized */
#        
