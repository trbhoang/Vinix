/*
* @file    boot2.S
* @brief   second-stage bootloader 
* @author  Hoang Tran <trbhoang@gmail.com>
*/

#include "boot.h"
        
	.file	"boot2.S"
	.text
	.global	_start
        
.code32
_start:                         # we are loaded at physical address 0x500 by stage1
        jmp     startup_32

        
        
/*****************************************
* Second Stage Entry Point 
*****************************************/        
startup_32:
        /* Set registers */
        cli
        movw    $0x10, %ax             # set data segments to data selector (0x10)
        movw    %ax, %ds
        movw    %ax, %ss
        movw    %ax, %es
        movl    $0x90000, %esp                   # stack begins from 0x90000

        /* TODO: jump to kernel */

        /* Stop execution */
        cli
        hlt
        
