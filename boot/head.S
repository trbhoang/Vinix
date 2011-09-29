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
	.global	idt, gdt, pg_dir, startup_32

pg_dir:
startup_32:
        movl    $0x10, %eax
        movw    %ax, %ds
        movw    %ax, %es
        movw    %ax, %fs
        movw    %ax, %gs
        lss     stack_start, %esp
        call    setup_idt
        call    setup_gdt
        
        /*
         * Reload all the segment registers after changing GDT. CS was
         * already reloaded in 'setup_gdt'. 
         */
        movl    $0x10, %eax             
        movw    %ax, %ds
        movw    %ax, %es
        movw    %ax, %fs
        movw    %ax, %gs
        lss     stack_start, %esp
        xorl    %eax, %eax
1:      incl    %eax            /* check that A20 is really enabled */
        movl    %eax, 0x000000
        cmpl    %eax, 0x100000
        je      1b
        movl    %cr0, %eax              /* check math chip */
        andl    $0x80000011, %eax       /* save PG, ET, PE */
        testl   $0x10, %eax
        jne     1f                      /* ET is set - 387 is present */
        orl     $4, %eax                /* else set emulate bit */
1:      movl    %eax, %cr0
        jmp     after_page_tables
        

/*
 *  setup_idt
 *        
 *  sets up an IDT with 256 entries pointing to ignore_idt, interrupt gates.
 *  It then loads IDT. Everything that wants to install itself in the idt-table
 *  may do so themselves. Interrupts are enabled elsewhere, when we can be relatively
 *  sure everything is ok. This routine will be over written by the page tables.
 */
setup_idt:
        lea     ignore_int, %edx        /* load effective address (absolute address where ignore_int located at runtime) to EDX */
        movl    $0x00080000, %eax       /* selector = 0x0008 which is CS descriptor */
        movw    %dx, %ax
        movw    $0x8E00, %dx
        lea     idt, %edi
        movl    $256, %ecx
rp_sidt:
        movl    %eax, (%edi)            /* move value in EAX to memory at location (EDI). Note the form: base_addr(offset, index, size) */
        movl    %edx, 4(%edi)           /* move value at EDX to memory at location (4 + EDI) */
        addl    $8, %edi
        dec     %ecx
        jne     rp_sidt
        lidt    idt_desc
        ret


/*
 *  setup_gdt
 *  This routines sets up a new GDT and loads it.
 *  Only two entries are currently built, the same
 *  ones that were built in init.s. The routine is
 *  VERY complicated at two whole lines, so this
 *  rather long comment is certainly needed :-).
 *  This routine will be overwritten by the page tables. 
 */
setup_gdt:
        lgdt    gdt_desc
        ret


.org    0x1000
pg0:

.org    0x2000
pg1:

.org    0x3000
pg2:            /* This is not used yet, but if you want to expand past 8M, you'll have to use it. */

.org    0x4000
after_page_tables:
        pushl   $0      /* These are the parameters to main :-) */
        pushl   $0
        pushl   $0
        pushl   $L6     /* return address for main, if it decides to */
        pushl   $main
        jmp     setup_paging
L6:
        jmp     L6      /* main should never return here, but just in case, we know what happens. */

        
        
/* This is the default interrupt "handler" :-) */
.align  2
ignore_int:
        /* put something on the screen so that we know something happened */
        incb    0xb8000+160             /* 0xb8000 is start of video memory */
        movb    $2, 0xb8000+161
        iret


/*
 *  setup_paging
 *  This routine sets up paging by setting the page bit in cr0.
 *  The page tables are set up, identity-mapping the first 8MB.
 *  The pager assumes that no illegal addresses are produced
 *  (ie > 4MB on a 4MB machine).
 *
 *  NOTE! Although all physical memory should be identity mapped
 *  by this routine, only the kernel page functions use the >1MB address
 *  directly. All 'normal' functions use just the lower 1MB, or the local
 *  data space, which will be mapped to some other place - mm keeps track of that.
 *
 *  For those with more memory than 8MB - tough luck. The source is here.
 *  Change it. (Seriously, it shouldn't be too difficult. Mostly change some constants etc.)
 */
.align  2
setup_paging:
        movl    $1024 * 3, %ecx
        xorl    %eax, %eax
        xorl    %edi, %edi              /* pg_dir is at 0x000 */
        cld
        rep
        stosl   /* load EAX to ES:DI (stos - Store String Data) --> fill the page directory, pg0 and pg1 with zeroes!!! */
        /*
         * fill the first two entries of the page directory with pointers to pg0 and pg1
         * and the necessary bits for paging (which can be found in the manuals)
         */
        movl    $pg0 + 7, pg_dir       /* set present bit/user r/w */
        movl    $pg1 + 7, pg_dir + 4
        movl    $pg1 + 4092, %edi
        movl    $0x7ff007, %eax         /* 8Mb - 4096 + 7 (r/w user, p) */
        std
1:      stosl                           /* fill pages backwards - more efficient :-) */
        subl    $0x1000, %eax
        jge     1b                      /* 1b: label 1 backward */
        xorl    %eax, %eax              /* pg_dir is at 0x0000 */
        movl    %eax, %cr3              /* cr3 - page directory start */
        movl    %cr0, %eax
        orl     $0x80000000, %eax
        movl    %eax, %cr0              /* set paging (PG) bit */
        ret                             /* this also flushes prefetch-queue */
        
        
.align  2
.word   0
idt_desc:
        .word   256 * 8 - 1             /* IDT contains 256 entries */
        .long   idt
        
.align  2
.word   0
gdt_desc:
        .word   256 * 8 - 1
        .long   gdt

.p2align  3        
idt:
        .fill   256, 8, 0               /* IDT is uninitialized */
        
gdt:
        .quad   0x0000000000000000      /* NULL descriptor */
        .quad   0x00c09a00000007ff      /* 8Mb */
        .quad   0x00c09200000007ff      /* 8Mb */
        .quad   0x0000000000000000      /* TEMPORARY - don't use */
        .fill   252, 8, 0               /* space for LDT's and TSS's etc */
