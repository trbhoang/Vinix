#include <unistd.h>
#include <time.h>
#include <linux/tty.h>

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
  time_init();
  tty_init();
  

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
