#include <stdint.h>
#include "../../nkc_common/nkc/nkc.h"

#ifndef GP_HELPER_H
#define GP_HELPER_H

#ifdef __cplusplus
  extern "C" void delay_ms(const uint16_t ms);
  extern "C" void write_with_bg(const char * const p_text, const uint8_t fg, const uint8_t bg, uint8_t length);
#else
  void delay_ms(const uint16_t ms);
  void write_with_bg(const char * const p_text, const uint8_t fg, const uint8_t bg, uint8_t length);
#endif




#endif