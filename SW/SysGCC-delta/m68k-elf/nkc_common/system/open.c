/*-
 * Copyright (C) 1991	Andreas Voggeneder
 */

#include <string.h>
#include <sys/path.h>
#include <sys/file.h>
#include <errno.h>

PATH    _path[_NPATH];

/*
 * globals for search environment
 */

char *_stdin_envname = "stdin";
char *_stdout_envname = "stdout";
char *_stderr_envname = "stderr";

int
open(const char *name, int flags, ...)          /* mode is never used */
{
        int i, fd, mod=0u;
        PATH    *pp, *passoc;
        DEVICE *pd, *tmpdev = (DEVICE *)0;
        //char *cp;
                
        if( !strncmp(name, "/dev/", 5) )  name += 5;
        pd = (DEVICE *)&_device_ary;
        while(pd){
            if(!strcmp(name, pd->name)) {
                tmpdev = pd;
            }   
            pd=pd->next;
        }
        pd = tmpdev;
        if(!pd) {
            errno =  ENOENT;
            return -1;  
        } else {
/* found empty path-descriptor */
            for(fd = 0; (_path[fd]).status & VALID; fd++)
                if(fd == _NPATH - 1){
                    errno = ENOENT;
                    return -1;
                } 
            pp = _path + fd;
            pp->devp = pd;
            if(pd->p_open(pd->devnum) == FAIL){
                errno = ENOENT;
                return -1;
            }
            pp->status = VALID;
            pp->mode = flags;
            pp->flag = CRMOD | ECHO; /* if found in _device_ary, map '\r' */
            pp->assoc = _NPATH; /* mark associated fd as unvalid */
            pp->chars.tc_intrc =  CINTR;
            pp->chars.tc_quitc =  CQUIT;            
            pp->chars.tc_startc =  CSTART;          
            pp->chars.tc_stopc =  CSTOP;            
            pp->chars.tc_erasec =  CERASE;          
            pp->chars.tc_killc =  CKILL;            
            pp->ri = pp->wi = pp->cnt = 0;
/* found associated fd */
            if((flags & 3) == O_RDONLY) mod = O_WRONLY;
            else if((flags & 3) == O_WRONLY) mod = O_RDONLY;
            else if((flags & 3) == O_RDWR) mod = O_RDWR;
            for(i = 0, passoc = _path; i < _NPATH; i++, passoc++){
                if(passoc->status & VALID && passoc->assoc == _NPATH &&  
                  !strcmp(name, passoc->devp->name) && (passoc->mode & 3) == mod){ 
                    passoc->assoc = fd;
                    pp->assoc = i;
                }
            }
            return fd;  
        }  
}

