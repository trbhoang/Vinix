/*
* @file    boot2.S
* @brief   second-stage bootloader
*          - enable and go into protected mode
*          - retrieve BIOS information
*          - load and execute the kernel
*          - enable the A20 address line for access upto 4G memory
*          - provide basic interrupt handling 
* @author  Hoang Tran <trbhoang@gmail.com>
*/

	.file	"boot2.S"
	.text

	.code16                 # we are still in Real Mode
	.global	_start

        
                                # we are loaded at physical address 0x10000 by first-stage bootloader
_start:
        jmp     main


#include "print.S"              /* to include basic IO routines */
#include "gdt.S"                /* GDT routines */


/*****************************************
* Data
*****************************************/        
loading_msg:
        .asciz	"\r\nPreparing to load operating system...\r\n"


/*****************************************
* Second Stage Bootloader Entry Point 
*****************************************/        
main:
        /* setup segments and stack */
        cli                             # clear interrupts
        movw    $0x9000, %ax
        movw    %ax, %ss
        movw    $0xffff, %sp
        push    %cs
        pop     %ax
        movw    %ax, %ds
        movw    %ax, %es
        sti                             # enable interrupts

        movw    $loading_msg, %si       # to print loading message
        call    print

        /* install GDT */
        call    install_gdt             

        /* go into Protected Mode */
        cli                             # clear interrupts
        movl    %cr0, %eax              # to set bit 0 of cr0 register
        orl     $1, %eax
        movl    %eax, %cr0

        
        ljmp    $0x08, $stage3          # far jump to update CS
                                        # remember that we're already in Protected Mode
                                        # so first operator of ljmp statement is offset (selector) of a certain descriptor in GDT 
        

/*****************************************
* Entry Point for Stage 3  
*****************************************/        
.code32                                 # welcome to the 32-bit world!
stage3:
        movw    $0x10, %ax              # set data segments to data selector (0x10)
        movw    %ax, %ds
        movw    %ax, %ss
        movw    %ax, %es
        movl    $0x90000, %esp          # stack begins from 0x90000
        

/*****************************************
* Stop execution   
*****************************************/        
        cli
        hlt
        
