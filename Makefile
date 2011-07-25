# Makefile
# This is makefile to build bootloader
# Hoang Tran <trbhoang@gmail.com>

CFLAGS  = -Wall -Werror -nostdinc
LDFLAGS = -nostdlib -Wl,-N,--oformat,binary

BOOT_START_ADDR = 0x7c00
KERN_START_ADDR = 0x1000

CC = gcc
LD = ld

BOOTDIR  = boot
BUILDDIR = tmp
BOOT_FILES = boot.S
BOOT_INCLUDES = boot

all : $(BUILDDIR)/Image

# build assembly code
%.o : %.S
	$(CC) $(CFLAGS) -c -o $@ $<

# link boot object file
$(BUILDDIR)/Image : $(BOOT_FILES:%=$(BOOTDIR)/%)
	$(CC) $(CFLAGS) $(LDFLAGS),-Ttext,$(BOOT_START_ADDR) -o $@ $^

install : $(BUILDDIR)/Image
	bochs

.PHONY : clean
clean :
	-rm $(BUILDDIR)/Image
	-rm $(BOOTDIR)/*.o
