/*-
 * Copyright (C) 1991	Andreas Voggeneder
 */
/*- NDR definitions */

#ifndef TARGET_H
#define TARGET_H

//#include "nkc/nkc.h"
/* 1 (68008), 2 (68000), 4 (68020) */

#define cpu 1
//#define cpu 2

#if (cpu==2)
 #define PADDING         1  // 16bit bis (68000)
#elif (cpu == 1)
 #define PADDING         0  // 8bit bis (68008)
#else 
 #error "Not supported Configuration"
#endif


//#define VIA_PADDING     PADDING
//#include <sys/via6522.h>
#define FPGA_TIMER_PADDING     PADDING
#include <sys/fpgatimer.h>
#define SC_PADDING     PADDING
#include <sys/sc6551.h>
#define GDP_PADDING     PADDING
#include <sys/gdp9366.h>
#define RTC_PADDING     PADDING
#include <sys/soundchip.h>
#define SOUNDCHIP_PADDING   PADDING
#include <sys/key.h>
#define KEY_PADDING   PADDING
#include <sys/ioe.h>
#define IOE_PADDING   PADDING

#define INST_PER_SEC    300000L
#define VECTOR_NUMBER   64

#define RAM_BASE        0x0L
#define RAM_MINSIZE     0x8000L
#define RAM_MAXSIZE     0x80000L
#define RAM             ( *(unsigned char(*)[RAM_MAXSIZE])RAM_BASE )

#define ROM_BASE        0x400L
#define ROM_MINSIZE     0x10000L
#define ROM_MAXSIZE     0x7c000L
#define ROM             ( *(const unsigned char(*)[ROM_MAXSIZE])ROM_BASE )

#define TARGET_NAME     "ndrcomp"
#ifndef ndrcomp
#define ndrcomp
#endif
#ifndef __MC68000__
#define __MC68000__
#endif

/* special */
//#define VIA             (*(volatile VIA6522 *)(0xffffff90L <<CPUTYPE))
#define FPGAT1          (*(volatile FPGA_TIMER *)(0xfffffff4L <<PADDING))
#define GDP_Ctrl        (*(volatile GDP_Page *)(0xffffff60L <<PADDING))
#define GDP             (*(volatile GDP9366 *)(0xffffff70L <<PADDING))
#define GDP_Col         (*(volatile GDP_Col *)(0xffffffA0L <<PADDING))
#define SC              (*(volatile SC6551 *)(0xfffffff0L <<PADDING))
#define SOUND           (*(volatile SOUNDCHIP *)(0xffffff50L <<PADDING))
#define KEY             (*(volatile KEY *)(0xffffff68L <<PADDING))
#define IOE             (*(volatile IOE *)(0xffffff30L <<PADDING))




#define DEVICE_NAMES    {"tty0", (char *)0}; 
 


#endif
