#
#   (C) Hoang Tran <trbhoang@gmail.com>
#

CC = gcc
CFLAGS = -Wall -Werror -nostdinc -I ../include

OBJS = sched.o mktime.o tty_io.o console.o serial.o keyboard.o rs_io.o


kernel.o: $(OBJS)
	$(LD) -r -o $@ $(OBJS)		# -r means 'relocatable' which make this kind of 'combining' OBJS into one

sched.o: sched.c
	$(CC) $(CFLAGS) -c sched.c

mktime.o: mktime.c
	$(CC) $(CFLAGS) -c mktime.c

console.o: console.c
	$(CC) $(CFLAGS) -c console.c

tty_io.o: tty_io.c
	$(CC) $(CFLAGS) -c tty_io.c

serial.o: serial.c
	$(CC) $(CFLAGS) -c serial.c

keyboard.o: keyboard.S
	$(CC) $(CFLAGS) keyboard.S -c -o keyboard.o

rs_io.o: rs_io.S
	$(CC) $(CFLAGS) rs_io.S -c -o rs_io.o

clean:
	rm -vf *.o
