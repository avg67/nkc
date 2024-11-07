; Color Mandelbrot Demo
; (c) 2024 by Andreas V.

;PMIn equ -2250          ; Y
;PMAX EQU 750
;QMIN EQU -1500          ; X
;QMAX EQU 1500

PMIn equ -600 ;-2250          ; Y
PMAX EQU 150  ;750
QMIN EQU -1200          ; X
QMAX EQU -550
M EQU 16*1000*1000      ;
COL_OFFSET EQU 10
ANZAHL EQU 255
;ANZAHL EQU 16

CPU equ 2              ; 68000 CPU. Please change to 1 for 68008
color equ $ffffffa0*CPU
color_mode equ $ffffff7f*CPU
hscroll equ $ffffff61*CPU
gdp_page_reg equ $ffffff60*2

START:
        move.b #1,color_mode.w
        clr.b hscroll.w
        jsr @curoff
        clr.b d0
        clr.b d1
        jsr @setflip
;       clr.b gdp_page_reg.w
        jsr @clr
        move #511,d1
        movea.l #m,a3
xschleife:
;        move #255,d2
        move #511,d2
yschleife:
        move.l #pmax-pmin,d3
        muls d1,d3
        lsr.l #8,d3
        lsr.l #1,d3
        add #pmin,d3
        move.l #qmax-qmin,d4
        muls d2,d4
        lsr.l #8,d4
        lsr.l #1,d4
        add #qmin,d4
        clr.l d5
        clr.l d6
  ;      clr d7
        move #anzahl-1,d7
        movem.l d1-d2,-(a7)
iterat:
        move d5,d1
        muls d1,d1
        move d6,d0
        muls d0,d0
        sub.l d0,d1
        divs #1000,d1
        add d3,d1
        move d5,d2
        muls d6,d2
        divs #500,d2
        add d4,d2
        move d1,d5
        move d2,d6
 ;       addq #1,d7
        muls d1,d1
        muls d2,d2
        add.l d2,d1
;        cmp.l #m,d1
        cmp.l a3,d1
;        bge.s ausgabe
        ;cmp #anzahl,d7
        ;beq.s ausgabe
        dbge d7,iterat
;        bra.s iterat
ausgabe:
        movem.l (a7)+,d1-d2
        ;cmp #anzahl,d7
        addq #1,d7
        beq.s weiter
        ;btst #0,d7
        ;beq.s weiter
        jsr @moveto
        move.b d7,d0
        not.b d0
        add.b #COL_OFFSET,d0
;        sub.b #255,d0
;        ror.b #2,d0
        move.b d0,color.w
        move.b #$80,d0
        jsr @cmd
weiter:
        dbra d2,yschleife
        dbra d1,xschleife
warte:
        jsr @csts
        beq.s warte
        move.b #0,color_mode.w
        rts

