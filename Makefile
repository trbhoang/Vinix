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
BOOT_FILES = sample_boot1.o
BOOT_INCLUDES = boot

all : $(BUILDDIR)/boot.img

# build assembly code
%.o : %.S
	$(CC) $(CFLAGS) -c -o $@ $<

# link boot object file
$(BUILDDIR)/boot.img : $(BOOT_FILES:%=$(BOOTDIR)/%)
	$(CC) $(CFLAGS) $(LDFLAGS),-Ttext,$(BOOT_START_ADDR) -o $@ $^

.PHONY : clean
clean :
	-rm $(BUILDDIR)/boot.img
