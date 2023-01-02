/*-
 * Copyright (C) 1991	Andreas Voggeneder
 */

#ifndef FIFO_SIZE
#define FIFO_SIZE 256 /* default fifosize */
#endif

struct fifo {
    volatile int ridx; /* read index */
    volatile int widx; /* write index */
    char buf[FIFO_SIZE];
};

static inline void
putfifo(struct fifo *f, char c)
{
    f->buf[f->widx++] = c;
    if(f->widx == FIFO_SIZE) f->widx = 0;
}

static inline int
getfifo(struct fifo *f)
{
    int c;

    c = f->buf[f->ridx++];
    if(f->ridx == FIFO_SIZE) f->ridx = 0;
    return c;
}

static inline int
isfullfifo(struct fifo *f)
{
    if(((f->widx + 1) == f->ridx) || (((f->widx + 1) == FIFO_SIZE) && (f->ridx == 0)))
        return -1;
    return 0;
}

static inline int
isemptyfifo(struct fifo *f)
{
    if(f->widx == f->ridx) return -1;
    return 0;
}    
