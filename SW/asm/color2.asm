; Color Demo for 256 Color Mode of GDP-FPGA
; (c) 2024 by Andreas V.
cpu equ 2   ; 68000 CPU. Please change to 1 for 68008
color_mode_reg equ $ffffff7f*cpu
fg_color_reg equ $ffffffa0*cpu
bg_color_reg equ $ffffffa1*cpu
gdp_cmd_reg equ $ffffff70*cpu
gdp_csize_reg equ $ffffff73*cpu
gdp_page_reg equ $ffffff60*cpu
gdp_hscroll_reg equ $ffffff61*cpu

start:

        jsr @wait
        move.b #1,color_mode_reg.w
        move.b #0,bg_color_reg.w
        clr.b gdp_hscroll_reg.w
        jsr @curoff
        clr.b d0
        clr.b d1
        jsr @setflip
        clr.b gdp_page_reg.w
        move.b #$04,gdp_cmd_reg.w       ; clear screen
        jsr @wait

        lea text(pc),a0
        clr.w d1
        move.w #500,d2
        move.b #$11,d0
        jsr @write

        move.b #$44,gdp_csize_reg.w

        lea table(pc),a0
        moveq #11,d6    ; 12 Zeilen a 19 Spalten
        clr.b d0
        clr.w d1
        move.w #150,d2
loop2:  move.w #18-1, d7
        jsr @moveto
        move.b (a0)+,d0 ; Startfarbe
loop1:
        bsr.s draw
        addq.b #1,d0
        dbra d7,loop1
        add.w #16,d2
        clr.w d1
        dbra d6,loop2

        move.w #100,d2
        move.b #232,d0  ; Grau start-index
        moveq #11,d7
        bsr.s draw1

        move.w #400,d2
        clr.b d0  ; ANSI palette start-index
        moveq #7,d7
        bsr.s draw1


wait:   jsr @csts
        beq.s wait
        move.b #0,color_mode_reg.w
        rts

; start y-pos in D2.w
; start-FARBE in D0
; nr of colums in D7
draw1:
        moveq #1,d6
        movea.l d7,a0   ; Backup d7
        lea table1(pc),a1
        clr.l d4
        move.b d0,d4
loop3:  ;moveq #11,d7
        move.l a0,d7
        jsr @moveto
loop4:
        move.b d4,d0
        cmp.b #16,d4
        bhs.s grey
        move.b 0(a1,d4.w),d0
grey:
        bsr.s draw
        addq.b #1,d4
        dbra d7,loop4
        sub.w #16,d2
        dbra d6,loop3
        rts

;color in d0
draw:
        jsr @wait
        move.b d0, fg_color_reg.w
        move.b #$0b,gdp_cmd_reg.w
        rts
table: dc.b 214,178,142,106,70,34,196,160,124,88,52,16
table1: dc.b 0,12,11,10,13,14,15,9, 8,4,3,2,5,6,7,1
text: dc.b 'Screen resolution: 512x512 with 256 Colors',0
