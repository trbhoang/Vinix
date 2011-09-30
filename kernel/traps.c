/*
 * 'traps.c' handles hardware traps and faults after we have saved some
 * state in 'asm.s'. Currently mostly a debugging-aid, will be extended
 * to mainly kill the offending process (probably by giving it a signal,
 * but possibly by killing it outright if necessary).
 */
#include <linux/sched.h>
#include <asm/system.h>

int do_exit(long code);


void divide_error(void);
void debug(void);
void nmi(void);
void int3(void);
void overflow(void);
void bounds(void);
void invalid_op(void);
void device_not_available(void);
void double_fault(void);
void coprocessor_segment_overrun(void);
void invalid_TSS(void);
void segment_not_present(void);
void stack_segment(void);
void general_protection(void);
void page_fault(void);
void coprocessor_error(void);
void reserved(void);

static void die(char *str, long esp_ptr, long nr)
{
  long *esp = (long *)esp_ptr;
  int i;

  printk("%s: %04x\n\r", str, nr & 0xffff);
  printk("EIP:\t%04x:%p\nEFLAGS:\t%p\nESP:\t%04x:%p\n", esp[1], esp[0], esp[2], esp[4], esp[3]);
  printk("fs: %04x\n", _fs());
  printk("base: %p, limit: %p\n", get_base(current->ldt[1]), get_limit(0x17));
  if (esp[4] == 0x17) {
    printk("Stack: ");
    for (i = 0; i < 4; i++)
      printk("%p ", get_seg_long(0x17, i + (long *)esp[3]));
    printk("\n");
  }
  str(i);
  printk("Pid: %d, process nr: %d\n\r", current->pid, 0xffff & i);
  for (i = 0; i < 10; i++)
    printk("%02x ", 0xff & get_seg_byte(esp[1], (i + (char *)esp[0])));
  printk("\n\r");
  do_exit(11);                  /* play segment exception */
}

void do_divide_error(long esp, long error_code)
{
  die("divide error", esp, error_code);
}

void trap_init(void)
{
  int i;

  set_trap_gate(0, &divide_error);
  set_trap_gate(1, &debug);
  set_trap_gate(2, &nmi);
  set_system_gate(3, &int3);    /* int3-5 can be called from all */
  set_system_gate(4, &overflow);
  set_system_gate(5, &bounds);
  set_trap_gate(6, &invalid_op);
  set_trap_gate(7, &device_not_available);
  set_trap_gate(8, &double_fault);
  set_trap_gate(9, &coprocessor_segment_overrun);
  set_trap_gate(10, &invalid_TSS);
  set_trap_gate(11, &segment_not_present);
  set_trap_gate(12, &stack_segment);
  set_trap_gate(13, &general_protection);
  set_trap_gate(14, &page_fault);
  set_trap_gate(15, &reserved);
  set_trap_gate(16, &coprocessor_error);
  for (i = 17; i < 32; i++)
    set_trap_gate(i, &reserved);
}
