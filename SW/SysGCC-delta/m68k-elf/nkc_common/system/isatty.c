/*-
 * Copyright (C) 1991	Andreas Voggeneder
 */

#include <sys/path.h>

isatty(fd)
    int fd;
{    
    if(fd<0 || fd>=_NPATH || !((_path[fd]).status & VALID) ||
            (!((_path[fd]).devp->devtype == DTYP_ASYNC) &&
             !((_path[fd]).devp->devtype == DTYP_LCD))){
        return 0;
    } else return 1;
}
