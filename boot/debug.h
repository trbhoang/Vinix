/**
 * @file  debug.h
 * @brief Simics debugging macros.
 *
 * Each debug macro may be called from assembly.  They do not trounce on
 * any registers, so none need to be saved before caling them.  However,
 * each macro does require a valid stack.
 *
 * If you wish to debug a portion of code where you do not have a valid
 * stack, crop out the relevant lines of assembly and insert them directly.
 * This will, however, trounce on registers.
 *
 * @author Mike Kasick <mkasick@andrew.cmu.edu>
 */

#ifndef DEBUG_H
#define DEBUG_H

/* Break simulation. */
#define MAGIC_BREAK \
	pushl	%ebx; \
	movl	$0x2badd00d, %ebx; \
	xchgl	%ebx, %ebx; \
	popl	%ebx

/* Print a null-terminated string to the Simics console. */
#define LPUTS(s) \
	pushl	%eax; \
	pushl	%ebx; \
	movl	$(s), %eax; \
	movl	$0x1badd00d, %ebx; \
	xchgl	%ebx, %ebx; \
	popl	%ebx; \
	popl	%eax

/* Print n bytes of a string to the Simics console. */
#define LPUTSN(s, n) \
	pushl	%eax; \
	pushl	%ebx; \
	pushl	%ecx; \
	movl	$(s), %eax; \
	movl	$0x3badd00d, %ebx; \
	movl	$(n), %ecx; \
	xchgl	%ebx, %ebx; \
	popl	%ecx; \
	popl	%ebx; \
	popl	%eax

/* Print the 32-bit long in hexadecimal to the Simics console. */
#define LPUTX(x) \
	pushl	%eax; \
	pushl	%ebx; \
	movl	$(x), %eax; \
	movl	$0x4badd00d, %ebx; \
	xchgl	%ebx, %ebx; \
	popl	%ebx; \
	popl	%eax

#endif
