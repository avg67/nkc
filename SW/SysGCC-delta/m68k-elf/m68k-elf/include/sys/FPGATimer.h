/*- FPGA_Timer definitions
 *
 * Copyright (C) 1991	Andreas Voggeneder
 */
/*-
 * Date		Version	Action						Who
 * 12.02.1991	1.00	created						avg
 */
#ifndef FPGA_TIMER_H
#define FPGA_TIMER_H

#ifndef FPGA_TIMER_PADDING
#ifdef PADDING
#define FPGA_TIMER_PADDING PADDING
#else
#error "padding not defined"
#endif
#endif

#if FPGA_TIMER_PADDING == 0
#define _(x) volatile unsigned char (x);
#else
#define _(x) volatile unsigned char (x); unsigned char _pad_ ## x [FPGA_TIMER_PADDING];
#endif

typedef struct fpga_timer {
    _(ctrl)
    _(th)
    _(tl)
} FPGA_TIMER;
#undef _

#endif