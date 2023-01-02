#define SOUND_CMD0 BYTE_AT(0xFFFFFF50)
#define SOUND_CMD1 BYTE_AT(0xFFFFFF51)

#define ON  1u
#define OFF 0u

#define BUFFERSIZE 32

byte pock_soundA[14*2] = {
  //A          B            C           |Noise  Mix   AmpA  AmpB  AmpC  Env   Env   Shape
  0x00, 0x00,  0x23, 0x08,  0x00, 0x00,   0x00, 0x00, 0x00, 11, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00,  0x23, 0x08,  0x00, 0x00,   0x00, 0x00, 0x00, 11, 0x00, 0x00, 0x00, 0x00,
  //0x00, 0x00,  0x23, 0x08,  0x00, 0x00,   0x00, 0x00, 0x00, 10, 0x00, 0x00, 0x00, 0x00
};

byte pock_soundB[14*2] = {
  //A          B            C          |Noise  Mix   AmpA  AmpB  AmpC  Env   Env   Shape
  0x00, 0x00,  0x90, 0x08,  0x00, 0x00,   0x00, 0x00, 0x00, 11, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00,  0x90, 0x08,  0x00, 0x00,   0x00, 0x00, 0x00, 11, 0x00, 0x00, 0x00, 0x00,
  //0x00, 0x00,  0x90, 0x08,  0x00, 0x00,   0x00, 0x00, 0x00, 10, 0x00, 0x00, 0x00, 0x00
};

byte pock_soundC[14*2] = {
  //A          B            C           |Noise  Mix   AmpA  AmpB  AmpC  Env   Env   Shape
  0x00, 0x00,  0x23, 0x08,  0x00, 0x00,   0x00, 0x00, 0x00, 11, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00,  0x23, 0x08,  0x00, 0x00,   0x00, 0x00, 0x00, 11, 0x00, 0x00, 0x00, 0x00,
  //0x00, 0x00,  0x23, 0x08,  0x00, 0x00,   0x00, 0x00, 0x00, 10, 0x00, 0x00, 0x00, 0x00
};

byte pock_soundD[14*2] = {
  //A          B            C          |Noise  Mix   AmpA  AmpB  AmpC  Env   Env   Shape
  0x00, 0x00,  0x91, 0x07,  0x00, 0x00,   0x00, 0x00, 0x00, 11, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00,  0x91, 0x07,  0x00, 0x00,   0x00, 0x00, 0x00, 11, 0x00, 0x00, 0x00, 0x00,
  //0x00, 0x00,  0x91, 0x07,  0x00, 0x00,   0x00, 0x00, 0x00, 10, 0x00, 0x00, 0x00, 0x00
};

byte* pock_sounds[4] = {NULL, NULL, NULL, NULL};  //populated at runtime when abs. adresses are available

byte sound_upFire_ChannelB[168] = {
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
};

byte sound_upFire_ChannelA[168] = {
  //A          B            C           |Noise  Mix   AmpA  AmpB  AmpC  Env   Env   Shape
  0xf1, 0x00,  0x00, 0x00,  0x00, 0x00,   0xa0, 0x00, 0x0E, 0x00, 0x00, 0x00, 0x00,  0x00, //1
  0xff, 0x00,  0x00, 0x00,  0x00, 0x00,   0xa0, 0x00, 0x0E, 0x00, 0x00, 0x00, 0x00,  0x00, //2
  0x04, 0x01,  0x00, 0x00,  0x00, 0x00,   0xa0, 0x00, 0x0E, 0x00, 0x00, 0x00, 0x00,  0x00, //3
  0x29, 0x01,  0x00, 0x00,  0x00, 0x00,   0xa0, 0x00, 0x0E, 0x00, 0x00, 0x00, 0x00,  0x00, //4
  0x47, 0x01,  0x00, 0x00,  0x00, 0x00,   0xa0, 0x00, 0x0D, 0x00, 0x00, 0x00, 0x00,  0x00, //5
  0x6f, 0x01,  0x00, 0x00,  0x00, 0x00,   0xa0, 0x00, 0x0D, 0x00, 0x00, 0x00, 0x00,  0x00, //6
  0xac, 0x01,  0x00, 0x00,  0x00, 0x00,   0xa0, 0x00, 0x0D, 0x00, 0x00, 0x00, 0x00,  0x00, //7
  0x25, 0x02,  0x00, 0x00,  0x00, 0x00,   0xa0, 0x00, 0x0C, 0x00, 0x00, 0x00, 0x00,  0x00, //8
  0xcd, 0x02,  0x00, 0x00,  0x00, 0x00,   0xa0, 0x00, 0x0C, 0x00, 0x00, 0x00, 0x00,  0x00, //9
  0x34, 0x03,  0x00, 0x00,  0x00, 0x00,   0xa0, 0x00, 0x0C, 0x00, 0x00, 0x00, 0x00,  0x00, //10
  0x45, 0x04,  0x00, 0x00,  0x00, 0x00,   0xa0, 0x00, 0x0B, 0x00, 0x00, 0x00, 0x00,  0x00, //11
  0x95, 0x05,  0x00, 0x00,  0x00, 0x00,   0xa0, 0x00, 0x0B, 0x00, 0x00, 0x00, 0x00,  0x00  //12
};

#define TONE 2000
#define thHz 70

byte super_sonic[14] = {
  0x00, 0x00,  0x00, 0x00,  0x01, 0x01,  0x00, 0x00, 0x00, 0x00, 
  0b00010000, 
  92, //((7812 * 10 * 8) / thHz) >> 3
  ((7812 * 10 * 8) / thHz) >> 11, 
  0b1110};

byte super_sonic_OFF[14] = {0x00, 0x00,  0x00, 0x00, 0x00, 0x00,  0x00, 0x00, 0x00, 0x00, 
  0b11000000, 0x00, 0x00, 0x00};

/*
envelope shapes:
                 C AtAlH
                 0 0 x x  \___
                 0 1 x x  /|___
                 1 0 0 0  \|\|\|\
                 1 0 0 1  \___
                 1 0 1 0  \/\/
                 1 0 1 1  \|^^^^
                 1 1 0 0  /|/|/|/|
                 1 1 0 1  /^^^^
                 1 1 1 0  /\/\
                 1 1 1 1  /___
*/

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

typedef struct AYregisterSet {

  //Tone Generator Control
  byte channelAfine;    //R0 - Channel A Tone Period 8 bit Fine
  byte channelAcoarse;  //R1 - Channel B Tone Period 4 bit Coarse
  byte channelBfine;    //R2 - Channel A Tone Period 8 bit Fine
  byte channelBcoarse;  //R3 - Channel B Tone Period 4 bit Coarse
  byte channelCfine;    //R4 - Channel A Tone Period 8 bit Fine
  byte channelCcoarse;  //R5 - Channel B Tone Period 4 bit Coarse
  
  //Noise Generator Control
  byte noisePeriod;     //R6 - 5 bit Noise Period
  
  //Mixer Control
  byte mixerControl;    //R7 - Mixer Control bits: IOB/IOA/C/B/A/C/B/A
  
  //Amplitude Control
  byte ampChannelA;     //R8 - Channel A -EVVVV
  byte ampChannelB;     //R9 - Channel B -EVVVV
  byte ampChannelC;     //R10 - Channel C -EVVVV
  
  //Envelope Generator Control
  byte envelopeFine;    //R11 - Envelope Period Control 8 bit Fine
  byte envelopeCoarse;  //R12 - Envelope Period Control 8 bit Coarse
  byte envelopeShape;   //R13 - Envelope Shape Control CONT/ATT/ALT/HOLD
  
  //IO
  //byte IOportA;         //R14 - Parallel IO Port A 8bit
  //byte IOportB;         //R15 - Parallel IO Port B 8bit (AY-3-8912 only)

} AYregisterSet;

typedef struct soundBuffer {
  
  union unionBuffer {
      AYregisterSet buffer[BUFFERSIZE];   
      byte          bufferBytes[BUFFERSIZE*sizeof(AYregisterSet)];
  } unionBuffer;
  int head;
  int tail;
} soundBuffer;

soundBuffer soundBufferA;

void __attribute__ ((inline)) setSoundRegister(int reg, int value) {
  SOUND_CMD0 = reg;
  SOUND_CMD1 = value;
}

void playAYFrame(AYregisterSet *s) {

  //switch channel ON if data to play
  byte mix = 0b00000000;
  //if ((s->channelAfine > 0) || (s->channelAcoarse > 0)) {mix = mix || 0b00000001;}
  //if ((s->channelBfine > 0) || (s->channelBcoarse > 0)) {mix = mix || 0b00000010;}
  //if ((s->channelCfine > 0) || (s->channelCcoarse > 0)) {mix = mix || 0b00000100;}
  setSoundRegister(MIXER_CONTROL, mix); s->mixerControl = 0x00;  //always all ON

  setSoundRegister(CHANNEL_A_FINE,   s->channelAfine);   s->channelAfine   = 0;
  setSoundRegister(CHANNEL_A_COARSE, s->channelAcoarse); s->channelAcoarse = 0;
  setSoundRegister(CHANNEL_B_FINE,   s->channelBfine);   s->channelBfine   = 0;
  setSoundRegister(CHANNEL_B_COARSE, s->channelBcoarse); s->channelBcoarse = 0;
  if (s->channelCfine > 0)   {setSoundRegister(CHANNEL_C_FINE,   s->channelCfine);   s->channelCfine   = 0;}
  if (s->channelCcoarse > 0) {setSoundRegister(CHANNEL_C_COARSE, s->channelCcoarse); s->channelCcoarse = 0;} //flaw!

  setSoundRegister(NOISE_PERIOD, s->noisePeriod);  s->noisePeriod = 0;
  
  setSoundRegister(AMP_CHANNEL_A, s->ampChannelA); s->ampChannelA = 0;  
  setSoundRegister(AMP_CHANNEL_B, s->ampChannelB); s->ampChannelB = 0;    
  
  if (s->ampChannelC > 0) {setSoundRegister(AMP_CHANNEL_C, s->ampChannelC); s->ampChannelC = 0;}

  //update only if value > 0, and keep value in buffer
  if (s->envelopeFine   > 0) {setSoundRegister(ENVELOPE_FINE,   s->envelopeFine);   s->envelopeFine   = 0; }
  if (s->envelopeCoarse > 0) {setSoundRegister(ENVELOPE_COARSE, s->envelopeCoarse); s->envelopeCoarse = 0; }
  if (s->envelopeShape  > 0) {setSoundRegister(ENVELOPE_SHAPE,  s->envelopeShape);  s->envelopeShape  = 0; }
}

void silence() {
  
  AYregisterSet s = {0x00, 0x00, 0x00, 0x00, 0x00 ,0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
  playAYFrame(&s);
}

void clearSoundQueue() {

  memset(&soundBufferA, 0x00, sizeof(soundBufferA));

  //set mixer byte in empyt sound queue to 'all channels off'
  for (int i = 0; i < (sizeof(AYregisterSet) * BUFFERSIZE); i=i+sizeof(AYregisterSet)) {
      soundBufferA.unionBuffer.bufferBytes[i+MIXER_CONTROL] = 0xFF;
  }
}

void initSound() {
  
  //init AY-3-891x
  silence();

  //init buffers
  clearSoundQueue(); //memset(&soundBufferA, 0x00, sizeof(soundBufferA));

  soundBufferA.head = 0; 
  soundBufferA.tail = 0;

  //init pointer table, Space Invaders specific, should move 
  pock_sounds[0] = (byte *) &pock_soundA;
  pock_sounds[1] = (byte *) &pock_soundB;
  pock_sounds[2] = (byte *) &pock_soundC;
  pock_sounds[3] = (byte *) &pock_soundD;
}

void addToSoundBuffer(soundBuffer *sndBuffer, byte const *samples, int const count) {

  int sndBufferPos = ((sndBuffer->head+1) % BUFFERSIZE) * 14;
  int noOfFrames = count / 14;
  int samplesPos = 0;

  for (int frame=0; frame < noOfFrames; frame++) {

      //merge freq for channel A, B, c and noise
      for (int i=0; i < 7; i++) {
         if (samples[samplesPos+i] !=0) {
           sndBuffer->unionBuffer.bufferBytes[(sndBufferPos+i) % (BUFFERSIZE*14)] = samples[samplesPos+i];
         }
      }

      //merge amplitude
      for (int i=8; i < 14; i++) {
         if (samples[samplesPos+i] !=0) {
           sndBuffer->unionBuffer.bufferBytes[(sndBufferPos+i) % (BUFFERSIZE*14)] = samples[samplesPos+i];
         }
      }

      samplesPos += 14;
      sndBufferPos += 14;
  } 
}

void playSound(int skip) {

  for (int i = 0; i < skip; ++i) {
    playAYFrame(&soundBufferA.unionBuffer.buffer[soundBufferA.head++]);
    soundBufferA.head %= BUFFERSIZE;   
  }
}

/*void playBeep(int freq, int tenthHz) {

	int cyc = 125000 / freq;
	int dur = (7812 * 10 * 8) / tenthHz;   //tenthHz = 1/10Hz, 5 = 0.5Hz

	SOUND_CMD0 = CHANNEL_A_FINE;    SOUND_CMD1 = 0x00;   
  SOUND_CMD0 = CHANNEL_A_COARSE; 	SOUND_CMD1 = 0x00;
	SOUND_CMD0 = CHANNEL_B_FINE; 	  SOUND_CMD1 = 0x00;   
	SOUND_CMD0 = CHANNEL_B_COARSE; 	SOUND_CMD1 = 0x00;
	SOUND_CMD0 = CHANNEL_C_FINE; 	  SOUND_CMD1 = cyc;   
	SOUND_CMD0 = CHANNEL_C_COARSE; 	SOUND_CMD1 = cyc >> 8;

  SOUND_CMD0 = NOISE_PERIOD;      SOUND_CMD1 = 0x00; //0b00111;

	SOUND_CMD0 = MIXER_CONTROL; 	  SOUND_CMD1 = 0x00; //0b11110110;  //only noise channel
	
  SOUND_CMD0 = AMP_CHANNEL_A; 	  SOUND_CMD1 = 0x00;  //env mode, max vol
	SOUND_CMD0 = AMP_CHANNEL_B; 	  SOUND_CMD1 = 0x00;  
	SOUND_CMD0 = AMP_CHANNEL_C; 	  SOUND_CMD1 = 0b00010000;  
	SOUND_CMD0 = ENVELOPE_FINE;		  SOUND_CMD1 = (dur*1) >> 3;
	SOUND_CMD0 = ENVELOPE_COARSE;   SOUND_CMD1 = (dur*1) >> 11;	  //fixed point math
	SOUND_CMD0 = ENVELOPE_SHAPE;    SOUND_CMD1 = 0b1110;	  //shape: /\/\/\/
}*/

/*int getChannelFreq(AYchannel ch) {  //NOT WORKING

	byte value = 0;

	SOUND_CMD0 = CHANNEL_A_FINE;
	value = SOUND_CMD1;	

	return (int)value;
}*/