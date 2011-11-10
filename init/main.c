#define __LIBRARY__
#include <unistd.h>
#include <time.h>

/*
 * We need this inline - forking from kernel space will result
 * in NO COPY ON WRITE (!!!), until an execve is executed. This
 * is no problem, but for the stack. This is handled by not letting
 * main() use the stack at all after fork(). Thus, no function
 * calls - which means inline code for fork too, as otherwise we
 * would use the stack upon exit from fork().
 *
 * Actually only pause and fork are needed inline, so that there
 * won't be any messing with the stack from main(), but we define
 * some others too.
 */


#include <linux/tty.h>
#include <linux/sched.h>

#include <asm/io.h>


/* These will be defined by using _syscall0 macro which is defined in 'unistd.h' */
// static inline _syscall0(int, pause)


extern long kernel_mktime(struct tm * tm);
extern long startup_time;


/*
 * Yeah, yeah, it's ugly, but I cannot find how to do this correctly
 * and this seems to work. Anybody has more info on the real-time clock
 * I'd be interested. Most of this was trial and error, and some
 * bios-listing reading. Urghh.
 */

#define CMOS_READ(addr) ({ \
  outb_p(0x80 | addr, 0x70); \
  inb_p(0x71); \
})

#define BCD_TO_BIN(val) ((val)=((val)&15) + ((val)>>4)*10)

static void time_init(void)
{
  struct tm time;

  do {
    time.tm_sec  = CMOS_READ(0);
    time.tm_min  = CMOS_READ(2);
    time.tm_hour = CMOS_READ(4);
    time.tm_mday = CMOS_READ(7);
    time.tm_mon  = CMOS_READ(8) - 1;
    time.tm_year = CMOS_READ(9);
  } while (time.tm_sec != CMOS_READ(0));

  BCD_TO_BIN(time.tm_sec);
  BCD_TO_BIN(time.tm_min);
  BCD_TO_BIN(time.tm_hour);
  BCD_TO_BIN(time.tm_mday);
  BCD_TO_BIN(time.tm_mday);
  BCD_TO_BIN(time.tm_mon);
  BCD_TO_BIN(time.tm_year);

  startup_time = kernel_mktime(&time);
}

int main(void)
{
  /* Interrupts are still disabled. Do necessary setups, then enable them. */
  time_init();
  tty_init();
  trap_init();
  sched_init();
  buffer_init();
  
  /*
   * NOTE!!
   * For any other task 'pause()' would mean we have to get a signal to awaken,
   * but task 0 gets activated at every idle moment (when no other tasks can run).
   * For task0 'pause()' just means we go check if some other task can run, and
   * if not we return here.
   */
  // for(;;) pause();

  return 0;
}
