extern inline unsigned char get_fs_byte(const char * addr);
extern inline unsigned short get_fs_word(const unsigned short *addr);
extern inline unsigned long get_fs_long(const unsigned long *addr);
extern inline void put_fs_byte(char val,char *addr);
extern inline void put_fs_word(short val,short * addr);
extern inline void put_fs_long(unsigned long val,unsigned long * addr);
