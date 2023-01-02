/*-
 * Copyright (C) 1991	Andreas Voggeneder
 */

#ifndef _CLOCKSYS_H
#define _CLOCKSYS_H

#define CLOCKS_PER_SEC 200

extern clock_t _clock(void (*clock_fu)(void));

#endif
