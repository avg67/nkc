/*- NDR- Time System- Function definitions
 *
 * Copyright (C) 1991	Andreas Voggeneder

 */
/*-
 * Date		Version	Action						Who
 * 12.02.1991	1.00	created						avg
 */
#ifndef _NDRCLOCK
#define _NDRCLOCK

typedef struct {
    unsigned char hour;
    unsigned char min;
    unsigned char day;
    unsigned char mon;
    unsigned char year;
    unsigned char week;
    unsigned char sec;
    unsigned char hsec;
	long tmp;
}ndrtimebuf;
#undef _
#endif