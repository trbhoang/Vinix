#include <signal.h>

#include <linux/config.h>
#include <linux/kernel.h>
#include <linux/mm.h>


int do_exit(long code);


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

inline void copy_page(unsigned long from, unsigned long to)
{
  int d0, d1, d2;
  __asm__ __volatile("cld\n\t"
		     "rep\n\t"
		     "movsl\n\t"
		     :"=&c" (d0), "=&S" (d1), "=&D" (d2)
		     :"0" (PAGE_SIZE/4),"1" (from),"2" (to)
		     :"memory");
}

static unsigned short mem_map[PAGING_PAGES] = {0,};


/*
 * Get physical address of first (actually last :-) free page, and mark it
 * used. If no free pages left, return 0.
 */
unsigned long get_free_page(void)
{
  register unsigned long __res;

  __asm__ __volatile__("std ; repne ; scasw\n\t"
		       "jne 1f\n\t"
		       "movw $1,2(%%edi)\n\t"
		       "sall $12,%%ecx\n\t"
		       "movl %%ecx,%%edx\n\t"
		       "addl %2,%%edx\n\t"
		       "movl $1024,%%ecx\n\t"
		       "leal 4092(%%edx),%%edi\n\t"
		       "rep ; stosl\n\t"
		       "movl %%edx,%%eax\n"
		       "1:"
		       :"=a" (__res)
		       :"0" (0),"i" (LOW_MEM),"c" (PAGING_PAGES),
			"D" (mem_map+PAGING_PAGES-1)
		       :"dx");
  return __res;
}

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


/*
 * This function puts a page in memory at the wanted address.
 * It returns the physical address of the page gotten, 0 if
 * out of memory (either when trying to access page-table or
 * page.)
 */
unsigned long put_page(unsigned long page, unsigned long address)
{
  unsigned long tmp, *page_table;

  /* NOTE!!! This uses the fact that _pg_dir = 0 */
  if (page < LOW_MEM || page > HIGH_MEMORY)
    printk("Trying to put page %p at %p\n", page, address);
  if (mem_map[(page - LOW_MEM) >> 12] != 1)
    printk("mem_map disagrees with %p at %p\n", page, address);
  page_table = (unsigned long *) ((address >> 20) & 0xffc);
  if ((*page_table) & 1)
    page_table = (unsigned long *) (0xfffff000 & *page_table);
  else {
    if (!(tmp = get_free_page()))
      return 0;
    *page_table = tmp | 7;
    page_table = (unsigned long *) tmp;
  }
  page_table[(address >> 12) & 0x3fff] = page | 7;
  return page;
}

void un_wp_page(unsigned long *table_entry)
{
  unsigned long old_page, new_page;

  old_page = 0xfffff000 & *table_entry;
  if (old_page >= LOW_MEM && mem_map[MAP_NR(old_page)] == 1) {
    *table_entry |= 2;
    return;
  }
  if (!(new_page = get_free_page()))
    do_exit(SIGSEGV);
  if (old_page >= LOW_MEM)
    mem_map[MAP_NR(old_page)]--;
  *table_entry = new_page | 7;
  copy_page(old_page, new_page);
}

/*
 * This routine handles present pages, when users try to write
 * to a shared page. It is done by copying the page to a new address
 * and decrementing the shared-page counter for the old page.
 */
void do_wp_page(unsigned long error_code, unsigned long address)
{
  un_wp_page((unsigned long *) (((address >> 10) & 0xffc) + (0xfffff000 & *((unsigned long *) ((address >> 20) & 0xffc)))));
}


void do_no_page(unsigned long error_code, unsigned long address)
{
  unsigned long tmp;

  if ((tmp = get_free_page()))
    if (put_page(tmp, address))
      return;
  do_exit(SIGSEGV);
}