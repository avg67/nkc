/* $Author: hse00045 $                                  */
/* $Date: 2003/14/02 19:31:38 $                         */
/* Description: TCP/IP Stack, UDP/TCP Functions	        */
/*                                                      */
/* Remarks:     No remarks.                             */
/*                                                      */

//#pragma iv(IRQVECOFS)

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


/**********************************************************************************
* OPTION DEFS: see net.h
**********************************************************************************/

/**********************************************************************************
* MAC-Level data
*
* Set a (default) MAC for THIS node
**********************************************************************************/
const uchar my_mac[6] __attribute__ ((aligned (2))) = {0x00, 0x51, 0xD3, 0xC4, 0xB5, 0xA6 }; // MAC for this machine: M0:M1:M2:M3:M4:M5

uchar remote_mac[6];  // used as temp.


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

IP_HDR hhdr;    // Temporary header for sending IP-data

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

PSEUDO_HDR pseudo_hdr;  // Used for TCP/IP-Checksums



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
//char tx_buffers[TX_BUFFERS][MAX_TX+1];
TX_BUFFER tx_buffers[TX_BUFFERS];
char tx_bufleft=TX_BUFFERS; // Counts left buffers





/**********************************************************************************
* This uC/51 is designed to support a maximum of >8 simultaneous open sockets
*
* ** Only implemented as a fragment until now!
* ** later there will be a bit-mask holding the 'active' sockets
* ** ** Later socket types: SOCKET_NONE(==0), UDP(port), TCP(port), HTTP, TELNET, ...
*
**********************************************************************************/

UC_SOCKET match_socket;  // Temporary matching socket (Work-pad!)

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
/*char * allocate_tx_buf(void){
 uint16_t ui;
 char *pbuf=&tx_buffers[0][0];

 if(tx_bufleft) for(ui=0;ui<TX_BUFFERS;ui++,pbuf+=(MAX_TX+1)){
  if(!(*pbuf)) {
   *pbuf=1; // Mark Buffer as allocated
   tx_bufleft--;
   return pbuf+1; // Return Startadress of buffer
  }
 }
 puts("No TX Buf\r\n");
 return 0; // Nothing found!
}*/

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

/*void free_tx_buf(char * pbuf){
    pbuf--;   // Pointer to Pos 0(Flag)
    if(*pbuf){
        *pbuf=0; // Buffer now free again...
        tx_bufleft++; // One more Buffer free...
    }
}*/

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
void free_match_socket(void){
 if(match_socket.buf_outsize1){
  match_socket.buf_outsize1=0;
  free_tx_buf(match_socket.p_outbuf1);
 }
 if(match_socket.buf_outsize2){
  match_socket.buf_outsize2=0;
  free_tx_buf(match_socket.p_outbuf2);
 }
 if(match_socket.buf_outsize3){
  match_socket.buf_outsize3=0;
  free_tx_buf(match_socket.p_outbuf3);
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

 RequestSend_8900(42);    // Send Reply

 Write_Frame_long_8900(0xFFFFFFFF);  // To Broadcast
 Write_Frame_word_8900(0xFFFF);    // To Broadcast

 write_frame_data_8900(my_mac,6);   // From US (MAC)

 Write_Frame_word_8900(0x0806);   // ARP!

 Write_Frame_long_8900(0x10800);   // Ethernet
 Write_Frame_long_8900(0x6040001);  // Request

 write_frame_data_8900(my_mac,6);   // From US (MAC)
 Write_Frame_long_8900(my_ip.ipl);  // and IP!

 // Variable filled out by Host
 Write_Frame_long_8900(0xFFFFFFFF);  // To Broadcast
 Write_Frame_word_8900(0xFFFF);    // To Broadcast

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

 if(net_match_ulong(0x00010800)) return EVENT_ARP_UNKNOWN; // No ARP!						// 4
 if(net_match_uint(0x0604)) return EVENT_ARP_UNKNOWN; // No ARP!							// 2
 type=Read_Frame_word_8900();  																// 2
// printf("ARP type %x\n",type);
 read_frame_data_8900(hframe.bytes,20); 	// Read informative part of ARP message			   20
 if(type>2) return EVENT_ARP_NOTYPE; 		// Unknown Reply

 if(type==1){ // ARP Request!
  if(hframe.arp_info.target_ip.ipl!=my_ip.ipl) return EVENT_ARP_OTHER; // ARP, but not for us...

  // NET_DEBUG("<ARP request>"); // Inform us...
  RequestSend_8900(42);   // Send Reply

  write_frame_data_8900(remote_mac,6);  // Kick packet back...
  write_frame_data_8900(my_mac,6);  // From US (MAC)
  Write_Frame_word_8900(0x0806);  // ARP!

  Write_Frame_long_8900(0x00010800);
  Write_Frame_long_8900(0x06040002); // Response

  write_frame_data_8900(my_mac,6);  // From US (MAC)
  Write_Frame_long_8900(my_ip.ipl);  // and IP!

  write_frame_data_8900(hframe.bytes,10);  // Sender MAC & Sender IP
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
     		//xram_fast_copy(hframe.arp_info.sender_mac,psock->sremote_mac,6);
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
 if(hframe.ping_info.type==0){
  // *** NOT REQUIRED FOR SERVER MODE! ***
  // NET_DEBUG("<ECHO REPLY ???>");
  return EVENT_ICMP_REPLY;

 }else if(hframe.ping_info.type==8){

  //NET_DEBUG("<ICMP ECHO REQUEST>"); // For debugging...

  // Reflect block as reply
  hframe.ping_info.type=0;
  hframe.ping_info.checksum=0;
  hframe.ping_info.checksum=~ip_check(hframe.bytes,dlen);

  // Now, send out reply
  hhdr.vhl_service=0x4500;
  hhdr.len=sizeof(IP_HDR)+dlen;
  hhdr.ident=0;
  hhdr.frags=16384; // No Fragmentation
  hhdr.ttl=100; // Industrial standard
  hhdr.pcol=1; // ICMP
  hhdr.checksum=0;
  hhdr.sip.ipl=my_ip.ipl;
  hhdr.dip.ipl=remote_ip.ipl;
  hhdr.checksum=~ip_check((unsigned char *)&hhdr,sizeof(IP_HDR));

  RequestSend_8900(dlen+sizeof(IP_HDR)+14); // Send Reply
  write_frame_data_8900(remote_mac,6);  // Kick back...
  write_frame_data_8900(my_mac,6);  // From US (MAC)
  Write_Frame_word_8900(0x800);  // type IP

  write_frame_data_8900((unsigned char *)&hhdr,sizeof(IP_HDR));  // Send Header
  write_frame_data_8900(hframe.bytes,dlen);  // and echo
  puts("PING");
  return EVENT_ICMP_REQUEST; // Someone has PINGED us!

 }else return EVENT_ICMP_UNKNOWN; // Ignore the Rest...
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
 UC_SOCKET * psock;
 uint16_t ui;
 uint16_t udp_sport, udp_dport;

 udp_sport=Read_Frame_word_8900();
 udp_dport=Read_Frame_word_8900();
 if(net_match_uint(dlen)) return EVENT_UDP_ERROR; // a simple check for plausibility...
 Read_Frame_word_8900(); // Ignore CS...


 psock=uc_socket;
 for(ui=0;ui<MAX_SOCK;ui++,psock++){
 	if(psock->socket_type==SOCKET_UDP){  // Only UDP-Sockets are of interest
    	// Test local port match
        if(psock->local_port==udp_dport){
    		psock->sremote_port=udp_sport;  // Copy Sender's Sourceport
    		psock->sremote_ip=remote_ip.ipl; // Copy Sender's IP
    		//xram_fast_copy(&remote_mac[0],psock->sremote_mac,6); // Copy Sender's MAC to socket
            memcpy(psock->sremote_mac, &remote_mac[0], 6);
    		dlen-=8; // Subtract header length
    		if(dlen>MAX_RX) break;   // Ignore too long frames...
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
void send_upd(unsigned char * dt, uint16_t len,unsigned char *pmac,unsigned long rem_ipl,uint16_t sport, uint16_t dport){
 // Now fill out IP-Header
 hhdr.vhl_service=0x4500;
 hhdr.len=sizeof(IP_HDR)+8+len; // 8 Bytes UDP-Header
 hhdr.ident=0;
 hhdr.frags=16384; // No Fragmentation
 hhdr.ttl=100; // Industrial standard
 hhdr.pcol=17; // UDP
 hhdr.checksum=0;
 hhdr.sip.ipl=my_ip.ipl;
 hhdr.dip.ipl=rem_ipl;
 hhdr.checksum=~(ip_check((unsigned char *)&hhdr,sizeof(IP_HDR))); // IP-Header only

 // Now, send out reply
 RequestSend_8900(sizeof(IP_HDR)+14+8+len); // Send Reply:  ETHERNET_HDR IP_HDR UDP_HDR +(data)
 write_frame_data_8900((unsigned char *)pmac,6);  // Physical destination
 write_frame_data_8900(my_mac,6);  // From US (MAC)
 Write_Frame_word_8900(0x800);  // type IP

 write_frame_data_8900((unsigned char *)&hhdr,sizeof(IP_HDR));  // Send IP Header
 Write_Frame_word_8900(sport);
 Write_Frame_word_8900(dport);
 Write_Frame_word_8900(len+8);  // Including UDP_HDR...
 Write_Frame_word_8900(0);  // 0: Means: Checksum not computed

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
void send_TCP(uchar * dt, uint16_t len, uchar * pmac,unsigned long rem_ipl){
 	uint16_t data_cs;

 	hframe.tcp_hdr.hlen=80;   // Standard Size: 20 Bytes
 	hframe.tcp_hdr.checksum=0;

 	pseudo_hdr.sip.ipl = my_ip.ipl;  // Built Pseudo-Header for Checksum
 	pseudo_hdr.dip.ipl = rem_ipl;
 	pseudo_hdr.pcol    = 6; // TCP
 	pseudo_hdr.len     = len + 20;   // Data+TCP-Header, without Pseudo-header!

 	data_cs=ip_check(dt,len); // Checksum of Data Block
 	hframe.tcp_hdr.checksum = ~( // Checksum of Header, Datablock and Pseudo_header
  	ip_check_more(hframe.bytes,20, // TCP-Header
   		ip_check_more((unsigned char *)&pseudo_hdr,sizeof(PSEUDO_HDR),data_cs))
	); // Data

 // Now fill out IP-Header
 	hhdr.vhl_service=0x4500;
 	hhdr.len=sizeof(IP_HDR)+20+len; // 20 Bytes TCP-Header (add MSS if required)
 	hhdr.ident=0;
 	hhdr.frags=16384; // No Fragmentation
 	hhdr.ttl=100; // Industrial standard
 	hhdr.pcol=6; // TCP
 	hhdr.checksum=0;
 	hhdr.sip.ipl=my_ip.ipl;
 	hhdr.dip.ipl=rem_ipl;
 	hhdr.checksum=~(ip_check((unsigned char *)&hhdr,sizeof(IP_HDR))); // IP-Header only

 // Now, send out reply
 	RequestSend_8900(sizeof(IP_HDR)+14+20+len); // Send Reply:  ETHERNET_HDR IP_HDR TCP_HDR +(data)


 	write_frame_data_8900((unsigned char *)pmac,6);  // Physical destination

 	write_frame_data_8900(my_mac,6);  	// From US (MAC)
 	Write_Frame_word_8900(0x800);  		// type IP

 	write_frame_data_8900((unsigned char *)&hhdr,sizeof(IP_HDR));  // Send IP Header
 	write_frame_data_8900(hframe.bytes,20);  // Send TCP Header
 	write_frame_data_8900(dt,len);   	// Send data

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
 send_TCP(0,0,pmac,ipl); // Replay
}

/**********************************************************************************
* void send_match_ok_TCP();
*
* Build Segment header and send it as regular Header, Data are in *pdata, size alen
* match_socket must fit! hframe used as a temporary variable
**********************************************************************************/
void send_match_ok_TCP(unsigned char *pdt, uint16_t dlen, uchar flags){
 	unsigned long seq;

 	hframe.tcp_hdr.sport=match_socket.local_port; // Our Port
 	hframe.tcp_hdr.dport=match_socket.sremote_port; // Remote

 // Window, Flags and Set ACK and SEQU in the response, rest will be completed by send_tcp
 	hframe.tcp_hdr.window=MAX_RX;  // Sender: Do not send more the MAX_RX

 	seq=match_socket.sseq.u;
 	if(flags & (TSYN)) seq--;  // If a SYN is sent, count this as 1
 	hframe.tcp_hdr.seq.u=seq;

 	hframe.tcp_hdr.ack.u=match_socket.sack.u; // This was received from the Sender
 	hframe.tcp_hdr.flags=flags;

 // Send empty
 	send_TCP(pdt,dlen,match_socket.sremote_mac, match_socket.sremote_ip );

 // printf("<TX P:%u A:%x S:%x F:%u, T:%u> ", hframe.tcp_hdr.dport, hframe.tcp_hdr.ack.w.l_word,hframe.tcp_hdr.seq.w.l_word,hframe.tcp_hdr.flags,match_socket.state);

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

uint16_t state_machine_TCP(uint16_t dlen){

 if(hframe.tcp_hdr.flags&TRST){
    free_match_socket();   // Free Buffers if allocated...
    match_socket.state=TCP_CLOSED;  // Connection ends immediatelly
    return EVENT_TCP_RESETRECEIVED;
 }

 NET_DEBUG("<rx D:%u P:%u A:%x S:%x F:%u, T:%u> ",dlen, hframe.tcp_hdr.sport, hframe.tcp_hdr.ack.w.l_word, hframe.tcp_hdr.seq.w.l_word, hframe.tcp_hdr.flags, match_socket.state);

 match_socket.timer=BASIC_RETRY_TIMER;

 switch(match_socket.state){

    // Socket was listening. Only a SYN could change this
    case TCP_CLOSED:  // Passive open!
        if(!(hframe.tcp_hdr.flags&TSYN)) break;
        NET_DEBUG("<SYN RECEIVED>");

#ifdef USE_TCP_CLIENT
        if(match_socket.tcp_client_flag!=FLAG_PASSIVE_OPEN) break; // Passove open not allowed.
#endif

        // Fast copy by two casts... (6 Bytes)
        //*(unsigned long *)match_socket.sremote_mac=*(unsigned long *)remote_mac;
        //*(uint16_t *)(match_socket.sremote_mac+4)=*(uint16_t *)(remote_mac+4);
        memcpy(match_socket.sremote_mac, remote_mac, sizeof(remote_mac));
        // Save remote's IP, set by process_IP() and other data
        match_socket.sremote_ip = remote_ip.ipl;
        match_socket.sremote_port = hframe.tcp_hdr.sport; // Remote Port match already matching!
        // Our Ack is sender's Sequence!
        match_socket.sack.u = hframe.tcp_hdr.seq.u+dlen+1; // +1: Bec. SYN rcvd.
        match_socket.sseq.w.h_word = net_service_cnt;   // Time ascending...
        match_socket.sseq.w.l_word = 0;    // Our relative Pointer (for HTTP)

        send_match_ok_TCP(0,0,TSYN+TACK); // Reply with a single SYN+ACK
        NET_DEBUG("<SYN+ACK SENT>");

        match_socket.state=TCP_SYNCON;  // SYN confirmed with SYN+ACK
        match_socket.retry_cnt=0;
        return EVENT_TCP_SYNRECEIVED; // Low-Byte added by caller!

#ifdef USE_TCP_CLIENT
    case TCP_SYNSENT:
        // NET_DEBUG("<ACTIVE OPEN SYN-RECEIVED>");
        if(!(hframe.tcp_hdr.flags&TSYN)) break;
        hframe.tcp_hdr.seq.u++;    // Count remote SYN
        match_socket.sack.u=hframe.tcp_hdr.seq.u; // +1: Bec. SYN rcvd.
#endif

    case TCP_SYNCON:
    case TCP_EST:	// Established, Connection OK
        if(!(hframe.tcp_hdr.flags&TACK)) break;
        if(dlen>MAX_RX) dlen=MAX_RX;  // IDIOTA! Clip data in size (don't know if this is safe?)

    // Here a small problem is silently ignored: A not acknowled Segment which is restransmitted larger
    // could contain old data as a part (maybe for TELNET...)
    // Silently assume all Segments have valid ACK

        if(match_socket.sack.u!=hframe.tcp_hdr.seq.u) {
            NET_DEBUG("<TCP_OOB>");
            return EVENT_TCP_OUTOFBOUNDS; // Ignore-out-of-bounds segments!
        }

        match_socket.state=TCP_EST;  // Connection now established

        match_socket.sack.u+=dlen;
        read_frame_data_8900((uint8_t *)(rcv_buf+rcv_ofs),dlen);  //+rcv_ofs Read Sender's Data, if any
        rcv_len=dlen;    // remember size of read data...
        if(!dlen) rcv_ofs=0;

    // Matching 3 Sockets? -> Clear ALL
        if(match_socket.buf_outsize3 && hframe.tcp_hdr.ack.u==match_socket.sseq_3){
            NET_DEBUG("<M123>");
            free_tx_buf(match_socket.p_outbuf3);
            free_tx_buf(match_socket.p_outbuf2);
            free_tx_buf(match_socket.p_outbuf1);
            match_socket.buf_outsize3=0;
            match_socket.buf_outsize2=0;
            match_socket.buf_outsize1=0;

            // Matching Sockets 2 and 1: Free 1,2, Shift 3 to 1
        }else if(match_socket.buf_outsize2 && hframe.tcp_hdr.ack.u==match_socket.sseq_2){
            NET_DEBUG("<M12>");
            free_tx_buf(match_socket.p_outbuf2);
            free_tx_buf(match_socket.p_outbuf1);

            match_socket.sseq_1=match_socket.sseq_3;
            match_socket.p_outbuf1=match_socket.p_outbuf3;
            match_socket.buf_outsize1=match_socket.buf_outsize3;

            match_socket.buf_outsize2=0;
            match_socket.buf_outsize3=0;

            // Matching Sockets 1 Free 1, Shift 2 to 1, 3 to 2
        }else if(match_socket.buf_outsize1 && hframe.tcp_hdr.ack.u==match_socket.sseq_1){
            NET_DEBUG("<M1>");
            free_tx_buf(match_socket.p_outbuf1);

            match_socket.sseq_1=match_socket.sseq_2;
            match_socket.p_outbuf1=match_socket.p_outbuf2;
            match_socket.buf_outsize1=match_socket.buf_outsize2;

            match_socket.sseq_2=match_socket.sseq_3;
            match_socket.p_outbuf2=match_socket.p_outbuf3;
            match_socket.buf_outsize2=match_socket.buf_outsize3;

            match_socket.buf_outsize3=0;

        }


        // Frame does not contain a TFIN so simply acknowledge it, if data od SYN received
        if(!(hframe.tcp_hdr.flags&TFIN)){
            if(dlen || (hframe.tcp_hdr.flags&TSYN)) send_match_ok_TCP(0,0,TACK); // Frame OK: Acknowledge immediatelly if data...
        }else if(hframe.tcp_hdr.flags&TFIN){ // Come to here if RST and/or received
            match_socket.sack.u++;  // Count remote FIN
            send_match_ok_TCP(0,0,TACK+TFIN+TPUSH); // Acknowledge + FIN
            match_socket.sseq.u++;  // Count our FIN after sending!...
            match_socket.state=TCP_FINCON; // FIN Confirmed
        }

        // Only if nothing available reset retry_counter...
        if(!match_socket.buf_outsize1) match_socket.retry_cnt=0;

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
        // printf("<<M:%ld H:%lx >>",match_socket.sack.u,hframe.tcp_hdr.seq.u);
        if(match_socket.sack.u!=hframe.tcp_hdr.seq.u) return EVENT_TCP_OUTOFBOUNDS; // Ignore-out-of-bounds segments!
        //NET_DEBUG("<Wait3LASTACK>");
        if(hframe.tcp_hdr.flags&TFIN){    // Fin accepted by Remote!
            match_socket.sack.u++;    		// Count remote FIN
            send_match_ok_TCP(0,0,TACK);   	// Frame OK: Acknowledge immediatelly!
            free_match_socket(); 			// Free Buffers if allocated...
            match_socket.state=TCP_CLOSED;  	// Connection ends NOW
            //NET_DEBUG("<FINAL ACK SENT CLOSED>");
        }
        match_socket.retry_cnt=0;
        return EVENT_TCP_WAITLASTACK;

    case TCP_FINCON: // Accept one last ACK
        if(!(hframe.tcp_hdr.flags&TACK)) break;
        if(match_socket.sack.u!=hframe.tcp_hdr.seq.u) return EVENT_TCP_OUTOFBOUNDS; // Ignore-out-of-bounds segments!

        match_socket.state=TCP_CLOSED;  	// Connection ends NOW
        free_match_socket(); 				// Free Buffers if allocated...
                                        // NET_DEBUG("<LAST FIN ACKNOWLEDGED>");
        match_socket.retry_cnt=0;
        return EVENT_TCP_CLOSED;
 }

 free_match_socket(); // Free Buffers if allocated...
 match_socket.state=TCP_CLOSED;
 send_incomming_reset_TCP(dlen, &remote_mac[0], remote_ip.ipl);  // Denie further request!
 return EVENT_TCP_ILLEGALFRAME; // Denie illegal frames;
}

/**********************************************************************************
* uint16_t final_timeout_socket();
*
* Socket has definitely timed out. Free it for other users...
**********************************************************************************/
uint16_t final_timeout_socket(void){

 //printf("TIMEOUT match_socket_type: %u\n",match_socket.socket_type);
 if(match_socket.socket_type==SOCKET_TCP){
#ifdef USE_TCP_CLIENT
     if(match_socket.state<ARPSENT)
#endif
  send_match_ok_TCP(0,0,TRST); // Reset this socket!
  free_match_socket(); // Free Buffers if allocated...
  //NET_DEBUG("<TIMEOUT RESET>");
  match_socket.state=TCP_CLOSED;  // ==0 (for UDP as well)
  return EVENT_TCP_TIMEOUT;
 }
 match_socket.state=0;  // ==0 (for UDP as well, but no action required)
 return EVENT_SOCKET_TIMEOUT;
}

/**********************************************************************************
* uint16_t retransmit_socket();
*
* Socket requires a retransmition
**********************************************************************************/
uint16_t retransmit_socket(void){
 unsigned long hseq;

 // printf(" >>--RE-TX:%u>>",match_socket.sremote_port);

 if(match_socket.socket_type==SOCKET_TCP){
  switch(match_socket.state){
  case TCP_SYNCON:    // Timeout after SYN-confirmed->Transmit Confirmation again
   send_match_ok_TCP(0,0,TSYN+TACK); // Transmit Again
   // NET_DEBUG("<TCP RETRANSMIT TSYN+TACK>");
   return EVENT_TCP_RETRANS;

  case TCP_EST:     // Timeout in an established Connection
   if(match_socket.buf_outsize1){  // Something un-acknowledged?
    //NET_DEBUG("<TCP RETRANSMIT EST>");
    // Seq. represents the sent data, so for resend subtract the block from seq, afterwards ad it...
    hseq=match_socket.sseq.u; // Save current Sequ (Pos.)
    // Rewind to Pos. before BUF1 was sent

    match_socket.sseq.u=match_socket.sseq_1-match_socket.buf_outsize1; // 32 Bit operation - This must be acknowledged to free the buffer.
    send_match_ok_TCP((uchar*)match_socket.p_outbuf1->buffer,match_socket.buf_outsize1,TACK+TPUSH);
    match_socket.sseq.u=hseq;  // Restore old Pointer

    return EVENT_TCP_RETRANS;
   }
   // NET_DEBUG("<TCP RT IDLE IDLE>");
   // Stack is idle: All ok
   match_socket.timer=TCP_IDLE_RETRIES;  // Socket OK, LONG TIMEOUT!!!
   return 0;

  case TCP_FINCON:
  case TCP_FINSENT:
   send_match_ok_TCP(0,0,TFIN+TACK+TPUSH); // Transmit, without any data after FIN_CON...
   // NET_DEBUG("<TCP FIN RETRANSMIT>");
   return EVENT_TCP_RETRANS;

#ifdef USE_TCP_CLIENT
  case ARPSENT:
   send_request_ARP(match_socket.sremote_ip);
   // NET_DEBUG("<(TCP) ARP RETRANSMIT>");
   return EVENT_TCP_RETRANS;

  case ARPREC:
   // NET_DEBUG("<(TCP) ARP-REQUEST RECEIVED!!!>");

   // Ports already setup!
   match_socket.sseq.w.h_word=net_service_cnt;   // Time ascending...
   match_socket.sseq.w.l_word=0;    // Our relative Pointer (for HTTP, -1 due to SYNC)
   match_socket.state=TCP_SYNSENT;  // SYN confirmed with SYN+ACK

  case TCP_SYNSENT:
   send_match_ok_TCP(0,0,TSYN); // Initiate Connection with a SYN
   // NET_DEBUG("<ACTIVE SYN SENT>");
   return 0; // Only 1 Try, No Retransmition!
#endif
  }
 }

#ifdef USE_UDP_CLIENT
     else if(match_socket.socket_type==SOCKET_UDP){
         switch(match_socket.state){
        case ARPSENT:
            send_request_ARP(match_socket.sremote_ip);
            // NET_DEBUG("<(UDP) ARP RETRANSMIT>");
            return EVENT_UDP_ARPRETRANS;

        default:
            // NET_DEBUG("<(UDP) TIMEOUT with ARP-REQUEST RECEIVED!!!>");

            match_socket.retry_cnt=0;                   // Never close an ARPED UDP-Socket...
            match_socket.timer=UDP_IDLE_RETRIES;        // Socket OK, LONG TIMEOUT!!! No change in state
            return 0;
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
uint16_t periodical_socket(void){
    uchar h;
    // First decrement sub-timer. If no 0: No Action required

    h=match_socket.timer-1;
    if(h){
        match_socket.timer=h;
        return 0;
    }


    match_socket.timer=BASIC_RETRY_TIMER;
    h=match_socket.retry_cnt+1;
    if(h==MAX_RETRIES){
        NET_DEBUG("Timeout");
        return final_timeout_socket();
    }else{
        match_socket.retry_cnt=h; // Retry again...
        return retransmit_socket();
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

 ohlen=hframe.tcp_hdr.hlen-80;
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
                            // First copy to MATCH_SOCKET
                            //xram_fast_copy((unsigned char *)psock,(unsigned char *)&match_socket,sizeof(UC_SOCKET));
                            memcpy(&match_socket, psock, sizeof(UC_SOCKET));
                            res=state_machine_TCP(dlen);     // Now Header read, ready to read data
                            // Copy back from MATCH_SOCKET and return
                            //xram_fast_copy((unsigned char *)&match_socket,(unsigned char *)psock,sizeof(UC_SOCKET));
                            memcpy(psock, &match_socket, sizeof(UC_SOCKET));
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
     for(ui=0;ui<MAX_SOCK;ui++,psock++){
         if(psock->socket_type==SOCKET_TCP){  // Only TCP-Sockets are of interest if an offered local port is matched
              if(psock->state==TCP_CLOSED && psock->local_port==hframe.tcp_hdr.dport){
                NET_DEBUG("!MATCH");
                // First copy to MATCH_SOCKET
                //xram_fast_copy((unsigned char *)psock,(unsigned char *)&match_socket,sizeof(UC_SOCKET));
                memcpy(&match_socket, psock, sizeof(UC_SOCKET));
                res=state_machine_TCP(dlen);     // Now Header read, ready to read data
                // Copy back from MATCH_SOCKET and return
                //xram_fast_copy((unsigned char *)&match_socket,(unsigned char *)psock,sizeof(UC_SOCKET));
                memcpy(psock, &match_socket, sizeof(UC_SOCKET));
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
uint16_t process_IP(void){
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
    }else if(pcol==6){ // TCP
        return process_TCP(dlen);
#ifdef USE_UDP
    }else if(pcol==17){ // UDP
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
uint16_t send_socket_udp(uchar sock, unsigned char * pbuf, uint16_t datalen){
    UC_SOCKET *psock;
    psock=&uc_socket[sock];
    if(psock->socket_type!=SOCKET_UDP) return EVENT_UDP_ERROR;
    //NET_DEBUG("dest MAC: %02x:%02x:%02x:%02x:%02x:%02x ", psock->sremote_mac[0],psock->sremote_mac[1],psock->sremote_mac[2],psock->sremote_mac[3],psock->sremote_mac[4],psock->sremote_mac[5]);
    send_upd(pbuf,datalen,psock->sremote_mac,psock->sremote_ip,psock->local_port,psock->sremote_port);
    return 0;
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
     UC_SOCKET *psock;
     psock=&uc_socket[sock];

	// Copy Socket to Working Socket
 	//xram_fast_copy((unsigned char *)psock,(unsigned char *)&match_socket,sizeof(UC_SOCKET));
    memcpy(&match_socket, psock,sizeof(UC_SOCKET));
 	if(match_socket.socket_type!=SOCKET_TCP || match_socket.state!=TCP_EST) return EVENT_TCP_DENIED;
 	if(!datalen) {
//		NET_DEBUG("<free>");
  		free_tx_buf(pbuf); // Free Buffer
  		return 0;  // IDIOTA!
 	}

 	// Bind Buffer try to allocate B1 first, then B2m then B3 else error
 	if(!match_socket.buf_outsize1){
  		match_socket.p_outbuf1=pbuf;
  		match_socket.buf_outsize1=datalen;
  		match_socket.sseq_1=match_socket.sseq.u+datalen;
//   	NET_DEBUG("<SB1>");
 	}else if(!match_socket.buf_outsize2){
  		match_socket.p_outbuf2=pbuf;
  		match_socket.buf_outsize2=datalen;
  		match_socket.sseq_2=match_socket.sseq.u+datalen;
//   	NET_DEBUG("<SB2>");
 	}else if(!match_socket.buf_outsize3){
  		match_socket.p_outbuf3=pbuf;
  		match_socket.buf_outsize3=datalen;
  		match_socket.sseq_3=match_socket.sseq.u+datalen;
//   	NET_DEBUG("<SB3>");
 	}else{
  // 	If data still pending: Error, Important: BUFFER NOT FREED!
//  	putchar('!');
  		return EVENT_TCP_TXPENDING; // Can't send, old data still waiting...
 	}
 	send_match_ok_TCP((uchar*)pbuf->buffer,datalen,TACK+TPUSH);
 	match_socket.sseq.u+=datalen; // 32 Bit operation - This must be acknowledged to free the buffer.

 // New TIMEOUT
 	match_socket.retry_cnt=0;
 	match_socket.timer=BASIC_RETRY_TIMER;

  // Copy back from MATCH_SOCKET and return
 	//xram_fast_copy((unsigned char *)&match_socket,(unsigned char *)psock,sizeof(UC_SOCKET));
    memcpy(psock, &match_socket, sizeof(UC_SOCKET));
 	return 0; // All OK
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
     UC_SOCKET *psock;
     psock=&uc_socket[sock];

 if(psock->socket_type!=SOCKET_TCP || psock->state!=TCP_EST) return EVENT_TCP_DENIED;
 if(!tx_bufleft) return EVENT_SOCKET_NOBUFFER;  // Stack may be ready, but no buffer available...

 if(flag){ // Check Ready for TX: BUF3 must be empty
  // If data still pending (Output Buffer full): Error
  if(psock->buf_outsize3) return EVENT_TCP_TXPENDING; // Can't send, old data still pending
 }else{  // Check Read for Close: BUF1 must be empty
  if(psock->buf_outsize1) return EVENT_TCP_TXPENDING; // Can't send, old data still pending

 }
 return 0; // SOCKEt IS READY!
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
    UC_SOCKET *psock;
    psock=&uc_socket[sock];
 // Copy Socket to Working Socket
    //xram_fast_copy((unsigned char *)psock,(unsigned char *)&match_socket,sizeof(UC_SOCKET));
    memcpy(&match_socket, psock, sizeof(UC_SOCKET));
    if(match_socket.socket_type!=SOCKET_TCP || !match_socket.state) return EVENT_TCP_DENIED; // Closing always possible...

    // If data still pending: Error
    if(match_socket.buf_outsize1) return EVENT_TCP_TXPENDING; // Can't send, old data still waiting...

    send_match_ok_TCP(0,0,TACK+TFIN+TPUSH);
    match_socket.sseq.u++; // 32 Bit operation - This must be acknowledged
    match_socket.state=TCP_FINSENT;

    // New TIMEOUT
    match_socket.retry_cnt=0;
    match_socket.timer=BASIC_RETRY_TIMER;

    // Copy back from MATCH_SOCKET and return
    //xram_fast_copy((unsigned char *)&match_socket,(unsigned char *)psock,sizeof(UC_SOCKET));
    memcpy(psock, &match_socket, sizeof(UC_SOCKET));

    // printf("<--CLOSE %u-->",match_socket.sremote_port);

    return 0; // All OK
    }

#ifdef USE_TCP_CLIENT
/**********************************************************************************
* uint16_t open_socket_tcp(sock,ipl,port);
*
* Initiate an active Open for a  given Socket
**********************************************************************************/
uint16_t open_socket_tcp(uchar sock,unsigned long remote_ipl,unsigned int remote_port){
     UC_SOCKET *psock;
     psock=&uc_socket[sock];
    // Copy Socket to Working Socket
    //xram_fast_copy((unsigned char *)psock,(unsigned char *)&match_socket,sizeof(UC_SOCKET));
    memcpy(&match_socket, psock, sizeof(UC_SOCKET));
    if(match_socket.socket_type!=SOCKET_TCP || match_socket.state) return EVENT_TCP_DENIED; // No Access to non

    match_socket.sremote_ip=remote_ipl;
    match_socket.sremote_port=remote_port;

    send_request_ARP(remote_ipl);
    match_socket.state=ARPSENT;

    // New TIMEOUT
    match_socket.retry_cnt=0;
    match_socket.timer=BASIC_RETRY_TIMER;

    // Copy back from MATCH_SOCKET and return
    //xram_fast_copy((unsigned char *)&match_socket,(unsigned char *)psock,sizeof(UC_SOCKET));
    memcpy(psock, &match_socket, sizeof(UC_SOCKET));
    return 0; // All OK
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
    UC_SOCKET *psock;

    psock=&uc_socket[sock];
    // Copy Socket to Working Socket
    //xram_fast_copy((unsigned char *)psock,(unsigned char *)&match_socket,sizeof(UC_SOCKET));
    memcpy(&match_socket, psock, sizeof(UC_SOCKET));
    if(match_socket.socket_type!=SOCKET_UDP || match_socket.state) return EVENT_UDP_DENIED; // No Access to non

    match_socket.sremote_ip=remote_ipl;
    match_socket.sremote_port=remote_port;

    if(remote_ipl!=0xffffffff){
		send_request_ARP(remote_ipl);
    	match_socket.state=ARPSENT;

    	// New TIMEOUT
    	match_socket.retry_cnt=0;
    	match_socket.timer=BASIC_RETRY_TIMER;
	}else{
		memset(match_socket.sremote_mac,0xff,6);
		match_socket.state=ARPREC;
		match_socket.retry_cnt=0;
    	match_socket.timer=1;
	}
    // Copy back from MATCH_SOCKET and return
    //xram_fast_copy((unsigned char *)&match_socket,(unsigned char *)psock,sizeof(UC_SOCKET));
    memcpy(psock,&match_socket, sizeof(UC_SOCKET));

    return 0; // All OK
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
        UC_SOCKET *psock;
        psock=&uc_socket[sock];
    // Copy Socket to Working Socket
    //xram_fast_copy((unsigned char *)psock,(unsigned char *)&match_socket,sizeof(UC_SOCKET));
    memcpy(&match_socket, psock, sizeof(UC_SOCKET));
    if(match_socket.socket_type!=SOCKET_UDP || !match_socket.state) return EVENT_UDP_DENIED; // Closing always possible...
    match_socket.state=0;   // That's all to close...
    // Copy back from MATCH_SOCKET and return
    //xram_fast_copy((unsigned char *)&match_socket,(unsigned char *)psock,sizeof(UC_SOCKET));
    memcpy(psock,&match_socket, sizeof(UC_SOCKET));
    return 0; // All OK
}
#endif



/**********************************************************************************
* uint16_t poll_net(void)
*
* Top-Level-Multiplexer, should be happy with SNAP frames too...
* Will return !=0 if Event was encountered
**********************************************************************************/
uint16_t poll_net(void){
 uint16_t RxEvent; //,len;
 uint16_t type;
 //uchar bfr[2048];

//if(!IRQLINE) return 0;
//if (IRQLINE) {
	//while(!IRQLINE);
//	putchar('!');
//	RxEvent=Read_8900(ISQ_PORT);

	//printf("ev %x\n",RxEvent);
	//if (!(RxEvent&0xffc0)) return 0;

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
        read_frame_data_8900(&remote_mac[0],6); // Read Sender's MAC			6
        //memcpy(&temp[3],remote_mac,6);  //3,4,5

        //temp[6]=type=Read_Frame_word_8900();										//	2
        type=Read_Frame_word_8900();										//	2
        /*uchar const * p_char = (uchar const *)temp;
        for(uint16_t i=0;i<(7*2); i++) {
            iprintf("%02X ",*p_char++);
        }*/
        //NET_DEBUG("Remote MAC: %02x:%02x:%02x:%02x:%02x:%02x ", remote_mac[0],remote_mac[1],remote_mac[2],remote_mac[3],remote_mac[4],remote_mac[5]);
        //NET_DEBUG(" Type %x %x\r\n",type,len);
        if(type<=0x5DC){ // SNAP Frame! Eat LSAP-Ctrl-OUI and retry...
            if(net_match_uint(0xAAAA)) return 0;							//  (2)
            if(net_match_ulong(0x3000000)) return 0;						//  (4)
            type=Read_Frame_word_8900(); // Read NEW type...					(2)
                                                                            //  = 20
        }
        // *** First stage input filter/multiplexer for received frames ***
        if(type==0x0806){ // This is an ARP-Frame!								= 18 (14)
            return process_ARP();
        }else if(type==0x800){ // IP Header!
            return process_IP();
        } // ignore unknown frames
    }else{
    // Do soemthing periodically net_timer decremented 2 times per Sec!... ***
        if(!net_timer){
            UC_SOCKET *psock;
            uchar ui;
            uint16_t res;
            net_service_cnt++;  // Sequence-Timer Highbyte
            net_timer=TIMER_FRQ/2; // about 0.5 Hz ONLY after one complete IDLE-pass...
            psock=uc_socket;
            for(ui=0;ui<MAX_SOCK;ui++,psock++){
                if(psock->state){  // Examine only non-0-state-Sockets
                // First copy to MATCH_SOCKET
                    //xram_fast_copy((unsigned char *)psock,(unsigned char *)&match_socket,sizeof(UC_SOCKET));
                    memcpy(&match_socket,psock, sizeof(UC_SOCKET));
                    res=periodical_socket();     // Retry transmition... (Could be UDP for ARP as well...)
                    // Copy back from MATCH_SOCKET and return
                    //xram_fast_copy((unsigned char *)&match_socket,(unsigned char *)psock,sizeof(UC_SOCKET));
                    memcpy(psock,&match_socket, sizeof(UC_SOCKET));
                    if(res) return res+ui; 		// Return immediatelly if necessary
                }
            }
            return EVENT_SOCKET_IDLETIMER; // About twice/sec
        }
    }
 return 0; // NO EVENT
}


#if 0
/**********************************************************************************
* IRQ: The system timer. Count down net_timer, leave it if 0!
**********************************************************************************/
//#pragma option -g0  // We don't want to have debug info in the interrupt
//IRQ_VECTOR(timer0int,TIMER0)
void timer0int (void) interrupt 1 {
 uchar data h;
 h=net_timer;
 if(h) net_timer=(--h);
}
//#pragma option -g   // Restore debug info level to default
#endif

volatile bool timer_flag=false;

void timer_func() {
  static uint8_t _prescaler = TIMER;
  if (!--_prescaler) {
    _prescaler=  TIMER;
    timer_flag=true;
    uchar h=net_timer;
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
 /*my_mac[0]=0; // High 4 of MAC Bytes fixed to 0
 my_mac[1]=0x51;*/
//	memset(tx_buffers,0,sizeof(tx_buffers));
 //xram_fast_copy(my_ip.bytes,my_mac+2,4); // Lower 4 Bytes: IP of this node

 if(cs_init()) return 1; // ERROR (MAC set as global!)
 rcv_ofs=0;
 // Use Timer 0 as TCP-Timer
#if 0
 EAL=0;  // Disable all IRQ

 TMOD &=0xF0;
 TMOD |=0x01; // 16 bit Prescaler: 28.125 Hz
 TR0=1;  // Timer 0 RUN
 ET0=1;

 EAL=1;  // Enable all IRQ
#endif
 _delay_ms(100); // May needs a few msec until ready
 return 0;
}


// END
