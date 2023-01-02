#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <ndrcomp/target.h>
#include "../../nkc_common/nkc/nkc.h"
#include "sound.h"
#include "nkc_sound_notes.h"

#define ENV_PERIOD (781u*2) //100ms

void sound_playback(void);
bool g_sound_mute = false;

static inline __attribute__((always_inline)) void setSoundRegister(uint8_t reg, uint8_t value) {
  SOUND.cmd0 = reg;
  SOUND.cmd1 = value;
}

uint16_t note_lookup[]= {
  0xEEE,    // _C1 
  0xE17,    // _CS1
  0xD4D,    // _D1 
  0xC8E,    // _DS1
  0xBD9,    // _E1 
  0xB2F,    // _F1 
  0xA8E,    // _FS1
  0x9F7,    // _G1 
  0x968,    // _GS1
  0x8E0,    // _A1 
  0x861,    // _AS1
  0x7E8,    // _B1 
  0x777,    // _C2 
  0x70B,    // _CS2
  0x6A6,    // _D2 
  0x647,    // _DS2
  0x5EC,    // _E2 
  0x597,    // _F2 
  0x547,    // _FS2
  0x4FB,    // _G2 
  0x4B3,    // _GS2
  0x470,    // _A2 
  0x430,    // _AS2
  0x3F4,    // _B2 
  0x3BB,    // _C3 
  0x385,    // _CS3
  0x353,    // _D3 
  0x323,    // _DS3
  0x2F6,    // _E3 
  0x2CB,    // _F3 
  0x2A3,    // _FS3
  0x27D,    // _G3 
  0x259,    // _GS3
  0x238,    // _A3 
  0x218,    // _AS3
  0x1FA,    // _B3 
  0x1DD,    // _C4 
  0x1C2,    // _CS4
  0x1A9,    // _D4 
  0x191,    // _DS4
  0x17B,    // _E4 
  0x165,    // _F4 
  0x151,    // _FS4
  0x13E,    // _G4 
  0x12C,    // _GS4
  0x11C,    // _A4 
  0x10C,    // _AS4
  0xFD,    // _B4 
  0xEE,    // _C5 
  0xE1,    // _CS5
  0xD4,    // _D5 
  0xC8,    // _DS5
  0xBD,    // _E5 
  0xB2,    // _F5 
  0xA8,    // _FS5
  0x9F,    // _G5 
  0x96,    // _GS5
  0x8E,    // _A5 
  0x86,    // _AS5
  0x7E,    // _B5 
  0x77,    // _C6 
  0x70,    // _CS6
  0x6A,    // _D6 
  0x64,    // _DS6
  0x5E,    // _E6 
  0x59,    // _F6 
  0x54,    // _FS6
  0x4F,    // _G6 
  0x4B,    // _GS6
  0x47,    // _A6 
  0x43,    // _AS6
  0x3F,    // _B6 
  0x3B,    // _C7 
  0x38,    // _CS7
  0x35,    // _D7 
  0x32,    // _DS7
  0x2F,    // _E7 
  0x2C,    // _F7 
  0x2A,    // _FS7
  0x27,    // _G7 
  0x25,    // _GS7
  0x23,    // _A7 
  0x21,    // _AS7
  0x1F     // _B7 
};

void delay_ms(const uint16_t ms) ;

void SetAY_Register(const AYregisterSet * const p_reg){
#if 0
  setSoundRegister(ENVELOPE_SHAPE,p_reg->envelopeShape);
  setSoundRegister(ENVELOPE_COARSE,p_reg->envelopeCoarse);
  setSoundRegister(ENVELOPE_FINE,p_reg->envelopeFine);
  setSoundRegister(AMP_CHANNEL_C,p_reg->ampChannelC);
  setSoundRegister(AMP_CHANNEL_B,p_reg->ampChannelB);
  setSoundRegister(AMP_CHANNEL_A,p_reg->ampChannelA);
  setSoundRegister(MIXER_CONTROL,p_reg->mixerControl);
  setSoundRegister(NOISE_PERIOD,p_reg->noisePeriod);
  setSoundRegister(CHANNEL_C_COARSE,p_reg->channelCcoarse);
  setSoundRegister(CHANNEL_C_FINE,p_reg->channelCfine);
  setSoundRegister(CHANNEL_B_COARSE,p_reg->channelBcoarse);
  setSoundRegister(CHANNEL_B_FINE,p_reg->channelBfine);
  setSoundRegister(CHANNEL_A_COARSE,p_reg->channelAcoarse);
  setSoundRegister(CHANNEL_A_FINE,p_reg->channelAfine);
#endif  
  uint8_t const * p_mem = (uint8_t*const)&p_reg->envelopeShape;
  uint16_t i=ENVELOPE_SHAPE;
  do {
    setSoundRegister(i,*p_mem);
    p_mem--;
  }while(i--!=CHANNEL_A_FINE);

}

void silence(void) {
  
  //AYregisterSet s = {0x00, 0x00, 0x00, 0x00, 0x00 ,0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
  static const AYregisterSet s = { .channelAfine=0,
                      .channelAcoarse =0,
                      .channelBfine=0,
                      .channelBcoarse =0,
                      .channelCfine=0,
                      .channelCcoarse =0,
                      .noisePeriod =0,
                      .mixerControl = 0xFF,
                      .ampChannelA =0,
                      .ampChannelB =0,
                      .ampChannelC =0,
                      .envelopeFine =0,
                      .envelopeCoarse=0,
                      .envelopeShape=0};
  SetAY_Register(&s);
  
}

void initSound(void) {
  
  //init AY-3-891x
  silence();
  // Play sound in background Timer-driven
  _clock(&sound_playback);
}
/*
void playDrop(void) {
  setSoundRegister(ENVELOPE_SHAPE,4);     // R15 Set Envelop , one periode
  setSoundRegister(ENVELOPE_COARSE,20);   // R14 Set Envelope Periode
  setSoundRegister(AMP_CHANNEL_C,16);     // R12 Set Amplitude Range under direct control of Envelope Generator
  setSoundRegister(AMP_CHANNEL_B,16);     // R11 Set Amplitude Range under direct control of Envelope Generator
  setSoundRegister(AMP_CHANNEL_A,16);     // R10 Set Amplitude Range under direct control of Envelope Generator
  setSoundRegister(MIXER_CONTROL,7);      // R7 Enable Noise for Ch A-C
  setSoundRegister(NOISE_PERIOD,1);       // R6 Set Noise Periode to mid value
}*/

  static const uint8_t notes[]= {
    N_E5,   //1
    N_NONE,
    N_NONE,
    N_NONE,
    N_B4,
    N_NONE,
    N_C5,
    N_NONE,
    N_D5,
    N_NONE,
    N_E5,
    N_D5,
    N_C5,
    N_NONE,
    N_B4,
    N_NONE,
    N_A4,
    N_NONE,
    N_NONE,
    N_NONE,
    N_A4,
    N_NONE,
    N_C5,
    N_NONE,
    N_E5,
    N_NONE,

    N_NONE,   //2
    N_NONE,
    N_D5,
    N_NONE,
    N_C5,
    N_NONE,
    N_B4,
    N_NONE,
    N_NONE,
    N_NONE,
    N_B4,
    N_B4,
    N_C5,
    N_NONE,
    N_D5,
    N_NONE,
    N_NONE,
    N_NONE,
    N_E5,
    N_NONE,
    N_NONE,
    N_NONE,
    N_C5,
    N_NONE,
    N_NONE,
    N_NONE,

    N_A4,   //3
    N_NONE,
    N_NONE,
    N_NONE,
    N_A4,
    N_NONE,
    N_NONE,
    N_NONE,
    N_NONE,
    N_NONE,
    N_NONE,
    N_D5,
    N_NONE,
    N_NONE,
    N_NONE,
    N_D5,
    N_NONE,
    N_F5,
    N_NONE,
    N_A5,
    N_NONE,
    N_NONE,
    N_NONE,
    N_G5,
    N_NONE,

    N_F5,   //4
    N_NONE,
    N_E5,
    N_NONE,
    N_NONE,
    N_NONE,
    N_E5,
    N_NONE,
    N_C5,
    N_NONE,
    N_E5,
    N_NONE,
    N_NONE,
    N_NONE,
    N_D5,
    N_NONE,
    N_C5,
    N_NONE,
    N_B4,
    N_NONE,
    N_NONE,
    N_NONE,
    N_B4,
    N_B4,
    N_C5,
    N_NONE,

    N_D5,   //5
    N_NONE,
    N_NONE,
    N_NONE,
    N_E5,
    N_NONE,
    N_NONE,
    N_NONE,
    N_C5,
    N_NONE,
    N_NONE,
    N_NONE,
    N_A4,
    N_NONE,
    N_NONE,
    N_NONE,
    N_A4,
    N_NONE,
    N_NONE,
    N_NONE,
    N_NONE,
    N_NONE,
    N_NONE,
    N_NONE, // ev. Loop bis hier
#if 0
    N_E5,
    N_NONE,

    N_NONE,
    N_NONE,
    N_B4,
    N_NONE,
    N_C5,
    N_NONE,
    N_D5,
    N_E5,
    N_D5,
    N_C5,
    N_NONE,
    N_B4,
    N_NONE,
    N_A4,
    N_NONE,
    N_NONE,
    N_NONE,
    N_A4,
    N_NONE,
    N_C5,
    N_NONE,
    N_E5,
    N_NONE,
    N_NONE,

    N_D5,
    N_NONE,
    N_C5,
    N_NONE,
    N_B4,
    N_NONE,
    N_NONE,
    N_NONE,
    N_B4,
    N_NONE,
    N_C5,
    N_NONE,
    N_D5,
    N_NONE,
    N_NONE,
    N_NONE,
    N_E5,
    N_NONE,
    N_NONE,
    N_NONE,
    N_C5,
    N_NONE,
    N_NONE,
    N_NONE,
    N_A4,
    N_NONE,

    N_NONE,
    N_NONE,
    N_A4,
    N_NONE,
    N_NONE,
    N_NONE,
    N_NONE,
    N_NONE,
    N_NONE,
    N_NONE,
    N_D5,
    N_NONE,
    N_NONE,
    N_NONE,
    N_D5,
    N_NONE,
    N_F5,
    N_NONE,
    N_A5,
    N_NONE,
    N_NONE,
    N_NONE,
    N_G5,
    N_NONE,
    N_F5,
    N_NONE,

    N_E5,
    N_NONE,
    N_NONE,
    N_NONE,
    N_E5,
    N_NONE,
    N_C5,
    N_NONE,
    N_E5,
    N_NONE,
    N_NONE,
    N_NONE,
    N_D5,
    N_NONE,
    N_C5,
    N_NONE,
    N_B4,
    N_NONE,
    N_NONE,
    N_NONE,
    N_B4,
    N_NONE,
    N_C5,
    N_NONE,
    N_D5,
    N_NONE,
    
#endif

  };
#if 0
void playTest(void) {
/*  static const uint8_t pock_soundA[14*2] = {
    //A          B            C           |Noise  Mix   AmpA  AmpB  AmpC  Env   Env   Shape
    0x00, 0x00,  0x23, 0x08,  0x00, 0x00,   0x00, 0x00, 0x00, 11, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00,  0x23, 0x08,  0x00, 0x00,   0x00, 0x00, 0x00, 11, 0x00, 0x00, 0x00, 0x00,
    //0x00, 0x00,  0x23, 0x08,  0x00, 0x00,   0x00, 0x00, 0x00, 10, 0x00, 0x00, 0x00, 0x00
  };*/
/*   static const uint8_t sound_upFire_ChannelB[168] = {
    //A          B            C          |Noise   Mix   AmpA  AmpB  AmpC  Env   Env   Shape
    0x00, 0x00,  0x95, 0x05,  0x00, 0x00,   0x10, 0x00, 0x00, 0x0E, 0x00, 0x00, 0x00, 0x00, 
    0x00, 0x00,  0x45, 0x04,  0x00, 0x00,   0x10, 0x00, 0x00, 0x0E, 0x00, 0x00, 0x00, 0x00, 
    0x00, 0x00,  0x34, 0x03,  0x00, 0x00,   0x10, 0x00, 0x00, 0x0E, 0x00, 0x00, 0x00, 0x00, 
    0x00, 0x00,  0xcd, 0x02,  0x00, 0x00,   0x10, 0x00, 0x00, 0x0E, 0x00, 0x00, 0x00, 0x00, 
    0x00, 0x00,  0x25, 0x02,  0x00, 0x00,   0x10, 0x00, 0x00, 0x0D, 0x00, 0x00, 0x00, 0x00, 
    0x00, 0x00,  0xac, 0x01,  0x00, 0x00,   0x10, 0x00, 0x00, 0x0D, 0x00, 0x00, 0x00, 0x00, 
    0x00, 0x00,  0x6f, 0x01,  0x00, 0x00,   0x10, 0x00, 0x00, 0x0D, 0x00, 0x00, 0x00, 0x00, 
    0x00, 0x00,  0x47, 0x01,  0x00, 0x00,   0x10, 0x00, 0x00, 0x0C, 0x00, 0x00, 0x00, 0x00, 
    0x00, 0x00,  0x29, 0x01,  0x00, 0x00,   0x10, 0x00, 0x00, 0x0C, 0x00, 0x00, 0x00, 0x00, 
    0x00, 0x00,  0x04, 0x01,  0x00, 0x00,   0x10, 0x00, 0x00, 0x0C, 0x00, 0x00, 0x00, 0x00, 
    0x00, 0x00,  0xff, 0x00,  0x00, 0x00,   0x10, 0x00, 0x00, 0x0B, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00,  0xf1, 0x00,  0x00, 0x00,   0x10, 0x00, 0x00, 0x0B, 0x00, 0x00, 0x00, 0x00
  };*/
  /*static const uint8_t siren_440Hz[14*2] = {
    //0    1     2     3      4     5       6     7     8     9   10    11    12    13
    //A          B            C           |Noise  Mix   AmpA  AmpB  AmpC Env   Env   Shape
    0xFE, 0x00,  0x00, 0x00,  0x00, 0x00,   0x00, 0x3E, 0x0f, 0x00, 0x00, 0x00, 0x00, 0x00,
    28,   0x01,  0x00, 0x00,  0x00, 0x00,   0x00, 0x3E, 0x0f, 0x00, 0x00, 0x00, 0x00, 0x00
  };*/
  /*static const uint8_t tet_sound[26*14] = {
    //0    1     2     3      4     5     6     7     8     9    10    11    12    13
    //A          B            C          |Noise  Mix   AmpA  AmpB  AmpC Env   Env   Shape
    189,	0,  0x00, 0x00,  0x00, 0x00,   0x00, 0x3E, 0x0f, 0x00, 0x00, 0x00, 0x00, 0x00,
    000,	0,  0x00, 0x00,  0x00, 0x00,   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    000,	0,  0x00, 0x00,  0x00, 0x00,   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    000,	0,  0x00, 0x00,  0x00, 0x00,   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    253,	0,  0x00, 0x00,  0x00, 0x00,   0x00, 0x3E, 0x0f, 0x00, 0x00, 0x00, 0x00, 0x00,
    000,	0,  0x00, 0x00,  0x00, 0x00,   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    238,	0,  0x00, 0x00,  0x00, 0x00,   0x00, 0x3E, 0x0f, 0x00, 0x00, 0x00, 0x00, 0x00,
    000,	0,  0x00, 0x00,  0x00, 0x00,   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    212,	0,  0x00, 0x00,  0x00, 0x00,   0x00, 0x3E, 0x0f, 0x00, 0x00, 0x00, 0x00, 0x00,
    000,	0,  0x00, 0x00,  0x00, 0x00,   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    189,	0,  0x00, 0x00,  0x00, 0x00,   0x00, 0x3E, 0x0f, 0x00, 0x00, 0x00, 0x00, 0x00,
    212,	0,  0x00, 0x00,  0x00, 0x00,   0x00, 0x3E, 0x0f, 0x00, 0x00, 0x00, 0x00, 0x00,
    238,	0,  0x00, 0x00,  0x00, 0x00,   0x00, 0x3E, 0x0f, 0x00, 0x00, 0x00, 0x00, 0x00,
    000,	0,  0x00, 0x00,  0x00, 0x00,   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    253,	0,  0x00, 0x00,  0x00, 0x00,   0x00, 0x3E, 0x0f, 0x00, 0x00, 0x00, 0x00, 0x00,
    000,	0,  0x00, 0x00,  0x00, 0x00,   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    28,	  1,  0x00, 0x00,  0x00, 0x00,   0x00, 0x3E, 0x0f, 0x00, 0x00, 0x00, 0x00, 0x00,
    000,	0,  0x00, 0x00,  0x00, 0x00,   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    000,	0,  0x00, 0x00,  0x00, 0x00,   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    000,	0,  0x00, 0x00,  0x00, 0x00,   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    28,	  1,  0x00, 0x00,  0x00, 0x00,   0x00, 0x3E, 0x0f, 0x00, 0x00, 0x00, 0x00, 0x00,
    000,	0,  0x00, 0x00,  0x00, 0x00,   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    238,	0,  0x00, 0x00,  0x00, 0x00,   0x00, 0x3E, 0x0f, 0x00, 0x00, 0x00, 0x00, 0x00,
    000,	0,  0x00, 0x00,  0x00, 0x00,   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    189,	0,  0x00, 0x00,  0x00, 0x00,   0x00, 0x3E, 0x0f, 0x00, 0x00, 0x00, 0x00, 0x00,
    000,	0,  0x00, 0x00,  0x00, 0x00,   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
  };*/

  for(uint8_t x=0u;x<5u;x++)
  {
    for (uint16_t i = 0u; i < ARRAY_SIZE(notes); i++) 
    {
    //  iprintf("%u\r",(unsigned int)i);
      uint8_t ay_regs[14]={0u};
      if (notes[i]>0u) {
        const uint16_t note_val = note_lookup[notes[i] -  NOTES_OFFSET];
        ay_regs[0]= note_val & 0xffu;
        ay_regs[1]= (note_val >> 8u) & 0xffu;
        ay_regs[7]= 0x3Eu;
        ay_regs[8]= 0x1fu;
        ay_regs[11]= (ENV_PERIOD & 0xFFu);
        ay_regs[12]= ((ENV_PERIOD >> 8u) & 0xFFu);
      }
      for(uint16_t j=0u;j<14u;j++) {
        setSoundRegister(j,ay_regs[j]);
      }
      delay_ms(70);
    }
    //iprintf("\r\n");
    //delay_ms(1000);
  }
  silence();
}
#endif

void play_note(const bool init) {
  static uint16_t note_index = 0u;
  if (init) {
    note_index = 0u;
  }
  uint8_t ay_regs[14]={0u};
  if (notes[note_index]>0u) {
    const uint16_t note_val = note_lookup[notes[note_index] -  NOTES_OFFSET];
    ay_regs[0]= note_val & 0xffu;
    ay_regs[1]= (note_val >> 8u) & 0xffu;
    ay_regs[7]= 0x3Eu;
    ay_regs[8]= 0x1fu;
    ay_regs[11]= (ENV_PERIOD & 0xFFu);
    ay_regs[12]= ((ENV_PERIOD >> 8u) & 0xFFu);
  }
  note_index++;
  if (note_index>=ARRAY_SIZE(notes)) {
    note_index=0u;
  }
  for(uint16_t j=0u;j<14u;j++) {
    setSoundRegister(j,ay_regs[j]);
  }
}

void sound_playback(void) {
  static uint8_t divider = NOTE_TIME;
  static bool reinit = false;
  if (!g_sound_mute) {
    if(--divider==0u) {
      divider = NOTE_TIME;
      play_note(reinit);
      reinit = false;
    }
  }else{
    divider = NOTE_TIME;
    reinit  = true;
  }
}