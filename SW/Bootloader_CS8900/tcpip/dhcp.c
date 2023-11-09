/* $Workfile:   dhcp.c $                                        */
/* $Revision: 1.1 $                                            	*/
/* $Author: Andfreas Voggeneder $                               */
/* $Date: 2003/14/02 19:31:38 $                                 */
/* Description:	DHCP Client for CS8900                          */
/*                                                              */
/* Remarks:     No remarks.                                     */
/*
DESCRIPTION :  DHCP protocol messaging flow
			     |	                    |
	                     |   DHCP DISCOVER      |
			     |--------------------->|
			     |      DHCP OFFER      |
		DHCP Client  |<---------------------|  DHCP SERVER
			     |   DHCP REQUEST       |
			     |--------------------->|
			     |   DHCP ACK           |
			     |<---------------------|
			     |     	                |
*/
//#include "net.h"
#include <stdio.h>
#include <ctype.h>
#include <delay.h>
#include <string.h>
#include "dhcp.h"
#include "netutil.h"

// Create Discover DHCP packet and broadcast it.
static inline void send_DHCP_DISCOVER(uchar sock,uchar *pBfr)
{

    RIP_MSG * MSG=(RIP_MSG *)pBfr;
    // Generate DISCOVER DHCP PACKET
    // setting values as DHCP Protocol
    MSG->op = DHCP_BOOTREQUEST;
    MSG->htype = DHCP_HTYPE10MB;
    MSG->hlen = DHCP_HLENETHERNET;
    MSG->hops = DHCP_HOPS;
    MSG->xid = DHCP_XID;
    MSG->secs = DHCP_SECS;
    MSG->flags = DHCP_FLAGSBROADCAST;

    memset(&MSG->ciaddr.bytes,0u,RIP_MSG_SIZE-12u);   // Clear all starting from ciaddr

    // setting default Mac Address Value.
    memcpy(MSG->chaddr, my_mac, 6);

    // MAGIC_COOKIE
    MSG->OPT[0] = MAGIC0;
    MSG->OPT[1] = MAGIC1;
    MSG->OPT[2] = MAGIC2;
    MSG->OPT[3] = MAGIC3;
    //*((unsigned long *)MSG->OPT)=MAGIC_COOKIE;

    // Option Request Param.
    MSG->OPT[4] = dhcpMessageType;
    MSG->OPT[5] = 0x01;
    MSG->OPT[6] = DHCP_DISCOVER;
    MSG->OPT[7] = dhcpParamRequest;
    MSG->OPT[8] = 0x05;
    MSG->OPT[9] = subnetMask;
    MSG->OPT[10] = routersOnSubnet;
    MSG->OPT[11] = dns;
    MSG->OPT[12] = dhcpT1value;
    MSG->OPT[13] = dhcpT2value;

    MSG->OPT[14]= hostName;
    MSG->OPT[15]= 3;
    memcpy(&MSG->OPT[16],"NKC",3);	//16-18

    MSG->OPT[19] = endOption;

    send_socket_udp(sock,pBfr,RIP_MSG_SIZE);
}

static inline void send_DHCP_REQUEST(uchar sock,uchar *pBfr)
{
    RIP_MSG * MSG = (RIP_MSG *)pBfr;

    MSG->op = DHCP_BOOTREQUEST;
    MSG->htype = DHCP_HTYPE10MB;
    MSG->hlen = DHCP_HLENETHERNET;
    MSG->hops = DHCP_HOPS;
    MSG->xid = DHCP_XID;
    MSG->secs = DHCP_SECS;
    MSG->flags = DHCP_FLAGSBROADCAST;

    MSG->ciaddr.ipl = my_ip.ipl;
    /*MSG->ciaddr[0] = my_ip.bytes[0];
    MSG->ciaddr[1] = my_ip.bytes[1];
    MSG->ciaddr[2] = my_ip.bytes[2];
    MSG->ciaddr[3] = my_ip.bytes[3];*/

    memset(MSG->yiaddr.bytes,0,RIP_MSG_SIZE-16u);
    memcpy(MSG->chaddr, my_mac, sizeof(my_mac));


/*	for (i = 6; i < 16; i++) MSG->chaddr[i] = 0;
    for (i = 0; i < 64; i++) MSG->sname[i] = 0;
    for (i = 0; i < 128; i++) MSG->file[i] = 0;*/

    // MAGIC_COOKIE
    MSG->OPT[0] = MAGIC0;
    MSG->OPT[1] = MAGIC1;
    MSG->OPT[2] = MAGIC2;
    MSG->OPT[3] = MAGIC3;
    //*((unsigned long *)MSG->OPT)=MAGIC_COOKIE;

    // Option Request Param.
    MSG->OPT[4] = dhcpMessageType;
    MSG->OPT[5] = 0x01u;
    MSG->OPT[6] = DHCP_REQUEST;

    // DHCP Option Request Param.
    MSG->OPT[7] = dhcpParamRequest;
    MSG->OPT[8] = 0x05u;
    MSG->OPT[9] = subnetMask;
    MSG->OPT[10] = routersOnSubnet;

    MSG->OPT[11] = dns;
    MSG->OPT[12] = dhcpT1value;
    MSG->OPT[13] = dhcpT2value;
    MSG->OPT[14]= hostName;
    MSG->OPT[15]= 7;
    memcpy(&MSG->OPT[16],"NKC",3u);
    MSG->OPT[19] = endOption;
    send_socket_udp(sock,pBfr,RIP_MSG_SIZE);
}

/*
void send_DHCP_RELEASE(SOCKET s)
{
	char i;
	MSG->op = DHCP_BOOTREQUEST;
	MSG->htype = DHCP_HTYPE10MB;
	MSG->hlen = DHCP_HLENETHERNET;
	MSG->hops = DHCP_HOPS;
	MSG->xid = DHCP_XID;
	MSG->secs = DHCP_SECS;
	MSG->flags = DHCP_FLAGSBROADCAST;

	MSG->ciaddr[0] = 0;
	MSG->ciaddr[1] = 0;
	MSG->ciaddr[2] = 0;
	MSG->ciaddr[3] = 0;

	MSG->yiaddr[0] = 0;
	MSG->yiaddr[1] = 0;
	MSG->yiaddr[2] = 0;
	MSG->yiaddr[3] = 0;

	MSG->siaddr[0] = 0;
	MSG->siaddr[1] = 0;
	MSG->siaddr[2] = 0;
	MSG->siaddr[3] = 0;

	MSG->giaddr[0] = 0;
	MSG->giaddr[1] = 0;
	MSG->giaddr[2] = 0;
	MSG->giaddr[3] = 0;

	MSG->chaddr[0] = DEFAULT_MAC0;
	MSG->chaddr[1] = DEFAULT_MAC1;
	MSG->chaddr[2] = DEFAULT_MAC2;
	MSG->chaddr[3] = DEFAULT_MAC3;
	MSG->chaddr[4] = DEFAULT_MAC4;
	MSG->chaddr[5] = DEFAULT_MAC5;

	for (i = 6; i < 16; i++) MSG->chaddr[i] = 0;
	for (i = 0; i < 64; i++) MSG->sname[i] = 0;
	for (i = 0; i < 128; i++) MSG->file[i] = 0;

	// MAGIC_COOKIE
	MSG->OPT[0] = MAGIC0;
	MSG->OPT[1] = MAGIC1;
	MSG->OPT[2] = MAGIC2;
	MSG->OPT[3] = MAGIC3;

	// Option Request Param.
	MSG->OPT[4] = dhcpMessageType;
	MSG->OPT[5] = 0x01;
	MSG->OPT[6] = DHCP_RELEASE;

	MSG->OPT[7] = endOption;

	for (i = 8; i < 312; i++) MSG->OPT[i] = 0;

	// DST IP
	ServerAddrIn.sin_port = DHCP_SERVER_PORT;
	ServerAddrIn.sin_addr.s_addr = 0xFFFFFFFF;

	sendto(s, (UCHAR *)(&MSG->op), RIP_MSG_SIZE,(sockaddr*)&ServerAddrIn);
}
*/

void DefaultNetConfig()
{
    COMPOSE_IP(my_ip,192,168,0,200);
#if defined(USE_TCP_CLIENT) || defined(USE_UDP_CLIENT)
    COMPOSE_IP(subnet_ip,255,255,255,0);
    COMPOSE_IP(gateway_ip,192,168,0,1);
#endif
}

#define pMSG ((RIP_MSG *) rcv_buf)
static char parseDHCPMSG(uchar sock)
{
    char type;
    UCHAR opt_len;
    UCHAR * p;
    UCHAR * e;

    if (uc_socket[sock].sremote_port == DHCP_SERVER_PORT)
    {
        //puts("DHCP MSG received..");
        my_ip.ipl=pMSG->yiaddr.ipl;
//		puts(IPAddrStr);
    }
    type = 0;
    p = (UCHAR *)(pMSG);
    p = p + 240;
    e = p + (rcv_len - 240);
// OPTIONS auswerten
    while ( p < e )
    {
        switch ( *p++ )
        {
            case endOption :
                return	type;
                break;
        case padOption :
                break;
        case dhcpMessageType :
                p++;
                type = *p++;
                break;
        case subnetMask :
                p++;
                for (uint16_t i = 0; i < 4; i++)	subnet_ip.bytes[i] = *p++;
                break;
        case routersOnSubnet :
                p++;
                for (uint16_t i = 0; i < 4; i++)	gateway_ip.bytes[i] = *p++;
                break;
/*	  	case dns :
//				p++;
                p++;
                for (i = 0; i < 4; i++)	DNS[i] = *p++;*/
/*				iprintf("dns : ");
                inet_ntoa(DNS,IPAddrStr);
                WriteScreen(IPAddrStr);
                WriteScreenf("\r\n");*/
                break;
            default :
                opt_len = *p++;
                p += opt_len;
                break;
        }
    }
    return	type;
}

char DHCP_SetIP()
{
    UCHAR i;
    UCHAR RetryCnt;
    uint16_t res;
    UCHAR type;      		// DHCP message type
    TX_BUFFER *pbuf;

    type = 0;
    RetryCnt = 0;

    // Discover DHCP server
    SOCKET_SETUP(UDP_SOCK,SOCKET_UDP,68,FLAG_PASSIVE_OPEN);
    if(open_socket_udp(UDP_SOCK, 0xffffffff, 67)!=0) {
        puts("Error opening UDP Socket");
        return 0;
    }
    pbuf=allocate_tx_buf();
    while(1)
    {
        send_DHCP_DISCOVER(UDP_SOCK,(uchar*)pbuf->buffer);
        // Check continuously with some delay if OFFER msg arrived from the DHCP server
        for(i = 0 ; i < 255; i++)
        {
            res=poll_net();
            if((res&0xff00)==EVENT_UDP_DATARECEIVED)
            {
                type = parseDHCPMSG(res&0xff);
                if (type == DHCP_OFFER)
                {
                    puts("Receive DHCP_OFFER OK");
                    break;
                }
            }
            _delay_ms(100);
//            wait_10ms(5);		// Wait OFFER message
        }
        if (type == DHCP_OFFER)
            break;
        else if ( RetryCnt++ > 5){
            free_tx_buf(pbuf);
            close_socket_udp(UDP_SOCK);
            DefaultNetConfig();
            return 0;
        }
    }

    RetryCnt = 0;
    type = 0;

    // After receiving OFFER message, send REQUEST message
    while(1)
    {
        send_DHCP_REQUEST(UDP_SOCK,(uchar*)pbuf->buffer);
        puts("Send DHCP REQUEST OK");
        // Check continuously with some delay if ACK message arrived from the DHCP server
        for(i = 0 ; i < 255; i++)
        {
            res=poll_net();
            if((res&0xff00)==EVENT_UDP_DATARECEIVED)
            {
                type = parseDHCPMSG(res&0xff);
                if (type == DHCP_ACK)
                {
                    puts("Receive DHCP_ACK OK");
                    break;
                    }
            }
            _delay_ms(100);
        }
        if (type == DHCP_ACK){
            break;
        } else if ( RetryCnt++ > 5){
            DefaultNetConfig();
            break;

        }
    }

    free_tx_buf(pbuf);
    close_socket_udp(UDP_SOCK);
    // Setup packet information from the server

    return 1;
}

