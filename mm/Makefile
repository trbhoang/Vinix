CC = gcc
CFLAGS = -Wall -Werror -nostdinc -I ../include

.c.o:
	$(CC) $(CFLAGS) -c -o $*.o $<
.s.o:
	$(CC) $(CFLAGS) -c -o $*.o $<

OBJS = page.o

all: mm.o

mm.o: $(OBJS)
	$(LD) -r -o $@ $(OBJS)		# -r means 'relocatable' which make this kind of 'combining' OBJS into one

