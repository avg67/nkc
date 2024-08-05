/*-
 * Copyright (C) 2023	Andreas Voggeneder
 */
/*- Minesweeper main file */

//#include <iostream>
//#include <string>
#include <string.h>
#include "board.h"
#include "mine.h"
#include "highscore.h"

#define UP    0x05u
#define DOWN  0x18u
#define LEFT  0x13u
#define RIGHT 0x04u
static int16_t mouse_x;
static int16_t mouse_y;
static bool mouse_present;

typedef enum{
    none_e = 0u,
    mark_e,
    uncover_e,
    left_e,
    right_e,
    up_e,
    down_e,
    exit_e
}key_cmd_t;

static int16_t play_game(board& myboard);
static void draw_mouse_pointer();
static void play_explosion(void);

int main(int argc, char *argv[])
{
    /*setvbuf(stdin, NULL, _IONBF, 0);*/
    setvbuf(stdout, NULL, _IONBF, 0);
    setvbuf(stderr, NULL, _IONBF, 0);

   const uint32_t sysinfo = gp_system();
#ifdef USE_GDP_FPGA
   if (!((sysinfo & (IS_08 | IS_00 | IS_20 | GDP_FPGA | UHR)) == ((IS_08 << PADDING) | GDP_FPGA | UHR))) {
#else
    if (((sysinfo & (IS_08 | IS_00 | IS_20)) != ((IS_08 << PADDING))) ||
        ((sysinfo & (GDP_FPGA | GDP_HS))==0) ||
        ((sysinfo & UHR)==0)) {
#endif
      #if(cpu==1)
         iprintf("Nicht unterstuetzte Systemkonfiguration: 0x%08X\r\nSie benoetigen eine GDP-HS sowie eine 68008 CPU und eine Uhr!\r\n",(unsigned int)sysinfo & (IS_08 | IS_00 | IS_20 | GDP_HS | UHR));
      #else
         puts("Nicht unterstuetzte Systemkonfiguration.\r\nSie benoetigen eine GDP-HS sowie eine 68000 CPU!\r\n");
      #endif
      return 0;
   }
   mouse_present = ((sysinfo & GDP_FPGA)!=0);

    gp_clearscreen();
    bool beginner_mode = true;
    bool show_hs       = false;
    if(argc>1) {
        for(uint16_t i=1u;i<argc;i++) {
            if (strcmp(argv[i],"-I")==0) {
                beginner_mode=false;
            }
            if(strcmp(argv[i],"-H")==0) {
                show_hs = true;
            }
        }
        if (show_hs) {
            highscore hs("mine_hsc.bin");
            const uint16_t level = (beginner_mode)?0u:1u;
            if (hs.GetLoaded()) {
                hs.Display(level);
            }else{
                iprintf("No Highscore found... :-(\r\n");
            }
            return 0;
        }
    }

#ifdef USE_GDP_FPGA
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
#endif
    mouse_x=X_RES/2u;
    mouse_y=Y_RES/2u;

    gp_cursor_off();
    gp_setflip(10u,10u);
#ifdef USE_GDP_FPGA
    GDP_Ctrl.page_dma = 0u;
#endif
    //const clock_t start_time = _clock(NULL);

    srand((unsigned) _gettime());
#ifdef USE_GDP_FPGA
    SetCurrentFgColor(RED);
#endif
    //GDP.ctrl2 = 1u<<4u; // Switch to User character set
    gp_writexy(190u,240,0x22u, "* Minesweeper! *");
    gp_setcurxy(1u,3u);
    iprintf("Press both Mouse keys together or 'x' to exit\r");
    gp_writexy(CCNV_X(BOARD_X + BOARD_X_SIZE)+20u,200u,0x11u, "space = Unhide");
    gp_writexy(CCNV_X(BOARD_X + BOARD_X_SIZE)+20u,190u,0x11u, "1     = Mark mine");
    gp_writexy(CCNV_X(BOARD_X + BOARD_X_SIZE)+20u,180u,0x11,  "down  = Move Down");
    gp_writexy(CCNV_X(BOARD_X + BOARD_X_SIZE)+20u,170u,0x11,  "left  = Move Left");
    gp_writexy(CCNV_X(BOARD_X + BOARD_X_SIZE)+20u,160u,0x11,  "right = Move Right");
    gp_writexy(CCNV_X(BOARD_X + BOARD_X_SIZE)+20u,150u,0x11,  "up    = Move up");

#ifdef MEASURE_TIME
    const clock_t start_ticks = _clock(NULL);
#endif
    board myboard(beginner_mode);
    myboard.draw();
#ifdef MEASURE_TIME
    const clock_t end_ticks = _clock(NULL);
    gp_setcurxy(20u,4u);
    iprintf("Time to draw board: %u ms\r", (unsigned int)(1000u*(end_ticks-start_ticks)/CLOCKS_PER_SEC));
#endif

    int16_t result=0;
    time_t time=0;
    time_t start_time = _gettime();
    do {
        const time_t now = _gettime();
        if(now!=time) {
            gp_setcurxy(1u,4u);
            iprintf("Time: %u s       \r",(unsigned int)(now-start_time));
            time=now;
        }

        result = play_game(myboard);
    }while(result==0);

    const uint8_t y_size = myboard.get_board_height() + 1;
    if(result<0) {
	    play_explosion();
#ifdef USE_GDP_FPGA
        SetCurrentFgColor(RED);
#endif
        gp_writexy(CCNV_X(1u),CCNV_Y(BOARD_Y+y_size),0x33u, "Game over - you died!");
    }else if(result==1u) {
#ifdef USE_GDP_FPGA
        SetCurrentFgColor(GREEN);
#endif
        gp_writexy(CCNV_X(1u),CCNV_Y(BOARD_Y+y_size),0x33u, "Congratulations -  you won!");
        gp_writexy(CCNV_X(1u),CCNV_Y(BOARD_Y+y_size-1u),0x11u, "press any key to continue...");
        highscore hs("mine_hsc.bin");
        gp_ci();
        gp_clearscreen();
        gp_setflip(10u,10u);
        gp_cursor_on();
        puts("Please enter your name for highscore list\r\n");
        char bfr[80u]={0u};
        fgets(bfr, sizeof(bfr), stdin);
        puts("\r\n");
        gp_cursor_off();
        gp_setflip(0u,0u);
        const uint16_t level = (beginner_mode)?0u:1u;
        const uint8_t new_entry = hs.InsertSorted(bfr,time, (uint32_t)time - start_time,level);
        hs.Save();
        hs.Display(level,new_entry);
    }
#ifdef USE_GDP_FPGA
    //GDP_set_clut(MAGENTA, 0b111000111);
    //GDP_set_clut(CYAN, 0b000111111);

    static const uint16_t colors_restore[]= {0b111000111,   // restore Magenta
                                     0b000111111,   // restore Cyan
                                     0b010010010};  // restore middle grey
    GDP_set_multiple_clut(MAGENTA, colors_restore, ARRAY_SIZE(colors_restore));
#endif
}

static inline int16_t limit_value(const int16_t val, const int16_t min, const int16_t max)
{
    int16_t ret = val;
    if(val<min) {ret=min;}
    else if(val>max) {ret=max;}
    return ret;
}

static key_cmd_t decode_keyboard(void)
{
    key_cmd_t key_stat = none_e;
    char key = 0;
    if (gp_csts()) {
         key = gp_ci();
         switch(key) {
            case LEFT:
                key_stat = left_e;
                break;
            case RIGHT:
                key_stat = right_e;
                break;
            case UP:
                key_stat = up_e;
                break;
            case DOWN:
                key_stat = down_e;
                break;
            case '1':
                key_stat = mark_e;
                break;
            case ' ':
                key_stat = uncover_e;
                break;
            case 'x':
                key_stat = exit_e;
                break;
        }
    }
    return key_stat;
}

static int16_t play_game(board& myboard) {
    //static const uint8_t mouse_pointer[]= {0x7f,0x7e,0x71,0xf0,0};
    int16_t dx=0;
    int16_t dy=0;
    int16_t result = 0;

    if (mouse_present) {
        static uint8_t old_mouse_keys =0u;
        static bool mouse_init = true;

        const uint8_t keys     = gp_get_mouse(&dx, &dy);

        if((dx!=0) || (dy!=0) || (keys!=0u)) {
            if(!mouse_init) {
                // delete old mouse pointer
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
                result = myboard.rclick_field(x,y);
            }
            draw_mouse_pointer();

            if((result==0) && myboard.check_done()) {
                result=1;
            }

            if((((~keys & old_mouse_keys) & L_BUTTON)!=0u)) {
                // left Mousebutton released
                draw_mouse_pointer();
                myboard.release();
                draw_mouse_pointer();
            }
            old_mouse_keys = keys;
            result =  ((keys & (L_BUTTON | R_BUTTON))==(L_BUTTON | R_BUTTON))?0xffu:result;
        }
    }
    const key_cmd_t keybd  = decode_keyboard();
    // Play with keyboard
    if (keybd != none_e) {
        switch(keybd){
            case exit_e:
                result = 0xffu;
                break;
            case left_e:
                myboard.release();
                myboard.move_mark(move_left_e);
                break;
            case right_e:
                myboard.release();
                myboard.move_mark(move_right_e);
                break;
            case up_e:
                myboard.release();
                myboard.move_mark(move_up_e);
                break;
            case down_e:
                myboard.release();
                myboard.move_mark(move_down_e);
                break;
            case mark_e:
                result = myboard.rclick_marked();
                break;
            case uncover_e:
                result = myboard.click_marked();
                break;
            default:
                break;
        }
        if((result==0) && myboard.check_done()) {
            result=1;
        }
    }
    return result;
}

static void draw_mouse_pointer()
{
    gp_setxor(true);
#ifndef USE_GDP_FPGA
    gp_moveto(mouse_x-5,mouse_y);
    gp_drawto(mouse_x+5,mouse_y);
    gp_moveto(mouse_x,mouse_y-5);
    gp_drawto(mouse_x,mouse_y+5);
#else
    GDP.ctrl2 = 1u<<4u; // Switch to User character set
    GDP_moveto(mouse_x,mouse_y-6u);
    GDP_cmd(0x7Fu); // Draw mouse pointer
    gdp_ready();
    GDP.ctrl2 = 0u;
#endif
    gp_setxor(false);
}

static void play_explosion(void)
{
    static const uint8_t explosion[]= {0,0,0,0,0,0,0xff,0x07,0x10,0,0x10,0x10,0x10,0,0x38,0};
    gp_sound(explosion);
}