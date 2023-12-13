/*-
 * Copyright (C) 2023	Andreas Voggeneder
 */
/*- Minesweeper Board class */

#ifndef BOARD_H
#define BOARD_H

//#include <array>
#include <vector>
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

template <typename T>
class DynamicArray
{
    public:
        DynamicArray(){};

        DynamicArray(uint8_t rows, uint8_t cols): dArray(rows, std::vector<T>(cols)){}

        std::vector<T> & operator[](uint8_t i)
        {
            return dArray[i];
        }

        const std::vector<T> & operator[] (uint8_t i) const
        {
            return dArray[i];
        }
        uint8_t size(void) const
        {
            return dArray.size();
        }
        void resize(uint8_t rows, uint8_t cols)//resize the two dimentional array .
        {
            dArray.resize(rows);
            for(uint8_t i = 0u;i < rows;++i) dArray[i].resize(cols);
        }
    private:
        std::vector<std::vector<T> > dArray;
};

class board
{
    private:
        uint8_t x_size;
        uint8_t y_size;
        //std::array<std::array<field*, BOARD_X_SIZE>, BOARD_Y_SIZE> arr;
        DynamicArray<field> arr;
        uint8_t tot_nr_mines;
        coord_t last_clicked;
        uint8_t mark_x;
        uint8_t mark_y;
        bool game_started;

        uint8_t count_marked_mines(void) const;
        uint8_t count_mines(const uint16_t x, const uint16_t y, const bool count_marked) const;
        void unhide_surrounding(const uint16_t x, const uint16_t y, const uint16_t level);
        void update_mines_info(void) const;
        void set_mark(const bool visible); //, const uint8_t x, const uint8_t y);
    public:
        board(const bool beginner=true);
        ~board();

        void unhide_all(void);
        bool check_done(void) const;
        int16_t click_field(const uint16_t x, const uint16_t y);
        int16_t click_marked(void);
        void release(void);
        int16_t rclick_field(const uint16_t x, const uint16_t y);
        int16_t rclick_marked(void);
        void show_fields(const uint16_t x, const uint16_t y, const bool hold);
        void draw(void) const;
        uint8_t get_board_height() const;
        uint8_t get_board_width(void) const;
        void move_mark(const mark_move_t move);
        uint16_t get_x_pixel(void) const;
        uint16_t get_y_pixel(void) const;
        bool is_started(void) const;



};
#endif
