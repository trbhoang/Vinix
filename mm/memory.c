#include <linux/config.h>
#include <linux/kernel.h>

inline void invalidate()
{
  int d0;
  __asm__ __volatile(
		     "movl %%eax, %%cr3"
		     :"=&a" (d0)
		     :"0" (0));
}

#if (BUFFER_END < 0x100000)
#define LOW_MEM 0x100000
#else
#define LOW_MEM BUFFER_END
#endif

/* these are not to be changed - they are calculated from the above */
#define PAGING_MEMORY (HIGH_MEMORY - LOW_MEM)
#define PAGING_PAGES (PAGING_MEMORY / 4096)
#define MAP_NR(addr) (((addr) - LOW_MEM) >> 12)

#if (PAGING_PAGES < 10)
#error "Won't work"
#endif

static unsigned short mem_map[PAGING_PAGES] = {0,};

/*
 * Free a page of memory at physical address 'addr'. Used by
 * 'free_page_tables()'
 */
void free_page(unsigned long addr)
{
  if (addr < LOW_MEM) return;
  if (addr > HIGH_MEMORY)
    panic("trying to free nonexistent page");
  addr -= LOW_MEM;
  addr >>= 12;
  if (mem_map[addr]--) return;
  mem_map[addr] = 0;
  panic("trying to free free page");
}

/*
 * This function frees a continuous block of page tables, as needed
 * by 'exit()'. As does conpy_page_tables(), this handles only 4Mb blocks.
 */
int free_page_tables(unsigned long from, unsigned long size)
{
  unsigned long *pg_table;
  unsigned long *dir, nr;

  if (from & 0x3fffff)
    panic("free_page_tables called with wrong alignment");
  if (!from)
    panic("Trying to free up swapper memory space");
  size = (size + 0x3fffff) >> 22;
  dir = (unsigned long *) ((from >> 20) & 0xffc); /* _pg_dir = 0 */
  for ( ; size-->0; dir++) {
    if (!(1 & *dir))
      continue;
    pg_table = (unsigned long *) (0xfffff000 & *dir);
    for (nr = 0; nr < 1024; nr++) {
      if (1 & *pg_table)
	free_page(0xfffff000 & *pg_table);
      *pg_table = 0;
      pg_table++;
    }
    free_page(0xfffff000 & *dir);
    *dir = 0;
  }
  invalidate();
  return 0;
}

