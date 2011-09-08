# Makefile
# This is makefile to build bootloader
# Hoang Tran <trbhoang@gmail.com>

CFLAGS  = -Wall -Werror -nostdinc
LDFLAGS = -nostdlib -s -x -M

CC = gcc
LD = ld

all: Image

Image: boot/boot Image/system
	dd if=/dev/zero of=Image/floppy.img bs=512 count=2880
	dd if=boot/boot of=Image/floppy.img count=1
	dd if=Image/system of=Image/floppy.img seek=1

boot/boot: boot/boot.S
	$(CC) $(CFLAGS) $@.S -nostdlib -Wl,-N,--oformat=binary -Ttext=0x0 -o $@

Image/system: boot/head.o kernel/kernel.o
	$(LD) $(LDFLAGS) boot/head.o kernel/kernel.o -o Image/system

boot/head.o: boot/head.S
	$(CC) $(CFLAGS) $*.S -c -o $@

kernel/kernel.o:
	(cd kernel; make)


.PHONY : clean
clean :
	(cd Image; rm *)
	(cd boot; make clean)
	(cd kernel; make clean)

