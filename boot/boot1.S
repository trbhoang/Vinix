/*
* @file    boot.S
* @brief   Boot loader 
* @author  Hoang Tran <trbhoang@gmail.com>
*/

	.file	"boot.S"
	.text

	.code16			# Emit 16-bit code for Real Mode.
	.global	_start
_start:
	# Print the welcome string
        movw    $welcome_str, %si
        call    print_str

/* fall into the infinite loop */        
	cli
halt:	hlt
	jmp halt

/* Print string from DS:SI until NULL character is met */
print_str:
	pusha			# Saves registers.
        movb    $0xE, %ah
        xorb    %bh, %bh
        movb    $0x7, %bl
next_char:
        lodsb
        orb     %al, %al
        jz      return_print_str
        int     $0x10
        jmp     next_char
return_print_str:
        popa 
        ret

/* data */        
welcome_str:
        .asciz	"\r\nWelcome to boot loader!\r\nFirst sector seems ok.\r\n"

        
/* flag the last two bytes of boot sector */        
        .org 510
boot_flag: .word 0xaa55

