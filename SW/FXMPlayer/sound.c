#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <ndrcomp/target.h>
#include "sound.h"

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



