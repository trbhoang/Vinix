#
#   (C) Hoang Tran <trbhoang@gmail.com>
#

CC = gcc
CFLAGS  = -Wall -Werror -fno-builtin -fno-stack-protector -nostdinc -I ../include


main.o: main.c
	$(CC) $(CFLAGS) -c main.c

clean:
	rm -vf *.o
