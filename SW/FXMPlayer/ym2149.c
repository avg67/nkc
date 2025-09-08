#include "ym2149.h"

#include <util/delay.h>
#include <avr/io.h>

// +5V is connected to BC2
#if defined(ARDUINO_AVR_MEGA2560)
// MSB (PA1) is connected to BDIR
// LSB (PA0) is connected to BC1
#define DATA_READ 0x01
#define DATA_WRITE 0x02
#define ADDRESS_MODE 0x03
#else
// MSB (PB3) is connected to BDIR
// LSB (PB2) is connected to BC1
#define DATA_READ (0x01 << 2)
#define DATA_WRITE (0x02 << 2)
#define ADDRESS_MODE (0x03 << 2)
#endif

// Sets a 4MHz clock OC2A (PORTB3)
void set_ym_clock(void) {
#ifndef ARDUINO_AVR_MEGA2560
  // PB3 - output
  DDRB |= 0x01 << PORTB3;
  // Set Timer 2 CTC mode with no prescaling. OC2A toggles on compare match
  //
  // WGM22:0 = 010: CTC Mode, toggle OC
  // WGM2 bits 1 and 0 are in TCCR2A,
  // WGM2 bit 2 is in TCCR2B
  // COM2A0 sets OC2A (arduino pin 11 on Uno or Duemilanove) to toggle on compare match
  //
  TCCR2A = ((1 << WGM21) | (1 << COM2A0));
  
  // Set Timer 2 No prescaling (i.e. prescale division = 1)
  //
  // CS22:0 = 001: Use CPU clock with no prescaling
  // CS2 bits 2:0 are all in TCCR2B
  TCCR2B = (1 << CS20);
  
  // Make sure Compare-match register A interrupt for timer2 is disabled
  TIMSK2 = 0;

  // Divide the 16MHz clock by 8 -> 2MHz
  OCR2A = 3;
#endif
}

void set_bus_ctl(void) {
#ifdef ARDUINO_AVR_MEGA2560
  DDRA |= 3;
#else
  DDRC |= 0x0c; // Bits 2 and 3
#endif
}

void set_data_out(void) {
#ifdef ARDUINO_AVR_MEGA2560
  DDRC = 0xff;
#else
  DDRC |= 0x03; // Bits 0 and 1
  DDRD |= 0xfc; // Bits 2 to 7
#endif
}

/*void set_data_in(void) {
  DDRC &= ~0x03; // Bits 0 and 1
  DDRD &= ~0xfc; // Bits 2 to 7
}*/

void set_address(char addr) {
  set_data_out();
#ifdef ARDUINO_AVR_MEGA2560
  PORTA = (PORTA & ~3) | ADDRESS_MODE;
  PORTC = addr;
#else
  PORTC = (PORTC & 0xf3) | ADDRESS_MODE;
  PORTC = (PORTC & 0xfc) | (addr & 0x03); // 2 first bits ont PORTC
  PORTD = (PORTD & 0x02) | (addr & 0xfc); // 6 last bits on PORTD
#endif
  _delay_us(1.); //tAS = 300ns
#ifdef ARDUINO_AVR_MEGA2560
  PORTA = (PORTA & ~3);
#else
  PORTC = (PORTC & 0xf3) /*INACTIVE*/ ;
#endif
  _delay_us(1.); //tAH = 80ns
}

void set_data(char data) {
  set_data_out();
#ifdef ARDUINO_AVR_MEGA2560
  PORTA = (PORTA & ~3) | DATA_WRITE;
  PORTC = data;
#else
  PORTC = (PORTC & 0xfc) | (data & 0x03); // 2 first bits ont PORTC
  PORTD = (PORTD & 0x02) | (data & 0xfc); // 6 last bits on PORTD
  PORTC = (PORTC & 0xf3) | DATA_WRITE;
#endif
  _delay_us(1.); // 300ns < tDW < 10us
#ifdef ARDUINO_AVR_MEGA2560
  PORTA = (PORTA & ~3);
#else
  PORTC = (PORTC & 0xf3) /*INACTIVE*/ ; // To fit tDW max
#endif
  _delay_us(1.); // tDH = 80ns
}

/*char get_data(void) {
  char data;
  set_data_in();
  PORTC = (PORTC & 0xf3) | DATA_READ;
  _delay_us(1.); // tDA = 400ns
  data = (PIND & 0xfc) | (PINB & 0x03);
  PORTC = (PORTC & 0xf3); // INACTIVE
  _delay_us(1.); // tTS = 100ns
  return data;
}*/

void send_data(char addr, char data) {
  set_address(addr);
  set_data(data);
}

/*char read_data(char addr) {
  set_address(addr);
  return get_data();
}*/

