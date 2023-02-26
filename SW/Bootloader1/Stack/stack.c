/*----------------------------------------------------------------------------
 Copyright:      Radig Ulrich  mailto: mail@ulrichradig.de
 Author:         Radig Ulrich
 Remarks:
 known Problems: none
 Version:        24.10.2007
 Description:    Ethernet Stack

 Dieses Programm ist freie Software. Sie können es unter den Bedingungen der
 GNU General Public License, wie von der Free Software Foundation ver�ffentlicht,
 weitergeben und/oder modifizieren, entweder gemäß Version 2 der Lizenz oder
 (nach Ihrer Option) jeder späteren Version.

 Die Veröffentlichung dieses Programms erfolgt in der Hoffnung,
 daß es Ihnen von Nutzen sein wird, aber OHNE IRGENDEINE GARANTIE,
 sogar ohne die implizite Garantie der MARKTREIFE oder der VERWENDBARKEIT
 FüR EINEN BESTIMMTEN ZWECK. Details finden Sie in der GNU General Public License.

 Sie sollten eine Kopie der GNU General Public License zusammen mit diesem
 Programm erhalten haben.
 Falls nicht, schreiben Sie an die Free Software Foundation,
 Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307, USA.
------------------------------------------------------------------------------*/
#include <string.h>
//#include "httpd.h"
//#include "telnetd.h"
#include "config.h"
#if USE_ENC28J60
 #include "enc28j60.h"
#endif
#if USE_CS8900
 #include "cs8900_eth.h"
#endif

//#include "dnsc.h"
#include "dhcpc.h"
#include "stack.h"

//#define DEBUG iprintf
#define DEBUG(...)
#if USE_TCP
TCP_PORT_ITEM TCP_PORT_TABLE[MAX_APP_ENTRY] = // Port-Tabelle
{
	{0,0},
	{0,0},
	{0,0}
};
#endif
UDP_PORT_ITEM UDP_PORT_TABLE[MAX_APP_ENTRY] = // Port-Tabelle
{
	{0,0},
	{0,0},
	{0,0}
};

IP_ADR myip;
IP_ADR netmask;
IP_ADR router_ip;
IP_ADR broadcast_ip;
unsigned short IP_id_counter = 0;
unsigned char eth_buffer[MTU_SIZE+1] __attribute__ ((aligned (2))) ;

struct arp_table arp_entry[MAX_ARP_ENTRY];

//TCP Stack Size
//+1 damit eine Verbindung bei vollen Stack abgewiesen werden kann
struct tcp_table tcp_entry[MAX_TCP_ENTRY+1];

PING_STRUCT ping;

//----------------------------------------------------------------------------


void default_ip() {
    COMPOSE_IP(myip,10,0,0,9);
    COMPOSE_IP(netmask,255,255,255,0);
    COMPOSE_IP(router_ip,10,0,0,138);
}

void print_ip() {
   iprintf("My IP: %1i.%1i.%1i.%1i\r\n\r\n",myip.bytes[0],myip.bytes[1],myip.bytes[2],myip.bytes[3]);

}

//----------------------------------------------------------------------------
//Trägt Anwendung in Anwendungsliste ein
void stack_init (void)
{
#if USE_DHCP
  COMPOSE_IP(myip,0,0,0,0);
  COMPOSE_IP(netmask,255,255,255,255);
  COMPOSE_IP(router_ip,0,0,0,0);
#else
	default_ip();
#endif
	broadcast_ip.ipl = (myip.ipl & netmask.ipl) | (~netmask.ipl);

    #if USE_DNS
    //DNS-Server IP aus EEPROM auslesen
    //(*((unsigned long*)&dns_server_ip[0])) = get_eeprom_value(DNS_IP_EEPROM_STORE,DNS_IP);
	dns_server_ip.ipl = 0u;
    #endif

	/*NIC Initialisieren*/
	DEBUG("\n\rNIC init:");
#if USE_ENC28J60
	ETH_INIT();
#endif
#if USE_CS8900
    cs_init();
#endif
	//DEBUG("My IP: %1i.%1i.%1i.%1i\r\n\r\n",myip.bytes[0],myip.bytes[1],myip.bytes[2],myip.bytes[3]);
	//print_ip();
}

//----------------------------------------------------------------------------
#if USE_TCP
//Verwaltung des TCP Timers
void tcp_timer_call (void)
{
    unsigned char index;
    for (index = 0;index<MAX_TCP_ENTRY;index++)
    {
        if (tcp_entry[index].time == 0)
        {
            if (tcp_entry[index].ip != 0)
            {
                tcp_entry[index].time = TCP_MAX_ENTRY_TIME;
                if ((tcp_entry[index].error_count++) > MAX_TCP_ERRORCOUNT)
                {
                    DEBUG("Eintrag wird entfernt MAX_ERROR STACK:%i\r\n",index);
                    ETH_INT_DISABLE;
                    tcp_entry[index].status =  RST_FLAG | ACK_FLAG;
                    create_new_tcp_packet(0,index);
                    ETH_INT_ENABLE;
                    tcp_index_del(index);
                }
                else
                {
                    DEBUG("Packet wird erneut gesendet STACK:%i\r\n",index);
                    find_and_start (index);
                }
            }
        }
        else
        {
            if (tcp_entry[index].time != TCP_TIME_OFF)
            {
                tcp_entry[index].time--;
            }
        }
    }
}
#endif
//----------------------------------------------------------------------------
//Verwaltung des ARP Timers
void arp_timer_call (void)
{
    for (uint16_t a = 0;a<MAX_ARP_ENTRY;a++)
    {
        if (arp_entry[a].arp_t_time == 0)
        {
            for (uint16_t b = 0;b<6;b++)
            {
                arp_entry[a].arp_t_mac[b]= 0;
            }
            arp_entry[a].arp_t_ip = 0;
        }
        else
        {
            arp_entry[a].arp_t_time--;
        }
    }
}
#if USE_TCP
//----------------------------------------------------------------------------
//Tr�gt TCP PORT/Anwendung in Anwendungsliste ein
void add_tcp_app (unsigned short port, void(*fp1)(unsigned char))
{
    unsigned char port_index = 0;
    //Freien Eintrag in der Anwendungliste suchen
    while (TCP_PORT_TABLE[port_index].port)
    {
        port_index++;
    }
    if (port_index >= MAX_APP_ENTRY)
    {
        DEBUG("TCP Zuviele Anwendungen wurden gestartet\r\n");
        return;
    }
    DEBUG("TCP Anwendung wird in Liste eingetragen: Eintrag %i\r\n",port_index);
    TCP_PORT_TABLE[port_index].port = port;
    TCP_PORT_TABLE[port_index].fp = *fp1;
    return;
}

//----------------------------------------------------------------------------
//�nderung der TCP PORT/Anwendung in Anwendungsliste
void change_port_tcp_app (unsigned short port_old, unsigned short port_new)
{
    unsigned char port_index = 0;
    //Freien Eintrag in der Anwendungliste suchen
    while (TCP_PORT_TABLE[port_index].port && TCP_PORT_TABLE[port_index].port != port_old)
    {
        port_index++;
    }
    if (port_index >= MAX_APP_ENTRY)
    {
        DEBUG("(Port�nderung) Port wurde nicht gefunden\r\n");
        return;
    }
    DEBUG("TCP Anwendung Port �ndern: Eintrag %i\r\n",port_index);
    TCP_PORT_TABLE[port_index].port = port_new;
    return;
}
#endif
//----------------------------------------------------------------------------
//Trägt UDP PORT/Anwendung in Anwendungsliste ein
void add_udp_app (unsigned short port, void(*fp1)(unsigned char))
{
    uint16_t port_index = 0;
    //Freien Eintrag in der Anwendungliste suchen
    while (UDP_PORT_TABLE[port_index].port)
    {
        port_index++;
    }
    if (port_index >= MAX_APP_ENTRY)
    {
        DEBUG("Zuviele UDP Anwendungen wurden gestartet\r\n");
        return;
    }
    DEBUG("UDP Anwendung wird in Liste eingetragen: Eintrag %i\r\n",port_index);
    UDP_PORT_TABLE[port_index].port = port;
    UDP_PORT_TABLE[port_index].fp = *fp1;
    return;
}

//----------------------------------------------------------------------------
//L�scht UDP Anwendung aus der Anwendungsliste
void kill_udp_app (unsigned short port)
{
    uint16_t i;

    for (i = 0; i < MAX_APP_ENTRY; i++)
    {
        if ( UDP_PORT_TABLE[i].port == port )
        {
            UDP_PORT_TABLE[i].port = 0;
        }
    }
    return;
}

void __attribute__((optimize("-O3"))) poll_isr() {
#if USE_ENC28J60
    if (ETH_INT_ACTIVE) {
      //unsigned char v = enc_read_reg(ENC_REG_EIR);     DEBUG("EIR %2x ", (unsigned)v);
      //v = enc_read_reg(ENC_REG_ESTAT);   DEBUG("ESTAT %2x\n\r", (unsigned)v);
      eth.data_present = 1;
    }
#endif
#if USE_CS8900
    //const uint16_t ppp =Read_8900(CS8900.add_l);
    const uint16_t status = Read_PP_8900(PP_RxEvent);
    if(status & RX_OK) {

        eth.data_present = 1;
        //DEBUG("Data present\r\n");
    }
#endif
}

//----------------------------------------------------------------------------
//Interrupt von der Netzwerkkarte
/*ISR (ETH_INTERRUPT)
{
	eth.data_present = 1;
    stack_watchdog   = 0;
	ETH_INT_DISABLE;
}*/

//----------------------------------------------------------------------------
//ETH get data
void __attribute__((optimize("-O3"))) eth_get_data (void)
{
    if(eth.timer)
    {
    //iprintf("TIC ");
#if USE_TCP
        tcp_timer_call();
#endif
        arp_timer_call();
        eth.timer = 0;
    }
    if(eth.data_present)
    {
    #if USE_ENC28J60
        while(ETH_INT_ACTIVE)
        {
    #endif
    #if USE_CS8900
        //while((Read_PP_8900(PP_RxEvent) & RX_OK)!= 0u)
        {
    #endif

    #if USE_RTL8019
        if ( (ReadRTL(RTL_ISR)&(1<<OVW)) != 0)
        {
            DEBUG ("Overrun!\n");
        }

        if ( (ReadRTL(RTL_ISR) & (1<<PRX)) != 0)
        {
            unsigned char ByteH = 0;
            unsigned char ByteL = 1;

            while (ByteL != ByteH) //(!= bedeutet ungleich)
            {
    #endif
                unsigned short packet_length;

                packet_length = ETH_PACKET_RECEIVE(MTU_SIZE,eth_buffer);
                if(packet_length > 0)
                {
                    eth_buffer[packet_length+1] = 0;
                    check_packet();
                }

    #if USE_RTL8019
                //auslesen des Empfangsbuffer BNRY = CURR
                ByteL = ReadRTL(BNRY); //auslesen NIC Register bnry
                WriteRTL ( CR ,(1<<STA|1<<RD2|1<<PS0));

                ByteH = ReadRTL(CURR); //auslesen NIC Register curr
                WriteRTL ( CR ,(1<<STA|1<<RD2));
            }
    #endif
        }
    #if USE_RTL8019
        Networkcard_INT_RES();
        Networkcard_Start();
    #endif
        eth.data_present = 0;
        ETH_INT_ENABLE;
    }
    return;
}
//----------------------------------------------------------------------------
//Check Packet and call Stack for TCP or UDP
void __attribute__((optimize("-O3"))) check_packet (void)
{
    struct Ethernet_Header *ethernet;    //Pointer auf Ethernet_Header
    struct IP_Header       *ip;          //Pointer auf IP_Header
    //struct TCP_Header      *tcp;         //Pointer auf TCP_Header
    struct ICMP_Header     *icmp;        //Pointer auf ICMP_Header

    ethernet = (struct Ethernet_Header *)&eth_buffer[ETHER_OFFSET];
    ip       = (struct IP_Header       *)&eth_buffer[IP_OFFSET];
    //tcp      = (struct TCP_Header      *)&eth_buffer[TCP_OFFSET];
    icmp     = (struct ICMP_Header     *)&eth_buffer[ICMP_OFFSET];

    //iprintf("PacketType: 0x%x\r\n",ethernet->EnetPacketType);

    if(ethernet->EnetPacketType == HTONS(0x0806) )     //ARP
    {
        arp_reply(); // check arp packet request/reply
    }
    else
    {
        if( ethernet->EnetPacketType == HTONS(0x0800) )  // if IP
        {
            if( ip->IP_Destaddr == myip.ipl )  // if my IP address
            {
                arp_entry_add();  ///Refresh des ARP Eintrages
                if(ip->IP_Proto == PROT_ICMP)
                {
                    switch ( icmp->ICMP_Type )
                    {
                        case (8): //Ping reqest
                            icmp_send(ip->IP_Srcaddr,0,0,icmp->ICMP_SeqNum,icmp->ICMP_Id);
                            iprintf("PING request\r\n");
                            break;

                        case (0): //Ping reply
                            if ((*((unsigned long*)&ping.ip1[0])) == ip->IP_Srcaddr)
                            {
                                DEBUG("PING reply\r\n");
                                ping.result |= 0x01;
                            }
                            DEBUG("%i",    (ip->IP_Srcaddr&0x000000FF)     );
                            DEBUG(".%i",  ((ip->IP_Srcaddr&0x0000FF00)>>8 ));
                            DEBUG(".%i",  ((ip->IP_Srcaddr&0x00FF0000)>>16));
                            DEBUG(".%i :",((ip->IP_Srcaddr&0xFF000000)>>24));
                            break;
                    }
                    return;
                }
                else
                {
#if USE_TCP
                    if( ip->IP_Proto == PROT_TCP ) tcp_socket_process();
#endif
                    if( ip->IP_Proto == PROT_UDP ) udp_socket_process();
                }
            }
            else
            if (ip->IP_Destaddr == (unsigned long)0xffffffff || ip->IP_Destaddr == broadcast_ip.ipl ) // if broadcast
            {
                if( ip->IP_Proto == PROT_UDP ) udp_socket_process();
            }
        }
    }
    return;
}

//----------------------------------------------------------------------------
//erzeugt einen ARP - Eintrag wenn noch nicht vorhanden
void arp_entry_add (void)
{
    struct Ethernet_Header *ethernet;
    struct ARP_Header      *arp;
    struct IP_Header       *ip;

    ethernet = (struct Ethernet_Header *)&eth_buffer[ETHER_OFFSET];
    arp      = (struct ARP_Header      *)&eth_buffer[ARP_OFFSET];
    ip       = (struct IP_Header       *)&eth_buffer[IP_OFFSET];

    //Eintrag schon vorhanden?
    for (unsigned char a = 0; a<MAX_ARP_ENTRY; a++)
    {
        if( ethernet->EnetPacketType == HTONS(0x0806) ) //If ARP
        {
            if(arp_entry[a].arp_t_ip == arp->ARP_SIPAddr)
            {
                //Eintrag gefunden Time refresh
                arp_entry[a].arp_t_time = ARP_MAX_ENTRY_TIME;
                return;
            }
        }
        if( ethernet->EnetPacketType == HTONS(0x0800) ) //If IP
        {
            if(arp_entry[a].arp_t_ip == ip->IP_Srcaddr)
            {
                //Eintrag gefunden Time refresh
                arp_entry[a].arp_t_time = ARP_MAX_ENTRY_TIME;
                return;
            }
        }
    }

    //Freien Eintrag finden
    for (unsigned char b = 0; b<MAX_ARP_ENTRY; b++)
    {
        if(arp_entry[b].arp_t_ip == 0)
        {
            if( ethernet->EnetPacketType == HTONS(0x0806) ) //if ARP
            {
                for(unsigned char a = 0; a < 6; a++)
                {
                    arp_entry[b].arp_t_mac[a] = ethernet->EnetPacketSrc[a];
                }
                arp_entry[b].arp_t_ip   = arp->ARP_SIPAddr;
                arp_entry[b].arp_t_time = ARP_MAX_ENTRY_TIME;
                return;
            }
            if( ethernet->EnetPacketType == HTONS(0x0800) ) //if IP
            {
                for(unsigned char a = 0; a < 6; a++)
                {
                    arp_entry[b].arp_t_mac[a] = ethernet->EnetPacketSrc[a];
                }
                arp_entry[b].arp_t_ip   = ip->IP_Srcaddr;
                arp_entry[b].arp_t_time = ARP_MAX_ENTRY_TIME;
                return;
            }
            DEBUG("Kein ARP oder IP Packet!\r\n");
            return;
        }
    }
    //Eintrag konnte nicht mehr aufgenommen werden
    DEBUG("ARP entry tabelle voll!\r\n");
    return;
}

//----------------------------------------------------------------------------
//Diese Routine such anhand der IP den ARP eintrag
char arp_entry_search (unsigned long dest_ip)
{
    //DEBUG("Search ARP for 0x%X\r\n",dest_ip);
    if (dest_ip!=0xffffffff) {
    for (unsigned char b = 0;b<MAX_ARP_ENTRY;b++)
    {
        if(arp_entry[b].arp_t_ip == dest_ip)
        {
            //DEBUG("Found ARP %d\r\n",b);
            return(b);
        }
    }
    }else{
    DEBUG("Broadcast IP\r\n");
    }
    return (MAX_ARP_ENTRY);
}

//----------------------------------------------------------------------------
//Diese Routine Erzeugt ein neuen Ethernetheader
void __attribute__((optimize("-O3"))) new_eth_header (unsigned char *buffer,unsigned long dest_ip)
{
    unsigned char b;
    unsigned char a;
    struct Ethernet_Header *ethernet;
    ethernet = (struct Ethernet_Header *)&buffer[ETHER_OFFSET];

    b = arp_entry_search (dest_ip);
    if (b != MAX_ARP_ENTRY) //Eintrag gefunden wenn ungleich
    {
        for(unsigned char a = 0; a < 6; a++)
        {
            //MAC Destadresse wird geschrieben mit MAC Sourceadresse
            ethernet->EnetPacketDest[a] = arp_entry[b].arp_t_mac[a];
            //Meine MAC Adresse wird in Sourceadresse geschrieben
            ethernet->EnetPacketSrc[a] = mymac[a];
        }
        return;
    }

    DEBUG("ARP Eintrag nicht gefunden* for 0x%X\r\n",dest_ip);
    for(a = 0; a < 6; a++)
    {
        //MAC Destadresse wird geschrieben mit MAC Sourceadresse
        ethernet->EnetPacketDest[a] = 0xFF;
        //Meine MAC Adresse wird in Sourceadresse geschrieben
        ethernet->EnetPacketSrc[a] = mymac[a];
    }
    return;

}

//----------------------------------------------------------------------------
//Diese Routine Antwortet auf ein ARP Paket
void arp_reply (void)
{
    unsigned char b;
    unsigned char a;
    struct Ethernet_Header *ethernet;
    struct ARP_Header      *arp;

    ethernet = (struct Ethernet_Header *)&eth_buffer[ETHER_OFFSET];
    arp      = (struct ARP_Header      *)&eth_buffer[ARP_OFFSET];


    if( arp->ARP_HWType  == HTONS(0x0001)  &&             // Hardware Typ:   Ethernet
        arp->ARP_PRType  == HTONS(0x0800)  &&             // Protokoll Typ:  IP
        arp->ARP_HWLen   == 0x06           &&             // L�nge der Hardwareadresse: 6
        arp->ARP_PRLen   == 0x04           &&             // L�nge der Protokolladresse: 4
        arp->ARP_TIPAddr == myip.ipl) // F�r uns?
    {
        if (arp->ARP_Op == HTONS(0x0001) )                  // Request?
        {
            arp_entry_add();
            new_eth_header (eth_buffer, arp->ARP_SIPAddr); // Erzeugt ein neuen Ethernetheader
            ethernet->EnetPacketType = HTONS(0x0806);      // Nutzlast 0x0800=IP Datagramm;0x0806 = ARP

            b = arp_entry_search (arp->ARP_SIPAddr);
            if (b < MAX_ARP_ENTRY)                         // Eintrag gefunden wenn ungleich
            {
                for(a = 0; a < 6; a++)
                {
                    arp->ARP_THAddr[a] = arp_entry[b].arp_t_mac[a];
                    arp->ARP_SHAddr[a] = mymac[a];
                }
            }
            else
            {
                DEBUG("ARP Eintrag nicht gefunden\r\n");        // Unwarscheinlich
            }

            arp->ARP_Op      = HTONS(0x0002);                   // ARP op = ECHO
            arp->ARP_TIPAddr = arp->ARP_SIPAddr;                // ARP Target IP Adresse
            arp->ARP_SIPAddr = myip.ipl;   // Meine IP Adresse = ARP Source

            ETH_PACKET_SEND(ARP_REPLY_LEN,eth_buffer);          // ARP Reply senden...
            return;
        }

        if ( arp->ARP_Op == HTONS(0x0002) )                    // REPLY von einem anderen Client
        {
            arp_entry_add();
            DEBUG("ARP REPLY EMPFANGEN!\r\n");
        }
    }
    return;
}

//----------------------------------------------------------------------------
//Diese Routine erzeugt einen ARP Request
char arp_request (unsigned long dest_ip)
{
    unsigned char buffer[ARP_REQUEST_LEN];
    unsigned char index = 0;
    unsigned char index_tmp;
    unsigned char count;
    unsigned long a;
    unsigned long dest_ip_store;

    struct Ethernet_Header *ethernet;
    struct ARP_Header *arp;

    ethernet = (struct Ethernet_Header *)&buffer[ETHER_OFFSET];
    arp      = (struct ARP_Header      *)&buffer[ARP_OFFSET];

    dest_ip_store = dest_ip;

    if ( (dest_ip & netmask.ipl)==
       (myip.ipl & netmask.ipl) )
    {
        DEBUG("MY NETWORK!\r\n");
    }
    else
    {
        DEBUG("ROUTING!\r\n");
        dest_ip = router_ip.ipl;
    }

    ethernet->EnetPacketType = HTONS(0x0806);          // Nutzlast 0x0800=IP Datagramm;0x0806 = ARP

    new_eth_header (buffer,dest_ip);

    arp->ARP_SIPAddr = myip.ipl;   // MyIP = ARP Source IP
    arp->ARP_TIPAddr = dest_ip;                         // Dest IP

    for(count = 0; count < 6; count++)
    {
        arp->ARP_SHAddr[count] = mymac[count];
        arp->ARP_THAddr[count] = 0;
    }

    arp->ARP_HWType = HTONS(0x0001);
    arp->ARP_PRType = HTONS(0x0800);
    arp->ARP_HWLen  = 0x06;
    arp->ARP_PRLen  = 0x04;
    arp->ARP_Op     = HTONS(0x0001);

    ETH_PACKET_SEND(ARP_REQUEST_LEN, buffer);        //send....

    for(count = 0; count<20; count++)
    {
        index_tmp = arp_entry_search(dest_ip_store);
        index = arp_entry_search(dest_ip);
        if (index < MAX_ARP_ENTRY || index_tmp < MAX_ARP_ENTRY)
        {
            DEBUG("ARP EINTRAG GEFUNDEN!\r\n");
            if (index_tmp < MAX_ARP_ENTRY) return(1);//OK
            arp_entry[index].arp_t_ip = dest_ip_store;
            return(1);//OK
        }
        for(a=0;a<10000;a++)
        {
            asm("nop");
        }
        eth_get_data();
        DEBUG("**KEINEN ARP EINTRAG GEFUNDEN**\r\n");
    }
    return(0);//keine Antwort
}

//----------------------------------------------------------------------------
//Diese Routine erzeugt ein neues ICMP Packet
void icmp_send (unsigned long dest_ip, unsigned char icmp_type,
                unsigned char icmp_code, unsigned short icmp_sn,
                unsigned short icmp_id)
{
    unsigned short result16;  //Checksum
    struct IP_Header   *ip;
    struct ICMP_Header *icmp;

    ip   = (struct IP_Header   *)&eth_buffer[IP_OFFSET];
    icmp = (struct ICMP_Header *)&eth_buffer[ICMP_OFFSET];

    //Das ist ein Echo Reply Packet
    icmp->ICMP_Type   = icmp_type;
    icmp->ICMP_Code   = icmp_code;
    icmp->ICMP_Id     = icmp_id;
    icmp->ICMP_SeqNum = icmp_sn;
    icmp->ICMP_Cksum  = 0;
    ip->IP_Pktlen     = HTONS(0x0054);   // 0x54 = 84
    ip->IP_Proto      = PROT_ICMP;
    make_ip_header (eth_buffer,dest_ip);

    //Berechnung der ICMP Header länge
    result16 = htons(ip->IP_Pktlen);
    result16 = result16 - ((ip->IP_Vers_Len & 0x0F) << 2);

    //pointer wird auf das erste Paket im ICMP Header gesetzt
    //jetzt wird die Checksumme berechnet
    result16 = checksum (&icmp->ICMP_Type, result16, 0);

    //schreibt Checksumme ins Packet
    icmp->ICMP_Cksum = htons(result16);

    //Sendet das erzeugte ICMP Packet
    ETH_PACKET_SEND(ICMP_REPLY_LEN,eth_buffer);
}

//----------------------------------------------------------------------------
//Diese Routine erzeugt eine Cecksumme
unsigned short __attribute__((optimize("-O3"))) checksum (unsigned char *pointer,unsigned short result16,unsigned long result32)
{
    unsigned short result16_1 = 0x0000u;

    //Jetzt werden alle Packete in einer While Schleife addiert
    while(result16 > 1u)
    {
        result16_1 = *((unsigned short*)pointer);
        pointer +=2u;

        //Addiert packet mit vorherigen
        result32 = result32 + result16_1;
        //decrimiert Länge von TCP Headerschleife um 2
        result16 -=2u;
    }

    //Ist der Wert result16 ungerade ist DataL = 0
    if(result16 > 0)
    {
        //schreibt Inhalt Pointer nach DATAH danach inc Pointer
        const unsigned char DataH=*pointer;
        //erzeugt Int aus Data L ist 0 (ist nicht in der Berechnung) und Data H
        result16_1 = (DataH << 8u);
        //Addiert packet mit vorherigen
        result32 = result32 + result16_1;
    }

    //Komplementbildung (addiert Long INT_H Byte mit Long INT L Byte)
    result32 = ((result32 & 0x0000FFFFu)+ ((result32 & 0xFFFF0000u) >> 16u));
    result32 = ((result32 & 0x0000FFFFu)+ ((result32 & 0xFFFF0000u) >> 16u));
    result16 =~(result32 & 0x0000FFFFu);

    return (result16);
}

//----------------------------------------------------------------------------
//Diese Routine erzeugt ein IP Packet
void make_ip_header (unsigned char *buffer,unsigned long dest_ip)
{
    unsigned short result16;  //Checksum
    struct Ethernet_Header *ethernet;
    struct IP_Header       *ip;

    ethernet = (struct Ethernet_Header *)&buffer[ETHER_OFFSET];
    ip       = (struct IP_Header       *)&buffer[IP_OFFSET];

    new_eth_header (buffer, dest_ip);         //Erzeugt einen neuen Ethernetheader
    ethernet->EnetPacketType = HTONS(0x0800); //Nutzlast 0x0800=IP

    IP_id_counter++;

    ip->IP_Frag_Offset = 0x4000;  //don't fragment
    ip->IP_ttl         = 128;      //max. hops
    ip->IP_Id          = htons(IP_id_counter);
    ip->IP_Vers_Len    = 0x45;  //4 BIT Die Versionsnummer von IP,
    ip->IP_Tos         = 0;
    ip->IP_Destaddr     = dest_ip;
    ip->IP_Srcaddr     = myip.ipl;
    ip->IP_Hdr_Cksum   = 0;

    //Berechnung der IP Header l�nge
    result16 = (ip->IP_Vers_Len & 0x0F) << 2;

    //jetzt wird die Checksumme berechnet
    result16 = checksum (&ip->IP_Vers_Len, result16, 0);

    //schreibt Checksumme ins Packet
    ip->IP_Hdr_Cksum = htons(result16);
    return;
}
#if USE_TCP
//----------------------------------------------------------------------------
//Diese Routine verwaltet TCP-Eintr�ge
void tcp_entry_add (unsigned char *buffer)
{
    unsigned long result32;

    struct TCP_Header *tcp;
    struct IP_Header  *ip;

    tcp = (struct TCP_Header *)&buffer[TCP_OFFSET];
    ip  = (struct IP_Header  *)&buffer[IP_OFFSET];

    //Eintrag schon vorhanden?
    for (unsigned char index = 0;index<(MAX_TCP_ENTRY);index++)
    {
        if( (tcp_entry[index].ip       == ip->IP_Srcaddr  ) &&
            (tcp_entry[index].src_port == tcp->TCP_SrcPort)    )
        {
            //Eintrag gefunden Time refresh
            tcp_entry[index].ack_counter = tcp->TCP_Acknum;
            tcp_entry[index].seq_counter = tcp->TCP_Seqnum;
            tcp_entry[index].status      = tcp->TCP_HdrFlags;
            if ( tcp_entry[index].time != TCP_TIME_OFF )
            {
                tcp_entry[index].time = TCP_MAX_ENTRY_TIME;
            }
            result32 = htons(ip->IP_Pktlen) - IP_VERS_LEN - ((tcp->TCP_Hdrlen& 0xF0) >>2);
            result32 = result32 + htons32(tcp_entry[index].seq_counter);
            tcp_entry[index].seq_counter = htons32(result32);

            DEBUG("TCP Entry gefunden %i\r\n",index);
            return;
        }
    }

    //Freien Eintrag finden
    for (unsigned char index = 0;index<(MAX_TCP_ENTRY);index++)
    {
        if(tcp_entry[index].ip == 0)
        {
            tcp_entry[index].ip          = ip->IP_Srcaddr;
            tcp_entry[index].src_port    = tcp->TCP_SrcPort;
            tcp_entry[index].dest_port   = tcp->TCP_DestPort;
            tcp_entry[index].ack_counter = tcp->TCP_Acknum;
            tcp_entry[index].seq_counter = tcp->TCP_Seqnum;
            tcp_entry[index].status      = tcp->TCP_HdrFlags;
            tcp_entry[index].app_status  = 0;
            tcp_entry[index].time        = TCP_MAX_ENTRY_TIME;
            tcp_entry[index].error_count = 0;
            tcp_entry[index].first_ack   = 0;
            DEBUG("TCP Entry neuer Eintrag %i\r\n",index);
            return;
        }
    }
    //Eintrag konnte nicht mehr aufgenommen werden
    DEBUG("Server Busy (NO MORE CONNECTIONS)!\r\n");
    return;
}

//----------------------------------------------------------------------------
//Diese Routine sucht den etntry eintrag
char tcp_entry_search (unsigned long dest_ip,unsigned short SrcPort)
{
    for (unsigned char index = 0;index<MAX_TCP_ENTRY;index++)
    {
        if(	tcp_entry[index].ip == dest_ip &&
            tcp_entry[index].src_port == SrcPort)
        {
            return(index);
        }
    }
	return (MAX_TCP_ENTRY);
}
#endif
//----------------------------------------------------------------------------
//Diese Routine verwaltet die UDP Ports
void __attribute__((optimize("-O3"))) udp_socket_process(void)
{
    unsigned char port_index = 0;
    struct UDP_Header *udp;

    udp = (struct UDP_Header *)&eth_buffer[UDP_OFFSET];

    //UDP DestPort mit Portanwendungsliste durchf�hren
    while (UDP_PORT_TABLE[port_index].port && UDP_PORT_TABLE[port_index].port!=(htons(udp->udp_DestPort)))
    {
        port_index++;
    }

    // Wenn index zu gross, dann beenden keine vorhandene Anwendung f�r den Port
    if (!UDP_PORT_TABLE[port_index].port)
    {
        //Keine vorhandene Anwendung eingetragen! (ENDE)
        DEBUG("UDP Keine Anwendung gefunden!\r\n");
        return;
    }

    //zugehörige Anwendung ausführen
    UDP_PORT_TABLE[port_index].fp(0);
    return;
}

//----------------------------------------------------------------------------
//Diese Routine Erzeugt ein neues UDP Packet
void __attribute__((optimize("-O3"))) create_new_udp_packet( unsigned short  data_length,
                            unsigned short  src_port,
                            unsigned short  dest_port,
                            unsigned long   dest_ip)
{
    unsigned short result16;
    unsigned long  result32;

    struct UDP_Header *udp;
    struct IP_Header  *ip;

    udp = (struct UDP_Header *)&eth_buffer[UDP_OFFSET];
    ip  = (struct IP_Header  *)&eth_buffer[IP_OFFSET];

    udp->udp_SrcPort  = htons(src_port);
    udp->udp_DestPort = htons(dest_port);

    data_length     += UDP_HDR_LEN;                //UDP Packetlength
    udp->udp_Hdrlen = htons(data_length);

    data_length     += IP_VERS_LEN;                //IP Headerlänge + UDP Headerlänge
    ip->IP_Pktlen = htons(data_length);
    data_length += ETH_HDR_LEN;
    ip->IP_Proto = PROT_UDP;
    make_ip_header (eth_buffer,dest_ip);

    udp->udp_Chksum = 0;

    //Berechnet Headerlänge und Addiert Pseudoheaderlänge 2XIP = 8
    result16 = htons(ip->IP_Pktlen) + 8;
    result16 = result16 - ((ip->IP_Vers_Len & 0x0F) << 2);
    result32 = result16 + 0x09;

    //Routine berechnet die Checksumme
    result16 = checksum ((&ip->IP_Vers_Len+12), result16, result32);
    udp->udp_Chksum = htons(result16);

    ETH_PACKET_SEND(data_length,eth_buffer); //send...
    return;
}
#if USE_TCP
//----------------------------------------------------------------------------
//Diese Routine verwaltet die TCP Ports
void tcp_socket_process(void)
{
    unsigned char index = 0;
    unsigned char port_index = 0;
    unsigned long result32 = 0;

    struct TCP_Header *tcp;
    tcp = (struct TCP_Header *)&eth_buffer[TCP_OFFSET];

    struct IP_Header *ip;
    ip = (struct IP_Header *)&eth_buffer[IP_OFFSET];

    //TCP DestPort mit Portanwendungsliste durchf�hren
    while (TCP_PORT_TABLE[port_index].port && TCP_PORT_TABLE[port_index].port!=(htons(tcp->TCP_DestPort)))
    {
        port_index++;
    }

    // Wenn index zu gross, dann beenden keine vorhandene Anwendung f�r Port
    //Geht von einem Client was aus? Will eine Clientanwendung einen Port �ffnen?
    if (!TCP_PORT_TABLE[port_index].port)
    {
        //Keine vorhandene Anwendung eingetragen! (ENDE)
        DEBUG("TCP Keine Anwendung gefunden!\r\n");
        return;
    }

    //Server �ffnet Port
    if((tcp->TCP_HdrFlags & SYN_FLAG) && (tcp->TCP_HdrFlags & ACK_FLAG))
    {
        //Nimmt Eintrag auf da es eine Client - Anwendung f�r den Port gibt
        tcp_entry_add (eth_buffer);
        //War der Eintrag erfolgreich?
        index = tcp_entry_search (ip->IP_Srcaddr,tcp->TCP_SrcPort);
        if (index >= MAX_TCP_ENTRY) //Eintrag gefunden wenn ungleich
        {
            DEBUG("TCP Eintrag nicht erfolgreich!\r\n");
            return;
        }

        tcp_entry[index].time = MAX_TCP_PORT_OPEN_TIME;
        DEBUG("TCP Port wurde vom Server ge�ffnet STACK:%i\r\n",index);
        result32 = htons32(tcp_entry[index].seq_counter) + 1;
        tcp_entry[index].seq_counter = htons32(result32);
        tcp_entry[index].status =  ACK_FLAG;
        create_new_tcp_packet(0,index);
        //Server Port wurde ge�ffnet App. kann nun daten senden!
        tcp_entry[index].app_status = 1;
        return;
    }

    //Verbindungsaufbau nicht f�r Anwendung bestimmt
    if(tcp->TCP_HdrFlags == SYN_FLAG)
    {
        //Nimmt Eintrag auf da es eine Server - Anwendung f�r den Port gibt
        tcp_entry_add (eth_buffer);
        //War der Eintrag erfolgreich?
        index = tcp_entry_search (ip->IP_Srcaddr,tcp->TCP_SrcPort);
        if (index >= MAX_TCP_ENTRY) //Eintrag gefunden wenn ungleich
        {
            DEBUG("TCP Eintrag nicht erfolgreich!\r\n");
            return;
        }

        DEBUG("TCP New SERVER Connection! STACK:%i\r\n",index);

        tcp_entry[index].status =  ACK_FLAG | SYN_FLAG;
        create_new_tcp_packet(0,index);
        return;
    }

    //Packeteintrag im TCP Stack finden!
    index = tcp_entry_search (ip->IP_Srcaddr,tcp->TCP_SrcPort);

    if (index >= MAX_TCP_ENTRY) //Eintrag nicht gefunden
    {
        DEBUG("TCP Eintrag nicht gefunden\r\n");

        if(tcp->TCP_HdrFlags & FIN_FLAG || tcp->TCP_HdrFlags & RST_FLAG)
        {
            tcp_entry_add (eth_buffer);//Tempor�rer Indexplatz
            result32 = htons32(tcp_entry[index].seq_counter) + 1;
            tcp_entry[index].seq_counter = htons32(result32);

            if (tcp_entry[index].status & FIN_FLAG)
            {
                tcp_entry[index].status = ACK_FLAG;
                create_new_tcp_packet(0,index);
            }
            tcp_index_del(index);
            DEBUG("TCP-Stack Eintrag gel�scht! STACK:%i\r\n",index);
            return;
        }
        return;
    }


    //Refresh des Eintrages
    tcp_entry_add (eth_buffer);

    //Host will verbindung beenden!
    if(tcp_entry[index].status & FIN_FLAG || tcp_entry[index].status & RST_FLAG)
    {
        result32 = htons32(tcp_entry[index].seq_counter) + 1;
        tcp_entry[index].seq_counter = htons32(result32);

        if (tcp_entry[index].status & FIN_FLAG)
        {
            // Ende der Anwendung mitteilen !
            TCP_PORT_TABLE[port_index].fp(index);

            tcp_entry[index].status = ACK_FLAG | FIN_FLAG;
            create_new_tcp_packet(0,index);
        }
        tcp_index_del(index);
        DEBUG("TCP-Stack Eintrag gel�scht! STACK:%i\r\n",index);
        return;
    }

    //Daten für Anwendung PSH-Flag gesetzt?
    if((tcp_entry[index].status & PSH_FLAG) &&
        (tcp_entry[index].status & ACK_FLAG))
    {
        //zugehörige Anwendung ausführen
        if(tcp_entry[index].app_status < 0xFFFE) tcp_entry[index].app_status++;
        tcp_entry[index].status =  ACK_FLAG | PSH_FLAG;
        TCP_PORT_TABLE[port_index].fp(index);
        return;
    }

    //Empfangene Packet wurde bestätigt keine Daten für Anwendung
    //z.B. nach Verbindungsaufbau (SYN-PACKET)
    if((tcp_entry[index].status & ACK_FLAG) && (tcp_entry[index].first_ack == 0))
    {
        //keine weitere Aktion
        tcp_entry[index].first_ack = 1;
        return;
    }

    //Empfangsbestätigung für ein von der Anwendung gesendetes Packet (ENDE)
    if((tcp_entry[index].status & ACK_FLAG) && (tcp_entry[index].first_ack == 1))
    {
        //ACK für Verbindungs abbau
        if(tcp_entry[index].app_status == 0xFFFF)
        {
            return;
        }

        //zugehörige Anwendung ausführen
        tcp_entry[index].status =  ACK_FLAG;
        if(tcp_entry[index].app_status < 0xFFFE) tcp_entry[index].app_status++;
        TCP_PORT_TABLE[port_index].fp(index);
        return;
    }
    return;
}

//----------------------------------------------------------------------------
//Diese Routine Erzeugt ein neues TCP Packet
void create_new_tcp_packet(unsigned short data_length,unsigned char index)
{
    unsigned short  result16;
    unsigned long   result32;
    unsigned short  bufferlen;

    struct TCP_Header *tcp;
    struct IP_Header  *ip;

    tcp = (struct TCP_Header *)&eth_buffer[TCP_OFFSET];
    ip  = (struct IP_Header  *)&eth_buffer[IP_OFFSET];

    tcp->TCP_SrcPort   = tcp_entry[index].dest_port;
    tcp->TCP_DestPort  = tcp_entry[index].src_port;
    tcp->TCP_UrgentPtr = 0;
    tcp->TCP_Window    = htons(MAX_WINDOWS_SIZE);
    tcp->TCP_Hdrlen    = 0x50;

    DEBUG("TCP SrcPort %4i\r\n", htons(tcp->TCP_SrcPort));

    result32 = htons32(tcp_entry[index].seq_counter);

    tcp->TCP_HdrFlags = tcp_entry[index].status;

    //Verbindung wird aufgebaut
    if(tcp_entry[index].status & SYN_FLAG)
    {
        result32++;
        // MSS-Option (siehe RFC 879) wil.
        eth_buffer[TCP_DATA_START]   = 2;
        eth_buffer[TCP_DATA_START+1] = 4;
        eth_buffer[TCP_DATA_START+2] = HI8(MAX_WINDOWS_SIZE); // >> 8) & 0xff;
        eth_buffer[TCP_DATA_START+3] = LO8(MAX_WINDOWS_SIZE); // & 0xff;
        data_length                  = 0x04;
        tcp->TCP_Hdrlen              = 0x60;
    }

    tcp->TCP_Acknum = htons32(result32);
    tcp->TCP_Seqnum = tcp_entry[index].ack_counter;

    bufferlen = IP_VERS_LEN + TCP_HDR_LEN + data_length;    //IP Headerl�nge + TCP Headerl�nge
    ip->IP_Pktlen = htons(bufferlen);                      //Hier wird erstmal der IP Header neu erstellt
    bufferlen += ETH_HDR_LEN;
    ip->IP_Proto = PROT_TCP;
    make_ip_header (eth_buffer,tcp_entry[index].ip);

    tcp->TCP_Chksum = 0;

    //Berechnet Headerlänge und Addiert Pseudoheaderlänge 2XIP = 8
    result16 = htons(ip->IP_Pktlen) + 8;
    result16 = result16 - ((ip->IP_Vers_Len & 0x0F) << 2);
    result32 = result16 - 2;

    //Checksum
    result16 = checksum ((&ip->IP_Vers_Len+12), result16, result32);
    tcp->TCP_Chksum = htons(result16);

    //Send the TCP packet
    ETH_PACKET_SEND(bufferlen,eth_buffer);
    //Für Retransmission
    tcp_entry[index].status = 0;
    return;
}

//----------------------------------------------------------------------------
//Diese Routine schließt einen offenen TCP-Port
void tcp_Port_close (unsigned char index)
{
	DEBUG("Port wird im TCP Stack geschlossen STACK:%i\r\n",index);
	tcp_entry[index].app_status = 0xFFFF;
	tcp_entry[index].status =  ACK_FLAG | FIN_FLAG;
	create_new_tcp_packet(0,index);
	return;
}

//----------------------------------------------------------------------------
//Diese Routine findet die Anwendung anhand des TCP Ports
void find_and_start (unsigned char index)
{
    unsigned char port_index = 0;

    //Port mit Anwendung in der Liste suchen
    while ( (TCP_PORT_TABLE[port_index].port!=(htons(tcp_entry[index].dest_port))) &&
          (port_index < MAX_APP_ENTRY)                                                 )
    {
        port_index++;
    }
    if (port_index >= MAX_APP_ENTRY) return;

    //zugeh�rige Anwendung ausf�hren (Senden wiederholen)
    TCP_PORT_TABLE[port_index].fp(index);
    return;
}

//----------------------------------------------------------------------------
//Diese Routine öffnet einen TCP-Port
void tcp_port_open (unsigned long dest_ip,unsigned short port_dst,unsigned short port_src)
{
    unsigned char index;

    ETH_INT_DISABLE;
    DEBUG("Oeffen eines Ports mit Server\r\n");

    //Freien Eintrag finden
    for (index = 0;index<MAX_TCP_ENTRY;index++)
    {
        if(tcp_entry[index].ip == 0)
        {
            tcp_index_del(index);
            tcp_entry[index].ip = dest_ip;
            tcp_entry[index].src_port = port_dst;
            tcp_entry[index].dest_port = port_src;
            tcp_entry[index].ack_counter = 1234;
            tcp_entry[index].seq_counter = 2345;
            tcp_entry[index].time = MAX_TCP_PORT_OPEN_TIME;
            DEBUG("TCP Open neuer Eintrag %i\r\n",index);
            break;
        }
    }
    if (index >= MAX_TCP_ENTRY)
    {
        //Eintrag konnte nicht mehr aufgenommen werden
        DEBUG("Busy (NO MORE CONNECTIONS)!\r\n");
    }

    tcp_entry[index].status =  SYN_FLAG;
    create_new_tcp_packet(0,index);
    ETH_INT_ENABLE;
    return;
}

//----------------------------------------------------------------------------
//Diese Routine löscht einen Eintrag
void tcp_index_del (unsigned char index)
{
    if (index<MAX_TCP_ENTRY + 1)
    {
        tcp_entry[index].ip = 0;
        tcp_entry[index].src_port = 0;
        tcp_entry[index].dest_port = 0;
        tcp_entry[index].ack_counter = 0;
        tcp_entry[index].seq_counter = 0;
        tcp_entry[index].status = 0;
        tcp_entry[index].app_status = 0;
        tcp_entry[index].time = 0;
        tcp_entry[index].first_ack = 0;
    }
    return;
}
#endif
//----------------------------------------------------------------------------
//End of file: stack.c







