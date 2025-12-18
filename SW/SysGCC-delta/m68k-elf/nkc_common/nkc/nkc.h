#ifndef __NKC_H
#define __NKC_H

#include <time.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <ndrcomp/target.h>
#include <sys/ndrclock.h>
#include <sys/times.h>

//Exportierte Symbole der NKCLIB
//volatile char gp_csts(void);
//volatile void gp_co(char x);
//volatile char gp_ci(void);
int ioctl(int fd, int code, void* buf);
int write(int fd, const void *buffer, size_t n);
int read(int fd, void *bfr, size_t n);
int close(int fd);
void * get_heap_ptr(void);

#ifndef __cplusplus
  #define min(a,b) (((a)<=(b))?(a):(b))
  #define max(a,b) (((a)>=(b))?(a):(b))
#endif

//extern const unsigned long ram_top;   // same as _mem_top
extern const char *_mem_top;
extern const char * _static_top;    // Unused memory between _static_top and _mem_top

#ifdef __cplusplus
  extern "C" time_t _gettime(void);
  extern "C" clock_t _clock(void (*clock_fu)(void));
  extern "C" clock_t _times(struct tms *buf);
#else
  time_t _gettime(void);
  clock_t _clock(void (*clock_fu)(void));
  clock_t _times(struct tms *buf);
#endif


#define ARRAY_SIZE(a) (sizeof(a)/sizeof(a[0u]))
#define LO8(x) ( (unsigned char) ((x) & 0xFFu) )
#define HI8(x) ( (unsigned char) (((x) >> 8u) & 0xFFu) )

/* TRAP-NUMMERN DES GP TRAP #1 (V7.0) */

#define _GP_TRAP	 1

#define _SCHREITE    1
#define _DREHE       2
#define _HEBE        3
#define _SENKE       4
#define _FIGURXY     5
#define _WRITELF     6
#define _SET         7
#define _MOVETO      8
#define _DRAWTO      9
#define _WRITE       10
#define _READ        11
#define _CI          12
#define _CSTS        13
#define _RI          14
#define _PO          15
#define _CLR         16
#define _CLPG        17
#define _WAIT        18
#define _SCHR16TEL   19
#define _CLRSCREEN   20
#define _CO          21
#define _LO          22
#define _SIN         23
#define _COS         24
#define _SIZE        25
#define _CMD         26
#define _NEWPAGE     27
#define _SYNC        28
#define _WERT        29
#define _ZUWEIS      30
#define _CIINIT2     31
#define _CI2         32
#define _CO2         33
#define _SETFLIP     34
#define _DELAY       35
#define _FIRSTTIME   36
#define _SETPEN      37
#define _ERAPEN      38
#define _GRAPOFF     39
#define _CMDPRINT    40
#define _PRINT2X     41
#define _PRINT4X     42
#define _PRINT6X     43
#define _PRINT8X     44
#define _PRINT8B     45
#define _PRINT4D     46
#define _HIDE        47
#define _SHOW        48
#define _CRT         49
#define _LST         50
#define _USR         51
#define _NIL         52
#define _SETERR      53
#define _GETERR      54
#define _SETPASS     55
#define _EDIT        56
#define _FIGUR       57
#define _SETFIG      58
#define _GETRAM      59
#define _AUTOFLIP    60
#define _CURSEIN     61
#define _CURSAUS     62
#define _CHAR        63
#define _PROGZGE     64
#define _ASSEMBLE    65
#define _GETSTX      66
#define _PUTSTX      67
#define _GETORG      68
#define _PUTORG      69
#define _PRINT8D     70
#define _PRINTV8D    71
#define _MULS32      72
#define _DIVS32      73
#define _FLINIT      74
#define _FLOPPY      75
#define _GETFLOP     76
#define _SETXOR      77
#define _GETXOR      78
#define _SETCOLOR    79
#define _GETCOLOR    80
#define _CURON       81
#define _CUROFF      82
#define _ADJ360      83
#define _PRTSYM      84
#define _SYMCLR      85
#define _GETSYM      86
#define _GETNEXT     87
#define _PUTNEXT     88
#define _GETBASIS    89
#define _GETVAR      90
#define _SETA5       91
#define _AUFXY       92
#define _KORXY       93
#define _AUFK        94
#define _GETK        95
#define _RND         96
#define _GETVERS     97
#define _GETSN       98
#define _CRLF        99
#define _GETLINE     100
#define _GETCURXY    101
#define _SETCURXY    102
#define _GETXY       103
#define _SI          104
#define _SO          105
#define _SISTS       106
#define _SOSTS       107
#define _SIINIT      108
#define _GETAD8      109
#define _GETAD10     110
#define _SETDA       111
#define _SPEAK       112
#define _SPEAK1      113
#define _SOUND       114
#define _GETUHR      115
#define _SETUHR      116
#define _LSTS        117
#define _RELAN       118
#define _RELAUS      119
#define _ASSERR      120
#define _PRINTFP0    121
#define _GETFLOAT    122
#define _READAUS     123
#define _GRUND       124
#define _HARDCOPY    125
#define _GRAFIK      126
#define _GDPVERS     127
#define _SER         128
#define _CO2SER      129
#define _CLUTINIT    130
#define _CLUT        131
#define _RELAIS      132
#define _RELAISIN    133
#define _SETDA12     134
#define _GETAD12     135
#define _DISASS      136
#define _SUCHBIBO    137
#define _SI2         138
#define _SYSTEM      139
#define _UHRPRINT    140
#define _HARDDISK    141
#define _HARDTEST    142
/*#define _            143
#define _            144   */
#define _PRTFP0      145
#define _FPUWERT     146
#define _SETFPX      147
#define _SETFPY      148
#define _SETFPZ      149
#define _SETSER      150
#define _GETSER      151
#define _SETS2I      152
#define _GETS2I      153
#define _IDETEST     154
#define _IDEDISK     155
#define _SRDISK      156
#define _SETF2S      157
#define _GETF2S      158
#define _GETSRD      159
#define _SETSYS      160
#define _GETSYS      161
#define _PATCH       162
/* SD-Card */
#define _SDTEST      163
#define _SDDISK      164
/* misc */
#define _SETCHAR     165
#define _SETTRANS    166
#define _GETTRANS    167


/* HARDDISK-COMMANDS */
#define _HD_CMD_REZERO_UNIT	0
#define _HD_CMD_READ		1
#define _HD_CMD_WRITE		2
#define _HD_CMD_READ_LONG	3
#define _HD_CMD_WRITE_LONG	4
#define _HD_CMD_MODE_SELECT	5
#define _HD_CMD_MODE_SENSE	6
#define _HD_CMD_SEEK		7
#define _HD_CMD_TEST_UNIT	8
#define _HD_CMD_STOP		9
#define _HD_CMD_START		10
#define _HD_CMD_EXT_READ	11
#define _HD_CMD_EXT_WRITE	12
#define _HD_CMD_READ_BUFF	13
#define _HD_CMD_WRITE_BUFF	14
#define _HD_CMD_RESERVE		15
#define _HD_CMD_RELEASE		16
#define _HD_CMD_WR_VERIFY	17
#define _HD_CMD_VERIFY		18
#define _HD_CMD_SEND_DIAG	19
#define _HD_CMD_EXT_SEEK	20
#define _HD_CMD_RD_USAGE_CT	21
#define _HD_CMD_RD_CAPACITY	22
#define _HD_CMD_RD_DIAG_RES	23
#define _HD_CMD_INQUIRY		24
#define _HD_CMD_RD_DEF_DATA	25
#define _HD_CMD_REASS_BLKS	26
#define _HD_CMD_REQ_SENSE	27
#define _HD_CMD_FORMAT_UNIT	28
#define _HD_CMD_CUSTOM_CMD	29

/* DISKNUMBER */
#define _HD_0	1
#define _HD_1	2
#define _HD_MASTER	1
#define _HD_SLAVE	2

asm (
  "# asm"						"\n\t"
  "_BIOS_TABLE= 0x000D0100" "\n\t"
  "_TSCHREITE=1"      "\n\t"
  "_TDREHE= 2"        "\n\t"
  "_THOCH= 3"         "\n\t"
  "_TRUNTER= 4"       "\n\t"
  "_FIGURXY= 5"       "\n\t"
  "_TEXTPRINT= 6"     "\n\t"
  "_TMOVE=   7"       "\n\t"
  "_MOVETO=  8"       "\n\t"
  "_DRAWTO=  9"       "\n\t"
  "_TEXTAUS= 10"      "\n\t"
  "_TEXTEIN= 11"      "\n\t"
  "_CI=      12"      "\n\t"
  "_CSTS=    13"      "\n\t"
  "_RI=      14"      "\n\t"
  "_POO=     15"      "\n\t"
  "_CLRALL=  16"      "\n\t"
  "_CLRINVIS=17"      "\n\t"
  "_WAIT=    18"      "\n\t"
  "_TSCHR16TEL= 19"   "\n\t"
  "_CLRSCREEN = 20"   "\n\t"
  "_CO=      21"      "\n\t"
  "_LO2=     22"      "\n\t"
  "_SIN=     23"      "\n\t"
  "_COS=     24"      "\n\t"
  "_SETGROE= 25"      "\n\t"
  "_CMD=     26"      "\n\t"
  "_NEWPAGE= 27"      "\n\t"
  "_SYNC=    28"      "\n\t"
  "_WERT=    29"      "\n\t"
  "_ZUWEIS=  30"      "\n\t"
  "_CIINIT2= 31"      "\n\t"
  "_CI2=     32"      "\n\t"
  "_CO2=     33"      "\n\t"
  "_SETFLIP= 34"      "\n\t"
  "_DELAY=   35"      "\n\t"
  "_FIRSTTIME= 36"    "\n\t"
  "_SETPEN=  37"      "\n\t"
  "_ERAPEN=  38"      "\n\t"
  "_GRAPOFF= 39"      "\n\t"
  "_PRINT=   40"      "\n\t"
  "_PRINT2X= 41"      "\n\t"
  "_PRINT4X= 42"      "\n\t"
  "_PRINT6X= 43"      "\n\t"
  "_PRINT8X= 44"      "\n\t"
  "_PRINT8B= 45"      "\n\t"
  "_PRINT4D= 46"      "\n\t"
  "_HIDE=    47"      "\n\t"
  "_SHOW=    48"      "\n\t"
  "_CRTEX=   49"      "\n\t"
  "_LSTEX=   50"      "\n\t"
  "_USREX=   51"      "\n\t"
  "_NILEX=   52"      "\n\t"
  "_SETERR=  53"      "\n\t"
  "_GETERR=  54"      "\n\t"
  "_SETPASS= 55"      "\n\t"
  "_EDIT=    56"      "\n\t"
  "_FIGUR=   57"      "\n\t"
  "_SETFIG=  58"      "\n\t"
  "_GETRAM=  59"      "\n\t"
  "_AUTOFLIP=60"      "\n\t"
  "_CURSOREIN= 61"    "\n\t"
  "_CURSORAUS= 62"    "\n\t"
  "_CHARHANDLER= 63"  "\n\t"
  "_PROGZGE= 64"      "\n\t"
  "_ASSEMBLE=65"      "\n\t"
  "_GETSTX=  66"      "\n\t"
  "_PUTSTX=  67"      "\n\t"
  "_GETORG=  68"      "\n\t"
  "_PUTORG=  69"      "\n\t"
  "_PRINT8D= 70"      "\n\t"
  "_PRINTV8D=71"      "\n\t"
  "_MULS32=  72"      "\n\t"
  "_DIVS32=  73"      "\n\t"
  "_FLINIT=  74"      "\n\t"
  "_FLOPPY=  75"      "\n\t"
  "_GETFLOP= 76"      "\n\t"
  "_SETXOR=  77"      "\n\t"
  "_GETXOR=  78"      "\n\t"
  "_SETCOLOR=79"      "\n\t"
  "_GETCOLOR=80"      "\n\t"
  "_CURONEIN=81"      "\n\t"
  "_CURONAUS=82"      "\n\t"
  "_ADJ360=  83"      "\n\t"
  "_SYMBOLAUS= 84"    "\n\t"
  "_SYMLOESCHE= 85"   "\n\t"
  "_GETSYMTAB= 86"    "\n\t"
  "_GETNEXT= 87 "     "\n\t"
  "_PUTNEXT= 88 "     "\n\t"
  "_GETBASIS=89 "     "\n\t"
  "_GETVAR=  90 "     "\n\t"
  "_SETA5=   91 "     "\n\t"
  "_AUFXY=   92 "     "\n\t"
  "_KORXY=   93 "     "\n\t"
  "_AUFK=    94 "     "\n\t"
  "_GETK=    95 "     "\n\t"
  "_RND=     96 "     "\n\t"
  "_GETVERS= 97 "     "\n\t"
  "_GETSN=   98 "     "\n\t"
  "_CRLFE=   99 "     "\n\t"
  "_GETLINE= 100"     "\n\t"
  "_GETCURXY=101"     "\n\t"
  "_SETCURXY=102"     "\n\t"
  "_GETXY=   103"     "\n\t"
  "_SI=      104"     "\n\t"
  "_SO=      105"     "\n\t"
  "_SISTS=   106"     "\n\t"
  "_SOSTS=   107"     "\n\t"
  "_SIINIT=  108"     "\n\t"
  "_GETAD8=  109"     "\n\t"
  "_GETAD10= 110"     "\n\t"
  "_SETDA=   111"     "\n\t"
  "_SPEAK=   112"     "\n\t"
  "_SPEAK1=  113"     "\n\t"
  "_SOUND=   114"     "\n\t"
  "_GETUHR=  115"     "\n\t"
  "_SETUHR=  116"     "\n\t"
  "_LSTS=    117"     "\n\t"
  "_RELAISAN=118"     "\n\t"
  "_RELAISAUS= 119"   "\n\t"
  "_ASSERR=  120"     "\n\t"
/*  _TNOTIMP= 121    NUR BEIM 68020 */
/*  _TNOTIMP= 122    NUR BEIM 68020 */
  "_READAUS= 123"     "\n\t"
  "_GRUND=   124"     "\n\t"
  "_HARDCOPY=125"     "\n\t"
  "_GRAFIK=  126"     "\n\t"
  "_GDPVERS= 127"     "\n\t"
  "_SERAUS=  128"     "\n\t"
  "_SEREX=   129"     "\n\t"
  "_CLUTINIT=130"     "\n\t"
  "_CLUT=    131"     "\n\t"
  "_RELAIS=  132"     "\n\t"
  "_RELAISIN=133"     "\n\t"
  "_SETDA12= 134"     "\n\t"
  "_GETAD12= 135"     "\n\t"
  "_SUCHBIBO=136"     "\n\t"
  "_TRAPDISASS= 137"  "\n\t"
  "_SI2=     138"     "\n\t"
  "_SYSTEM=  139"     "\n\t"
  "_UHRPRINT=140"     "\n\t"
  "_HARDDISK=141"     "\n\t"
  "_HARDTEST=142"     "\n\t"
/* "_TNOTIMP= 143    Reserviert */
/* "_TNOTIMP= 144    Reserviert */
/* "_TNOTIMP= 145    Nur bei 68020 */
/* "_TNOTIMP= 146    Nur bei 68020 */
/* "_TNOTIMP= 147    Nur bei 68020 */
/* "_TNOTIMP= 148    Nur bei 68020 */
/* "_TNOTIMP= 149    Nur bei 68020 */
 "_SETSER=   150"     "\n\t"
 "_GETSER=   151"     "\n\t"
 "_SETS2I=   152"     "\n\t"
 "_GETS2I=   153"     "\n\t"
 "_IDETEST=  154"     "\n\t"
 "_IDEDISK=  155"     "\n\t"
 "_SRDISK=   156"     "\n\t"
 "_SETF2S=   157"     "\n\t"
 "_GETF2S=   158"     "\n\t"
 "_GETSRD=   159"     "\n\t"
 "_SETSYS=   160"     "\n\t"
 "_GETSYS=   161"     "\n\t"
 "_PATCH=    162"     "\n\t"
 "_SDTEST=   163"     "\n\t"
 "_SDDISK=   164"     "\n\t"
 "_SETCHAR=  165"     "\n\t"
 "_SETTRANS=  166"     "\n\t"
 "_GETTRANS=  167"     "\n\t"
 "# Jados"						"\n\t"
 "__uppercas= 11"     "\n\t"
   );


#ifdef USE_JADOS
/* JADOS 3.4 TRAPS (TRAP #6) */
#define __JD_TRAP	6

#define __getleng 	0
#define __getname 	1
#define __getstadd 	2
#define __lese		3
#define __loadtext	4
#define __motoroff	5
#define __response	6
#define __schreibe	7
#define __strgcomp	8
#define __tload		9
#define __tsave		10
#define __uppercas	11
#define __wrblank	12
#define __wrint		13
#define __close		14
#define __copyfile	15
#define __create	16
#define __erase		17
#define __fillfcb	18
#define __open		19
#define __readrec	20
#define __rename	21
#define __setdta	22
#define __writerec	23
#define __getversi	24
#define __getparm	25
#define __hardcopy	26
#define __bell		27
#define __beep		28
#define __errnoise	29
#define __sound		30
#define __inport	31
#define __outport	32
#define __movelbin	33
#define __moveltxt	34
#define __moverbin	35
#define __wrtcmd	36
#define __gtretcod	37
#define __stretcod	38
#define __moveline	39
#define __wraddr	40
#define __ci		41
#define __getparm1	42
#define __getparm2	43
#define __fileload	44
#define __filesave	45
#define __getparm3	46
#define __getparm4	47
#define __loadpart	48
#define __savepart	49
#define __catalog	50
#define __floppy	51
#define __drivecod	52
#define __getdrive	53
#define __setdrive	54
#define __gttraptb	55
#define __blockread	56
#define __blockwrit	57
#define __getladdr	58
#define __skipchar	59
#define __delete	60
#define __insert	61
#define __ramtop	62
#define __getuhr	65
#define __setufr	66
#define __date		67
#define __time		68
#define __datim		69
#define __setdatim	70
#define __fileinfo	71
#define __diskinfo	72
#define __wrlint	73
#define __directory	74
#define __table		75
#define __respinfo	76
#define __lineedit	77
#define __getcpu	78
#define __getclock	79
#define __getgrund	80
#define __getsound	81
#define __getdisks	82
#define __chmod		83
#define __gtcmdtab	84
#define __getdpath	85
#define __clrovwrt	86
#define __setovwrt	87
#define __asctonum	88
#define __numtoasc	89
#define __gethdisk	90
#define __loadauto	91
#define __cmdexec	92
#define __setrec	93
#endif


///// Utils /////
static inline __attribute__((always_inline)) unsigned long to_bendian(unsigned long l_in)
{
    register unsigned long ret  __asm__("%d0") = 0u;
    asm volatile(
    "# asm"                      "\n\t" \
    "movel %1,%%d0"              "\n\t" \
    "rolw #8,%%d0"               "\n\t" \
	  "swap %%d0"                  "\n\t" \
	  "rolw #8,%%d0"               "\n\t" \
    : "=r"(ret)       /* outputs */    \
    : "g"(l_in)       /* inputs */    \
    :                 /* clobbered regs */ \
    );
    return ret;
}
#if 0
// Argument ist am Stack, Returnwert muss in D0 sein
static inline __attribute__((always_inline)) unsigned short to_bendian16( unsigned short l_in)
{
	register unsigned short ret  __asm__("%d0") = 0;
	asm volatile(
    "# asm"                      "\n\t" \
    "movew %1,%%d0"              "\n\t" \
	"rolw #8,%%d0"               "\n\t" \
    : "=r"(ret)       /* outputs */    \
    : "g"(l_in)       /* inputs */    \
    :                 /* clobbered regs */ \
    );
  return ret;
}
#endif


static inline __attribute__((always_inline)) uint16_t to_bendian16( uint16_t l_in)
{
    uint16_t ret = l_in;
    return (ret<<8u)|(ret>>8u);
}


/* ----------------------------------------------------------------------------- (G)IDE ------------------------------------------------------------------------------------------------------------- */

/*
	A3	/A3	A2	A1	A0															10 (GIDE BASE)
	C1	C0					register								variable	address
	1	0	0	0	0		data i/o								idedat		18
	1	0	0	0	1		error									ideerr		19
	1	0	0	1	0		sector count							        idescnt		1A
	1	0	0	1	1		start sector	LBA[0..7]						idesnum		1B
	1	0	1	0	0		cylinder low byte LBA[8..15]						ideclo		1C
	1	0	1	0	1		cylinder high byte LBA[16.23]						idechi		1D
	1	0	1	1	0		head and device	LBA[24..27]						idesdh		1E
	1	0	1	1	1		command/status							        idecmd		1F
	0	1	1	1	0		2nd status/interrupt/reset				                idesir		16
	0	1	1	1	1		active status of the IDE device			                        idestat		17


-	head and device register (idesdh)
	========================
	A write register that sets the master/slave selection and the head number.

	bits 3..0: head number [0..15]
	bit  4   : master/slave select: 0=master,1=slave
	bits 7..5: fixed at 101B. This is in fact the bytes/sector
           coding. In old (MFM) controllers you could specify if
           you wanted 128,256,512 or 1024 bytes/sector. In the
           IDE world only 512 bytes/sector is supported. This bit
           pattern is a relic from the MFM controllers age. The
           bit 6 of this pattern could in fact be used to access
           a disk in LBA modus.

-	Status register (idecmd)
	===============
	Both the primary and secondary status register use the same bit coding. The register is a read register.

	bit 0 : error bit. If this bit is set then an error has
   	        occurred while executing the latest command. The error
           	status itself is to be found in the error register.
	bit 1 : index pulse. Each revolution of the disk this bit is
           pulsed to '1' once. I have never looked at this bit, I
           do not even know if that really happens.
	bit 2    : ECC bit. if this bit is set then an ECC correction on
           the data was executed. I ignore this bit.
	bit 3    : DRQ bit. If this bit is set then the disk either wants
           data (disk write) or has data for you (disk read).
	bit 4    : SKC bit. Indicates that a seek has been executed with
           success. I ignore this bit.
	bit 5    : WFT bit. indicates a write error has happened. I do
           not know what to do with this bit here and now. I've
           never seen it go active.
	bit 6    : RDY bit. indicates that the disk has finished its
           power-up. Wait for this bit to be active before doing
           anything (execpt reset) with the disk. I once ignored
           this bit and was rewarded with a completely unusable
           disk.
	bit 7    : BSY bit. This bit is set when the disk is doing
           something for you. You have to wait for this bit to
           clear before you can start giving orders to the disk.


-	interrupt and reset register (idesir)
	============================
	This register has only two bits that do something (that I know of). It is a write register.
        bit 0           : = 0
	bit 1    : IRQ enable. If this bit is '0' the disk will give and
           IRQ when it has finished executing a command. When it
           is '1' the disk will not generate interrupts.
	bit 2    : RESET bit. If you pulse this bit to '1' the disk will
           execute a software reset. The bit is normally '0'. I
           do not use it because I have full software control of
           the hardware /RESET line.

-	Active status register
	======================
	This is a read register. I have -up till now- ignored this register. I have only one IDE device (a 	disk) on my contraption.

	bit 0    : master active. If this bit is set then the master IDE
           device is active.
	bit 1    : slave active. If this bit is set then the slave IDE
           device is active.
	bits 5..2: complement of the currently active disk head.
	bit 6    : write bit. This bit is set when the device is writing.
	bit 7    : in a PC environment this bit indicates if a floppy is
           present in the floppy drive. Here it has no meaning.

-	error register
	==============
	The error register indicates what went wrong when a command execution results in an error. The fact that an error has occurred is indicated in the status register, the explanation is given in the error register. This is a read register.

	bit 0    : AMNF bit. Indicates that an address mark was not
           found. What this means I not sure of. I have never
           seen this happen.
	bit 1    : TK0NF bit. When this bit is set the drive was not able
           to find track 0 of the device. I think you will have
           to throw away the disk if this happens.
	bit 2    : ABRT bit. This bit is set when you have given an
           indecent command to the disk. Mostly wrong parameters
           (wrong head number etc..) cause the disk to respond
           with error flag in the status bit set and the ABRT bit
           set. I have gotten this error a lot when I tried to
           run the disk with interrupts. Something MUST have been
           wrong with my interface program. I have not (yet)
           found what.
	bit 3    : MCR bit. indicated that a media change was requested.
           What that means I do not know. I've ignored this bit
           till now.
	bit 4    : IDNF bit. Means that a sector ID was not found. I have
           never seen this happen, I guess it means that you've
           requested a sector that is not there.
	bit 5    : MC bit. Indicates that the media has been changed. I
           ignore this bit.
	bit 6    : UNC bit. Indicates that an uncorrectable data error
           happened. Some read or write errors could provoke
           this. I have never seen it happen.
	bit 7    : reserved.


*/

#define 	idebase  0xffffff10*cpu


#define 	idedor  0xffffff16*cpu
/* data register */
#define 	idedat  0xffffff18*cpu
/* error regsiter */
#define 	ideerr  0xffffff19*cpu
/* sector count register */
#define 	idescnt 0xffffff1A*cpu
/* sector number register */
#define 	idesnum 0xffffff1B*cpu
/* cluster low register */
#define 	ideclo  0xffffff1C*cpu
/* cluster high regsiter */
#define 	idechi  0xffffff1D*cpu
/* head/device regsiter */
#define 	idesdh  0xffffff1E*cpu
/* command register */
#define 	idecmd  0xffffff1F*cpu
/* isecond status / interrupt / reset register */
#define 	idesir	0xffffff16*cpu
/* active status register */
#define 	idestat	0xffffff17*cpu


/* GIDE commands (_IDEDISK) */

#define _IDEDISK_CMD_READ	1
#define _IDEDISK_CMD_WRITE 	2
#define _IDEDISK_CMD_TEST_UNIT_READY 8
#define _IDEDISK_CMD_READ_CAPACITY 22
#define _IDEDISK_CMD_INQUIRY 24

/* -------------------------------------------------------------------------SPI/SDCARD ------------------------------------------------------------------------------------------------------------- */

/*
			FPGA(LFXP6C)
SD0_DI		SD_MOSI_o	21
SD0_DO		SD_MISO_i	18
SD0_CS 		SD_nCS_o	22
SD0_SCLK	SD_SCK_o 	20

constant SPI_BASE_ADDR_c    : std_logic_vector(7 downto 0) := X"00"; -- r/w
s_spi_cs <= not nIORQ when wbm_address(7 downto 1) =  SPI_BASE_ADDR_c(7 downto 1) else '0';
=> SPI == 00..01

$FFFFFF00 - SPI-Control-Register
Schreiben
7 6 5 4 3 2 1 0
| | | | | | | |
| | | | | ------- Clockdivider
| | | | | 000 = 40MHz/1  => 40,0MHz
| | | | | 001 = 40MHz/2  => 20,0MHz
| | | | | 011 = 40MHz/7  =>  5,7MHz
| | | | | 111 = 40MHz/16 =>  2,5MHz
| | | | --------- SCK IDLE Level (1=stop clk at high level)
| | | ----------- frei
| --------------- Slave Select
| 01 = Slave 0, 10 = Slave 1
----------------- SPI-Controller enable
Lesen
7 6 5 4 3 2 1 0
| | | | | | | |
| | | | | | | --- IDLE 1 = Controler bereit für Daten
| | | | | | ----- Write Collision 1 = Datenverlust
----------------- frei

$FFFFFF01 - SPI-Daten-Register

---------------------------------------------------

SD-Card Specifications:

SD 			 ... 2GB	FAT16
SDHC    4GB  ... 32GB	FAT32
SDXC	64GB ... 2TB	exFAT

Information Registers:

Name 	Width 	Description
CID 	128 	Card identification number; card individual number for identification (See 5.2). Mandatory.
RCA1 	16 		Relative card address; local system address of a card, dynamically suggested by
				the card and approved by the host during initialization (See 5.4). Mandatory.
DSR 	16 		Driver Stage Register; to configure the card’s output drivers (See 5.5). Optional.
CSD 	128 	Card Specific Data; information about the card operation conditions (See 5.3). Mandatory
SCR 	64 		SD Configuration Register; information about the SD Memory Card’s Special Features
				capabilities (See 5.6). Mandatory
OCR 	32 		Operation conditions register (See 5.1). Mandatory.
SSR 	512 	SD Status; information about the card proprietary features (See 4.10.2). Mandatory
CSR 	32 		Card Status; information about the card status (See 4.10.1). Mandatory



*/

#ifndef spibase
#define		spibase	0xffffff00*cpu
#endif
#ifndef spictrl
#define		spictrl 0xffffff00*cpu
#endif
#ifndef spidata
#define		spidata 0xffffff01*cpu
#endif

/*  CS der ersten Hardware SD */
#define		SPIH0_CS 5
/*  CS der zweiten Hardware SD */
#define		SPIH1_CS 6

/* SD commands */

/* SD commands (TRAP _SDDISK) */

#define _SDDISK_CMD_READ	1
#define _SDDISK_CMD_WRITE 	2
#define _SDDISK_CMD_TEST_UNIT_READY 8
#define _SDDISK_CMD_READ_CAPACITY 22
#define _SDDISK_CMD_INQUIRY 24

//extern char SDTYPE[];	-> sd_block_drv.c

/* ----------------------------------------------------------------------------- RTC 12887 ------------------------------------------------------------------------------------------------------------- */


#define RTC_DS12887_INDEX       0xfffffffa*cpu
#define RTC_DS12887_DATA        0xfffffffb*cpu

/**********************************************************************
 * register summary
 **********************************************************************/
#define RTC_SECONDS		0
#define RTC_SECONDS_ALARM	1
#define RTC_MINUTES		2
#define RTC_MINUTES_ALARM	3
#define RTC_HOURS		4
#define RTC_HOURS_ALARM		5
/* RTC_*_alarm is always true if 2 MSBs are set */
# define RTC_ALARM_DONT_CARE 	0xC0

#define RTC_DAY_OF_WEEK		6
#define RTC_DAY_OF_MONTH	7
#define RTC_MONTH		8
#define RTC_YEAR		9
#define RTC_CENTURY		50

/* control registers - Moto names
 */
#define RTC_REG_A		10
#define RTC_REG_B		11
#define RTC_REG_C		12
#define RTC_REG_D		13


#define RTC_ALWAYS_BCD  1


/* ----------------------------------------------------------------------------- TIMER ------------------------------------------------------------------------------------------------------------- */

#define TIMER1_BASE       0xFFFFFFF4*cpu
#define TIMER1_CTRL       0xFFFFFFF4*cpu
#define TIMER1_HI         0xFFFFFFF5*cpu
#define TIMER1_LO         0xFFFFFFF6*cpu

static inline __attribute__((always_inline)) uint16_t get_timer(void)
{
    return ((uint16_t)FPGAT1.th << 8) | FPGAT1.tl;
}

/* ----------------------------------------------------------------------------- FLOPPY ------------------------------------------------------------------------------------------------------------- */

#define FLO_COMMAND         0xFFFFFFC0*cpu
#define FLO_TRACK           0xFFFFFFC1*cpu
#define FLO_SECTOR          0xFFFFFFC2*cpu
#define FLO_DATA            0xFFFFFFC3*cpu
#define FLO_CTRL            0xFFFFFFC4*cpu

/* ----------------------------------------------------------------------------- SERIAL ------------------------------------------------------------------------------------------------------------- */

/*
 *
 * control register definition
 * ---------------------------
 * bit
 * 7		stop bits	0=1, 1=2, (1 if wordlength=8 and parity)
 * 6 5		word length	00=8, 01=7, 10=6, 11=5
 * 4		clock source	0=external, 1=internal baud rate generator
 * 3210		baud rate	0000=16x external clock
 * 				0001=50
 * 				0010=75
 * 				0011=109,92 (115200 using GDP-FPGA)
 * 				0100=134,58 (57600 using GDP-FPGA)
 * 				0101=150 (38400 usinf GDP-FPGA)
 * 				0110=300
 * 				0111=600
 * 				1000=1200
 * 				1001=1800
 * 				1010=2400
 * 				1011=3600
 * 				1100=4800
 * 				1101=7200
 * 				1110=9600
 * 				1111=1920
 *
 * 8N1,9600 => 0001 1110 = 0x1e
 * 8N1, 115200 => 0001 0011 = 0x13
 *
 *
 * command register definitions
 * ----------------------------
 * bit
 * 7		parity check cntrl:
 * 		--0 : parity check disabled
 * 		001 : odd parity receiver and transmitter
 * 		011 : even parity receiver and transmitter
 *		101 : mark parity bit transmitted, parity check disabled
 *		111 : space parity bit transmitted, parity check disabled
 * 4		0 = normal mode, 1 = echo mode (bit 2 = bit 3 = 0)
 * 3 2		transmitter controls:
 * 			transmit INT 	/RTS level	transmitter
 * 		00:	 disabled	 high		 off
 * 		01:	 enabled	 low		 on
 * 		10:	 disabled	 low		 on
 * 		11:	 disabled	 low		 transmit brk
 * 1		0 = IRQ enabled from bit 3 of status register, 1 = disable IRQ
 * 0		1 = enable receiver and all interrupts
 *
 * no parity, receive/transmit enable, disable IRQ, no echo => 0000 1011 = 0x0b
 *
 *
 * status register definitions
 * ---------------------------
 *
 * bit
 * 7		0 = no INT, 1 = INT
 * 6		0 = DSR low, 1 = DSR high
 * 5		0 = DCD low, 1 = DCD high
 * 4		1 = transmit data register empty
 * 3		1 = receive data register full
 * 2		1 = overrun error
 * 1		1 = framing error
 * 0		1 = parity error
 *
 */

#define NKC_SER1_BASE        0xFFFFFFF0*cpu
#define NKC_SER1_CTRL        0xFFFFFFF3*cpu
#define NKC_SER1_CMD         0xFFFFFFF2*cpu
#define NKC_SER1_STAT        0xFFFFFFF1*cpu
#define NKC_SER1_TX          0xFFFFFFF0*cpu
#define NKC_SER1_RX          0xFFFFFFF0*cpu

// System-call bits
#define IS_08      (1u<<0u)
#define IS_00      (1u<<1u)
#define IS_20      (1u<<2u)
#define GDP_HS     (1u<<3u)
#define UHR        (3u<<5u)
#define SMARTWATCH (3u<<5u)
#define HDD        (1u<<15u)
#define KEY3       (1u<<16u)
#define SER        (1u<<17u)
#define SER2       (1u<<18u)
#define GIDE       (1u<<19u)
#define RAMDISK    (1u<<20u)
#define GDP_FPGA   (1u<<21u)


/* ----------------------------------------------------------------------------- KEYBOARD ------------------------------------------------------------------------------------------------------------- */

#define NKC_KEY_STATUS	     0xffffff67*cpu
#define NKC_KEY_DATA         0xffffff68*cpu
#define NKC_KEY_DIP          0xffffff69*cpu

/* ----------------------------------------------------------------------------- GDP ------------------------------------------------------------------------------------------------------------- */
// Colors of GDP-FPGA Unit
#define BLACK       0u
#define WHITE       1u
#define YELLOW      2u
#define GREEN       3u
#define RED         4u
#define BLUE        5u
#define MAGENTA     6u
#define CYAN        7u
#define GRAY        8u
#define DARK        8u	// can be or'ed to colors to make them darker

static inline __attribute__((always_inline)) char gp_csts(void)
{
    register long retvalue asm("%d0");
    asm volatile(
    "# asm"             "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "moveq #_CSTS,%%d7" "\n\t" \
    "trap #1"           "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    : "=r"(retvalue) /* outputs */    \
    :                /* inputs */    \
    : "%d7"    /* clobbered regs */ \
    );
    return retvalue;
}

static inline __attribute__((always_inline)) void gp_co(char x)
{

    asm volatile(
    "# asm"                  "\n\t" \
    "moveb %0,%%d0"          "\n\t" \
    "moveq #_CO2,%%d7"       "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #1"                "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    :                /* outputs */    \
    : "d"(x)          /* inputs */    \
    : "%d0", "%d7"    /* clobbered regs */ \
    );
}

static inline __attribute__((always_inline)) char gp_ci(void)
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

static inline __attribute__((always_inline)) void gp_getuhr(volatile ndrtimebuf * p_time)
{
    asm volatile(
    "# asm"                        "\n\t" \
    "moveal %0,%%a0"               "\n\t" \
    "moveml %%d4/%%a5-%%a6,%%sp@-" "\n\t" \
    "moveq #_GETUHR,%%d7"          "\n\t" \
    "trap #1"                      "\n\t" \
    "moveml %%sp@+,%%d4/%%a5-%%a6" "\n\t" \
    : "=g" (p_time)          /* outputs */    \
    :                        /* inputs */    \
    : "%a0","%d7"            /* clobbered regs */ \
    );
}

static inline __attribute__((always_inline)) void gp_cmd(const uint8_t cmd) {
  asm volatile(
    "# asm"                      "\n\t" \
    "moveb %0,%%d0"              "\n\t" \
    "moveq %1,%%d7"              "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #1"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    :                        /* outputs */    \
    : "d"(cmd), "g"(_CMD)    /* inputs */    \
    : "%d7"                  /* clobbered regs */ \
    );
}

/* --> gdplib/nkc_gdplib.h */
static inline __attribute__((always_inline)) void gp_moveto(const uint16_t x, const uint16_t y) {
  asm volatile(
    "# asm"                      "\n\t" \
    "movew %0,%%d1"              "\n\t" \
    "movew %1,%%d2"              "\n\t" \
    "moveq %2,%%d7"              "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #1"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    :                   /* outputs */    \
    : "g"(x), "g"(y), "g"(_MOVETO)    /* inputs */    \
    : "%d1", "%d2", "%d7"    /* clobbered regs */ \
    );
}

static inline __attribute__((always_inline)) void gp_getxy(uint16_t* const p_x, uint16_t* const p_y) {
  asm volatile(
    "# asm"                      "\n\t" \
    "moveq %2,%%d7"              "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #1"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    "movew %%d1,%0"              "\n\t" \
    "movew %%d2,%1"              "\n\t" \
    : "=g"(*p_x),"=g"(*p_y)        /* outputs */    \
    : "g"(_GETXY)                 /* inputs */    \
    : "%d1", "%d2", "%d7"          /* clobbered regs */ \
    );
}

static inline __attribute__((always_inline)) void gp_drawto(const uint16_t x, const uint16_t y) {
  asm volatile(
    "# asm"                      "\n\t" \
    "movew %0,%%d1"              "\n\t" \
    "movew %1,%%d2"              "\n\t" \
    "moveq %2,%%d7"              "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #1"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    :                   /* outputs */    \
    : "g"(x), "g"(y), "g"(_DRAWTO)    /* inputs */    \
    : "%d1", "%d2", "%d7"    /* clobbered regs */ \
    );
}

static inline __attribute__((always_inline)) void gp_setcolor(const uint8_t fg_color,const uint8_t bg_color) {
  asm volatile(
    "# asm"                      "\n\t" \
    "moveb %1,%%d0"              "\n\t" \
    "moveb %2,%%d1"              "\n\t" \
    "moveq %0,%%d7"              "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #1"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    :                   /* outputs */    \
    :  "g"(_SETCOLOR), "d"(fg_color),"d"(bg_color)    /* inputs */    \
    : "%d0", "d1", "%d7"    /* clobbered regs */ \
    );
}

static inline __attribute__((always_inline)) void gp_newpage(const uint8_t wr_page,const uint8_t rd_page) {
  asm volatile(
    "# asm"                      "\n\t" \
    "moveb %1,%%d0"              "\n\t" \
    "moveb %2,%%d1"              "\n\t" \
    "moveq %0,%%d7"              "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #1"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    :                   /* outputs */    \
    : "g"(_NEWPAGE), "d"(wr_page),"d"(rd_page)    /* inputs */    \
    : "%d0", "d1", "%d7"    /* clobbered regs */ \
    );
}

static inline __attribute__((always_inline)) void gp_settrans(const bool trans) {
  asm volatile(
    "# asm"                      "\n\t" \
    "moveb %1,%%d0"              "\n\t" \
    "movew %0,%%d7"              "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #1"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    :                   /* outputs */    \
    :  "g"(_SETTRANS), "d"((trans)?1u:0u)    /* inputs */    \
    : "%d0", "%d7"    /* clobbered regs */ \
    );
}

static inline __attribute__((always_inline)) void gp_setxor(const bool x) {
  asm volatile(
    "# asm"                      "\n\t" \
    "moveb %1,%%d0"              "\n\t" \
    "moveq %0,%%d7"              "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #1"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    :                   /* outputs */    \
    :  "g"(_SETXOR), "d"((x)?1u:0u)    /* inputs */    \
    : "%d0", "%d7"    /* clobbered regs */ \
    );
}

static inline __attribute__((always_inline)) void gp_erapen(void) {
  asm volatile(
    "# asm"                      "\n\t" \
    "movew %0,%%d7"              "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #1"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    :                  /* outputs */    \
    :  "g"(_ERAPEN)    /* inputs */    \
    : "%d7"            /* clobbered regs */ \
    );
}

static inline __attribute__((always_inline)) void gp_setpen(void) {
  asm volatile(
    "# asm"                      "\n\t" \
    "movew %0,%%d7"              "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #1"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    :                  /* outputs */    \
    :  "g"(_SETPEN)    /* inputs */    \
    : "%d7"            /* clobbered regs */ \
    );
}

static inline __attribute__((always_inline)) void gp_draw_filled_rect(const uint16_t x_pos, const uint16_t y_pos, const uint16_t dx, const uint16_t dy) {
  asm volatile(
    "# asm"                      "\n\t" \
    "moveq #6,%%d0"              "\n\t" \
    "movew %1,%%d1"              "\n\t" \
    "movew %2,%%d2"              "\n\t" \
    "movew %3,%%d3"              "\n\t" \
    "movew %4,%%d4"              "\n\t" \
    "moveq %0,%%d7"              "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #1"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    :                   /* outputs */    \
    :  "g"(_GRAFIK), "g"(x_pos), "g"(y_pos), "g"(dx), "g"(dy)    /* inputs */    \
    : "%d0","%d1","%d2","%d3","%d4", "%d7"    /* clobbered regs */ \
    );
}

static inline __attribute__((always_inline)) void gp_draw_filled_circle(const uint16_t x_pos, const uint16_t y_pos, const uint16_t r) {
  asm volatile(
    "# asm"                      "\n\t" \
    "moveq #8,%%d0"              "\n\t" \
    "movew %1,%%d1"              "\n\t" \
    "movew %2,%%d2"              "\n\t" \
    "movew %3,%%d3"              "\n\t" \
    "moveq %0,%%d7"              "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #1"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    :                                                  /* outputs */    \
    :  "g"(_GRAFIK), "g"(x_pos), "g"(y_pos), "g"(r)    /* inputs */    \
    : "%d0","%d1","%d2","%d3", "%d7"                   /* clobbered regs */ \
    );
}

static inline __attribute__((always_inline)) void gp_clearscreen(void) {
  asm volatile(
    "# asm"                      "\n\t" \
    "moveq %0,%%d7"              "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #1"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    :                   /* outputs */    \
    : "g"(_CLRSCREEN)    /* inputs */    \
    : "%d7"    /* clobbered regs */ \
    );
}

static inline __attribute__((always_inline)) uint32_t gp_system(void) {
   uint32_t systeminfo=0u;
   asm volatile(
    "# asm"                      "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "movew %1,%%d7"              "\n\t" \
    "trap #1"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    "movel %%d0,%0"              "\n\t" \
    : "=g"(systeminfo)        /* outputs */    \
    : "g"(_SYSTEM)            /* inputs */    \
    : "d0","d7"             /* clobbered regs */ \
   );
   return systeminfo;
}

static inline __attribute__((always_inline)) void gp_setflip(const uint8_t two_page, const uint8_t four_page) {
  asm volatile(
    "# asm"                      "\n\t" \
    "moveb %1,%%d0"              "\n\t" \
    "moveb %2,%%d1"              "\n\t" \
    "moveq %0,%%d7"              "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #1"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    :                   /* outputs */    \
    : "g"(_SETFLIP),"d"(two_page),"d"(four_page)   /* inputs */    \
    : "%d0","%d1","%d7"             /* clobbered regs */ \
    );
}

static inline __attribute__((always_inline)) void gp_cursor_off(void) {
  asm volatile(
    "# asm"                      "\n\t" \
    "moveq %0,%%d7"              "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #1"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    :                   /* outputs */    \
    : "g"(_CUROFF)      /* inputs */    \
    : "%d7"             /* clobbered regs */ \
    );
}

static inline __attribute__((always_inline)) void gp_cursor_on(void) {
  asm volatile(
    "# asm"                      "\n\t" \
    "moveq %0,%%d7"              "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #1"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    :                   /* outputs */    \
    : "g"(_CURON)       /* inputs */    \
    : "%d7"             /* clobbered regs */ \
    );
}

static inline __attribute__((always_inline)) void gp_writexy(uint16_t x, uint16_t y, uint8_t size, const char* const p_str) {
  asm volatile(
    "# asm"                      "\n\t" \
    "moveq %0,%%d7"              "\n\t" \
    "moveb %4,%%d0"              "\n\t" \
    "movew %1,%%d1"              "\n\t" \
    "movew %2,%%d2"              "\n\t" \
    "moveal %3,%%a0"             "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #1"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    :                   /* outputs */    \
    : "g"(_WRITE),"g"(x), "g"(y), "g"(p_str), "d"(size)    /* inputs */    \
    : "%d0","%d1","%d2","%d7","%a0"    /* clobbered regs */ \
    );
}

static inline __attribute__((always_inline)) void gp_setcurxy(const uint8_t x,const uint8_t y) {
  asm volatile(
    "# asm"                      "\n\t" \
    "moveb %1,%%d1"              "\n\t" \
    "moveb %2,%%d2"              "\n\t" \
    "moveq %0,%%d7"              "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #1"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    :                   /* outputs */    \
    : "g"(_SETCURXY), "d"(x),"d"(y)    /* inputs */    \
    : "%d1", "%d2", "%d7"    /* clobbered regs */ \
    );
}

static inline __attribute__((always_inline)) void gp_getcurxy(uint8_t* const p_x, uint8_t* const p_y) {
  register uint8_t x  __asm__("%d1") =0;
  register uint8_t y  __asm__("%d2") =0;
  asm volatile(
    "# asm"                      "\n\t" \
    "moveq %2,%%d7"              "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #1"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    : "=g"(x),"=g"(y)              /* outputs */    \
    : "g"(_GETCURXY)               /* inputs */    \
    : "%d7"          /* clobbered regs */ \
    );
    *p_x = x;
    *p_y = y;
}

#define L_BUTTON 0x80u
#define R_BUTTON 0x40u

static inline __attribute__((always_inline)) uint8_t gp_get_mouse(int16_t* const p_x, int16_t* const p_y){
  register uint8_t keys  __asm__("%d0") =0;
  asm volatile(
    "# asm"                      "\n\t" \
    "moveq %3,%%d7"              "\n\t" \
    "moveq #0,%%d0"              "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #1"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    "moveb %%d0,%2"              "\n\t" \
    "movew %%d1,%0"              "\n\t" \
    "movew %%d2,%1"              "\n\t" \
    : "=g"(*p_x),"=g"(*p_y),"=d"(keys)     /* outputs */    \
    : "g"(_HARDCOPY)               /* inputs */    \
    : "%d1", "%d2", "%d7"          /* clobbered regs */ \
  );
  return (keys^(L_BUTTON | R_BUTTON)) & (L_BUTTON | R_BUTTON);
}

static inline __attribute__((always_inline)) void gp_progzge(const uint8_t* const p_char){
  asm volatile(
    "# asm"                      "\n\t" \
    "moveq %0,%%d7"              "\n\t" \
    "moveal %1,%%a0"             "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #1"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    :                              /* outputs */    \
    : "g"(_PROGZGE),"g"(p_char)    /* inputs */    \
    : "%a0","%d7"                  /* clobbered regs */ \
  );
}

static inline __attribute__((always_inline)) void gp_sound(const uint8_t* const p_table){
  asm volatile(
    "# asm"                      "\n\t" \
    "moveq %0,%%d7"              "\n\t" \
    "moveal %1,%%a0"             "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #1"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    :                              /* outputs */    \
    : "g"(_SOUND),"g"(p_table)    /* inputs */    \
    : "%a0","%d7"                  /* clobbered regs */ \
  );
}

static inline __attribute__((always_inline)) int16_t gp_sin(int16_t angle) {
   register int16_t result  __asm__("%d0") =0;
   asm volatile(
    "# asm"                      "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "moveq %1,%%d7"              "\n\t" \
    "movew %2,%%d0"              "\n\t" \
    "trap #1"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    "movew %%d0,%0"              "\n\t" \
    : "=g"(result)          /* outputs */    \
    : "g"(_SIN),"g"(angle)  /* inputs */    \
    : "d7"             /* clobbered regs */ \
   );
   return result;
}

static inline __attribute__((always_inline)) int16_t gp_cos(int16_t angle) {
   register int16_t result  __asm__("%d0") =0;
   asm volatile(
    "# asm"                      "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "moveq %1,%%d7"              "\n\t" \
    "movew %2,%%d0"              "\n\t" \
    "trap #1"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    "movew %%d0,%0"              "\n\t" \
    : "=g"(result)          /* outputs */    \
    : "g"(_COS),"g"(angle)  /* inputs */    \
    : "d7"             /* clobbered regs */ \
   );
   return result;
}

//#ifdef USE_JADOS

static inline __attribute__((always_inline)) uint32_t jd_getversi(void) {
  //uint32_t jados_version = 0;
  register uint32_t jados_version __asm__("%d0") =0;
  asm volatile(
    "# asm"                      "\n\t" \
    "movem.l %%d2/%%d7/%%a5-%%a6,-(%%sp)"  "\n\t" \
    "moveq %1,%%d7"              "\n\t" \

    "trap #6"                    "\n\t" \
    "movem.l (%%sp)+, %%d2/%%d7/%%a5-%%a6" "\n\t" \
    /*"move.l %%d0,%0" */            "\n\t" \
    : "=r"(jados_version)        /* outputs */    \
    : "g"(__getversi)    /* inputs */    \
    : "d7"             /* clobbered regs */ \
    );
  return jados_version;
}

static inline __attribute__((always_inline)) uint8_t jd_directory(char * const p_buf, const char * const p_pattern, uint8_t attrib, uint16_t columns, uint16_t size) {
  register uint8_t ret  __asm__("%d0") = 0u;
  asm volatile(
    "# asm"                      "\n\t" \
    "moveq %1,%%d7"              "\n\t" \
    "moveal %2,%%a0"               "\n\t" \
    "moveal %3,%%a1"               "\n\t" \
    "moveb %4,%%d2"                "\n\t" \
    "movew %5,%%d3"                "\n\t" \
    "movew %6,%%d1"                "\n\t" \
    "movem.l %%d4/%%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #6"                    "\n\t" \
    "movem.l (%%sp)+, %%d4/%%a5-%%a6" "\n\t" \
    /*"move.b %%d0,%0" */            "\n\t" \
    : "=r"(ret)        /* outputs */    \
    : "g"(__directory),"g"(p_buf),"g"(p_pattern),"d"(attrib),"g"(columns),"g"(size)    /* inputs */    \
    : "d1","d2","d3","d7","a0","a1"             /* clobbered regs */ \
    );
    return ret;

}

  #define JD_BLOCKSIZE 1024u

// Disks and Drives
  #define DISK_RAM 0u
  #define DISK_1  1u
  #define DISK_2  2u
  #define DISK_3  3u
  #define DISK_4  4u
  #define DISK_A  5u
  #define DISK_B  6u
  #define DISK_C  7u
  #define DISK_D  8u
  #define DISK_E  9u
  #define DISK_F  10u
  #define DISK_G  11u
  #define DISK_H  12u
  #define DISK_I  13u

//
static inline __attribute__((always_inline)) void jd_set_drive(const uint16_t drive) {
  asm volatile(
    "# asm"                           "\n\t" \
    "movem.l %%d7/%%a5-%%a6,-(%%sp)"  "\n\t" \
    "moveq %0,%%d7"                   "\n\t" \
    "movew %1,%%d0"                   "\n\t" \
    "trap #6"                         "\n\t" \
    "movem.l (%%sp)+, %%d7/%%a5-%%a6" "\n\t" \
    :                               /* outputs */    \
    : "g"(__setdrive),"g"(drive)    /* inputs */    \
    : "d0","d7"                     /* clobbered regs */ \
    );
}

static inline __attribute__((always_inline)) uint16_t jd_get_drive(void)
{
   register uint16_t ret  asm("%d0") = 0u;
  asm volatile(
    "# asm"                      "\n\t" \
    "moveq %1,%%d7"              "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #6"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    : "=r"(ret)                   /* outputs */    \
    : "g"(__getdrive)             /* inputs */    \
    : "d7"                        /* clobbered regs */ \
    );
    return ret;
}

/* FCB */
struct jdfcb{
	uint16_t 	lw;		/* 00..01 */
	char 		filename[8];	/* 02..09 */
	uint16_t 	reserverd01;	/* 10..11 */
	char 		fileext[3];	/* 12..14 */
	uint8_t	reserved02;	/* 15 	  */
	uint16_t 	starttrack;	/* 16..17 */ // number of first track
	uint16_t 	endsec;		/* 18..19 */ // number of last sector in last track  (track relative ! 10 sectors/track with HD and 5 sec/track with FD))
	uint16_t 	endbyte;	/* 20..21 */ // always 0
	unsigned int	date;		/* 22..25 */
	uint16_t 	length;		/* 26..27 */ // filelength in sectors
	uint8_t	mode;		/* 28     */ // 0xE4 read only, 0xE5 read/write (not used correctly in current JADOS (always 0xE5)!!)
	uint16_t 	reserved03;	/* 29..30 */
	uint8_t  reserved04;	/* 31     */
	uint16_t  dirsec;		/* 32..33 */
	uint16_t  dirbyte;	/* 34..35 */
	uint16_t  status;		/* 36..37 */
	uint16_t  curtrack;	/* 38..39 */ // current track (Track-Relativ !)
	uint16_t  cursec;		/* 40..41 */ // current sector in current track (track relative)
	uint16_t  lasttrack;	/* 42..43 */ // last track
	uint8_t  *pbuffer;	/* 44..47 */
}__attribute__ ((packed));				/* otherwise datafields would be aligned ... */
typedef struct jdfcb jdfcb_t ;

static inline __attribute__((always_inline)) uint8_t jd_fillfcb(jdfcb_t * const p_FCB, const char * const p_name)
{
   register uint8_t ret  asm("%d0") = 0u;
  asm volatile(
    "# asm"                      "\n\t" \
    "moveq %1,%%d7"              "\n\t" \
    "moveal %4,%%a0"             "\n\t" \
    "moveal %3,%%a1"             "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #6"                    "\n\t" \
    "moveq %2,%%d7"              "\n\t" \
    "trap #6"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    : "=r"(ret)        /* outputs */    \
    : "g"(__uppercas),"g"(__fillfcb),"g"(p_FCB),"g"(p_name)    /* inputs */    \
    : "d7","a0","a1"             /* clobbered regs */ \
    );
    return ret;
}

static inline __attribute__((always_inline)) uint8_t jd_open(jdfcb_t * const p_FCB)
{
   register uint8_t ret  asm("%d0") = 0u;
  asm volatile(
    "# asm"                      "\n\t" \
    "moveq %1,%%d7"              "\n\t" \
    "moveal %2,%%a1"             "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #6"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    : "=r"(ret)                /* outputs */    \
    : "g"(__open),"g"(p_FCB)   /* inputs */    \
    : "d7","a1"                /* clobbered regs */ \
    );
    return ret;
}

static inline __attribute__((always_inline)) void jd_close(jdfcb_t * const p_FCB)
{
  asm volatile(
    "# asm"                      "\n\t" \
    "moveq %0,%%d7"              "\n\t" \
    "moveal %1,%%a1"             "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #6"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    :                           /* outputs */    \
    : "g"(__close),"g"(p_FCB)   /* inputs */    \
    : "d7","a1"                /* clobbered regs */ \
    );
}

static inline __attribute__((always_inline)) uint8_t jd_readrec(jdfcb_t * const p_FCB)
{
   register uint8_t ret  asm("%d0") = 0u;
  asm volatile(
    "# asm"                      "\n\t" \
    "moveq %1,%%d7"              "\n\t" \
    "moveal %2,%%a1"             "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #6"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    : "=r"(ret)                   /* outputs */    \
    : "g"(__readrec),"g"(p_FCB)   /* inputs */    \
    : "d7","a1"                   /* clobbered regs */ \
    );
    return ret;
}

static inline __attribute__((always_inline)) void jd_setdta(jdfcb_t * const p_FCB, void * const p_buf)
{
  asm volatile(
    "# asm"                      "\n\t" \
    "moveq %0,%%d7"              "\n\t" \
    "moveal %1,%%a1"             "\n\t" \
    "moveal %2,%%a0"             "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #6"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    :                                        /* outputs */    \
    : "g"(__setdta),"g"(p_FCB),"g"(p_buf)   /* inputs */    \
    : "d7","a0","a1"                         /* clobbered regs */ \
    );
}

static inline __attribute__((always_inline)) uint8_t jd_writerec(jdfcb_t * const p_FCB)
{
   register uint8_t ret  asm("%d0") = 0u;
  asm volatile(
    "# asm"                      "\n\t" \
    "moveq %1,%%d7"              "\n\t" \
    "moveal %2,%%a1"             "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #6"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    : "=r"(ret)                   /* outputs */    \
    : "g"(__writerec),"g"(p_FCB)   /* inputs */    \
    : "d7","a1"                   /* clobbered regs */ \
    );
    return ret;
}

struct jd_fi_date {
  uint8_t reserved;
  uint16_t year;
  uint8_t month;
  uint8_t day;
} __attribute__ ((packed));
typedef struct jd_fi_date jd_fi_date_t;

struct jdfile_info {
	uint32_t length;
  /*union {
    jd_fi_date_t date;
    uint32_t date_l;
  } __attribute__ ((packed));*/
  //uint8_t date[4];
  uint32_t date;
  uint8_t attribute;
} __attribute__ ((packed));				/* otherwise datafields would be aligned ... */
typedef struct jdfile_info jdfile_info_t;

struct jddisk_info {
  uint32_t o_tracks;
  uint32_t f_tracks;
  uint32_t o_entries;
  uint32_t f_entries;
  uint32_t o_secs;
  uint32_t f_secs;
  uint32_t f_bytes;
} __attribute__ ((packed));				/* otherwise datafields would be aligned ... */
typedef struct jddisk_info jddisk_info_t;

static inline __attribute__((always_inline)) uint8_t jd_fileinfo(jdfcb_t * const p_FCB, volatile jdfile_info_t * p_info)
{
  register uint8_t ret asm("%d0");
  register uint32_t length asm("%d1");
  register uint32_t date asm("%d2");
  register uint8_t attribute asm("%d3");

  asm volatile(
    "# asm"                      "\n\t" \
    "moveq %4,%%d7"              "\n\t" \
    "moveal %5,%%a1"             "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #6"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    : "=r"(ret),"=r"(length),"=r"(date),"=r"(attribute)        /* outputs */    \
    : "g"(__fileinfo),"g"(p_FCB)    /* inputs */    \
    : "d7","a1"             /* clobbered regs */ \
    );
    p_info->length = length;
    p_info->date  = date;
    p_info->attribute = attribute;
    return ret;
}

static inline __attribute__((always_inline)) uint8_t jd_diskinfo(const uint8_t disk, jddisk_info_t ** const pp_info)
{
  register uint8_t ret asm("%d0");
  register uint32_t ptr asm("%a0");
  asm volatile(
    "# asm"                      "\n\t" \
    "moveq %1,%%d7"              "\n\t" \
    "moveb %2,%%d4"              "\n\t" /*disk*/ \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #6"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    : "=r"(ret)                   /* outputs */    \
    : "g"(__diskinfo),"d"(disk)   /* inputs */    \
    : "d4","d7","a0"              /* clobbered regs */ \
    );
    *pp_info = (jddisk_info_t * const)ptr;
    return ret;
}

static inline __attribute__((always_inline)) void jd_get_disks(volatile uint8_t * const p_info)
{
  asm volatile(
    "# asm"                      "\n\t" \
    "moveq %0,%%d7"              "\n\t" \
    "moveal %1,%%a0"             "\n\t" /*p_info*/ \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #6"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    :                                 /* outputs */    \
    : "g"(__getdisks),"g"(p_info)     /* inputs */    \
    : "d7","a0"                       /* clobbered regs */ \
    );
}

static inline __attribute__((always_inline)) uint8_t jd_fileload(jdfcb_t * const p_FCB,void * const p_buf)
{
   register uint8_t ret  asm("%d0") = 0u;
  asm volatile(
    "# asm"                      "\n\t" \
    "moveq %1,%%d7"              "\n\t" \
    "moveal %3,%%a0"             "\n\t" \
    "moveal %2,%%a1"             "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #6"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    /*"moveb %%d0,%0" */             "\n\t" \
    : "=r"(ret)                                /* outputs */    \
    : "g"(__fileload),"g"(p_FCB),"g"(p_buf)    /* inputs */    \
    : "d7","a0","a1"                      /* clobbered regs */ \
    );
    return ret;
}

static inline __attribute__((always_inline)) uint8_t jd_filesave(jdfcb_t * const p_FCB,const void * const p_buf, const size_t length)
{
   register uint8_t ret  asm("%d0") = 0u;
   uint16_t nr_blocks = (uint16_t)((JD_BLOCKSIZE-1u+length)/JD_BLOCKSIZE)-1u;
  asm volatile(
    "# asm"                      "\n\t" \
    "moveq %1,%%d7"              "\n\t" \
    "moveal %3,%%a0"             "\n\t" \
    "moveal %2,%%a1"             "\n\t" \
    "movew %4,%%d1"              "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #6"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    /*"moveb %%d0,%0" */             "\n\t" \
    : "=r"(ret)                                /* outputs */    \
    : "g"(__filesave),"g"(p_FCB),"g"(p_buf),"g"(nr_blocks)   /* inputs */    \
    : "d7","a0","a1"                      /* clobbered regs */ \
    );
    return ret;
}

static inline __attribute__((always_inline)) uint8_t jd_copyfile(jdfcb_t * const p_FCB_src, jdfcb_t * const p_FCB_dst, uint8_t * const p_copy_bfr)
{
   register uint8_t ret  asm("%d0") = 0u;
  asm volatile(
    "# asm"                      "\n\t" \
    "moveq %1,%%d7"              "\n\t" \
    "moveal %4,%%a0"             "\n\t" \
    "moveal %2,%%a1"             "\n\t" \
    "moveal %3,%%a2"             "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #6"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    : "=r"(ret)                                /* outputs */    \
    : "g"(__copyfile),"g"(p_FCB_src),"g"(p_FCB_dst),"g"(p_copy_bfr)   /* inputs */    \
    : "d7","a0","a1","a2"                     /* clobbered regs */ \
    );
    return ret;
}

static inline __attribute__((always_inline)) uint8_t jd_create(jdfcb_t * const p_FCB)
{
   register uint8_t ret  asm("%d0") = 0u;
  asm volatile(
    "# asm"                      "\n\t" \
    "moveq %1,%%d7"              "\n\t" \
    "moveal %2,%%a1"             "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #6"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    : "=r"(ret)                   /* outputs */    \
    : "g"(__create),"g"(p_FCB)   /* inputs */    \
    : "d7","a1"                   /* clobbered regs */ \
    );
    return ret;
}

static inline __attribute__((always_inline)) uint8_t jd_erase(jdfcb_t * const p_FCB)
{
   register uint8_t ret  asm("%d0") = 0u;
  asm volatile(
    "# asm"                      "\n\t" \
    "moveq %1,%%d7"              "\n\t" \
    "moveal %2,%%a1"             "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #6"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    : "=r"(ret)                   /* outputs */    \
    : "g"(__erase),"g"(p_FCB)     /* inputs */    \
    : "d7","a1"                   /* clobbered regs */ \
    );
    return ret;
}


static inline __attribute__((always_inline)) uint8_t jd_blockread(jdfcb_t * const p_FCB,const void * const p_buf, const size_t length)
{
   register uint8_t ret  asm("%d0") = 0u;
   uint16_t nr_blocks = (uint16_t)((JD_BLOCKSIZE-1u+length)/JD_BLOCKSIZE)-1u;
  asm volatile(
    "# asm"                      "\n\t" \
    "moveq %1,%%d7"              "\n\t" \
    "moveal %3,%%a0"             "\n\t" \
    "moveal %2,%%a1"             "\n\t" \
    "movew %4,%%d2"              "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #6"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    : "=r"(ret)                                /* outputs */    \
    : "g"(__blockread),"g"(p_FCB),"g"(p_buf),"g"(nr_blocks)   /* inputs */    \
    : "d2","d7","a0","a1"                      /* clobbered regs */ \
    );
    return ret;
}

static inline __attribute__((always_inline)) uint8_t jd_blockwrite(jdfcb_t * const p_FCB,const void * const p_buf, const uint16_t nr_blocks)
{
   register uint8_t ret  asm("%d0") = 0u;
   //uint16_t nr_blocks = (uint16_t)((JD_BLOCKSIZE-1u+length)/JD_BLOCKSIZE);
  asm volatile(
    "# asm"                      "\n\t" \
    "moveq %1,%%d7"              "\n\t" \
    "moveal %3,%%a0"             "\n\t" \
    "moveal %2,%%a1"             "\n\t" \
    "movew %4,%%d2"              "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #6"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    : "=r"(ret)                                /* outputs */    \
    : "g"(__blockwrit),"g"(p_FCB),"g"(p_buf),"g"(nr_blocks)   /* inputs */    \
    : "d2","d7","a0","a1"                      /* clobbered regs */ \
    );
    return ret;
}

static inline __attribute__((always_inline)) uint8_t jd_setrec(jdfcb_t * const p_FCB, const uint16_t block)
{
   register uint8_t ret  asm("%d0") = 0u;
  asm volatile(
    "# asm"                      "\n\t" \
    "moveq %1,%%d7"              "\n\t" \
    "moveal %2,%%a1"             "\n\t" \
    "movew %3,%%d1"              "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #6"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    : "=r"(ret)                               /* outputs */    \
    : "g"(__setrec),"g"(p_FCB),"g"(block)     /* inputs */    \
    : "d1","d7","a1"                          /* clobbered regs */ \
    );
    return ret;
}

static inline __attribute__((always_inline)) uint8_t jd_chmode(jdfcb_t * const p_FCB, const uint8_t attrib)
{
   register uint8_t ret  asm("%d0") = 0u;
  asm volatile(
    "# asm"                      "\n\t" \
    "moveq %1,%%d7"              "\n\t" \
    "moveb %3,%%d1"              "\n\t" /* attrib */ \
    "moveal %2,%%a1"             "\n\t" /* FCB */ \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #6"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    : "=r"(ret)                                /* outputs */    \
    : "g"(__chmod),"g"(p_FCB),"d"(attrib)   /* inputs */    \
    : "d1","d7","a1"                      /* clobbered regs */ \
    );
    return ret;
}

static inline __attribute__((always_inline)) void jd_clrovwrt(void)
{
  asm volatile(
    "# asm"                      "\n\t" \
    "moveq %0,%%d7"              "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #6"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    :                   /* outputs */    \
    : "g"(__clrovwrt)   /* inputs */    \
    : "d7"              /* clobbered regs */ \
    );
}

static inline __attribute__((always_inline)) void jd_setovwrt(void)
{
  asm volatile(
    "# asm"                      "\n\t" \
    "moveq %0,%%d7"              "\n\t" \
    "movem.l %%a5-%%a6,-(%%sp)"  "\n\t" \
    "trap #6"                    "\n\t" \
    "movem.l (%%sp)+, %%a5-%%a6" "\n\t" \
    :                   /* outputs */    \
    : "g"(__setovwrt)   /* inputs */    \
    : "d7"              /* clobbered regs */ \
    );
}




//#endif



#endif


