/* $Author: Andreas Voggeneder $                        */
/* $Date: 2004/08/22 19:31:38 $                         */
/* Description: TCP/IP Stack, network utils   	        */
/*                                                      */
/* Remarks:     No remarks.                             */
/*                                                      */

//#pragma src

#include <stdio.h>

#include "netutil.h"		// Utilities


#define NETUTIL_DEBUG(...)
//#define NETUTIL_DEBUG iprintf

uint16_t ip_check_more(uchar const* ps, uint16_t len, uint16_t old_cs)
{
    register uint32_t result32 = (uint32_t)old_cs;
    while(len>1u) {
        uint16_t temp = *((uint16_t*)ps);
        //Addiert packet mit vorherigen
        result32 += temp;
        ps +=2u;
        len -=2u;
    }
    //Ist der Wert len ungerade ist DataL = 0
    if(len > 0)
    {
        //schreibt Inhalt Pointer nach DATAH danach inc Pointer
        const uint8_t DataH=*ps;
        //erzeugt Int aus Data L ist 0 (ist nicht in der Berechnung) und Data H
        uint16_t temp = (DataH << 8u);
        //Addiert packet mit vorherigen
        result32 += temp;
    }
    //Komplementbildung (addiert Long INT_H Byte mit Long INT L Byte)
    result32 = ((result32 & 0x0000FFFFu)+ ((result32 & 0xFFFF0000u) >> 16u));
    result32 = ((result32 & 0x0000FFFFu)+ ((result32 & 0xFFFF0000u) >> 16u));
    const uint16_t result16 = (result32 & 0x0000FFFFu);
    NETUTIL_DEBUG("<CS:0x%04X>",result16);
    return (result16);
}

extern volatile clock_t _clock_value;

void _delay_ms(uint16_t delay) {
    const uint32_t end_time = _clock_value + (((uint32_t)delay * CLOCKS_PER_SEC) / 1000uL);
    //iprintf("time %d - %d",_clock_value,end_time);
    while(_clock_value < end_time) {
    };
}

// END