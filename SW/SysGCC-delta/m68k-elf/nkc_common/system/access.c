/*-
 * Copyright (C) 1991	Andreas Voggeneder
 */

#include <sys/path.h>
#include <sys/file.h>
#include <errno.h>
#include <string.h>

PATH    _path[_NPATH];

int
access(const char *name, int mode)
{
        DEVICE *pd, *tmpdev = (DEVICE *)0;
        char *cp;
                
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
            if((mode == X_OK || mode == R_OK) && pd->flag & NO_REC){
                errno = EACCES;
                return -1;
            }
            else if(mode == W_OK && pd->flag & NO_TRANS){
                errno = EACCES;
                return -1;
            }
        }
        return 0;
}                


