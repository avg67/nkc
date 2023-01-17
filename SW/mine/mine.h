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
   GDP.xh = x >> 8u;
   GDP.yl = y & 0xffu;
   GDP.yh = y >> 8u;
}

/*static inline __attribute__((always_inline)) void GDP_draw_line_x(const uint8_t delta)
{
   gdp_ready();
   GDP.deltax = delta;
   GDP.deltay = 0;
   GDP.cmd = 0x10;

}

static inline __attribute__((always_inline)) void GDP_draw_line_y(const uint8_t delta)
{
   gdp_ready();
   GDP.deltay = delta;
   GDP.deltax = 0;
   GDP.cmd = 0x10;

}*/
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
   GDP.cmd = 0x11|sx|sy;
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
