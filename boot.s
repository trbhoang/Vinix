/*
   1. start executing from _start (the first byte on floppy disk)
   2. _start: copy 512 bytes starting at 0x7c00 to 0x9000
   3. print a boot up message on the screen
*/

.code16
.text
              
/* some constants */
# .equ BOOTSEG, 0x07c0   # this is segment base, the linear address will be
                       # (segment * 16 + offset) = 0x07c00
# .equ INITSEG, 0x9000   # linear address = 0x90000
.globl _start
_start:
              cli
              movw $0x07c0, %ax
              movw %ax, %ds   
              movw %ax, %ss
              movw $0x1000, %sp
              sti

              movw $hello_msg, %si

print_string1:
              movb (%si), %al
              cmpb $0x00, %al
              je moving

              movb $0x0e, %ah
              xorw %bx, %bx
              int $0x10

              incw %si
              jmp print_string1

moving:       
              movw $0x9000, %ax
              movw %ax, %es   
              movw $256, %cx  # we'll move 512 bytes = 256 words
              
              // set source index and dest index to 0,
              // that  means it points to start of this segment (0x07c00)
              subw %si, %si   
              subw %di, %di
              rep    # repeat the following instruction %cx times
              movsw  # move (ds:si) to (es:di)

              // do long jump to new segment now at 0x90000
              ljmp $0x9000, $0x3f  # !!!!!! this may not correct (what is CS at this movement?)
              
go:
              // set code segment, data seg, stack seg,.. point to new area
              movw $0x9000, %ax
              movw %ax, %cs  
              movw %ax, %ds
              movw %ax, %es
              movw %ax, %ss
              movw $0x1000, %sp  # arbitrary value >> 512
              
              // Here we just fall into the infinite loop
kernel_exit:
              hlt
              jmp kernel_exit

hello_msg:
              .asciz "Hello world!!!" /* Zero-padded string. */
.space 429, 0 /* padding remaining bytes with 0s */
.word 0xaa55  /* The boot signature for PC BIOS */
