/*-
 * Copyright (C) 2023	Andreas Voggeneder
 */
/*- Minesweeper main file */

//#include <iostream>
//#include <string>
#include <string.h>
#include "board.h"
#include "mine.h"
//#include "gp_helper.h"

static int16_t mouse_x;
static int16_t mouse_y;


static int16_t check_mouse(board& myboard);
static void draw_mouse_pointer();

int main(int argc, char *argv[])
{
    setvbuf(stdin, NULL, _IONBF, 0);
    setvbuf(stdout, NULL, _IONBF, 0);
    setvbuf(stderr, NULL, _IONBF, 0);

    bool beginner_mode = true;
    if((argc>1) && (strcmp(argv[0],"-I")==0)) {
        beginner_mode=false;
    }

   const uint32_t sysinfo = gp_system();
   if (!((sysinfo & (IS_08 | IS_00 | IS_20 | GDP_FPGA)) == ((IS_08 << PADDING) | GDP_FPGA))) {
      #if(cpu==1)
         puts("Nicht unterstuetzte Systemkonfiguration.\r\nSie benoetigen eine GDP-FPGA sowie eine 68008 CPU!\r\n");
      #else
         puts("Nicht unterstuetzte Systemkonfiguration.\r\nSie benoetigen eine GDP-FPGA sowie eine 68000 CPU!\r\n");
      #endif
      return 0;
   }
    // redefine Magenta as dark grey
    /*GDP_set_clut(MAGENTA, 0b001001001);
    // redefine Cyan as light grey
    GDP_set_clut(CYAN, 0b100100100);
    // middle grey
    GDP_set_clut(GRAY, 0b010010010);*/
    static_assert((CYAN==(MAGENTA+1)) && (GRAY==(MAGENTA+2)),"Wrong color definition");
    static const uint16_t colors[]= {0b001001001,   // redefine Magenta as dark grey
                                     0b100100100,   // redefine Cyan as light grey
                                     0b010010010};  // middle grey
    GDP_set_multiple_clut(MAGENTA, colors, ARRAY_SIZE(colors));


    static const uint8_t mouse_pointer[CHAR_SIZE]= {0x7Fu,0x3Eu,0x3Cu,0x58u,0x90u};
    GDP_define_char(0x7F,mouse_pointer);

    mouse_x=X_RES/2u;
    mouse_y=Y_RES/2u;

    gp_clearscreen();
    gp_cursor_off();
    gp_setflip(10u,10u);
    GDP_Ctrl.page_dma = 0u;

    srand((unsigned) _gettime());
    SetCurrentFgColor(RED);
    //GDP.ctrl2 = 1u<<4u; // Switch to User character set
    gp_writexy(190u,240,0x22u, "* Minesweeper! *");
    gp_setcurxy(1u,3u);
    iprintf("Press both Mouse keys together to exit\r");

    /*GDP_moveto(400u,200u);
    GDP_cmd(0x7F);
    gdp_ready();
    GDP.ctrl2 = 0u;*/

    const clock_t start_ticks = _clock(NULL);
    board myboard(beginner_mode);
    myboard.draw();
    const clock_t end_ticks = _clock(NULL);
    gp_setcurxy(20u,4u);
    iprintf("Time to draw board: %u ms\r", (unsigned int)(1000u*(end_ticks-start_ticks)/CLOCKS_PER_SEC));
    //iprintf("Sizeof(field): %u\r\n",sizeof(field));

    int16_t result=0;
    time_t time=0;
    time_t start_time = _gettime();
    do {
        const time_t now = _gettime();
        if(now!=time) {
            gp_setcurxy(1u,4u);
            iprintf("Time: %u s\r",(unsigned int)(now-start_time));
            time=now;
        }

        result = check_mouse(myboard);
    }while(result==0);
    const uint8_t y_size = myboard.get_board_height() + 1;
    if(result<0) {
        SetCurrentFgColor(RED);
        gp_writexy(CCNV_X(1u),CCNV_Y(BOARD_Y+y_size),0x33u, "Game over - you died!");
    }else if(result==1u) {
        SetCurrentFgColor(GREEN);
        gp_writexy(CCNV_X(1u),CCNV_Y(BOARD_Y+y_size),0x33u, "Game over -  you won!");
    }
    /*GDP_set_clut(MAGENTA, 0b111000111);
    GDP_set_clut(CYAN, 0b000111111);*/

    static const uint16_t colors_restore[]= {0b111000111,   // restore Magenta
                                     0b000111111,   // restore Cyan
                                     0b010010010};  // restore middle grey
    GDP_set_multiple_clut(MAGENTA, colors_restore, ARRAY_SIZE(colors_restore));

}

static inline int16_t limit_value(const int16_t val, const int16_t min, const int16_t max)
{
    int16_t ret = val;
    if(val<min) {ret=min;}
    else if(val>max) {ret=max;}
    return ret;
}

static int16_t check_mouse(board& myboard) {
    //static const uint8_t mouse_pointer[]= {0x7f,0x7e,0x71,0xf0,0};
    int16_t dx=0;
    int16_t dy=0;
    int16_t result = 0;
    static uint8_t old_mouse_keys =0u;
    static bool mouse_init=true;
    const uint8_t keys = gp_get_mouse(&dx, &dy);

    if((dx!=0) || (dy!=0) || (keys!=0u)) {
        if(!mouse_init) {
            // delete old mouse pinter
            draw_mouse_pointer();
        }
        mouse_init=false;
        mouse_x = limit_value(mouse_x+(dx*2),0, X_RES-1);
        mouse_y = limit_value(mouse_y+dy,0, Y_RES-1);

        uint16_t x = (mouse_x - CCNV_X(BOARD_X)) / (4u*X_SCALE);
        uint16_t y = (mouse_y - CCNV_Y(BOARD_Y)) / (4u*Y_SCALE);

        if((((keys & ~old_mouse_keys) & L_BUTTON)!=0u)) {
            result = myboard.click_field(x,y);
        }else if((((keys & ~old_mouse_keys) & R_BUTTON)!=0u)) {
            myboard.mark_field(x,y);
        }
        draw_mouse_pointer();

        if((result==0) && myboard.check_done()) {
            result=1;
        }
    }
    if((((~keys & old_mouse_keys) & L_BUTTON)!=0u)) {
        // left Mousebutton released
        draw_mouse_pointer();
        myboard.release();
        draw_mouse_pointer();
    }
    old_mouse_keys = keys;
    return ((keys & (L_BUTTON | R_BUTTON))==(L_BUTTON | R_BUTTON))?0xffu:result;
}

static void draw_mouse_pointer()
{
    gp_setxor(true);
    /*gp_moveto(mouse_x-5,mouse_y);
    gp_drawto(mouse_x+5,mouse_y);
    gp_moveto(mouse_x,mouse_y-5);
    gp_drawto(mouse_x,mouse_y+5);*/
    GDP.ctrl2 = 1u<<4u; // Switch to User character set
    GDP_moveto(mouse_x,mouse_y-6u);
    GDP_cmd(0x7Fu); // Draw mouse pointer
    gdp_ready();
    GDP.ctrl2 = 0u;
    gp_setxor(false);
}