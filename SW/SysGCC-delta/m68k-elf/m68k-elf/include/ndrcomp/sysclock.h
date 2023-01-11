/*-
 * Copyright (C) 1991	Andreas Voggeneder
 */

#ifndef _CLOCKSYS_H
#define _CLOCKSYS_H

#define CLOCKS_PER_SEC 200
#ifdef __cplusplus
  extern "C" clock_t _clock(void (*clock_fu)(void));
#else 
  clock_t _clock(void (*clock_fu)(void));
#endif

#endif
