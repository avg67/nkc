/*- AY3-8910 Soundchip definitions
 *
 * Copyright (C) 2021	Andreas Voggeneder
 */
/*-
 * Date		Version	Action						Who
 * 06.08.2021	1.00	created				    avg
 */
#ifndef SOUNDCHIP_H
#define SOUNDCHIP_H
#include <stdint.h>

#ifndef SOUNDCHIP_PADDING
#ifdef PADDING
#define SOUNDCHIP_PADDING PADDING
#else
#error "padding not defined"
#endif
#endif

#if SOUNDCHIP_PADDING == 0
#define _(x) volatile unsigned char (x);
#else
#define _(x) volatile unsigned char (x); unsigned char _pad_ ## x [SOUNDCHIP_PADDING];
#endif

typedef struct  {
    _(cmd0)
    _(cmd1)
} SOUNDCHIP;

enum {CHANNEL_A_FINE = 0, CHANNEL_A_COARSE = 1, 
			CHANNEL_B_FINE = 2, CHANNEL_B_COARSE = 3, 
			CHANNEL_C_FINE = 4, CHANNEL_C_COARSE = 5, 
			NOISE_PERIOD = 6, 
			MIXER_CONTROL = 7, 
			AMP_CHANNEL_A = 8,  AMP_CHANNEL_B = 9,    AMP_CHANNEL_C = 10, 
			ENVELOPE_FINE = 11, ENVELOPE_COARSE = 12, ENVELOPE_SHAPE = 13, 
			IOportA = 14,       IOportB = 15} 
			AYregister;

enum {TONE_CHANNEL_A = 0, TONE_CHANNEL_B = 1, TONE_CHANNEL_C = 2,
			NOISE_CHANNEL  = 3, ENVELOPE       = 4, 
			IO_A           = 5, IO_B           = 6} 
			AYchannel;

typedef struct {

  //Tone Generator Control
  uint8_t channelAfine;    //R0 - Channel A Tone Period 8 bit Fine
  uint8_t channelAcoarse;  //R1 - Channel B Tone Period 4 bit Coarse
  uint8_t channelBfine;    //R2 - Channel A Tone Period 8 bit Fine
  uint8_t channelBcoarse;  //R3 - Channel B Tone Period 4 bit Coarse
  uint8_t channelCfine;    //R4 - Channel A Tone Period 8 bit Fine
  uint8_t channelCcoarse;  //R5 - Channel B Tone Period 4 bit Coarse
  
  //Noise Generator Control
  uint8_t noisePeriod;     //R6 - 5 bit Noise Period
  
  //Mixer Control
  uint8_t mixerControl;    //R7 - Mixer Control bits: IOB/IOA/C/B/A/C/B/A
  
  //Amplitude Control
  uint8_t ampChannelA;     //R8 - Channel A -EVVVV
  uint8_t ampChannelB;     //R9 - Channel B -EVVVV
  uint8_t ampChannelC;     //R10 - Channel C -EVVVV
  
  //Envelope Generator Control
  uint8_t envelopeFine;    //R11 - Envelope Period Control 8 bit Fine
  uint8_t envelopeCoarse;  //R12 - Envelope Period Control 8 bit Coarse
  uint8_t envelopeShape;   //R13 - Envelope Shape Control CONT/ATT/ALT/HOLD
  
  //IO
  //uint8_t IOportA;         //R14 - Parallel IO Port A 8bit
  //uint8_t IOportB;         //R15 - Parallel IO Port B 8bit (AY-3-8912 only)

} AYregisterSet;

#undef _

#endif