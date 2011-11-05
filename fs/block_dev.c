#include <linux/fs.h>
#include <linux/kernel.h>


#define NR_BLK_DEV ((sizeof (rd_blk)) / (sizeof (rd_blk[0])))

extern void rw_hd(int rw, struct buffer_head * bh);

typedef void (*blk_fn)(int rw, struct buffer_head * bh);

static blk_fn rd_blk[] = {
  NULL, 			/* nodev */
  NULL, 			/* dev mem */
  NULL,				/* dev fd */
  rw_hd, 			/* dev hd */
  NULL, 			/* dev ttyx */
  NULL, 			/* dev tty */
  NULL				/* dev lp */
};

void ll_rw_block(int rw, struct buffer_head * bh)
{
  blk_fn blk_addr = NULL;
  unsigned int major;

  if ((major = MAJOR(bh->b_dev)) >= NR_BLK_DEV || !(blk_addr = rd_blk[major]))
    panic("Trying to read nonexistent block-device");
  blk_addr(rw, bh);
}
