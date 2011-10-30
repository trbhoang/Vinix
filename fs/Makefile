CC = gcc
CFLAGS = -Wall -Werror -fno-builtin -nostdinc -I ../include

.c.o:
	$(CC) $(CFLAGS) -c -o $*.o $<
.S.o:
	$(CC) $(CFLAGS) -c -o $*.o $<

OBJS = open.o inode.o

all: fs.o 

fs.o: $(OBJS)
	$(LD) -r -o $@ $(OBJS)		# -r means 'relocatable' which make this kind of 'combining' OBJS into one

clean:
	rm -rf *.o
