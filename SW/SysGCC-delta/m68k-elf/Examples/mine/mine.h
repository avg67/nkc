/*-
 * Copyright (C) 2023	Andreas Voggeneder
 */
/*- Minesweeper definitions */

#ifndef MINE_H
#define MINE_H

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <time.h>
#include <ndrcomp/target.h>
#include <ndrcomp/sysclock.h>
#include "../../nkc_common/nkc/nkc.h"

#define BOARD_X_SIZE 16u
#define BOARD_Y_SIZE 16u

#define CCNV_X(X) (((uint16_t)X)*4u*X_SCALE)
#define CCNV_Y(Y) (((uint16_t)Y)*4u*Y_SCALE)

#define X_SCALE 5u
#define Y_SCALE 3u
#define BOARD_X	1u
#define BOARD_Y	0u
#define X_RES 512
#define Y_RES 256

#define BEGINNER_X_SIZE 9u
#define BEGINNER_Y_SIZE 9u
#define BEGINNER_NR_MINES 10u
#define INTERMEDIATE_X_SIZE 16u
#define INTERMEDIATE_Y_SIZE 16u
#define INTERMEDIATE_NR_MINES 40u

static inline __attribute__((always_inline)) void gdp_ready(void) {
   while(!(GDP.cmd & 0x04u)) {};
}

static inline __attribute__((always_inline)) void GDP_moveto(const uint16_t x, const uint16_t y)
{
   gdp_ready();
   GDP.xl = x & 0xffu;
   GDP.xh = (x >> 8u) & 0xFFu;
   GDP.yl = y & 0xffu;
   GDP.yh = (y >> 8u) & 0xFFu;
}

// Very fast Line drawing routine (10x faster than calling GP)
static inline __attribute__((always_inline)) void GDP_draw_line(const int8_t dx, const int8_t dy)
{
   const int8_t abs_dx = abs(dx);
   const int8_t abs_dy = abs(dy);
   const uint8_t sx = (dx<0)?SX_BIT:0u;
   const uint8_t sy = (dy<0)?SY_BIT:0u;
   gdp_ready();
   GDP.deltax = abs_dx;
   GDP.deltay = abs_dy;
   GDP.cmd = 0x11u|sx|sy;
}

static inline __attribute__((always_inline)) void GDP_cmd(const uint8_t cmd)
{
   gdp_ready();
   GDP.cmd = cmd;
}

static inline __attribute__((always_inline)) void GDP_draw4x4(const uint16_t x, const uint16_t y)
{
   GDP_moveto(x,y);
   GDP.cmd = 0x0Bu;  // 4x4
}

static inline __attribute__((always_inline)) void GDP_erapen(void)
{
   gdp_ready();
   GDP.cmd = 0x01u;  // Löschstift
}

static inline __attribute__((always_inline)) void GDP_drawpen(void)
{
   gdp_ready();
   GDP.cmd = 0x00u;  // Schreibstift
}
static inline __attribute__((always_inline)) void GDP_set_clut(const uint8_t col_idx, const uint16_t rgb)
{
   GDP_Clut.color_idx = col_idx;
   GDP_Clut.color_h   = (uint8_t)((rgb >> 8u) & 0xFFu);
   GDP_Clut.color_l   = (uint8_t)(rgb & 0xFFu);
}

static inline __attribute__((always_inline)) void GDP_set_multiple_clut(const uint8_t start_col_idx, const uint16_t* p_rgb, const uint8_t nr_of_cols)
{
   uint8_t color_count = nr_of_cols;
   GDP_Clut.color_idx = start_col_idx;
   while(color_count>0u) {
      const uint16_t color = *p_rgb++;
      GDP_Clut.color_h   = (uint8_t)((color >> 8u) & 0xFFu);
      GDP_Clut.color_l   = (uint8_t)(color & 0xFFu);
      color_count--;
   }
}

static inline __attribute__((always_inline)) void GDP_define_char(const uint8_t ch, const uint8_t* p_char) {
   GDP.ctrl2 = 1u<<4u;
   const uint16_t chr_addr = ((uint16_t)(ch - ' ')) * CHAR_SIZE;
   GDP.xh = (uint8_t)(chr_addr >> 8u) & 0xFFu;
   GDP.xl = (uint8_t)(chr_addr & 0xFFu);
   for(uint16_t i=0u;i<CHAR_SIZE;i++) {
      GDP.char_def = *p_char++;
   }
   GDP.ctrl2 = 0u;
}

static inline __attribute__((always_inline)) void GDP_define_chars(const uint8_t start_index, const uint8_t* p_char, const uint8_t nr_chars) {
   uint8_t char_count = nr_chars;
   GDP.ctrl2 = 1u<<4u;
   const uint16_t chr_addr = ((uint16_t)(start_index - ' ')) * CHAR_SIZE;
   GDP.xh = (uint8_t)(chr_addr >> 8u) & 0xFFu;
   GDP.xl = (uint8_t)(chr_addr & 0xFFu);
   while(char_count>0u) {
      for(uint16_t i=0u;i<CHAR_SIZE;i++) {
         GDP.char_def = *p_char++;
      }
      char_count--;
   }
   GDP.ctrl2 = 0u;
}

static inline __attribute__((always_inline)) void SetCurrentFgColor(uint8_t fg) {
   gdp_ready();
   //fg_color = fg;
    GDP_Col.fg=fg;
}

static inline __attribute__((always_inline)) void SetCurrentBgColor(uint8_t bg) {
   gdp_ready();
   //bg_color = bg;
   GDP_Col.bg=bg;
}

#endif
