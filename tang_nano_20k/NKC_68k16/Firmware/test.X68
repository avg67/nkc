*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $0
VGABASE EQU $FFFFF000  
;GDP_BASE EQU (VGABASE + ($70*2))
GDP_SFR_BASE EQU $ffffff70*2
KEY_SFR_BASE EQU $ffffff68*2
DIP_SFR_BASE EQU $ffffff69*2

GPIO_SFR_BASE EQU $ffffff00*2

CHARBUF equ $80000800

;	org $1d0000

	dc.l	STACK+$100		; Initial stack pointer
	dc.l	$1d0000+START

START:				; first instruction of program
;	lea 	STACK,a7
    clr.l d0
    clr.l d1
    clr.l d2
    clr.l d3
    clr.l d4
    clr.l d5
    clr.l d6
    clr.l d7
    movea.l d0,a0
    movea.l d0,a1
    movea.l d0,a2
    movea.l d0,a3
    movea.l d0,a4
    movea.l d0,a5
    movea.l d0,a6
    moveq #$99,d0
    move.b #$ff,GPIO_SFR_BASE.w
    move.b #$55,(GPIO_SFR_BASE+2).w
    move.b (GPIO_SFR_BASE+2).w,d0
    
*    moveq #4,d7   
*    move.b DIP_SFR_BASE.w ,d0
*    lea $400.w,a0
*wait_key:
*    move.b KEY_SFR_BASE.w ,d0
*    btst #7,d0
*    bne.s wait_key
*    move.b d0,(a0)+
*    move.b DIP_SFR_BASE.w ,d0
*    dbra d7,wait_key
*    move.l $400,d0
    move.l #$12345678, 0.w
    move.l 0.w,d0
    move.l #$789ABCDE, $1d000
    move.l $1d000,d1

	lea GDP_SFR_BASE,a1
	move.b #4,(a1)

    lea $800000,a0
    clr.l d0
    moveq #127,d7  ; nr of columns
.m3
    move.l d0,(a0)+
    addq.l #1,d0
    dbra d7,.m3

    
	moveq #2,d0
	movep.w d0,(8,a1)
	nop
	movep.w (8,a1),d1
	addq.w #1,d0
	move.b #55,GDP_SFR_BASE.w
;	move.b #$00,(4,a1)
;	move.b #$02,(6,a1)
	lea	$2ff00,a0 ;$3ff00
    lea $1e0000,a1
	move.w #$7654,(a0)
	move.w #$3210,($fe,a0)
	moveq #1,d0
	move.l #512,d2
	move #255,d6  ; nr of lines
.m2	
	moveq #127,d7  ; nr of columns
.m1
	move.w d0,(a0)
	move.w d0,(a1)
	move.w (a0)+,d1
    move.w (a1)+,d3
    cmp.w d0,d1
    bne.s stop
    cmp.w d0,d3
    bne.s stop

	addq #1,d0
	dbf d7,.m1
  sub.l d2,a0
  dbf d6,.m2
stop:
.end bra .end  

STACK:

  END



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
