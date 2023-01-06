#include <array>
#include "field.h"
#include "mine.h"

#ifndef BOARD_H
#define BOARD_H

class board
{
    private:
        std::array<std::array<field, BOARD_X_SIZE>, BOARD_Y_SIZE> arr;

        uint8_t count_marked_mines();
    public:
        board();

        void unhide_all();
        bool check_done();
        uint8_t get_info(const uint16_t x, const uint16_t y);
        bool unhide(const uint16_t x, const uint16_t y);
        void setInfo(const uint16_t x, const uint16_t y,const uint8_t info);
        uint8_t getInfo(const uint16_t x, const uint16_t y);
        uint8_t count_mines(const uint16_t x, const uint16_t y);

        void unhide_surrounding(const uint16_t x, const uint16_t y, const uint16_t level);
        void draw(void);
//        int16_t check_mouse();


};
#endif
