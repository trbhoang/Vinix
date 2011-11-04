/* bitmap.c contains the code that handles the inode and block bitmaps */
#include <string.h>

#include <linux/sched.h>
#include <linux/kernel.h>

#define clear_bit(nr,addr) ({						\
      register int res;/* __asm__("ax");*/				\
      __asm__("btrl %2,%3\n\tsetnb %%al":"=a" (res):"0" (0),"r" (nr),"m" (*(addr))); \
      res;})

    
void free_inode(struct m_inode *inode)
{
  struct super_block *sb;
  struct buffer_head *bh;

  if (!inode)
    return;
  if (!inode->i_dev) {
    memset(inode, 0, sizeof(*inode));
    return;
  }
  if (inode->i_count > 1) {
    printk("trying to free inode with count=%d\n", inode->i_count);
    panic("free_inode");
  }
  if (inode->i_nlinks)
    panic("trying to free inode with links");
  if (!(sb = get_super(inode->i_dev)))
    panic("trying to free inode on nonexistent device");
  if (inode->i_num < 1 || inode->i_num > sb->s_ninodes)
    panic("trying to free inode 0 or nonexistent inode");
  if (!(bh = sb->s_imap[inode->i_num >> 13]))
    panic("nonexistent imap in superblock");
  if (clear_bit(inode->i_num & 8191, bh->b_data))
    panic("free_inode: bit already cleared");
  bh->b_dirt = 1;
  memset(inode, 0, sizeof(*inode));
}
