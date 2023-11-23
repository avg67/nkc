/*-
 * Copyright (C) 2023	Andreas Voggeneder
 */
/*- Highscore load/store class */

#ifndef HIGHSCORE_H
#define HIGHSCORE_H

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
//#include <delay.h>
#include <string.h>
#include <stdbool.h>
#include <ndrcomp/target.h>
#include <ndrcomp/sysclock.h>
#include "../../nkc_common/nkc/nkc.h"
#include <time.h>
#include <string>
#include <stdint.h>

#define MAX_NAME_LENGTH     (24u)
#define MAX_ENTRIES         (31u)
#define MAX_ENTRIES_TO_SHOW (10u)

#define HS_TABLE_LENGTH (42-4+MAX_NAME_LENGTH)
//#define HIGHSORCE_FILE_NAME "mine_hsc.bin"

/*typedef struct{
   time_t   date;                   // 4 played at
   uint16_t duration;               // 2 time (s) to finish
   uint16_t level;                  // 2 0:beginner; 1:intermediate mode
   char     name[MAX_NAME_LENGTH];  // 32-8
} __attribute__ ((packed)) highscore_entry_t; // total length 32bytes
*/
// Highscore entry representation
class highscore_entry_t
{
    public:
        time_t   date;                   // 4 played at
        uint16_t duration;               // 2 time (s) to finish
        uint16_t level;                  // 2 0:beginner; 1:intermediate mode
        char     name[MAX_NAME_LENGTH];  // 32-8
} __attribute__ ((packed));

/*typedef struct{
   uint16_t nr_entries;
   highscore_entry_t hs[MAX_ENTRIES];
}highscore_t;
*/
// Memory storage representation
class highscore_t
{
    public:
        uint16_t nr_entries;
        highscore_entry_t hs[MAX_ENTRIES];
};

class highscore
{
    private:
        std::string FileName;
        char* p_buffer;
        bool loaded;
        void write_with_bg(const char * const p_text, const uint8_t fg, const uint8_t bg, uint8_t length);
        void filter_string(char* p_string);
        void sort(const uint16_t filter, std::vector<highscore_entry_t *>& idx_array);
    public:
        // class constructor
        highscore(const std::string FileName);
        ~highscore();
        bool Load(void);
        bool Save(void);
        bool Append(const std::string name, const time_t time, const uint16_t duration, const uint16_t level);
        uint8_t InsertSorted(const std::string name, const time_t time, const uint16_t duration, const uint16_t level);
        void Display(const uint16_t filter, const uint8_t hlEntry);
        void Display(const uint16_t filter);
        bool GetLoaded(void);

};

#endif
