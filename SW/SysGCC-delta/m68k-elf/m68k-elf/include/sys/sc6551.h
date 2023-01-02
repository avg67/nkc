/*- SC 6551 definitions
 *
 * Copyright (C) 1991	Andreas Voggeneder
 */
/*-
 * Date		Version	Action						Who
 * 12.02.1991	1.00	created						avg
 */

#ifndef SC_PADDING
#ifdef PADDING
#define SC_PADDING PADDING
#else
#error "padding not defined"
#endif
#endif

#if SC_PADDING == 0
#define _(x) volatile unsigned char (x);
#else
#define _(x) volatile unsigned char (x); unsigned char _pad_ ## x [SC_PADDING];
#endif

typedef struct m6551 {
    _(data)
    _(status)
    _(command)
    _(control)
} SC6551;
#undef _
