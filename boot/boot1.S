/*
* @file    boot.S
* @brief   Boot loader 
* @author  Hoang Tran <trbhoang@gmail.com>
*/

	.file	"boot1.S"
	.text

	.code16			# Emit 16-bit code for Real Mode.
	.global	_start
_start:
        jmp     loader


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
** Bootloader Entry Point 
*****************************************/        
loader:
        xorw    %ax, %ax
        movw    %ax, %ds
        movw    %ax, %es

        movw    $msg, %si       # print message 
        call    print
        
        xorw    %ax, %ax        # clear ax
        int     $0x12            # get the ammount of KB from BIOS

        cli                     # clear all interrupts
        hlt                     # halt the system


/*****************************************
** Data
*****************************************/        
msg:
        .asciz	"\r\nWelcome to boot loader!\r\nFirst sector seems ok...\r\n"

        
.org 510
.word 0xaa55    # boot signature

