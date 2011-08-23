# makefile
# this is makefile to build bootloader
# Hoang Tran <trbhoang@gmail.com>

CC = gcc
LD = ld
CFLAGS  = -Wall -Werror -nostdinc
LDFLAGS = -nostdlib -Wl,-N,--oformat,binary

STAGE1_START_ADDR = 0x7c00
STAGE2_START_ADDR = 0x0

IMAGE_DIR = ../Image
IMAGE_FILE = $(IMAGE_DIR)/floppy.img

all: boot1 boot2 image

boot1: boot1.o
	$(CC) $(CFLAGS) $(LDFLAGS) -Ttext=$(STAGE1_START_ADDR) -o $@ $^

boot2: boot2.o
	$(CC) $(CFLAGS) $(LDFLAGS) -Ttext=$(STAGE2_START_ADDR) -o $@ $^

%.o: %.S
	$(CC) $(CFLAGS) -c -o $@ $<

image: 
	dd if=/dev/zero of=$(IMAGE_FILE) bs=512 count=2880
	dd if=boot1 of=$(IMAGE_FILE) count=1
	dd if=boot2 of=$(IMAGE_FILE) seek=1

clean:
	rm *.o boot1 boot2 $(IMAGE_FILE)
