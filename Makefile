#
#  (C) Hoang Tran <trbhoang@gmail.com>
#

CC = gcc
CFLAGS  = -Wall -nostdinc -fno-stack-protector
LD = ld
LDFLAGS = -nostdlib -x -M -Ttext 0

OBJS = boot/head.o init/main.o kernel/kernel.o mm/mm.o fs/fs.o
LIBS = lib/lib.a

all: Image

Image: boot/boot Image/system
	objcopy -O binary -R .note -R .comment Image/system Image/system.bin
	cat boot/boot Image/system.bin > Image/floppy.img

boot/boot: boot/boot.S
	$(CC) $(CFLAGS) $@.S -nostdlib -Wl,-N,--oformat=binary -Ttext=0x0 -o $@

Image/system: $(OBJS) $(LIBS)
	$(LD) $(LDFLAGS) $(OBJS) $(LIBS) -o Image/system

# boot/head.o: boot/head.S
.S.o:
	$(CC) $(CFLAGS) $*.S -c -o $@

kernel/kernel.o:
	(cd kernel; make)

init/main.o:
	(cd init; make)

lib/lib.a:
	(cd lib; make)

mm/mm.o:
	(cd mm; make)

fs/fs.o:
	(cd fs; make)

.PHONY : clean
clean :
	(cd Image; rm -vf *)
	(cd boot; make clean)
	(cd init; make clean)
	(cd kernel; make clean)
	(cd lib; make clean)
	(cd mm; make clean)
	(cd fs; make clean)

