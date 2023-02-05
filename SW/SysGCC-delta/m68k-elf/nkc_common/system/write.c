/*-
 * Copyright (C) 1991	Andreas Voggeneder
 */

#include <sys/path.h>
#include <errno.h>
#include <signal.h>

int write(int fd, const void *bfr, size_t n)
{
    int         j, flg = 0;
    size_t      i;
    char        c;
    PATH        *pp, *passoc;
    DEVICE      *dp;
    const char* buffer = (const char*) bfr;

    if(fd<0 || fd>=_NPATH || !((pp=&_path[fd])->status & VALID) || 
                !(dp = pp->devp)->p_write){
        errno = EBADF;
        return -1;
    }
    passoc = pp->assoc < _NPATH ? _path + pp->assoc : NULL;
    for(i = 0; i < n;){
        if(passoc && !(passoc->flag & RAW)){
retry:
            if((j = (passoc->devp->p_read)(passoc->devp->devnum, &c)) != NO_CHAR){
/* save receive errors ? */
                passoc->status |= j;
/* check for soft handshake */
                if(passoc->flag & ALL_XON) pp->status &= ~BLOCKED; 
                if(passoc->chars.tc_startc == c) pp->status &= ~BLOCKED; 
                else if(passoc->chars.tc_stopc == c) pp->status |= BLOCKED;
                else if(passoc->chars.tc_intrc == c) raise(SIGINT);     
                else if(passoc->chars.tc_quitc == c) raise(SIGTERM);
/* save character if there is enought space */
                else if(passoc->cnt < SIZE_OF_READBUF){
                    passoc->cnt++;
                    if(passoc->wi >= SIZE_OF_READBUF) passoc->wi = 0;
                    passoc->readbuf[passoc->wi++] = c;
                }
            }
            if(pp->status & BLOCKED)
                 goto retry;
        }
        c = buffer[i];
        if(c == LF && !(pp->flag & RAW) && pp->flag & CRMOD) {
            if(!flg){ 
                flg = 1;
                c = CR;
            } else { 
                 flg = 0;
                 c = LF;
                 i++;
            }
        } else i++;    
        while((j = dp->p_write(dp->devnum, c)) == FULL)
            if(pp->flag & NO_BLOCK) {
                errno = EWOULDBLOCK;
                return -1;
            }
    }
    return i;
}
