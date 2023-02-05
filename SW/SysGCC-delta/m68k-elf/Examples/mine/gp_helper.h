/*-
 * Copyright (C) 2023	Andreas Voggeneder
 */
/*- Minesweeper GP helper functions */

#ifndef GP_HELPER_H
#define GP_HELPER_H

#include <stdint.h>
#include "../../nkc_common/nkc/nkc.h"

#ifdef __cplusplus
  extern "C" void delay_ms(const uint16_t ms);
  extern "C" void write_with_bg(const char * const p_text, const uint8_t fg, const uint8_t bg, uint8_t length);
  //extern "C" void GDP_set_multiple_clut(const uint8_t start_col_idx, const uint16_t* p_rgb, const uint8_t nr_of_cols);
#else
  void delay_ms(const uint16_t ms);
  void write_with_bg(const char * const p_text, const uint8_t fg, const uint8_t bg, uint8_t length);
  //void GDP_set_multiple_clut(const uint8_t start_col_idx, const uint16_t* p_rgb, const uint8_t nr_of_cols);
#endif




#endif