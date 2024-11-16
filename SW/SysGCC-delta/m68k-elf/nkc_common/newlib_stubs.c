/*
 * newlib_stubs.c
 *
 *  Created on: 2 Nov 2010
 *      Author: Andreas Voggeneder
 */
#include <errno.h>
#include <sys/stat.h>
#include <sys/unistd.h>
#include <ndrcomp/target.h>
#include <ndrcomp/sysclock.h>
#include <sys/ndrclock.h>
#include <sys/m68k.h>
#include <stdint.h>
#include <time.h>
#include <ctype.h>
#include <sys/time.h>
#include <sys/times.h>
//#include <ndrcomp/gruprg.h>
#include <sys/path.h>
#include <sys/file.h>
#include <errno.h>
#include <string.h>
#include <stdbool.h>
#include "nkc/nkc.h"

#define FIFO_SIZE 256
#include "../../nkc_common/fifo.h"

#define BACKSPACE 0x7F

#define INT_FPGA 0x1d /* FPGA Interrupt */
//#define BACKUP_SER_INT

void (*_serexcept_fu)(void) = NULL;
short _serexcept_char = 0;
//static void
//_clock_intr(void);
#define HANDLE_EXCEPT(c) \
    if(_serexcept_fu && (_serexcept_char == (c))){ \
    _serexcept_fu();\
    return;}

/* fifo for receive data */
static struct fifo rfifo;
/* accumulate receive errors */
static int recerroraccu=0;
static int baudsave=19200;
#ifdef BACKUP_SER_INT
  static unsigned long oldservec=0;
#endif
/* receive data interrupt handler */
//static inline void recdata(void);
//static void recerror(void);

void (*_clock_fu)(void) = NULL;
bool _clock_installed = false;
volatile clock_t _clock_value = 0;

int _getcon(char dev_nr, char *cp);
int _getconint(char dev_nr, char *cp);
int _putcon(char dev_nr, char c);
int _ctlcon(char dev_nr, int fcode, void *para);
int _initcon(char dev_nr);
int _opencon(char dev_nr);
int _closecon(char dev_nr);

int _getser(char dev_nr, char *cp);
int _getserint(char dev_nr, char *cp);
int _putser(char dev_nr, char c);
int _ctlser(char dev_nr, int fcode, void *para);
int _initser(char dev_nr);
int _openser(char dev_nr);
int _closeser(char dev_nr);

#if 0
volatile char gp_csts(void)
{
    register long retvalue asm("%d0");
    asm volatile(
    "# asm"             "\n\t" \
    "movem.l %%d7/%%a5-%%a6,-(%%sp)"  "\n\t" \
    "moveq #_CSTS,%%d7" "\n\t" \
    "trap #1"           "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6/%%d7" "\n\t" \
    : "=r"(retvalue) /* outputs */    \
    :                /* inputs */    \
    : "%d7"    /* clobbered regs */ \
    );
    return retvalue;
}

volatile void gp_co(char x)
{

    asm volatile(
    "# asm"                  "\n\t" \
    "moveb %0,%%d0"          "\n\t" \
    "moveq #_CO2,%%d7"       "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #1"                "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    :                /* outputs */    \
    : "g"(x)          /* inputs */    \
    : "%d0", "%d7"    /* clobbered regs */ \
    );

}

volatile char gp_ci(void)
{
    register long retvalue asm("%d0");
    asm volatile(
    "# asm"            "\n\t" \
    "moveq #_CI,%%d7"  "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #1"          "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    : "=r"(retvalue) /* outputs */    \
    :                /* inputs */    \
    : "%d7"    /* clobbered regs */ \
    );
    return retvalue;

}
#endif



DEVICE _device_ary = {"tty0", 0, DTYP_NO, 0, _getcon, _putcon, _ctlcon, _initcon, _opencon, _closecon, 0};
DEVICE _dev1       = {"tty1", 0, DTYP_ASYNC, 0, _getser, _putser, _ctlser, _initser, _openser, _closeser, 0};

void _init_dev(){
    _device_ary.next = &_dev1;
}

int _test_port()    /* Test the Hardware */
{
    //int i;
    return 0;
}

void _init_port()
{
  _init_dev();
  _initcon(0);
  _initser(0);
}


/* Sucess return value is 0, else -1. */
int _ctlcon(dev_nr, fcode, para)
    char dev_nr;
    int fcode;
    void *para;
{

    return OK;
}

int _initcon(dev_nr)
    char dev_nr;
{
    //int i;

/*    i = 0;
    _ctlcon(dev_nr, IOCW_ASYMODE, &i);
    i = 19200;
    _ctlcon(dev_nr, IOCW_BAUDRATE, &i);*/
    return OK;
}

int _getcon(char dev_nr, char* cp)
{

    if(!gp_csts())
        return NO_CHAR;
    else
    {
        char ch = gp_ci();
        if(ch==BACKSPACE) { // convert backspace into CTRL-H
            ch='\b';
        }
        *cp=ch;
        return 0;
    }

}

int _putcon(dev_nr, c)
    char dev_nr;
    char c;
{
    gp_co(c);
    return OK;
}

int _opencon(dev_nr)
    char dev_nr;
{
    return OK;
}

int _closecon(dev_nr)
    char dev_nr;
{
    return OK;
}

#undef errno
extern int errno;

///int __open(const char *filename, int flags, ...)
int _open(const char *filename, int flags)
{
  return open(filename,flags);
}


static inline void _bcdtonum(unsigned char *v)
{
    *v=(*v >>4)*10 + (*v & 0x0f);
}

time_t _gettime(void)
{
    ndrtimebuf ts;

    //memset(&ts,0,sizeof(ts));

    asm volatile(
    "# asm"               "\n\t" \
    "lea %0,%%a0"         "\n\t" \
    "moveml %%d4/%%d7/%%a5-%%a6,%%sp@-" "\n\t" \
    "moveq #_GETUHR,%%d7"   "\n\t" \
    "trap #1"             "\n\t" \
    "moveml %%sp@+,%%d4/%%d7/%%a5-%%a6" "\n\t" \
    : "=g" (ts) /* outputs */    \
    :          /* inputs */    \
    : "%a0"            /* clobbered regs */ \
    );

//    iprintf("%x:%x:%x %x  %x.%x.%x %x\r\n",ts.hour,ts.min,ts.sec,ts.hsec,  ts.day,ts.mon,ts.year,ts.week);
    for(unsigned char* pts=(unsigned char*)&ts;pts<((unsigned char*)&ts)+sizeof(ts);pts++) {
      _bcdtonum(pts);
    }

//    iprintf("%d:%d:%d %d  %d.%d.%d %d\r\n",ts.hour,ts.min,ts.sec,ts.hsec,  ts.day,ts.mon,ts.year,ts.week);
    // Map from NKC to Unix specific struct;
    struct tm tm;
    tm.tm_sec= ts.sec;
    tm.tm_min = ts.min;
    tm.tm_hour = ts.hour;
    tm.tm_mday = ts.day;
    tm.tm_mon = ts.mon-1; // month 0 to 11
    tm.tm_year = ts.year+100; // years since 1900
    tm.tm_wday = ts.week;
    tm.tm_yday = 0;   // day of year (0 to 365) -> hopefully not needed
    tm.tm_isdst = 0;  // Sommer/Winterzeit ?
    return mktime(&tm);
}


/*
time_t _Time (time_t *timer)
{
  //HOST_SERVICE (SVC_TIME);
}*/

time_t time (time_t *tod)
{
  time_t t = _gettime ();

  if (tod)
    *tod = t;

  return (t);
}

/*
 execve
 Transfer control to a new process. Minimal implementation (for a system without processes):
 */
int _execve(char *name, char **argv, char **env) {
    errno = ENOMEM;
    return -1;
}
/*
 fork
 Create a new process. Minimal implementation (for a system without processes):
 */

int _fork() {
    errno = EAGAIN;
    return -1;
}
/*
 fstat
 Status of an open file. For consistency with other minimal implementations in these examples,
 all files are regarded as character special devices.
 The `sys/stat.h' header file required is distributed in the `include' subdirectory for this C library.
 */
/*int fstat(int file, struct stat *st) {
    st->st_mode = S_IFCHR;
    return 0;
}*/

/*
 getpid
 Process-ID; this is sometimes used to generate strings unlikely to conflict with other processes. Minimal implementation, for a system without processes:
 */

int getpid() {
    return 1;
}

/*
 isatty
 Query whether output stream is a terminal. For consistency with the other minimal implementations,
 */
/*int isatty(int file) {
    switch (file){
    case STDOUT_FILENO:
    case STDERR_FILENO:
    case STDIN_FILENO:
        return 1;
    default:
        //errno = ENOTTY;
        errno = EBADF;
        return 0;
    }
}*/

/*
 kill
 Send a signal. Minimal implementation:
 */
int kill(int pid, int sig) {
    errno = EINVAL;
    return (-1);
}

/*
 link
 Establish a new name for an existing file. Minimal implementation:
 */

int _link(char *old, char *new) {
    errno = EMLINK;
    return -1;
}

/*
 lseek
 Set position in a file. Minimal implementation:
 */
//int lseek(int file, int ptr, int dir) {
/*off_t lseek (int __fildes, off_t __offset, int __whence ) {
    return 0;
}*/

/*
 sbrk
 Increase program data space.
 Malloc and related functions depend on this
 */
/*caddr_t _sbrk(int incr) {

    extern char _ebss; // Defined by the linker
    static char *heap_end;
    char *prev_heap_end;

    if (heap_end == 0) {
        heap_end = &_ebss;
    }
    prev_heap_end = heap_end;

char * stack = (char*) __get_MSP();
     if (heap_end + incr >  stack)
     {
         _write (STDERR_FILENO, "Heap and stack collision\n", 25);
         errno = ENOMEM;
         return  (caddr_t) -1;
         //abort ();
     }

    heap_end += incr;
    return (caddr_t) prev_heap_end;

}*/

extern caddr_t _end;
extern caddr_t ram_top;
//#ifndef RAMSIZE
//#define RAMSIZE             (caddr_t)0x100000
//#endif

static caddr_t heap_ptr = NULL;

void * sbrk (ptrdiff_t nbytes)
//caddr_t sbrk(nbytes)
//     int nbytes;
{
  void *        base;

  if (heap_ptr == NULL) {
    heap_ptr = (void *)&_end;
  }
  //iprintf("sbrk %d at 0x%X\r\n",nbytes, heap_ptr);

  //if ((RAMSIZE - heap_ptr) >= 0) {
  if ((heap_ptr + nbytes) <= ram_top) {
    base = heap_ptr;
    heap_ptr += nbytes;
    return (base);
  } else {
//    errno = ENOMEM;
    return ((void *)-1);
  }
}

void * get_heap_ptr(void) {
    if(heap_ptr!=NULL) {
        return heap_ptr;
    }else{
        return (void *)&_end;
    }
}

/*
 times
 Timing information for current process. Minimal implementation:
 */

clock_t _times(struct tms *buf) {
    return _clock_value;
}


/*
 unlink
 Remove a file's directory entry. Minimal implementation:
 */
int _unlink(char *name) {
    errno = ENOENT;
    return -1;
}

/*
 wait
 Wait for a child process. Minimal implementation:
 */
int _wait(int *status) {
    errno = ECHILD;
    return -1;
}


// Common Interrupt-Handler for Timer & Ser
__attribute__((__interrupt_handler__)) static void intr_handler(void)
{
    if (FPGAT1.ctrl & 0x40)
    {
      FPGAT1.ctrl = 0x81;
      _clock_value++;
      if(_clock_fu){
          _clock_fu();
      }
    }
    uint8_t i;
    if (((i=SC.status) & 0x88)==0x88){
      //recdata();
      char c = SC.data;
      HANDLE_EXCEPT(c);
      if(!isfullfifo(&rfifo)) putfifo(&rfifo, c);
      if (i & 0x07)
      {
          if(i & 0x02) recerroraccu  |= FRAME_ERR;
          if(i & 0x01) recerroraccu  |= PARITY_ERR;
          if(i & 0x04) recerroraccu  |= OVERF_ERR;
      }
    }
}

//#pragma endinterrupt


/* baudrate value conversion */
static const struct baud_convert {
    long ioctl_baud; /* value given by ioctl */
    unsigned char baud_reg; /* baudrate-register */
    } baud_tab[] = {
       {115200, 0x3},
       {57600, 0x4},
       {38400, 0x5},
       {19200, 0xf},
       {9600,  0xe},
       {4800,  0xc},
       {2400,  0xa},
       {1200, 0x8},
       {600,  0x7},
       {300,  0x6},
       {0, 0},
    };



/* Sucess return value is 0, else -1. */
int _ctlser(dev_nr, fcode, para)
    char dev_nr;
    int fcode;
    void *para;
{
    int wrflag;
    unsigned char c = 0,d = 0;
    DEVICE *tmp_device_pointer;
    //puts("ctlser");

//   if(0) rec_handle();
    wrflag = fcode & IOC_WR ? 1 : 0;
    fcode &= ~IOC_WR;
    switch(fcode){
//      case _IOC_ASYMODE :
      case IOCR_ASYMODE :
        if(!wrflag){
            int i = 0;
            c = SC.control;
            d = SC.command;
            if(c & 0x20) {i |= BITS7;}
            if(d & 0x20){
                if(d & 0x40) {i |= EVENP;}
                else {i |= ODDP;}
            }
            if(c & 0x80) {i |= LONGSTOP;}
            if(!(d & 0x02)) {i |= REC_INTERRUPT;}
            *(int *)(para) = i;
            return OK;
        } else {

            int i = *(int *)para;
            if (i & ASY_CMDMASK){
                if(i & CLR_ERR) {
                    recerroraccu = 0;
                }
                return OK;
            }
            //i = *(int *)para;
            tmp_device_pointer = (DEVICE *)&_device_ary;
            if(i & REC_INTERRUPT){
            /* Routine fuer Interrupt einhaengen */
                while(tmp_device_pointer->p_cntl != _ctlser){
                    tmp_device_pointer = tmp_device_pointer->next;
                }
                tmp_device_pointer->p_read = _getserint;
                DISABLE_CPU_INTERRUPTS;
#ifdef BACKUP_SER_INT
                if (!oldservec){
                  oldservec=(unsigned long)EXCEPT_VEC(INT_FPGA);
                }
#endif
                EXCEPT_VEC(INT_FPGA) = intr_handler; //recdata;  //rec_handle;
                EXCEPT_VEC(0x1f) = intr_handler; //recdata; //rec_handle;
//              EXCEPT_VEC(VEC_RX_ERR) = recerror;
                d=0x09;
//              SC.command &=0xf1;
                ENABLE_CPU_INTERRUPTS;
            } else {
            /* Routine fuer Polling einhaengen */
                d=0x0b;
//              SC.command = (SC.command | 0x2) & 0xf3;
#ifdef BACKUP_SER_INT
                if (oldservec)
                {
                    EXCEPT_VEC(INT_FPGA) = oldservec;
                    oldservec=0;
                }
#endif
                while(tmp_device_pointer->p_cntl != _ctlser) {
                    tmp_device_pointer = tmp_device_pointer->next;
                }
                tmp_device_pointer->p_read = _getser;
            }
            c=(SC.control & 0x1f) ? (SC.control & 0x1f)|0x10 : 0x1f; // Baudrate default 19200,n,8,1
            if(i & BITS7) {c |= 0x20;}
//          else c = 0x1f;
            if(i & EVENP) {d |= 0x60;}
//          else d=8;
            if(i & ODDP) {d |= 0x20;}
            if(i & LONGSTOP) {c |= 0x80;}
            SC.control = c; /* set serial modes */
            if(SC.status & 0x80) {c=SC.data;}
            SC.command = d;
        }
        break;
      case IOCR_BAUDRATE :
        if(!wrflag){
            *(long *)(para) = baudsave;
            //puts("wrflag!");
        } else {
            d=SC.status;
            d=SC.data;
            int i;
            //iprintf("para %d ", *(long *)(para));
            for(i = sizeof(baud_tab)/sizeof(baud_tab[0]); i;){
                if(*(long *)(para) == (baud_tab[--i]).ioctl_baud) goto match;
            }
            return FAIL;
            match:
            //iprintf("match\r\n");
            baudsave = *(long *)(para);
            SC.control= (SC.control & 0xf0) | (baud_tab[i].baud_reg & 0x0f);
        }
        break;
      case IOCR_INSTAT :
        if(wrflag) return FAIL;
        int i = 0;
        if (!(c = SC.status & 0x08)) i |= NO_CHAR;
        if(c & 0x04) i |= OVERF_ERR;
        if(c & 0x1) i |= PARITY_ERR;
        if(c & 0x2) i |= FRAME_ERR;
        *(int *)para = i;
        break;
      case IOCR_OUTSTAT :
        if(wrflag) return FAIL;
        if (!(SC.status & 0x10)) *(int *)para = FULL;
        else *(int *)para = 0;
        break;
      case _IOC_CSWITCH_FU :
        if(wrflag) _serexcept_fu = *(void (**)(void))para;
        else *(void (**)(void))para = _serexcept_fu;
        break;
      case _IOC_CSWITCH_CHAR :
        if(wrflag) _serexcept_char = *(int *)para;
        else *(int *)para = _serexcept_char;
        break;
      case IOCR_SWITCH_PORT:
        if(wrflag){
            int i = *(int *)para;
            if(i & CLR_DTR) SC.command |= 0x1;
            if(i & SET_DTR) SC.command &= ~0x1;
            return OK;
        }
        default: return FAIL;
    }

    return OK;
}

int _initser(dev_nr)
    char dev_nr;
{
    int i;

//    asm("movel #0x56785678,d0");
    i = 0;
    _ctlser(dev_nr, IOCW_ASYMODE, &i);
    i = 19200;
    _ctlser(dev_nr, IOCW_BAUDRATE, &i);
    return OK;
}

int _getser(dev_nr, cp)
    char dev_nr;
    char *cp;       // Pointer to return Char
{
     int i, ret = 0;

    if(!isemptyfifo(&rfifo)){
        *cp = getfifo(&rfifo);
        return recerroraccu;
    }
    if (!((i = SC.status) & 0x08))
        return NO_CHAR;
    *cp = SC.data;
    if(i & 0x07){
        if(i & 0x04) ret |= OVERF_ERR;
        if(i & 0x01) ret |= PARITY_ERR;
        if(i & 0x02) ret |= FRAME_ERR;
//        if(i & 8)    ret |= BREAK_DET;
    }
    return ret;
}

int _putser(dev_nr, c)
    char dev_nr;
    char c;
{
//  asm("movel #0x12341234,d0");
    //iprintf("put ser <%c>\r\n",c);
    if (!(SC.status & 0x10)) return FULL;
    SC.data = c;
    return OK;
}

int _openser(dev_nr)
    char dev_nr;
{
    //puts("open ser");
    return OK;
}

int _closeser(dev_nr)
    char dev_nr;
{
    SC.command = (SC.command | 0x2) & 0xf3;
#ifdef BACKUP_SER_INT
    if (oldservec)
    {
        EXCEPT_VEC(INT_FPGA) = (int)oldservec;
        oldservec=0;
    }
#endif
    return OK;
}

int _getserint(dev_nr, cp)
    char dev_nr;
    char *cp;
{
    if(isemptyfifo(&rfifo)){
        return NO_CHAR;
    }
    *cp = getfifo(&rfifo);
    return recerroraccu;
}

#define VIA_TIMER_VALUE (1E6/CLOCKS_PER_SEC) //5000    /* 5ms Timer */

//__attribute__((__interrupt_handler__)) static void
/*static inline void
_clock_intr(void)
{
    if (FPGAT1.ctrl & 0x40)
    {
      FPGAT1.ctrl = 0x81;
      _clock_value++;
      if(_clock_fu)
          _clock_fu();
    }
}*/


clock_t _clock(void (*clock_fu)(void))
{
    if(clock_fu) _clock_fu = clock_fu;
    if(!_clock_installed){
        _clock_installed = true;
        DISABLE_CPU_INTERRUPTS;
   //     oldvec=(unsigned long)EXCEPT_VEC(INT_TIMER);

      //for (i=25;i<32;i++)
      //  EXCEPT_VEC(i) = intr_handler;
        EXCEPT_VEC(INT_FPGA) = intr_handler;
        EXCEPT_VEC(0x1f) = intr_handler;

//  #ifdef VIA_TEST
//    VIA.ddrb=0xff;
//    VIA.ddra=0xff;
//    VIA.pa=0;
//    VIA.pb=0;
//  #endif
//        VIA.acr &=0xdf;
//        VIA.ier=0xa0;
//        VIA.t2l=(VIA_TIMER_VALUE & 0xff);
//        VIA.t2h=(VIA_TIMER_VALUE >> 8);
        const uint32_t timer_val = VIA_TIMER_VALUE;
        FPGAT1.ctrl = 0x04;
        FPGAT1.th=(timer_val >> 8);
        FPGAT1.tl=(timer_val & 0xff);
        FPGAT1.ctrl = 0x81;
        ENABLE_CPU_INTERRUPTS;
    }
    return _clock_value;

}