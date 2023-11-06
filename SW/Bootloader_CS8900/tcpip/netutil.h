/* $Author: Andreas Voggeneder $                        */
/* $Date: 2004/08/22 19:31:38 $                         */
/* Description: TCP/IP Stack, network utils   	        */
/*                                                      */
/* Remarks:     No remarks.                             */
/*                                                      */
#ifndef NETUTILS_H
#define NETUTILS_H

#include "net.h"
#include "cs8900_eth.h"		// Utilities
#include <time.h>

uint16_t ip_check_more(uchar const * ps, uint16_t len, uint16_t old_cs);
void _delay_ms(uint16_t delay);

//#define MIN(a,b) (((a)<(b))?(a):(b))
//#define MAX(a,b) (((a)>(b))?(a):(b))

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

/**********************************************************************************
* uchar net_match_ulong(unsigned long m)
*
* function, that returns 0 only if the nrext read word from the Ethernet matches
* matches a fixed one
**********************************************************************************/

static inline bool net_match_uint(uint16_t m)
{
    return (Read_Frame_word_8900()!=m); //?true:false;
}

/**********************************************************************************
* function, that returns 0 only if the next read long from the Ethernet matches
* matches a fixed one
**********************************************************************************/
static inline bool net_match_ulong(uint32_t m)
{
    return (Read_Frame_long_8900()!=m);
}

#endif
// END