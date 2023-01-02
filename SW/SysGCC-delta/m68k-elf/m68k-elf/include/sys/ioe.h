/*- IOE definitions
 *
 * Copyright (C) 1991	Andreas Voggeneder
 */
/*-
 * Date		Version	Action						Who
 * 12.02.1991	1.00	created						avg
 */
#ifndef IOE_H
#define IOE_H

#ifndef IOE_PADDING
#ifdef PADDING
#define IOE_PADDING PADDING
#else
#error "padding not defined"
#endif
#endif

#if IOE_PADDING == 0
#define _(x) volatile unsigned char (x);
#else
#define _(x) volatile unsigned char (x); unsigned char _pad_ ## x [IOE_PADDING];
#endif

typedef struct ioe {
    _(port_a)
    _(port_b)
} IOE;
#undef _

#endif