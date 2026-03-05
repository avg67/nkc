
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdbool.h>
#include "i2c.h"

void delayi2c(void) {
	asm("moveq #20,d0
dly1:   nop 
	dbra d0,dly1");
}

void I2cInit() {
	INTERN.sim.pfpar &=~(SCL|SDA);	//	0xf3;
	INTERN.sim.ddrf &= ~(SCL|SDA);	//0xf3;
	INTERN.sim.portf |=	(SCL|SDA);	//0x0c;
	stopi2c();
}

void sdah(void)
{
//	asm("bclrb #2,%0"::"g"(INTERN.sim.ddrf));
	INTERN.sim.ddrf &= ~SDA;		// SDA hochohmig
//	while(!(PDDATA & SDA));
	delayi2c();
}

void sdal(void)
{
//	asm("bclrb #2,%0"::"g"(INTERN.sim.portf));
//	asm("bsetb #2,%0"::"g"(INTERN.sim.ddrf));
	INTERN.sim.portf &= ~SDA;  // 
  	INTERN.sim.ddrf |= SDA;		// SDA low
	delayi2c();
}


void sclh(void)
{
//	asm("bclrb #3,%0"::"g"(INTERN.sim.ddrf));
	INTERN.sim.ddrf &= ~SCL;		// SCL hochohmig
	while(!(INTERN.sim.portf & SCL));
	delayi2c();
}


void scll(void)
{
//	asm("bclrb #3,%0"::"g"(INTERN.sim.portf));
//	asm("bsetb #3,%0"::"g"(INTERN.sim.ddrf));
	INTERN.sim.portf &= ~SCL;  // 
	INTERN.sim.ddrf |= SCL;		// SDA low
	delayi2c();
}

void starti2c(void)
{
	sdah();
	sclh();
    sdal();
    scll();
}

void stopi2c(void)
{
    scll();
    sdal();
    sclh();
    sdah();
}

void restarti2c( void )
{
    starti2c();
}
// sends one byte 
// returns true if ACK from slave is received, false if not.
bool sendbytei2c(uint8_t sb)
{
    uint8_t x;
    bool y;

    for (x=1;x<9;x++){
        if ((sb & 0x80)==0x80)
            sdah();
        else
            sdal();
        sb=sb<<1;
        sclh();
        scll();
    }
    sdah();
    sclh();
    if (INTERN.sim.portf & SDA)  // SDA einlesen
        y=false;
    else
        y=true;
    scll();
    return(y);
}
// Receives one byte. Parameter "letzte" needs to be set for last byte
uint8_t receivebytei2c(bool letzte)
{
    uint8_t x,y;

    sdah();
    y=0;
    for (x=1;x<9;x++){
        y=y<<1;
        sclh();
        if (INTERN.sim.portf & SDA)
            y++;
        scll();
    }
    if (letzte == true)
        sdah();
    else
        sdal();
    sclh();
    scll();
    sdah();
/*    printf("Byte %x",y); */
    return(y);
}

// Reads az bytes from I2C Slave and stores them to pBfr
// Return true if ACK from slave is received, false if not
bool receivei2c(uint8_t addr,uint8_t az,uint8_t *pBfr)
{
    bool letzte;
    uint8_t x;
    bool y;

    starti2c();
    if (sendbytei2c(addr)==false)
    {
        stopi2c();
        printf("no ack received at receivei2c\n");
        y=false;
    }
    else
    {
       letzte=false;
       for (x=1;x<(az+1);x++){
           if (x==az)
               letzte=true;
           *pBfr++=receivebytei2c(letzte);
       }
       stopi2c();
       y=true;
    }
    return(y);
}

// Sends Buffer pBfr with size az to I2C Slave 
// returns true if successful, false if failed (no ack from slave received)
bool sendi2c(uint8_t addr,uint8_t az,uint8_t const *pBfr)
{
    int i, c;
    uint8_t x,y;

    starti2c();
    if (sendbytei2c(addr)==false)
    {
        stopi2c();
        printf("no ack1 received at sendi2c\n");
        return false;
    }
    else
    {
      for (x=0;x<az;x++){
         if (!sendbytei2c(*pBfr++)) {
            stopi2c();
            printf("no ack received at sendi2c\n");
            return false;
         }
      }
      stopi2c();
    }
    return true;
}


