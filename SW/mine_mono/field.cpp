/*-
 * Copyright (C) 2023	Andreas Voggeneder
 */
/*- Minesweeper field class */

#include "field.h"

// define the class constructor
field::field()
{
    this->isMine=false;
    this->info=0u;
    this->hidden=true;
    this->hl=false;
}

void field::setInfo(const uint8_t info)
{
    this->info = info;
}

uint8_t field::getInfo()
{
    return this->info;
}

void field::setMine(const bool mine)
{
    this->isMine = mine;
}

bool field::checkMine()
{
    return this->isMine;
}

bool field::is_hidden()
{
    return this->hidden;
}

void field::highlight(const bool highlight)
{
    this->hl = highlight;
}

bool field::unhide()
{
    this->hidden=false;
    if(this->isMine) {
        // we clicked on a mine
        return true;
    }
    return false;
}

#ifdef USE_GDP_FPGA
void field::draw(const uint16_t x, const uint16_t y)
{
    uint8_t color = GRAY;
    if(this->hl) {
        color = GREEN;
    }else if(!this->hidden) {
        if (this->isMine) {
            color = RED;
        }else{
            color = WHITE | DARK;
        }
    }
    const uint8_t csize_backup = GDP.csize;
    GDP.csize = ((X_SCALE)<<4u) |(Y_SCALE);
    //const uint8_t color = (isMine)?RED:GRAY;
    SetCurrentFgColor(color);
    GDP_draw4x4(x,y);
    if((this->info>0u) && (this->info<=9u)) {
        SetCurrentFgColor(WHITE);
        GDP.csize = 0x11;
        GDP_moveto(x+8u,y+2u);
        GDP.cmd = '0' + this->info;
    }else if(this->info==0xffu) {
        // marked as mine
        SetCurrentFgColor(RED);
        GDP.csize = 0x21;
        GDP_moveto(x+6u,y+2u);
        GDP.cmd = '*';
        //gp_draw_filled_circle(x+6u,y+2u,10u);
    }

    gdp_ready();
    GDP.csize = csize_backup;
    if(this->hidden) {
        SetCurrentFgColor(MAGENTA); // very dark grey
        /*GDP_moveto(x+CCNV_X(1u),y);
        GDP_draw_line(-(int8_t)CCNV_X(1u),0u);
        GDP_draw_line(0,CCNV_Y(1u));*/
        GDP_moveto(x+1u,y+1u);
        GDP_draw_line(CCNV_X(1u)-2u,0u);
        GDP_draw_line(0,CCNV_Y(1u)-2u);
        GDP_moveto(x,y);
        GDP_draw_line(CCNV_X(1u)-1u,0u);
        GDP_draw_line(0,CCNV_Y(1u));
        SetCurrentFgColor(CYAN);    // very light grey
        //SetCurrentFgColor(WHITE);
        GDP_moveto(x+CCNV_X(1u)-2u,y+CCNV_Y(1u)-1u);
        GDP_draw_line(-((int8_t)(CCNV_X(1u)-3u)),0u);
        GDP_draw_line(0,-((int8_t)(CCNV_Y(1u)-3u)));
    }else{
        SetCurrentBgColor(BLACK);
        GDP_erapen();
        GDP_moveto(x+CCNV_X(1u),y);
        GDP_draw_line(-(int8_t)CCNV_X(1u),0u);
        GDP_draw_line(0,CCNV_Y(1u));
        GDP_drawpen();
    }

}
#else
void field::draw(const uint16_t x, const uint16_t y)
{
    if((!this->hidden) && (!this->isMine)) {
        GDP_erapen();
    }

    const uint8_t csize_backup = GDP.csize;
    GDP.csize = ((X_SCALE)<<4u) |(Y_SCALE);

    GDP_draw4x4(x,y);
    GDP_drawpen();
    gdp_ready();
    gp_setxor(true);
    if(this->hl) {
        gdp_ready();
        GDP.csize = 0x21;
        GDP_moveto(x+6u,y+2u);
        GDP.cmd = '\x7f';
    }else if((this->info>0u) && (this->info<=9u)) {
        GDP.csize = 0x11;
        GDP_moveto(x+8u,y+2u);
        GDP.cmd = '0' + this->info;
    }else if(this->info==0xffu) {
        // marked as mine
        gdp_ready();
        GDP.csize = 0x21u;
        GDP_moveto(x+6u,y+2u);
        GDP.cmd = '*';
    }

    gdp_ready();
    gp_setxor(false);
    GDP.csize = csize_backup;

    if((!this->hidden) && (!this->isMine)) {
        GDP_drawpen();
    }else{
        GDP_erapen();
    }
    GDP_moveto(x+CCNV_X(1u),y);
    GDP_draw_line(-(int8_t)(CCNV_X(1u)),0u);
    GDP_draw_line(0,CCNV_Y(1u));
    GDP_drawpen();
}
#endif