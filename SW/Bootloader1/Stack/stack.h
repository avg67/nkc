/*----------------------------------------------------------------------------
 Copyright:      Radig Ulrich  mailto: mail@ulrichradig.de
 Author:         Radig Ulrich
 Remarks:
 known Problems: none
 Version:        24.10.2007
 Description:    Ethernet Stack

 Dieses Programm ist freie Software. Sie k�nnen es unter den Bedingungen der
 GNU General Public License, wie von der Free Software Foundation ver�ffentlicht,
 weitergeben und/oder modifizieren, entweder gem�� Version 2 der Lizenz oder
 (nach Ihrer Option) jeder sp�teren Version.

 Die Ver�ffentlichung dieses Programms erfolgt in der Hoffnung,
 da� es Ihnen von Nutzen sein wird, aber OHNE IRGENDEINE GARANTIE,
 sogar ohne die implizite Garantie der MARKTREIFE oder der VERWENDBARKEIT
 F�R EINEN BESTIMMTEN ZWECK. Details finden Sie in der GNU General Public License.

 Sie sollten eine Kopie der GNU General Public License zusammen mit diesem
 Programm erhalten haben.
 Falls nicht, schreiben Sie an die Free Software Foundation,
 Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307, USA.
------------------------------------------------------------------------------*/

#ifndef _STACK_H
#define _STACK_H

#include <stdio.h>

//#define DEBUG iprintf	//mit Debugausgabe
#define DEBUG(...) 			//ohne Debugausgabe

#define MAX_APP_ENTRY 5

/*#define IP_EEPROM_STORE 30
#define NETMASK_EEPROM_STORE 34
#define ROUTER_IP_EEPROM_STORE 38*/

struct
{
    volatile unsigned char data_present : 1;
    volatile unsigned char timer        : 1;
}eth;

typedef struct
{
    unsigned short port;		// Port
    void(*fp)(unsigned char);  	// Zeiger auf auszuf�hrende Funktion
} TCP_PORT_ITEM;

typedef struct
{
    unsigned short port;		// Port
    void(*fp)(unsigned char);  	// Zeiger auf auszuf�hrende Funktion
} UDP_PORT_ITEM;

typedef union{
 unsigned char bytes[4];  // Byte representation
 unsigned long ipl;       // 32bit representation
} IP_ADR;

TCP_PORT_ITEM TCP_PORT_TABLE[MAX_APP_ENTRY];
UDP_PORT_ITEM UDP_PORT_TABLE[MAX_APP_ENTRY];

//#define HTONS(n) (unsigned int)((((unsigned int) (n)) << 8) | (((unsigned int) (n)) >> 8))
#define HTONS(n) (n)
//#define HTONS32(x) ((x & 0xFF000000)>>24)+((x & 0x00FF0000)>>8)+((x & 0x0000FF00)<<8)+((x & 0x000000FF)<<24)
#define HTONS32(x) (x)

extern IP_ADR myip;
extern IP_ADR netmask;
extern IP_ADR router_ip;
extern IP_ADR broadcast_ip;


extern unsigned short IP_id_counter;

#if defined (ndrcomp)
    #define MAX_TCP_ENTRY 5
    #define MAX_UDP_ENTRY 5
    #define MAX_ARP_ENTRY 5
    #define MTU_SIZE 1200
#endif

#define COMPOSE_IP(x,a,b,c,d)  {x.bytes[0]=a;x.bytes[1]=b;x.bytes[2]=c;x.bytes[3]=d;}

#define ARP_REPLY_LEN		60
#define ICMP_REPLY_LEN		98
#define ARP_REQUEST_LEN		42

extern unsigned char eth_buffer[MTU_SIZE+1];

#define TCP_TIME_OFF 		0xFF
#define TCP_MAX_ENTRY_TIME	3
#define MAX_TCP_PORT_OPEN_TIME 30 //30sekunden
#define MAX_TCP_ERRORCOUNT	5

#define ARP_MAX_ENTRY_TIME 100 //100sec.


#define MAX_WINDOWS_SIZE (MTU_SIZE-100)

struct arp_table
{
    volatile unsigned char arp_t_mac[6];
    volatile unsigned long arp_t_ip;
    volatile unsigned short arp_t_time;
};

struct tcp_table
{
    volatile unsigned long ip				;
    volatile unsigned short  src_port		;
    volatile unsigned short  dest_port		;
    volatile unsigned long ack_counter	;
    volatile unsigned long seq_counter	;
    volatile unsigned char status			;
    volatile unsigned short  app_status		;
    volatile unsigned char time			;
    volatile unsigned char error_count	;
    volatile unsigned char first_ack	:1	;
};

typedef struct
{
    unsigned char ip1[4];
    volatile unsigned char no;
    volatile unsigned char result;
}PING_STRUCT;

extern PING_STRUCT ping;
//----------------------------------------------------------------------------
//Prototypen
void poll_isr();
//unsigned short  htons(unsigned short val);
//unsigned long htons32(unsigned long val);
//Converts integer variables to network Byte order
static inline __attribute__((always_inline)) unsigned short htons(unsigned short val)
{
  return HTONS(val);
}
//----------------------------------------------------------------------------
//Converts integer variables to network Byte order
static inline __attribute__((always_inline)) unsigned long htons32(unsigned long val)
{
  return HTONS32(val);
}

void stack_init (void);
void check_packet (void);
void eth_get_data (void);
//unsigned long get_eeprom_value (unsigned int eeprom_adresse,unsigned long default_value);

void default_ip();
void print_ip();
void new_eth_header (unsigned char *,unsigned long);

char arp_entry_search (unsigned long);
void arp_reply (void);
void arp_entry_add (void);
char arp_request (unsigned long);

void make_ip_header (unsigned char *,unsigned long);
void icmp_send (unsigned long,unsigned char,unsigned char,unsigned short,unsigned short);
unsigned short checksum (unsigned char *,unsigned short,unsigned long);

void udp_socket_process(void);

void tcp_entry_add (unsigned char *);
void tcp_socket_process(void);
char tcp_entry_search (unsigned long ,unsigned short);
void tcp_Port_close (unsigned char);
void tcp_port_open (unsigned long, unsigned short, unsigned short);
void tcp_index_del (unsigned char);
void create_new_tcp_packet(unsigned short,unsigned char);
void create_new_udp_packet(	unsigned short,unsigned short,unsigned short,unsigned long);

void find_and_start (unsigned char index);
void tcp_timer_call (void);
void arp_timer_call (void);
void add_tcp_app (unsigned short, void(*fp1)(unsigned char));
void kill_tcp_app (unsigned short port);
void add_udp_app (unsigned short, void(*fp1)(unsigned char));
void kill_udp_app (unsigned short port);
void change_port_tcp_app (unsigned short, unsigned short);
void pinging (void);

#define ETHER_OFFSET			0x00
#define ARP_OFFSET				0x0E
#define IP_OFFSET				0x0E
#define ICMP_OFFSET				0x22
#define ICMP_DATA				0x2A
#define TCP_OFFSET				0x22
#define UDP_OFFSET				0x22

struct arp_table arp_entry[MAX_ARP_ENTRY];
struct tcp_table tcp_entry[MAX_TCP_ENTRY+1];

//IP Protocol Types
#define	PROT_ICMP				0x01	//zeigt an die Nutzlasten enthalten das ICMP Prot
#define	PROT_TCP				0x06	//zeigt an die Nutzlasten enthalten das TCP Prot.
#define	PROT_UDP				0x11	//zeigt an die Nutzlasten enthalten das UDP Prot.

//Defines für IF Abfrage
#define IF_MYIP 				(ip->IP_Destaddr==myip.ipl)
#define IP_UDP_PACKET 			(ip->IP_Proto == PROT_UDP)
#define IP_TCP_PACKET 			(ip->IP_Proto == PROT_TCP)
#define IP_ICMP_PACKET 			(ip->IP_Proto == PROT_ICMP)

//Defines für if Abfrage
#define ETHERNET_IP_DATAGRAMM	ethernet->EnetPacketType == 0x0008
#define ETHERNET_ARP_DATAGRAMM 	ethernet->EnetPacketType == 0x0608

#define IP_VERS_LEN 			20
#define TCP_HDR_LEN 			20
#define UDP_HDR_LEN				8
#define ETH_HDR_LEN 			14
#define TCP_DATA_START			(IP_VERS_LEN + TCP_HDR_LEN + ETH_HDR_LEN)
#define UDP_DATA_START			(IP_VERS_LEN + UDP_HDR_LEN + ETH_HDR_LEN)
#define UDP_DATA_END_VAR        (ETH_HDR_LEN + ((eth_buffer[IP_PKTLEN]<<8)+eth_buffer[IP_PKTLEN+1]) - UDP_HDR_LEN + 8)

#define	TCP_HDRFLAGS_FIX		0x2E
#define TCP_DATA_START_VAR		(ETH_HDR_LEN + IP_VERS_LEN + ((eth_buffer[TCP_HDRFLAGS_FIX] & 0xF0) >>2))

#define	IP_PKTLEN				0x10
#define TCP_DATA_END_VAR 		(ETH_HDR_LEN + IP_VERS_LEN + ((eth_buffer[IP_PKTLEN]<<8)+eth_buffer[IP_PKTLEN+1]) - ((eth_buffer[TCP_HDRFLAGS_FIX] & 0xF0) >>2))

//TCP Flags
#define  FIN_FLAG				0x01	//Daten�bertragung beendet (finished)
#define  SYN_FLAG				0x02	//Verbindungs aufbauen (synchronize)
#define  RST_FLAG				0x04	//Verbindung neu initialisieren (reset)
#define  PSH_FLAG				0x08	//Daten�bergabe an Anwendung beschleunigen (push)
#define  ACK_FLAG				0x10	//Daten�bertragung best�tigen (acknowledged)

//----------------------------------------------------------------------------
//Aufbau eines Ethernetheader
//
//
//
//
struct Ethernet_Header	{
    unsigned char EnetPacketDest[6];	//MAC Zieladresse 6 Byte
    unsigned char EnetPacketSrc[6];	//MAC Quelladresse 6 Byte
    unsigned short EnetPacketType;		//Nutzlast 0x0800=IP Datagramm;0x0806 = ARP
};

//----------------------------------------------------------------------------
//Aufbau eines ARP Header
//
//	2 BYTE Hardware Typ				|	2 BYTE Protokoll Typ
//	1 BYTE L�nge Hardwareadresse	|	1 BYTE L�nge Protokolladresse
//	2 BYTE Operation
//	6 BYTE MAC Adresse Absender		|	4 BYTE IP Adresse Absender
//	6 BYTE MAC Adresse Empf�nger	|	4 BYTE IP Adresse Empf�nger
struct ARP_Header	{
    unsigned short ARP_HWType;		//Hardware Typ enth�lt den Code f�r Ethernet oder andere Link Layer
    unsigned short ARP_PRType;		//Protokoll Typ enth�lt den Code f�r IP o. anderes �bertragungsprotokoll
    unsigned char ARP_HWLen;		//L�nge der Hardwareadresse enth�lt 6 f�r 6 Byte lange MAC Adressen
    unsigned char ARP_PRLen;		//L�nge der Protocolladresse enth�lt 4 f�r 4 Byte lange IP Adressen
    unsigned short ARP_Op;			//Enth�lt Code der signalisiert ob es sich um eine Anfrage o. Antwort handelt
    unsigned char ARP_SHAddr[6];	//Enth�lt die MAC Adresse des Anfragenden
    unsigned long ARP_SIPAddr;    //Enth�lt die IP Adresse des Absenders
    unsigned char ARP_THAddr[6];	//MAC Adresse Ziel, ist in diesem Fall 6 * 00,da die Adresse erst noch herausgefunden werden soll (ARP Request)
    unsigned long ARP_TIPAddr;    //IP Adresse enth�lt die IP Adresse zu der die Kommunikation aufgebaut werden soll
};

//----------------------------------------------------------------------------
//Aufbau eines IP Datagramms (B=BIT)
//
//4B Version	|4B Headergr.	|8B Tos	|16B Gesamtl�nge in Bytes
//16B Identifikation			|3B Schalter	|13B Fragmentierungsposition
//8B Time to Live	|8B Protokoll	|16B Header Pr�fsumme
//32B IP Quelladresse
//32B IB Zieladresse
struct IP_Header	{
    unsigned char	IP_Vers_Len;	//4 BIT Die Versionsnummer von IP,
                                    //meistens also 4 + 4Bit Headergr��e
    unsigned char	IP_Tos;			//Type of Service
    unsigned short IP_Pktlen;		//16 Bit Komplette L�ng des IP Datagrams in Bytes
    unsigned short	IP_Id;			//ID des Packet f�r Fragmentierung oder
                                    //Reassemblierung
    unsigned short	IP_Frag_Offset;	//wird benutzt um ein fragmentiertes
                                    //IP Packet wieder korrekt zusammenzusetzen
    unsigned char	IP_ttl;			//8 Bit Time to Live die lebenszeit eines Paket
    unsigned char	IP_Proto;		//Zeigt das h�herschichtige Protokoll an
                                    //(TCP, UDP, ICMP)
    unsigned short	IP_Hdr_Cksum;	//Checksumme des IP Headers
    unsigned long	IP_Srcaddr;		//32 Bit IP Quelladresse
    unsigned long	IP_Destaddr;	//32 Bit IP Zieladresse
};

//----------------------------------------------------------------------------
//Aufbau einer ICMP Nachricht
//
//8 BIT Typ	|8 BIT Code	|16 BIT Pr�fsumme
//Je nach Typ			|Nachricht unterschiedlich
//Testdaten
//
//8 BIT Typ = 0 Echo Reply oder 8 Echo request
struct ICMP_Header {
    unsigned char     	ICMP_Type;		//8 bit typ identifiziert Aufgabe der Nachricht
                                        //0 = Echo Reply 8 = Echo Request
    unsigned char     	ICMP_Code;		//8 Bit Code enth�lt Detailangaben zu bestimmten Typen
    unsigned short     	ICMP_Cksum;		//16 Bit Pr�fsumme enth�lt die CRC Pr�fsumme
    unsigned short     	ICMP_Id;		//2 byte Identifizierung
    unsigned short     	ICMP_SeqNum;	//Sequenznummer
};

//----------------------------------------------------------------------------
//TCP Header Layout
//
//
struct TCP_Header {
    unsigned short 	TCP_SrcPort;	//der Quellport f�r die Verbindung (Socket)
    unsigned short 	TCP_DestPort;	//der Zielport f�r die Verbindung (Socket)
    unsigned long	TCP_Seqnum;	//numerierter Bytestrom
    unsigned long	TCP_Acknum;	//numerierter Bytestrom (Gegenrichtung)
    unsigned char  TCP_Hdrlen;
    unsigned char 	TCP_HdrFlags;//4Bit L�nge des Headers in 32 Bit schritten rest Flags
    unsigned short	TCP_Window;	//Fenstergr��e max. 64K Byte
    unsigned short	TCP_Chksum;	//Enth�lt eine Pr�fsumme �ber Header und Datenbereich
    unsigned short	TCP_UrgentPtr;	//16 Bit f�r dringende �bertragung
};

//----------------------------------------------------------------------------
//UDP Header Layout
//
//
struct UDP_Header {
    unsigned short 	udp_SrcPort;	//der Quellport f�r die Verbindung (Socket)
    unsigned short 	udp_DestPort;	//der Zielport f�r die Verbindung (Socket)
    unsigned short  udp_Hdrlen;
    unsigned short	udp_Chksum;	//Enth�lt eine Pr�fsumme �ber Header und Datenbereich
};

#endif // #define _STACK_H
