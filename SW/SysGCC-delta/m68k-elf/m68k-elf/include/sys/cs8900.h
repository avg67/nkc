/*- CS8900 (8 bit-mode) definitions
 *
 * Copyright (C) 1991	Andreas Voggeneder
 */
/*-
 * Date		Version	Action						Who
 * 12.02.1991	1.00	created						avg
 */

#ifndef CS_PADDING
#ifdef PADDING
#define CS_PADDING PADDING
#else
#error "padding not defined"
#endif
#endif

#if CS_PADDING == 0
#define _(x) volatile unsigned char (x);
#else
#define _(x) volatile unsigned char (x); unsigned char _pad_ ## x [CS_PADDING];
#endif

typedef struct cs8900 {
    _(rxtx_data0_l) // 0  R/W
    _(rxtx_data0_h) // 1
    _(rxtx_data1_l) // 2  R/W
    _(rxtx_data1_h) // 3
    _(txcmd_l)      // 4  W
    _(txcmd_h)      // 5
    _(txlen_l)      // 6  W
    _(txlen_h)      // 7
    _(isq_l)        // 8  R
    _(isq_h)        // 9
    _(add_l)        // A  R/W
    _(add_h)        // B
    _(data0_l)      // C  R/W
    _(data0_h)      // D
    _(data1_l)      // E  R/W
    _(data1_h)      // F
} CS8900;
#undef _
