/*
,-----------------------------------------------------------------------------------------.
|
| Ethernet device driver for the CS8900 in 8-bit mode
|
| Author: Andreas Voggeneder
| Date:   2023/02/18
|
|
|-----------------------------------------------------------------------------------------
|
| License:
| This program is free software; you can redistribute it and/or modify it under
| the terms of the GNU General Public License as published by the Free Software
| Foundation; either version 2 of the License, or (at your option) any later
| version.
| This program is distributed in the hope that it will be useful, but
|
| WITHOUT ANY WARRANTY;
|
| without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
| PURPOSE. See the GNU General Public License for more details.
|
| You should have received a copy of the GNU General Public License along with
| this program; if not, write to the Free Software Foundation, Inc., 51
| Franklin St, Fifth Floor, Boston, MA 02110, USA
|
| http://www.gnu.de/gpl-ger.html
|
`-----------------------------------------------------------------------------------------*/
#include <string.h>
#include <stdint.h>
#include "cs8900_eth.h"
#include "net.h"
//#define _DEBUG_

//-----------------------------------------------------------------------------

//const uint8_t mymac[6] __attribute__ ((aligned (2))) = {MYMAC1, MYMAC2, MYMAC3, MYMAC4, MYMAC5, MYMAC6};

//uint8_t remote_mac[6] __attribute__ ((aligned (2))) = {0u};  // used as temp.
//-----------------------------------------------------------------------------

/*typedef union {
    uint16_t us[2];
    uint8_t  ub[5];
} t_cs_hdr;*/

//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------

static inline void cs_reset(void)
{
    CS_DEBUG("CS8900-Reset\r\n");
    Write_PP_8900(PP_SelfCTL, POWER_ON_RESET);    // Soft-Reset the Ethernet-Controller

    while (!(Read_PP_8900(PP_SelfST) & INIT_DONE));    // wait until chip-reset is done
}

/**********************************************************************************
* uchar net_match_ulong(unsigned long m)
*
* function, that returns 0 only if the nrext read word from the Ethernet matches
* matches a fixed one
**********************************************************************************/
/*static inline bool net_match_ulong(const uint32_t m){
    if(Read_Frame_long()!=m) return true;
    return false;	// MATCH!
}*/
/**********************************************************************************
* uchar net_match_uint(uint m){
*
* function, that returns 0 only if the next read long from the Ethernet matches
* matches a fixed one
**********************************************************************************/
/*static inline bool net_match_uint(const uint32_t m){
    if(Read_Frame_word()!=m) return true;
    return false;	// MATCH!
}*/

#if 0 //(cpu==2)
    // optimized version - only for 68000 (16bit)
    void write_frame_data_8900(const uint8_t* ps, const uint16_t len)
    {
        register uint16_t nr_words asm("%d1") = (len>>1u)-1u;   // prepare for dbra
        register const uint8_t* addr asm("%a1") = ps;

            asm volatile(
            "# asm"                 "\n\t" \
            "lea %0,%%a0"           "\n\t" /*CS8900.data0_l*/ \
    /*"wf1_%=: movew %%a1@+,%%d0"*/     "\n\t" \
    "wf1_%=: moveb %%a1@+,%%d0"     "\n\t" \
            "lslw #8,%%d0"          "\n\t" \
            "moveb %%a1@+,%%d0"     "\n\t" \
            "movepw %%d0,0(%%a0)"   "\n\t" \
            "dbra %%d1,wf1_%="      "\n\t" \
            "movew %1,%%d0"         "\n\t" /*len*/ \
            "btstb #0,%%d0"         "\n\t" \
            "beqs wf2_%="           "\n\t" \
            "moveb %%a1@,(%%a0)"    "\n\t" \
    "wf2_%=:" \
            : "=m"(CS8900.rxtx_data0_l) /* outputs */    \
            : "g"(len),"g"(nr_words),"g"(addr)               /* inputs */    \
            : "d0","a0"    /* clobbered regs */ \
            );
    }

    // optimized version - only for 68000 (16bit)
    void  read_frame_data_8900(uint8_t* ps, const uint16_t len)
    {
        register uint16_t nr_words asm("%d1") = (len>>1u)-1u;   // prepare for dbra
        register uint8_t* addr asm("%a1") = ps;

            asm volatile(
            "# asm"                  "\n\t" \
            "lea %0,%%a0"            "\n\t" /*CS8900.data0_l*/ \
    "rf1_%=: movepw 0(%%a0),%%d0"    "\n\t" \
            "movew %%d0,%%a1@+"      "\n\t" \
            "dbra %%d1,rf1_%="       "\n\t" \
            "movew %1,%%d0"          "\n\t" /*len*/ \
            "btstb #0,%%d0"          "\n\t" \
            "beqs rf2_%="            "\n\t" \
            "moveb (%%a0),%%a1@"     "\n\t" \
    "rf2_%=:" \
            : "=m"(CS8900.rxtx_data0_l) /* outputs */    \
            : "g"(len),"g"(nr_words),"g"(addr)               /* inputs */    \
            : "d0","a0"    /* clobbered regs */ \
            );
    }
#else
    void __attribute__((optimize("-O3"))) write_frame_data_8900(const uint8_t* ps, const uint16_t len)
    {
        uint16_t nr_words = len>>1u;
        const uint8_t* p_ptr = ps;
        while(nr_words) {
            //const uint8_t hib=*ps++;
            //const uint8_t lob=*ps++;
            //Write_Frame_word(((uint16_t)hib<<8u) | lob);
            CS8900.rxtx_data0_l = *p_ptr++;
            CS8900.rxtx_data0_h = *p_ptr++;
            nr_words--;
        }
        // write also last byte if len is odd
        if(len&1u) {
            CS8900.rxtx_data0_l = *p_ptr;
        }
    }

    void  read_frame_data_8900(uint8_t* ps, const uint16_t len)
    {
        uint16_t nr_words = len>>1u;
        uint8_t* p_ptr = (uint8_t*)ps;
        if (nr_words > 0u) {
            do {
                const uint8_t temp_l = CS8900.rxtx_data0_l;
                const uint8_t temp_h = CS8900.rxtx_data0_h;
                *p_ptr++ = temp_l; //CS8900.rxtx_data0_l;
                *p_ptr++ = temp_h; //CS8900.rxtx_data0_h;
                //*p_ptr++ = (uint16_t)CS8900.rxtx_data0_l | (((uint16_t)CS8900.rxtx_data0_h << 8u));
            }while(--nr_words);
        }
        // read also last byte if len is odd
        if(len & 1u) {
            *p_ptr++ = CS8900.rxtx_data0_l;
        }
    }
#endif


/*void print_reg(uint16_t reg, uint8_t nr) {
    if(!nr) return;
    CS_DEBUG("0x%04x = ",reg);
    do {
        const uint16_t val= Read_PP_8900(reg);
        CS_DEBUG("0x%04x ",val);
        reg+=2;
    }while(--nr);
    putchar('\n');
}

void print_debug(void)
{
    print_reg(PP_LineST,1);
    print_reg(PP_SelfST,1);
    print_reg(PP_RxCTL,1);
    print_reg(PP_LineCTL,1);
    print_reg(PP_RxStatus,1);
    print_reg(PP_RxCFG,1);
    print_reg(PP_RxMiss,1);
    print_reg(PP_BusCTL,1);
    print_reg(PP_IA,3);
}*/

//-----------------------------------------------------------------------------

uint8_t cs_init(void)
{
    const uint16_t chip_id = Read_PP_8900(PP_ChipID);
    CS_DEBUG("CS8900-ID: 0x%04X\r\n",chip_id);
    if(chip_id!=CHIP_ID) {
        return 0xffu;		// Failed to read CS8900A's ID!
    }
    cs_reset();

    // Read individual MAC from Array and set...
    const uint16_t* pmac = (const uint16_t*)my_mac;
    for(uint16_t ui=PP_IA;ui<PP_IA+6u;ui+=2u){
        const uint16_t mac=to_bendian16(*pmac++);
        //const uint16_t mac=*pmac++;
        //CS_DEBUG("CS8900-MAC 0x%04X = 0x%04X\r\n",ui,mac);
        Write_PP_8900(ui, mac);     // Write MAC
    }

    Write_PP_8900(PP_RxCTL, RX_OK_ACCEPT | RX_IA_ACCEPT | RX_BROADCAST_ACCEPT);
    Write_PP_8900(PP_TestCTL, FDX_8900);		// Full Duplex
    Write_PP_8900(PP_LineCTL, SERIAL_RX_ON | SERIAL_TX_ON);	// Transciever ON

    //print_debug();

    /*uint8_t data[]={0x12,0x34,0x56,0x78,0x9A};
    //write_frame_data(data, sizeof(data));
    //CS_DEBUG("Test1: 0x%X\r\n", Read_Frame_long());

    //read_frame_data(data, sizeof(data));
    //request_send(100);
    cs_send_packet(sizeof(data),data);*/

    return 0u;
}

void RequestSend_8900(const uint16_t frame_size){
  Write_8900(CS8900.txcmd_l, TX_START_ALL_BYTES);
  Write_8900(CS8900.txlen_l, frame_size);
  uint8_t del=0;
  while (!(Read_PP_8900(PP_BusST) & READY_FOR_TX_NOW)){
    del++;
    if(!del) {
        CS_DEBUG("Timeout request_send\r\n");
        break;
    }
  }
}

/*Order howto send an Frame:
    1. request_send
    2. write_frame_data
*/

#if 0
void cs_send_packet( uint16_t len, const uint8_t * buf )
{
    RequestSend_8900(len);
    write_frame_data(buf,len);
}


uint16_t __attribute__((optimize("-O3"))) cs_receive_packet( uint16_t bufsize, uint8_t *buf )
{
    /*
    50 bytes frame:
    - 2 bytes Status
    - 2 bytes Length
    - 6 Byte source address
    - 6 Byte dest address
    - 2 bytes length or Type
    - 46 bytes of data
    */
#ifdef LEVEL2_DEBUG
    char ch;
    do {
        ch = gp_ci();
        if ((ch=='i') && (p_debug_info!=NULL)) {
            iprintf("NR-Frames: %u\r\n",p_debug_info->nr_frames);
            for(uint16_t i=0u;i<p_debug_info->nr_frames;i++) {
                const uint8_t* const tmp = p_debug_info->p_buf[i];
                iprintf("Frame %u:"i);
                for(uint16_t j=0u;j<20u;j++) {
                    CS_DEBUG("%02X ",tmp[j]);
                }
                iprintf("\r\n");
            }
        }
    }while(ch=='i');

    if (p_debug_info == NULL) {
        p_debug_info = (t_debug*)0x1e3000u;
        p_debug = (uint8_t*)0x1e3100u;
        memset(p_debug_info,0u,sizeof(t_debug));
        p_debug_info->p_buf[0u] = p_debug;
        p_debug_info->nr_frames = 1u;

    }else{
        if (p_debug_info->nr_frames == ARRAY_SIZE(p_debug_info->p_buf)) {
            exit(0);
        }
        p_debug = p_debug_info->p_buf[p_debug_info->nr_frames] = (uint8_t*)((uint32_t)p_debug + bufsize);
        p_debug_info->nr_frames++;


    }
    memset(p_debug,0u, bufsize);
#endif
    //uint8_t rxheader[5] __attribute__ ((aligned (2))) ={0u};
    //read_frame_data( (uint8_t*)rxheader, sizeof(rxheader) );
    //uint16_t len                  = *((uint16_t*)&rxheader[2]);
    t_cs_hdr rx_hdr;
    read_frame_data( (uint8_t*)rx_hdr.ub, 5u );
    uint16_t len = rx_hdr.us[1u];

#ifdef _DEBUG_
    uint16_t status               = rx_hdr.us[0u]; //*((uint16_t*)&rxheader[0]);

    CS_DEBUG("HEADER: 0x%04X 0x%04X\r\n",status,len);
#endif
    // skip the checksum (4 bytes) at the end of the buffer
    len -= 4;

    // if the application buffer is to small, we just truncate
    if( len > bufsize ) len = bufsize;
    //memset(buf,0u, bufsize);
    // now read the packet data into buffer
    read_frame_data( buf, len );
#ifdef _DEBUG_
    for(uint16_t i=0u;i<20u;i++) {
        CS_DEBUG("%02X ",buf[i]);
    }
    CS_DEBUG("\r\n");
#endif

    /*(void)Read_FrameHL_word(); 		// Skip Status HL						2
    const uint16_t len=Read_FrameHL_word(); 	// Read Length HL (delivered >= 60!)	2
    read_frame_data(buf,6);*/

    /*Read_Frame_word(); 		// Skip OUR MAC... (6 Bytes)			2
    Read_Frame_long();										//		4
    read_frame_data(&remote_mac[0],6); // Read Sender's MAC			6
    uint16_t type=Read_Frame_word();
    CS_DEBUG("Remote MAC: %02x:%02x:%02x:%02x:%02x:%02x\n", remote_mac[0],remote_mac[1],remote_mac[2],remote_mac[3],remote_mac[4],remote_mac[5]);
    CS_DEBUG("Type %x %x\n",type,len);
    if(type<=0x5DC){ // SNAP Frame! Eat LSAP-Ctrl-OUI and retry...
        if(net_match_uint(0xAAAA)) return 0;							//  (2)
        if(net_match_ulong(0x3000000)) return 0;						//  (4)
        type=Read_Frame_word(); // Read NEW type...					(2)
                                                                        //  = 20
    }*/
    CS_DEBUG("cs_receive: %u bytes\n\r", len);
    return len;
}
#endif
