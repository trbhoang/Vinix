/*
 *  (C) Hoang Tran <trbhoang@gmail.com>
 */

/*
 *  We're now at kernel!
 */
        
	.file	"head.S"
	.text
	.code32
	.global	_start

_start:
        jmp     main

main:
        cli 
        hlt
        
