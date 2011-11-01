CC = gcc
CFLAGS = -Wall -Werror -fno-builtin -fno-stack-protector -nostdinc -I ../include

.c.o:
	$(CC) $(CFLAGS) -c -o $*.o $<
.S.o:
	$(CC) $(CFLAGS) -c -o $*.o $<

OBJS = page.o segment.o memory.o string.o

all: mm.o 

mm.o: $(OBJS)
	$(LD) -r -o $@ $(OBJS)		# -r means 'relocatable' which make this kind of 'combining' OBJS into one


clean:
	rm -rf *.o
