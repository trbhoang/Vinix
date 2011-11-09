#
#   (C) Hoang Tran <trbhoang@gmail.com>
#

CC = gcc
CFLAGS = -Wall -Werror -O -fno-builtin -fno-stack-protector -nostdinc -I ../include

.c.o:
	$(CC) $(CFLAGS) -c -o $*.o $<
.S.o:
	$(CC) $(CFLAGS) -c -o $*.o $<

OBJS = sched.o mktime.o tty_io.o console.o serial.o keyboard.o rs_io.o traps.o asm.o printk.o exit.o vsprintf.o panic.o hd.o system_call.o sys.o fork.o

all: kernel.o

kernel.o: $(OBJS)
	$(LD) -r -o $@ $(OBJS)		# -r means 'relocatable' which make this kind of 'combining' OBJS into one

clean:
	rm -vf *.o
