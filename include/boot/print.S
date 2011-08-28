/**
 * @file   boot.h
 * @brief  Generally useful bootloader values.
 * @author Mike Kasick <mkasick@andrew.cmu.edu>
 */

#ifndef STDIO_H
#define STDIO_H
        

/*****************************************
* Print a string
* DS:SI -> null terminated string 
*****************************************/
print:
        pusha                   # save registers
print_loop:     
        lodsb                   # load next byte from string to AL
        orb     %al, %al        # does AL = 0?
        jz      end_of_str      # yes, reach the end of the string
        movb    $0xE, %ah       # no, print the character
        int     $0x10           # BIOS 10h function
        jmp     print_loop      # repeat until reach null character 
end_of_str:
        popa                    # restore registers 
        ret                     # we are done, so return 
        

#endif
