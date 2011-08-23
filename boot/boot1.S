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
* Bootloader Entry Point 
*****************************************/        
loader:
        xorw    %ax, %ax
        movw    %ax, %ds
        movw    %ax, %es

        movw    $welcome_msg, %si       # print message 
        call    print
        
        movw    $stage2_msg, %si        # start loading stage 2
        call    print
        
reset_fd:
        movb    $0, %ah         # reset floppy disk function
        movb    $0, %dl         # drive 0 is floppy drive
        int     $0x13
        jc      reset_fd        # try again if carry flag (CF) is set (there was an error)

        movw    $0x1000, %ax    # we are going to read sector into address 0x1000:0
        movw    %ax, %es
        xorw    %bx, %bx

read_fd:    
        movb    $0x02, %ah      # read floppy sector function
        movb    $1, %al         # read one sector
        movb    $0, %ch         # we are reading the second sector past us, so it's still on track 1 (cylinder 1)
        movb    $2, %cl         # sector to read (the second sector)
        movb    $0, %dh         # head number
        movb    $0, %dl         # drive number (0 is floppy drive)
        int     $0x13
        jc      read_fd

        movw    $complete_stage2_msg, %si
        call    print
        ljmp    $0x1000, $0     # jump to loaded code
        

/*****************************************
* Data
*****************************************/        
welcome_msg:
        .asciz	"\r\nWelcome to My Operating System!\r\n"
stage2_msg:
        .asciz  "Loading stage 2...\r\n"
complete_stage2_msg:
        .asciz  "Complete loading stage 2. Start executing second stage...\r\n"
        
.org 510
.word 0xaa55    # boot signature

