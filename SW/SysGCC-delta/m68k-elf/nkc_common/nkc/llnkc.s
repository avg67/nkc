#include "../../nkc_common/nkc/nkc.h"
#include "../../nkc_common/nkc/macros.h"

#include <ndrcomp/gruprg.h>

	.text


__getleng 	=0
__getname 	=1
__getstadd 	=2
__lese		=3
__loadtext	=4
__motoroff	=5
__response	=6
__schreibe	=7
__strgcomp	=8
__tload		=9
__tsave		=10
__uppercas	=11
__wrblank	=12
__wrint		=13
__close		=14
__copyfile	=15
__create	   =16
__erase		=17
__fillfcb	=18
__open		=19
__readrec	=20
__rename	   =21
__setdta	   =22
__writerec	=23
__getversi	=24
__getparm	=25
__hardcopy	=26
__bell		=27
__beep		=28
__errnoise	=29
__sound		=30
__inport	   =31
__outport	=32
__movelbin	=33
__moveltxt	=34
__moverbin	=35
__wrtcmd	   =36
__gtretcod	=37
__stretcod	=38
__moveline	=39
__wraddr	   =40
__ci		   =41
__getparm1	=42
__getparm2	=43
__fileload	=44
__filesave	=45
__getparm3	=46
__getparm4	=47
__loadpart	=48
__savepart	=49
__catalog	=50
__floppy	   =51
__drivecod	=52
__getdrive	=53
__setdrive	=54
__gttraptb	=55
__blockread	=56
__blockwrit	=57
__getladdr	=58
__skipchar	=59
__delete	   =60
__insert	   =61
__ramtop	   =62
__progzge      =64
__getuhr	   =65
__setufr	   =66
__date		=67
__time		=68
__datim		=69
__setdatim	=70
__fileinfo	=71
__diskinfo	=72
__wrlint	   =73
__directory	=74
__table		=75
__respinfo	=76
__lineedit	=77
__getcpu	   =78
__getclock	=79
__getgrund	=80
__getsound	=81
__getdisks	=82
__chmod		=83
__gtcmdtab	=84
__getdpath	=85
__clrovert	=86
__setovwrt	=87
__asctonum	=88
__numtoasc	=89
__gethdisk	=90
__loadauto	=91
__cmdexec	=92
__setrec	   =93

#define USE_JADOS

/*
 --------------------------------------------------- Hier folgend GrundProgramm- und JADOS-Aufrufe, die könnten noch in ein eigenes File ---------------------------------------------------

 Note:
 
 native calls are prefixed nkc_
 gp calls are prefixed gp_
 jados calls are prefixed jd_
 
*/ 

#ifdef USE_GP
/*****************************************************************************
 * void gp_progzge(const void * const p_mem);
 * Stack-frame:
 *  16: Address
 * 
 *
 *****************************************************************************/  	
gp_progzge: .global gp_progzge
	movem.l %d7/%a0/%a6,-(%sp)	/* used by jados frame-pointer */	
	movea.l 16(%sp),%a0
	moveq #__progzge,%d7		/* call GP */
	trap #1
	movem.l (%sp)+, %d7/%a0/%a6
	rts 	
	

#endif
#ifdef USE_JADOS
/*  --------------------------------------------------- calls to JADOS (trap #6) --------------------------------------------- */ 	
/*
 UCHAR jd_fillfcb(struct fcb *FCB,char *name)
 returns 0 if successful
*/	
jd_fillfcb: .global jd_fillfcb 	
	movem.l %a6,-(%a7)	/* used by jados frame-pointer */
	movea.l 12(%sp),%a0  	/* *name */
	moveq #__uppercas, %d7	/* Dateinamen immer in Großbuchstaben */
	trap #6
	movea.l 8(%sp),%a1   	/* *fcb  */
	movea.l 12(%sp),%a0  	/* *name */
	moveq #__fillfcb,%d7
	trap #6
	movem.l (%a7)+,%a6
	rts

/*
 UCHAR jd_open(struct fcb *FCB)
 returns 0 if successful
*/	
jd_open: .global jd_open 	
	movem.l %a6,-(%a7)	/* used by jados frame-pointer */
	movea.l 8(%sp),%a1 	/* *fcb  */
	moveq #__open,%d7
	trap #6
	movem.l (%a7)+,%a6
	rts
	
/*
 UCHAR jd_create(struct fcb *FCB)
 returns 0 if successful
*/	
jd_create: .global jd_create 	
	movem.l %a6,-(%a7)	/* used by jados frame-pointer */
	movea.l 8(%sp),%a1 	/* *fcb  */
	moveq #__create,%d7
	trap #6
	movem.l (%a7)+,%a6
	rts	

/*
 void jd_close(struct fcb *FCB)
*/	
jd_close: .global jd_close 	
	movem.l %a6,-(%a7)	/* used by jados frame-pointer */
	movea.l 8(%sp),%a1 	/* *fcb  */
	moveq #__close,%d7
	trap #6
	movem.l (%a7)+,%a6
	rts
	
/*
 UCHAR jd_erase(struct fcb *FCB)
 
 result	Bedeutung
		0	Datei gelöscht
		2	Datei nicht vorhanden
		0xff	Fehler beim Zugriff auf den Massenspeicher
		
		Achtung: falls die Datei schon existiert, wird sie lediglich geöffnet !
		
*/	
jd_erase: .global jd_erase 	
	movem.l %a6,-(%a7)	/* used by jados frame-pointer */
	movea.l 8(%sp),%a1 	/* *fcb  */
	moveq #__erase,%d7
	trap #6
	movem.l (%a7)+,%a6
	rts			

/*
 UCHAR jd_readrec(struct fcb *FCB)
 returns 	   0 - if successful
 		   1 - EOF
 		  99 - end of memory
 		0xFF - access error 
*/	
jd_readrec: .global jd_readrec
	movem.l %a6,-(%a7)	/* used by jados frame-pointer */
	movea.l 8(%sp),%a1 	/* *fcb  */
	moveq #__readrec,%d7
	trap #6
	movem.l (%a7)+,%a6
	rts		

/*
 UCHAR jd_writerec(struct fcb *FCB)
 returns 	   0 - if successful
 		   5 - disk full
 		0xFF - access error 
*/	
jd_writerec: .global jd_writerec
	movem.l %a6,-(%a7)	/* used by jados frame-pointer */
	movea.l 8(%sp),%a1 	/* *fcb  */
	moveq #__writerec,%d7
	trap #6
	movem.l (%a7)+,%a6
	rts		

/*
 UCHAR jd_setrec(struct fcb *FCB, int sector)
 returns 	   0 - if successful
 		   1 - EOF
 		0xFF - access error 
*/	
jd_setrec: .global jd_setrec	
	movem.l %a6,-(%a7)	/* used by jados frame-pointer */
	movea.l 8(%sp),%a1 	/* *fcb  */
	move.l 12(%sp),%d1 	/* sector  */
	moveq #__setrec,%d7
	trap #6
	movem.l (%a7)+,%a6
	rts		
	
/*
 void jd_setdta(struct fcb *FCB, void* buffer)
*/	
jd_setdta: .global jd_setdta
	movem.l %a6,-(%a7)	/* used by jados frame-pointer */
	movea.l 8(%sp),%a1 	/* *fcb  */
	movea.l 12(%sp),%a0 	/* buffer  */	
	/*
	moveq #__setdta,%d7
	trap #6
	*/	
	move.l %a0,44(%a1)	 
	
	movem.l (%a7)+,%a6
	rts	

/*****************************************************************************
 * int jd_remove(char *name)
  * delete file
 *****************************************************************************/                                       
jd_remove: .global jd_remove
	movem.l %d7/%a6,-(%sp)	/* used by jados frame-pointer */
	movea.l 12(%sp),%a0  	/* *name */
	moveq #__uppercas, %d7	/* Dateinamen immer in Großbuchstaben */
	trap #6
#ifdef M68000
	lea buffer,%a1   	/* *fcb  <<-- !!*/
#else
	lea buffer(%pc),%a1   	/* *fcb  <<-- !!*/
#endif
	movea.l 12(%sp),%a0  	/* *name */
	moveq #__fillfcb,%d7
	trap #6
#ifdef M68000
	lea buffer,%a1 	/* *fcb  <<-- !!*/
#else
	lea buffer(%pc),%a1 	/* *fcb  <<-- !!*/
#endif
	moveq #__erase,%d7
	trap #6
	movem.l (%sp)+,%d7/%a6
	rts
	
	
/*****************************************************************************
 * int jd_rename(char *old , char *new)
 * Rename a file (DOS function 56h,Int21)
 * z.B. rename C:/Mydir/myfile.dat c:/newdir/otherfile.dat
 *****************************************************************************/                                      
jd_rename: .global jd_rename
	movem.l %d7/%a2/%a6,-(%sp)	/* used by jados frame-pointer */
	movea.l 20(%sp),%a0  	/* *newname */
	moveq #__uppercas, %d7	/* Dateinamen immer in Großbuchstaben */
	trap #6
#ifdef M68000
	lea buffer,%a1   	/* *fcb  */
#else
	lea buffer(%pc),%a1   	/* *fcb  */
#endif
	movea.l 20(%sp),%a0  	/* *newname <<--! */
	moveq #__fillfcb,%d7
	trap #6
	movea.l %a1, %a2
	movea.l 16(%sp),%a0  	/* *oldname */
	moveq #__uppercas, %d7	/* Dateinamen immer in Großbuchstaben */
	trap #6
#ifdef M68000
	lea buffer,%a1     /* <<--- !! */
#else
	lea buffer(%pc),%a1     /* <<--- !! */
#endif
	adda.l #64, %a1   	/* *fcb  */
	movea.l 16(%sp),%a0  	/* *oldname */
	moveq #__fillfcb,%d7
	trap #6
	moveq #__rename, %d7
	trap #6
	movem.l (%sp)+, %d7/%a2/%a6
	rts

/*****************************************************************************
 * int jd_get_drive();
 *
 * Return vaules:
 * 	0 		= ramdisk
 *	1..4 	= disk 1..4
 *  5..30 	= harddisk partition A..Z
 *****************************************************************************/ 
jd_get_drive: .global jd_get_drive
	movem.l %d7/%a2/%a6,-(%sp)	/* used by jados frame-pointer */
	clr.l %d0
	moveq #__getdrive,%d7		/* call jados */
	trap #6
	movem.l (%sp)+, %d7/%a2/%a6
	rts
/*****************************************************************************
 * void jd_set_drive(int drive);
 *
 * input:
 * 	0 		= ramdisk
 *	1..4 	= disk 1..4
 *  5..30 	= harddisk partition A..Z
 *****************************************************************************/  	
jd_set_drive: .global jd_set_drive
	movem.l %d7/%a2/%a6,-(%sp)	/* used by jados frame-pointer */
	move.l 16(%sp),%d0  		/* drive */
	moveq #__setdrive,%d7		/* call jados */
	trap #6
	movem.l (%sp)+, %d7/%a2/%a6
	rts 

/*****************************************************************************
 * BYTE jd_directory(void* pbuf, void* ppattern, BYTE attrib, WORD columns, WORD size);
 *
 * input:
 *      pbuf		pointer output buffer
 *	ppattern	pointer to file pattern
 *	attrib		bitmapped file attribute: 1=file length; 2=date; 4=r/w attribute
 *	columns		number of colums for output
 *	size		size of output buffer pbuf (256x14 Bytes max.)
 *	
 * output:
 *    	buffer filled with directory entries
 *	return code: 0x00 = Success, 0xFF = Values unvalid
 *  
 * stack-frame:
 *		0x0028   40+2	size		(WORD)
 *		0x0024	 36+2	columns 	(WORD)
 *		0x0020	 32+3	attrib 		(BYTE)
 *		0x001C	 28	ppattern	(DOWRD)
 *              0x0018	 24	pbuf		(DWORD)
 *		0x0014	 20	return address
 *		0x0010	 16	saved jados frame
 *		0x000C	 12	---"---	
 *		0x0008	 8	---"---
 *		0x0004	 4	saved registers
 *	sp--->	0x0000	 0	---"---
 *****************************************************************************/
jd_directory: .global jd_directory
    /*movem.l %d7/%a2/%a6,-(%sp) */     /* used by jados frame-pointer */
	/*movem.l %d2/%d3/%d4,-(%sp) */		/* save used regs (%a0,%a1,%d0,%d1 are scratch regs) */
	movem.l %d2/%d3/%d4/%d7/%a2/%a6,-(%sp)

    movea.l 28(%sp),%a0     /* 24 pbuf */
	movea.l 32(%sp),%a1		/* 28 ppattern */
	move.b  39(%sp),%d2		/* 35 attrib */
	move.w  42(%sp),%d3		/* 38 columns */
	move.w  46(%sp),%d1		/* 42 size */
	
    moveq #__directory,%d7           /* call jados */
    trap #6

	/*movem.l (%sp)+, %d2/%d3/%d4 */		/* restore used regs */
    /*movem.l (%sp)+, %d7/%a2/%a6 */	/* restore jados frame-pointer */
	movem.l (%sp)+, %d2/%d3/%d4/%d7/%a2/%a6
    rts

 jd_directory_test: .global jd_directory_test
    movem.l %d7/%a2/%a6,-(%sp)      /* used by jados frame-pointer */
	movem.l %d2/%d3,-(%sp)		/* save used regs (%a0,%a1,%d0,%d1 are scratch regs) */
	
	clr.l %d1
	clr.l %d2
	clr.l %d3
	
    movea.l 24(%sp),%a0             /* pbuf */
	movea.l 28(%sp),%a1		/* ppattern */
	move.b  35(%sp),%d2		/* attrib */
	move.w  38(%sp),%d3		/* columns */
	move.w  42(%sp),%d1		/* size */
	
	/*writeln msg001(%pc)*/
	/*
        prthex8 %a0
        crlf
        prthex8 %a1
        crlf
        */
        /*prthex8 %d1
        writeln buffer(%pc)
        crlf
        prthex8 %d2
        writeln buffer(%pc)
        crlf
        prthex8 %d3
        writeln buffer(%pc)
        crlf*/

	movem.l (%sp)+, %d2/%d3		/* restore used regs */
        movem.l (%sp)+, %d7/%a2/%a6	/* restore jados frame-pointer */
        rts
/*****************************************************************************
 * void* jd_get_ramtop(void);
 *
 * get end of user space from JAODS 
 *
 *****************************************************************************/  	
jd_get_ramtop: .global jd_get_ramtop
	movem.l %d7/%a2/%a6,-(%sp)	/* used by jados frame-pointer */	
	moveq #__ramtop,%d7		/* call jados */
	trap #6
	movem.l (%sp)+, %d7/%a2/%a6
	rts 
	
/*****************************************************************************
 * void* jd_get_gp(void);
 *
 * get start address of GP from JADOS 
 *
 *****************************************************************************/  	
jd_get_gp: .global jd_get_gp
	movem.l %d7/%a2/%a6,-(%sp)	/* used by jados frame-pointer */	
	moveq #__getgrund,%d7		/* call jados */
	trap #6
	movem.l (%sp)+, %d7/%a2/%a6
	rts 	
	
/*****************************************************************************
 * void* jd_get_laddr(void);
 *
 * get start address of user space from JADOS 
 *
 *****************************************************************************/  	
jd_get_laddr: .global jd_get_laddr
	movem.l %d7/%a2/%a6,-(%sp)	/* used by jados frame-pointer */	
	moveq #__getladdr,%d7		/* call jados */
	trap #6
	movem.l (%sp)+, %d7/%a2/%a6
	rts 		
	
#endif /* USE_JADOS */





#if defined USE_JADOS || defined USE_GP
.data

buffer:		ds.b 255 	
msg001:	.ascii "jd_directory_test:" 	
	.byte 0x0d,0x0a,0x00
#endif		
