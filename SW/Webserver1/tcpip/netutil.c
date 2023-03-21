/* $Author: hse00045 $                                  */
/* $Date: 2004/08/22 19:31:38 $                         */
/* Description: TCP/IP Stack, network utils   	        */
/*                                                      */
/* Remarks:     No remarks.                             */
/*                                                      */

//#pragma src

#include <stdio.h>

#include "cs8900_eth.h"		// Utilities
#include "netutil.h"		// Utilities


#define NETUTIL_DEBUG(...)
//#define NETUTIL_DEBUG iprintf

/**********************************************************************************
* uchar net_match_ulong(unsigned long m)
*
* function, that returns 0 only if the nrext read word from the Ethernet matches
* matches a fixed one
**********************************************************************************/
unsigned char net_match_ulong(unsigned long m){
    if(Read_Frame_long_8900()!=m) return 1;
    return 0;	// MATCH!
}
/*************************** consm){
*t
* function, that returns 0 only if the next read long from the Ethernet matches
* matches a fixed one
**********************************************************************************/
unsigned char net_match_uint(uint16_t m){
    if(Read_Frame_word_8900()!=m) return 1;
    return 0;	// MATCH!
}

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

/*
// **********************************************************************************
// unsigned int ip_check(xdata uchar* ps, uint len);
// unsigned int ip_check_more(xdata uchar* ps, uint len, uint old_cs);
//
// Calculate an IP Checksum of Xram Block Block ,
// Used Assembler: This is really FAST!
// ip_check_more: Takes a given CS and adds some more bytes. This is necessary
// for TCP-segments (and optional UDP too), if data are not in a continous block...
// ip_check_more is only allowed if previously an even number of bytes was read...
// **********************************************************************************
#pragma asm
	PUBLIC _ip_check
	.export _ip_check, _ip_check_more
_ip_check:		; Adr: R6:R7, len: R4:R5, tmp: B
	clr A		; R6:7 working reg. (delayed in R2:3)
	mov R2,A
	mov R3,A

_ip_check_more:		; Adr: R6:R7, len: R4:R5, tmp: B, old_cs in R2:R3
	mov DPL,R7
	mov DPH,R6
	mov R6,2	; CS Working register, copy from R2
	mov R7,3	; R3
	mov B,#0	;
	mov A,R4	; omit 0 words len
	orl A,R5
	jz ?csx
	mov A,R5	; prepare to use 2 djnz
	jz ?cs1
	inc R4
?cs1:	movx A,@DPTR
	inc DPTR
	jnb B.0,?csh
	add A,R7
	mov R7,A
	jnc ?cs2
	inc R6
	mov A,R6
	jnz ?cs2
	inc R7
	sjmp ?cs2
?csh:	add A,R6
	mov R6,A
	jnc ?cs2
	inc R7
	mov A,R7
	jnz ?cs2
	inc R6
?cs2:	inc B
	djnz R5,?cs1
	djnz R4,?cs1
?csx:
	ret
#pragma endasm

// **********************************************************************************
// void xram_fast_copy(xdata uchar* src,xdata uchar* dest,uint size);
//
// Copy size data in XRAM
// **********************************************************************************
void xram_fast_copy(unsigned char xdata* src,unsigned char xdata* dest,unsigned int size);
#pragma asm
	PUBLIC _xram_fast_copy
	;.export _xram_fast_copy
_xram_fast_copy:
	; src in R6/R7
	; dest in R4/R5
	; len in R2/R3
	mov A,R3	; prepare to use 2 djnz
	jz ?xfc1
	inc R2
?xfc1:	; get from source byte
	mov DPL,R7
	mov DPH,R6
	movx A,@DPTR
	inc DPTR
	mov R7,DPL
	mov R6,DPH
	; write to dest byte
	mov DPL,R5
	mov DPH,R4
	movx @DPTR,A
	inc DPTR
	mov R5,DPL
	mov R4,DPH
	; loop
	djnz R3,?xfc1
	djnz R2,?xfc1
	ret
#pragma endasm
*/

// END