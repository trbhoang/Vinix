/*
 * super.c contains code to handle the super-block tables.
 */
#include <linux/config.h>
#include <linux/sched.h>
#include <linux/kernel.h>

struct super_block super_block[NR_SUPER];

struct super_block * get_super(int dev)
{
	struct super_block * s;

	for(s = 0+super_block;s < NR_SUPER+super_block; s++)
		if (s->s_dev == dev)
			return s;
	return NULL;
}
