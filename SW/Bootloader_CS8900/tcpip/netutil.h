/* $Author: Andreas Voggeneder $                        */
/* $Date: 2004/08/22 19:31:38 $                         */
/* Description: TCP/IP Stack, network utils   	        */
/*                                                      */
/* Remarks:     No remarks.                             */
/*                                                      */
#ifndef NETUTILS_H
#define NETUTILS_H

#include "net.h"
#include <time.h>

unsigned char net_match_ulong(unsigned long m);
unsigned char net_match_uint(uint16_t m);
//uint16_t ip_check(uchar const * ps, uint16_t len);
uint16_t ip_check_more(uchar const * ps, uint16_t len, uint16_t old_cs);
//void xram_fast_copy(unsigned char * src,unsigned char * dest,uint16_t size);
void _delay_ms(uint16_t delay);

#define MIN(a,b) (((a)<(b))?(a):(b))
#define MAX(a,b) (((a)>(b))?(a):(b))

#if 0
extern volatile clock_t _clock_value;

static inline void _delay_ms(uint16_t delay) {
    const uint32_t end_time = _clock_value + (((uint32_t)delay * CLOCKS_PER_SEC) / 1000uL);
    //iprintf("time %d - %d",_clock_value,end_time);
    while(_clock_value < end_time) {
    };
}
#endif

static inline uint16_t ip_check(uchar const * ps, uint16_t len)
{
    return (len>0u)?ip_check_more(ps, len, 0u):0u;
}

#endif
// END