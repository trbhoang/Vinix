/**
 * @file   a20.S
 * @brief  routines to enable A20 line
 * @author Hoang Tran <trbhoang@gmail.com>
 */

#ifndef A20_S
#define A20_S

/*****************************************
* Enable A20 line through BIOS
*****************************************/
        
enableA20:
        pusha
        movw    $0x2401, %ax
        int     $0x15
        popa
        ret
        
#endif
