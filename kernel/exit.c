
static inline void send_sig(long sig, struct task_struct *p, int priv)
{
  if (!p || sig < 1 || sig > 32) return;
  if (priv ||
      current->uid == p->uid ||
      current->euid == p->uid ||
      current->uid == p->euid ||
      current->euid == p->euid)
    p->signal |= (1 << (sig - 1));
}

void do_kill(long pid, long sig, int priv)
{
  struct task_struct **p = NR_TASKS + task;

  if (!pid)
    while (--p > &FIRST_TASK) {
      if (*p && (*p)->pgrp == current->pid)
        send_sig(sig, *p, priv);
    }
  else if (pid > 0)
    while (--p > &FIRST_TASK) {
      if (*p && (*p)->pid == pid)
        send_sig(sig, *p, priv);
    }
  else if (pid == -1)
    while (--p > &FIRST_TASK)
      send_sig(sig, *p, priv);
  else
    while (--p > &FIRST_TASK)
      if (*p && (*p)->pgrp == -pid)
        send_sig(sig, *p, priv);
}

int do_exit(long code)
{
  int i;

  free_page_tables(get_base(current->ldt[1]), get_limit(0x0f));
  free_page_tables(get_base(current->ldt[2]), get_limit(0x17));
  for (i = 0; i < NR_TASKS; i++)
    if (task[i] && task[i]->father == current->pid)
      task[i]->father = 0;
  for (i = 0; i < NR_OPEN; i++)
    if (current->filp[i])
      sys_close(i);
  iput(current->pwd);
  current->pwd = NULL;
  iput(current->root);
  current->root = NULL;
  if (current->leader && current->tty >= 0)
    tty_table[current->tty].pgrp = 0;
  if (last_task_used_math == current)
    last_task_used_math = NULL;
  if (current->father) {
    current->state = TASK_ZOMBIE;
    do_kill(current->father, SIGCHLD, 1);
    current->exit_code = code;
  } else
    release(current);
  schedule();
  return -1;                    /* just to suppress warnings */
}
