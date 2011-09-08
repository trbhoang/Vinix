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


clean:
	-rm *.o boot 
