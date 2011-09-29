/*
 * 'sched.c' is the main kernel file. It contains scheduling primitives
 * (sleep_on, wakeup, schedule etc) as well as a number of simple system
 * call functions (type getpid(), which just extracts a field from current-task).
 */
#include <linux/sched.h>



#define PAGE_SIZE 4096

long startup_time = 0;

union task_union {
  struct task_struct task;
  char stack[PAGE_SIZE];
};

static union task_union init_task = {INIT_TASK,};


struct task_struct *task[NR_TASKS] = {&(init_task.task), };


/* allocate a buffer for stack */
long user_stack[PAGE_SIZE>>2];  /* (4096 >> 2) * 4 =  */

struct {
  long * a;
  short  b;                     /* 2 bytes */
} stack_start = {&user_stack[PAGE_SIZE>>2], 0x10}; /* will become (ESP, SS selector) */



void wake_up(struct task_struct **p)
{
  if (p && *p) {
    (**p).state = 0;
    *p = NULL;
  }
}
