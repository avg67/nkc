
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
#include "sound.h"


// Declare your global variables here

void NewGame(void);
void DrawStone(unsigned char Column, unsigned char Row, signed char Type);
void DropStone(unsigned char Column);
void UndoMove(void);
void FlashWinningLine(void);
void AddStone(unsigned char Column);
void DelStone(void);
void AutoMove(void);
int NextSearchLevel(unsigned char Depth, int BestSoFar);
int GetScore(void);
extern volatile char csts(void);
extern time_t _gettime(void);

//extern clock_t _clock(void (*clock_fu)(void));
#define TIME (_clock(NULL))
#define HZ CLOCKS_PER_SEC 

/* Stone types */

#define EMPTY  	-1
#define PLAYER_1	0
#define PLAYER_2	1

/* Board screen locations */

#define X_RES 512u
#define Y_RES 256u
#define BOARD_X	5u
#define BOARD_Y	1u

#define CCNV_X(X) (((uint16_t)X)*8u)
#define CCNV_Y(Y) (((uint16_t)Y)*8u)
//#define SetCurrentColor gp_setcolor
#define SetCurrentColor SetCurrentFgColor
#define BGCOLOR (WHITE|DARK)

/* Player Modes */

#define TWO_PLAYER	0
#define ONE_PLAYER	1

/* Scores for number of stones in win lines */

#define SCORE_1	1
#define SCORE_2	6
#define SCORE_3	13

/*
	Global Variables
*/
unsigned char NextPlayer;
unsigned char ColumnHeight[7];
unsigned char WinLineStones[2][70];
unsigned char History[42];
unsigned char MoveNumber;
unsigned char WinningLine;
//int SearchDepth;
unsigned char PlayerMode;
                              
// Spielfeld hat 7x6
// Bit 7 == 1 -> edge of board
static const unsigned char WinMap[4][42]={{0x81, 0x02, 0x03, 0x04, 0x00, 0x00, 0x00,
							 0x85, 0x06, 0x07, 0x08, 0x00, 0x00, 0x00,
							 0x89, 0x0A, 0x0B, 0x0C, 0x00, 0x00, 0x00,
							 0x8D, 0x0E, 0x0F, 0x10, 0x00, 0x00, 0x00,
							 0x91, 0x12, 0x13, 0x14, 0x00, 0x00, 0x00,
							 0x95, 0x16, 0x17, 0x18, 0x00, 0x00, 0x00},
							 
							{0x99, 0x9A, 0x9B, 0x9C, 0x9D, 0x9E, 0x9F,
							 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26,
							 0x27, 0x28, 0x29, 0x2A, 0x2B, 0x2C, 0x2D,
							 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
							 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
							 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00},
                  	{0xAE, 0xAF, 0xB0, 0xB1, 0x80, 0x80, 0x80,
							 0xB2, 0x33, 0x34, 0x35, 0x00, 0x00, 0x00,
							 0xB6, 0x37, 0x38, 0x39, 0x00, 0x00, 0x00,
							 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
							 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
							 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00},
                     {0x80, 0x80, 0x80, 0xBA, 0xBB, 0xBC, 0xBD,
							 0x00, 0x00, 0x00, 0x3E, 0x3F, 0x40, 0xC1,
							 0x00, 0x00, 0x00, 0x42, 0x43, 0x44, 0xC5,
							 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80,
							 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80,
							 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80}};
							 
static const unsigned char WinMapDirection[4]={1,7,8,6};

static inline __attribute__((always_inline)) void SetCurrentFgColor(uint8_t fg) {
   //fg_color = fg;
    GDP_Col.fg=fg;
}

static inline __attribute__((always_inline)) void SetCurrentBgColor(uint8_t bg) {
   //bg_color = bg;
   GDP_Col.bg=bg;
}

static inline __attribute__((always_inline)) void Gotoxy(uint8_t x, uint8_t y)
{
   gp_moveto(CCNV_X(x),CCNV_Y(y));
}

static inline __attribute__((always_inline)) void WriteScreenxy(uint8_t x, uint8_t y,const char* const p_str)
{
   gp_writexy(CCNV_X(x),CCNV_X(y),0x11, p_str);
}

static inline __attribute__((always_inline)) void GDP_setpixel(uint16_t x, uint16_t y)
{
   while(!(GDP.cmd & 0x04u)) {};
   GDP.xl = x & 0xffu;
   GDP.xh = x >> 8u;
   GDP.yl = y & 0xffu;
   GDP.yh = y >> 8u;
   GDP.cmd = 0b10100000u;  // 2 Pixel in x direction
}

static inline __attribute__((always_inline)) void GDP_setpixel1(uint16_t x, uint16_t y)
{
   while(!(GDP.cmd & 0x04u)) {};
   GDP.xl = x & 0xffu;
   GDP.xh = x >> 8u;
   GDP.yl = y & 0xffu;
   GDP.yh = y >> 8u;
   GDP.cmd = 0b10000000u;  // 1 Pixel in x direction
}

void delay_ms(uint16_t ms) {
   clock_t ticks = ((clock_t)ms*200u)/1000u;
   clock_t start = _clock(NULL);
   while((_clock(NULL)-start)<ticks) {};
}

void draw_stone(uint8_t row, uint8_t col, uint8_t color) {
  static const uint8_t Stone[]={0x00,0x00,0x00,0x80,0xc0,0xe0,0xF0,0xf8,  //6
                              0xf8,0xfc,0xfc,0xfc,0xfc,0xfc,0xfc,0xf8,  //7
                              0xf8,0xf0,0xe0,0xc0,0x80,0x00,0x00,0x00, //8 

                              0x00,0x00,0x7e,0xff,0xff,0xff,0xff,0xff,  //3
                              0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,  //4
                              0xff,0xff,0xff,0xff,0xff,0x7e,0x00,0x00,  //5

                              0x00,0x00,0x00,0x01,0x03,0x07,0x0f,0x1f,  //0
                              0x1f,0x3f,0x3f,0x3f,0x3f,0x3f,0x3f,0x1f,  //1
                              0x1f,0x0f,0x07,0x03,0x01,0x00,0x00,0x00};  //2
                              
  uint8_t index=0u;  
  const uint16_t x_pos = CCNV_X(BOARD_X) + (col * 26u * 2u) + 2u;
  const uint16_t y_pos = CCNV_Y(BOARD_Y) + (row * 26u) + 2u;
  SetCurrentColor(color);
  for(uint16_t y=y_pos;y<(y_pos+24u);y+=8u) {
    for(uint16_t x=x_pos;x<(x_pos+48u);x+=2u) {
      uint8_t b=Stone[index++];
      for(uint8_t i=0u;i<8u;i++){
         if (b & 1u) {
           //const uint8_t color = (b & 1u)?fg_color:bg_color;
            //gp_moveto(x,y+i);
            //gp_drawto(x+1u,y+i);
            GDP_setpixel(x,y+i);
         }
        b>>=1u;
      }
    }
  }
}

#if 0
// Draw an 8x8 Graphic item
void draw_item(uint16_t x_pos, uint16_t y_pos, const uint8_t*  p_item)
{
   for(uint16_t x=x_pos;x<(x_pos+16u);x+=2u) {
      uint8_t b=*p_item++;
      for(uint8_t i=0u;i<8u;i++){
        const uint8_t color = (b & 0x80u)?fg_color:bg_color;
        SetCurrentColor(color);
        gp_moveto(x,y_pos+i);
        gp_drawto(x+1u,y_pos+i);
        b<<=1u;
      }
   }
}
#endif

void draw_edge(uint16_t x, uint16_t y) {
   // 8 vertical lines
   for (uint16_t i=0u;i<7u;i++) {
      // 8 lines per edge to draw
      uint8_t len=16u;
      for (uint16_t j=0u;j<7u;j++) {
         gp_moveto(x+i*26u*2u+1u,y+j);
         gp_drawto(x+i*26u*2u+len+1u,y+j);
         //gp_moveto(x+i*26u*2u,y+j+26u-9u);
         //gp_drawto(x+i*26u*2u+len,y+j+26u-9u);
         gp_moveto(x+(i+1)*26u*2u-1u,y+j);
         gp_drawto(x+(i+1)*26u*2u-len-1u,y+j);
         len-=2u;
      }
   }
}


void draw_board(void) {
   SetCurrentColor(BLUE | DARK);
   // 1. draw 7 horizontal lines
   for(uint16_t i=0u;i<=6u;i++) {
      gp_moveto(CCNV_X(BOARD_X),CCNV_Y(BOARD_Y)+(i*26u));
      gp_drawto(CCNV_X(BOARD_X)+(26u*7*2),CCNV_Y(BOARD_Y)+(i*26u));
      gp_moveto(CCNV_X(BOARD_X),CCNV_Y(BOARD_Y)+(i*26u)+1u);
      gp_drawto(CCNV_X(BOARD_X)+(26u*7*2),CCNV_Y(BOARD_Y)+(i*26u)+1u);
      if (i<6u) {
         draw_edge(CCNV_X(BOARD_X),CCNV_Y(BOARD_Y)+(i*26u)+1);
      }
   }
   
   // 1. draw 8 vertical lines
   for(uint16_t i=0u;i<=7u;i++) {
      gp_moveto(CCNV_X(BOARD_X)+(26u*i*2u),CCNV_Y(BOARD_Y));
      gp_drawto(CCNV_X(BOARD_X)+(26u*i*2u),CCNV_Y(BOARD_Y)+(26*6));
      gp_moveto(CCNV_X(BOARD_X)+(26u*i*2u)+1,CCNV_Y(BOARD_Y));
      gp_drawto(CCNV_X(BOARD_X)+(26u*i*2u)+1,CCNV_Y(BOARD_Y)+(26*6));
   }
}

static inline __attribute__((always_inline)) void set_player_color(void) {
    SetCurrentColor((NextPlayer==PLAYER_1)?GREEN:RED);
}

int main(void)
{
	//bool b=false;
   unsigned char tmp;
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
   gp_setflip(0u,0u);
   //GDP_Col.bg = GRAY | DARK;
   //GDP.ctrl2 |= (1u<<5u); // turn on BG mode
   
   initSound();
#if 0
   SetCurrentColor(RED);
   const uint16_t radius = 10u;
   for(int y=-radius; y<=radius; y++) {
      for(int x=-radius; x<=radius; x++) {
        if(x*x+y*y <= radius*radius) {
            GDP_setpixel1(100+x*2, 100+y);
         }
      }
   }

   gp_ci();
   //DefineStone();
   SetCurrentBgColor(BGCOLOR);
   gp_clearscreen();
   gp_cursor_off();
   gp_setflip(0u,0u);
#endif   
//while (1) {
      // Place your code here
	int key;

   //const time_t t= _gettime();
   //iprintf("Time: %u",(uint32_t) t);
   srand((unsigned) _gettime());

	//SetCurrentBgColor(GRAY | DARK);
   SetCurrentBgColor(BGCOLOR);
   SetCurrentColor(RED);
   gp_writexy(CCNV_X(20),CCNV_X(30),0x22, "Vier-Gewinnt!");
		SetCurrentColor(BLUE);
   WriteScreenxy(10,32-3,"n = New Game      x = Exit");
   WriteScreenxy(10,32-4,"z = Undo");
   WriteScreenxy(10,32-5,"t = Two Player");
   WriteScreenxy(10,32-6,"o = One Player / Auto move");
   WriteScreenxy(10,32-8,"Select column with keys 1 to 7");
   WriteScreenxy(10,32-9,"One Player mode");
   
   SetCurrentFgColor(GRAY | DARK);
   draw_board();
   
   NewGame();
   PlayerMode = ONE_PLAYER;

   do{
      if(WinningLine!=0)
      {
      	FlashWinningLine();
      }else {
         if(NextPlayer==PLAYER_1) {
            SetCurrentColor(GREEN);
            WriteScreenxy(10,32-11,"Player 1");
         }else{
            SetCurrentColor(RED);
            WriteScreenxy(10,32-11,"Player 2");
         }
      }
		key=gp_ci();
      if(key>='8')
      {
         	//* Extened Key Press 
            switch(key)
            {
            	case 'n':	// F1 = New Game 
               	NewGame();
                  break;

               case 'z': // F2 = Undo 
               	
               	
               	tmp=1;
              		do {
              			UndoMove();
              		} while( PlayerMode == ONE_PLAYER && tmp--);
               	
                  break;

               case 't': // F3 = Two Player  
                  SetCurrentColor(BLUE);
               	WriteScreenxy(10,32-9,"Two Player mode");
               	PlayerMode = TWO_PLAYER;
                  break;

               case 'o': // F4 = One Player / Auto move 
               	SetCurrentColor(BLUE);
                  WriteScreenxy(10,32-9,"One Player mode");
               	PlayerMode = ONE_PLAYER;
                  AutoMove();
                  break;
            	default:
               //	key=0;
                  break;
            }
      }
      if(key >= '1' && key < '8')
      {
         WriteScreenxy(10,32-11,"        ");
         playDrop();
         
         DropStone(key-'1');
         if(WinningLine==0 && PlayerMode != TWO_PLAYER) {
            AutoMove();
         }
      }
   }while(key != 'x'); 

   //SetCurrentColor(0u);
   GDP_Col.fg=1;
   GDP_Col.bg=0;
   gp_clearscreen();
//   };
}

void NewGame(void)
{
	unsigned char i,j;

//   randomize();
   /* Reset column height array */
   for(i=0;i!=7;i++)
   {
   	ColumnHeight[i]=0u;
	}

   /* Clear WinLineStone counters */
   for(i=1;i!=70;i++)
   {
   	WinLineStones[PLAYER_1][i]=0u;
      WinLineStones[PLAYER_2][i]=0u;
   }

   /* Set intial player */
   NextPlayer = PLAYER_1;

   WinningLine=0;
   MoveNumber = 0;

   /* Draw Empty Board */

   for(j=0;j!=6;j++)
   {
   	for(i=0;i!=7;i++)
      {
			DrawStone(i, j, EMPTY);
      }
   }
   SetCurrentColor(CYAN);
	{
      WriteScreenxy(BOARD_X, 0,"   1        2        3        4        5       6        7 ");
	}

}

/*
	FUNCTION		DrawStone

   This function draws a stone on the screen of 'Type' at
   location Row, Column
*/

void DrawStone(unsigned char Column, unsigned char Row, signed char Type)
{
	
//   textbackground(BLUE);
   uint8_t color=0u;
   switch(Type)
   {
   	case EMPTY:
           color=BGCOLOR;
           break;
      case PLAYER_1:
            color=GREEN;
            break;
      case PLAYER_2:
            color=RED;
				break;
   }
   draw_stone(Row, Column, color);
   
}

void DropStone(unsigned char Column)
{
	int Count;
	unsigned char Row;

	if(WinningLine == 0 && ColumnHeight[Column]<6)
   {
      Row = 5;
      Count = 6 - ColumnHeight[Column];
      do{
      	DrawStone(Column, Row, NextPlayer);
         if(--Count==0)
         {
         	break;
         }
         delay_ms(70);
         DrawStone(Column, Row, EMPTY);
         Row--;
		}while(1);
      delay_ms(70);
   	AddStone(Column);
   }
}

void UndoMove(void)
{
	int Column;

   if(MoveNumber>0)
   {
		DelStone();
 		Column = History[MoveNumber];
      DrawStone(Column, ColumnHeight[Column], EMPTY);
   }
}

void FlashWinningLine(void)
{
	unsigned char i,j,Index=0u;
	char Direction=0u,FlashState;

   for(i=0;i!=4;i++)
   {
   	for(j=0;j!=42;j++)
      {
      	if(WinMap[i][j] == WinningLine)
         {
         	Direction = WinMapDirection[i];
            Index = j;
         }
      }
	}

   FlashState = EMPTY;
   if(NextPlayer == PLAYER_1)
   {
      SetCurrentColor(RED);
      WriteScreenxy(10,32-11,"Player 2 won!");
   }
   else
   {
      SetCurrentColor(GREEN);
      WriteScreenxy(10,32-11,"Player 1 won!");
   }
   do{
   		j=Index;
   		for(i=0;i!=4;i++)
         {
         	DrawStone(j%7,j/7,FlashState);
            j += Direction;
         }
         if(FlashState == EMPTY)
         {
         	if(NextPlayer == PLAYER_1)
            {
            	FlashState = PLAYER_2;
            }
            else
            {
            	FlashState = PLAYER_1;
            }
         }
         else
         {
         	FlashState = EMPTY;
         }
			i=10;
			do {
				delay_ms(50);
         }while(!gp_csts()&&--i);
   }while(FlashState != EMPTY || !gp_csts()); 
   WriteScreenxy(10,32-11,"             ");
}



void AddStone(unsigned char Column)
{
	unsigned char i,j,k;

	/* Return if column is full */
	if(ColumnHeight[Column]==6)
   	return;

   /* Store move in history array and increase index */
	History[MoveNumber++] = Column;

   /* For each direction ... */
	for(i=0; i!=4 ; i++)
   {
   	/* Get index to WinMap for new stone location */
		j = Column + (ColumnHeight[Column]*7);
      /* for a maximum of 4 time's... */
      for(k=0;k!=4;k++)
      {
      	/* Check for valid win number */
      	if((WinMap[i][j]&0x7f))
         {
         	/* Add 1 to stone counter for this win line */
      		if(++WinLineStones[NextPlayer][(WinMap[i][j]&0x7F)]==4)
            	/* If 4 stones are in this line flag as winner */
         		WinningLine = WinMap[i][j];
         }
         /* Terminate loop if at edge of board */
         if((WinMap[i][j]&0x80))
         		break;
         /* Move index in direction of map */
      	j -= WinMapDirection[i];
      }
   }
   /* Add 1 to column height */
	ColumnHeight[Column]++;
   /* Change player */
 	if(NextPlayer==PLAYER_1)
   	NextPlayer = PLAYER_2;
   else
   	NextPlayer = PLAYER_1;
}

/*
	FUNCTION		DelStone

   This funtion removes the last stone dropped from the WinLineStone counters
   and ColumnHeight array. It also changes the player.

*/

void DelStone()
{
   unsigned char i,j,k,Column;

   /* Return if no moves to undo */
   if(MoveNumber==0)
   	return;

   /* No winning line */
   WinningLine = 0;

   /* Change player */
   if(NextPlayer == PLAYER_1)
   	NextPlayer = PLAYER_2;
   else
   	NextPlayer = PLAYER_1;

   /* Get last move column and decrease move index */
   Column = History[--MoveNumber];

   /* Decrease column height */
   ColumnHeight[Column]--;

   /* For each direction ... */
	for(i=0; i!=4 ; i++)
   {
   	/* Get index to WinMap for  stone location */
		j = Column + (ColumnHeight[Column]*7);
      /* for a maximum of 4 time's... */
      for(k=0;k!=4;k++)
      {
      	/* Check for valid win number */
      	if((WinMap[i][j]&0x7f))
         	/* Subtract 1 from stone counter for this win line */
      		--WinLineStones[NextPlayer][(WinMap[i][j]&0x7F)];
         /* Terminate loop if at edge of board */
         if((WinMap[i][j]&0x80))
         		break;
         /* Move index in direction of map */
      	j -= WinMapDirection[i];
      }
   }
}

void AutoMove(void)
{
	int MoveScore[7], Best; 
	unsigned char i,Column;
	
	set_player_color();
   WriteScreenxy(20,32-11,"Thinking ...");
   Best = -128;
   Column = 0;
   for(i=0;i!=7;i++)
   {
   	if(ColumnHeight[i]==6)
      {
      	MoveScore[i]= -128;
      	continue;
      }
      AddStone(i);
      if(WinningLine)
      	MoveScore[i] = 127;
   	else
   		MoveScore[i] = NextSearchLevel(4,-128);
      if(MoveScore[i]>Best)
      {
      	Best = MoveScore[i];
         Column = i;
      }

      DelStone();
   }
   playDrop();
	DropStone(Column);
	WriteScreenxy(20,32-11,"            ");
}

int NextSearchLevel(unsigned char Depth, int BestSoFar)
{
	int Best=-127,j;
	unsigned char i;


   if(Depth==0)
   	return GetScore();


   for(i=0;i!=7 ;i++)
   {
   	if(ColumnHeight[i]!=6)
      {
			AddStone(i);
         if(WinningLine)
         	Best = (int)122+Depth;
			j = NextSearchLevel(Depth-1, Best);
         if(j>Best)
         	Best = j;
         DelStone();
         if(Best==(int)122+Depth)
         	break;
      }

      if(BestSoFar >= -Best)
      	break;
   }

   if(Best == -127)
    return 0;
   else
    return -Best;
}

int GetScore(void)
{
	int score;
	unsigned char i;

   score = 0;
   for(i=1;i!=70;i++)
   {
   	if(WinLineStones[PLAYER_2][i]==0 || WinLineStones[PLAYER_1][i]==0)
      {
       	switch(WinLineStones[PLAYER_2][i])
        	{
        		case 1:score+=SCORE_1;break;
           	case 2:score+=SCORE_2;break;
           	case 3:score+=SCORE_3;break;
        	}
        	switch(WinLineStones[PLAYER_1][i])
        	{
        		case 1:score-=SCORE_1;break;
           	case 2:score-=SCORE_2;break;
           	case 3:score-=SCORE_3;break;
        	}
      }
   }

//   score += 7-random(15);
	//score += 7-((int)(Rnd16()%16));
   score += 7-((int)(rand()%16));
   if(NextPlayer == PLAYER_1)
   	return score;
   else
   	return -score;
}
