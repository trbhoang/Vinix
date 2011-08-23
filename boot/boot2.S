/*
* @file    boot.S
* @brief   second-stage bootloader
* @author  Hoang Tran <trbhoang@gmail.com>
*/

	.file	"boot2.S"
	.text

	.code16                 # we are still in real mode
	.global	_start

        
# we are loaded at linear address 0x10000
_start:
        jmp     main

        
/*****************************************
*  Print a string
*  DS:SI -> null terminated string 
*****************************************/
print:
        lodsb                   # load next byte from string to AL
        orb     %al, %al        # does AL = 0?
        jz      end_of_str      # yes, reach the end of the string
        movb    $0xE, %ah       # no, print the character
        int     $0x10
        jmp     print           # repeat until reach null character 
end_of_str:
        ret                     # we are done, so return 
        

/*****************************************
* Second Stage Bootloader Entry Point 
*****************************************/        
main:
        cli                     # clear interrupts
        push    %cs             # to insure DS=CS
        pop     %ds
        movw    $msg, %si       # print message
        call    print

        cli
        hlt
        
/*****************************************
* Data
*****************************************/        
msg:
        .asciz	"\r\nYou are in second stage!\r\n"

