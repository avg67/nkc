/* $Workfile:   Webfiles.h $								 										*/
/* $Revision: 1.1 $                                            	*/
/* $Author: hse00045 $                           								*/
/* $Date: 2003/09/02 19:31:38 $																	*/
/* Description:	Rom- Filesystem for Webserver	                 	*/
/*																											        */
/* Remarks:     No remarks.                                     */

#ifndef _WEBFILES_H
#define _WEBFILES_H

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "webside.h"
#include "html\hsse.h"		// Include here all Files (.html, .gif, .jpg, ...) for Webserver
#include "html\io.h"
#include "html\fh.h"
#include "html\t_disp.h"
#include "html\set.h"
#include "html\reply.h"
#include "html\draw.h"
#include "dynhtml.h"


#define CGIFORMULAR1  "FormIO"		// Name of Posted Formular (must be identical to html Code)

// Standard type Strings required for dynamic File- Header
static char const jpgType[]="image/jpeg";    // MIME Type String for jpeg- Images (.jpg)
static char const gifType[]="image/gif";	 // MIME Type String for gif- Images
static char const bmpType[]="image/x-ms-bmp";// MIME Type String for Windows BMP
static char const htmlType[]="text/html";    // Type String for html Files

//?PR?_GENDYN_HTML?WEB_SERV ! (?PR?_PARSEWEBSIDE?MAIN,?PR?_INSERTDYNAMICVALUES?MAIN,?PR?_TDISPDYNAMIC?MAIN,?PR?_SETDYNAMIC?MAIN,?PR?_SETREPLY?MAIN),
//?PR?_PARSEDATA?WEB_SERV ! (?PR?_FORM1PARSER?MAIN,?PR?_PARSEREPLY?MAIN)


//Calling Tree  for Formular-Parser Fkt:
//
//?PR?PARSEDATA?WEB_SERV
//  |
//   -> ?PR?_?FORM1PARSER?MAIN

// Forward declarations of Formulars
void Form1Parser(char*,char*);
void ParseReply(char*,char*);
void ParseDraw(char*,char*);

// Forward declarations of dynamic HTML-Fkt.
unsigned char InsertDynamicValues(char * pTag, char * pReplace, unsigned char sizeOfReplace);
unsigned char ParseWebSide(char * pTag, char * pReplace, unsigned char sizeOfReplace);
unsigned char tDispDynamic(char * pTag, char * pReplace, unsigned char sizeOfReplace);
unsigned char setDynamic(char * pTag, char * pReplace, unsigned char sizeOfReplace);
unsigned char setReply(char * pTag, char * pReplace, unsigned char sizeOfReplace);


// Directory of ROM- FS
// Each File stored on the Webserver must be added to this List.
static tFile const webFiles[]={{WebSide,NameOfWebSide,htmlType,sizeof(WebSide),0,ParseWebSide},
                        {io_htm,NameOfio_htm,htmlType,sizeof(io_htm),"Change IO",InsertDynamicValues},
    //					  {io_htm,NameOfio_htm,htmlType,sizeof(io_htm),0,InsertDynamicValues},
                        {hsse_jpg,NameOfhsse_jpg,jpgType,sizeof(hsse_jpg),0,0},
                        {fh_gif,NameOffh_gif,gifType,sizeof(fh_gif),0,0},
                        {t_disp_htm,NameOft_disp_htm,htmlType,sizeof(t_disp_htm),0,tDispDynamic},
                        {set_htm,NameOfset_htm,htmlType,sizeof(set_htm),"Change IO",setDynamic},
                        {reply_htm,NameOfreply_htm,htmlType,sizeof(reply_htm),0,setReply},
                        {0,"sc.bmp",bmpType,128*64/8+54+8,0,0}
                        /*{draw_htm,NameOfdraw_htm,htmlType,sizeof(draw_htm),0,0}*/
                  };


// Posted Formulares
static char const CGIForm1[]=CGIFORMULAR1;

typedef struct{
	char const* pName;
	char const* pFile;
	void (*f)(char *,char *);		// Parser for Posted Data
}tForm;


static tForm const Forms[]={{CGIForm1,NameOfio_htm,Form1Parser},
					{NameOfreply_htm,0,ParseReply}
//					{NameOfdraw_htm,0,ParseDraw}
				   };



#endif