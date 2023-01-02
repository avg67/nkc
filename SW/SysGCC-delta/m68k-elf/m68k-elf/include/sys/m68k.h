
/*
 * m68k.h: some m68k processor family stuff
 */

#define ENABLE_CPU_INTERRUPTS asm("andi #0xf8ff,%sr")
#define DISABLE_CPU_INTERRUPTS asm("ori #0x700,%sr")
#define GET_STATUS_REGISTER(x) asm("move sr,%0" : "=d" (x) : "0" (x))
#define SET_STATUS_REGISTER(x) asm("move %0,sr" : : "d" (x))
#define EXCEPT_VEC(x)  (*(void (**)(void))((x) * 4))

