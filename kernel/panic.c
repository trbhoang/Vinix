/*
 * This function is used through-out the kernel
 * to indicate a major problem.
 */
#include <linux/kernel.h>

void panic(const char *s)
{
  printk("Kernel panic: %s\n\r", s);
  for (;;);
}
