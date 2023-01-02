/*-
 * Copyright (C) 1991	Andreas Voggeneder
 */

#include <sys/stat.h>

int
fstat(int fildes, struct stat *stbuf)
{
    return stat(0, stbuf);
} 

int
stat(const char *name, struct stat *stbuf)
{
        stbuf->st_dev = 0;
        stbuf->st_ino = 0;
        stbuf->st_mode = S_IFCHR; //0777 | 0020000;
        stbuf->st_nlink = 1;
        stbuf->st_uid = 0;
        stbuf->st_gid = 0;
        stbuf->st_rdev = 0;
        stbuf->st_size = 0;
        stbuf->st_atime = 0;
        stbuf->st_mtime = 0;
        stbuf->st_ctime = 0;
        stbuf->st_blksize = 0;
        stbuf->st_blocks = 0;
        return 0;
}

