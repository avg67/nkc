/*-
 * Copyright (C) 2023	Andreas Voggeneder
 */
/*- Minesweeper field class */

#ifndef FIELD_H
#define FIELD_H

//#include <iostream>
//#include <string>
#include <stdint.h>
#include "mine.h"

// one field in minesweeper
class field
{
    private:
        bool isMine;
        uint8_t info;
        bool hidden;
        bool hl;
        uint16_t x;
        uint16_t y;

        void draw(const uint16_t x, const uint16_t y) const;
    public:
        // class constructor
        field();
        field(const uint16_t x, const uint16_t y, bool is_mine);
        ~field();

        void setInfo(const uint8_t info);
        uint8_t getInfo(void) const;
        void setMine(const bool mine);
        void setPos(const uint16_t x, const uint16_t y);
        bool checkMine(void) const;
        bool unhide(void);
        bool is_hidden(void) const;
        void highlight(const bool highlight);

        void draw(void) const;
};

#endif
