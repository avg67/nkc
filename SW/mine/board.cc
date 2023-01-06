//#include <iostream>
//#include <string>
#include "board.h"
#include "gp_helper.h"

board::board()
{
    uint8_t nr_mines=0u;
//    this->mouse_x=256;
//    this->mouse_y=128;
    do {
        const uint16_t mine_pos = rand() % (BOARD_X_SIZE*BOARD_Y_SIZE);
        //iprintf("%u ",mine_pos);
        const uint8_t x_pos = (mine_pos % BOARD_X_SIZE);
        const uint8_t y_pos = (mine_pos / BOARD_X_SIZE);
        if(!arr[x_pos][y_pos].checkMine()) {
            nr_mines++;
            arr[x_pos][y_pos].setMine(true);
        }
    }while(nr_mines<NR_MINES);
    //iprintf("\r\n");
}

uint8_t board::get_info(const uint16_t x, const uint16_t y)
{
    return this->arr[x][y].getInfo();
}

bool board::unhide(const uint16_t x, const uint16_t y)
{
    return this->arr[x][y].unhide();
}

void board::setInfo(const uint16_t x, const uint16_t y,const uint8_t info)
{
    this->arr[x][y].setInfo(info);
}

uint8_t board::getInfo(const uint16_t x, const uint16_t y)
{
    return this->arr[x][y].getInfo();
}

void board::draw()
{
    //auto begin{ arr.begin() };

    //for(uint16_t y=0;y<BOARD_Y_SIZE;y++) {
    for(uint16_t y=0u;y<arr.size();y++) {
        //for(uint16_t x=0;x<BOARD_X_SIZE;x++) {
        for(uint16_t x=0u;x<arr[y].size();x++) {
            const uint16_t x_pos = CCNV_X(BOARD_X) + (x * 4u * X_SCALE);
            const uint16_t y_pos = CCNV_Y(BOARD_Y) + (y * 4u * Y_SCALE);
            arr[x][y].draw(x_pos,y_pos);
        }
        SetCurrentBgColor(BLACK);
        GDP_erapen();
        gp_moveto(CCNV_X(BOARD_X),CCNV_Y(BOARD_Y + y));
        gp_drawto(CCNV_X(BOARD_X+BOARD_X_SIZE),CCNV_Y(BOARD_Y + y));
        GDP_drawpen();
//		iprintf("\r\n");
    }
    GDP_erapen();
    for(uint16_t x=0;x<BOARD_X_SIZE;x++) {
        gp_moveto(CCNV_X(BOARD_X + x),CCNV_Y(BOARD_Y));
        gp_drawto(CCNV_X(BOARD_X + x),CCNV_Y(BOARD_Y + BOARD_Y_SIZE));
    }
    GDP_drawpen();
    //char bfr[50];
    //siprintf(bfr,"Mines: %u  ",(unsigned int)count_marked_mines());
    //gp_writexy(10u,240,0x11, bfr);
    gp_setcurxy(1u,5u);
    iprintf("Mines found: %u of %u    \r",(unsigned int)count_marked_mines(),NR_MINES);

}

// Count surrounding mines
uint8_t board::count_mines(const uint16_t x, const uint16_t y)
{
    uint8_t nr_mines = 0u;
    const uint16_t x_start = (x>0u)?x-1u:x;
    const uint16_t x_end = (x<(BOARD_X_SIZE-1u))?x+1:x;
    const uint16_t y_start = (y>0u)?y-1:y;
    const uint16_t y_end = (y<(BOARD_Y_SIZE-1u))?y+1:y;
    for(uint16_t x1 = x_start; x1<=x_end;x1++) {
        for(uint16_t y1 = y_start; y1<=y_end;y1++) {
            if(((x1!=x) || (y1!=y)) && (this->arr[x1][y1].checkMine())) {
                nr_mines++;
            }
        }
    }
    return nr_mines;
}

uint8_t board::count_marked_mines()
{
    uint8_t nr_marked_mines = 0u;
    for(uint16_t y=0u;y<arr.size();y++) {
        for(uint16_t x=0u;x<arr[y].size();x++) {
            if(arr[x][y].getInfo()==0xff) {
                nr_marked_mines++;
            }
        }
    }
    return nr_marked_mines;
}

// display all mines
void board::unhide_all()
{
    for(uint16_t y=0u;y<arr.size();y++) {
        for(uint16_t x=0u;x<arr[y].size();x++) {
            arr[x][y].unhide();
        }
    }
}

/*void board::unhide_surrounding(const uint16_t x, const uint16_t y, const uint16_t level) {
    const uint8_t mines = count_mines(x,y);
    if (mines==0u) {
        arr[x][y].unhide();
        if(level<10u) {
            const uint16_t x_start = (x>0u)?x-1u:x;
            const uint16_t x_end = (x<(BOARD_X_SIZE-1u))?x+1:x;
            const uint16_t y_start = (y>0u)?y-1:y;
            const uint16_t y_end = (y<(BOARD_Y_SIZE-1u))?y+1:y;
            for(uint16_t x1 = x_start; x1<=x_end;x1++) {
                for(uint16_t y1 = y_start; y1<=y_end;y1++) {
                    unhide_surrounding(x1,y1,level+1u);
                }
            }
        }
    }else{
        arr[x][y].setInfo(mines);
    }
}*/

void board::unhide_surrounding(const uint16_t x, const uint16_t y, const uint16_t level) {
    const uint8_t mines = count_mines(x,y);
    arr[x][y].unhide();
    if (mines==0u) {
        if(level<50u) {
            const uint16_t x_start = (x>0u)?x-1u:x;
            const uint16_t x_end = (x<(BOARD_X_SIZE-1u))?x+1:x;
            const uint16_t y_start = (y>0u)?y-1:y;
            const uint16_t y_end = (y<(BOARD_Y_SIZE-1u))?y+1:y;
            for(uint16_t x1 = x_start; x1<=x_end;x1++) {
                for(uint16_t y1 = y_start; y1<=y_end;y1++) {
                    if(((x1!=x) || (y1!=y)) && arr[x1][y1].is_hidden()) {
                        unhide_surrounding(x1,y1,level+1u);
                    }
                }
            }
        }
    }else{
        arr[x][y].setInfo(mines);
    }
}

bool board::check_done()
{
    uint8_t nr_hidden=0u;
    for(uint16_t y=0u;y<arr.size();y++) {
        for(uint16_t x=0u;x<arr[y].size();x++) {
            if (arr[x][y].is_hidden() && (arr[x][y].getInfo()!=0xFFu)){
                nr_hidden++;
            }
        }
    }
    // we are done when there are no more hidden fields
    return (nr_hidden==0u);
}

#if 0
int16_t board::check_mouse() {
    //static const uint8_t mouse_pointer[]= {0x7f,0x7e,0x71,0xf0,0};
    int16_t dx=0;
    int16_t dy=0;
    int16_t result = 0;
    static uint8_t old_mouse_keys =0u;
    //static bool mouse_init=true;
    const uint8_t keys = gp_get_mouse(&dx, &dy);
    if((dx!=0) || (dy!=0) || (keys!=0)) {
        //if(!mouse_init) {
            //mouse_init=false;
            // delete old mouse pinter
            draw_mouse_pointer();
        //}
        this->mouse_x +=(dx*2);
        this->mouse_y +=dy;
        uint16_t x = (this->mouse_x - CCNV_X(BOARD_X)) / (4u*X_SCALE);
        uint16_t y = (this->mouse_y - CCNV_Y(BOARD_Y)) / (4u*Y_SCALE);

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
                if(arr[x][y].getInfo()!=0xFF) {
                    if(arr[x][y].unhide()) {
                        result = -1;
                    }
                    if (result==0) {
                        const uint8_t nr_mines = count_mines(x,y);
                        arr[x][y].setInfo(nr_mines);
                        unhide_surrounding(x,y,0u);
                        //iprintf("Mines: %u         \r\n",nr_mines);
                    }else{
                        // Game is over - unhide all mines
                        //iprintf("Game over!\r\n");
                        unhide_all();
                        //game_over();
                    }
                }
                draw();
                //arr[x][y].draw(x_pos,y_pos);

            }else if(((keys & ~old_mouse_keys) & R_BUTTON)!=0u) {
                arr[x][y].setInfo((arr[x][y].getInfo()!=0)?0u:0xFFu);
                draw();
            }
        }
        //iprintf("0x%X %03d %03d %02d %02d      \r", keys, this->mouse_x, this->mouse_y, x, y);
        old_mouse_keys = keys;
        draw_mouse_pointer();
        if((result==0) && check_done()) {
            result=1;
        }

    }
    return ((keys & (L_BUTTON | R_BUTTON))==(L_BUTTON | R_BUTTON))?0xffu:result;
}

void board::draw_mouse_pointer()
{
    gp_setxor(true);
    gp_moveto(this->mouse_x-5,this->mouse_y);
    gp_drawto(this->mouse_x+5,this->mouse_y);
    gp_moveto(this->mouse_x,this->mouse_y-5);
    gp_drawto(this->mouse_x,this->mouse_y+5);
    gp_setxor(false);
}
#endif

/*void board::game_over() {
    GDP.ctrl2 |= (1u<<5u); // turn on BG mode
    do {
        SetCurrentFgColor(RED);
        gp_writexy(CCNV_X(14u),CCNV_Y(BOARD_Y+BOARD_Y_SIZE/2u),0x33u, "Game over!");
        delay_ms(500u);
        SetCurrentFgColor(BLACK);
        gp_writexy(CCNV_X(14u),CCNV_Y(BOARD_Y+BOARD_Y_SIZE/2u),0x33u, "          ");
        delay_ms(500u);
    }while(!gp_csts());
    gp_ci();
    GDP.ctrl2 &= ~(1u<<5u); // turn off BG mode
}*/