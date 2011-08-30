# makefile
# this is makefile to build bootloader
# Hoang Tran <trbhoang@gmail.com>

IMAGE_DIR = ../Image
IMAGE_FILE = $(IMAGE_DIR)/floppy.img
INC_DIR = ../include/boot

CC = gcc
CFLAGS  = -Wall -Werror -nostdinc -I $(INC_DIR)
LDFLAGS = -nostdlib -Wl,-N,--oformat,binary -Ttext=0x0


all: boot1 boot2 image

# link object file so that it could be ready to load into memory to be executed
# link and tie boot1 to offset addr 0x7c00 which also the physical addr where BIOS supposes to place it
# so to point to correct physical addr, the code must initialize data segments to 0x0 at the beginning
# 0x0:0x7c00 -> 0x7c00
boot1: boot1.o
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^		

# link and tie boot2 to offset addr 0x1000
boot2: boot2.o
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^		

%.o: %.S
	$(CC) $(CFLAGS) -c -o $@ $<				# compile file of assembly code (.S) to object file (.o)


image:  
	dd if=/dev/zero of=$(IMAGE_FILE) bs=512 count=2880	# make floppy image file 
	dd if=boot1 of=$(IMAGE_FILE) count=1			# record boot1 at boot sector
	dd if=boot2 of=$(IMAGE_FILE) seek=1			# record boot2 at second sector (right after boot sector)

clean:
	rm *.o boot1 boot2 $(IMAGE_FILE)
