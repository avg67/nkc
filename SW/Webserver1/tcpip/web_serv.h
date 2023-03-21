/* $Author: hse00045 $                           				*/
/* $Date: 2003/14/02 19:31:38 $									*/
/* Description:	Webserver main file			                    */
/*																*/
/* Remarks:     No remarks.                                     */
/*    															*/
#ifndef WEB_SERV_H
#define WEB_SERV_H

#include "dynhtml.h"
// Structure for monitoring port80 sockets
typedef struct{
    uchar html_state:4;	// 0: Nothing/Waiting for GET, 1,2: Wait 3: HTTP, 4: Pending
    uchar cmd:2;
    uchar headsent:1;
    uchar authentificated:1;
//	uchar dyna_flag;	// If set: Dynamic HTML (requires Server-Close)
    uint16_t weblen;
    uchar const * pweb;	// Points to current Page data
    tFile const * pfile;
//	uint16_t weblen;		// Size of page
} HTTP_INFO;

extern HTTP_INFO http_info[MAX_SOCK];
//extern uchar *web_args; // points tp start of first argument


// Webserver Functions
uint16_t gendyn_html(HTTP_INFO *pinfo, char *pbuf, uint16_t bufsize);
uint16_t poll_webserver(void);
//uchar * webpage_name(void);
char* ExtractFileName(char *pBuf, char *pNameBuf);
bool CheckAuthorization(char  *pBuf, tFile const * const pFile);
uchar url_getarg_no(void);
uchar *url_getarg_str(void);
void webpage_bind(uchar sock, tFile const * const pd);
tFile const* FindFile(char *pFileName);
void ParseData(char *pPostedData,char * pFormName);
void ConvertString(uchar *pBuf);
void Init_Webserver(void);

#endif
