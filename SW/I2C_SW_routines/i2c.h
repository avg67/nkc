/* $Workfile:   I2C.h $                                        			    		*/
/* $Revision:   $                                                       			*/
/* $Author:     Andreas Voggeneder $                                    			*/
/* $Date:       09.08.2001 $														*/
/* Description: I2C Routinen									 					*/
/*																					*/
/* Remarks:     No remarks.                                             			*/


#ifndef ___I2C_H
#define ___I2C_H

#include <stdbool.h>

void I2cInit();
void sdah(void);
void sdal(void);
void sclh(void);
void scll(void);
void starti2c(void);
void stopi2c(void);
void restarti2c( void );
bool sendbytei2c(uint8_t sb);
uint8_t receivebytei2c(bool letzte);
bool receivei2c(uint8_t addr,uint8_t az,uint8_t *pBfr);
bool sendi2c(uint8_t addr,uint8_t az,uint8_t const *pBfr);

#endif