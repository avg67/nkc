/*-
 * Copyright (C) 1991	Andreas Voggeneder
 */

#include <sys/path.h>
#include <errno.h>

int
close(fd)
int fd;
{
    PATH *pp;
    
    if(fd<0 || fd>=_NPATH || !((pp = &_path[fd])->status & VALID)){ 
        errno = EBADF;
        return -1;
    }
    if(pp->devp->p_close) pp->devp->p_close(pp->devp->devnum); 
    _path[fd].status &= ~VALID;
    return 0;
}
