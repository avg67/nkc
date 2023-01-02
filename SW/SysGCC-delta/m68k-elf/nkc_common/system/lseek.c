/*-
 * Copyright (C) 1991	Andreas Voggeneder
 */

/*
 * actually there are only ttys on target machines (no filesystem) - not much to do
 */

long
lseek(int filedes, long position, int place)
{       
    return 0;
}
