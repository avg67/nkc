/* $Workfile:   dhcp.c $									 										  */
/* $Revision: 1.1 $                                            	*/
/* $Author: hse00045 $                           								*/
/* $Date: 2003/14/02 19:31:38 $																	*/
/* Description:	DHCP Client for W3100A- Chip                    */
/*																											        */
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

//#define IP_FH									//IP Adress inside FH- Net used

/*#ifdef IP_FH
unsigned char flash IPAdr[4]={10,24,1,101};         //  IP- Address of Sandbox (10.24.1.101)
unsigned char flash GWAdr[4]={10,24,1,254};         //  IP- Address of Default Gateway (10.24.1.254)
unsigned char flash Mask[4]={255,255,255,0};        //  Subnet- Mask (255,255,255,0)
#else
unsigned char flash IPAdr[4]={10,0,0,101};
unsigned char flash GWAdr[4]={10,0,0,138};
unsigned char flash Mask[4]={255,255,255,0};

#endif */


/*UCHAR SubMask[4];			// Global variable for subnet mask value received from dhcp server
UCHAR Gateway[4];                 // Global variable for gateway ip address value received from dhcp server
UCHAR IpAddr[4];			// Global variable for ip address value received from dhcp server
UCHAR DNS[4];			// Global variable for domain name server ip address value received from dhcp server

RIP_MSG MSG;

u_char sin_addr[6];		// DHCP Server IP Address
u_int sin_port;	  		// DHCP Server Port Number
*/

// Create Discover DHCP packet and broadcast it.
void send_DHCP_DISCOVER(uchar sock,uchar *pBfr)
{
//	uint16_t i;
	RIP_MSG * MSG=(RIP_MSG *)pBfr;
	//#define MSG ((RIP_MSG *) pBfr)
	// Generate DISCOVER DHCP PACKET
	// setting values as DHCP Protocol
	MSG->op = DHCP_BOOTREQUEST;
	MSG->htype = DHCP_HTYPE10MB;
	MSG->hlen = DHCP_HLENETHERNET;
	MSG->hops = DHCP_HOPS;
	MSG->xid = DHCP_XID;
	MSG->secs = DHCP_SECS;
	MSG->flags = DHCP_FLAGSBROADCAST;

	memset(MSG->ciaddr,0,RIP_MSG_SIZE-12);
/*	MSG->ciaddr[0] = 0;
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
	MSG->giaddr[3] = 0;*/


	// setting default Mac Address Value.
//	*((unsigned long*)MSG->chaddr)=*((unsigned long*)my_mac);
//	*((unsigned int*)MSG->chaddr+4)=*((unsigned int*)my_mac+4);
	//xram_fast_copy(my_mac,MSG->chaddr,6);
    memcpy(MSG->chaddr, my_mac, 6);
/*	MSG->chaddr[0] = my_mac[0];
	MSG->chaddr[1] = my_mac[1];
	MSG->chaddr[2] = my_mac[2];
	MSG->chaddr[3] = my_mac[3];
	MSG->chaddr[4] = my_mac[4];
	MSG->chaddr[5] = my_mac[5];*/

/*	for (i = 6; i < sizeof(MSG->chaddr); i++) MSG->chaddr[i] = 0;
	for (i = 0; i < sizeof(MSG->sname); i++) MSG->sname[i] = 0;
	for (i = 0; i < sizeof(MSG->file); i++) MSG->file[i] = 0;*/

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
	MSG->OPT[15]= 7;
	memcpy(&MSG->OPT[16],"Sandbox",7);	//16-22

	MSG->OPT[23] = endOption;


	// Null Padding
//	for (i = 24; i < 312; i++) MSG->OPT[i] = 0;

	/* DST IP : BroadCasting*/
//	sin_port = DHCP_SERVER_PORT;
//	for (i=0; i<4; i++) sin_addr[i] = 0xFF;

//	sendto(s, (UCHAR *)(&MSG->op), RIP_MSG_SIZE, sin_addr, sin_port);
	send_socket_udp(sock,pBfr,RIP_MSG_SIZE);
}



void send_DHCP_REQUEST(uchar sock,uchar *pBfr)
{
//	uint16_t i;
	RIP_MSG * MSG = (RIP_MSG *)pBfr;
	//#define MSG ((RIP_MSG *) pBfr)

	MSG->op = DHCP_BOOTREQUEST;
	MSG->htype = DHCP_HTYPE10MB;
	MSG->hlen = DHCP_HLENETHERNET;
	MSG->hops = DHCP_HOPS;
	MSG->xid = DHCP_XID;
	MSG->secs = DHCP_SECS;
	MSG->flags = DHCP_FLAGSBROADCAST;

	//*((unsigned long *)MSG->ciaddr)=my_ip.ipl;
	MSG->ciaddr[0] = my_ip.bytes[0];
	MSG->ciaddr[1] = my_ip.bytes[1];
	MSG->ciaddr[2] = my_ip.bytes[2];
	MSG->ciaddr[3] = my_ip.bytes[3];

	memset(MSG->yiaddr,0,RIP_MSG_SIZE-16);

/*	MSG->yiaddr[0] = 0;
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
	MSG->giaddr[3] = 0;*/

	MSG->chaddr[0] = my_mac[0];
	MSG->chaddr[1] = my_mac[1];
	MSG->chaddr[2] = my_mac[2];
	MSG->chaddr[3] = my_mac[3];
	MSG->chaddr[4] = my_mac[4];
	MSG->chaddr[5] = my_mac[5];
	//xram_fast_copy(my_mac,MSG->chaddr,6);

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
	MSG->OPT[5] = 0x01;
	MSG->OPT[6] = DHCP_REQUEST;

	// DHCP Option Request Param.
	MSG->OPT[7] = dhcpParamRequest;
	MSG->OPT[8] = 0x05;
	MSG->OPT[9] = subnetMask;
	MSG->OPT[10] = routersOnSubnet;

	MSG->OPT[11] = dns;
	MSG->OPT[12] = dhcpT1value;
	MSG->OPT[13] = dhcpT2value;
//	MSG->OPT[14] = endOption;
	MSG->OPT[14]= hostName;
	MSG->OPT[15]= 7;
	memcpy(&MSG->OPT[16],"Sandbox",7);
	MSG->OPT[23] = endOption;

//	for (i = 15; i < 312; i++) MSG->OPT[i] = 0;

	// DST IP : BroadCasting
//	sin_port = DHCP_SERVER_PORT;
//	for (i=0; i<4; i++) sin_addr[i] = 0xFF;
//	sendto(s, (UCHAR *)(&MSG->op), RIP_MSG_SIZE, sin_addr, sin_port);
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
/*	IndirectWritefBuf(SRC_HA_PTR,MacAdr,6);
	IndirectWritefBuf(SRC_IP_PTR,IPAdr,4);
	IndirectWritefBuf(GATEWAY_PTR,GWAdr,4);
	IndirectWritefBuf(SUBNET_MASK_PTR,Mask,4);
	sysinit(0x55, 0x55);*/
	COMPOSE_IP(my_ip,192,168,0,200);
#if defined(USE_TCP_CLIENT) || defined(USE_UDP_CLIENT)
	COMPOSE_IP(subnet_ip,255,255,255,0);
	COMPOSE_IP(gateway_ip,192,168,0,1);
#endif
}


char DHCP_SetIP()
{
	UCHAR i;
	UCHAR RetryCnt;
	uint16_t res;
//	UCHAR sock;
//	u_char Addr[6];
	UCHAR type;      		// DHCP message type
	TX_BUFFER *pbuf;


	type = 0;
	RetryCnt = 0;
//	len = 0;

	// Discover DHCP server
    SOCKET_SETUP(UDP_SOCK,SOCKET_UDP,68,FLAG_PASSIVE_OPEN);
	if(open_socket_udp(UDP_SOCK,0xffffffff,67)!=0) {
		puts("Error opening UDP Socket\r");
		return 0;
	}
	pbuf=allocate_tx_buf();
    while(1)
    {
        send_DHCP_DISCOVER(UDP_SOCK,(uchar*)pbuf->buffer);
//  		WriteScreenf("Send DHCP_DISCOVER OK\r\n");
//		RetryCnt=select(s,SEL_CONTROL);
        // Check continuously with some delay if OFFER msg arrived from the DHCP server
        for(i = 0 ; i < 255; i++)
        {
            res=poll_net();
            if((res&0xff00)==EVENT_UDP_DATARECEIVED)
            {
                type = parseDHCPMSG(res&0xff);
                if (type == DHCP_OFFER)
                {
                    puts("Receive DHCP_OFFER OK\r\n");
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
//	len = 0;

	// After receiving OFFER message, send REQUEST message
    while(1)
    {
        send_DHCP_REQUEST(UDP_SOCK,(uchar*)pbuf->buffer);
        puts("Send DHCP REQUEST OK\r\n");
    //		wait_10ms(5);		// Wait REQUEST message
        // Check continuously with some delay if ACK message arrived from the DHCP server
        for(i = 0 ; i < 255; i++)
        {
            res=poll_net();
            if((res&0xff00)==EVENT_UDP_DATARECEIVED)
            {
                type = parseDHCPMSG(res&0xff);
                if (type == DHCP_ACK)
                {
                    puts("Receive DHCP_ACK OK\r\n");
                    break;
                    }
            }
            _delay_ms(100);
    //			wait_10ms(5);
        }
        if (type == DHCP_ACK){
            break;
        } else if ( RetryCnt++ > 2){ //10
    //			free_tx_buf(pbuf);
    //			close_socket_udp(UDP_SOCK);
            DefaultNetConfig();
            break;

        }
    }

    free_tx_buf(pbuf);
    close_socket_udp(UDP_SOCK);
    // Setup packet information from the server

    return 1;
}

#define pMSG ((RIP_MSG *) rcv_buf)
char parseDHCPMSG(uchar sock)
{


//	uint16_t len;
//	UCHAR DNS[6];
	char type;
    UCHAR opt_len;
	UCHAR * p;
	UCHAR * e;

//	len = recvfrom(s, (UCHAR*)&MSG, length, ServerAddrIn, &ServerPort);

	if (uc_socket[sock].sremote_port == DHCP_SERVER_PORT)
	{
		//puts("DHCP MSG received..\r\n");
//		puts("yiaddr : ");
//		for (i = 0; i < 4; i++)	my_ip.bytes[i] = pMSG->yiaddr[i];
		my_ip.ipl=*((unsigned long *)pMSG->yiaddr);
		//inet_ntoa(IpAddr,IPAddrStr);
//		puts(IPAddrStr);
//		putchar('\r');
	}
	type = 0;	//(*((unsigned long*)pMSG->OPT)==MAGIC_COOKIE)?pMSG->op:0;
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
//				goto PARSE_END;
				break;
    	case padOption :
//				p++;
				break;
   		case dhcpMessageType :
//				p++;
				p++;
				type = *p++;
//        		puts("dhcpMessageType : ");
//				PutHTOA(type);
//				iprintf("%02x\r\n",type);
//				PutStringLn("");
				break;
   		case subnetMask :
//				p++;
				p++;
				for (uint16_t i = 0; i < 4; i++)	subnet_ip.bytes[i] = *p++;
				//xram_fast_copy(p,subnet_ip.bytes,4);
				//p+=4;
//				subnet_ip.ipl=*((unsigned long *)p);

/*				WriteScreenf("subnetMask : ");
				inet_ntoa(SubMask,IPAddrStr);
				WriteScreen(IPAddrStr);
				WriteScreenf("\r\n");*/
				break;
      case routersOnSubnet :
//				p++;
				p++;
				//xram_fast_copy(p,gateway_ip.bytes,4);
				//p+=4;
				for (uint16_t i = 0; i < 4; i++)	gateway_ip.bytes[i] = *p++;
/*				WriteScreenf("routersOnSubnet : ");
				inet_ntoa(Gateway,IPAddrStr);
				WriteScreen(IPAddrStr);
				WriteScreenf("\r\n");*/
				break;
/*	  	case dns :
//				p++;
				p++;
				for (i = 0; i < 4; i++)	DNS[i] = *p++;*/
/*				WriteScreenf("dns : ");
				inet_ntoa(DNS,IPAddrStr);
				WriteScreen(IPAddrStr);
				WriteScreenf("\r\n");*/
				break;
			default :
//				p++;
				opt_len = *p++;
				p += opt_len;
/*				WriteScreenf("opt_len : ");
				//PutHTOA(opt_len);
				sprintf(IPAddrStr,"%02x\r\n",opt_len);
				WriteScreen(IPAddrStr);
//				PutStringLn("");*/
				break;
		}
	}
//PARSE_END:
    return	type;
}
