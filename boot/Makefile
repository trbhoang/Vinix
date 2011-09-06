# makefile
# this is makefile to build bootloader
# Hoang Tran <trbhoang@gmail.com>

IMAGE_DIR = ../Image
IMAGE_FILE = $(IMAGE_DIR)/floppy.img
INC_DIR = ../include/boot

CC = gcc
CFLAGS  = -Wall -Werror -nostdinc -I $(INC_DIR)
LDFLAGS = -nostdlib -Wl,-N,--oformat=binary -Ttext=0x0


all: boot head image

boot: boot.o
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^		

head: head.o
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

%.o: %.S
	$(CC) $(CFLAGS) -c -o $@ $<				# compile file of assembly code (.S) to object file (.o)

image:  
	dd if=/dev/zero of=$(IMAGE_FILE) bs=512 count=2880	# make floppy image file 
	dd if=boot of=$(IMAGE_FILE) count=1			# record boot at boot sector
	dd if=head of=$(IMAGE_FILE) seek=1			# record head at second sector (right after boot sector)

clean:
	rm *.o boot head $(IMAGE_FILE)
