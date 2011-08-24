/*
* @file    boot2.S
* @brief   second-stage bootloader
* @author  Hoang Tran <trbhoang@gmail.com>
*/

	.file	"boot2.S"
	.text

	.code16                 # we are still in Real Mode
	.global	_start

        
                                # we are loaded at physical address 0x10000 by first-stage bootloader
_start:
        jmp     main

        
/*****************************************
* Print a string
* DS:SI -> null terminated string 
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
