
// Standard Input/Output functions
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
//#include <delay.h>
#include <string.h>
#include <stdbool.h>
#include <ndrcomp/target.h>
#include <ndrcomp/sysclock.h>
//#include "../../nkc_common/nkc/llnkc.h"
#include "../../nkc_common/nkc/nkc.h"
#include <time.h>
//#include "sound.h"


// Declare your global variables here


extern volatile char csts(void);
extern time_t _gettime(void);

//extern clock_t _clock(void (*clock_fu)(void));
#define TIME (_clock(NULL))
#define HZ CLOCKS_PER_SEC 
#define UP    0x05u
#define DOWN  0x18u
#define LEFT  0x13u
#define RIGHT 0x04u

#define SPEED_DELAY 1000u
#define MAX_SPEED_DELAY (SPEED_DELAY-100u)
#define SPEED_CALC(level) ((clock_t)(min((uint16_t)level,5u)*200u))
//#define SPEED_INC_VAL 307uLL  //((uint32_t)(1.2f*256.0f))

/* Board screen locations */
#define X_RES 512u
#define Y_RES 256u
#define X_SCALE 3u
#define Y_SCALE 2u
#define BOARD_X	15u
#define BOARD_Y	1u
#define BOARD_WIDTH	15u
#define BOARD_HEIGHT	20u

#define CCNV_X(X) (((uint16_t)X)*4u*X_SCALE)
#define CCNV_Y(Y) (((uint16_t)Y)*4u*Y_SCALE)
//#define SetCurrentColor gp_setcolor
#define SetCurrentColor SetCurrentFgColor
#define BGCOLOR             (WHITE|DARK)
#define MAX_NAME_LENGTH     (24u)
#define MAX_ENTRIES         (31u)
#define MAX_ENTRIES_TO_SHOW (10u)

#define ARRAY_SIZE(a) (sizeof(a)/sizeof(a[0u]))

#define HS_TABLE_LENGTH (42-4+MAX_NAME_LENGTH)

// global variables
// board[cols][rows]
static uint8_t board[BOARD_HEIGHT][BOARD_WIDTH];

typedef enum {
   none_e      =0u,
   move_left_e,
   move_right_e,
   rotate_e,
   drop_e
}Command_t;

typedef struct{
   uint8_t rows;
   uint8_t cols;
   const uint8_t * const p_pattern;
} Stone_t;

typedef struct{
   time_t   date;
   uint16_t points;
   uint16_t level;
   char     name[MAX_NAME_LENGTH]; // 32-8
} __attribute__ ((packed)) highscore_entry_t; // total length 32bytes

typedef struct{
   uint16_t nr_entries;
   highscore_entry_t hs[MAX_ENTRIES];
}highscore_t;


static const uint8_t s_stone_pattern[]={0u,1u,1u, 1u,1u,0u};
static const Stone_t s_stone = {
   .rows = 2u,
   .cols = 3u,
   .p_pattern = s_stone_pattern
};

static const uint8_t z_stone_pattern[]={1u,1u,0u, 0u,1u,1u};
static const Stone_t z_stone = {
   .rows = 2u,
   .cols = 3u,
   .p_pattern = z_stone_pattern
};

static const uint8_t t_stone_pattern[]={0u,1u,0u, 1u,1u,1u};
static const Stone_t t_stone = {
   .rows = 2u,
   .cols = 3u,
   .p_pattern = t_stone_pattern
};

static const uint8_t l_stone_pattern[]={0u,0u,1u, 1u,1u,1u};
static const Stone_t l_stone = {
   .rows = 2u,
   .cols = 3u,
   .p_pattern = l_stone_pattern
};

static const uint8_t fl_stone_pattern[]={1u,0u,0u, 1u,1u,1u};
static const Stone_t fl_stone = {
   .rows = 2u,
   .cols = 3u,
   .p_pattern = fl_stone_pattern
};

static const uint8_t o_stone_pattern[]={1u,1u, 1u,1u};
static const Stone_t o_stone = {
   .rows = 2u,
   .cols = 2u,
   .p_pattern = o_stone_pattern
};

static const uint8_t i_stone_pattern[]={1u,1u, 1u,1u};
static const Stone_t i_stone = {
   .rows = 1u,
   .cols = 4u,
   .p_pattern = i_stone_pattern
};

static const Stone_t* stones[] = {
   &s_stone,
   &z_stone,
   &t_stone,
   &l_stone,
   &fl_stone,
   &o_stone,
   &i_stone
};

static const uint8_t colors[]={YELLOW, GREEN, RED, BLUE, MAGENTA, CYAN, GRAY};


static inline __attribute__((always_inline)) void gdp_ready(void) {
   while(!(GDP.cmd & 0x04u)) {};
}

static inline __attribute__((always_inline)) void SetCurrentFgColor(uint8_t fg) {
   gdp_ready();
   //fg_color = fg;
    GDP_Col.fg=fg;
}

static inline __attribute__((always_inline)) void SetCurrentBgColor(uint8_t bg) {
   gdp_ready();
   //bg_color = bg;
   GDP_Col.bg=bg;
}

static inline __attribute__((always_inline)) void Gotoxy(uint8_t x, uint8_t y)
{
   gp_moveto(CCNV_X(x),CCNV_Y(y));
}

static inline __attribute__((always_inline)) void WriteScreenxy(const uint8_t x, const uint8_t y,const char* const p_str)
{
   gp_writexy(CCNV_X(x),CCNV_X(y),0x11, p_str);
}

static inline __attribute__((always_inline)) void GDP_setpixel(const uint16_t x, const uint16_t y)
{
   gdp_ready();
   GDP.xl = x & 0xffu;
   GDP.xh = x >> 8u;
   GDP.yl = y & 0xffu;
   GDP.yh = y >> 8u;
   GDP.cmd = 0b10100000u;  // 2 Pixel in x direction
}

static inline __attribute__((always_inline)) void GDP_draw4x4(const uint16_t x, const uint16_t y)
{
   gdp_ready();
   GDP.xl = x & 0xffu;
   GDP.xh = x >> 8u;
   GDP.yl = y & 0xffu;
   GDP.yh = y >> 8u;
   GDP.cmd = 0x0Bu;  // 4x4
}

static inline __attribute__((always_inline)) void GDP_setpixel1(const uint16_t x, const uint16_t y)
{
   gdp_ready();
   GDP.xl = x & 0xffu;
   GDP.xh = x >> 8u;
   GDP.yl = y & 0xffu;
   GDP.yh = y >> 8u;
   GDP.cmd = 0b10000000u;  // 1 Pixel in x direction
}

void delay_ms(const uint16_t ms) {
   clock_t ticks = ((clock_t)ms*200u)/1000u;
   clock_t start = _clock(NULL);
   while((_clock(NULL)-start)<ticks) {};
}

//#define SPEED_CALC(level) ((clock_t)(min((uint16_t)level,5u)*200u))
// increases speed by 20%
uint16_t speed_increase(const uint16_t current_speed)
{
   /*uint32_t temp = (uint32_t)current_speed<<8u;
   temp*=SPEED_INC_VAL;
   return (uint16_t)(temp>>16u);*/
   return (current_speed + ((SPEED_DELAY - current_speed )/4u));
}

void draw_square(const uint8_t row, const uint8_t col, const uint8_t color) {
   const uint16_t x_pos = CCNV_X(BOARD_X) + (col * 4u * X_SCALE);
   const uint16_t y_pos = CCNV_Y(BOARD_Y) + (row * 4u * Y_SCALE);
   SetCurrentColor(color);
   const uint8_t csize_backup = GDP.csize;
   GDP.csize = ((X_SCALE)<<4u) |(Y_SCALE);   //0x32u;
   GDP_draw4x4(x_pos,y_pos);
   
   if (color != BGCOLOR) {
      // schwarze umrahmung zeichnen
      SetCurrentColor(BLACK);

      gp_moveto(x_pos,y_pos);
      gp_drawto(x_pos + (4u * X_SCALE) - 1u, y_pos);
      gp_drawto(x_pos + (4u * X_SCALE) - 1u, y_pos + (4u * Y_SCALE) - 1u);
      gp_drawto(x_pos,y_pos + (4u * Y_SCALE) - 1u);
      gp_drawto(x_pos,y_pos);
      SetCurrentColor(color);
   }

   gdp_ready();
   GDP.csize = csize_backup;
}

void draw_stone(const Stone_t* const p_stone, const uint8_t row, const uint8_t col, const uint8_t color) {
   const uint8_t* p_data = p_stone->p_pattern;

   const uint8_t rows = p_stone->rows;
   const uint8_t cols = p_stone->cols;
   for (uint16_t i=0u;i<rows; i++) {
      for (uint16_t j=0u;j<cols; j++) {
         if ((*p_data!=0u)) { // || (color == BGCOLOR)) {
            draw_square(row+(rows-i-1),col+j,color);
         }
         p_data++;
      }
   }
#if 0   
   if (color != BGCOLOR) {
      SetCurrentColor(WHITE); 
   }
   gp_moveto(CCNV_X(BOARD_X+col),CCNV_Y(BOARD_Y+row));               // Ursprung ist links unten
   gp_drawto(CCNV_X(BOARD_X+col),CCNV_Y(BOARD_Y+row+rows));          // up
   gp_drawto(CCNV_X(BOARD_X+col+cols),CCNV_Y(BOARD_Y+row+rows));     // right
   gp_drawto(CCNV_X(BOARD_X+col+cols),CCNV_Y(BOARD_Y+row));          //
   gp_drawto(CCNV_X(BOARD_X+col),CCNV_Y(BOARD_Y+row));
#endif   
}


static inline __attribute__((always_inline)) uint8_t get_offset(const uint8_t row, const uint8_t col, const uint8_t rows, const uint8_t cols)
{
   return (row * cols) + col;
}


static inline __attribute__((always_inline)) uint16_t min(uint16_t a, uint16_t b) {
   return (a<b)?a:b;
}


void get_stone(const Stone_t* const p_stone, const uint8_t orientation, Stone_t* const p_out) {
   const uint8_t* p_data     = p_stone->p_pattern;
   uint8_t* p_data_out       = (uint8_t*)p_out->p_pattern;
   uint8_t rows;
   uint8_t cols;
   switch (orientation & 0x03u) {
      default:
         {
            rows = p_stone->rows;
            cols = p_stone->cols;
            for (uint16_t i=0u;i<rows; i++) {
               for (uint16_t j=0u;j<cols; j++) {
                  //draw_square(row+(rows-i),col+j,color);
                  p_data_out[get_offset(i, j, rows, cols)] = *p_data;
                  p_data++;
               }
            }
         }
         break;
      case 1u: // 90° im Uhrzeigersinn rotiert
         {
            rows = p_stone->cols;
            cols = p_stone->rows;
            for (uint16_t i=0u;i<cols; i++) {
               for (uint16_t j=0u;j<rows; j++) {
                  
                  //draw_square(row+(rows - j - 1u), col+(cols - i - 1u),color);
                  p_data_out[get_offset(j , (cols - i - 1u), rows, cols)] = *p_data;
                  p_data++;
               }
            }
         }
         break;

      case 2u:  // 180° im Uhrzeigersinn rotiert
         {
            rows = p_stone->rows;
            cols = p_stone->cols;
            for (uint16_t i=0u;i<rows; i++) {
               for (uint16_t j=0u;j<cols; j++) {

                  //draw_square(row + i,col+(cols - j - 1u),color);
                  p_data_out[get_offset(rows - i - 1, (cols - j - 1u), rows, cols)] = *p_data;
                  p_data++;
               }
            }
         }
         break;

      case 3u: // 270° im Uhrzeigersinn rotiert
         {
            rows = p_stone->cols;
            cols = p_stone->rows;
            for (uint16_t i=0u;i<cols; i++) {
               for (uint16_t j=0u;j<rows; j++) {

                  //draw_square(row + j , col + i ,color);
                  p_data_out[get_offset(rows - j - 1  , i, rows, cols)] = *p_data;
                  p_data++;
               }
            }
         }
         break;
   }
   p_out->rows = rows;
   p_out->cols = cols;
}
/*
void print_stone(const Stone_t* const p_stone)
{
   const uint8_t* p_data     = p_stone->p_pattern;
   const uint8_t rows = p_stone->rows;
   const uint8_t cols = p_stone->cols;

   for (uint16_t i=0u;i<rows; i++) {
      for (uint16_t j=0u;j<cols; j++) {
         iprintf("%d ",*p_data);
         p_data++;
      }
      iprintf("   ");
   }
   iprintf("\r\n");
}*/

void draw_board(void) {
   SetCurrentColor(BLUE | DARK);
   gp_moveto(CCNV_X(BOARD_X)-1u,CCNV_Y(BOARD_Y+BOARD_HEIGHT));
   gp_drawto(CCNV_X(BOARD_X)-1u,CCNV_Y(BOARD_Y)-1u);
   gp_drawto(CCNV_X(BOARD_X+BOARD_WIDTH),CCNV_Y(BOARD_Y)-1u);
   gp_drawto(CCNV_X(BOARD_X+BOARD_WIDTH),CCNV_Y(BOARD_Y+BOARD_HEIGHT));
   const uint8_t csize_backup = GDP.csize;
   gdp_ready();
   GDP.csize = ((X_SCALE)<<4u) |(Y_SCALE);   //0x32u;
   for(uint16_t i=CCNV_Y(BOARD_Y);i<CCNV_Y(BOARD_Y+BOARD_HEIGHT);i+=CCNV_Y(1u)) {
      GDP_draw4x4(CCNV_X(BOARD_X)-(4u*X_SCALE),i);
      GDP_draw4x4(CCNV_X(BOARD_X+BOARD_WIDTH),i);

   }
   for(uint16_t i=CCNV_X(BOARD_X)-(4u*X_SCALE);i<CCNV_X(BOARD_X+BOARD_WIDTH+1u);i+=CCNV_X(1u)) {
      GDP_draw4x4(i, CCNV_Y(BOARD_Y)-(4u*Y_SCALE));
   }
   gdp_ready();
   GDP.csize = csize_backup;
   #if 0
   for(uint8_t i=0;i<BOARD_WIDTH;i++){
      draw_square(0u,i,WHITE);
   }
   #endif
}

uint8_t check_board_lines(void) 
{
   // search for first filled line and return it. If no filled line is found 0xff is returned
   for (uint8_t i=0u;i<BOARD_HEIGHT;i++) {
      uint8_t line_result = 0u;
      for (uint8_t j=0u;j<BOARD_WIDTH; j++) {
         const uint8_t pixel = board[i][j] & 0x0fu;
         line_result += (pixel!=0u)?1u:0u;
      }
      if (line_result == BOARD_WIDTH) {
/*         
         // filled line found!
         char bfr[16];
         SetCurrentColor(WHITE); 
         siprintf(bfr,"Complete %02u",i);
         WriteScreenxy(0,10,bfr); */
         return i;
      }
   }
   return 0xffu;
}

void redraw_board(void) {
   for (uint8_t i=0u;i<BOARD_HEIGHT;i++) {
      for (uint8_t j=0u;j<BOARD_WIDTH; j++) {
         const uint8_t color = board[i][j] & 0x0fu;
         draw_square(i,j,(color!=0u)?color:BGCOLOR);
      }
   }
}

void delete_board_line(const uint8_t line)
{
   // 1. highlight filled line
   for (uint8_t j=0u;j<BOARD_WIDTH; j++) {
      draw_square(line,j,WHITE);
   }
   delay_ms(200u);
   for (uint8_t i=(line+1u);i<BOARD_HEIGHT;i++) {
      for (uint8_t j=0u;j<BOARD_WIDTH; j++) {
         board[i-1u][j] = board[i][j];
      }
   }
   // clear top line
   for (uint8_t j=0u;j<BOARD_WIDTH; j++) {
      board[BOARD_HEIGHT-1u][j] = 0xf0u;
   }
   redraw_board();
}

bool check_finish(void)
{
   for (uint8_t j=0u;j<BOARD_WIDTH; j++) {
      if (board[BOARD_HEIGHT-2u][j] & 0x0fu) {
         return true;
      }
   }
   return false;
}

bool check_collision(const uint8_t row, const uint8_t col, const Stone_t* const p_stone)
{
   const uint8_t* p_data  = p_stone->p_pattern;
   const uint8_t rows     = p_stone->rows;
   const uint8_t cols     = p_stone->cols;

//   static uint16_t er_count=0u;
   // 1. letzte Zeile im Stein suchen

   //const uint8_t last_row_index = (rows-1u) * cols;
   if(row==0xffu) {
#if 0      
      SetCurrentColor(WHITE); 
      char bfr[16];
      siprintf(bfr,"!row %u",er_count);
      WriteScreenxy(0,5,bfr);
      er_count++;
#endif      
      return true;
   }
   for (uint8_t i=0u;i<rows; i++) {
      const uint8_t current_row = row+(rows-i-1u);
      for (uint8_t j=0u;j<cols; j++) {
         const uint8_t current_col = col+j;
         if ((current_row < BOARD_HEIGHT) && (current_col < BOARD_WIDTH)) {
            const uint8_t pixel = board[current_row][current_col] & 0x0fu;
            if ((*p_data!=0u) && (pixel!=0u)) {
   #if 0            
               char bfr[16];
               siprintf(bfr,"r:%02u c:%02u",row+(rows-i-1),col+j);
               SetCurrentColor(WHITE); 
               WriteScreenxy(0,0,bfr);
   #endif            
               return true;
            }
         }
         p_data++;
      }
   }
#if 0   
   SetCurrentColor(WHITE); 
   WriteScreenxy(0,5,"    ");
#endif   
   return false;
}


void copy_stone(const uint8_t row, const uint8_t col, const Stone_t* const p_stone, const uint8_t color)
{
   const uint8_t* p_data  = p_stone->p_pattern;
   const uint8_t rows     = p_stone->rows;
   const uint8_t cols     = p_stone->cols;
#if 0
   {
      char bfr[16];
      SetCurrentColor(WHITE); 
      siprintf(bfr,"copy %02u %02u %02u",row,col,color);
      WriteScreenxy(0,3,bfr);
   }
#endif   
   for (uint8_t i=0u;i<rows; i++) {
      for (uint8_t j=0u;j<cols; j++) {
         if (*p_data!=0u) {
#if 0
            if (board[col+j][row+(rows-i-1)]!=0) {
               char bfr[16];
               SetCurrentColor(WHITE); 
               siprintf(bfr,"er %02u %02u",row+(rows-i-1),col+j);
               WriteScreenxy(0,2,bfr);
            }
#endif
            board[row+(rows-i-1)][col+j]=color;
         }
         p_data++;
      }
   }
   /*const uint8_t filled_line = check_board_lines();
   if (filled_line!=0xff) {
      delete_board_line(filled_line);
   }*/
}

#define HIGHSORCE_FILE_NAME "tet_hsc.bin"
bool load_highscore(highscore_t * const p_highscore, const size_t hs_buf_len) {
   jdfcb_t myfcb={0};
	uint8_t result = jd_fillfcb(&myfcb,HIGHSORCE_FILE_NAME);
   if (result==0) {
      jdfile_info_t info __attribute__ ((aligned (4))) = {0u};
      
      result = jd_fileinfo(&myfcb, &info);
      //iprintf("Fileinfo-Result: 0x%X length: %u %u date:0x%lX, att:0x%X\r\n",result, (unsigned int)info.length, hs_buf_len, info.date, info.attribute);
      if ((result==0) && (hs_buf_len>=info.length)) {
         result = jd_fileload(&myfcb, (char*const)p_highscore);
         //iprintf("Fileload-Result: %u filename:%s\r\n",result, myfcb.filename);
      }
   }
   return (result==0)?true:false;
}

bool save_highscore(highscore_t * const p_highscore, const size_t hs_buf_len) {
   jdfcb_t myfcb={0};
	uint8_t result = jd_fillfcb(&myfcb,HIGHSORCE_FILE_NAME);
   if (result==0) {
      result = jd_filesave(&myfcb, (const char*const)p_highscore, hs_buf_len);
      //iprintf("Filesave-Result: 0x%X\r\n",result);
   }
   return (result==0)?true:false;
}

uint8_t hs_insert_sorted(highscore_t * const p_hs, const highscore_entry_t * const p_entry)
{
   uint16_t found_idx = 0u;
   bool found = false;
   if (p_hs->nr_entries>0u) {
      for (uint16_t i=0u;i<p_hs->nr_entries;i++) {
         if(p_hs->hs[i].points <= p_entry->points) {
            found_idx = i;
            found     = true;
            iprintf("Found: %u\r\n",i);
            break;
         }
      }
      const uint16_t nr_items = min(p_hs->nr_entries, MAX_ENTRIES-1u);
      if (found) {
         for (uint16_t j=nr_items;j>found_idx;j--) {
            memcpy(&p_hs->hs[j], &p_hs->hs[j-1], sizeof(highscore_entry_t));
         }
      }else if (p_hs->nr_entries < MAX_ENTRIES) {
         // Append one item
         found_idx = p_hs->nr_entries;
      }
   }
   memcpy(&p_hs->hs[found_idx],p_entry,sizeof(highscore_entry_t));
   if(p_hs->nr_entries < MAX_ENTRIES) {
      p_hs->nr_entries++;
   }

   return found_idx;
}

void write_with_bg(const char * const p_text, const uint8_t fg, const uint8_t bg, uint8_t length)
{
   gp_setcolor(fg,bg);
   const size_t len = strlen(p_text);
   puts(p_text);
      
   uint16_t x_pos=0u;
   uint16_t y_pos=0u;
   gp_getxy(&x_pos,&y_pos);
   //gp_erapen();
   gp_setxor(true);

   uint16_t dx; //= (41-4+24)*6u;
   if(!length) {
      dx = (len*6u); // use text-length
   }else{
      dx = length*6u;
   }
   uint8_t loops=1u;
   if(dx>=256u) {
      dx/=2u;
      loops++;
   }

   for(uint8_t page=0u;page<2u; page++) {
      gp_newpage(page,0u);

      uint16_t x = x_pos-(len*6u);
      for(uint8_t j=0u;j<loops;j++) {
         gp_draw_filled_rect(x,y_pos*2u,dx,18u);   // need to keep dx < 256 to prevent xor artifacts
         x+=dx;
      }
      //gp_draw_filled_rect(x+dx,y_pos*2u,dx,16u);   // //(len*6u),16u);
   }
   //gp_setpen();
   gp_setxor(false);
}

void display_hs(highscore_t * const p_hs, const uint8_t new_entry) {
   //puts("Highscore:\r\n**********\r\n");
   write_with_bg(" Highscore:",BLUE, BLACK, 0u);
   puts("\r\n");
   //gp_setcolor(RED,WHITE);
 

   //iprintf("X:%u Y:%u\r\n",x_pos,y_pos);
   //puts("Nr: LV   Points    Played at         Name");
   write_with_bg(" Nr: LV   Points    Played at         Name",WHITE,BLACK,HS_TABLE_LENGTH);   // 41 characters, name max 24 chars
   gp_setcolor(BLACK,BLACK);
   char timebuf[20];
   char linebuf[80];
   // Display max first 10 HS items and highlight currently added one with green
   for (uint16_t i=0;i<min(p_hs->nr_entries,MAX_ENTRIES_TO_SHOW);i++) {
      const struct tm * const p_tm = localtime(&p_hs->hs[i].date);
      //strftime(timebuf, sizeof(timebuf), "%d.%m.%y %H:%M:%S", localtime(&p_hs->hs[i].date));
      siprintf(timebuf,"%02u.%02u.%02u %02u:%02u:%02u",p_tm->tm_mday,p_tm->tm_mon,p_tm->tm_year-100u,p_tm->tm_hour,p_tm->tm_min,p_tm->tm_sec);
      siprintf(linebuf," %-2u: %02u %8u %20s %s",i+1u, p_hs->hs[i].level, (unsigned int)p_hs->hs[i].points, timebuf, p_hs->hs[i].name);
      uint8_t fg = (i&1u)?GRAY:WHITE|DARK;
      if (i==new_entry) {
         fg = GREEN;
      }
      write_with_bg(linebuf,fg,BLACK,HS_TABLE_LENGTH);
      /*if (i&1) {
         write_with_bg(linebuf,GRAY,BLACK,HS_TABLE_LENGTH);
      }else{
         gp_setcolor(BLACK,BLACK);
         puts(linebuf);
      }*/
   }
   gp_setcolor(BLACK,BLACK);
}

int main(void)
{
   const uint32_t sysinfo = gp_system();
   if (!((sysinfo & (IS_08 | IS_00 | IS_20 | GDP_FPGA)) == ((IS_08 << PADDING) | GDP_FPGA))) {
      #if(cpu==1)
         puts("Nicht unterstuetzte Systemkonfiguration.\r\nSie benoetigen eine GDP-FPGA sowie eine 68008 CPU!\r\n");
      #else
         puts("Nicht unterstuetzte Systemkonfiguration.\r\nSie benoetigen eine GDP-FPGA sowie eine 68000 CPU!\r\n");
      #endif
      return 0;
   }
   //SetCurrentBgColor(GRAY | DARK);
   SetCurrentBgColor(BGCOLOR);
   gp_clearscreen();
   gp_cursor_off();
   gp_setflip(10u,10u);
   GDP_Ctrl.page_dma = 0u;
   //GDP_Col.bg = GRAY | DARK;
   //GDP.ctrl2 |= (1u<<5u); // turn on BG mode
   
   //initSound();

	char key;

   srand((unsigned) _gettime());

   SetCurrentBgColor(BGCOLOR);
   SetCurrentColor(RED);
   gp_writexy(CCNV_X(20u),CCNV_Y(30u),0x22u, "Tetris!");
   SetCurrentColor(CYAN|DARK);
   gp_writexy(CCNV_X(2u),CCNV_Y(0u),0x11u, "(C) by AV'22");
   SetCurrentColor(WHITE);
   gp_writexy(CCNV_X(BOARD_X+BOARD_WIDTH+2u),CCNV_Y(BOARD_Y),   0x11u, "Lines: 0 ");
   gp_writexy(CCNV_X(BOARD_X+BOARD_WIDTH+2u),CCNV_Y(BOARD_Y+2u),0x11u, "Level: 1 ");
   gp_writexy(CCNV_X(BOARD_X+BOARD_WIDTH+2u),CCNV_Y(BOARD_Y+4u),0x11, "Speed: 0");
   gp_writexy(CCNV_X(2u),CCNV_Y(BOARD_Y+BOARD_HEIGHT+2u),0x22, "Points: 0  ");
   gp_writexy(CCNV_X(2u),CCNV_Y(2u),0x11, "x = Exit");
   gp_writexy(CCNV_X(2u),CCNV_Y(3u),0x11, "p = Pause");
   gp_writexy(CCNV_X(2u),CCNV_Y(5u),0x11, "down  = Drop");
   gp_writexy(CCNV_X(2u),CCNV_Y(6u),0x11, "left  = Move Left");
   gp_writexy(CCNV_X(2u),CCNV_Y(7u),0x11, "right = Move Right");
   gp_writexy(CCNV_X(2u),CCNV_Y(8u),0x11, "up    = Rotate");
   
   
   uint16_t deleted_lines = 0u;
   uint8_t level = 0u;
   uint8_t old_level = level;
   clock_t speed = 400u;
   uint16_t points = 0u;
   uint8_t stone_index=0u;
   uint8_t stone_data[8]={0u};
   Stone_t my_stone={.cols=0u,.rows=0u, .p_pattern = stone_data};
   uint8_t orientation = 0u;
   uint8_t color = colors[rand() % ARRAY_SIZE(colors)];
   uint8_t current_row=BOARD_HEIGHT-1u;
   uint8_t current_col=(BOARD_WIDTH/2u)-1u;

   draw_board();

   memset(board, 0u, sizeof(board));

   orientation = 0u;
   
   bool stop = false;
   bool refresh = false;
   bool new_stone = true;
   bool game_over = false;
   bool abort     = false;
   Command_t command = none_e;
   clock_t end_time  = 0u;
   do {
      if (refresh || (_clock(NULL) >= end_time) ) {
         // 1. delete current stone
         if(!new_stone) {
            draw_stone(&my_stone, current_row, current_col, BGCOLOR);
         }
         if (!refresh) {

            end_time  = _clock(NULL) + ((SPEED_DELAY - speed)*CLOCKS_PER_SEC)/1000u;
            
            if (new_stone) {
               if (check_finish()) {
                  game_over=true;
                  break;
               }
               // Get a random Stone with random color
               color = colors[rand() % ARRAY_SIZE(colors)];
               stone_index = rand() % ARRAY_SIZE(stones);
               orientation=0u;
               current_row=BOARD_HEIGHT-1u;
               current_col=(BOARD_WIDTH/2u)-1u;
               new_stone=false;
            }else{
               // drop current stone
               if(!check_collision(current_row-1u,current_col,&my_stone)) {
                  current_row--;
               }else{
                  new_stone=true;
                  copy_stone(current_row, current_col, &my_stone, color);
               }
            }

         }else{
            switch(command) {
               case move_left_e:
                  if ((current_col>0u) && !check_collision(current_row,current_col-1u,&my_stone)){

                     current_col--;
                  }
                  break;
               case move_right_e:
                  if (((current_col + my_stone.cols) < BOARD_WIDTH) && !check_collision(current_row,current_col+1u,&my_stone)) {
                     current_col++;
                  }
                  break;
               case drop_e:
                  while(!check_collision(current_row-1u,current_col,&my_stone)) {
                     current_row--;
                     points++;
                  }
                  new_stone=true;
                  copy_stone(current_row, current_col, &my_stone, color);
                  break;
               case rotate_e:
                  {
                     // get a temporary stone with new orientation to check if it collides
                     const uint8_t temp_or = (orientation - 1u) & 0x03u;
                     Stone_t temp_stone={.cols=0u,.rows=0u, .p_pattern = stone_data};
                     get_stone(stones[stone_index], temp_or, &temp_stone);
                     if (((current_col + temp_stone.cols) < BOARD_WIDTH) && !check_collision(current_row,current_col,&temp_stone)) {
                        orientation = temp_or;
                     }
                  }
                  break;
               default:
                  break;
            }
            command = none_e;
         }
         // draw stone with current orientation
         get_stone(stones[stone_index], orientation, &my_stone);
         if ((current_col + my_stone.cols)>= BOARD_WIDTH) {
            current_col -= ((current_col + my_stone.cols) - BOARD_WIDTH);
         }   
         draw_stone(&my_stone, current_row, current_col, color);
         if(new_stone) {
            uint8_t filled_line = check_board_lines();
            char bfr[16];
            uint8_t currently_deleted_lines =0u;
            while (filled_line!=0xffu) {
               delete_board_line(filled_line);
               deleted_lines++;
               currently_deleted_lines++;
               SetCurrentColor(WHITE);                
               siprintf(bfr,"Lines: %u  ",deleted_lines);
               gp_writexy(CCNV_X(BOARD_X+BOARD_WIDTH+2u),CCNV_Y(BOARD_Y),0x11, bfr);
               // check if there are more lines to delete
               level = deleted_lines/10u;
               siprintf(bfr,"Level: %u  ",level+1u);
               gp_writexy(CCNV_X(BOARD_X+BOARD_WIDTH+2u),CCNV_Y(BOARD_Y+2u),0x11, bfr);
               filled_line = check_board_lines();
            }
            if (currently_deleted_lines>0u) {
               points += (level+1u)*10u + (currently_deleted_lines-1u)*20u;
            }
            SetCurrentColor(WHITE);
            if (level!=old_level) {
               // Level increased. So speed up the game
               const uint16_t speed_temp = speed_increase(speed); //SPEED_CALC(level);
               if (speed_temp<MAX_SPEED_DELAY) {
                  speed = speed_temp;
               }
               //speed = SPEED_DELAY - speed_temp;
               old_level = level;
            }
            siprintf(bfr,"Speed: %u  ",(unsigned int)speed); //(unsigned int)SPEED_CALC(level+1u));  
            gp_writexy(CCNV_X(BOARD_X+BOARD_WIDTH+2u),CCNV_Y(BOARD_Y+4u),0x11, bfr);
            siprintf(bfr,"Points: %u  ",points); 
            gp_writexy(CCNV_X(2u),CCNV_Y(BOARD_Y+BOARD_HEIGHT+2u),0x22, bfr);
         }

         refresh=false;
      }
      if (gp_csts()) {
         key = gp_ci();
         if(key=='x') {
            abort=true;
            break;
         }
         switch(key) {
            case 'x':
               stop=true;
               break;
            case UP:
            case 'r':
               // delete old stone
               // fixme: check if stone exceeds board
               /*orientation--;
               orientation&=0x03;*/
               refresh=true;
               command = rotate_e;
               break;
            case 'n':
               end_time=0u;
               break;
            case 'p':
               while(!gp_csts()) {};
               gp_ci();
               break;
            case LEFT:
            case 's':
               // left
               command = move_left_e;
               refresh = true;
               break;
            case RIGHT:
            case 'd':
               // right
               command = move_right_e;
               refresh = true;
               break;
            case DOWN:
            case ' ':
               command = drop_e;
               refresh = true;
               break;
            case 'u':
               redraw_board();
               break;
            case 'c':
               GDP.ctrl2 &= ~(1u<<5u); // turn off BG mode
               GDP_Ctrl.page_dma = 0u;
               break;
/*            case 'i':
               old_level++;
               break;*/
         }
         
      }
   }while (!stop);
   if (game_over) {
      
      GDP.ctrl2 |= (1u<<5u); // turn on BG mode
      do {
         SetCurrentColor(RED);
         gp_writexy(CCNV_X(14u),CCNV_Y(BOARD_Y+BOARD_HEIGHT/2u),0x33u, "Game over!");
         delay_ms(500u);
         SetCurrentColor(BGCOLOR);
         gp_writexy(CCNV_X(14u),CCNV_Y(BOARD_Y+BOARD_HEIGHT/2u),0x33u, "          ");
         delay_ms(500u);
      }while(!gp_csts());
      gp_ci();
      GDP.ctrl2 &= ~(1u<<5u); // turn off BG mode
   }

   GDP_Col.fg=1;
   GDP_Col.bg=0;
   gp_clearscreen();
   {
      char* hs_buf = malloc(1024); 
      highscore_t* p_hs = (highscore_t*)hs_buf;
      if (!load_highscore(p_hs,1024u)) {
         puts("Highscore not found. Creating new...\r\n");
         p_hs->nr_entries = 0u;
/*         hs.nr_entries = 1u;
         hs.hs[0].date = _gettime();
         strcpy(hs.hs[0].name,"Andreas Voggeneder");
         hs.hs[0].points = (uint32_t)points;         
         (void)save_highscore(&hs,sizeof(hs));*/
      }else{
         iprintf("Loaded higscore...\r\n%u Entries\r\n",(unsigned int)p_hs->nr_entries);
      }
      uint8_t new_entry = 0xFFu;
      {
         char bfr[80u]={0u};
         if(!abort) {
            puts("Please enter your name for highscore list\r\n");
            gets(bfr);
            puts("\r\n");
         }
         if(!abort && (strlen(bfr)>0)) {
/*            strncpy(p_hs->hs[p_hs->nr_entries].name,bfr,MAX_NAME_LENGTH-1u);
            p_hs->hs[p_hs->nr_entries].name[MAX_NAME_LENGTH-1u]='\0';
            p_hs->hs[p_hs->nr_entries].date    = _gettime();
            p_hs->hs[p_hs->nr_entries].points  = points;
            p_hs->hs[p_hs->nr_entries].level   = level+1u;
            p_hs->nr_entries++;*/
            highscore_entry_t hs_entry = {
               .date  = _gettime(),
               .level = level+1u,
               .points = points,
            };
            strncpy(hs_entry.name,bfr,MAX_NAME_LENGTH-1u);
            new_entry = hs_insert_sorted(p_hs,&hs_entry);


            (void)save_highscore(p_hs,sizeof(highscore_t));
         }
      }
      display_hs(p_hs, new_entry);
      free(hs_buf);
   }



   //iprintf("GDP.ctrl2: 0x%X\r\n", GDP.ctrl2 );
/*   for (uint8_t i=BOARD_HEIGHT-1u;i!=0xffu;i--) {
      iprintf("%02u:",i);
      for (uint8_t j=0u;j<BOARD_WIDTH; j++) {
         iprintf("%02x ",board[i][j]);
      }
      iprintf("\r\n");
   }
*/
}


