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


