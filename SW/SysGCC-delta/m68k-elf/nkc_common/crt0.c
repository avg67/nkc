/*-
 * Copyright (C) 1991	Andreas Voggeneder
 */
 
/*
 * Definitions:
 *
 * OPEN_STDIO : Open stdin, stdout and stderr.
 * USE_ENV_DEVICE : Check environment for "stdin", "stdout" and "stderr"
 *                          and open, if there is an entry.
 * STDIO_CLEANUP : Enables cleanup for buffered stdio at exit.
 * COPYDATA : backup data
 *
 */

//#define ndrcomp
//#define MINI

//#include <sys/a_out.h>
#include <sys/file.h>
#include <sys/path.h>
#include <stdio.h>
#ifdef ndrcomp
//#define OPa             (*(volatile unsigned char *)0x000fc000L)
#include <ndrcomp/target.h>
#include <sys/m68k.h>
#endif

#ifndef MINI
#define OPEN_STDIO 
#define USE_ENV_DEVICE
#define STDIO_CLEANUP
#endif

#ifdef OPEN_STDIO
 extern int _open(const char *name, int flags, ...);
 #ifdef USE_ENV_DEVICE 
//  #error "NO Envdevice!"
  #define OPEN_DEVICE(dev, flag) (getenv(dev) ? \
      (_open(getenv(dev), (flag)) < 0 ? _open(_device_ary.name, (flag)) : 0) : \
       _open(_device_ary.name, (flag)))
 #else
  #define OPEN_DEVICE(dev, flag) (_open(_device_ary.name, (flag)))
 #endif
#else
 #define OPEN_DEVICE(dev, flag)
#endif

extern void _init_dev();
extern void _cleanup();
extern char *getenv();

/*
 * _init_port is the hardware specific peripheral initialisation.
 */
#if defined ndrcomp
//	extern void	_init_port();
    char *args[5];
#endif

int
main(int argc, char **argp, char **envp);

//int _exit(int ret);

/*
 * Flag for data must copied
 */
#ifdef COPYDATA
int _copydata = -1;
#endif  
/*
 * Definition of standard C globals
 */
char **environ;
int errno;

/*
 * Top of static variables.
 */
char *_static_top;

/*
 * Top of memory, dummy.
 */
char *_mem_top;

/*
 * extern symbols of memory layout, generated from linker
 */
extern unsigned long _btext, _etext, copy_start, _edata, _end, __bss_start;
extern unsigned long hardware_init_hook, software_init_hook;
extern unsigned long __INIT_SECTION__,__FINI_SECTION__;
//_bdata

#if defined ndrcomp
    extern void	_init_port();
    unsigned long ram_top=0;
    static unsigned long stacksave=0;
    static const unsigned char jados_cmd[5]={25,42,43,46,47};
#endif
void _start(int stackmagi, char **argv, char **envp) __attribute__((__section__(".startup")));

void _start(int stackmagi, char **argv, char **envp)
{

//    unsigned long *src;
    unsigned long *dest;
//    char **cpp;
    long cnt;
//    static char *nix = (char *)0;
    extern char *_stdin_envname;	
    extern char *_stdout_envname;	
    extern char *_stderr_envname;	

    asm volatile ("movel #0,%a6");

/* 
 * copy datasegment 
 */
//    if(&_etext != &_bdata){
//    if(&_etext != &copy_start){
//      //	for(src = &_etext, dest = &_bdata; dest < &_edata;)
//      for(src = &_etext, dest = &copy_start; dest < &_edata;)
//            *dest++ = *src++; 
//#ifdef COPYDATA
//    } else {
//        if (_copydata) {
//          //          for(src = &_bdata, dest = &_end; src < &_edata;)
//          for(src = &copy_start, dest = &_end; src < &_edata;)
//                *dest++ = *src++; 
//            _copydata = 0;
//        } else {
//          //          for(src = &_end, dest = &_bdata; dest < &_edata;)
//          for(src = &_end, dest = &copy_start; dest < &_edata;)
//                *dest++ = *src++; 
//            _copydata = 0;
//	}
//#endif
//    }
    
/* 
 * clear bss 
 */
    for(dest = &__bss_start; dest < &_end;) *dest++ = 0;
/* 
 * After this pointer static and global variables are useble.
 */
    _static_top = (char *)&_end; 
#ifdef COPYDATA
    //    if (!_copydata) _static_top += (char *)&_edata - (char *)&_bdata;
    if (!_copydata) _static_top += (char *)&_edata - (char *)&copy_start;
#endif
/* 
 * Check if the stack is valid and count the arguments. 
 */

#if defined ndrcomp
    asm volatile(
    "movel %%a7,%0":"=r"(stacksave));
#endif

/*
 * initialize target specific stuff. Only execute these
 * functions it they exist.
 */
	asm   volatile(
  "# asm"						                              "\n\t"  \
	"lea	%0, %%a0"                                 "\n\t"  \
	"cmpaw	#0,%%a0"                                  "\n\t"  \
	"beqs	m4"                                       "\n\t"  \
	"jsr     (%%a0)"                                  "\n\t"  \
"m4: lea	%1, %%a0"                                 "\n\t"  \
	"cmpaw	#0,%%a0"                                  "\n\t"  \
	"beqs	m5"                                       "\n\t"  \
	"jsr     (%%a0)"                                  "\n\t"  \
"m5: " \
    :                 /* outputs */    \
    : "g"(hardware_init_hook),"g"(software_init_hook)  /* inputs */    \
    : "%a0"    /* clobbered regs */ \
    );

	asm   volatile(
  "# asm"						                              "\n\t"  \
	"lea	%0, %%a0"                                 "\n\t"  \
	"cmpaw	#0,%%a0"                                  "\n\t"  \
	"beqs	no_init"                                  "\n\t"  \
	"jsr     (%%a0)"                                  "\n\t"  \
"no_init:"                                         "\n\t"  \
    :                 /* outputs */    \
    : "g"(__INIT_SECTION__)  /* inputs */    \
    : "%a0"    /* clobbered regs */ \
    );

#if defined ndrcomp


//    OPa=0x55;
    
   asm   volatile(
    "# asm"						                     "\n\t"  \
    "moveq #62,%%d7" /* Ramtop ermitteln */          "\n\t"  \
    "movem.l %%a6,-(%%sp)"  /* destroyed by jados*/  "\n\t" \
    "trap #6"				                         "\n\t"  \
    "movem.l (%%sp)+, %%a6"                          "\n\t" \
    "move.l %%a0,%0"				                 "\n\t"  \
    : "=g" (ram_top)                /* outputs */    \
    :   /* inputs */    \
    : "%d7", "%a0"    /* clobbered regs */ \
    );

    asm   volatile(
    "# asm"						                    "\n\t"  \
    "movel %1,%%a1"     /* Pointer auf args */      "\n\t"  \
    "movel %2,%%a2"     /* Pointer auf jados_cmd */ "\n\t"  \
    "clrl %%d1"         /* Argumente Zaehlen */     "\n\t"  \
    "clrl %%d7"                                     "\n\t"  \
    "clrl %%d6"         /* Argumente Zaehlen */     "\n\t"  \
"m2: moveb %%a2@+,%%d7"                              "\n\t"  \
    "movem.l %%a6,-(%%sp)" /* destroyed by jados*/  "\n\t" \
    "trap #6"           /* Gesamte Commandline */   "\n\t"  \
    "movem.l (%%sp)+, %%a6"                          "\n\t" \
    "#movel %%a0,%%d0"   /* Pointer auf Cmdline */   "\n\t"  \
    "movel %%a0,%%a1@+"  /* Store to Args */         "\n\t"  \
    "tstb (%%a0)"                                   "\n\t"  \
    "beqs m1"                                       "\n\t"  \
    "addq #1,%%d6"                                  "\n\t"  \
    "cmpw %3,%%d6"                                  "\n\t"  \
    "bnes m2"                                       "\n\t"  \
"m1: movel %%d6,%0"                                 "\n\t"  \
    : "=g" (cnt)                /* outputs */    \
    : "g"(args),"g"(jados_cmd),"g"(sizeof(jados_cmd))  /* inputs */    \
    : "%d0","%d1", "%d6","%d7", "%a0","%a1","%a2"    /* clobbered regs */ \
    );
    
    
    argv=args;
//    envp=envr;
    envp=0; //NULL;

    _init_port();
#else
//    if(stackmagi == STACK_MAGIC)
//    for(cpp = argv, cnt = 0; *cpp++ != (char *)0; cnt++);
//    else
//        argv = envp = &nix, cnt = 0;
//    environ = envp;
///*
// * init the device structure for all channels
// */
//    _init_dev();
#endif
/* 
 * Open the 3 standardchannels, if defined.
 */
    //_REENT->_stdin=
    OPEN_DEVICE(_stdin_envname, O_RDONLY);
    //_REENT->_stdout=
    OPEN_DEVICE(_stdout_envname, O_WRONLY);
    //_REENT->_stderr=
    OPEN_DEVICE(_stderr_envname, O_WRONLY);
    /*setvbuf(stdin, NULL, _IONBF, 0);
    setvbuf(stdout, NULL, _IONBF, 0);
    setvbuf(stderr, NULL, _IONBF, 0);*/

#if defined ndrcomp

   asm("moveb %0,%%d0"::"g"(SC.status): "%d0");
   asm("moveb %0,%%d0"::"g"(SC.data): "%d0");
   main(cnt, argv, envp);
   //   VIA.ier=0;
   FPGAT1.ctrl=0;
   DISABLE_CPU_INTERRUPTS;
   SC.command |=0x1f;
   
#if 0
   asm   volatile(
  "#asm"                                           "\n\t"  \
	"lea	%0, %%a0"                                 "\n\t"  \
	"cmpaw	#0,%%a0"                                  "\n\t"  \
	"beqs	no_fini"                                  "\n\t"  \
	"jsr (%%a0)"                                    "\n\t"  \
"no_fini:"                                         "\n\t"  \
    :                 /* outputs */    \
    : "g"(__FINI_SECTION__)  /* inputs */    \
    : "%a0"    /* clobbered regs */ \
    );
#endif

#else
   //   exit(main(cnt, argv, envp));
#endif
   asm volatile("_exit_label:");
}

void _exit(int ret)
{
#ifdef STDIO_CLEANUP
    _cleanup();
#endif


#if defined ndrcomp

    FPGAT1.ctrl=0;
    DISABLE_CPU_INTERRUPTS;
    SC.command |=0x1f;
    
    /*
    * Returnvalue in register d0.
    */
//    asm("movel %0,%%d0" : : "g" (ret));
    asm volatile(
    "# asm"						                    "\n\t"  \
    "movel %0,%%d0"	                                "\n\t"  \
    "moveq #38,%%d7"                                "\n\t"  \
    "movem.l %%a6,-(%%sp)" /* destroyed by jados*/  "\n\t" \
    "trap #6"                                       "\n\t"  \
    "movem.l (%%sp)+, %%a6"                         "\n\t" \
    :                 /* outputs */    \
    : "g" (ret)       /* inputs */    \
    : /*"%d0","%d7"     clobbered regs */ \
    );
    
    asm volatile(
    "# asm"						             "\n\t"  \
    "movel %0,%%a7"	                         "\n\t"  \
    "moveml %%sp@+,%%d2/%%d6-%%d7/%%a2-%%a3" "\n\t"  \
    "rts"	                                 "\n\t"  \
    :                 /* outputs */    \
    : "g" (stacksave) /* inputs */    \
    :                 /* clobbered regs */ \
    );

#else
    asm("trap  #7");
#endif
    while(1) {};
}

