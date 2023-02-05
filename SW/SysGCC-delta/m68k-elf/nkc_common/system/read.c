/*-
 * Copyright (C) 1991	Andreas Voggeneder
 */

#include <sys/path.h>
#include <errno.h>
#include <ctype.h>
#include <signal.h>
#include "nkc/nkc.h"

static void outdelchar();
//int write(int fd, char *buffer, size_t n);

int read(int fd, void *bfr, size_t n)
{
    int         j = 0, lineend = 0;
    size_t      i;
    char        c;
    PATH        *pp, *passoc;
    DEVICE      *dp;
    char * buffer = (char *)bfr;

    if(fd<0 || fd>=_NPATH || !((pp=&_path[fd])->status & VALID) || 
                !(dp = pp->devp)->p_read){
        errno = EBADF;
        return -1;
    }
    passoc = pp->assoc < _NPATH ? _path + pp->assoc : NULL;
    for(i = 0; i < n && !lineend;){
        /* first read buffer */
        if(pp->cnt){
            pp->cnt--;
            if(pp->ri >= SIZE_OF_READBUF) pp->ri = 0;
            c = pp->readbuf[pp->ri++];
        } else {
            while((j = dp->p_read(dp->devnum, &c) ) == NO_CHAR){
/* process nonblocking */
                if(pp->flag & NO_BLOCK) {
                    if(i) return i;
                    errno = EWOULDBLOCK;
                    return -1;
                }
            }
/* register receive errors */
            pp->status |= j;
        }       
/* do line processing */
        if(c == CR && pp->flag & CRMOD) c = LF;
        if(!(pp->flag & RAW)) {
            if(passoc && passoc->flag & ALL_XON) 
                passoc->status &= ~BLOCKED;  
            if(c == LF){ 
                lineend = 1;
            }
            if(c == pp->chars.tc_intrc) raise(SIGINT);  
            else if(c == pp->chars.tc_quitc) raise(SIGTERM);
            else if(c == pp->chars.tc_stopc){
                if(passoc != NULL)
                    passoc->status |= BLOCKED;
                continue;
            }           
            else if(c == pp->chars.tc_startc){  
                if(passoc != NULL) 
                    passoc->status &= ~BLOCKED;
                continue;
            }

        /* line edit functions */               
            if(!(pp->flag & CBREAK)) { 
                if(c == pp->chars.tc_erasec) {
                    if(i){ 
                        i--;
                        outdelchar(pp);
                    }
                    continue;
                }
                if(c == pp->chars.tc_killc) {
                    while(i){ 
                        i--;
                        outdelchar(pp);
                    }
                    continue;
                }
            }
        } 
        /* fill buffer */
        buffer[i++] = c;
        /* echo character */
        if((pp->flag & ECHO) && (passoc!=NULL) && isascii(c) && isprint(c)) {
            write(pp->assoc, &c, 1);
        }
    }
    return i;
}
        
static void         
outdelchar(pp)
    PATH *pp;
{
    if(pp->flag & ECHO && pp->assoc < _NPATH) 
        write(pp->assoc, "\b \b", 3);
}          

