#
# Makefile for some libs needed in the kernel
#

AR = ar
CC = gcc
CFLAGS  = -Wall -Werror -fno-builtin -fno-stack-protector -nostdinc -I ../include
LD = ld
LDFLAGS = -nostdlib -x -M -Ttext 0

.c.o:
	$(CC) $(CFLAGS) -c -o $*.o $<

OBJS = ctype.o errno.o write.o open.o dup.o close.o setsid.o execve.o _exit.o wait.o

lib.a: $(OBJS)
	$(AR) rcs lib.a $(OBJS)

clean:
	rm -vf *.o *.a
