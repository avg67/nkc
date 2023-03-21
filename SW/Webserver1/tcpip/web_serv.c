/* $Author: hse00045 $                           				*/
/* $Date: 2003/14/02 19:31:38 $									*/
/* Description:	Webserver main file			                    */
/*																*/
/* Remarks:     No remarks.                                     */
/*    															*/

#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <stdlib.h>

#include "net.h"		// Basic network handling (public)
#include "web_serv.h"		// Webserver
#include "webfiles.h"
#include "base64.h"
//#include "dynhtml.h"
//#include "..\GrTest\graph_ext.h"

//extern bit OCH;
//extern int HitCnt;
#define _HTTPHDR_

#define CMDGET 	1
#define CMDPOST 2

// Data Structuires required for Authorization
/*typedef enum {NONE=0,REQUEST_SENT,AUTHORIZED} tAuthState;
typedef struct {
	tAuthState state;
	tFile const *pfile;
}tAuth;

tAuth  Auth;*/


// This is the Default Message. Using code 200 displays OUR page, whereas 404 may display a Browser's message...
static char const html_notfound[] = {
#ifndef _HTTPHDR_
"HTTP/1.0 200 OK\r\n"
"Content-Type: text/html\r\n"
"Connection: close\r\n"
"\r\n"
#endif
"<html><head><title>Andi's Webserver</title></head>"
"<body text=\"#0000FF\" bgcolor=\"#FFFF80\" link=\"#FF0000\">"
"Page not found"
"</body></html>\r\n"
};

#ifdef _HTTPHDR_
static char const GetResponse[] =
	{
    "HTTP/1.1 200 OK\r\n"
   	"Server: SAB80C517a\r\n"
//   	"Last-modified: "__DATE__" "__TIME__" GMT\r\n"
	};

static char const Response401[] =
	{
    "HTTP/1.0 401 Authorization required\r\n"
	};

static char const pContentType[]="Content-Type: ";
static char const pContentLength[]="Content-length: ";
static char const pCloseStr[]="\r\nConnection: close";
static char const pAuthenticate[]="WWW-Authenticate: Basic realm=";

// Creates the Header required for normal html Files or Pictures,
size_t CreateStdHeader(tFile const * const pFile, char *pbuf) {
    size_t len;
    char str[10];

    len=sizeof(GetResponse) - 1+4
        +sizeof(pContentType)-1+sizeof(pCloseStr)-1;          // calculated length of Header

    memcpy(pbuf, GetResponse, sizeof(GetResponse));
    //	*(pbuf+sizeof(GetResponse) - 1)=0;

    if(pFile) {
        len+=strlen(pFile->pTypeStr);
        if(pFile->pTypeStr==jpgType || pFile->pTypeStr==gifType) {
            strcpy(pbuf+sizeof(GetResponse) - 1,pContentLength);
            siprintf(str,"%d\r\n",pFile->size);
            strcat(pbuf,str);
            len+=strlen(str)+sizeof(pContentLength)-1;
        }
        strcat(pbuf,pContentType);
        strcat(pbuf,pFile->pTypeStr);
    }else{
        len+=(sizeof(htmlType)-1);
        strcat(pbuf,pContentType);
        strcat(pbuf,htmlType);

    }
    strcat(pbuf,pCloseStr);
    strcat(pbuf,"\r\n\r\n");
    return len;
}
#endif

// Creates an 401 Authorization request, using Realm provided by pFile
size_t Create401Header(tFile const * const pFile, char *pbuf) {
    size_t len;
    char *ptr;

    if(!pFile) return 0;

    len = strlen(pFile->pRealm);


    ptr=memcpy(pbuf, Response401, sizeof(Response401) - 1);
    ptr+=(sizeof(Response401) - 1);
    ptr=memcpy(ptr,pAuthenticate,sizeof(pAuthenticate) - 1)+(sizeof(pAuthenticate) - 1);
    *ptr++='"';
    ptr=strcpy(ptr,pFile->pRealm)+len;
    *ptr++='"';
    strcpy(ptr,"\r\n\r\n");

    len = len +2
        + sizeof(Response401) - 1+4
        + sizeof(pAuthenticate) - 1;


    return len;
}

// Search the requested File in Filesystem
tFile const* FindFile(char *pFileName) {
  tFile const * pFile = webFiles;
  uint16_t i;

  for(i=0;i<(sizeof(webFiles)/sizeof(tFile));i++) {
    if(!strcmp(pFileName,pFile->pName)) break;
    pFile++;
  }
  if (i==(sizeof(webFiles)/sizeof(tFile))) return 0;

  return pFile;
}

// Parse the posted Client Form- Data and extract Values
void ParseData(char *pPostedData,char * pFormName) {
    char *pValue, *pEnd;
    uint16_t i;
    tForm const *pForms = (tForm const *)Forms;

    // Search for Parser for posted Form
    for(i=0;i<(sizeof(Forms)/sizeof(tForm));i++) {
        if(strcmp(pFormName,pForms->pName)==0) {
            i=0xff;
            (*pForms->f)(0,0);		// Set Defaults of Form
            break;
        }
        pForms++;
    }

    //  	pPostedData+=4;
    if(i==0xff) {
        pEnd=strchr(pPostedData,' ');
        if(pEnd){
            *pEnd=0;
        }
        while(pPostedData)  {	//>4
            if((pValue=strchr(pPostedData,'='))!=0) {
                *pValue++=0;
                if((pEnd=strchr(pValue,'&'))!=0) {
                    *pEnd++=0;
                }
                // And now evaluate Fields
                (*pForms->f)(pPostedData,pValue);
                pPostedData=pEnd;
            }else return;  // Error occured. Stop parsing.
        }
        if(pForms->pFile)
            strcpy(pFormName,pForms->pFile);
    }
}

unsigned char atox(char xchr) {
    unsigned char tmp=((unsigned char)xchr)-'0';
    if (tmp>9) tmp-=7;
    return tmp;
}

// User- Callable Function to convert a posted String into ASCII
void ConvertString(uchar *pBuf) {
    uchar * pString;

        pString=pBuf;
        while(*pBuf!=0) {
            if(*pBuf=='+')  {
                *pString++=' ';		// Text invers darstellen
                pBuf++;
            }
            else if(*pBuf=='%' && isxdigit(*(pBuf+1)) && isxdigit(*(pBuf+2))) {
                uchar erg=' ';
                erg=atox(*(pBuf+1))<<4|atox(*(pBuf+2));

    /*				char val[3],erg=' ';
                val[0]=*(pBuf+1);
                val[1]=*(pBuf+2);
                val[2]=0;*/

    //				if (sscanf(val,"%x",&erg)!=1)
    //					erg=' ';
    //				erg=atoi(val);
                *pString++=erg;
                pBuf+=3;
            }else{
                *pString++=*pBuf++;
            }
        }
        *pString=0;  		// terminate String
}


// Here the HTTP state machine is managed
HTTP_INFO http_info[MAX_SOCK];

//uchar  *web_args; // static internal variable, points to start of first argument

uchar csock=0xFF;	//   static internal variable, Current-Socket Index if !0xFF



//Creates dynamic HTML
// Replaces embedded TAGS (@TAG@)

uint16_t gendyn_html(HTTP_INFO *pinfo, char *pbuf, uint16_t bufsize){
    uint16_t leftos;		// Left to send or process
    uint16_t cnt;		// No. of data to send
    uchar rlen;
    char pTag[16];
    char pReplace[32];

    char  *dsrc;

    char const *psrc;	// Source is in pinfo
    bool df;
    char c;

    psrc=(char*)pinfo->pweb;
    leftos=pinfo->weblen;
    df=(pinfo->pfile && pinfo->pfile->f!=0);	//dyna_flag;
    cnt=0;
    while(leftos){
        c=*psrc;
        psrc++;
        leftos--;
        if(df && c=='@'){	// Dynamic Sentinel
            rlen=0;
            do {
                pTag[rlen]=*psrc;
                psrc++;
                rlen++;
            }while(*psrc!='@' && rlen<sizeof(pTag));
            if(*psrc=='@') {
                psrc++;
                pTag[rlen]='\0';
                {
                    uchar varlen=(pinfo->pfile->f)(pTag,pReplace,sizeof(pReplace));
                    if (varlen) {
                        if((cnt+varlen)<=bufsize){
                            leftos-=(rlen+1);
                            rlen=varlen;
                        }else{
                            psrc--;		// Wind back HTML-Template and
                            leftos++;	// use a new segment...
                            break;
                        }
                    }else{
                        rlen++;
                        goto rollback;
                    }

                }
    //				if(rlen>MAX_TX) rlen=MAX_TX;	// Clip too long variables to max. segment size

    /*				if(rlen+cnt>MAX_TX){	// Current data + Variable: Too much!
                    psrc--;		// Wind back HTML-Template and
                    leftos++;	// use a new segment...
                    break;		// Exit for now
                }*/

                dsrc=pReplace;
                // Insert Var. string in HTML
                while(rlen--){
                    c=*dsrc;
                    dsrc++;
                    *pbuf=c;
                    pbuf++;
                    cnt++;
                }
            }else{
rollback:
                psrc-=(rlen);
                *pbuf=c;
                pbuf++;
                cnt++;
            }

		}else{
			*pbuf=c;
			pbuf++;
			cnt++;
		}

		if(cnt==bufsize) break;	// Buffer full
	}

	pinfo->pweb=(uchar*)psrc;
	pinfo->weblen=leftos;

	return cnt;
}

#if 0
extern unsigned char  display[];
static const tBMP Hdr={{'B','M'},
                swap_endian32(128L*64/8+54+8),
                0,
                swap_endian32(54L+8),
                swap_endian32(40L),
                swap_endian32(128L),
                swap_endian32(64L),
                swap_endian16(1L),
                swap_endian16(1L),
                0,
                swap_endian32(128L*64/8),
                0,
                0,
                0,
                0,
                swap_endian32(0x0004400L),
                swap_endian32(0x00ffffffL)};

/*void createBMPHdr(tBMP  *pBmpBfr) {
	pBmpBfr->ID[0]='B';
	pBmpBfr->ID[1]='M';
	pBmpBfr->reserved1=0;
	pBmpBfr->fs=swap_endian32(128L*64/8+54);
	pBmpBfr->ofs=swap_endian32(54);
	pBmpBfr->hdrLen
	pBmpBfr->hwidth
	pBmpBfr->vwidth
	pBmpBfr->nrPlanes
	pBmpBfr->bpp
	pBmpBfr->cpr


}*/

uint16_t createBMP(HTTP_INFO  *pinfo, uchar  *pbuf, uint16_t bufsize){
	uint16_t leftos;		// Left to send or process
	uint16_t cnt;			// No. of data to send
	uchar mask;
	uchar x;

	uchar  *psrc;	// Source is in pinfo
	register uchar c;

	leftos=pinfo->weblen;


	if(leftos<1024){
//		psrc=(uchar *)pinfo->pweb;
		cnt=0;
	}else{
		memcpy(pbuf,&Hdr,sizeof(Hdr));
		pbuf+=sizeof(Hdr);
		cnt=sizeof(Hdr);
		leftos-=sizeof(Hdr);
//		psrc=display;

	}
	{
		unsigned char y;

		y=(leftos-1)/16;
		x=((1024-leftos)*8)%128;
		psrc=display+y/8*128L;
		mask=1<<(y%8);
	}
//	mask=0x80>>(y%8);

// 1. Reihe 0 - 7f
// 2. Reihe 80 - ff


	while(leftos){
//		mask=0x01;
		while(x<128){
			c<<=1;
			c|=(psrc[x]&mask)?1:0;
			if((x++%8)==7){
				*pbuf=c;
				pbuf++;
				cnt++;
				leftos--;
				if(cnt==bufsize) {
					goto exit;
				}
			}

		}
//		mask<<=1;
		mask>>=1;
		if(!mask) {
			mask=0x80;	//1
			psrc-=128;
		}
		x=0;
//		y--;

	}
exit:
	pinfo->weblen=leftos;

	return cnt;
}
#endif


/**********************************************************************************
*  poll_webserver()
**********************************************************************************/
uint16_t poll_webserver(void){
//	static bit headsent;
	bool first;
	uint16_t res;
	uchar uci;	//,c;
	uchar sock,state,cmd=0;
	HTTP_INFO  *pinfo;

	uint16_t sendlen;		// Temp. Len
	TX_BUFFER *pbuf;	// Temp. Buffer

	res=poll_net();
	//if(res) iprintf("Res %x ",res);
	// First check if a socket is pending
    if(!res && csock!=0xFF && http_info[csock].html_state==3 &&  !notready_socket_tcp(csock,RDY_4_TX)){
        // Patch EVENT
        res=EVENT_TCP_DATARECEIVED+csock;
        rcv_len=0;
        rcv_ofs=0;
        csock=0xFF;
    }else if(res==EVENT_SOCKET_IDLETIMER){
        for(uci=0;uci<MAX_SOCK;uci++){
            if(http_info[uci].html_state>=1 &&  !notready_socket_tcp(uci,RDY_4_TX)){
                // Patch EVENT (simulate a received 0-size segment)
                res=EVENT_TCP_DATARECEIVED+uci;
                rcv_len=0;
                rcv_ofs=0;
            }
        }
    }

	// Received a TCP_EVENT. Could indicate received data or a closure of the TCP socket
	if(res>=0xF000){
		sock=(uchar)res;	// isolate socket index
		// Only process HTTP-Sockets!
		if(uc_socket[sock].local_port!=80) return res;
		pinfo=&http_info[sock];	// Pointer to HTTP_INFO for the current socket
		state=pinfo->html_state;

		// *** RECEIVED DATA ***
		if((res&0xFF00)==EVENT_TCP_DATARECEIVED) {
#if 0 // Disabled (enable only for debugging)
			// Show request...
			for(uint16_t i=0;i<rcv_len;i++){
				const char c=rcv_buf[i];
				if(c=='\r') puts("<CR>");
				else if(c=='\n') puts("<LF>");
				else putchar(c);
			}
			putchar('\n');
#endif
			res=0;	// This is our new return EVENT (default: nothing)
			if(rcv_len){
				char  FileName[20];
				static uint16_t PostedLength;
				char  *pEnd,*pContent;		// CR,LF marks end of request

				rcv_buf[rcv_ofs+rcv_len]=0;
				// State 0: Searching for CMD
				// State 1: Searching for Packet End (multiple TCP Packets allowed)
				//
				if(state==0){
					cmd=0;
					first=0;
					pinfo->headsent=0;
					PostedLength=0xffff;
					if(!strncmp(rcv_buf,"GET",3)){	//reply.htm?A1=12&A2=34&A3=56&A9=Set+Clock
	  					cmd=CMDGET;
						state=1;
	  				}else if(!strncmp(rcv_buf,"POST",4)){
						cmd=CMDPOST;
						state=1;
					}
				}
				if(state==1){	// State 0: READING Request
					if(cmd==CMDGET){
//						pContent=strstr(rcv_buf+4,"\r\n");
						pContent=ExtractFileName(rcv_buf+4,FileName);
						state=2;
					}else if(cmd==CMDPOST){
						ExtractFileName(rcv_buf+5,FileName);
						if(PostedLength==0xffff){
							if((pEnd=strstr(rcv_buf+4,"Content-Length: "))){
								uci=0;
								pEnd+=16;
								while(*(pEnd+uci) && *(pEnd+uci)!='\r')
									uci++;
								if(*(pEnd+uci)=='\r') {
									*(pEnd+uci)='\0';
									PostedLength=atoi(pEnd);
									pEnd+=uci+1;
//									state=2;
								}else{
									pEnd=0;
								}

							}
						}
						if(PostedLength!=0xffff && (pContent=strstr(pEnd,"\r\n\r\n"))){
								// double CR,LF marks end of http Header
							pContent+=4;
//							PostedLength-=(rcv_ofs+rcv_len-(pContent-rcv_buf));
//							first=1;
							PostedLength-=(rcv_ofs-(pContent-rcv_buf));
                            first=0;
							state=2;
						}else
							pContent=0;

						/*pEnd=strstr(rcv_buf,"\r\n\r\n");		// double CR,LF marks end of http Header
						if(pEnd) {
							if (strstr(pEnd+4,"Content-Length:")){

								ExtractFileName(rcv_buf+6,FileName);
//								ParseData(pEnd,FileName);
							}else{
								pEnd=0;
							}
						}*/
					}else
						return 0;

/*					if(pContent) {
						state=2;			// End of Request found. Switch to next State
//						rcv_ofs=0;
					}else{
						rcv_ofs=rcv_len;
					}*/
				}/*else
					rcv_ofs=0;*/

				if(state==2){
				 if(cmd==CMDPOST && PostedLength) {
					if(!first) {
						PostedLength-=(rcv_len>PostedLength)?PostedLength:rcv_len;
					}
					first=0;
					if(!PostedLength) {
						ParseData(pContent,FileName);
					}else{
						rcv_ofs+=rcv_len;
					}
				 }else if(cmd==CMDGET && pContent) {
					// Extract GET-Arguments
					ParseData(pContent,FileName);
				 }

				 if(cmd==CMDGET||(cmd==CMDPOST && !PostedLength)) {	// GET or Post
					tFile const *pFile;

					res=EVENT_HTTP_REQUEST+sock;

					if ((pFile=FindFile(FileName))!=0){
//						if (pFile->pData==WebSide)	HitCnt++;
						webpage_bind(sock,pFile);
						if(cmd==CMDGET) {
							pinfo->authentificated=CheckAuthorization(rcv_buf+4,pFile);
							//Auth.state=AUTHORIZED;
						}
					}else{
						// Set Default Reply to NotFound
						pinfo->pweb=(const uchar*)html_notfound;
						pinfo->weblen=sizeof(html_notfound);
						pinfo->pfile=0;
					}
					state=3;
					rcv_ofs=0;

				 }

				}
			}
			// Parse request


			// Try to send data for states 3 and 4
			if(state>=3){
				if(!notready_socket_tcp(sock,RDY_4_TX)){
					state=3;
/*#ifdef _HTTPHDR_
					if(!headsent) {
						// First create and send HTTP Header
						headsent=1;
						pbuf=allocate_tx_buf();
						sendlen=CreateStdHeader(pinfo->pfile,pbuf);
						send_socket_tcp(sock, pbuf, sendlen);
						csock=sock;
					}else
#endif*/
					if(pinfo->weblen){	// There is still something to send
//						printf("TX %u\n",pinfo->weblen);
						pbuf=allocate_tx_buf(); // Allocate a buffer
//						if(Auth.state!=AUTHORIZED && pinfo->pfile && pinfo->pfile->pRealm){
						if(!pinfo->authentificated && pinfo->pfile && pinfo->pfile->pRealm){
//							if (Auth.state==NONE) {
								sendlen=Create401Header(pinfo->pfile,pbuf->buffer);
//								Auth.state=REQUEST_SENT;
								pinfo->weblen=0;
//							}
						}else{
							// Hier HTTP Header einf�gen !
							if(!pinfo->headsent) {
								sendlen=CreateStdHeader(pinfo->pfile,pbuf->buffer);
								pinfo->headsent=1;
							}else{
								sendlen=0;
							}
							//if(pinfo->pweb){
								sendlen+=gendyn_html(pinfo,pbuf->buffer+sendlen,MAX_TX-sendlen); // Fill Buffer
							/*}else{
								sendlen+=createBMP(pinfo,pbuf+sendlen,MAX_TX-sendlen);
							}*/
						}


						send_socket_tcp(sock, pbuf, sendlen); // Send buffer (safe, because notready()-checked already)
						csock=sock;	// Could send something, retry soon!
					}else{ // Manually close only dynamic Pages...
						state=4;	// Waiting for close could block other transfers
//						puts("Close ");
						if(!notready_socket_tcp(sock,RDY_4_CLOSE)){
							state=0;
							close_socket_tcp(sock);
						}
					}

				}else{ // !notready
					state=4; // Mark socket as pending, try in 500 msec again
					//puts("<BUSY>");
				}

			}
			pinfo->html_state=state;	// Keep state
			pinfo->cmd=cmd;
			return 0;			// Ignore Webserver maintained events

		}else if(res>=0xF800){ // all Events >=0xF800 close TCP Connections.
			pinfo->html_state=0;	// ALL other TCP_EVENTS close the socket (ensured by design)
			pinfo->cmd=0;
			return 0;		// Ignore this Event, socket is maintained by webserver
		}
	}
	return res;
}

// Extract the Filename requested by the client
char * ExtractFileName(char  *pBuf, char  *pNameBuf) {
    char  *pFileName,*pSlash,*pArgs;
    size_t len;

    pFileName=strchr(pBuf,' ');
    pArgs=strchr(pBuf,'?');
    if(pArgs && pArgs < pFileName) pFileName=pArgs; else pArgs=0;
    if (pFileName) {
        *pFileName=0;			//Den Namen  Terminieren, damit sich strrchr nicht verrennt !
        pSlash=strrchr(pBuf,'/');
        if (pSlash==0) {
            pSlash=pBuf;
        }else{
            pSlash++;
        }
        *pFileName=' ';
        len=pFileName-pSlash;
        if(!len) {
            strcpy(pNameBuf,webFiles[0].pName);
        }else{
            strncpy(pNameBuf,pSlash,len);
            pNameBuf[len]=0;
        }
        if (pArgs) pArgs++;
        return pArgs;
    }
    strcpy(pNameBuf,webFiles[0].pName);		// Default Website is index.htm (if Websever is confused)
    return 0;

}

// Checks for an Authentification Parameter within posted Data (from Browser)
// Extracts User / PWD when found and checks if valid User + Password provided
//
bool CheckAuthorization(char  *pBuf, tFile const * const pFile) {
    char  *pAuth,*pEnd;
    size_t len;

//	Auth.pfile=pFile;
    // Requires requested File a Authorization ?
    if (!pFile || !pFile->pRealm) {
//		Auth.state=AUTHORIZED;		// No. Set to "Authorized" state
        return 1;
    }
    if((pAuth=strstr(pBuf,"Authorization: Basic"))){
        pAuth+=21;
        pEnd=strstr(pAuth,"\r\n");
        if (!pEnd) return 0;
        *pEnd='\0';

        len=Curl_base64_decode(pAuth,pAuth);
        if(len){
            *(pAuth+len)='\0';
            pEnd=strchr(pAuth,':');
            if(pEnd) {
                *pEnd++='\0';
                if (!strcmp(pAuth,"avg") && !strcmp(pEnd,"qpal")) {
    //	 				Auth.state=AUTHORIZED;
                    return 1;
                }
            }
        }
    }/*else{
        // Resource requires Authorization and no
        // authorization String found
        Auth.state=NONE;
    }*/
	return 0;
}

/**********************************************************************************
* webpage_bind(uchar socket, code unsigned char *pd)
* This will bind a webpage to a given socket, after a HTTP-Request was received
* for this page.
**********************************************************************************/
void webpage_bind(uchar sock, tFile const * const pFile){
    HTTP_INFO *pinfo;
    pinfo=&http_info[sock];	// Pointer to HTTP_INFO for the current socket

    pinfo->weblen=pFile->size;
    pinfo->pweb=pFile->pData;
    //	pinfo->dyna_flag=(pFile->f!=0);
    pinfo->pfile=pFile;


}



void Init_Webserver(void) {
//	Auth.state=NONE;
//	Auth.pfile=0;
}

// EOF