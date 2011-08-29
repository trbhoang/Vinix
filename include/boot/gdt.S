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
        lgdt    gdtr_48 	# load GDT to GDTR
        sti             	# enable interrupts
        popa            	# restore registers
        ret             	# done

        
/*****************************************
* Null descriptor
* which is filled with eight 0 bytes 
*****************************************/
start_of_gdt:   
        .quad   0       # 8-byte 0


/*****************************************
* Code Descriptor 
* right after null descriptor 
*****************************************/        
.short  0xffff          # limit low
.short  0               # base low
.byte   0               # base middle
.byte   0b10011010      # access
.byte   0b11001111      # granularity
.byte   0               # base high
        

/*****************************************
* Data Descriptor 
* right after null descriptor 
*****************************************/        
.short  0xffff          # limit low (same as code segment descriptor)
.short  0               # base low
.byte   0               # base middle
.byte   0b10010010      # access
.byte   0b11001111      # granularity
.byte   0               # base high
end_of_gdt:
        
gdtr_48:                # this contains what will be load to GDTR register 
        .short  end_of_gdt - start_of_gdt         # size of GDT (2 bytes)
        .short  start_of_gdt, 0x1                 # base of GDT (4 bytes) --> become 0x1XXXX
        

#endif
        
