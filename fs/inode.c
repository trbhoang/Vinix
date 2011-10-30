#include <string.h>
#include <linux/sched.h>
#include <linux/kernel.h>
#include <linux/mm.h>
#include <asm/system.h>

/* static void read_inode(struct m_inode *inode); */
static void write_inode(struct m_inode *inode);

static inline void wait_on_inode(struct m_inode *inode)
{
  cli();
  while (inode->i_lock)
    sleep_on(&inode->i_wait);
  sti();
}

static inline void lock_inode(struct m_inode *inode)
{
  cli();
  while (inode->i_lock)
    sleep_on(&inode->i_wait);
  inode->i_lock = 1;
  sti();
}

static inline void unlock_inode(struct m_inode *inode)
{
  inode->i_lock = 0;
  wake_up(&inode->i_wait);
}

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

/* static void read_inode(struct m_inode *inode) */
/* { */
/*   struct super_block *sb; */
/*   struct buffer_head *bh; */
/*   int block; */

/*   lock_inode(inode); */
/*   sb = get_super(inode->i_dev); */
/*   block = 2 + sb->s_imap_blocks + sb->s_zmap_blocks + (inode->i_num - 1) / INODES_PER_BLOCK; */
/*   if (!(bh = bread(inode->i_dev, block))) */
/*     panic("unable to read i-node block"); */
/*   *(struct d_inode *)inode = ((struct d_inode *)bh->b_data)[(inode->i_num - 1) % INODES_PER_BLOCK]; */
/*   brelse(bh); */
/*   unlock_inode(inode); */
/* } */

static void write_inode(struct m_inode *inode)
{
  struct super_block *sb;
  struct buffer_head *bh;
  int block;

  lock_inode(inode);
  sb = get_super(inode->i_dev);
  block = 2 + sb->s_imap_blocks + sb->s_zmap_blocks + (inode->i_num - 1) / INODES_PER_BLOCK;
  if (!(bh = bread(inode->i_dev, block)))
    panic("unable to read i-node block");
  ((struct d_inode *) bh->b_data)[(inode->i_num - 1) % INODES_PER_BLOCK] = *(struct d_inode *) inode;
  bh->b_dirt = 1;
  inode->i_dirt = 0;
  brelse(bh);
  unlock_inode(inode);
}
