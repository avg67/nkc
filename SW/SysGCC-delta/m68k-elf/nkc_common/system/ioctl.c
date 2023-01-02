/*-
 * Copyright (C) 1991	Andreas Voggeneder
 */

#include <string.h>
#include <sys/path.h>
#include <errno.h>

int
ioctl(fd, code, buf)
    int fd;
    int code;
    void *buf;
{
    PATH        *pp;
    int         wf;
    struct ttychars *cp;

    if(fd < 0 || fd>=_NPATH || !((pp = _path + fd)->status & VALID)){ 
        errno = EBADF;
        return -1;
    }
    if(code & IOC_DEV){ 
        DEVICE  *dp = pp->devp;
        if((dp->p_cntl)(dp->devnum, code, buf) == FAIL){
            errno = EINVAL;
            return -1;
        } else {
            return 0;
        }
    }
    wf = code & IOC_WR ? 1 : 0;
    switch(code & ~IOC_WR){
        case IOC_CLRERR : pp->status &= ~ERR_BITS;      
                        break;  
        case _IOC_MODE :   if(wf) pp->mode = *(int *)buf;
                        else *(int *)buf = pp->mode; 
                        break;
        case _IOC_FLAG :   if(wf) pp->flag = *(int *)buf;
                        else *(int *)buf = pp->flag; 
                        break;
        case _IOC_STATUS : if(wf) pp->status = *(int *)buf;
                        else *(int *)buf = pp->status; 
                        break;
        case _IOC_ASSOC :  if(wf) pp->assoc = *(int *)buf;
                        else *(int *)buf = pp->assoc; 
                        break;
        case _IOC_CHARS :  cp = (struct ttychars *)buf;
                        if(wf) memcpy(&pp->chars, cp, sizeof(struct ttychars));
                        else memcpy(cp, &pp->chars, sizeof(struct ttychars));
                        break;
        default :       errno = EINVAL;
                        return -1;               
    }
/*
*/
    return 0;
}
