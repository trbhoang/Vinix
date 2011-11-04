/*
 * 'sched.c' is the main kernel file. It contains scheduling primitives
 * (sleep_on, wakeup, schedule etc) as well as a number of simple system
 * call functions (type getpid(), which just extracts a field from current-task).
 */
#include <linux/sched.h>
#include <signal.h>



#define PAGE_SIZE 4096

long volatile jiffies = 0;
long startup_time = 0;

union task_union {
  struct task_struct task;
  char stack[PAGE_SIZE];
};

static union task_union init_task = {INIT_TASK,};

struct task_struct *current = &(init_task.task), *last_task_used_math = NULL;
struct task_struct *task[NR_TASKS] = {&(init_task.task), };


/* allocate a buffer for stack */
long user_stack[PAGE_SIZE>>2];  /* (4096 >> 2) * 4 =  */

struct {
  long * a;
  short  b;                     /* 2 bytes */
} stack_start = {&user_stack[PAGE_SIZE>>2], 0x10}; /* will become (ESP, SS selector) */

/*
 * math_state_restore() saves the current math information in the old math state array,
 * and gets the new ones from the current task
 */
void math_state_restore()
{
  if (last_task_used_math)
    __asm__("fnsave %0"::"m" (last_task_used_math->tss.i387));
  if (current->used_math)
    __asm__("frstor %0"::"m" (current->tss.i387));
  else {
    __asm__("fninit"::);
    current->used_math = 1;
  }
  last_task_used_math = current;
}

/*
 * 'schedule()' is the scheduler function. This is GOOD CODE! There
 * probably won't be any reason to change this, as it should work well
 * in all circumstances (ie gives IO-bound processes good response etc).
 * The one thing you might take a look at is the signal-handler code here.
 *
 * NOTE!! Task 0 is the 'idle' task, which gets called when no other
 * tasks can run. It can not be killed, and it cannot sleep. The 'state'
 * information in task[0] is never used.
 */
void schedule(void)
{
  int i, next, c;
  struct task_struct **p;

  /* check alarm, wake up any interruptible tasks that have got a signal */
  for (p = &LAST_TASK; p > &FIRST_TASK; --p)
    if (*p) {
      if ((*p)->alarm && (*p)->alarm < jiffies) {
	(*p)->signal |= (1 << (SIGALRM - 1));
	(*p)->alarm = 0;
      }
      if ((*p)->signal && (*p)->state == TASK_INTERRUPTIBLE)
	(*p)->state = TASK_RUNNING;
    }

  /* this is the scheduler proper */
  while (1) {
    c = -1;
    next = 0;
    i = NR_TASKS;
    p = &task[NR_TASKS];
    while (--i) {
      if (!*--p)
	continue;
      if ((*p)->state == TASK_RUNNING && (*p)->counter > c)
	c = (*p)->counter, next = i;
    }
    if (c) break;
    for (p = &LAST_TASK; p > &FIRST_TASK; --p)
      if (*p)
	(*p)->counter = ((*p)->counter >> 1) + (*p)->priority;
  }
  switch_to(next);
}

void wake_up(struct task_struct **p)
{
  if (p && *p) {
    (**p).state = 0;
    *p = NULL;
  }
}

void sleep_on(struct task_struct **p)
{
  struct task_struct *tmp;

  if (!p) return;
  if (current == &(init_task.task))
    panic("task[0] trying to sleep");
  tmp = *p;
  *p = current;
  current->state = TASK_INTERRUPTIBLE;
  schedule();
  if (tmp) tmp->state = 0;
}

void interruptible_sleep_on(struct task_struct **p)
{
  struct task_struct *tmp;

  if (!p) return;
  if (current == &(init_task.task))
    panic("task[0] trying to sleep");
  tmp = *p;
  *p = current;
 repeat:
  current->state = TASK_INTERRUPTIBLE;
  schedule();
  if (*p && *p != current) {
    (**p).state = 0;
    goto repeat;
  }
  *p = NULL;
  if (tmp)
    tmp->state = 0;
}
