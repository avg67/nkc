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
  extern "C" void draw_arc(const uint16_t center_x, const uint16_t center_y, const uint16_t r, const int16_t s, const int16_t e);
#else
  void delay_ms(const uint16_t ms);
  void write_with_bg(const char * const p_text, const uint8_t fg, const uint8_t bg, uint8_t length);
  //void GDP_set_multiple_clut(const uint8_t start_col_idx, const uint16_t* p_rgb, const uint8_t nr_of_cols);
  void draw_circle(const uint16_t nr_points);
#endif




#endif