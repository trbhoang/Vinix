# Makefile
# This is makefile to build bootloader
# Hoang Tran <trbhoang@gmail.com>

IMAGE_FILE = ../Image/floppy.img
INC = ../include/boot

CC = gcc
CFLAGS  = -Wall -Werror -nostdinc -I $(INC)
LDFLAGS = -nostdlib -Wl,-N,--oformat=binary -Ttext=0x0


all: boot head image

.S:
	$(CC) $(CFLAGS) $@.S $(LDFLAGS) -o $@	# compile and link  *.S to * binary

image:  
	dd if=/dev/zero of=$(IMAGE_FILE) bs=512 count=2880	# make floppy image file 
	dd if=boot of=$(IMAGE_FILE) count=1			# record boot at boot sector
	dd if=head of=$(IMAGE_FILE) seek=1			# record head at second sector (right after boot sector)

clean:
	rm *.o boot head $(IMAGE_FILE)
