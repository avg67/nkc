//#include <iostream>
//#include <string>
#include "board.h"
#include "mine.h"

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
/*
    int16_t mouse_x=256;
    int16_t mouse_y=128;
    uint8_t keys=0u;
    do {
        int16_t dx=0;
        int16_t dy=0;
        keys = gp_get_mouse(&dx, &dy);
        mouse_x +=dx;
        mouse_y +=dy;
        if (mouse_x >= X_RES) {
            mouse_x = X_RES-1;
        }
        if (mouse_x < 0) {
            mouse_x = 0;
        }
        if (mouse_y >= Y_RES) {
            mouse_y = Y_RES-1;
        }
        if (mouse_y < 0) {
            mouse_y = 0;
        }
        iprintf("0x%X %03d %03d\r",keys, mouse_x,mouse_y);
    }while((keys & (L_BUTTON | R_BUTTON))==0);*/

    int16_t result=0;
    do {
        result = myboard.check_mouse();
    }while(result==0);

    if(result<0) {
        SetCurrentFgColor(RED);
        gp_writexy(CCNV_X(1u),CCNV_Y(BOARD_Y+BOARD_Y_SIZE+1),0x33u, "Game over - you died!");
    }else if(result==1u) {
        SetCurrentFgColor(GREEN);
        gp_writexy(CCNV_X(1u),CCNV_Y(BOARD_Y+BOARD_Y_SIZE+1u),0x33u, "Game over -  you won!");
    }

}