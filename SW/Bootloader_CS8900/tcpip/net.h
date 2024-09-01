/* $Author: Andreas Voggeneder $                 				*/
/* $Date: 2003/14/02 19:31:38 $									*/
/* Description:	TCP/IP Stack, UDP/TCP Functions	                */
/*																*/
/* Remarks:     No remarks.                                     */
/*    															*/



/**********************************************************************************
* OPTION DEFs for this Stack (Change for your needs)
*
* For a simple Webserver with <1kB RAM:
* - none of the Options DEBUG_REC, USE_UDP or USE_TCP_CLIENT  is required
* - for MAX_RX and MAX_TX 100 (Bytes) is sufficient
* - With MAX_SOCK 4 and TX_BUFFERS 4 up to 4 simultaneous request can be served
*
* For a simple Mail-Client with <400 Bytes RAM
* - only  the Option USE_TCP_CLIENT  is required
* - for MAX_RX and MAX_TX 100 (Bytes) is sufficient
* - With MAX_SOCK 1 and TX_BUFFERS 3 it will work perfectly
**********************************************************************************/

#ifndef _NET_H
#define _NET_H

#include <stdbool.h>
#include <stdint.h>

//#define DEBUG_REC   // if defined: Record Send/received Frames (show with show_frame())

#define USE_UDP  // If defined: UDP-Server added, not req. for simple webserver
#define USE_UDP_CLIENT // If defined: UDP-Client added (Active open, Active ARP), not req. for simple webserver

//#define USE_TCP_CLIENT // If defined: TCP-Client (Active open, Active ARP) added, not req. for simple webserver

// RX-Buffer (only one)
#define MAX_RX 2048   // May be up to 1400-1500 Bytes, use at least 100 Bytes
// TX-Buffers (>=1)
#define MAX_TX 800  // Transmition Buffer Size, may be up to 1400-1500 Bytes

#define MAX_SOCK 5  // Maximum No. of Sockets (1-8 recommended)
#define UDP_SOCK (MAX_SOCK-1)
#define UDP_SERVER_SOCK (MAX_SOCK-2)
#define TX_BUFFERS 4  // Recommended: 3 to 3*MAX_SOCK

//#define data
//#define idata
//#define
//#define code const

/**********************************************************************************
* Internal Options (Changes not recommended)
**********************************************************************************/
typedef unsigned char uchar;
//typedef unsigned short uint;


// *** Timeouts-Definitions ***
#define MAX_RETRIES 4 // No of Retries (ARP/UDP/TCP...)
#define BASIC_RETRY_TIMER 6 // in 0.5 Seconds (WIN32 uses 3 sec?)
#define TCP_IDLE_RETRIES 40 // == TOTAl TIMEOUT=((TCP_IDLE_RETRIES*(MAX_RETRIES-1)+BASIC_RETRY_TIMER)/2 ins sec, (40 ca. 1 min )
#define UDP_IDLE_RETRIES 40 // == TOTAl TIMEOUT=((UDP_IDLE_RETRIES*(MAX_RETRIES-1)+BASIC_RETRY_TIMER)/2 ins sec, (40 ca. 1 min )


/* tcp_client_flag */
#define FLAG_ACTIVE_OPEN 1 // Only used for TCP_CLIENTS, else ignored (= Passive open only poss.)
#define FLAG_PASSIVE_OPEN 0 // dto.

/* Socket type */
#define SOCKET_NONE 0 // Not active
#ifdef USE_UDP
 #define SOCKET_UDP 1 // UDP-Socket
#endif
#define SOCKET_TCP 2 // TCP_IP-Socket

/* Public Socket states */
#define TCP_CLOSED  0 // 0 for all: Socket closed (and listen)
#define TCP_EST  2    // Established, Connection OK

#ifdef USE_UDP_CLIENT
 #define UDP_EST  7  // For UDP Established is the same as ARP Received...
#endif




/* Buffer-Flags for notready_socket_tcp() */
#define RDY_4_TX 1
#define RDY_4_CLOSE 0


/**********************************************************************************
* Global structures and data
**********************************************************************************/
typedef union{
    uchar bytes[4];  // Byte representation
    unsigned long ipl; // 32bit representation
} IP_ADR;

typedef union{
    unsigned long u;
    struct{
        uint16_t h_word;
        uint16_t l_word;
    } w;
} WORD2_LONG;

typedef uchar MAC[6]; // define it as a type

typedef struct {
    bool allocated;
    char buffer[MAX_TX]  __attribute__ ((aligned (2)));
}TX_BUFFER;

typedef struct{
    uchar  socket_type;  // Usage for this socket, see above
 uchar state;   // TCP-Socket state machine (TCP_CLOSED=0....)

#ifdef USE_TCP_CLIENT
    uchar  tcp_client_flag; // Only required for TCP clients to dist. between active/passive open.
#endif
    uchar sremote_mac[6] __attribute__ ((aligned (2)));  // Remote's node MAC
    unsigned long sremote_ip; // Remote node's IP
    uint16_t sremote_port;  // Remote's port
    uint16_t local_port;  // Our port for UDP and TCP (HTTP==80)

    WORD2_LONG sack;  // TCP-Acknowledge nr. (of remote node)
    WORD2_LONG sseq;  // TCP-Sequence nr. (== rel. Data Pointer)

    uchar retry_cnt;  // Up-Counter for retries (may be later used as an exponent for timer)
    uchar timer;   // Counts down to 0, then something may happen or not...

    // Here 3 Packets for each Socket reserved
    uint16_t  buf_outsize3;  			// 0 for NO-Data, Size o following pointer...
    unsigned long sseq_3;  		// TCP-Sequence nr. (== rel. Data Pointer for this pack)
    TX_BUFFER  *p_outbuf3;       	// Pointer to avtive fragment 3 for this socket (outgoing)

    uint16_t  buf_outsize2;  			// 0 for NO-Data, Size o following pointer...
    unsigned long sseq_2;  		// TCP-Sequence nr. (== rel. Data Pointer)
    TX_BUFFER  *p_outbuf2;       	// Pointer to avtive fragment 2 for this socket (outgoing)

    uint16_t  buf_outsize1;  			// 0 for NO-Data, Size o following pointer...
    unsigned long sseq_1;  		// TCP-Sequence nr. (== rel. Data Pointer)
    TX_BUFFER  *p_outbuf1;       	// Pointer to avtive fragment 1 for this socket (outgoing)
} UC_SOCKET;

extern const uchar  my_mac[6];  // init to ($51:$80:IP)

extern IP_ADR  my_ip;  //  init manually to desired IP for this machine (public)
extern IP_ADR  remote_ip; // Last read IP (can be used as a temporary (see demos)

#if defined(USE_TCP_CLIENT) || defined(USE_UDP_CLIENT)
 extern IP_ADR  subnet_ip;  // init to subnetmask (usually: 255,255,255,0}, Subnet mask for this node
 extern IP_ADR  gateway_ip;   // init to  Gateway-IP for this node
#endif

// *** THE SOCKETS ***
extern UC_SOCKET  uc_socket[MAX_SOCK];  // My (User's) Sockets!


/**********************************************************************************
* The public buffers in RAM
**********************************************************************************/

// RX-Buffer (1)
extern char  rcv_buf[MAX_RX];   // Buffer for receiving data (Mainly HTTP-Header...)
extern uint16_t  rcv_len;    // Size of received data (int)
extern uint16_t  rcv_ofs;


/**********************************************************************************
* Useful Macros
**********************************************************************************/
// A Macro for composing IP-Adrs. (Usage: COMPOSE_IP(remote_ip,192,168,1,5);)
#define COMPOSE_IP(x,a,b,c,d)  {x.bytes[0]=a;x.bytes[1]=b;x.bytes[2]=c;x.bytes[3]=d;}

// A Macro for setting up an socket. tcp_socket_flags only used for clients...
#ifdef USE_TCP_CLIENT
 #define SOCKET_SETUP(a,b,c,d) {uc_socket[a].socket_type=b; uc_socket[a].local_port=c; uc_socket[a].tcp_client_flag=d;}
#else
 #define SOCKET_SETUP(a,b,c,d) {uc_socket[a].socket_type=b; uc_socket[a].local_port=c;} // Par. d only required if TCP_CLIENT, ignored!
#endif


/**********************************************************************************
* NETWORK Events
**********************************************************************************/
// ========GROUP 9: <HTTP>=======================
// --- HTTP EVENTS ---
#define EVENT_HTTP_REQUEST 0x9000  // Somebody has requested a Page


// ========GROUP A: <ARP>=======================
// --- ARP EVENTS ---
#define EVENT_ARP_REQUEST 0xA000  // Somebody requestet OUR IP (no important)
#define EVENT_ARP_OTHERREPLY 0xA100  // Received a Reply to (our???) ARP Request?
#define EVENT_ARP_UNKNOWN 0xA200  // Unknown ARP frame received
#define EVENT_ARP_NOTYPE 0xA300  // ARP with unknown Type received
#define EVENT_ARP_OTHER  0xA400  // Arp's MAC did'nt match our
#define EVENT_ARP_OURREPLY 0xA500  // ARP received as a Reply to OUR Request

// ========GROUP B: <ICMP>=====================
// --- ICMP EVENTS ---
#define EVENT_ICMP_REPLY 0xB000  // Received a reply to a PING?
#define EVENT_ICMP_REQUEST 0xB100  // We have been PINGed! (This EVENT could be of interest...)
#define EVENT_ICMP_UNKNOWN 0xB200  // Unknown ICMP frame received

// ========GROUP C: <IP>=======================
// --- IP EVENTS ---
#define EVENT_IP_NOIP4  0xC000  // Accept only IP4 Frames
#define EVENT_IP_WONTFRAG 0xC100  // We don't accept fragemnts!
#define EVENT_IP_UNKNOWN 0xC200  // received unknown IP

// ========GROUP D: <Gen. sockets>=============
// --- General socket EVENTS ---
#define EVENT_SOCKET_TIMEOUT 0xD000  // General non-TCP-Socket-TIMEOUT (for TCP: _TCP_TIMOUT)
#define EVENT_SOCKET_RETRANS 0xD100  // General non-TCP-Socket-Retransmition
#define EVENT_SOCKET_NOBUFFER 0xD200  // No Buffer available
#define EVENT_SOCKET_BUF2SMALL 0xD300  // Buffer is too small
#define EVENT_SOCKET_IDLETIMER 0xD400  // Idle-Time triggered (about 2/sec)

// ========GROUP E: <UDP>======================
// --- UDP EVENTS ---
#define EVENT_UDP_UNSOLICITED 0xE000  // Received Unsolicited UDP-DATA...
#define EVENT_UDP_ERROR  0xE100  // UDP segment with error received (ignored)
#define EVENT_UDP_DATARECEIVED 0xE200  // Received UDP-Data, lower 3 Bits contain the socket no. Len separate...
#define EVENT_UDP_ARPRETRANS 0xE300  // UDP-ARP-Retransmition due to timeout
#define EVENT_UDP_DENIED 0xE400  // Denied an incomming or outgoing request (maybe socket failure or state error)!

// =======GROUP F: <TCP>========================
// --- Misc. TCP EVENTS  (less important) ---
#define EVENT_TCP_DENIED     0xF000       // Denied an incomming or outgoing request (maybe socket failure or state error)!
#define EVENT_TCP_RETRANS 0xF100  // TCP-Retransmition due to timeout
#define EVENT_TCP_SYNRECEIVED  0xF200  // <Passive Open>: SYN received, replied with an SYN+ACK. Stack-Idx in LowByte
#define EVENT_TCP_OUTOFBOUNDS 0xF300  // Out-of-Bound-Segment received (Segment ignored)
#define EVENT_TCP_TXPENDING 0xF400  // Can not send, old data not acknowledged!

// --- Only ONE EVENT indicates received data (or ACK) on an (open) Socket ---
#define EVENT_TCP_DATARECEIVED 0xF500  // Received rcv_len data in rcv_buf[] (== Implicit Passive Open)

// --- These TCP EVENTS cause closing the socket (Bitmask 0xF800 or Cond. >= 0xF800)
#define EVENT_TCP_ILLEGALFRAME  0xF800    // Received a totally-out-or-order TCP frame
#define EVENT_TCP_RESETRECEIVED 0xF900  // Received a RESET-Signal for this Socket
#define EVENT_TCP_TIMEOUT 0xFA00  // Connection closed because of timeout
#define EVENT_TCP_WAITLASTACK 0xFB00  // Waiting for Last Acknoledge (only in active mode)
#define EVENT_TCP_CLOSED 0xFC00  // Closing Socket (regular)

#define GENERAL_ERROR 0xFFFF

/**********************************************************************************
* Functions (some are reserved for internal usage)
**********************************************************************************/

// Low Level (Use only in special cases).
TX_BUFFER * allocate_tx_buf(void);
void free_tx_buf(TX_BUFFER * pbuf);
//void free_match_socket(void);
void send_request_ARP(unsigned long ipl);
void send_udp(char * dt, uint16_t len,MAC  *pmac,unsigned long rem_ipl,uint16_t sport, uint16_t dport);


// TCP
uint16_t send_socket_tcp(uchar sock, TX_BUFFER * pbuf, uint16_t datalen);
uint16_t notready_socket_tcp(uchar sock, uchar flag);
uint16_t stringsend_socket_tcp(uchar sock, char * pd);
uint16_t close_socket_tcp(uchar sock);
uint16_t open_socket_tcp(uchar sock,unsigned long remote_ipl,unsigned int remote_port);

// UDP
uint16_t open_socket_udp(uchar sock,unsigned long remote_ipl,unsigned int remote_port);
uint16_t send_socket_udp(uchar sock, const unsigned char * const pbuf, uint16_t datalen);
uint16_t close_socket_udp(uchar sock);

// General
uint16_t poll_net(void);
uchar Init_net(void);


#ifdef DEBUG_REC

// --- Debugging stuff (only available if DEBUG_REC defined )
#define MAX_REC_FRAME   100 // Max. No. of frames to record
extern uint16_t rec_no;

void record_frame(uchar typ, uint16_t port, unsigned long seq, unsigned long ack, uchar flags, uint16_t len);
uchar show_frame(uint16_t no);

#endif

/**********************************************************************************/

#endif
// EOF