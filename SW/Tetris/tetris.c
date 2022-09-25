
// Standard Input/Output functions
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
//#include <delay.h>
#include <string.h>
#include <stdbool.h>
#include <ndrcomp/target.h>
#include <ndrcomp/sysclock.h>
#include "../../nkc_common/nkc/llnkc.h"
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

#define SPEED_DELAY 1010u
#define SPEED_CALC(level) ((clock_t)(min((uint16_t)level,5u)*200u))

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
#define BGCOLOR (WHITE|DARK)

#define ARRAY_SIZE(a) (sizeof(a)/sizeof(a[0u]))

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



int main(void)
{
	//bool b=false;
   //unsigned char tmp;
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

   
   uint16_t deleted_lines = 0u;
   uint8_t level = 0u;
   clock_t speed = SPEED_DELAY-SPEED_CALC(1u);
   uint16_t points = 0u;
   uint8_t stone_index=0u;
   uint8_t stone_data[8]={0u};
   Stone_t my_stone={.cols=0u,.rows=0u, .p_pattern = stone_data};
   uint8_t orientation = 0u;
   uint8_t color = colors[rand() % ARRAY_SIZE(colors)];
   uint8_t current_row=BOARD_HEIGHT-1u;
   uint8_t current_col=(BOARD_WIDTH/2u)-1u;

#if 0
   // draw all Stones with all possible orientations
   for(uint16_t j=0u;j<4u;j++) {
      uint8_t color_index = 0u;
      for(uint16_t i=0u;i<ARRAY_SIZE(stones);i++) {
         //draw_stone(stones[i],j, j*4,i*4u, colors[color_index++]);
      

         get_stone(stones[i], j, &my_stone);
         //iprintf("Stone: %d, orientation %d\r\n",i,j );
         //print_stone(&my_stone);
         draw_stone(&my_stone, j*4,i*4u, colors[color_index++]);

         if(color_index>=ARRAY_SIZE(colors)) {
            color_index=0u;
         }
      }
      
   }
#endif  

   draw_board();

   memset(board, 0u, sizeof(board));

   orientation = 0u;
   
   bool stop = false;
   bool refresh = false;
   bool new_stone = true;
   bool game_over = false;
   Command_t command = none_e;
   clock_t end_time  = 0u;
   do {
      if (refresh || (_clock(NULL) >= end_time) ) {
         // 1. delete current stone
         if(!new_stone) {
            draw_stone(&my_stone, current_row, current_col, BGCOLOR);
         }
         if (!refresh) {

            end_time  = _clock(NULL) + (speed*CLOCKS_PER_SEC)/1000u;
            
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
/*                  if ((current_row + my_stone.rows) >=(BOARD_HEIGHT-2u)) {
                     game_over=true;
                     break;
                  }*/
                  new_stone=true;
                  copy_stone(current_row, current_col, &my_stone, color);
                  
#if 0
                  char bfr[16];
                  SetCurrentColor(WHITE); 
                  siprintf(bfr,"ss r:%02u c:%02u",current_row,current_col);
                  WriteScreenxy(0,10,bfr);
#endif
               }
            }
/*            {
               // debug
               char bfr[16];
               SetCurrentColor(WHITE); 
               siprintf(bfr,"cr:%02u cc:%02u",current_row,current_col);
               WriteScreenxy(0,20,bfr);
            }*/
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
               case rotate_e:
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
            speed = SPEED_DELAY-SPEED_CALC(level);
            siprintf(bfr,"Speed: %u  ",(unsigned int)SPEED_CALC(level+1u));  
            gp_writexy(CCNV_X(BOARD_X+BOARD_WIDTH+2u),CCNV_Y(BOARD_Y+4u),0x11, bfr);
            siprintf(bfr,"Points: %u  ",points); 
            gp_writexy(CCNV_X(2u),CCNV_Y(BOARD_Y+BOARD_HEIGHT+2u),0x22, bfr);
         }

         refresh=false;
      }
      if (gp_csts()) {
         key = gp_ci();
         if(key=='x') {
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
               orientation--;
               orientation&=0x03;
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
/*   do
   {

      key = gp_ci();

   } while (key != 'x');*/

   //SetCurrentColor(0u);
   GDP_Col.fg=1;
   GDP_Col.bg=0;
   gp_clearscreen();
   iprintf("GDP.ctrl2: 0x%X\r\n", GDP.ctrl2 );
/*   for (uint8_t i=BOARD_HEIGHT-1u;i!=0xffu;i--) {
      iprintf("%02u:",i);
      for (uint8_t j=0u;j<BOARD_WIDTH; j++) {
         iprintf("%02x ",board[i][j]);
      }
      printf("\r\n");
   }
*/
}


