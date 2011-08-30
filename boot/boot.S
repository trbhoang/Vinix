/*
* @file    boot1.S
* @brief   first-stage bootloader 
* @author  Hoang Tran <trbhoang@gmail.com>
*/

#include "boot.h"

	.file	"boot.S"
	.text

	.code16			# we are in Real Mode.
	.global	_start
        

_start:                         # we are loaded at physical address 0x7c00 by BIOS
        jmp     main

        
#include "print.S"              /* to include IO functions */

        
/*****************************************
* Bootloader Entry Point 
*****************************************/        
main:
        /* code located at 0000:7c00 */
        cli                             # disable interrupts
        movw    $0x07c0, %ax            # setup registers to point to 0x7c00
        movw    %ax, %ds
        movw    %ax, %es
        movw    %ax, %fs
        movw    %ax, %gs

        /* setup stack */
        movw    $0x0, %ax
        movw    %ax, %ss
        movw    $0xffff, %sp
        sti                             # enable interrupts 

        /* print a welcome message */
        movw    $welcome_msg, %si  
        call    print

        /* print loading message */
        movw    $start_loading_msg, %si   
        call    print

        /* load kernel from second record of floppy disk */
reset_fd:
        movb    $0, %ah         	# reset floppy disk function
        movb    $0, %dl         	# drive number: 0 is floppy drive
        int     $0x13           	# BIOS 13h function
        jc      reset_fd        	# try again if carry flag (CF) is set (there was an error)

        movw    $KERN_SEC, %ax          # we are going to read second sector into address ES:BX
        movw    %ax, %es        	# ES = KERN_SEC
        xorw    %bx, %bx        	# clear BX
read_fd:    
        movb    $0x02, %ah      # read floppy sector function
        movb    $1, %al         # read one sector
        movb    $0, %ch         # we are reading the second sector past us, so it's still on track 1 (cylinder 1, note: tracks are numbered from 0)
        movb    $2, %cl         # sector to read (the second sector, note: sectors are numbered from 1)
        movb    $0, %dh         # head number (floppy disk has only one 'plane', so two 'faces' or 'heads': head 0, head 1), the second sector is on head 0
        movb    $0, %dl         # drive number (0 is floppy drive)
        int     $0x13           # BIOS 13h function
        jc      read_fd         # try again if error 

        movw    $complete_loading_msg, %si      # print a message that says stage 2 has been loaded 
        call    print
        ljmp    $KERN_SEC, $0                   # jump to loaded code
        

/*****************************************
* Data
*****************************************/        
welcome_msg:
        .asciz	"\r\n===== Welcome to Vinix Operating System! =====\r\n"
start_loading_msg:
        .asciz  "\r\nLoading kernel...\r\n"
complete_loading_msg:
        .asciz  "\r\nStart executing the kernel...\r\n"

        
.org 510
.word 0xaa55    # boot sector signature
