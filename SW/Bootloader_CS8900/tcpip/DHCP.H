/* $Workfile:   dhcp.h $                                        */
/* $Revision: 1.1 $                                            	*/
/* $Author: Andfreas Voggeneder $                               */
/* $Date: 2003/14/02 19:31:38 $                                 */
/* Description:	DHCP Client for CS8900                          */
/*                                                              */
/* Remarks:     No remarks.                                     */

#ifndef __DHCP_H
#define __DHCP_H

#include "net.h"
#include "type.h"

/* UDP port numbers for DHCP */
#define	DHCP_SERVER_PORT	67	/* from server to client */
#define DHCP_CLIENT_PORT	68	/* from client to server */

/* DHCP message OP code */
#define DHCP_BOOTREQUEST	1
#define DHCP_BOOTREPLY		2

/* DHCP message type */
#define	DHCP_DISCOVER		1
#define DHCP_OFFER			2
#define	DHCP_REQUEST		3
#define	DHCP_DECLINE		4
#define	DHCP_ACK  			5
#define DHCP_NAK  			6
#define	DHCP_RELEASE		7
#define DHCP_INFORM  		8

/* DHCP RETRANSMISSION TIMEOUT (microseconds) */
#define DHCP_INITIAL_RTO    ( 4*1000000)
#define DHCP_MAX_RTO        (64*1000000)

#define DHCP_HTYPE10MB		1
#define DHCP_HTYPE100MB		2

#define DHCP_HLENETHERNET	6
#define DHCP_HOPS			0
#define DHCP_XID 			0x12345670  // Client Unique ID
#define DHCP_SECS			0

#define DHCP_FLAGSBROADCAST	0x8000

#define MAGIC_COOKIE		0x63825363

#define DEFAULT_LEASETIME	0xffffffff	/* infinite lease time */

/* DHCP option and value (cf. RFC1533) */

typedef enum _OPTION
{
	padOption = 0,
	subnetMask =1,
	timerOffset =2,
	routersOnSubnet=3,
	timeServer=4,
	nameServer=5,
	dns=6,
	logServer=7,
	cookieServer=8,
	lprServer=9,
	impressServer=10,
	resourceLocationServer=11,
	hostName=12,
	bootFileSize=13,
	meritDumpFile=14,
	domainName=15,
	swapServer=16,
	rootPath=17,
	extentionsPath=18,
	IPforwarding=19,
	nonLocalSourceRouting=20,
	policyFilter=21,
	maxDgramReasmSize=22,
	defaultIPTTL=23,
	pathMTUagingTimeout=24,
	pathMTUplateauTable=25,
	ifMTU=26,
	allSubnetsLocal=27,
	broadcastAddr=28,
	performMaskDiscovery=29,
	maskSupplier=30,
	performRouterDiscovery=31,
	routerSolicitationAddr=32,
	staticRoute=33,
	trailerEncapsulation=34,
	arpCacheTimeout=35,
	ethernetEncapsulation=36,
	tcpDefaultTTL=37,
	tcpKeepaliveInterval=38,
	tcpKeepaliveGarbage=39,
	nisDomainName=40,
	nisServers=41,
	ntpServers=42,
	vendorSpecificInfo=43,
	netBIOSnameServer=44,
	netBIOSdgramDistServer=45,
	netBIOSnodeType=46,
	netBIOSscope=47,
	xFontServer=48,
	xDisplayManager=49,
	dhcpRequestedIPaddr=50,
	dhcpIPaddrLeaseTime=51,
	dhcpOptionOverload=52,
	dhcpMessageType=53,
	dhcpServerIdentifier=54,
	dhcpParamRequest=55,
	dhcpMsg=56,
	dhcpMaxMsgSize=57,
	dhcpT1value=58,
	dhcpT2value=59,
	dhcpClassIdentifier=60,
	dhcpClientIdentifier=61,
	endOption = 255
}OPTION;

typedef struct _RIP_MSG{
	UCHAR op;
	UCHAR htype;
	UCHAR hlen;
	UCHAR hops;
	ULONG xid;
	uint16_t secs;
	uint16_t flags;
	UCHAR ciaddr[4];
	//UCHAR yiaddr[4];
    IP_ADR yiaddr;
	UCHAR siaddr[4];
	UCHAR giaddr[4];
	UCHAR chaddr[16];
	UCHAR sname[64];
	UCHAR file[128];
	UCHAR OPT[312];
}RIP_MSG;

#define RIP_MSG_SIZE	548
#define MAX_DHCP_OPT	16




extern void send_DHCP_DISCOVER(uchar sock,uchar  *pBfr);     		/* Send DHCP_DISCOVER message to a dhcp server. */
extern void send_DHCP_REQUEST(uchar sock,uchar  *pBfr);                /* Send DHCP_REQUEST message to a dhcp server. */
//extern void send_DHCP_RELEASE(SOCKET s);

extern char DHCP_SetIP();				/* request Ip address to a dhcp server and then apply received ip address from dhcp server to W3100A */

extern char parseDHCPMSG(uchar sock);		/* Analyze message received from dhcp server and then apply it. */



// Definition default MAC address to be used in dhcp-client

/*#define DEFAULT_MAC0	0x00
#define DEFAULT_MAC1	0x08
#define DEFAULT_MAC2	0xDC
#define DEFAULT_MAC3	0x00
#define DEFAULT_MAC4	0x00
#define DEFAULT_MAC5	0x00*/

/* DEFINE DHCP MACGIC COOKIE */
/* Like to DEFAULT MAC ADRESS , this value is unique - You must specify this value */
#define MAGIC0	 0x63
#define MAGIC1	 0x82
#define MAGIC2	 0x53
#define MAGIC3	 0x63

#endif


