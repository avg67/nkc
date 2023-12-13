/*-
 * Copyright (C) 2023	Andreas Voggeneder
 */
/*- Minesweeper Board class */

//#include <iostream>
//#include <string>
#include "board.h"
#include "gp_helper.h"

board::board(const bool beginner)
{
    if(beginner) {
        x_size = BEGINNER_X_SIZE;
        y_size = BEGINNER_Y_SIZE;
        tot_nr_mines = BEGINNER_NR_MINES;
    }else{
        x_size = INTERMEDIATE_X_SIZE;
        y_size = INTERMEDIATE_Y_SIZE;
        tot_nr_mines = INTERMEDIATE_NR_MINES;
    }

        /*for(auto px = py->begin(); px != py->end(); ++px) {
            *px=NULL;
        }*/
    arr.resize(y_size,x_size);
	for(uint16_t y=0u;y<arr.size();y++) {
        const uint16_t y_pos = CCNV_Y(BOARD_Y) + (y * 4u * Y_SCALE);
        for(uint16_t x=0u;x<arr[y].size();x++) {
            const uint16_t x_pos = CCNV_X(BOARD_X) + (x * 4u * X_SCALE);
            //arr[x][y] = new field(x_pos,y_pos,false);
            arr[x][y].setPos(x_pos,y_pos);
        }
    }
    last_clicked= {.x = 0, .y = 0, .marked = false};
    mark_x = mark_y = 0u;
    uint8_t nr_mines=0u;
    do {
        const uint16_t mine_pos = rand() % (x_size*y_size);
        //iprintf("%u ",mine_pos);
        const uint8_t x_pos = (mine_pos % x_size);
        const uint8_t y_pos = (mine_pos / x_size);
        if(!arr[x_pos][y_pos].checkMine()) {
            nr_mines++;
            arr[x_pos][y_pos].setMine(true);
        }
    }while(nr_mines<tot_nr_mines);
    game_started=false;
    //iprintf("\r\n");
}

board::~board()
{
    //iprintf("Destructor\r\n");
    /*for(uint16_t y=0u;y<y_size;y++) {
        for(uint16_t x=0u;x<x_size;x++) {
            delete arr[x][y];
        }
    }*/
}

void board::draw(void) const
{
    //auto begin{ arr.begin() };

    for(uint16_t y=0u;y<y_size;y++) {
        //const uint16_t y_pos = CCNV_Y(BOARD_Y) + (y * 4u * Y_SCALE);
        //for(uint16_t x=0u;x<x_size;x++) {
        for(uint16_t x=x_size-1u;x!=UINT16_MAX;x--) {
            //const uint16_t x_pos = CCNV_X(BOARD_X) + (x * 4u * X_SCALE);
            arr[x][y].draw();
        }
    }

    update_mines_info();
}

// Count surrounding mines
/*uint8_t board::count_mines(const uint16_t x, const uint16_t y)
{
    uint8_t nrm = 0u;
    const uint16_t x_start = (x>0u)?x-1u:x;
    const uint16_t x_end = (x<(x_size-1u))?x+1:x;
    const uint16_t y_start = (y>0u)?y-1:y;
    const uint16_t y_end = (y<(y_size-1u))?y+1:y;
    for(uint16_t x1 = x_start; x1<=x_end;x1++) {
        for(uint16_t y1 = y_start; y1<=y_end;y1++) {
            if(((x1!=x) || (y1!=y)) && (this->arr[x1][y1].checkMine())) {
                nrm++;
            }
        }
    }
    return nrm;
}*/

uint8_t board::count_mines(const uint16_t x, const uint16_t y, const bool count_marked=false) const
{
    uint8_t nrm = 0u;
    const uint16_t x_start = (x>0u)?x-1u:x;
    const uint16_t x_end = (x<(x_size-1u))?x+1:x;
    const uint16_t y_start = (y>0u)?y-1:y;
    const uint16_t y_end = (y<(y_size-1u))?y+1:y;
    for(uint16_t x1 = x_start; x1<=x_end;x1++) {
        for(uint16_t y1 = y_start; y1<=y_end;y1++) {
            const field& f = this->arr[x1][y1];
            if(((x1!=x) || (y1!=y)) && (((!count_marked && f.checkMine())) || (count_marked && f.getInfo()==0xff))) {
                nrm++;
            }
        }
    }
    return nrm;
}

/*uint8_t board::count_marked_mines()
{
    uint8_t nr_marked_mines = 0u;

    //for(auto y = arr.begin(); y != arr.end(); ++y) {
    uint16_t y; auto py = arr.begin();
    for(y=0u, py = arr.begin(); (y<y_size) && (py != arr.end()); ++py,++y) {
        //for(auto f = y->begin(); f != y->end(); ++f) {
        uint16_t x; auto f = py->begin();
        for(x=0, f = py->begin(); (x<x_size) && (f != py->end()); ++x,++f) {
            //field& f = this->arr[x][y];
            if((*f)->getInfo()==0xff) {
                nr_marked_mines++;
            }
        }
    }
    return nr_marked_mines;
}*/

uint8_t board::count_marked_mines(void) const
{
    uint8_t nr_marked_mines = 0u;

    for(uint16_t y=0u;y<y_size;y++) {
        for(uint16_t x=0u;x<x_size;x++) {
            if(arr[x][y].getInfo()==0xff) {
                nr_marked_mines++;
            }
        }
    }
    return nr_marked_mines;
}

void board::update_mines_info(void) const
{
    //gp_setcurxy(1u,5u);
    //iprintf("Mines found: %2u of %2u    \r",(unsigned int)count_marked_mines(),tot_nr_mines);
    char bfr[10];

    SetCurrentFgColor(WHITE);
#ifdef USE_SURROUND
    SetCurrentBgColor(GRAY);
#endif
    siprintf(bfr,"%03u",(unsigned int)(tot_nr_mines - count_marked_mines()));
    gp_writexy(CCNV_X(BOARD_X),get_y_pixel(),0x21,bfr);
}

// display all mines
/*void board::unhide_all()
{
    //for(auto y = arr.begin(); y != arr.end(); ++y) {
    for(uint16_t y=0u;y<y_size;y++) {
        //for(auto f = y->begin(); f != y->end(); ++f) {
        for(uint16_t x=0u;x<x_size;x++) {
            //f->unhide();
            arr[x][y].unhide();
        }
    }
}*/

void board::unhide_all(void)
{
    for(uint16_t y=0u;y<y_size;y++) {
        for(uint16_t x=0u;x<x_size;x++) {
            arr[x][y].unhide();
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
                const uint16_t x_end = (x<(x_size-1u))?x+1:x;
                const uint16_t y_start = (y>0u)?y-1:y;
                const uint16_t y_end = (y<(y_size-1u))?y+1:y;
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

bool board::check_done(void) const
{
    uint16_t nr_hidden=0u;
    for(uint16_t y=0u;y<y_size;y++) {
        for(uint16_t x=0u;x<x_size;x++) {
            const field& f = this->arr[x][y];
            if (f.is_hidden() && (f.getInfo()!=0xFFu)){
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
    if ((y<y_size) && (x<x_size)) {
        game_started=true;
        field& f = arr[x][y];
        this->last_clicked = {.x=x,.y=y,.marked=false};

        if(f.getInfo()!=0xFFu && f.is_hidden()) {
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
        /*const uint16_t x_pos = CCNV_X(BOARD_X) + (x * 4u * X_SCALE);
        const uint16_t y_pos = CCNV_Y(BOARD_Y) + (y * 4u * Y_SCALE);
        f.draw(x_pos,y_pos);
        update_mines_info();*/
    }
    return result;
}

int16_t board::click_marked(void)
{
    const int16_t result = click_field(mark_x, mark_y);
    set_mark(true);
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
        const uint16_t x_end = (x<(x_size-1u))?x+1:x;
        const uint16_t y_start = (y>0u)?y-1:y;
        const uint16_t y_end = (y<(y_size-1u))?y+1:y;
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

int16_t board::rclick_field(const uint16_t x, const uint16_t y)
{
    int16_t result = 0;
    if ((y<y_size) && (x<x_size)) {
        field& f = arr[x][y];
        if(f.is_hidden()) {
            // rclick on an invisible field
            if((f.getInfo()==0xFF) || (count_marked_mines()<tot_nr_mines)) {
                f.setInfo((f.getInfo()!=0)?0u:0xFFu);
                //draw();
                //const uint16_t x_pos = CCNV_X(BOARD_X) + (x * 4u * X_SCALE);
                //const uint16_t y_pos = CCNV_Y(BOARD_Y) + (y * 4u * Y_SCALE);
                f.draw();
                update_mines_info();
            }
        }else{
            // rclick on an visible field
            const uint8_t marked_mines = count_mines(x,y, true);
            // Check if there are as much mines marked as hidden surrounding this field
            if (f.getInfo() == marked_mines) {
                const uint16_t x_start = (x>0u)?x-1u:x;
                const uint16_t x_end = (x<(x_size-1u))?x+1:x;
                const uint16_t y_start = (y>0u)?y-1:y;
                const uint16_t y_end = (y<(y_size-1u))?y+1:y;
                bool exit = false;
                for(uint16_t x1 = x_start; x1<=x_end && !exit;x1++) {
                    for(uint16_t y1 = y_start; y1<=y_end;y1++) {
                        field& f = arr[x1][y1];
                        if(f.getInfo()!=0xFF && f.is_hidden()) {
                            if(f.unhide()) {
                                result = -1;
                            }
                            if (result==0) {
                                const uint8_t nr_mines = count_mines(x1,y1);
                                f.setInfo(nr_mines);
                                unhide_surrounding(x1,y1,0u);
                                //iprintf("Mines: %u         \r\n",nr_mines);
                            }else{
                                // Game is over - unhide all mines
                                //iprintf("Game over!\r\n");
                                unhide_all();
                                exit=true;
                                break;
                            }
                        }
                    }
                }
                draw();
            }
        }
    }
    return result;
}

int16_t board::rclick_marked(void)
{
    const int16_t result = rclick_field(mark_x, mark_y);
    set_mark(true);
    return result;
}

void board::release(void)
{
    if (this->last_clicked.marked) {
        this->last_clicked.marked=false;
        show_fields(this->last_clicked.x,this->last_clicked.y,false);
    }
}

uint8_t board::get_board_height(void) const
{
    return this->y_size;
}

uint8_t board::get_board_width(void) const
{
    return this->x_size;
}

void board::set_mark(const bool visible) //, const uint16_t x, const uint16_t y)
{
    if ((mark_y < y_size) && (mark_x < x_size)) {
        const uint16_t y_pos = CCNV_Y(BOARD_Y) + (mark_y * 4u * Y_SCALE);
        const uint16_t x_pos = CCNV_X(BOARD_X) + (mark_x * 4u * X_SCALE);
        arr[mark_x][mark_y].draw();
        if (visible) {
            SetCurrentFgColor(YELLOW);
            GDP_moveto(x_pos+1,y_pos+1);
            GDP_draw_line((4*(int16_t)X_SCALE)-2,0);
            GDP_draw_line(0,(4*(int16_t)Y_SCALE)-2);
            GDP_draw_line((-4*(int16_t)X_SCALE)+2,0);
            GDP_draw_line(0,(-4*(int16_t)Y_SCALE)+2);
        }
    }

}

void board::move_mark(const mark_move_t move)
{
    set_mark(false); //
    switch (move) {
        case move_left_e:
            if (mark_x > 0u) {
                mark_x -= 1u;
            }
            break;
        case move_right_e:
            if (mark_x < (x_size - 1u)) {
                mark_x += 1u;
            }
            break;
        case move_down_e:
            if (mark_y > 0u) {
                mark_y -= 1u;
            }
            break;
        case move_up_e:
            if (mark_y < (y_size - 1u)) {
                mark_y += 1u;
            }
            break;
    }
    set_mark(true);

}

uint16_t board::get_x_pixel(void) const
{
    return CCNV_X(BOARD_X) + (x_size * 4u * X_SCALE);
}

uint16_t board::get_y_pixel(void) const
{
    return CCNV_Y(BOARD_Y) + (y_size * 4u * Y_SCALE);
}

bool board::is_started(void) const
{
    return game_started;
}
