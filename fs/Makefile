CC = gcc
CFLAGS = -Wall -Werror -fno-builtin -fno-stack-protector -nostdinc -I ../include

.c.o:
	$(CC) $(CFLAGS) -c -o $*.o $<
.S.o:
	$(CC) $(CFLAGS) -c -o $*.o $<

OBJS = open.o inode.o truncate.o bitmap.o super.o buffer.o block_dev.o stat.o exec.o read_write.o namei.o fcntl.o pipe.o ioctl.o sys_getdents.o file_table.o char_dev.o file_dev.o tty_ioctl.o

all: fs.o 

fs.o: $(OBJS)
	$(LD) -r -o $@ $(OBJS)		# -r means 'relocatable' which make this kind of 'combining' OBJS into one

clean:
	rm -rf *.o
