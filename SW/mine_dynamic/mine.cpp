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
#include "gp_helper.h"
#include <cstring>

//#define MEASURE_TIME
//#define USE_SURROUND

#define UP    0x05u
#define DOWN  0x18u
#define LEFT  0x13u
#define RIGHT 0x04u

#define GAME_EXIT   0xffu
#define NEW_GAME    0xfeu
#define TOGGLE_MODE 0xfdu

#define SMILEY_RADIUS 30u

static int16_t mouse_x;
static int16_t mouse_y;
static bool mouse_init;
static uint8_t old_mouse_keys;

typedef enum{
    none_e = 0u,
    mark_e,
    uncover_e,
    left_e,
    right_e,
    up_e,
    down_e,
    exit_e,
    new_game_e,
    toggle_mode_e
}key_cmd_t;

typedef struct {
    uint16_t x;
    uint16_t y;
} xy_pos_t;

static int16_t play_game(board& myboard, const bool mode);
static void draw_mouse_pointer();
static void play_explosion(void);
//void draw_smiley(const uint16_t center_x, const uint16_t center_y, const bool happy);
static void draw_smiley(board const & myboard, const bool happy);
static void draw_3d_rect(const uint16_t x_pos, const uint16_t y_pos, const uint16_t dx, const uint16_t dy);
//static char wait_key(const char* const p_abort_chars);
static char wait_key(const std::string abort_chars);
void write_text_centered_with_bg(board const & myboard, const std::string text);

int main(int argc, char *argv[])
{
    /*setvbuf(stdin, NULL, _IONBF, 0);*/
    setvbuf(stdout, NULL, _IONBF, 0);
    setvbuf(stderr, NULL, _IONBF, 0);

   const uint32_t sysinfo = gp_system();
#ifdef USE_GDP_FPGA
   if (!((sysinfo & (IS_08 | IS_00 | IS_20 | GDP_FPGA | UHR)) == ((IS_08 << PADDING) | GDP_FPGA | UHR))) {
#else
    if (!((sysinfo & (IS_08 | IS_00 | IS_20 | GDP_HS | UHR)) == ((IS_08 << PADDING) | GDP_HS | UHR))) {
#endif
      #if(cpu==1)
         puts("Nicht unterstuetzte Systemkonfiguration.\r\nSie benoetigen eine GDP-HS sowie eine 68008 CPU!\r\n");
      #else
         puts("Nicht unterstuetzte Systemkonfiguration.\r\nSie benoetigen eine GDP-HS sowie eine 68000 CPU!\r\n");
      #endif
      return 0;
   }

    gp_clearscreen();

    bool beginner_mode = true;
    bool show_hs       = false;
    if(argc>1) {
        for(uint16_t i=1u;i<argc;i++) {
            if (strcmp(argv[i],"-I")==0) {
                beginner_mode = false;
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
                /*hs.InsertSorted("Andi1",_gettime(),55,level);
                hs.InsertSorted("Andi2",_gettime(),65,level);
                hs.InsertSorted("Andi3",_gettime(),45,level);
                hs.InsertSorted("Andi4",_gettime(),105,level);
                const uint8_t idx= hs.InsertSorted("Andi5",_gettime(),19,level);
                hs.Save();
                hs.Display(level,idx);*/
            }
            return 0;
        }
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
    int16_t result=0;
    do {
        mouse_init=true;
        old_mouse_keys =0u;


        gp_cursor_off();
        gp_setflip(10u,10u);
        GDP_Ctrl.page_dma = 0u;
    #ifdef USE_SURROUND
        SetCurrentFgColor(GRAY);
        draw_3d_rect(5u, 5u, 500u, 250u);
        SetCurrentBgColor(GRAY);
    #endif

        srand((unsigned) _gettime());
        SetCurrentFgColor(RED);

        //GDP.ctrl2 = 1u<<4u; // Switch to User character set
        gp_writexy(180u,235u,0x22u, "* Minesweeper! *");
        SetCurrentFgColor(WHITE);
        //gp_setcurxy(1u,3u);
        //iprintf("Press both Mouse keys together or 'x' to exit\r");
        gp_writexy(CCNV_X(BOARD_X + BOARD_X_SIZE)+20u,210u,0x11u, "X     = Exit");
        gp_writexy(CCNV_X(BOARD_X + BOARD_X_SIZE)+20u,200u,0x11,  "N     = New Game");
        gp_writexy(CCNV_X(BOARD_X + BOARD_X_SIZE)+20u,190u,0x11u, "space = Unhide");
        gp_writexy(CCNV_X(BOARD_X + BOARD_X_SIZE)+20u,180u,0x11u, "1     = Mark mine");
        gp_writexy(CCNV_X(BOARD_X + BOARD_X_SIZE)+20u,170u,0x11,  "down  = Move Down");
        gp_writexy(CCNV_X(BOARD_X + BOARD_X_SIZE)+20u,160u,0x11,  "left  = Move Left");
        gp_writexy(CCNV_X(BOARD_X + BOARD_X_SIZE)+20u,150u,0x11,  "right = Move Right");
        gp_writexy(CCNV_X(BOARD_X + BOARD_X_SIZE)+20u,140u,0x11,  "up    = Move up");
        gp_writexy(CCNV_X(BOARD_X + BOARD_X_SIZE)+20u,130u,0x11,  "M     = Toggle mode");

    #ifdef MEASURE_TIME
        const clock_t start_ticks = _clock(NULL);
    #endif
        board myboard(beginner_mode);
        //SetCurrentFgColor(GRAY);
        //draw_3d_rect(0u, CCNV_Y(BOARD_Y)-10u, CCNV_X(BOARD_X) + myboard.get_x_pixel(), myboard.get_y_pixel() + 50u);
        myboard.draw();
    #ifdef MEASURE_TIME
        const clock_t end_ticks = _clock(NULL);
        gp_setcurxy(20u,4u);
        iprintf("Time to draw board: %u ms\r", (unsigned int)(1000u*(end_ticks-start_ticks)/CLOCKS_PER_SEC));
    #endif


        draw_smiley(myboard,true);

        result=0;
        time_t time=0;
        time_t start_time = _gettime();
        do {
            do {
                const time_t now = _gettime();
                if(now!=time) {
                    if (abs(now - time)<5u) {
                        //gp_setcurxy(1u,4u);
                        //iprintf("Time: %u s       \r",(unsigned int)(now - start_time));
                        char bfr[20];
                        SetCurrentFgColor(WHITE);
            #ifdef USE_SURROUND
                        SetCurrentBgColor(GRAY);
            #endif
                        siprintf(bfr, "%03u",(unsigned int)(now - start_time));
                        gp_writexy(myboard.get_x_pixel()-30u,myboard.get_y_pixel(),0x21,bfr);
                    }
                    time=now;
                }

                result = play_game(myboard, false);

            }while(result==0);

            if (result==TOGGLE_MODE || result==NEW_GAME) {
                if (myboard.is_started()) {
                    //GDP_erapen();
                    //const uint8_t y_size = myboard.get_board_height();
                    //SetCurrentBgColor(GRAY);
                    //SetCurrentFgColor(WHITE);
                    //gp_draw_filled_rect(CCNV_X(2u),CCNV_Y(BOARD_Y+y_size-1u), 26u*6u /*512u-CCNV_X(2u)*/, 40u);

                    //gp_writexy(CCNV_X(1u),CCNV_Y(BOARD_Y+y_size)/2u,0x11u, "abort current game (y/n)?");
                    write_text_centered_with_bg(myboard, "abort current game (y/n)?");
                    const char key = wait_key("yn");
                    if(key=='y') {
                        if (result==TOGGLE_MODE) {
                            beginner_mode=!beginner_mode;
                        }
                        result=NEW_GAME;
                    }else{
                        if(!mouse_init) {
                            draw_mouse_pointer();   // delete old mouse pointer
                        }
                        myboard.draw();
                        mouse_init=true;
                        /*if(!mouse_init) {
                            draw_mouse_pointer();
                        }*/
                        result=0;
                    }
                }else{
                    if (result==TOGGLE_MODE) {
                        beginner_mode=!beginner_mode;
                    }
                    result=NEW_GAME;
                }
            }else if(result<0) {
                play_explosion();

                /*SetCurrentFgColor(RED);
                gp_writexy(CCNV_X(1u),CCNV_Y(BOARD_Y+y_size),0x33u, "Game over - you died!");*/

                draw_smiley(myboard,false);
                // wait until clicked on Smiley
                do {
                    result = play_game(myboard, true);
                }while(result==0);

            }else if(result==1u) {
                /*gp_clearscreen();
                gp_cursor_off();
                gp_setflip(0u,0u);*/
                SetCurrentFgColor(GREEN);
                const uint8_t y_size = myboard.get_board_height() + 1;
                SetCurrentBgColor(BLACK);
                GDP_erapen();
                gp_draw_filled_rect(0,CCNV_Y(BOARD_Y+y_size-1u)*2u, 512u, 80u);

                gp_writexy(CCNV_X(1u),CCNV_Y(BOARD_Y+y_size),0x33u, "Congratulations -  you won!");
                SetCurrentFgColor(WHITE);
                gp_writexy(CCNV_X(1u),CCNV_Y(BOARD_Y+y_size-1u),0x11u, "press any key to continue...");

                highscore hs("mine_hsc.bin");
                gp_ci();

                gp_clearscreen();
                gp_cursor_on();
                gp_setflip(10u,10u);
                puts("Please enter your name for highscore list\r\n");
                //gets(bfr);
                char bfr[80u]={0u};
                fgets(bfr, sizeof(bfr), stdin);
                puts("\r\n");
                const size_t len= strlen(bfr);
                if(len>1u) {
                    gp_cursor_off();
                    gp_setflip(0u,0u);
                    const uint16_t level = (beginner_mode)?0u:1u;
                    const uint8_t new_entry = hs.InsertSorted(std::string(bfr),time, (uint32_t)time - start_time,level);
                    hs.Save();
                    hs.Display(level,new_entry);

                }else{
                    puts("Highscore skipped...\r\n");
                }
                //puts("Press any key to continue...");
                //gp_ci();
                puts("New game y/n?");
                /*char key = '\0';
                do {
                    key = tolower(gp_ci());
                }while(key!='y' && key!='n');*/
                const char key = wait_key("yn");
                result=(key=='y')?NEW_GAME:GAME_EXIT;
                gp_clearscreen();
            }
        }while(result==0);
    }while(result!=GAME_EXIT);
    SetCurrentBgColor(BLACK);
    gp_clearscreen();

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

static key_cmd_t decode_keyboard(void)
{
    key_cmd_t key_stat = none_e;
    char key = 0;
    if (gp_csts()) {
         key = tolower(gp_ci());
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
            case 'n':
                key_stat = new_game_e;
                break;
            case 'm':
                key_stat = toggle_mode_e;
                break;
        }
    }
    return key_stat;
}

static xy_pos_t get_smiley_pos(board const & myboard)
{
    const uint16_t x_s = CCNV_X(BOARD_X);
    const uint16_t x_e = myboard.get_x_pixel();
    const uint16_t center_x=x_s+((x_e-x_s)/2u);
    const uint16_t center_y=(2u*myboard.get_y_pixel())+35u;
    const xy_pos_t center = {.x=center_x, .y=center_y};
    return center;
}

static int16_t play_game(board& myboard, const bool mode=false) {
    //static const uint8_t mouse_pointer[]= {0x7f,0x7e,0x71,0xf0,0};
    int16_t dx=0;
    int16_t dy=0;
    int16_t result = 0;

    const key_cmd_t keybd  = decode_keyboard();
    const uint8_t keys     = gp_get_mouse(&dx, &dy);

    if((dx!=0) || (dy!=0) || (keys!=0u)) {
        if(!mouse_init) {
            // delete old mouse pointer
            draw_mouse_pointer();
        }

        mouse_init=false;
        mouse_x = limit_value(mouse_x+(dx*2),0, X_RES-1);
        mouse_y = limit_value(mouse_y+dy,0, Y_RES-1);

        if (!mode) {
            const uint16_t x = (mouse_x - CCNV_X(BOARD_X)) / (4u*X_SCALE);
            const uint16_t y = (mouse_y - CCNV_Y(BOARD_Y)) / (4u*Y_SCALE);
            if((((keys & ~old_mouse_keys) & L_BUTTON)!=0u)) {
                result = myboard.click_field(x,y);
            }else if((((keys & ~old_mouse_keys) & R_BUTTON)!=0u)) {
                result = myboard.rclick_field(x,y);
            }
            draw_mouse_pointer();

            if((result==0) && myboard.check_done()) {
                result=1;
            }
        }else{
            // Game over mode
            if((((keys & ~old_mouse_keys) & L_BUTTON)!=0u)) {
                const xy_pos_t sc = get_smiley_pos(myboard);
                //gp_setcurxy(1u,4u);
                //iprintf("x:%03d y:%03d sx:%u xy: %u\r",mouse_x, mouse_y, sc.x, sc.y);
                if ((mouse_x >= (int16_t)(sc.x - SMILEY_RADIUS)) && (mouse_x <= (int16_t)(sc.x + SMILEY_RADIUS))  &&
                    (mouse_y >= (int16_t)((sc.y/2u) - SMILEY_RADIUS)) && (mouse_y <= (int16_t)((sc.y/2u) + SMILEY_RADIUS))) {
                        result = NEW_GAME;
                }
            }
            draw_mouse_pointer();
        }
    }
    if(!mode && (((~keys & old_mouse_keys) & L_BUTTON)!=0u)) {
        // left Mousebutton released
        draw_mouse_pointer();
        myboard.release();
        draw_mouse_pointer();
    }
    // Play with keyboard
    if (keybd != none_e) {
        if(!mouse_init) {
            draw_mouse_pointer();   // Delete mouse pointer if visible
            mouse_init=true;
        }
        switch(keybd){
            case exit_e:
                result = GAME_EXIT;
                break;
            case left_e:
                if (!mode) {
                    myboard.release();
                    myboard.move_mark(move_left_e);
                }
                break;
            case new_game_e:
                result = NEW_GAME;
                break;
            case right_e:
                if (!mode) {
                    myboard.release();
                    myboard.move_mark(move_right_e);
                }
                break;
            case up_e:
                if (!mode) {
                    myboard.release();
                    myboard.move_mark(move_up_e);
                }
                break;
            case down_e:
                if (!mode) {
                    myboard.release();
                    myboard.move_mark(move_down_e);
                }
                break;
            case mark_e:
                if (!mode) {
                    result = myboard.rclick_marked();
                }
                break;
            case uncover_e:
                if (!mode) {
                    result = myboard.click_marked();
                }
                break;
            case toggle_mode_e:
                result = TOGGLE_MODE;
                break;
            default:
                break;
        }
        if((!mode) && (result==0) && myboard.check_done()) {
            result=1;
        }
    }


    old_mouse_keys = keys;
    result =  ((keys & (L_BUTTON | R_BUTTON))==(L_BUTTON | R_BUTTON))?GAME_EXIT:result;
    return result;

}

static void draw_mouse_pointer()
{
    gp_setxor(true);
    /*gp_moveto(mouse_x-5,mouse_y);
    gp_drawto(mouse_x+5,mouse_y);
    gp_moveto(mouse_x,mouse_y-5);
    gp_drawto(mouse_x,mouse_y+5);*/
    GDP.ctrl2 = 1u<<4u; // Switch to User character set
    GDP.csize = 0x21u;
    GDP_moveto(mouse_x,mouse_y-6u);
    GDP_cmd(0x7Fu); // Draw mouse pointer
    gdp_ready();
    GDP.ctrl2 = 0u;
    gp_setxor(false);
}

static void play_explosion(void)
{
    static const uint8_t explosion[]= {0,0,0,0,0,0,0xff,0x07,0x10,0,0x10,0x10,0x10,0,0x38,0};
    gp_sound(explosion);
}

static void draw_sad_eye(const uint16_t center_x, const uint16_t center_y)
{
    gp_moveto(center_x-4u,center_y-2u);
    gp_drawto(center_x+4u,center_y+2u);
    gp_moveto(center_x-4u,center_y+2u);
    gp_drawto(center_x+4u,center_y-2u);
}

//void draw_smiley(const uint16_t center_x, const uint16_t center_y, const bool happy)
static void draw_smiley(board const & myboard, const bool happy)
{

    /*const uint16_t x_s = CCNV_X(BOARD_X);
    const uint16_t x_e = myboard.get_x_pixel();
    const uint16_t center_x=x_s+((x_e-x_s)/2u);
    const uint16_t center_y=(2u*myboard.get_y_pixel())+35u;*/
    const xy_pos_t center =get_smiley_pos(myboard);
    //draw_smiley(x_s+((x_e-x_s)/2u),myboard.get_y_pixel()+20u,true);

    const uint16_t radius = SMILEY_RADIUS;
    SetCurrentFgColor(YELLOW);
    SetCurrentBgColor(BLACK);
    gp_draw_filled_circle(center.x, center.y, radius);
    GDP_erapen();
    //SetCurrentFgColor(RED);
    if (happy) {
        draw_arc(center.x, center.y/2u, radius-10u,135,225);
        draw_arc(center.x-(radius/2u)+2u,center.y/2u+radius/5u,radius/6u,-65,65);
        draw_arc(center.x+(radius/2u)-2u,center.y/2u+radius/5u,radius/6u,-65,65);
    }else{
        draw_arc(center.x,center.y/2u-radius/2u,radius-10u,-45,45);
        draw_sad_eye(center.x-(radius/2u)+2u,center.y/2u+radius/5u);
        draw_sad_eye(center.x+(radius/2u)-2u,center.y/2u+radius/5u);
    }

    GDP_drawpen();
}

static void draw_3d_rect(const uint16_t x_pos, const uint16_t y_pos, const uint16_t dx, const uint16_t dy)
{
    // Current FG color used for rect - destroyed afterwards
    gp_draw_filled_rect(x_pos, y_pos*2u, dx, dy*2u);
    SetCurrentFgColor(MAGENTA); // very dark grey
    gp_moveto(x_pos + 1u, y_pos + 1u );
    gp_drawto(x_pos + dx - 2u, y_pos + 1u );
    gp_drawto(x_pos + dx - 2u, y_pos + dy - 2u );
    gp_moveto(x_pos, y_pos);
    gp_drawto(x_pos + dx - 1u, y_pos);
    gp_drawto(x_pos + dx - 1u, y_pos + dy - 1u);

    SetCurrentFgColor(CYAN);    // very light grey
    //GDP_moveto(x+CCNV_X(1u)-2u,y+CCNV_Y(1u)-1u);
    gp_moveto(x_pos + dx - 2u, y_pos + dy - 1u );
    gp_drawto(x_pos, y_pos + dy - 1u);
    gp_drawto(x_pos, y_pos + 1u);
    gp_moveto(x_pos + dx - 3u, y_pos + dy - 2u );
    gp_drawto(x_pos + 1u , y_pos + dy - 2u);
    gp_drawto(x_pos + 1u, y_pos + 2u);
}

/*static char wait_key(const char* const p_abort_chars)
{
    char key = '\0';
    do {
        key = tolower(gp_ci());
    }while(std::strchr(p_abort_chars, key)==NULL);
    return key;
}*/

static char wait_key(const std::string abort_chars)
{
    char key = '\0';
    do {
        key = tolower(gp_ci());
    }while(abort_chars.find(key,0)==std::string::npos);
    return key;
}

/*void write_text_centered_with_bg(board const & myboard, const std::string text)
{
    GDP_erapen();
    const uint8_t y_size = myboard.get_board_height();
    const uint8_t x_size = myboard.get_board_width();
    const size_t len = text.length()*6u;
    SetCurrentBgColor(GRAY);
    SetCurrentFgColor(WHITE);

    const uint16_t x_pos= CCNV_X(BOARD_X)+(CCNV_X(x_size)-len)/2u;
    gp_draw_filled_rect(x_pos,CCNV_Y(BOARD_Y+y_size-1u), len+4u, 40u);

    GDP_drawpen();
    gp_writexy(x_pos + 2u,CCNV_Y(BOARD_Y+y_size)/2u,0x11u, text.c_str());
}*/

void write_text_centered_with_bg(board const & myboard, const std::string text)
{
    const uint8_t y_size = myboard.get_board_height();
    const uint8_t x_size = myboard.get_board_width();
    const size_t len = text.length()*6u;
    GDP_drawpen();
    //SetCurrentBgColor(GRAY);
    SetCurrentFgColor(WHITE);

    const uint16_t x_pos= CCNV_X(BOARD_X)+(CCNV_X(x_size)-len)/2u;
    draw_3d_rect(x_pos,CCNV_Y(BOARD_Y+y_size-1u)/2u, len+6u, 40u/2u);

    SetCurrentBgColor(WHITE);
    SetCurrentFgColor(BLACK);
    gp_writexy(x_pos + 3u,CCNV_Y(BOARD_Y+y_size)/2u,0x11u, text.c_str());
}