# Makefile
# This is makefile to build bootloader
# Hoang Tran <trbhoang@gmail.com>

CFLAGS  = -Wall -Werror -nostdinc
LDFLAGS = -nostdlib -Wl,-N,--oformat,binary

CC = gcc
LD = ld

all:
	(cd boot; make)


.PHONY : clean
clean :
	(cd boot; make clean)
