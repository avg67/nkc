/* $Author: Andreas Voggeneder $                        */
/* $Date: 2003/14/02 19:31:38 $                         */
/* Description: TCP/IP Stack, UDP/TCP Functions	        */
/*                                                      */
/* Remarks:     No remarks.                             */
/*                                                      */

#include <stdio.h>
#include <string.h>

#define FLEXGATE
#define TIMER ((CLOCKS_PER_SEC * 36u) / 1000u)  //~35ms = ~28Hz

#include "cs8900_eth.h"  // CS8900 Register Definitions
#include "net.h"  // Basic network handling (public)
#include "netutil.h"  // Toolbox
#include "delay.h"

#define NET_DEBUG(...)
//#define NET_DEBUG iprintf

/**********************************************************************************
* Private structs
**********************************************************************************/
typedef struct{
    uint16_t vhl_service; // 0x45xx-0x4Fxx
    uint16_t len;
    uint16_t ident;
    uint16_t frags;
    uchar ttl;
    uchar pcol;
    uint16_t checksum;
    IP_ADR sip;
    IP_ADR dip;
} IP_HDR;

/**********************************************************************************
* Private Definitions (not in net.h)
**********************************************************************************/
#define TIMER_FRQ 22  // (exactly 22.888 @ 18 MHz) Timer Frequency in Hz (<512!)

/************ TCP Soecket states *************************/
//#define TCP_CLOSED  0 // 0 for all: Socket closed (and listen)

// ** Initial Server States
#define TCP_SYNCON  1   // Confirmed an incomming SYN
//#define TCP_EST  2    // Established, Connection OK

// ** Closing
#define TCP_FINSENT  3    // A FIN was sent. Wait for Acknowledge+FIN
#define TCP_FINCON 4    // Confirmed a FIN with FIN+ACK, waiting for last ACK

// ** Client States
#ifdef USE_TCP_CLIENT
 #define TCP_SYNSENT  5   // Arp was Ok, send SYN now
#endif

/************ UDP Socket states *************************/

#if defined(USE_TCP_CLIENT) || defined(USE_UDP_CLIENT)
/*********** ARP_STATES *********************/
 // IMPORTANT: ARP-States numerical > TCP/UDP/OTHER-STATES! because of Final Timeout!
 #define ARPSENT  6   // Client has sent an ARP
 #define ARPREC   7   // Received Reply for this ARP
  //#define UDP_EST  ARPREC  // For UDP Established is the same as ARP Received...

#endif

/* TCP-Option-Flags */
#define TFIN 0x01
#define TSYN 0x02
#define TRST 0x04
#define TPUSH 0x08
#define TACK 0x10
#define TURGE 0x20  // Flag ignored


// private prototypes
static void free_match_socket(UC_SOCKET* p_match_socket);


/**********************************************************************************
* OPTION DEFS: see net.h
**********************************************************************************/

/**********************************************************************************
* MAC-Level data
*
* Set a (default) MAC for THIS node
**********************************************************************************/
const uchar my_mac[6] __attribute__ ((aligned (2))) = {0x00, 0x51, 0xD3, 0xC4, 0xB5, 0xA6 }; // MAC for this machine: M0:M1:M2:M3:M4:M5

uchar remote_mac[6] __attribute__ ((aligned (2)));  // used as temp.


#if defined(USE_TCP_CLIENT) || defined(USE_UDP_CLIENT)
 uchar gateway_mac[6]; // optional Gateway for active oen of an "ouside" peer
#endif


/**********************************************************************************
* IP-Header-Level data
*
* Set a IP for THIS node
**********************************************************************************/
IP_ADR my_ip;    // IP for this machine (public)
IP_ADR remote_ip;   // Last read IP

#if defined(USE_TCP_CLIENT) || defined(USE_UDP_CLIENT)
IP_ADR subnet_ip;   // These two IPs require Setup!
IP_ADR gateway_ip;
#endif

//IP_HDR hhdr;    // Temporary header for sending IP-data

/**********************************************************************************
* ICMP/ARP-Level data
*
* ICMP is designed for Standard WIN-pings with 0-32 bytes. Enlarge structs if req.
**********************************************************************************/


typedef struct{ // Definition
    IP_ADR sip;
    IP_ADR dip;
    uint16_t pcol; // 6 for TCP, 17 for UDP
    uint16_t len;
} PSEUDO_HDR;


// Same variables for initial examination of incomming frames
typedef struct{ // Size: 20 Bytes
    MAC sender_mac;
    IP_ADR sender_ip;
    MAC target_mac;
    IP_ADR target_ip;
} ARP_INFO; // The informative Part of an ARP message...

typedef struct{ // Size: 40 Bytes
    uchar type;
    uchar icmp_code;
    uint16_t checksum;
    uint16_t ident; // Commonly unused
    uint16_t sequ; // dto.
    uchar d[32]; // large enough for a standard WINDOWS ping...
} PING_INFO;  // A frame for a standard PING

typedef struct{ // Size: 20 Bytes
    uint16_t sport; // Source port
    uint16_t dport; // Destination port

    WORD2_LONG seq; // Sequence ('my pointer');
    WORD2_LONG ack; // Acknowledge ('your pointer')

    uchar hlen; // TCP header len <<2 (==80 without Options)
    uchar flags; // option Flags TFIN-TURGE

    uint16_t window; // window size
    uint16_t checksum; //
    uint16_t urgent; // urgend pointer (commonly unused)
} TCP_HDR;

#ifdef USE_UDP
typedef struct{ // Size: 8 Bytes (Struct. Currently not used)
    uint16_t sport; // Source port
    uint16_t dport; // Destination port

    uint16_t mlen; // MessageLen
    uint16_t checksum; //
} UDP_HDR;
#endif

#define HFRAME_SIZE 40 // Large enough for the biggest header
typedef union{
    ARP_INFO  arp_info; // 2.nd Level
    PING_INFO ping_info; // 2.nd Level
    TCP_HDR  tcp_hdr; // 3.rd Level, remote IP in remote_ip, rest of IP_HDR known.
#ifdef USE_UDP
    UDP_HDR  udp_hdr; // 3.rd Level
#endif
    uchar bytes[HFRAME_SIZE]; // Bytes of "generic" access
} HFRAME;

// A Frame for temporary usage 2.nd and 3.rd level
HFRAME hframe;

/**********************************************************************************
* The timer, counts down with about 2 Hz
**********************************************************************************/
volatile uchar  net_timer; // Temporary value, counts down until by an IRQ
uchar  net_service_cnt; // Additional Timer, counts up. twice /sec.

/**********************************************************************************
* The 'official' buffers in XRAM
**********************************************************************************/

// RX-Buffer (1)
char rcv_buf[MAX_RX]  __attribute__ ((aligned (2)));   // Buffer for receiving data (Mainly HTTP-Header...)
uint16_t  rcv_len,rcv_ofs;    // Size of received data (int)

// TX-Buffers (x)
TX_BUFFER tx_buffers[TX_BUFFERS];
char tx_bufleft=TX_BUFFERS; // Counts left buffers





/**********************************************************************************
* This stack is designed to support a maximum of >8 simultaneous open sockets
*
* ** Only implemented as a fragment until now!
* ** later there will be a bit-mask holding the 'active' sockets
* ** ** Later socket types: SOCKET_NONE(==0), UDP(port), TCP(port), HTTP, TELNET, ...
*
**********************************************************************************/

//static UC_SOCKET match_socket;  // Temporary matching socket (Work-pad!)

// *** THE SOCKETS ***
UC_SOCKET uc_socket[MAX_SOCK];  // My (User's) Sockets!



#ifdef DEBUG_REC
/**********************************************************************************
* Debugging Stuff: Records sent and receiced frames
**********************************************************************************/

uint16_t rec_no;
typedef struct{
    uchar typ;  // 'R': Received, 'T' Transmitted, 't' Retransmitted, ...
    uint16_t port;
    unsigned long seq;
    unsigned long ack;
    uchar flags;
    uint16_t len;
} REC_FRAME;

REC_FRAME rec_frame[MAX_REC_FRAME];


/**********************************************************************************
* record_frame: Record 1 Frame
**********************************************************************************/
void record_frame(uchar typ, uint16_t port, unsigned long seq, unsigned long ack, uchar flags, uint16_t len){
    REC_FRAME *pr;
    if(rec_no==MAX_REC_FRAME) return;   // FULL!
    pr=rec_frame+rec_no;
    pr->typ=typ;
    pr->port=port;
    pr->seq=seq;
    pr->ack=ack;
    pr->flags=flags;
    pr->len=len;
    rec_no++;
}
/**********************************************************************************
* Show Frame, return 1  if data available
**********************************************************************************/
uchar show_frame(uint16_t no){
    uchar flags;
    REC_FRAME *pr;
    if(no>=rec_no) return 0;
    pr=rec_frame+no;
    printf("No:%u '%c' P:%u  S:%lu    A:%lu    ",no+1, pr->typ, pr->port,  pr->seq, pr->ack);
    flags=pr->flags;
    if(flags & TFIN) printf("FIN ");
    if(flags & TSYN) printf("SYN ");
    if(flags & TRST) printf("RST ");
    if(flags & TACK) printf("ACK ");

    printf("   L:%u\n",pr->len);
    return 1;   // OK!
}



#endif



/**********************************************************************************
* unsigned char * allocate_tx_buf(void);
*
* Find a free buffer, if one found, allocate it and return startadress,
* return 0 if none available!
**********************************************************************************/
TX_BUFFER * allocate_tx_buf(void){
    TX_BUFFER *pbuf=&tx_buffers[0];

    if(tx_bufleft) {
        for(uint16_t ui=0;ui<TX_BUFFERS;ui++,pbuf++){
            if(!(pbuf->allocated)) {
                pbuf->allocated=true; // Mark Buffer as allocated
                tx_bufleft--;
                return pbuf; // Return Startadress of buffer
            }
        }
    }
    puts("<No TX Buf>");
    return NULL; // Nothing found!
}

/**********************************************************************************
* void free_tx_buf(unsigned char * pbuf)
*
* Free TX-Buffer if not more required
**********************************************************************************/
void free_tx_buf(TX_BUFFER * pbuf){
    if(pbuf && pbuf->allocated){
        pbuf->allocated=false; // Buffer now free again...
        tx_bufleft++; // One more Buffer free...
    }
}


/**********************************************************************************
* void free_match_socket(void);
*
* Function for state transition to TCP_CLOSED for a socket, ensures freeing of the
* buffers!
**********************************************************************************/
static void free_match_socket(UC_SOCKET* p_match_socket){
    if(p_match_socket->buf_outsize1){
        p_match_socket->buf_outsize1=0u;
        free_tx_buf(p_match_socket->p_outbuf1);
    }
    if(p_match_socket->buf_outsize2){
        p_match_socket->buf_outsize2=0u;
        free_tx_buf(p_match_socket->p_outbuf2);
    }
    if(p_match_socket->buf_outsize3){
        p_match_socket->buf_outsize3=0u;
        free_tx_buf(p_match_socket->p_outbuf3);
    }
}


#if defined(USE_TCP_CLIENT) || defined(USE_UDP_CLIENT)

/**********************************************************************************
* void send_request_ARP for a specific Internet
*
* Send an ARP Request for a specific MAC
**********************************************************************************/
void send_request_ARP(unsigned long ipl){
    // NET_DEBUG("<ARP QUERRY>"); // Inform us...

    RequestSend_8900(42u);    // Send Reply

    Write_Frame_long_8900(0xFFFFFFFFu);  // To Broadcast
    Write_Frame_word_8900(0xFFFFu);    // To Broadcast

    write_frame_data_8900(my_mac,sizeof(my_mac));   // From US (MAC)

    Write_Frame_word_8900(0x0806u);   // ARP!

    Write_Frame_long_8900(0x10800u);   // Ethernet
    Write_Frame_long_8900(0x6040001u);  // Request

    write_frame_data_8900(my_mac,sizeof(my_mac));   // From US (MAC)
    Write_Frame_long_8900(my_ip.ipl);  // and IP!

    // Variable filled out by Host
    Write_Frame_long_8900(0xFFFFFFFFu);  // To Broadcast
    Write_Frame_word_8900(0xFFFFu);    // To Broadcast

    // If Our Mask and Destin. Mask differs in the significant netbits, querry MAC of Gateway
    if((ipl^my_ip.ipl)&subnet_ip.ipl) {
        Write_Frame_long_8900(gateway_ip.ipl); // and IP! (far connection over gatewy)
    }else{
        Write_Frame_long_8900(ipl);   // and IP! (local connection)
    }
}
#endif

/**********************************************************************************
* void process_ARP(void){
*
* 2.nd-Level-Multiplexer
* process an ARP request or (not implemented until now) an ARP reply
**********************************************************************************/
uint16_t process_ARP(void){
    #if defined(USE_TCP_CLIENT) || defined(USE_UDP_CLIENT)
        UC_SOCKET *psock;
        uchar ui;
    #endif

    uint16_t type;

    if(net_match_ulong(0x00010800u)) return EVENT_ARP_UNKNOWN; // No ARP!						// 4
    if(net_match_uint(0x0604u)) return EVENT_ARP_UNKNOWN; // No ARP!							// 2
    type=Read_Frame_word_8900();  																// 2
    // printf("ARP type %x\n",type);
    read_frame_data_8900(hframe.bytes,20u); 	// Read informative part of ARP message			   20
    if(type>2u) return EVENT_ARP_NOTYPE; 		// Unknown Reply

    if(type==1u){ // ARP Request!
        if(hframe.arp_info.target_ip.ipl!=my_ip.ipl) return EVENT_ARP_OTHER; // ARP, but not for us...

        NET_DEBUG("<ARP request>"); // Inform us...
        RequestSend_8900(42u);   // Send Reply

        write_frame_data_8900(remote_mac,sizeof(remote_mac));  // Kick packet back...
        write_frame_data_8900(my_mac,sizeof(my_mac));  // From US (MAC)
        Write_Frame_word_8900(0x0806u);  // ARP!

        Write_Frame_long_8900(0x00010800u);
        Write_Frame_long_8900(0x06040002u); // Response

        write_frame_data_8900(my_mac,sizeof(my_mac));  // From US (MAC)
        Write_Frame_long_8900(my_ip.ipl);  // and IP!

        write_frame_data_8900(hframe.bytes,10u);  // Sender MAC & Sender IP
        return EVENT_ARP_REQUEST;    // No Event of interest, but an EVENT

    }else{ // Arp response! For us?
#if defined(USE_TCP_CLIENT) || defined(USE_UDP_CLIENT)
    //  NET_DEBUG("<ARP response>");
    // Will work with all non-0 type sockets!
        psock=uc_socket;
        for(ui=0;ui<MAX_SOCK;ui++,psock++){
            if(psock->socket_type && psock->state==ARPSENT){
                // Only ARP-Sockets are of interest if an offered ip is matched
                if((psock->sremote_ip==hframe.arp_info.sender_ip.ipl) || // Either direct IP match
                // Or Response is from Gateway, if subnets differ
                ((  (psock->sremote_ip ^ my_ip.ipl) & subnet_ip.ipl  )&&(hframe.arp_info.sender_ip.ipl==gateway_ip.ipl))  ){

                    // Copy MAC
                    memcpy(psock->sremote_mac, hframe.arp_info.sender_mac, 6);
                    psock->state=ARPREC;

                    psock->retry_cnt=0;
                    psock->timer=1;  // Start NOW!

                    return EVENT_ARP_OURREPLY;

                }
            }
        }
#endif
        return EVENT_ARP_OTHERREPLY;
    }
}

/**********************************************************************************
* void process_ICMP(uint16_t dlen)
*
* 2.nd-Level-Multiplexer
* received an ICMp frame ('PING')
**********************************************************************************/
uint16_t process_ICMP(uint16_t dlen){
    //  MICROCHIP SAYS IT IS SAVE TO TRUNCATE ICMPs, so truncate...
    if(dlen>sizeof(HFRAME)) dlen=sizeof(HFRAME);  // Truncate too long Pings!

    read_frame_data_8900(hframe.bytes,dlen); // Read Sender's Data
    // printf("Type %bx\n",hframe.ping_info.type);
    if(hframe.ping_info.type==0u){
        // *** NOT REQUIRED FOR SERVER MODE! ***
        // NET_DEBUG("<ECHO REPLY ???>");
        return EVENT_ICMP_REPLY;

    }else if(hframe.ping_info.type==8u){
        //NET_DEBUG("<ICMP ECHO REQUEST>"); // For debugging...

        // Reflect block as reply
        hframe.ping_info.type=0u;
        hframe.ping_info.checksum=0u;
        hframe.ping_info.checksum=~ip_check(hframe.bytes,dlen);

        // Now, send out reply
        IP_HDR hhdr = {    // Temporary header for sending IP-data
            .vhl_service=0x4500u,
            .len=sizeof(IP_HDR)+dlen,
            .ident=0u,
            .frags=16384u, // No Fragmentation
            .ttl=100u, // Industrial standard
            .pcol=1u, // ICMP
            .checksum=0u,
            .sip.ipl=my_ip.ipl,
            .dip.ipl=remote_ip.ipl
        };

        hhdr.checksum=~ip_check((unsigned char *)&hhdr,sizeof(IP_HDR));

        RequestSend_8900(dlen+sizeof(IP_HDR)+14u); // Send Reply
        write_frame_data_8900(remote_mac,sizeof(remote_mac));  // Kick back...
        write_frame_data_8900(my_mac,sizeof(my_mac));  // From US (MAC)
        Write_Frame_word_8900(0x800u);  // type IP

        write_frame_data_8900((unsigned char *)&hhdr,sizeof(IP_HDR));  // Send Header
        write_frame_data_8900(hframe.bytes,dlen);  // and echo
        puts("PING");
        return EVENT_ICMP_REQUEST; // Someone has PINGED us!

    }else{
        return EVENT_ICMP_UNKNOWN; // Ignore the Rest...
    }
}


#ifdef USE_UDP
/**********************************************************************************
* void process_UDP(void)
*
* 3.rd-Level-Multiplexer
* Process the Header (and contents) of a UDP datagram.
*
* An UPD frame may arrive as broadcast, so treat is as non important first...
*
* Note: It is intended hframe my by used for synthesisinhg a response header...
*
**********************************************************************************/
uint16_t process_UDP(uint16_t dlen){
    const uint16_t udp_sport=Read_Frame_word_8900();
    const uint16_t udp_dport=Read_Frame_word_8900();
    if(net_match_uint(dlen)) return EVENT_UDP_ERROR; // a simple check for plausibility...
    Read_Frame_word_8900(); // Ignore CS...


    UC_SOCKET * psock=uc_socket;
    for(uint16_t ui=0u; ui < MAX_SOCK; ui++, psock++){
        if(psock->socket_type==SOCKET_UDP){  // Only UDP-Sockets are of interest
            // Test local port match
            if(psock->local_port==udp_dport){
                psock->sremote_port=udp_sport;  // Copy Sender's Sourceport
                psock->sremote_ip=remote_ip.ipl; // Copy Sender's IP
                memcpy(psock->sremote_mac, remote_mac, sizeof(remote_mac));
                dlen-=8u; // Subtract header length
                if(dlen > MAX_RX) break;   // Ignore too long frames...
                read_frame_data_8900((uint8_t*)rcv_buf,dlen);  // Read Sender's Data, if any
                rcv_len=dlen;    // remember size of read data...
                return EVENT_UDP_DATARECEIVED+ui;
            }
        }
    }

    // *********** Check local sockets for a match or return ...... ************
    return EVENT_UDP_UNSOLICITED; // None of our Sockets: RETURN
}

/**********************************************************************************
* void send_upd();
**********************************************************************************/
static inline void __attribute__((optimize("-O3"))) send_upd(const unsigned char * const dt, uint16_t len,unsigned char *pmac,unsigned long rem_ipl,uint16_t sport, uint16_t dport){
    // Now fill out IP-Header
    IP_HDR hhdr = {    // Temporary header for sending IP-data
        .vhl_service=0x4500u,
        .len=sizeof(IP_HDR)+8u+len, // 8 Bytes UDP-Header
        .ident=0u,
        .frags=16384u, // No Fragmentation
        .ttl=100u, // Industrial standard
        .pcol=17u, // UDP
        .checksum=0u,
        .sip.ipl=my_ip.ipl,
        .dip.ipl=rem_ipl
    };
    hhdr.checksum=~(ip_check((const uint8_t*)&hhdr,sizeof(IP_HDR))); // IP-Header only

    // Now, send out reply
    RequestSend_8900(sizeof(IP_HDR)+14u+8u+len); // Send Reply:  ETHERNET_HDR IP_HDR UDP_HDR +(data)
    write_frame_data_8900((unsigned char *)pmac,sizeof(remote_mac));  // Physical destination
    write_frame_data_8900(my_mac,sizeof(my_mac));  // From US (MAC)
    Write_Frame_word_8900(0x800u);  // type IP

    write_frame_data_8900((const uint8_t*)&hhdr,sizeof(IP_HDR));  // Send IP Header
    Write_Frame_word_8900(sport);
    Write_Frame_word_8900(dport);
    Write_Frame_word_8900(len+8u);  // Including UDP_HDR...
    Write_Frame_word_8900(0u);  // 0: Means: Checksum not computed

    write_frame_data_8900(dt,len);   // Send data
}
#endif

/**********************************************************************************
* void send_TCP();
*
* Will send a given Segment as IP-TCP-(DATA). ACK,SEQU,WINDOW,FLAGS must be set
* by the caller! TCP-Checksum is computed. MSS not regarded, because sure to be less
* than the rest of the network...
* Data for header in HFRAME already setup
**********************************************************************************/
void send_TCP(uchar * dt, uint16_t len, const uchar * const pmac, unsigned long rem_ipl){
    hframe.tcp_hdr.hlen=80u;   // Standard Size: 20 Bytes
    hframe.tcp_hdr.checksum=0u;

    // Used for TCP/IP-Checksums
    const PSEUDO_HDR pseudo_hdr = {
        .sip.ipl = my_ip.ipl,  // Built Pseudo-Header for Checksum
        .dip.ipl = rem_ipl,
        .pcol    = 6u, // TCP
        .len     = len + 20u   // Data+TCP-Header, without Pseudo-header!
    };

    const uint16_t data_cs=ip_check(dt,len); // Checksum of Data Block
    hframe.tcp_hdr.checksum = ~( // Checksum of Header, Datablock and Pseudo_header
    ip_check_more(hframe.bytes,20, // TCP-Header
        ip_check_more((unsigned char *)&pseudo_hdr,sizeof(PSEUDO_HDR),data_cs))
    ); // Data

    // Now fill out IP-Header
    IP_HDR hhdr = {    // Temporary header for sending IP-data
        .vhl_service=0x4500u,
        .len=sizeof(IP_HDR)+20u+len, // 20 Bytes TCP-Header (add MSS if required)
        .ident=0u,
        .frags=16384u, // No Fragmentation
        .ttl=100u, // Industrial standard
        .pcol=6u, // TCP
        .checksum=0u,
        .sip.ipl=my_ip.ipl,
        .dip.ipl=rem_ipl
    };

    hhdr.checksum=~(ip_check((unsigned char *)&hhdr,sizeof(IP_HDR))); // IP-Header only

    // Now, send out reply
    RequestSend_8900(sizeof(IP_HDR)+14+20+len); // Send Reply:  ETHERNET_HDR IP_HDR TCP_HDR +(data)


    write_frame_data_8900((const uint8_t *)pmac,sizeof(remote_mac));  // Physical destination
    write_frame_data_8900((const uint8_t *)my_mac,sizeof(my_mac));  	// From US (MAC)
    Write_Frame_word_8900(0x800u);  		// type IP

    write_frame_data_8900((const uint8_t *)&hhdr,sizeof(IP_HDR));  // Send IP Header
    write_frame_data_8900((const uint8_t *)hframe.bytes,20u);  // Send TCP Header
    write_frame_data_8900((const uint8_t *)dt,len);   	// Send data

#ifdef DEBUG_REC
    // Record Data of Transmitted Frame
    record_frame('T',hframe.tcp_hdr.dport,hframe.tcp_hdr.seq.u,hframe.tcp_hdr.ack.u, hframe.tcp_hdr.flags,len);
#endif

}

/**********************************************************************************
* void send_incomming_reset_TCP();
*
* Build reset-segment as reply without using match_socket, i.e. as denial for an
* incomming request... ACK included.
**********************************************************************************/
void send_incomming_reset_TCP(uint16_t dlen,uchar *pmac,unsigned long ipl){
    unsigned long ack;
    uint16_t sport;
    sport=hframe.tcp_hdr.dport;
    hframe.tcp_hdr.dport=hframe.tcp_hdr.sport; // Bounce port
    hframe.tcp_hdr.sport=sport;

    // Window, Flags and Set ACK and SEQU in the response, rest will be completed by send_tcp
    hframe.tcp_hdr.window=0;  // No reply!
    ack=hframe.tcp_hdr.seq.u+dlen;
    if(hframe.tcp_hdr.flags & (TSYN | TFIN)) ack++;
    hframe.tcp_hdr.seq.u=hframe.tcp_hdr.ack.u;
    hframe.tcp_hdr.ack.u=ack;
    hframe.tcp_hdr.flags=TRST+TACK;
    send_TCP(0u,0u,pmac,ipl); // Replay
}

/**********************************************************************************
* void send_match_ok_TCP();
*
* Build Segment header and send it as regular Header, Data are in *pdata, size alen
* match_socket must fit! hframe used as a temporary variable
**********************************************************************************/
void send_match_ok_TCP(unsigned char * const pdt, uint16_t dlen, uchar flags, const UC_SOCKET* const p_match_socket){
    unsigned long seq;

    hframe.tcp_hdr.sport=p_match_socket->local_port; // Our Port
    hframe.tcp_hdr.dport=p_match_socket->sremote_port; // Remote

    // Window, Flags and Set ACK and SEQU in the response, rest will be completed by send_tcp
    hframe.tcp_hdr.window=MAX_RX;  // Sender: Do not send more the MAX_RX

    seq=p_match_socket->sseq.u;
    if(flags & (TSYN)) seq--;  // If a SYN is sent, count this as 1
    hframe.tcp_hdr.seq.u=seq;

    hframe.tcp_hdr.ack.u=p_match_socket->sack.u; // This was received from the Sender
    hframe.tcp_hdr.flags=flags;

    // Send empty
    send_TCP(pdt,dlen,p_match_socket->sremote_mac, p_match_socket->sremote_ip );

 // iprintf("<TX P:%u A:%x S:%x F:%u, T:%u> ", hframe.tcp_hdr.dport, hframe.tcp_hdr.ack.w.l_word,hframe.tcp_hdr.seq.w.l_word,hframe.tcp_hdr.flags,p_match_socket->state);

}

/**********************************************************************************
* uint16_t state_machine_TCP(uint16_t dlen);
*
* 4.rd-Level-Multiplexer
*
* Process one step in the TCP-state-Machine. The 'match_socket' follows the
* TCP-State-Machine if its type is SOCKET_HTTP or SOCKET_TCP.
* The low_word of the sequence-number is the offset for SOCKET_HTTP. May wrap
* for SOCKET_TCP! So resending the sequence-number $zzzz0000 for SOCKET_HTTP implies
* resending the SYN!
* if this routine is called, destination/source port match already checked and
* 'match_socket' copied...
**********************************************************************************/
uchar flags_temp;

uint16_t state_machine_TCP(uint16_t dlen, UC_SOCKET* p_match_socket){

    if(hframe.tcp_hdr.flags&TRST){
        free_match_socket(p_match_socket);   // Free Buffers if allocated...
        p_match_socket->state=TCP_CLOSED;  // Connection ends immediatelly
        return EVENT_TCP_RESETRECEIVED;
    }

    NET_DEBUG("<rx D:%u P:%u A:%x S:%x F:%u, T:%u> ",dlen, hframe.tcp_hdr.sport, hframe.tcp_hdr.ack.w.l_word, hframe.tcp_hdr.seq.w.l_word, hframe.tcp_hdr.flags, p_match_socket->state);

    p_match_socket->timer=BASIC_RETRY_TIMER;

    switch(p_match_socket->state){

        // Socket was listening. Only a SYN could change this
        case TCP_CLOSED:  // Passive open!
            if(!(hframe.tcp_hdr.flags&TSYN)) break;
            NET_DEBUG("<SYN RECEIVED>");

    #ifdef USE_TCP_CLIENT
            if(p_match_socket->tcp_client_flag!=FLAG_PASSIVE_OPEN) break; // Passove open not allowed.
    #endif

            // Fast copy by two casts... (6 Bytes)
            //*(unsigned long *)p_match_socket->sremote_mac=*(unsigned long *)remote_mac;
            //*(uint16_t *)(p_match_socket->sremote_mac+4)=*(uint16_t *)(remote_mac+4);
            memcpy(p_match_socket->sremote_mac, remote_mac, sizeof(remote_mac));
            // Save remote's IP, set by process_IP() and other data
            p_match_socket->sremote_ip = remote_ip.ipl;
            p_match_socket->sremote_port = hframe.tcp_hdr.sport; // Remote Port match already matching!
            // Our Ack is sender's Sequence!
            p_match_socket->sack.u = hframe.tcp_hdr.seq.u+dlen+1; // +1: Bec. SYN rcvd.
            p_match_socket->sseq.w.h_word = net_service_cnt;   // Time ascending...
            p_match_socket->sseq.w.l_word = 0u;    // Our relative Pointer (for HTTP)

            send_match_ok_TCP(0u,0u,TSYN+TACK, p_match_socket); // Reply with a single SYN+ACK
            NET_DEBUG("<SYN+ACK SENT>");

            p_match_socket->state=TCP_SYNCON;  // SYN confirmed with SYN+ACK
            p_match_socket->retry_cnt=0;
            return EVENT_TCP_SYNRECEIVED; // Low-Byte added by caller!

    #ifdef USE_TCP_CLIENT
        case TCP_SYNSENT:
            // NET_DEBUG("<ACTIVE OPEN SYN-RECEIVED>");
            if(!(hframe.tcp_hdr.flags&TSYN)) break;
            hframe.tcp_hdr.seq.u++;    // Count remote SYN
            p_match_socket->sack.u=hframe.tcp_hdr.seq.u; // +1: Bec. SYN rcvd.
    #endif

        case TCP_SYNCON:
        case TCP_EST:	// Established, Connection OK
            if(!(hframe.tcp_hdr.flags&TACK)) break;
            if(dlen>MAX_RX) dlen=MAX_RX;  // IDIOTA! Clip data in size (don't know if this is safe?)

        // Here a small problem is silently ignored: A not acknowled Segment which is restransmitted larger
        // could contain old data as a part (maybe for TELNET...)
        // Silently assume all Segments have valid ACK

            if(p_match_socket->sack.u!=hframe.tcp_hdr.seq.u) {
                NET_DEBUG("<TCP_OOB>");
                return EVENT_TCP_OUTOFBOUNDS; // Ignore-out-of-bounds segments!
            }

            p_match_socket->state=TCP_EST;  // Connection now established

            p_match_socket->sack.u+=dlen;
            read_frame_data_8900((uint8_t *)(rcv_buf+rcv_ofs),dlen);  //+rcv_ofs Read Sender's Data, if any
            rcv_len=dlen;    // remember size of read data...
            if(!dlen) rcv_ofs=0;

        // Matching 3 Sockets? -> Clear ALL
            if(p_match_socket->buf_outsize3 && hframe.tcp_hdr.ack.u==p_match_socket->sseq_3){
                NET_DEBUG("<M123>");
                free_tx_buf(p_match_socket->p_outbuf3);
                free_tx_buf(p_match_socket->p_outbuf2);
                free_tx_buf(p_match_socket->p_outbuf1);
                p_match_socket->buf_outsize3=0;
                p_match_socket->buf_outsize2=0;
                p_match_socket->buf_outsize1=0;

                // Matching Sockets 2 and 1: Free 1,2, Shift 3 to 1
            }else if(p_match_socket->buf_outsize2 && hframe.tcp_hdr.ack.u==p_match_socket->sseq_2){
                NET_DEBUG("<M12>");
                free_tx_buf(p_match_socket->p_outbuf2);
                free_tx_buf(p_match_socket->p_outbuf1);

                p_match_socket->sseq_1=p_match_socket->sseq_3;
                p_match_socket->p_outbuf1=p_match_socket->p_outbuf3;
                p_match_socket->buf_outsize1=p_match_socket->buf_outsize3;

                p_match_socket->buf_outsize2=0;
                p_match_socket->buf_outsize3=0;

                // Matching Sockets 1 Free 1, Shift 2 to 1, 3 to 2
            }else if(p_match_socket->buf_outsize1 && hframe.tcp_hdr.ack.u==p_match_socket->sseq_1){
                NET_DEBUG("<M1>");
                free_tx_buf(p_match_socket->p_outbuf1);

                p_match_socket->sseq_1=p_match_socket->sseq_2;
                p_match_socket->p_outbuf1=p_match_socket->p_outbuf2;
                p_match_socket->buf_outsize1=p_match_socket->buf_outsize2;

                p_match_socket->sseq_2=p_match_socket->sseq_3;
                p_match_socket->p_outbuf2=p_match_socket->p_outbuf3;
                p_match_socket->buf_outsize2=p_match_socket->buf_outsize3;

                p_match_socket->buf_outsize3=0u;

            }


            // Frame does not contain a TFIN so simply acknowledge it, if data od SYN received
            if(!(hframe.tcp_hdr.flags&TFIN)){
                if(dlen || (hframe.tcp_hdr.flags&TSYN)) send_match_ok_TCP(0u,0u,TACK,p_match_socket); // Frame OK: Acknowledge immediatelly if data...
            }else if(hframe.tcp_hdr.flags&TFIN){ // Come to here if RST and/or received
                p_match_socket->sack.u++;  // Count remote FIN
                send_match_ok_TCP(0,0,TACK+TFIN+TPUSH,p_match_socket); // Acknowledge + FIN
                p_match_socket->sseq.u++;  // Count our FIN after sending!...
                p_match_socket->state=TCP_FINCON; // FIN Confirmed
            }

            // Only if nothing available reset retry_counter...
            if(!p_match_socket->buf_outsize1) p_match_socket->retry_cnt=0;

        //    if(!dlen || hframe.tcp_hdr.flags&TPUSH){
            if(!dlen || flags_temp&TPUSH){
                return EVENT_TCP_DATARECEIVED;
            }else{
                rcv_ofs=dlen;
                return 0;
            }

        case TCP_FINSENT:
            NET_DEBUG("<FINSENT>");
            if(!(hframe.tcp_hdr.flags&TACK)) break;
            // printf("Flags: %u\n",hframe.tcp_hdr.flags);
            // printf("<<M:%ld H:%lx >>",p_match_socket->sack.u,hframe.tcp_hdr.seq.u);
            if(p_match_socket->sack.u!=hframe.tcp_hdr.seq.u) return EVENT_TCP_OUTOFBOUNDS; // Ignore-out-of-bounds segments!
            //NET_DEBUG("<Wait3LASTACK>");
            if(hframe.tcp_hdr.flags&TFIN){    // Fin accepted by Remote!
                p_match_socket->sack.u++;    		// Count remote FIN
                send_match_ok_TCP(0u,0u,TACK,p_match_socket);   	// Frame OK: Acknowledge immediatelly!
                free_match_socket(p_match_socket); 			// Free Buffers if allocated...
                p_match_socket->state=TCP_CLOSED;  	// Connection ends NOW
                //NET_DEBUG("<FINAL ACK SENT CLOSED>");
            }
            p_match_socket->retry_cnt=0u;
            return EVENT_TCP_WAITLASTACK;

        case TCP_FINCON: // Accept one last ACK
            if(!(hframe.tcp_hdr.flags&TACK)) break;
            if(p_match_socket->sack.u!=hframe.tcp_hdr.seq.u) return EVENT_TCP_OUTOFBOUNDS; // Ignore-out-of-bounds segments!

            p_match_socket->state=TCP_CLOSED;  	// Connection ends NOW
            free_match_socket(p_match_socket); 				// Free Buffers if allocated...
                                            // NET_DEBUG("<LAST FIN ACKNOWLEDGED>");
            p_match_socket->retry_cnt=0u;
            return EVENT_TCP_CLOSED;
    }

    free_match_socket(p_match_socket); // Free Buffers if allocated...
    p_match_socket->state=TCP_CLOSED;
    send_incomming_reset_TCP(dlen, &remote_mac[0], remote_ip.ipl);  // Denie further request!
    return EVENT_TCP_ILLEGALFRAME; // Denie illegal frames;
}

/**********************************************************************************
* uint16_t final_timeout_socket();
*
* Socket has definitely timed out. Free it for other users...
**********************************************************************************/
static inline uint16_t final_timeout_socket(UC_SOCKET* p_match_socket){

    //printf("TIMEOUT match_socket_type: %u\n",p_match_socket->socket_type);
    if(p_match_socket->socket_type==SOCKET_TCP){
#ifdef USE_TCP_CLIENT
        if(p_match_socket->state<ARPSENT)
#endif
            send_match_ok_TCP(0,0,TRST,p_match_socket); // Reset this socket!
        free_match_socket(p_match_socket); // Free Buffers if allocated...
        //NET_DEBUG("<TIMEOUT RESET>");
        p_match_socket->state=TCP_CLOSED;  // ==0 (for UDP as well)
        return EVENT_TCP_TIMEOUT;
    }
    p_match_socket->state=0;  // ==0 (for UDP as well, but no action required)
    return EVENT_SOCKET_TIMEOUT;
}

/**********************************************************************************
* uint16_t retransmit_socket();
*
* Socket requires a retransmition
**********************************************************************************/
inline uint16_t retransmit_socket(UC_SOCKET* p_match_socket){
 unsigned long hseq;

 // printf(" >>--RE-TX:%u>>",p_match_socket->sremote_port);

 if(p_match_socket->socket_type==SOCKET_TCP){
    switch(p_match_socket->state){
        case TCP_SYNCON:    // Timeout after SYN-confirmed->Transmit Confirmation again
            send_match_ok_TCP(0,0,TSYN+TACK,p_match_socket); // Transmit Again
            // NET_DEBUG("<TCP RETRANSMIT TSYN+TACK>");
            return EVENT_TCP_RETRANS;

        case TCP_EST:     // Timeout in an established Connection
            if(p_match_socket->buf_outsize1){  // Something un-acknowledged?
                //NET_DEBUG("<TCP RETRANSMIT EST>");
                // Seq. represents the sent data, so for resend subtract the block from seq, afterwards ad it...
                hseq=p_match_socket->sseq.u; // Save current Sequ (Pos.)
                // Rewind to Pos. before BUF1 was sent

                p_match_socket->sseq.u=p_match_socket->sseq_1-p_match_socket->buf_outsize1; // 32 Bit operation - This must be acknowledged to free the buffer.
                send_match_ok_TCP((uchar*)p_match_socket->p_outbuf1->buffer,p_match_socket->buf_outsize1,TACK+TPUSH,p_match_socket);
                p_match_socket->sseq.u=hseq;  // Restore old Pointer

                return EVENT_TCP_RETRANS;
            }
            // NET_DEBUG("<TCP RT IDLE IDLE>");
            // Stack is idle: All ok
            p_match_socket->timer=TCP_IDLE_RETRIES;  // Socket OK, LONG TIMEOUT!!!
            return 0u;

        case TCP_FINCON:
        case TCP_FINSENT:
            send_match_ok_TCP(0,0,TFIN+TACK+TPUSH,p_match_socket); // Transmit, without any data after FIN_CON...
            // NET_DEBUG("<TCP FIN RETRANSMIT>");
            return EVENT_TCP_RETRANS;

#ifdef USE_TCP_CLIENT
        case ARPSENT:
            send_request_ARP(p_match_socket->sremote_ip);
            // NET_DEBUG("<(TCP) ARP RETRANSMIT>");
            return EVENT_TCP_RETRANS;

            case ARPREC:
            // NET_DEBUG("<(TCP) ARP-REQUEST RECEIVED!!!>");

            // Ports already setup!
            p_match_socket->sseq.w.h_word=net_service_cnt;   // Time ascending...
            p_match_socket->sseq.w.l_word=0;    // Our relative Pointer (for HTTP, -1 due to SYNC)
            p_match_socket->state=TCP_SYNSENT;  // SYN confirmed with SYN+ACK

            case TCP_SYNSENT:
            send_match_ok_TCP(0,0,TSYN,p_match_socket); // Initiate Connection with a SYN
            // NET_DEBUG("<ACTIVE SYN SENT>");
            return 0; // Only 1 Try, No Retransmition!
#endif
    }
 }
#ifdef USE_UDP_CLIENT
     else if(p_match_socket->socket_type==SOCKET_UDP){
        switch(p_match_socket->state){
            case ARPSENT:
                send_request_ARP(p_match_socket->sremote_ip);
                // NET_DEBUG("<(UDP) ARP RETRANSMIT>");
                return EVENT_UDP_ARPRETRANS;

            default:
                // NET_DEBUG("<(UDP) TIMEOUT with ARP-REQUEST RECEIVED!!!>");

                p_match_socket->retry_cnt=0;                   // Never close an ARPED UDP-Socket...
                p_match_socket->timer=UDP_IDLE_RETRIES;        // Socket OK, LONG TIMEOUT!!! No change in state
                return 0u;
            }
    }
#endif


 return EVENT_SOCKET_RETRANS;
}

/**********************************************************************************
* uint16_t periodical_socket();
*
* Watch non-0-state sockets periodically every 0.5 secs...
**********************************************************************************/
uint16_t periodical_socket(UC_SOCKET* p_match_socket){
    // First decrement sub-timer. If no 0: No Action required

    uchar h=p_match_socket->timer-1;
    if(h){
        p_match_socket->timer=h;
        return 0u;
    }


    p_match_socket->timer=BASIC_RETRY_TIMER;
    h=p_match_socket->retry_cnt+1;
    if(h==MAX_RETRIES){
        NET_DEBUG("Timeout");
        return final_timeout_socket(p_match_socket);
    }else{
        p_match_socket->retry_cnt=h; // Retry again...
        return retransmit_socket(p_match_socket);
    }
}

/**********************************************************************************
* void process_TCP(void)
*
* 3.rd-Level-Multiplexer
* A note for reading UDP-Datagrams: if Size is odd, last byte is in the
* HBYTE of the last Read_Frame_word_8900()...
* Usually a TCP-frame will never come as broadcast, so treat each as more
* important than other types...
**********************************************************************************/

uint16_t process_TCP(uint16_t dlen){
    UC_SOCKET *psock;
    uchar ui;
    uchar ohlen;
    uint16_t res;

    //iprintf("Process TCP %u\n",dlen);

    read_frame_data_8900(hframe.bytes,20); // Read informative part of TCP header to HFRAME
    flags_temp=hframe.tcp_hdr.flags;


    dlen-=20;    //

    ohlen=hframe.tcp_hdr.hlen-80u;
    while(ohlen){  // Eat TCP-option, if MSS: ignore silently...
        ohlen-=16; // ohlen = size in 32-bit-word<<4
        dlen-=4;
        (void)Read_Frame_long_8900();
    }

#ifdef DEBUG_REC
    // Record Data of received Frame
    record_frame('R',hframe.tcp_hdr.sport,hframe.tcp_hdr.seq.u,hframe.tcp_hdr.ack.u, hframe.tcp_hdr.flags,dlen);
#endif

 // First try: Find any MATCHING socket. If one found, copy and process it...
     // This will also find a closed socket for a ACK-FIN->ACK-retransmition...
     psock=uc_socket;
     for(ui=0;ui<MAX_SOCK;ui++,psock++){
         if(psock->socket_type==SOCKET_TCP){  // Only TCP-Sockets are of interest
              // Test Remote IP-Match-Match,remote port and local port
              if(psock->sremote_ip==remote_ip.ipl){
                  if(psock->sremote_port==hframe.tcp_hdr.sport){
                       if(psock->local_port==hframe.tcp_hdr.dport){
                            res=state_machine_TCP(dlen, psock);     // Now Header read, ready to read data
                            NET_DEBUG("Sock Match %u %x\r\n",ui,res);
                            return res+ui;
                       }
                  }
              }
         }
     }

     // Now: No matching Socket found: Then only frames with SYN are allowed!
     if(!(hframe.tcp_hdr.flags&TSYN)) return EVENT_TCP_ILLEGALFRAME;
     // No matching socket has been found, so find one with TCP_CLOSED and matching local port to open as a new one...
     psock=uc_socket;
     for(ui=0u;ui<MAX_SOCK;ui++,psock++){
         if(psock->socket_type==SOCKET_TCP){  // Only TCP-Sockets are of interest if an offered local port is matched
              if(psock->state==TCP_CLOSED && psock->local_port==hframe.tcp_hdr.dport){
                NET_DEBUG("!MATCH");
                res=state_machine_TCP(dlen,psock);     // Now Header read, ready to read data
                if (res) return res+ui;
              }
         }
     }

     // Nothing found and nothing free! Deny request by replying with a TCP-RESET (not replying may be safer but unpolite...)
     NET_DEBUG("TCP-RESET");
     send_incomming_reset_TCP(dlen,&remote_mac[0],remote_ip.ipl);
     return EVENT_TCP_DENIED;

}



/**********************************************************************************
* void process_IP(void)
*
*
* 2.nd-Level-Multiplexer
**********************************************************************************/
uint16_t __attribute__((optimize("-O3"))) process_IP(void){
    uint16_t hdr;
    uint16_t dlen;
    uchar pcol;

    hdr=Read_Frame_word_8900();  // Read Header
    //NET_DEBUG("HDR %x\r\n",hdr);
    if((hdr&0xF000)!=0x4000) return EVENT_IP_NOIP4; // Not IP4!
    dlen=Read_Frame_word_8900();  // Read total length of datagram

    //NET_DEBUG("len %u\r\n",dlen);

    Read_Frame_word_8900();   // Ignore Ident

    if(Read_Frame_word_8900()&0x3FFF) {
    //	NET_DEBUG("Fragment\n");
        return EVENT_IP_WONTFRAG; // Reject fragemnts!
    }

    pcol=(uchar)Read_Frame_word_8900(); // Protocol (1: ICMP 6 TCP 17: UDP)
    Read_Frame_word_8900();   // Ignore IP Checksum (already secured by Ethernet)

    remote_ip.ipl=Read_Frame_long_8900(); // Destination IP (should be US)

    Read_Frame_long_8900();   // Destination IP (should be US)

    dlen-=20;    // Adjust header
    hdr&=0xF00;
    hdr>>=8;
    hdr-=5;
    NET_DEBUG("<skip %x ",hdr);
    while(hdr--){
        Read_Frame_long_8900();  // Ignore IP options
        dlen-=4;
    }
    NET_DEBUG("pcol %x>",pcol);
    if(pcol==1){
        return process_ICMP(dlen);
    }else if(pcol==6u){ // TCP
        return process_TCP(dlen);
#ifdef USE_UDP
    }else if(pcol==17u){ // UDP
        return process_UDP(dlen);
#endif
    }
    return EVENT_IP_UNKNOWN;  // Don't unterstand this
}


#ifdef USE_UDP
/**********************************************************************************
* uint16_t send_socket_udp(uchar sock, unsigned char * pdata, uint16_t datalen)
*
* Send data without any buffering
**********************************************************************************/
uint16_t __attribute__((optimize("-O3"))) send_socket_udp(uchar sock, const unsigned char * const pbuf, uint16_t datalen){
    if (sock < MAX_SOCK) {
        UC_SOCKET *psock;
        psock=&uc_socket[sock];
        if(psock->socket_type!=SOCKET_UDP) return EVENT_UDP_ERROR;
        //NET_DEBUG("dest MAC: %02x:%02x:%02x:%02x:%02x:%02x ", psock->sremote_mac[0],psock->sremote_mac[1],psock->sremote_mac[2],psock->sremote_mac[3],psock->sremote_mac[4],psock->sremote_mac[5]);
        send_upd(pbuf,datalen,psock->sremote_mac,psock->sremote_ip,psock->local_port,psock->sremote_port);
        return 0;
    }
    return GENERAL_ERROR;
}
#endif

/**********************************************************************************
* uint16_t send_socket_tcp(uchar sock, unsigned char * pdata, uint16_t datalen)
*
* Bind an (allocated and filled ) buffer to a socket and send it. After Success,
* the buffer is freed by the stack (check with ready4tx_socket()
* The buffer must be allocated with allocate_tx_buf().
* For return values!=0 the buffer must be freed by the caller!
*
**********************************************************************************/
uint16_t send_socket_tcp(uchar sock, TX_BUFFER * pbuf, uint16_t datalen){
    if (sock < MAX_SOCK) {
        UC_SOCKET * const p_match_socket = &uc_socket[sock];

        if(p_match_socket->socket_type!=SOCKET_TCP || p_match_socket->state!=TCP_EST) return EVENT_TCP_DENIED;
        if(!datalen) {
    //		NET_DEBUG("<free>");
            free_tx_buf(pbuf); // Free Buffer
            return 0u;  // IDIOTA!
        }

        // Bind Buffer try to allocate B1 first, then B2m then B3 else error
        if(!p_match_socket->buf_outsize1){
            p_match_socket->p_outbuf1=pbuf;
            p_match_socket->buf_outsize1=datalen;
            p_match_socket->sseq_1=p_match_socket->sseq.u+datalen;
    //   	NET_DEBUG("<SB1>");
        }else if(!p_match_socket->buf_outsize2){
            p_match_socket->p_outbuf2=pbuf;
            p_match_socket->buf_outsize2=datalen;
            p_match_socket->sseq_2=p_match_socket->sseq.u+datalen;
    //   	NET_DEBUG("<SB2>");
        }else if(!p_match_socket->buf_outsize3){
            p_match_socket->p_outbuf3=pbuf;
            p_match_socket->buf_outsize3=datalen;
            p_match_socket->sseq_3=p_match_socket->sseq.u+datalen;
    //   	NET_DEBUG("<SB3>");
        }else{
    // 	If data still pending: Error, Important: BUFFER NOT FREED!
    //  	putchar('!');
            return EVENT_TCP_TXPENDING; // Can't send, old data still waiting...
        }
        send_match_ok_TCP((uchar*)pbuf->buffer,datalen,TACK+TPUSH,p_match_socket);
        p_match_socket->sseq.u+=datalen; // 32 Bit operation - This must be acknowledged to free the buffer.

    // New TIMEOUT
        p_match_socket->retry_cnt=0u;
        p_match_socket->timer=BASIC_RETRY_TIMER;
        return 0u; // All OK
    }
    return GENERAL_ERROR;
}

/**********************************************************************************
* uint16_t notready4tx_socket_tcp(uchar sock)
*
* Querries if a TCP socket is ready for Transmition, ok if 0.
* Checks if a Buffer is available for transmition to!)
*
* Flag: RDY_4_TX (>0) or RDY_4_CLOSE (0)
**********************************************************************************/
uint16_t notready_socket_tcp(uchar sock, uchar flag){
    if (sock < MAX_SOCK) {
        UC_SOCKET * const p_match_socket = &uc_socket[sock];

        if(p_match_socket->socket_type!=SOCKET_TCP || p_match_socket->state!=TCP_EST) return EVENT_TCP_DENIED;
        if(!tx_bufleft) return EVENT_SOCKET_NOBUFFER;  // Stack may be ready, but no buffer available...

        if(flag){ // Check Ready for TX: BUF3 must be empty
        // If data still pending (Output Buffer full): Error
            if(p_match_socket->buf_outsize3) return EVENT_TCP_TXPENDING; // Can't send, old data still pending
        }else{  // Check Read for Close: BUF1 must be empty
            if(p_match_socket->buf_outsize1) return EVENT_TCP_TXPENDING; // Can't send, old data still pending
        }
        return 0u; // SOCKEt IS READY!
    }
    return GENERAL_ERROR;
}


/*********************************************************************************
* uint16_t stringsend_socket_tcp(uchar sock, far char* pdata);
*
* Allocate a TCP-TX-Buffer and copy a string (far!) into it.
* Returns 0 on success. Calls send_socket_tcp().
*********************************************************************************/
/*uint16_t stringsend_socket_tcp(uchar sock, char * pdt){
 unsigned char * pbuf;
 uint16_t datalen;

 // Check if allowed
 if(notready_socket_tcp(sock,RDY_4_TX)) return EVENT_TCP_DENIED;
 datalen=strlen(pdt);
 if(datalen>MAX_TX) return EVENT_SOCKET_BUF2SMALL; // Can't send as much...
 // Allocate a buffer
 pbuf=allocate_tx_buf();
 if(!pbuf) return EVENT_SOCKET_NOBUFFER;   // No Buffer free?? -> Memory corrupt!
 bmove(pdt,pbuf,datalen);
 return send_socket_tcp(sock,pbuf,datalen);
}*/


/**********************************************************************************
* uint16_t close_socket_tcp(sock)
*
* Close an open socket (regular mode)
*
**********************************************************************************/
uint16_t close_socket_tcp(uchar sock){
    if (sock < MAX_SOCK) {
        UC_SOCKET * const p_match_socket =  &uc_socket[sock];

        if(p_match_socket->socket_type!=SOCKET_TCP || !p_match_socket->state) return EVENT_TCP_DENIED; // Closing always possible...

        // If data still pending: Error
        if(p_match_socket->buf_outsize1) return EVENT_TCP_TXPENDING; // Can't send, old data still waiting...

        send_match_ok_TCP(0,0,TACK+TFIN+TPUSH,p_match_socket);
        p_match_socket->sseq.u++; // 32 Bit operation - This must be acknowledged
        p_match_socket->state=TCP_FINSENT;

        // New TIMEOUT
        p_match_socket->retry_cnt=0u;
        p_match_socket->timer=BASIC_RETRY_TIMER;

        // printf("<--CLOSE %u-->",p_match_socket->sremote_port);

        return 0u; // All OK
    }
    return GENERAL_ERROR;

}

#ifdef USE_TCP_CLIENT
/**********************************************************************************
* uint16_t open_socket_tcp(sock,ipl,port);
*
* Initiate an active Open for a  given Socket
**********************************************************************************/
uint16_t open_socket_tcp(uchar sock,unsigned long remote_ipl,unsigned int remote_port){
    if (sock < MAX_SOCK) {
        UC_SOCKET * const p_match_socket=&uc_socket[sock];

        if(p_match_socket->socket_type!=SOCKET_TCP || p_match_socket->state) return EVENT_TCP_DENIED; // No Access to non

        p_match_socket->sremote_ip=remote_ipl;
        p_match_socket->sremote_port=remote_port;

        send_request_ARP(remote_ipl);
        p_match_socket->state=ARPSENT;

        // New TIMEOUT
        p_match_socket->retry_cnt=0;
        p_match_socket->timer=BASIC_RETRY_TIMER;

        return 0; // All OK
    }
    return GENERAL_ERROR;
}
#endif

#ifdef USE_UDP_CLIENT
/**********************************************************************************
* uint16_t open_socket_udp(sock,ipl,port);
*
* Initiate an active Open for a  given Socket in UDP-Mode
*
**********************************************************************************/
uint16_t open_socket_udp(uchar sock,unsigned long remote_ipl,unsigned int remote_port){
    if (sock < MAX_SOCK) {
        UC_SOCKET * const p_match_socket = &uc_socket[sock];

        if(p_match_socket->socket_type!=SOCKET_UDP || p_match_socket->state) return EVENT_UDP_DENIED; // No Access to non

        p_match_socket->sremote_ip=remote_ipl;
        p_match_socket->sremote_port=remote_port;

        if(remote_ipl!=0xffffffffu){
            send_request_ARP(remote_ipl);
            p_match_socket->state=ARPSENT;

            // New TIMEOUT
            p_match_socket->retry_cnt=0;
            p_match_socket->timer=BASIC_RETRY_TIMER;
        }else{
            memset(p_match_socket->sremote_mac,0xff,sizeof(p_match_socket->sremote_mac));
            p_match_socket->state=ARPREC;
            p_match_socket->retry_cnt=0;
            p_match_socket->timer=1;
        }

        return 0; // All OK
    }
    return GENERAL_ERROR;
}
#endif

#ifdef USE_UDP
/**********************************************************************************
* uint16_t close_socket_udp(sock)
*
* Close an open socket (regular mode)
*
**********************************************************************************/
uint16_t close_socket_udp(uchar sock){
    if (sock < MAX_SOCK) {
        UC_SOCKET * const p_match_socket = &uc_socket[sock];

        if(p_match_socket->socket_type!=SOCKET_UDP || !p_match_socket->state) return EVENT_UDP_DENIED; // Closing always possible...
        p_match_socket->state=0;   // That's all to close...

        return 0; // All OK
    }
    return GENERAL_ERROR;
}
#endif



/**********************************************************************************
* uint16_t poll_net(void)
*
* Top-Level-Multiplexer, should be happy with SNAP frames too...
* Will return !=0 if Event was encountered
**********************************************************************************/
uint16_t __attribute__((optimize("-O3"))) poll_net(void){
 uint16_t RxEvent; //,len;
 uint16_t type;

	RxEvent=Read_PP_8900(PP_RxEvent);
    if(RxEvent & RX_OK)
    {
        //NET_DEBUG("rx 0x%x ",RxEvent);
        (void)Read_FrameHL_word_8900(); 		// Skip Status HL						2
        const uint16_t len =Read_FrameHL_word_8900(); 	// Read Length HL (delivered >= 60!)	2
        //uint16_t temp[10];
        (void)Read_Frame_word_8900(); 		// Skip OUR MAC... (6 Bytes)			2
        (void)Read_Frame_long_8900();										//			4
        //read_frame_data_8900(&temp[0],6);       // Skip OUR MAC... (6 Bytes)  0,1,2
        read_frame_data_8900(remote_mac,sizeof(remote_mac)); // Read Sender's MAC			6
        //memcpy(&temp[3],remote_mac,6);  //3,4,5

        //temp[6]=type=Read_Frame_word_8900();										//	2
        type=Read_Frame_word_8900();										//	2
        /*uchar const * p_char = (uchar const *)temp;
        for(uint16_t i=0;i<(7*2); i++) {
            iprintf("%02X ",*p_char++);
        }*/
        //NET_DEBUG("Remote MAC: %02x:%02x:%02x:%02x:%02x:%02x ", remote_mac[0],remote_mac[1],remote_mac[2],remote_mac[3],remote_mac[4],remote_mac[5]);
        //NET_DEBUG(" Type %x %x\r\n",type,len);
        if(type<=0x5DCu){ // SNAP Frame! Eat LSAP-Ctrl-OUI and retry...
            if(net_match_uint(0xAAAAu)) return 0u;							//  (2)
            if(net_match_ulong(0x3000000u)) return 0u;						//  (4)
            type=Read_Frame_word_8900(); // Read NEW type...					(2)
                                                                            //  = 20
        }
        // *** First stage input filter/multiplexer for received frames ***
        if(type==0x0806u){ // This is an ARP-Frame!								= 18 (14)
            return process_ARP();
        }else if(type==0x800){ // IP Header!
            return process_IP();
        } // ignore unknown frames
    }else{
        // Do soemthing periodically net_timer decremented 2 times per Sec!... ***
        if(!net_timer){
            net_service_cnt++;  // Sequence-Timer Highbyte
            net_timer=TIMER_FRQ/2u; // about 0.5 Hz ONLY after one complete IDLE-pass...
            UC_SOCKET* psock = uc_socket;
            for(uint16_t ui=0u;ui<MAX_SOCK;ui++,psock++){
                if(psock->state){  // Examine only non-0-state-Sockets
                    uint16_t res=periodical_socket(psock);     // Retry transmition... (Could be UDP for ARP as well...)
                    if(res) return res+ui; 		// Return immediatelly if necessary
                }
            }
            return EVENT_SOCKET_IDLETIMER; // About twice/sec
        }
    }
 return 0; // NO EVENT
}


/**********************************************************************************
* IRQ: The system timer. Count down net_timer, leave it if 0!
**********************************************************************************/
volatile bool timer_flag=false;

void timer_func() {
  static uint8_t _prescaler = TIMER;
  if (!--_prescaler) {
    _prescaler = TIMER;
    timer_flag = true;
    register uchar h=net_timer;
    if(h) net_timer=(--h);
  }
}

/**********************************************************************************
* uchar Init_net()
*
* Initialise Network, return 0 if OK, else ERROR
**********************************************************************************/
uchar Init_net(void){

    _clock(timer_func);

    if(cs_init()) return 1; // ERROR (MAC set as global!)
    rcv_ofs=0u;
    _delay_ms(100); // May needs a few msec until ready
    return 0u;
}


// END
