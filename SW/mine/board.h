#include <array>
#include "field.h"
#include "mine.h"

#ifndef BOARD_H
#define BOARD_H

class board
{
    private:
        std::array<std::array<field, BOARD_X_SIZE>, BOARD_Y_SIZE> arr;
        int16_t mouse_x;
        int16_t mouse_y;

        void draw_mouse_pointer();
        void unhide_all();
        bool check_done();
        uint8_t count_mines(const uint16_t x, const uint16_t y);
        uint8_t count_marked_mines();
        void unhide_surrounding(const uint16_t x, const uint16_t y, const uint16_t level);
        void game_over();

    public:
        board();

        void draw(void);
        int16_t check_mouse();


};
#endif
