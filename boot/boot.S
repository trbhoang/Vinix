# @file  sample_boot1.S
# @brief First stage bootloader (sample code).
#
# Doesn't actually load anything, but rather serves as demonstration code
# for making BIOS calls and useful gas directives.
#
# @author Mike Kasick <mkasick@andrew.cmu.edu>

#include "boot.h"
#include "debug.h"
        
	.file	"sample_boot1.S"
	.text

	.code16			# Emit 16-bit code for Real Mode.
	.global	_start
_start:				# _start = 0x1000
	# Print the welcome string
	movw	$one_str, %bp	# String isn't null terminated.
	movzbw	one_len, %si	# But the string length is calculated.
	call	print_str	# That's how "Write String" works.

	# Print a string from the neighboring sector.
	movw	$two_str, %bp	# "$label" loads the label address into %bp (same as "leaw two_str, %bp").
	movzbw	two_len, %si	# "label" loads the value defined at the label into %si.
	call	print_str

	# Debug macros.
	MAGIC_BREAK		# Break execution.
	LPUTS(null_term_str)	# Print null-terminated string.
	LPUTSN(null_term_str, 4) # Print part of a string.
	LPUTX(adata)		# Print a long in hex.

	# Execute no further.
	cli
halt:	hlt
	jmp halt

print_str:
	pusha			# Saves only the lower 16 bits of registers.

	# Get the current cursor position.
	movb	$READ_CURSOR_POS_AH, %ah
	xorb	%bh, %bh	# Page 0.
	int	$VIDEO_INT	# Clobbers %cx & %dx (cursor type & pos).

	# Write %si characters of the string pointed to by %bp.
	movb	$WRITE_STRING_AH, %ah
	movb	$MOVE_CURSOR_AL, %al
	movb	$LGRAY_ATTRIB, %bl
	xorb	%bh, %bh	# Page 0.
	movw	%si, %cx	# Character count.
	int	$VIDEO_INT	# %dx: String location, %es:%bp: String ptr.

	popa
	ret

	# Define a non-null terminated string, and it's length.  The .ascii
	# directive does not null terminate.
one_str: .ascii	"\r\nWelcome to boot1!\r\nFirst sector seems ok.\r\n"
one_len: .byte	. - one_str	# '.' is the "Special Dot Symbol", it
				# refers to the current address that as is
				# assembling into.

	# Define a null-terminated (i.e., C) string.  The .asciz directive
	# terminates and is equivalent to the .string directive.
null_term_str: .asciz "Null-terminated string."

	# More unused data, but this might be a useful way to build a
	# struct or some other data structure.
bdata:	.byte	0xf0		# Define byte data.
b2data:	.byte	0x0d, 0xd0	# Define multiple-byte data "array".
wdata:	.word	0x1337		# Define word data.
ldata:	.long	0xdeadbeef	# Define long data.

	.p2align 3		# Eight byte align the following data.
adata:	.long	0x1337c0de

        .org 510
boot_flag: .word 0xaa55

	# Move the location counter to the 512 byte mark, which is the
	# start of the second sector on disk, which should be loaded to
	# address 0x1200 in memory.  Once linked, two_str = 0x1200.
	.org	0x200		
two_str: .ascii "Second sector seems ok too.\r\n"
two_len: .byte	. - two_str
