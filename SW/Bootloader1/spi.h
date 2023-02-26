
/*
 * Copyright (c) 2006-2008 by Roland Riegel <feedback@roland-riegel.de>
 *
 * This file is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#ifndef SPI_H
#define SPI_H

#include <stdint.h>

#define SPI_CFG                 0x82  // 10 MHZ
#define SPI_CFG_LOW             0x87  // 2 MHZ
#define SPI_CTRL  (*(volatile unsigned char *)(0xffffff00L*2))
#define SPI_DATA  (*(volatile unsigned char *)(0xffffff01L*2))

#define enc_select()            SPI_CTRL=(SPI_CFG | 0x10) //ENC_PORT &= ~(1<<ENC_CS)
#define enc_deselect()          SPI_CTRL=(SPI_CFG | 0x00) //ENC_PORT |= (1<<ENC_CS)
#define sd1_select()            SPI_CTRL=(SPI_CFG | 0x40) 
#define sd1_deselect()          SPI_CTRL=(SPI_CFG | 0x00) 

//void spi_init();

//void spi_send_byte(uint8_t b);
//uint8_t spi_rec_byte();

void spi_send_data(const uint8_t* data, uint16_t data_len);
void spi_rec_data(uint8_t* buffer, uint16_t buffer_len);

void spi_low_frequency();
void spi_high_frequency();

static inline __attribute__((always_inline))  void spi_init(void)
{
	// configure pins MOSI, SCK as output
/*	SPI_DDR |= (1<<SPI_MOSI) | (1<<SPI_SCK);
	// pull SCK high
	SPI_PORT |= (1<<SPI_SCK);

	// configure pin MISO as input
	SPI_DDR &= ~(1<<SPI_MISO);
	SPI_DDR |= (1<<SPI_SS);

	//SPI: enable, master, positive clock phase, msb first, SPI speed fosc/2
	SPCR = (1<<SPE) | (1<<MSTR);
	SPSR = (1<<SPI2X);
*/
  SPI_CTRL=SPI_CFG;
  //enc_deselect();
  //usdelay(10000);
}

static inline __attribute__((always_inline))  void spi_put( unsigned char value )
{
	//ENC_DEBUG("spi_put(%2x)\n\r", (unsigned) value );
//	SPDR = value;
//	while( !(SPSR & (1<<SPIF)) ) ;
  SPI_DATA=value;
  while(!(SPI_CTRL & 0x01));
}

static inline __attribute__((always_inline))  unsigned char spi_get(void)
{
	unsigned char value = SPI_DATA; //SPDR;
	//ENC_DEBUG("spi_get()=%2x\n\r", (unsigned) value );
	return value;
}

static inline __attribute__((always_inline)) uint8_t spi_rec_byte(void) {
    spi_put(0xff); 
    return spi_get();
}

static inline __attribute__((always_inline)) void spi_send_byte(uint8_t b)
{
    spi_put(b);
}
/**
 * @}
 * @}
 */

#endif

