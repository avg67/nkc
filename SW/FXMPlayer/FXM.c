//#pragma GCC optimize ("-O3")
#include <stdbool.h>
#include <string.h>
#include "FXM.h"
#include "ym2149.h"
#include "sound.h"

static const uint8_t *ram;
static uint16_t ram_addr;

//#define pgm_read_byte(a) *((uint8_t*)a)
//#define pgm_read_word(a) (pgm_read_byte(a) | (pgm_read_byte(a+1)<<8))
//#define pgm_read_word(a) *((uint16_t*)a)

static inline __attribute__((always_inline))  uint8_t peek(uint16_t addr)
{
    //return pgm_read_byte(ram + addr - ram_addr);
    return *((uint8_t*)(ram + addr - ram_addr));
}

static inline __attribute__((always_inline))  uint16_t peek2(uint16_t addr)
{
  return peek(addr) + (peek(addr + 1) << 8);
}

static uint8_t ayregs[14];
static inline __attribute__((always_inline))  void write_ay_reg(uint8_t reg, uint8_t val)
{
  ayregs[reg] = val;
}

static const uint16_t FXM_Table[]  = {
  0xfbf, 0xedc, 0xe07, 0xd3d, 0xc7f, 0xbcc, 0xb22, 0xa82, 0x9eb, 0x95d, 0x8d6, 0x857, 0x7df, 0x76e, 0x703,
  0x69f, 0x640, 0x5e6, 0x591, 0x541, 0x4f6, 0x4ae, 0x46b, 0x42c, 0x3f0, 0x3b7, 0x382, 0x34f, 0x320, 0x2f3,
  0x2c8, 0x2a1, 0x27b, 0x257, 0x236, 0x216, 0x1f8, 0x1dc, 0x1c1, 0x1a8, 0x190, 0x179, 0x164, 0x150, 0x13d,
  0x12c, 0x11b, 0x10b, 0xfc, 0xee, 0xe0, 0xd4, 0xc8, 0xbd, 0xb2, 0xa8, 0x9f, 0x96, 0x8d, 0x85, 0x7e, 0x77, 0x70,
  0x6a, 0x64, 0x5e, 0x59, 0x54, 0x4f, 0x4b, 0x47, 0x43, 0x3f, 0x3b, 0x38, 0x35, 0x32, 0x2f, 0x2d, 0x2a, 0x28, 0x25,
  0x23, 0x21
};

struct FXMChannel
{
  uint8_t id;
  uint16_t address_in_pattern;
  uint16_t point_in_ornament;
  uint16_t ornament_pointer;
  uint16_t point_in_sample;
  uint16_t sample_pointer;
  uint8_t volume;
  uint8_t sample_tick_counter;
  uint8_t mixer;
  int16_t note_skip_counter;
  uint16_t tone;
  uint8_t note;
  uint8_t transposit;

  bool b0e, b1e, b2e, b3e;

  uint16_t stack[16];
  uint8_t sp;
};

static uint8_t noise;
static struct FXMChannel channels[3];

void fxm_init(const uint8_t *fxm)
{
  if ((fxm[0] != 'F')
    || (fxm[1] != 'X')
    || (fxm[2] != 'S')
    || (fxm[3] != 'M')) {
    return;
  }

  ram = fxm + 6;
  //ram_addr = pgm_read_byte(fxm + 4) + (pgm_read_byte(fxm + 5) << 8);
  ram_addr = fxm[4] + (fxm[5] << 8);
  
  for (int i = 0 ; i < 3 ; ++i)
  {
    channels[i].note_skip_counter = 1;
    channels[i].mixer = 8;
    channels[i].id = i;
  }
  //channels[0].address_in_pattern = pgm_read_byte(fxm + 6) + (pgm_read_byte(fxm + 7) << 8);
  channels[0].address_in_pattern = fxm[6] + (fxm[7] << 8);
  //channels[1].address_in_pattern = pgm_read_byte(fxm + 8) + (pgm_read_byte(fxm + 9) << 8);
  channels[1].address_in_pattern = fxm[8] + (fxm[9] << 8);
  //channels[2].address_in_pattern = pgm_read_byte(fxm + 10) + (pgm_read_byte(fxm + 11) << 8);
  channels[2].address_in_pattern = fxm[10] + (fxm[11] << 8);


  // init hardware YM
  //set_ym_clock();
  //set_bus_ctl();
  initSound();
}

static void fxm_play_channel(struct FXMChannel *ch)
{
  if (!--ch->note_skip_counter)
  {
    while (true)
    {
      uint8_t v = peek(ch->address_in_pattern++);
      switch (v)
      {
      case 0x80:
        // jump
        ch->address_in_pattern = peek2(ch->address_in_pattern);
        break;
      case 0x81:
        // call
        ch->stack[ch->sp++] = ch->address_in_pattern + 2;
        ch->address_in_pattern = peek2(ch->address_in_pattern);
        break;
      case 0x82:
        // loop begin
        ch->stack[ch->sp++] = peek(ch->address_in_pattern++);
        ch->stack[ch->sp++] = ch->address_in_pattern;
        break;
      case 0x83:
        // loop
        if (--ch->stack[ch->sp - 2] & 0xff)
          ch->address_in_pattern = ch->stack[ch->sp - 1];
        else
          ch->sp -= 2;
        break;
      case 0x84:
        // set noise
        noise = peek(ch->address_in_pattern++);
        break;
      case 0x85:
        // set mixer
        ch->mixer = peek(ch->address_in_pattern++);
        break;
      case 0x86:
        // set ornament
        ch->ornament_pointer = peek2(ch->address_in_pattern);
        ch->address_in_pattern += 2;
        break;
      case 0x87:
        // set sample
        ch->sample_pointer = peek2(ch->address_in_pattern);
        ch->address_in_pattern += 2;
        break;
      case 0x88:
        // transposition
        ch->transposit = peek(ch->address_in_pattern++);
        break;
      case 0x89:
        // return
        ch->address_in_pattern = ch->stack[--ch->sp];
        break;
      case 0x8a:
        // don't restart sample at new note
        ch->b0e = true;
        ch->b1e = false;
        break;
      case 0x8b:
        // restart sample at new note
        ch->b0e = false;
        ch->b1e = false;
        break;
      case 0x8c:
        // not implemented code call
        ch->address_in_pattern += 2;
        break;
      case 0x8d:
        // add to noise
        noise = (noise + peek(ch->address_in_pattern++)) & 0x1f;
        break;
      case 0x8e:
        // add transposition
        ch->transposit += peek(ch->address_in_pattern++);
        break;
      case 0x8f:
        // push transposition
        ch->stack[ch->sp++] = ch->transposit;
        break;
      case 0x90:
        // pop transposition
        ch->transposit = ch->stack[--ch->sp];
        break;
      default:
        // note
        if (v <= 0x54)
        {
          if (v)
          {
            ch->note = v + ch->transposit;
            ch->tone = FXM_Table[ch->note - 1];
            ch->b3e = false;
          }
          else
          {
            ch->tone = 0;
          }
          ch->note_skip_counter = peek(ch->address_in_pattern++);
          ch->point_in_ornament = ch->ornament_pointer;
          ch->b2e = true;
          if (!ch->b1e)
          {
            ch->b1e = ch->b0e;
            ch->point_in_sample = ch->sample_pointer;
            ch->volume = peek(ch->point_in_sample++);
            ch->sample_tick_counter = peek(ch->point_in_sample++);
            goto ret;
          }
          else
          {
            goto decode_sample;
          }
          break;
        }
      }
    }
  }

decode_sample:
  if (!--ch->sample_tick_counter)
  {
    while (true)
    {
      uint8_t s = peek(ch->point_in_sample++);
      if (s == 0x80)
      {
        ch->point_in_sample = peek2(ch->point_in_sample);
        continue;
      }
      else if (s < 0x1e)
      {
        ch->volume = s;
        ch->sample_tick_counter = peek(ch->point_in_sample++);
      }
      else
      {
        s -= 0x32;
        ch->volume = s;
        ch->sample_tick_counter = 1;
      }
      break;
    }
  }
  // decode ornament
  if (ch->tone && !ch->b2e)
  {
    while (true)
    {
      uint8_t s = peek(ch->point_in_ornament++);
      switch (s)
      {
      case 0x80:
        ch->point_in_ornament = peek2(ch->point_in_ornament);
        break;
      case 0x82:
        ch->b3e = true;
        break;
      case 0x83:
        ch->b3e = false;
        break;
      case 0x84:
        ch->mixer ^= 9;
        break;
      default:
        if (!ch->b3e)
        {
          ch->tone += (int8_t)s;
        }
        else
        {
          ch->note += s;
          ch->tone = FXM_Table[ch->note - 1];
        }
        goto ret;
      }
    }
  }
ret:
  write_ay_reg(NOISE_PERIOD, noise);
  ch->b2e = 0;
  
  write_ay_reg(ch->id + AMP_CHANNEL_A, ch->tone ? (ch->volume & 0xf)/2u : 0);
  write_ay_reg(2 * ch->id, ch->tone); // CHANNEL_AB_FINE
  write_ay_reg(2 * ch->id + 1, ch->tone >> 8);  //CHANNEL_AB_COARSE
}

void fxm_loop()
{
  if (!ram) {
    return;
  }

  fxm_play_channel(&channels[0]);
  fxm_play_channel(&channels[1]);
  fxm_play_channel(&channels[2]);

  write_ay_reg(7, (channels[2].mixer << 2) | (channels[1].mixer << 1) | channels[0].mixer);
  for (int i = 13 ; i >= 0 ; --i)
    setSoundRegister(i, ayregs[i]);
}

