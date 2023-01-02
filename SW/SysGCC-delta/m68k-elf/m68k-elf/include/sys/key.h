/*- Keys definitions
 *
 * Copyright (C) 1991	Andreas Voggeneder
 */
/*-
 * Date		Version	Action						Who
 * 12.02.1991	1.00	created						avg
 */
#ifndef KEY_H
#define KEY_H

#ifndef KEY_PADDING
#ifdef PADDING
#define KEY_PADDING PADDING
#else
#error "padding not defined"
#endif
#endif

#if KEY_PADDING == 0
#define _(x) volatile unsigned char (x);
#else
#define _(x) volatile unsigned char (x); unsigned char _pad_ ## x [KEY_PADDING];
#endif

typedef struct key {
    _(reg)
    _(dipsw)
} KEY;
#undef _

#endif