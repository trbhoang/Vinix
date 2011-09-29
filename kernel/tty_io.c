/*
 * 'tty_io.c' gives an orthogonal feeling to tty's, be they consoles
 * or rs-channels. It also implements echoing, cooked mode etc (well,
 * not currently, but...)
 */
#include <ctype.h>
#include <errno.h>
#include <signal.h>

#define ALRMMASK (1 << (SIGALRM - 1))

#include <linux/sched.h>
#include <linux/tty.h>
#include <asm/segment.h>
#include <asm/system.h>

#define _L_FLAG(tty,f)	((tty)->termios.c_lflag & f)
#define _I_FLAG(tty,f)	((tty)->termios.c_iflag & f)
#define _O_FLAG(tty,f)	((tty)->termios.c_oflag & f)

#define L_CANON(tty)	_L_FLAG((tty),ICANON)
#define L_ISIG(tty)	_L_FLAG((tty),ISIG)
#define L_ECHO(tty)	_L_FLAG((tty),ECHO)
#define L_ECHOE(tty)	_L_FLAG((tty),ECHOE)
#define L_ECHOK(tty)	_L_FLAG((tty),ECHOK)
#define L_ECHOCTL(tty)	_L_FLAG((tty),ECHOCTL)
#define L_ECHOKE(tty)	_L_FLAG((tty),ECHOKE)

#define I_UCLC(tty)	_I_FLAG((tty),IUCLC)
#define I_NLCR(tty)	_I_FLAG((tty),INLCR)
#define I_CRNL(tty)	_I_FLAG((tty),ICRNL)
#define I_NOCR(tty)	_I_FLAG((tty),IGNCR)

#define O_POST(tty)	_O_FLAG((tty),OPOST)
#define O_NLCR(tty)	_O_FLAG((tty),ONLCR)
#define O_CRNL(tty)	_O_FLAG((tty),OCRNL)
#define O_NLRET(tty)	_O_FLAG((tty),ONLRET)
#define O_LCUC(tty)	_O_FLAG((tty),OLCUC)


struct tty_struct tty_table[] = {
  {
    {0,
     OPOST|ONLCR,	/* change outgoing NL to CRNL */
     0,
     ICANON | ECHO | ECHOCTL | ECHOKE,
     0,		/* console termio */
     INIT_C_CC},
    0,			/* initial pgrp */
    0,			/* initial stopped */
    con_write,
    {0,0,0,0,""},		/* console read-queue */
    {0,0,0,0,""},		/* console write-queue */
    {0,0,0,0,""}		/* console secondary queue */
  },{
    {0, /*IGNCR*/
     OPOST | ONLRET,		/* change outgoing NL to CR */
     B2400 | CS8,
     0,
     0,
     INIT_C_CC},
    0,
    0,
    rs_write,
    {0x3f8,0,0,0,""},		/* rs 1 */
    {0x3f8,0,0,0,""},
    {0,0,0,0,""}
  },{
    {0, /*IGNCR*/
     OPOST | ONLRET,		/* change outgoing NL to CR */
     B2400 | CS8,
     0,
     0,
     INIT_C_CC},
    0,
    0,
    rs_write,
    {0x2f8,0,0,0,""},		/* rs 2 */
    {0x2f8,0,0,0,""},
    {0,0,0,0,""}
  }
};

/*
 * these are the tables used by the machine code handlers.
 * you can implement pseudo-tty's or something by changing
 * them. Currently not done.
 */
struct tty_queue *table_list[] = {
  &tty_table[0].read_q, &tty_table[0].write_q,
  &tty_table[1].read_q, &tty_table[1].write_q,
  &tty_table[2].read_q, &tty_table[2].write_q
};

void tty_init(void)
{
  rs_init();
  con_init();
}

void tty_intr(struct tty_struct *tty, int signal)
{
  int i;

  if (tty->pgrp <= 0) return;
  for (i = 0; i < NR_TASKS; i++)
    if (task[i] && task[i]->pgrp == tty->pgrp)
      task[i]->signal |= 1 << (signal - 1);
}

void copy_to_cooked(struct tty_struct *tty)
{
  signed char c;

  while (!EMPTY(tty->read_q) && !FULL(tty->secondary)) {
    GETCH(tty->read_q, c);
    if (c == 13)
      if (I_CRNL(tty))
        c = 10;
      else if (I_NOCR(tty))
        continue;
      else ;
    else if (c == 10 && I_NLCR(tty))
      c = 13;

    if (I_UCLC(tty)) c = tolower(c);

    if (L_CANON(tty)) {
      if (c == ERASE_CHAR(tty)) {
        if (EMPTY(tty->secondary) || (c = LAST(tty->secondary)) == 10 || c == EOF_CHAR(tty)) continue;
        if (L_ECHO(tty)) {
          if (c < 32) PUTCH(127, tty->write_q);
          PUTCH(127, tty->write_q);
          tty->write(tty);
        }
        DEC(tty->secondary.head);
        continue;
      }
      if (c == STOP_CHAR(tty)) {
        tty->stopped = 1;
        continue;
      }
      if (c == START_CHAR(tty)) {
        tty->stopped = 0;
        continue;
      }
    }
    if (!L_ISIG(tty)) {
      if (c == INTR_CHAR(tty)) {
        tty_intr(tty, SIGINT);
        continue;
      }
    }
    if (c == 10 || c == EOF_CHAR(tty))
      tty->secondary.data++;
    if (L_ECHO(tty)) {
      if (c == 10) {
        PUTCH(10, tty->write_q);
        PUTCH(13, tty->write_q);
      } else if (c < 32) {
        if (L_ECHOCTL(tty)) {
          PUTCH('^', tty->write_q);
          PUTCH(c + 64, tty->write_q);
        }
      } else PUTCH(c, tty->write_q);
      tty->write(tty);
    }
    PUTCH(c, tty->secondary);
  }
  wake_up(&tty->secondary.proc_list);
}

/*
 * Jeh, sometimes I really like the 386.
 * This routine is called from an interrupt,
 * and there should be absolutely no problem
 * with sleeping even in an interrupt (I hope).
 * Of course, if somebody proves me wrong, I'll
 * hate intel for all time :-). We'll have to
 * be careful and see to reinstating the interrupt
 * chips before calling this, though.
 */
void do_tty_interrupt(int tty)
{
  copy_to_cooked(tty_table + tty);
}
