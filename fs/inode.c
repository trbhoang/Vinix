#include <string.h>
#include <linux/sched.h>
#include <linux/kernel.h>
#include <linux/mm.h>
#include <asm/system.h>



void iput(struct m_inode *inode)
{
  if (!inode) return;
  wait_on_inode(inode);
  if (!inode->i_count)
    panic("iput: trying to free free inode");
  if (inode->i_pipe) {
    wake_up(&inode->i_wait);
    if (--inode->i_count) return;
    free_page(inode->i_size);
    inode->i_count = 0;
    inode->i_dirt = 0;
    inode->i_pipe = 0;
    return;
  }
  if (!inode->i_dev || inode->i_count > 1) {
    inode->i_count--;
    return;
  }
 repeat:
  if (!inode->i_nlinks) {
    truncate(inode);
    free_inode(inode);
    return;
  }
  if (inode->i_dirt) {
    write_inode(inode);  	/* we can sleep - so do again */
    wait_on_inode(inode);
    goto repeat;
  }
  inode->i_count--;
  return;
}
