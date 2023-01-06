//#include <iostream>
//#include <string>
#include "board.h"
#include "mine.h"

static int16_t mouse_x;
static int16_t mouse_y;


int16_t check_mouse(board& myboard);
void draw_mouse_pointer();

int main(void)
{
    setvbuf(stdin, NULL, _IONBF, 0);
    setvbuf(stdout, NULL, _IONBF, 0);
    setvbuf(stderr, NULL, _IONBF, 0);

   const uint32_t sysinfo = gp_system();
   if (!((sysinfo & (IS_08 | IS_00 | IS_20 | GDP_FPGA)) == ((IS_08 << PADDING) | GDP_FPGA))) {
      #if(cpu==1)
         puts("Nicht unterstuetzte Systemkonfiguration.\r\nSie benoetigen eine GDP-FPGA sowie eine 68008 CPU!\r\n");
      #else
         puts("Nicht unterstuetzte Systemkonfiguration.\r\nSie benoetigen eine GDP-FPGA sowie eine 68000 CPU!\r\n");
      #endif
      return 0;
   }

    mouse_x=X_RES/2u;
    mouse_y=Y_RES/2u;

    gp_clearscreen();
    gp_cursor_off();
    gp_setflip(10u,10u);
    GDP_Ctrl.page_dma = 0u;

    //const clock_t start_time = _clock(NULL);

    srand((unsigned) _gettime());
    SetCurrentFgColor(RED);
    gp_writexy(200u,240,0x22u, "Minesweeper!");
    gp_setcurxy(1u,3u);
    iprintf("Press both Mouse keys together to exit\r");

    board myboard;
    myboard.draw();
    //const clock_t end_time = _clock(NULL);
    //iprintf("Time to draw board: %u ms\r\n", 1000u*(end_time-start_time)/CLOCKS_PER_SEC);
    //iprintf("Sizeof(field): %u\r\n",sizeof(field));

    int16_t result=0;
    time_t time=0;
    time_t start_time = _gettime();
    do {
        const time_t now = _gettime();
        if(now!=time) {
            gp_setcurxy(1u,4u);
            iprintf("Time: %u s\r",now-start_time);
            time=now;
        }

        result = check_mouse(myboard);
    }while(result==0);

    if(result<0) {
        SetCurrentFgColor(RED);
        gp_writexy(CCNV_X(1u),CCNV_Y(BOARD_Y+BOARD_Y_SIZE+1),0x33u, "Game over - you died!");
    }else if(result==1u) {
        SetCurrentFgColor(GREEN);
        gp_writexy(CCNV_X(1u),CCNV_Y(BOARD_Y+BOARD_Y_SIZE+1u),0x33u, "Game over -  you won!");
    }

}

int16_t check_mouse(board& myboard) {
    //static const uint8_t mouse_pointer[]= {0x7f,0x7e,0x71,0xf0,0};
    int16_t dx=0;
    int16_t dy=0;
    int16_t result = 0;
    static uint8_t old_mouse_keys =0u;
    static bool mouse_init=true;
    const uint8_t keys = gp_get_mouse(&dx, &dy);
    if((dx!=0) || (dy!=0) || (keys!=0)) {
        if(!mouse_init) {
            // delete old mouse pinter
            draw_mouse_pointer();
        }
        mouse_init=false;
        mouse_x +=(dx*2);
        mouse_y +=dy;
        uint16_t x = (mouse_x - CCNV_X(BOARD_X)) / (4u*X_SCALE);
        uint16_t y = (mouse_y - CCNV_Y(BOARD_Y)) / (4u*Y_SCALE);

        /*uint8_t cur_x=0u, cur_y=0u;
        gp_getcurxy(&cur_x,&cur_y);
        gp_moveto(this->mouse_x,this->mouse_y);
        gp_progzge(mouse_pointer);
        gp_setcurxy(cur_x,cur_y);
        */
        if ((y<BOARD_Y_SIZE) && (x<BOARD_X_SIZE)) {
            if(((keys & ~old_mouse_keys) & L_BUTTON)!=0u) {
                //const uint16_t x_pos = CCNV_X(BOARD_X) + (x * 4u * X_SCALE);
                //const uint16_t y_pos = CCNV_Y(BOARD_Y) + (y * 4u * Y_SCALE);
                //if(arr[x][y].getInfo()!=0xFF) {
                if(myboard.getInfo(x,y)!=0xFF) {
                    //if(arr[x][y].unhide()) {
                    if(myboard.unhide(x,y)) {
                        result = -1;
                    }
                    if (result==0) {
                        const uint8_t nr_mines = myboard.count_mines(x,y);
                        //arr[x][y].setInfo(nr_mines);
                        myboard.setInfo(x,y,nr_mines);
                        myboard.unhide_surrounding(x,y,0u);
                        //iprintf("Mines: %u         \r\n",nr_mines);
                    }else{
                        // Game is over - unhide all mines
                        //iprintf("Game over!\r\n");
                        myboard.unhide_all();
                        //game_over();
                    }
                }
                myboard.draw();
                //arr[x][y].draw(x_pos,y_pos);

            }else if(((keys & ~old_mouse_keys) & R_BUTTON)!=0u) {
                //arr[x][y].setInfo((arr[x][y].getInfo()!=0)?0u:0xFFu);
                if(myboard.is_hidden(x,y)) {
                    myboard.setInfo(x,y,(myboard.getInfo(x,y)!=0)?0u:0xFFu);
                    myboard.draw();
                }
            }
        }
        //iprintf("0x%X %03d %03d %02d %02d      \r", keys, this->mouse_x, this->mouse_y, x, y);
        old_mouse_keys = keys;
        draw_mouse_pointer();
        if((result==0) && myboard.check_done()) {
            result=1;
        }

    }
    return ((keys & (L_BUTTON | R_BUTTON))==(L_BUTTON | R_BUTTON))?0xffu:result;
}

void draw_mouse_pointer()
{
    gp_setxor(true);
    gp_moveto(mouse_x-5,mouse_y);
    gp_drawto(mouse_x+5,mouse_y);
    gp_moveto(mouse_x,mouse_y-5);
    gp_drawto(mouse_x,mouse_y+5);
    gp_setxor(false);
}