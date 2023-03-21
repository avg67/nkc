#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <ndrcomp/target.h>
#include <ndrcomp/sysclock.h>
#include "net.h"
#include "netutil.h"
#include "dhcp.h"
#include "web_serv.h"
#include "cs8900_eth.h"

#define TIMER ((CLOCKS_PER_SEC * 36u) / 1000u)  //~35ms = ~28Hz

/*void checkDebug() {
    HTTP_INFO  *pinfo;
    if(gp_csts()) {
        char ch=getchar();
        if (ch=='d' || ch== 'D') {
            PrintReg(PP_LineST,1);
            PrintReg(PP_SelfST,1);
            PrintReg(PP_RxCTL,1);
            PrintReg(PP_LineCTL,1);
            PrintReg(PP_RxStatus,1);
            PrintReg(PP_RxCFG,1);
            PrintReg(PP_RxMiss,1);
            PrintReg(PP_BusCTL,1);
            PrintReg(PP_IA,3);
            pinfo=&http_info[0];	// Pointer to HTTP_INFO for the current socket
    //			iprintf("State(0) %u %u %x\n",pinfo->html_state,pinfo->weblen,notready_socket_tcp(0,RDY_4_TX));

        }
    }
}*/


typedef struct{
    unsigned char std;
    unsigned char min;
    unsigned char sek;
}tTime;

bool readtime (tTime  *pTime)
{
    const time_t now = _gettime();
    const struct tm * p_lt = localtime(&now);
    pTime->std = p_lt->tm_hour;
    pTime->min = p_lt->tm_min;
    pTime->sek = p_lt->tm_sec;
    return true;
}


#if 0
//#define RTC ((unsigned char *)0xFA00)


bit readtime (tTime  *pTime)
{
    unsigned char i;
    unsigned char  *rtc;
	uint8_t ti[6];

    do {
        rtc=RTC;
        for(i=0;i<=5;i++)
            ti[i]=*rtc++;

        rtc=RTC;
        for(i=0;i<=5;i++)
        {
	        if (ti[i]!=*rtc++)
	        {
	            ti[0]=0xff;
	            break;
	        }
	        if ((ti[i] & 0xf) > 9)
	            return(1);
        } /* for */
    } /* do */
    while(ti[0]==0xff);

    pTime->sek=(ti[0] & 15) + (ti[1] & 15)*10;
    pTime->min=(ti[2] & 15) + (ti[3] & 15)*10;
    pTime->std=(ti[4] & 15) + (ti[5] & 15)*10;


    if (pTime->sek > 59 || pTime->min >59 || pTime->std >23 )
    {
        return 1;
    }
    return 0;
}


void settime (tTime  *pTime)
{
    uint8_t i;
    unsigned char  *rtc;
	uint8_t ti[6];

    rtc=RTC;
    ti[0]=pTime->sek-(10*(pTime->sek/10));
    ti[1]=(pTime->sek/10) & 15;
    ti[2]=pTime->min-(10*(pTime->min/10));
    ti[3]=(pTime->min/10) & 15;
    ti[4]=pTime->std-(10*(pTime->std/10));
    ti[5]=(pTime->std/10) & 15;
    rtc[15]=7;
    for(i=0;i<=5;i++)
        rtc[i]=ti[i];
    rtc[15]=4;
}
#endif


int HitCnt=0;


//extern const unsigned char  WebSide[];

/*------------------------------------------------------------------------------
Read_ADC( unsigned char ): reads an analog signal from the received unsigned
char and returns the converted value
------------------------------------------------------------------------------*/
unsigned short Read_ADC( unsigned char channel )
{
  /*ADCON1 &= ~0x0F;                          //Clears Channel for selection
  ADCON1 |= 0x0F & channel;                 //Selects received Channel
  ADDATL |= ~ADDATL;                        //Write to ADDATL starts execution of ADC

  while( ADCON0 & 0x10);                    //Wait until A to D is complete
  return( (  ( (unsigned) ADDATH << 8) | ADDATL ) >> 6 );*/
  return 10u;
}

#if 0
extern volatile clock_t _clock_value;

/*volatile bool timer_flag=false;

void timer_func() {
  static uint8_t _prescaler = TIMER;
  if (!--_prescaler) {
    _prescaler=  TIMER;
    timer_flag=true;
  }
}*/

void _delay_ms(uint16_t delay) {
    const uint32_t end_time = _clock_value + (((uint32_t)delay * CLOCKS_PER_SEC) / 1000uL);
    //iprintf("time %d - %d",_clock_value,end_time);
    while(_clock_value < end_time) {
    };
 }
#endif

int main(void)
{
// uint8_t socket;
// uint8_t  *pc;
// tFile *pFile;

   //_clock(timer_func);
  setvbuf(stdin, NULL, _IONBF, 0);
  setvbuf(stdout, NULL, _IONBF, 0);
  setvbuf(stderr, NULL, _IONBF, 0);

 _delay_ms(1);
 // A HTTP-Server with only passive sockets requires only an IP address
 COMPOSE_IP(my_ip,0,0,0,0);
#if defined(USE_TCP_CLIENT) || defined(USE_UDP_CLIENT)
 COMPOSE_IP(subnet_ip,0,0,0,0);
 COMPOSE_IP(gateway_ip,0,0,0,0);
#endif

  iprintf("Webserver\r\n");
  iprintf("Compiliert am "__DATE__" um "__TIME__"\r\n");
  iprintf("Compiliert mit GCC Version "__VERSION__"\r\n");


 if(Init_net()) puts("<NET FAILURE>"); // Init Variables, Counter, ...

 //iprintf("MAC:%02bx:%02bx:%02bx:%02bx:%02bx:%02bx\r\n", my_mac[0],my_mac[1],my_mac[2],my_mac[3],my_mac[4],my_mac[5]);
// iprintf("IP:  %bu.%bu.%bu.%bu\r\n",my_ip.bytes[0],my_ip.bytes[1],my_ip.bytes[2],my_ip.bytes[3]);

/* SOCKET_SETUP(UDP_SOCK,SOCKET_UDP,68,FLAG_PASSIVE_OPEN)
 if(open_socket_udp(UDP_SOCK,0xffffffff,67)==0) {
	uint res;
	uint8_t  *pbuf=allocate_tx_buf();
	Send_dhcp_discover(pbuf,0x12345678);
	do {
		do {
			res=poll_net();
		}while(!res);
	}while((res&0xff00)!=EVENT_UDP_DATARECEIVED);

	free_tx_buf(pbuf);
	close_socket_udp(UDP_SOCK);
 }*/
 DHCP_SetIP();

 //COMPOSE_IP(my_ip,10,0,0,101);

 if(Init_net()) puts("<NET FAILURE>");
 iprintf("IP:  %u.%u.%u.%u\r\n",my_ip.bytes[0],my_ip.bytes[1],my_ip.bytes[2],my_ip.bytes[3]);
 puts("*** MINI-WEBSERVER ***\r\n");

 Init_Webserver();

    // Enable ALL (or less) Sockets  as General Server HTTP at port 80
    for(uint16_t i=0;i<(MAX_SOCK-1);i++) {
        SOCKET_SETUP(i,SOCKET_TCP,80,FLAG_PASSIVE_OPEN);
    }
    char ch=0;
  	while(ch!='x') {
        //checkDebug();
        const uint16_t res=poll_webserver();

        if((res&0xFF00) ==EVENT_HTTP_REQUEST){
            char  FileName[20];
            uint8_t socket=(uint8_t)res&0x0f;
            iprintf("!Sock %x ",socket);
//   			pc=webpage_name(); // get name of requested page
            ExtractFileName(rcv_buf+((res&0x00f0)?6:5),FileName);
            iprintf("Webpage %s/%u\n",FileName,socket); // Show requested page and socket

            if((res&0x00f0)) {
                char * pTest=NULL;
                char * pData=strstr(rcv_buf,"\r\n\r\n");
                if(pData && (pTest=strstr(pData+4,"\r\n"))){
                    ParseData(pData,FileName);
                    rcv_ofs=0;
                }else{
                    rcv_ofs=rcv_len;
                }

            }
            const tFile * const pFile=FindFile(FileName);
            if (pFile!=NULL){
                //if (pFile->pData==WebSide)	HitCnt++;
                webpage_bind(socket,pFile);
                puts("  Found ");

            }

//			if(*pc=='a') {
//    			siprintf(aval_0,"%u",ad535(0)/2);
//    			siprintf(aval_1,"%u",ad535(1)/2);
//			    siprintf(aval_2,"%u",ad535(2)/2);
//			    siprintf(aval_3,"%u",ad535(3)/2);
//			    webpage_bind(socket,pFile);
//		   	}else if(*pc=='f'){
//		    	webpage_bind(socket,form);
//		   	}else if(*pc=='r'){
//		    	webpage_bind(socket,reply);
//		   	}else{
//		    	webpage_bind(socket,home); // HOME
//		   	}
/*			for(;;){
			    i=url_getarg_no();
				iprintf("%bd ",i);
			    if(!i) break;
			    pc=url_getarg_str();

			    iprintf("Arg A%u: '%s'\n",i,pc); // Opt. Show Args...

			    if(i==1) strcpy(name,pc); // Copy without regarding max. len...
			    else if(i==2) strcpy(cont,pc);
			    else if(i==3) strcpy(adr,pc);

			    // ignore other Args...
			 }*/

		}
        if(gp_csts()) {
            ch=getchar();
        }
	}
    return 0;
}

void reverse(char *s) {
    int i,j;
    char c;

    for(i=0,j=strlen(s)-1;i<j;i++,j--) {
        c=s[i];
        s[i]=s[j];
        s[j]=c;
    }
}

int itoa(int n, char *s) {
    int i,sign;
    if((sign=n)<0)
        n=-n;
    i=0;
    do {
        s[i++]=n%10+'0';
    }while((n/=10)>0);
    if (sign<0)
        s[i++]='-';
    s[i]='\0';
    reverse(s);
    return i;
}

unsigned char ParseWebSide(char * pTag, char * pReplace, unsigned char sizeOfReplace){
    if(strcmp(pTag,"cnt")==0 && sizeOfReplace>=4) {
    //	 	return siprintf(pReplace,"%u",HitCnt);		// siprintf is not reentrant :-(
        return itoa(++HitCnt,pReplace);
    }
    return 0;
}

inline void putsNoLF(char * pStr) {
    while(*pStr) {
        putchar(*pStr);
        pStr++;
    }
}

// Evaluates the Posted Values of CGIFORMULAR1
// Called via Function Pointer (Callback)
void Form1Parser(char * pName, char * pValue){
    //char *pChar;
    //pChar=pValue;

    if (pName==0 && pValue==0) { 			// Set Defaults.
    //		LED_REG1&=~(LOW7SEG_ON|HIGH7SEG_ON);
    //		LED_REG2=LedReg2Save=0;
        //P5=0;
        return;
    }

    /*if (strcmp(pName,"Kommentar")==0) {
    // Text extrahieren und auf LCD anzeigen
        coord x,y;
        ConvertString(pChar);
        OCH=0;
        x=getx();
        y=gety();
        setviewport(x,y,getmaxx(),y+7);
        clearviewport();
        setviewport(0,0,getmaxx(),getmaxy());
        moveto(x,y);
        putsNoLF(pChar);
        putchar('\r');
        putchar('\n');
        OCH=1;

    }else*/ if(*pName=='C' && *(pName+1)>='0' && *(pName+1)<='7') {
        if(strcmp(pValue,"ON")==0) {

            //P5|=1<<(*(pName+1)-'0');
        }
    }

	/*else	if (strcmpf(pName,"CLOW")==0) {
	 	if(strcmpf(pValue,"ON")==0) {
	 		LED_REG1|=LOW7SEG_ON;
	 	}
	}else	if (strcmpf(pName,"CHIGH")==0) {
	 	if(strcmpf(pValue,"ON")==0) {
	 		LED_REG1|=HIGH7SEG_ON;
	 	}
	}else	if (strcmpf(pName,"SevenSeg")==0) {
		unsigned char value=0;
	 	if(strlen(pValue)==0)
	 		SEG7_REG=0;
	 	else if (sscanf(pValue,"%x",&value)==1){
	 	 	SEG7_REG=value;
	 	}
	}*/
}

/*****************************************************************************
*  		Callback- Functions specific to dynamic html- Files
******************************************************************************/
// Callback- Function
unsigned char InsertDynamicValues(char * pTag, char * pReplace, unsigned char sizeOfReplace)
{
//unsigned char  NewKey[6];
//unsigned int i;
unsigned int dt;

// A sign for a Dynamic Value is "ADX%"
    if (sizeOfReplace<7) return 0;
    if (*pTag == 'A') {
        if (*(pTag + 1) == 'D')
            if (*(pTag + 2)>='0' && *(pTag + 2)<='7')
            {
    //					data=ad_read_polling(*(Key + 2)-'0');
                    dt=Read_ADC(*(pTag + 2)-'0');
                    dt=100*(unsigned long)dt/1024;
    //					dt=1024/2;
    //					dt>>=3;		// DIV 8 because of Resolution of html bar
                    if(dt>100) dt=100;
                    return itoa(dt,pReplace);
    //					siprintf(NewKey, "%3u", data);
    //					memcpy(Key, NewKey, 3);
                }
        }else if(*pTag == 'C' && *(pTag + 2)=='%'){
        if (*(pTag + 1) >= '0' && *(pTag + 1) <= '7') {
            /*if((P5 & (1<<(*(pTag+1)-'0')))){
                strcpy(pReplace,"checked");
                return 7;
            }else{
                *pReplace++=' ';
                *pReplace='\0';
                return 1;
    //		    	  		memcpy(pReplace,"   ",3);
            }*/
        }
    }

    return 0;


}



unsigned char tDispDynamic(char * pTag, char * pReplace, unsigned char sizeOfReplace) {

    if (sizeOfReplace<9) return 0;

    if(strcmp(pTag,"t_wid")==0) {
        unsigned int temp100;

        temp100=100*((unsigned long)Read_ADC(2))/1024;
    //		siprintf(t_wid,"%u",(temp100-1000)/5);
        return itoa(temp100,pReplace);
    }else if(strcmp(pTag,"t_deg")==0) {
        return itoa(Read_ADC(2),pReplace);
    }else if(strcmp(pTag,"ctime")==0) {
        tTime  Time;
        unsigned char cnt;

        if(!readtime(&Time)) {
            cnt=siprintf(pReplace,"%02u:%02u:%02u",Time.std,Time.min,Time.sek);
            return cnt;
        }
    }
    return 0;
}

unsigned char SetID=0;

unsigned char setDynamic(char * pTag, char * pReplace, unsigned char sizeOfReplace) {
    if (sizeOfReplace<5) return 0;

    if(*pTag == 'L' && (*(pTag + 1)=='3'||*(pTag + 1)=='4')){
        /*if((P4 & (1<<(*(pTag+1)-'0')))){
            strcpy(pReplace,"checked");
            return 7;
        }else{
            *pReplace++=' ';
            *pReplace='\0';
            return 1;
        }*/
    }else if(*pTag == 'i' && *(pTag + 1)=='d'){
        return itoa(SetID,pReplace);
    }else if(strcmp(pTag,"ID")==0) {
        return itoa(SetID,pReplace);
    }else if(strcmp(pTag,"hr")==0) {
        tTime  Time;

        if(!readtime(&Time)) {
            return siprintf(pReplace,"%02u",Time.std);
        }
    }else if(strcmp(pTag,"min")==0) {
        tTime  Time;

        if(!readtime(&Time)) {
            return siprintf(pReplace,"%02u",Time.min);
        }
    }else if(strcmp(pTag,"sec")==0) {
        tTime  Time;

        if(!readtime(&Time)) {
            return siprintf(pReplace,"%02u",Time.sek);
        }
    }
    return 0;
}

unsigned char setReply(char * pTag, char * pReplace, unsigned char sizeOfReplace) {
    if(sizeOfReplace>=4) {
        if(*pTag == 'i' && *(pTag + 1)=='d') {
            SetID++;
            return itoa(SetID,pReplace);
        }
    }
    return 0;
}


void ParseReply(char * pName, char * pValue){
    if (pName==0 && pValue==0) {
    //		P4&=~(1<<3|1<<4);
    }else {
        if(*pName == 'A' && *(pName + 1)>='1' && *(pName + 1)<='3'){
            tTime  Time;
            unsigned char val;
            if(readtime(&Time)) return;
            ConvertString((uchar*)pValue);
            val=atoi(pValue);

            if(*(pName + 1)=='1' && val>=0 && val<24) Time.std=val;
            else if(*(pName + 1)=='2' && val>=0 && val<60) Time.min=val;
            else if(*(pName + 1)=='3' && val>=0 && val<60) Time.sek=val;
            //settime(&Time);


        }else if(*pName=='A' && *(pName+1)>='5' && *(pName+1)<='6') {
            // A5==P4.3
            // A6==P4.4
            if(strcmp(pValue,"ON")==0) {

                //P4|=1<<(*(pName+1)-'2');
            }
        }else if(*pName=='A' && *(pName+1)=='4'){
            //P4&=~(1<<3|1<<4);
        }
    }
}

#if 0
char * GetCoord(char * pValue, coord *pX, coord *pY) {
    char  * pDel;

    pDel=strchr(pValue,',');
    if (pDel) {
        *pDel=0;
        *pX=atoi(pValue);
        pValue=pDel+1;
        pDel=strchr(pValue,';');
        if(pDel) {
            *pDel++=0;
        }
        *pY=atoi(pValue);
        return pDel;
    }
    return 0;
}

// Callback Fkt f�r Draw.htm
void ParseDraw(char * pName, char * pValue){
	if (pName && pValue) {
		if(*pName == 'T' && *(pName + 1)=='1'){
			coord x,y;
			coord oldX,oldY;
			oldX=getx();
			oldY=gety();
			ConvertString(pValue);
			pValue=GetCoord(pValue,&x,&y);
			if(pValue){
				moveto(x,y);
			}
			while(pValue) {
				pValue=GetCoord(pValue,&x,&y);
//				if(!pValue) break;
				lineto(x,y);
			}
			moveto(oldX,oldY);


		}else if(*pName == 'R' && *(pName + 1)=='1'){
			if(*pValue=='A')	setlinestyle(SOLID_LINE,NULL);
			else if (*pValue=='S')	setlinestyle(DASHED_LINE,NULL);
			else if (*pValue=='D')	setlinestyle(CENTER_LINE,NULL);
			else if (*pValue=='P')	setlinestyle(DOTTED_LINE,NULL);
		}else if(*pName == 'C' && *(pName + 1)=='L' && *(pName + 2)=='S'){
			cleardevice();
		}

	}

}
#endif

