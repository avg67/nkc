/*-
 * Copyright (C) 2023	Andreas Voggeneder
 */
/*- Minesweeper Board class */

#ifndef BOARD_H
#define BOARD_H

#include <array>
#include "field.h"
#include "mine.h"

typedef struct{
   uint16_t x;
   uint16_t y;
   bool marked;
}coord_t;

typedef enum {
    move_left_e,
    move_right_e,
    move_up_e,
    move_down_e
} mark_move_t;
class board
{
    private:
        std::array<std::array<field, BOARD_X_SIZE>, BOARD_Y_SIZE> arr;
        uint8_t x_size;
        uint8_t y_size;
        uint8_t tot_nr_mines;
        coord_t last_clicked;
        uint8_t mark_x;
        uint8_t mark_y;

        uint8_t count_marked_mines();
        uint8_t count_mines(const uint16_t x, const uint16_t y, const bool count_marked);
        void unhide_surrounding(const uint16_t x, const uint16_t y, const uint16_t level);
        void update_mines_info();
        void set_mark(const bool visible);
#ifndef USE_GDP_FPGA		
        inline void draw_field_border(void);
#endif		
    public:
        board(const bool beginner=true);

        void unhide_all();
        bool check_done();
        int16_t click_field(const uint16_t x, const uint16_t y);
        int16_t click_marked(void);
        void release();
        int16_t rclick_field(const uint16_t x, const uint16_t y);
        int16_t rclick_marked(void);
        void show_fields(const uint16_t x, const uint16_t y, const bool hold);
        void draw(void);
        uint8_t get_board_height();
        void move_mark(const mark_move_t move);

};
#endif
