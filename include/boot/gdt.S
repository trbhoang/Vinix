/**
 * @file   gdt.S
 * @brief  Global Descriptor Table
 * @author Hoang Tran <trbhoang@gmail.com>
 */

#ifndef GDT_S
#define GDT_S
        
        
/***************************************************************
* Global Descriptor Table (GDT)
* Each entry is a descriptor
* The first one must be a null descriptor
* This GDT contains three 8-byte descriptors: null, code, data
****************************************************************/



/*****************************************
* Install GDT
*****************************************/
install_gdt:    
        cli             	# clear interrupts 
        pusha           	# save registers
        lgdt    gdt_desc 	# load GDT to GDTR
        sti             	# enable interrupts
        popa            	# restore registers
        ret             	# done


        .p2align        2       /* force 4-byte alignment */
gdt:
        .word   0, 0
        .byte   0, 0, 0, 0

        /* code segment */
        .word   0xFFFF, 0
        .byte   0, 0x9A, 0xCF, 0

        /* data segment */
        .word   0xFFFF, 0
        .byte   0x, 0x92, 0xCF, 0

        /* 16 bit real mode CS */
        .word   0xFFFF, 0
        .byte   0, 0x9E, 0, 0

        /* 16 bit real mode DS */
        .word   0xFFFF, 0
        .byte   0, 0x92, 0, 0

        
/* this is the GDT descriptor */        
gdt_desc:              
        .word   0x27            /* limit */
        .long   gdt             /* addr */
        

#endif
        
