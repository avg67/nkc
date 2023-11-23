/*-
 * Copyright (C) 2023	Andreas Voggeneder
 */
/*- Minesweeper GP helper functions */

// Standard Input/Output functions
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
//#include <delay.h>
#include <string.h>
#include <stdbool.h>
#include <ndrcomp/target.h>
#include <ndrcomp/sysclock.h>
//#include "../../nkc_common/nkc/llnkc.h"
#include "../../nkc_common/nkc/nkc.h"

// Declare your global variables here

void delay_ms(const uint16_t ms) {
   clock_t ticks = ((clock_t)ms*200u)/1000u;
   clock_t start = _clock(NULL);
   while((_clock(NULL)-start)<ticks) {};
}

void write_with_bg(const char * const p_text, const uint8_t fg, const uint8_t bg, uint8_t length)
{
   gp_setcolor(fg,bg);
   const size_t len = strlen(p_text);
   puts(p_text);

   uint16_t x_pos=0u;
   uint16_t y_pos=0u;
   gp_getxy(&x_pos,&y_pos);
   //gp_erapen();
   gp_setxor(true);

   uint16_t dx; //= (41-4+24)*6u;
   if(!length) {
      dx = (len*6u); // use text-length
   }else{
      dx = length*6u;
   }
   uint8_t loops=1u;
   if(dx>=256u) {
      dx/=2u;
      loops++;
   }

   for(uint8_t page=0u;page<2u; page++) {
      gp_newpage(page,0u);

      uint16_t x = x_pos-(len*6u);
      for(uint8_t j=0u;j<loops;j++) {
         gp_draw_filled_rect(x,y_pos*2u,dx,18u);   // need to keep dx < 256 to prevent xor artifacts
         x+=dx;
      }
      //gp_draw_filled_rect(x+dx,y_pos*2u,dx,16u);   // //(len*6u),16u);
   }
   //gp_setpen();
   gp_setxor(false);
}

void draw_arc(const uint16_t center_x, const uint16_t center_y, const uint16_t r, const int16_t s, const int16_t e)
{
    const uint16_t scale=256u/r;
    const int16_t is=min(s,e);
    const int16_t ie=max(s,e);
#if 0
    uint16_t count=0u;
    iprintf("S:%d E:%d\r\n",is,ie);
#endif
    int16_t i=is;
    int16_t delta;
    do{
        const uint16_t x=(uint16_t)((gp_sin(i)/(int16_t)scale)+center_x);
        const uint16_t y=(uint16_t)((gp_cos(i)/(int16_t)(2u*scale))+center_y);
        //iprintf("%d %u %u\r\n",i,x,y);
        if(i==is) {
            gp_moveto(x,y);
        }else{
            gp_drawto(x,y);
        }
#if 0
        if(++count>=20) {
            break;
        }
#endif
        delta = min(10,ie - i);   // make max. 10° steps
        i+=delta;
    }while(delta>0);
    //gp_ci();
}



