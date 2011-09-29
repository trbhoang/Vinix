#define PAGE_SIZE 4096

long startup_time = 0;

/* allocate a buffer for stack */
long user_stack[PAGE_SIZE>>2];  /* (4096 >> 2) * 4 =  */

struct {
  long * a;
  short  b;                     /* 2 bytes */
} stack_start = {&user_stack[PAGE_SIZE>>2], 0x10}; /* will become (ESP, SS selector) */
