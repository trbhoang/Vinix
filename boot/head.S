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

_start:
        jmp     main


#include "print.S"              /* to include basic IO routines */


/*****************************************
* Data
*****************************************/        
loading_msg:
        .asciz	"\r\nPreparing to load operating system...\r\n"


/*****************************************
* Kernel Entry Point
* We're loaded at 0x10000 (0x1000:0x0)
*****************************************/        
main:
        /* setup segments and stack */
        cli                             # clear interrupts
        movw    $0x1000, %ax
        movw    %ax, %ds
        movw    %ax, %es
        movw    $0x9000, %ax            # stack segment will be located at 0x9000 -> 0xffff
        movw    %ax, %ss
        movw    $0xffff, %sp
        sti                             # enable interrupts

        /* print loading message */
        movw    $loading_msg, %si
        call    print

        /*
        # call    install_gdt             

#        cli                             # clear interrupts
#        movl    %cr0, %eax              # to set bit 0 of cr0 register
#        orl     $1, %eax
#        movl    %eax, %cr0
#
#        
#        ljmp    $0x08, $startup_32      # far jump to update CS
#                                        # remember that we're already in Protected Mode
                                        # so first operator of ljmp statement is offset (selector) of a certain descriptor in GDT 
        */

/*****************************************
* Stop execution   
*****************************************/        
        cli
        hlt
        
