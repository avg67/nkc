#include "field.h"

// define the class constructor
field::field()
{
    this->isMine=false;
    this->info=0u;
    this->hidden=true;
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

bool field::unhide()
{
    this->hidden=false;
    if(this->isMine) {
        // we clicked on a mine
        return true;
    }
    return false;
}

void field::draw(const uint16_t x, const uint16_t y)
{
    uint8_t color = GRAY;
    if(!this->hidden) {
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
        gdp_ready();
        GDP.csize = 0x11;
        gp_moveto(x+8u,y+2u);
        SetCurrentFgColor(WHITE);
        GDP.cmd = '0' + this->info;
    }else if(this->info==0xffu) {
        // marked as mine
        gdp_ready();
        GDP.csize = 0x21;
        gp_moveto(x+6u,y+2u);
        SetCurrentFgColor(RED);
        GDP.cmd = '*';
        //gp_draw_filled_circle(x+6u,y+2u,10u);
    }

    gdp_ready();
    GDP.csize = csize_backup;
}