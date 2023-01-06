//#include <iostream>
//#include <string>
#include <stdint.h>
#include "mine.h"

#ifndef FIELD_H
#define FIELD_H

// one field in minesweeper
class field
{
    private:
        bool isMine;
        uint8_t info;
        bool hidden;

    public:
        // class constructor
        field();

        void setInfo(const uint8_t info);
        uint8_t getInfo();
        void setMine(const bool mine);
        bool checkMine();
        bool unhide();
        bool is_hidden();
        void draw(const uint16_t x, const uint16_t y);
};

#endif
