/*- structures and definitions for low level I/O 
 *
 * Copyright (C) 1991	Andreas Voggeneder
 *
 */

/*-Date		Version	Action						Who
 * 01.04.1991	1.00	created						avg
 * 16.01.1992   1.10    modify DEVICE structure, direct baudrate        avg
 */

#ifndef _TYPES_H
#include <sys/types.h>
#endif

#ifndef _PATH_H
#define _PATH_H

#define NULL 	((void *)0)
#define	CR	0x0d
#define	LF	0x0a

/* default special characters */
/* #define CTRL(c) ('c'&037) dosen't work with GNU-CPP */ 

#define CINTR   ('C' - '@')
#define CQUIT   034             /* FS, ^\ */
#define CSTART  ('Q' - '@')
#define CSTOP   ('S' - '@')
#define CERASE 	'\b'
#define CKILL 	('U' - '@')

/*
 * internal path structures. the idea resembles fdc from un*x.
 */

#define	_NPATH		8		/* # of available file descs */
#define SIZE_OF_READBUF 256

struct ttychars { 
        char    tc_intrc;       /* interrupt */
        char    tc_quitc;       /* quit */
        char    tc_startc;      /* start output */
        char    tc_stopc;       /* stop output */
        char	tc_erasec;	/* erase last character */
        char	tc_killc;	/* kill until beginning of line */ 
   } ;
     
typedef struct _device {
	char *name; /* name for open system call */
	char devnum; /* device number for following io systemcalls */
	char devtype; /* Type of device */
        short	flag; /* not used now */
	int	(*p_read)(char dev_nr, char *cp);		/* read function */
	int	(*p_write)(char dev_nr, char cp);		/* write function */
	int	(*p_cntl)(char dev_nr, int fcode, void *para);	/* ioctl function */
	int	(*p_init)(char dev_nr);				/* initialisation function */
        int     (*p_open)(char dev_nr);			        /* open function */
	int 	(*p_close)(char dev_nr);			/* close function */
	struct _device *next;					/* Pointer to the next device */
    } DEVICE;

typedef struct {
	u_char	mode;		/* open mode */
	u_char	assoc;	        /* associated echo/abort path */
	u_short flag;		/* echo, raw, ... */
	u_short	status;		/* blocked, error, ... */
	struct 	ttychars chars; 
	DEVICE 	*devp;
	char 	readbuf[SIZE_OF_READBUF];	
	int	ri, 	/* readbuffer readindex */
		wi,	/* 	"     writeindex */
		cnt;	/* 	"     count */ 
    } PATH;

extern PATH	_path[_NPATH];
extern DEVICE	_device_ary;

/* PATH->flag definitions */
#define RAW 	1
#define ECHO 	2
#define CBREAK	4
#define CRMOD	8 /* Map CR to LF, output LF as CR-LF */
#define NO_BLOCK 0x10 	/* Don't block if there are no chars availible. */

#define ALL_XON 0x40    /* every character works as XON */

/* PATH->status definitions */
#define BLOCKED 1	/* waiting on tc_startc */
#define CTL_DIRTY 2 	/* control flags are dirty */
#define VALID 0x4	/* valid path */
#define ERR_BITS 0x138	/* all error bits in PATH->status */
#define PARITY_ERR 8	/* parity error special serial errorflag */ 
#define OVERF_ERR 0x10	/* overflow error */
#define FRAME_ERR 0x20	/* frame error */
#define FULL 0x40	/* buffer full only for write access */
#define NO_CHAR 0x80	/* only for read access */
#define BREAK_DET 0x100 /* break character detected */


/*
 * Definitions for DEVICE->devtype.
 */
#define DTYP_NO     0 /* type of device not specified */
#define DTYP_ASYNC  1 /* device is a asyncronious seriell port */
#define DTYP_LCD    2 /* device is a lcd port */
#define DTYP_DISK   3 /* device is a File System */

/* return values for device functions */
/* see also fd->status for error flags */
#define OK 0
#define FAIL -1

/* definitions for ioctl */
#define IOC_WR		0x4000  /* or'ed with ioctl code, to write */
#define IOC_DEV	        0x2000	/* this ioctl needs a DEVICE->p_cntl() call */

#define _IOC_MODE	1       /* read/write open mode */
#define IOCW_MODE (_IOC_MODE | IOC_WR)        
#define IOCR_MODE (_IOC_MODE)        

#define _IOC_FLAG	2       /* read/write PATH->flag settings */  
#define IOCW_FLAG (_IOC_FLAG | IOC_WR)
#define IOCR_FLAG (_IOC_FLAG)

#define _IOC_STATUS	3       /* read/write PATH->status */
#define IOCW_STATUS (_IOC_STATUS | IOC_WR)
#define IOCR_STATUS (_IOC_STATUS)

#define _IOC_ASSOC	4       /* read/write PATH->assoc */
#define IOCW_ASSOC (_IOC_ASSOC | IOC_WR)
#define IOCR_ASSOC (_IOC_ASSOC)

#define _IOC_CHARS	5       /* read/write PATH->chars */
#define IOCW_CHARS (_IOC_CHARS | IOC_WR)
#define IOCR_CHARS (_IOC_CHARS)

#define IOC_CLRERR      6       /* clear errors in PATH->status */

/*
 * ioctl functions for DEV_ASYNC ports
 */
#define _IOC_ASYMODE  (1 | IOC_DEV) /* read/write serial port modes */
#define IOCW_ASYMODE (_IOC_ASYMODE | IOC_WR)
#define IOCR_ASYMODE (_IOC_ASYMODE)
/* 
 * Definitions for ioctl with _IOC_ASYMODE
 */
#define BITS7 1 	/* 7 bit chars instead of 8 bit chars */
#define EVENP 2 	/* use even parity */
#define ODDP 4 		/* use odd parity */
#define LONGSTOP 8 	/* use 1.5 or 2 (hardware dependent) Stopbits instead of one */
#define NO_REC 0x10 	/* no/disable receiver */
#define NO_TRANS 0x20	/* no/disable transmitter */ 
#define CLR_RTS 0x40	/* negate RTS */
#define CLR_ERR 0x80	/* clear error flags */
#define CLR_REC 0x100   /* clear/reset receiver */
#define CLR_TRANS 0x200 /* clear/reset transmitter */
#define CTL_CTS 0x400   /* transmitter controlled by CTS */
#define CTL_RTS 0x800   /* control RTS line */
#define SET_RTS 0x1000	/* assert RTS */
#define REC_INTERRUPT 0x2000 /* enable receive interrupt */
/* this commands are exclusiv, you can't call and set other modes */
#define ASY_CMDMASK (CLR_RTS | SET_RTS | CLR_ERR | CLR_REC | CLR_TRANS)

#define _IOC_BAUDRATE (2 | IOC_DEV) /* read/write serial port baudrate */
#define IOCW_BAUDRATE (_IOC_BAUDRATE | IOC_WR)
#define IOCR_BAUDRATE (_IOC_BAUDRATE)
/* 
 * Definitions for ioctl with _IOC_BAUDRATE
 */
#define EXTERN1 -1 	/* target specific extern baudrate */
#define EXTERN2 -2 	/* target specific extern baudrate */

#define _IOC_INSTAT     (3 | IOC_DEV) /* input port status, read only */
#define IOCR_INSTAT     (_IOC_INSTAT)
/*
 * Definitions for ioctl with _IOC_INSTAT  are the same as for PATH->status.
 */
#if 0
#define PARITY_ERR 8	/* parity error special serial errorflag */ 
#define OVERF_ERR 0x10	/* overflow error */
#define FRAME_ERR 0x20	/* frame error */
#define NO_CHAR 0x80	/* only for read access */
#endif

#define _IOC_OUTSTAT    (4 | IOC_DEV) /* output port status, read only */
#define IOCR_OUTSTAT    (_IOC_OUTSTAT)
/*
 * Definitions for ioctl with _IOC_OUTSTAT are the same as for PATH->status.
 */
#if 0
#define FULL 0x40	/* buffer full only for write access */
#endif

/*
 * Function and character for context switch in serial interrupt.
 * Created for debugger support.
 */
#define _IOC_CSWITCH_FU (5 | IOC_DEV) /* context switch function */
#define IOCW_CSWITCH_FU (_IOC_CSWITCH_FU | IOC_WR)
#define IOCR_CSWITCH_FU (_IOC_CSWITCH_FU)
#define _IOC_CSWITCH_CHAR (6 | IOC_DEV) /* context switch character */
#define IOCW_CSWITCH_CHAR (_IOC_CSWITCH_CHAR | IOC_WR)
#define IOCR_CSWITCH_CHAR (_IOC_CSWITCH_CHAR)

/*
 * Function to switch ports from the ttys for IFIR
 */
#define _IOC_SWITCH_PORT (7 | IOC_DEV)
#define IOCW_SWITCH_PORT (_IOC_SWITCH_PORT | IOC_WR)
#define IOCR_SWITCH_PORT (_IOC_SWITCH_PORT)
/*
 * Definitions for ioctl() with _IOC_SWITCH_PORT
 */
#define SET_DTR 1
#define CLR_DTR 2

/*
 * ioctl functions for DEV_LCD ports
 */
#define _IOC_PIXEL   (1 | IOC_DEV) /* read/write pixel of lcd */
#define IOCW_PIXEL   (_IOC_ASYMODE | IOC_WR)
#define IOCR_PIXEL   (_IOC_ASYMODE) /* Not used */

#endif /* _PATH_H */
