# Makefile
# This is makefile to build bootloader
# Hoang Tran <trbhoang@gmail.com>

CFLAGS  = -Wall -Werror -nostdinc
LDFLAGS = -nostdlib -x -M -Ttext 0 -e startup_32

CC = gcc
LD = ld

all: Image

Image: boot/boot Image/system
	objcopy -O binary -R .note -R .comment Image/system Image/system.bin
	cat boot/boot Image/system.bin > Image/floppy.img

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

