/**
 * @file   boot.h
 * @brief  Generally useful bootloader values.
 * @author Mike Kasick <mkasick@andrew.cmu.edu>
 */

#ifndef BOOT_H
#define BOOT_H

/* Video interrupt related. */
#define VIDEO_INT          0x10
#define READ_CURSOR_POS_AH 0x03
#define WRITE_TELETYPE     0x0e
#define WRITE_STRING_AH    0x13
#define MOVE_CURSOR_AL     0x01
#define LGRAY_ATTRIB       0x07

/* Memory size interrupt related. */
#define LOW_MEM_SIZE_INT  0x12

/* Disk interrupt related. */
#define DISK_INT          0x13
#define RESET_DISK_SYS_AH 0x00
#define READ_SECTORS_AH   0x02

/* "System" interrupt related. */
#define SYSTEM_INT       0x15
#define A20_GATE_AH      0x24
#define DISABLE_AL       0x00
#define ENABLE_AL        0x01
#define EISA_MEM_SIZE_AX 0xe801

#define RM_STACK_TOP 0x7000
#define PM_STACK_TOP 0x0000f000

/* boot1 related. */
#define BOOT1_START_ADDR 0x1000
#define BOOT1_START_SEC  2
#define BOOT1_SECTORS    17

/* kernel related. */
#define KERNEL_PRELOAD_ADDR 0x0000f000
#define KERNEL_MAX_SIZE     0x00090000
#define KERNEL_START_CYL    1
#define KERNEL_CYLINDERS    32

/* Disk loader (CHS) data. */
#define DISK_BUFFER_ADDR   0x8000
#define BYTES_PER_SECTOR   512
#define SECTORS_PER_TRACK  18
#define BYTES_PER_TRACK    (BYTES_PER_SECTOR * SECTORS_PER_TRACK)
#define HEADS              2
#define BYTES_PER_CYLINDER (HEADS * BYTES_PER_TRACK)

/* Protected mode related. */
#define CR0_PROTECTION_ENABLE  0x00000001
#define CR0_PROTECTION_DISABLE 0xfffffffe

#endif
