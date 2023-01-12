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

static inline __attribute__((always_inline)) void GDP_draw4x4(const uint16_t x, const uint16_t y)
{
   gdp_ready();
   GDP.xl = x & 0xffu;
   GDP.xh = x >> 8u;
   GDP.yl = y & 0xffu;
   GDP.yh = y >> 8u;
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
