/*
 *   console.c
 * This module implements the console io functions
 *   'void con_init(void)'
 *   'void con_write(struct tty_queue *queue)'
 * Hopefully this will be a rather complete VT102 implementation.
 *
 */

/*
 * NOTE!!! We sometimes disable and enable interrupts for a short while
 * (to put a word in video IO), but this will work even for keyboard
 * interrupts. We know interrupts aren't enabled when getting a keyboard
 * interrupt, as we use trap-gate. Hopefully all is well. 
 */

#include <linux/sched.h>
#include <asm/io.h>
#include <asm/system.h>


#define SCREEN_START 0xb8000
#define LINES        25
#define COLUMNS      80

extern void keyboard_interrupt(void);


static unsigned long origin = SCREEN_START;
static unsigned long lines = LINES, columns = COLUMNS;

static unsigned long pos;
static unsigned long x, y;


static inline void gotoxy(unsigned int new_x, unsigned int new_y)
{
  if (new_x >= columns || new_y >= lines) return;
  x = new_x;
  y = new_y;
  pos = origin + ((y * columns + x) << 1);
}


/*
 * void con_init(void);
 *
 * This routine initializes console interrupts, and does nothing else.
 * If you want the screen to clear, call tty_write with the appropriate
 * escape-sequence.
 */
void con_init(void)
{
  register unsigned char a;

  gotoxy(*(unsigned char *)(0x90000 + 510), *(unsigned char *)(0x90000 + 511));
  set_trap_gate(0x21, &keyboard_interrupt);
  outb_p(inb_p(0x21) & 0xfd, 0x21);
  a = inb_p(0x61);
  outb_p(a | 0x80, 0x61);
  outb(a, 0x61);
}
