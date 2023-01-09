//#include <iostream>
//#include <string>
#include "board.h"
#include "gp_helper.h"

board::board()
{
    last_clicked.x = 0;
    last_clicked.y = 0;
    last_clicked.marked = false;
    uint8_t nr_mines=0u;
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

void board::draw()
{
    //auto begin{ arr.begin() };

    for(uint16_t y=0u;y<arr.size();y++) {
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
    iprintf("Mines found: %2u of %2u    \r",(unsigned int)count_marked_mines(),NR_MINES);

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
    for(auto y = arr.begin(); y != arr.end(); ++y) {
        for(auto f = y->begin(); f != y->end(); ++f) {
            if(f->getInfo()==0xff) {
                nr_marked_mines++;
            }
        }
    }
    return nr_marked_mines;
}

// display all mines
void board::unhide_all()
{
    for(auto y = arr.begin(); y != arr.end(); ++y) {
        for(auto f = y->begin(); f != y->end(); ++f) {
            f->unhide();
        }
    }
}

void board::unhide_surrounding(const uint16_t x, const uint16_t y, const uint16_t level) {
    const uint8_t mines = count_mines(x,y);
    field& f = arr[x][y];
    if (f.getInfo()!=0xFF) {
        f.unhide();
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
            f.setInfo(mines);
        }
    }
}

bool board::check_done()
{
    uint8_t nr_hidden=0u;
    for(auto y = arr.begin(); y != arr.end(); ++y) {
        for(auto f = y->begin(); f != y->end(); ++f) {
            if (f->is_hidden() && (f->getInfo()!=0xFFu)){
                nr_hidden++;
            }
        }
    }
    // we are done when there are no more hidden fields
    return (nr_hidden==0u);
}

int16_t board::click_field(const uint16_t x, const uint16_t y)
{
    int16_t result=0;
    if ((y<BOARD_Y_SIZE) && (x<BOARD_X_SIZE)) {
        field& f = arr[x][y];
        this->last_clicked = {.x=x,.y=y,.marked=false};

        if(f.getInfo()!=0xFF && f.is_hidden()) {
            if(f.unhide()) {
                result = -1;
            }
            if (result==0) {
                const uint8_t nr_mines = count_mines(x,y);
                f.setInfo(nr_mines);
                unhide_surrounding(x,y,0u);
                //iprintf("Mines: %u         \r\n",nr_mines);
            }else{
                // Game is over - unhide all mines
                //iprintf("Game over!\r\n");
                unhide_all();
            }
        }else if (!f.is_hidden()) {
            show_fields(x,y,true);
        }
        draw();
        //arr[x][y].draw(x_pos,y_pos);
    }
    return result;
}

void board::show_fields(const uint16_t x, const uint16_t y, const bool hold)
{
    field& f = arr[x][y];
    if (!f.is_hidden()) { // && !this->last_clicked.clicked) {
        if (hold) {
            this->last_clicked.marked=true;
        }
        const uint16_t x_start = (x>0u)?x-1u:x;
        const uint16_t x_end = (x<(BOARD_X_SIZE-1u))?x+1:x;
        const uint16_t y_start = (y>0u)?y-1:y;
        const uint16_t y_end = (y<(BOARD_Y_SIZE-1u))?y+1:y;
        for(uint16_t x1 = x_start; x1<=x_end;x1++) {
            for(uint16_t y1 = y_start; y1<=y_end;y1++) {
                if((x1!=x) || (y1!=y))  {
                    this->arr[x1][y1].highlight(hold);
                }
            }
        }
        draw();
    }
}

void board::mark_field(const uint16_t x, const uint16_t y)
{
    if ((y<BOARD_Y_SIZE) && (x<BOARD_X_SIZE)) {
        field& f = arr[x][y];
        if(f.is_hidden() && ((f.getInfo()==0xFF) || (count_marked_mines()<NR_MINES))) {
            f.setInfo((f.getInfo()!=0)?0u:0xFFu);
            draw();
        }
    }
}

void board::release()
{
    if (this->last_clicked.marked) {
        this->last_clicked.marked=false;
        show_fields(this->last_clicked.x,this->last_clicked.y,false);
    }
}
