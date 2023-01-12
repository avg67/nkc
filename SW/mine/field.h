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

    public:
        // class constructor
        field();

        void setInfo(const uint8_t info);
        uint8_t getInfo();
        void setMine(const bool mine);
        bool checkMine();
        bool unhide();
        bool is_hidden();
        void highlight(const bool highlight);
        void draw(const uint16_t x, const uint16_t y);
};

#endif
