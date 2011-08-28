/**
 * @file   gdt.S
 * @brief  Global Descriptor Table
 * @author Hoang Tran <trbhoang@gmail.com>
 */

        
        
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
        cli             # clear interrupts 
        pusha           # save registers
        lgdt    gdtr    # load GDT to GDTR
        sti             # enable interrupts
        popa            # restore registers
        ret             # done
        
        
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
.int    0xffff          # limit low
.int    0               # base low
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
        
gdtr:                   # this contains what will be load to GDTR register 
        .short  end_of_gdt - start_of_gdt - 1           # size of GDT
        .int    start_of_gdt                            # base of GDT
        

#endif
        
