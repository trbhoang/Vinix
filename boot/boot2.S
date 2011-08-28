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


#include "print.S"              /* to include IO functions */


/*****************************************
* Second Stage Bootloader Entry Point 
*****************************************/        
main:
        cli                     # clear interrupts
        push    %cs             # this stage of bootloader is loaded at a certain place (pointed to by CS) by first-stage,
        pop     %ds             # and originated at offset 0x0 by linker but code and data are on the same segment,
                                # so DS must equal to CS so that they reference correct physical addr
        movw    $msg, %si       # print a message that says we're at the second stage 
        call    print

        cli
        hlt

        
/*****************************************
* Data
*****************************************/        
msg:
        .asciz	"\r\nYou are in the second stage!\r\n"
