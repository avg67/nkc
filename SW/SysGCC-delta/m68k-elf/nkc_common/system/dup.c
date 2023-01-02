/*-
 * Copyright (C) 1991	Andreas Voggeneder
 */

#include <string.h>
#include <sys/path.h>
#include <sys/file.h>
#include <errno.h>

PATH    _path[_NPATH];


int
dup(int oldd)
{
    int i;
        
    if(oldd < 0 || oldd >= _NPATH){
        errno = EBADF;
        return -1;
    }
/* found empty path-descriptor */
    for(i = 0; (_path[i]).status & VALID; i++)
        if(i == _NPATH - 1){
            errno = EMFILE;
            return -1;
        } 
    memcpy(_path + i, _path + oldd, sizeof(PATH));
    return i;
}


