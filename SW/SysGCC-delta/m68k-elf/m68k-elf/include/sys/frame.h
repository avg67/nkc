/*- Register stackframe structure
 *
 * Copyright (C) 1991	Andreas Voggeneder
 */
/*-
 * last Date	Version	  Action					Who
 * 5.04.1994	 1.00	  created					avg
 */

#ifndef _FRAME_H
#define _FRAME_H
#ifndef __R3000__
#define GENERAL 16
#else
#define GENERAL 32    
#endif
	    	
struct frame {
#ifdef mc68000
        unsigned short vector; /* pushed by handler function */
#endif
	unsigned long	        regs[GENERAL];
#ifdef __R3000__
        unsigned long       cp0_regs[13]; /* reg 5-7 are reserved */
	unsigned long       hi;
	unsigned long       lo;
	unsigned long       cp1_ctl;
	unsigned long       cp1_rev; 
	unsigned long       cp1_regs[32];
	unsigned long       pc;
#else
	short	        stackadj; 
	unsigned short	sr;
	unsigned long	pc;
#ifndef mc68000
	unsigned short	format:4,
		        vector:12;
	union u {
		struct fmt2 {
			unsigned int	iaddr;
		} fmt2;
#ifdef mcpu32

		struct fmtC {
			unsigned int    fadr;
			unsigned int    dbuf;
			unsigned int	cipc;
			unsigned short	itcr;
			unsigned short	ssw;
		} fmtC;
 
#elif defined mc68020
		struct fmt9 {
			unsigned int	iaddr;
			unsigned short	iregs[4];
		} fmt9;

		struct fmtA {
			unsigned short	ir0;
			unsigned short	ssw;
			unsigned short	ipsc;
			unsigned short	ipsb;
			unsigned int	dcfa;
			unsigned short	ir1, ir2;
			unsigned int	dob;
			unsigned short	ir3, ir4;
		} fmtA;

		struct fmtB {
			unsigned short	ir0;
			unsigned short	ssw;
			unsigned short	ipsc;
			unsigned short	ipsb;
			unsigned int	dcfa;
			unsigned short	ir1, ir2;
			unsigned int	dob;
			unsigned short	ir3, ir4;
			unsigned short	ir5, ir6;
			unsigned int	sba;
			unsigned short	ir7, ir8;
			unsigned int	dib;
			unsigned short	iregs[22];
		} fmtB;
#else
#error you must implement stackframe for this cpu
#endif
	} u;
#else /* mc68000 */
	union u {
		struct fbus {
			unsigned short	inst;
			unsigned short	usr;
			unsigned long	upc;
		} fbus;
	/* artifical frame to access bus frame data */
		struct fb {
			unsigned short	inst;
			unsigned short	fcode;
			unsigned long	aaddr;
		} fb;
	} u;
#endif
#endif
    };

struct context {
#ifndef __R3000__
    unsigned long usp;
    unsigned long vbr;
    unsigned short sfc;
    unsigned short dfc;
#endif
    struct frame f;
};

#ifdef __cplusplus
extern "C" {
#endif
void (*_sig_context(int, void (*fp)(int, struct frame *)))(int);
void _do_context(struct frame *);
void $_exception_handler(void);
void (*_sig_handler_ptr)(struct frame frame); 
#ifdef  __cplusplus
}
#endif

#endif

