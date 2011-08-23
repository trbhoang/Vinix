/*
* @file    boot.S
* @brief   Boot loader 
* @author  Hoang Tran <trbhoang@gmail.com>
*/

	.file	"boot0.S"
	.text

	.code16
	.global	_start
_start:
        movw $str, %si
        call print_str

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
str:
        .asciz	"\r\nYou are in second stage!\r\n"

