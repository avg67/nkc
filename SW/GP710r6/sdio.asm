*******************************************************************************
*                          680xx Grundprogramm sdio                           *
*                             2009 Jens Mewes, 2025 AVG                       *
*                               V 7.10 Rev 6                                  *
*                                06.07.2025                                   *
*                             SD-Card-Routinen, patched                       *
*******************************************************************************

SDCTL equ $82

MACRO sd1rdbyte
 move.b #$ff, spidata.w                 * Dummybyte
*sd1rd1b||:
* btst.b #0, spictrl.w                   * OK?
* beq.s sd1rd1b||
 move.b spidata.w, |0
ENDMACRO

MACRO sd1wrbyte                      * schreibt ein Byte auf die SD-Card
 move.b |0, spidata.w                   * Daten ausgeben
*sd1wr1b||:
* btst.b #0, spictrl.w                   * Bereit?
* beq.s sd1wr1b||
ENDMACRO

sdtest:                         * Test, ob Laufwerk vorhanden
                                        * d4 enthûlt Laufwerk
 btst.b #6, keydil(a5)                  * GDP-FPGA da?
 beq.s sdtst00                          * nein, dann Softwarelüsung
 bra sd1test
sdtst00:
 movem.l d1-d7/a1/a2/a6, -(a7)
 and #$0f, d4
 cmp.b #1, d4                           * SD-Card 0?
 bne.s sdtst01                          * nein
 move.b #$ff, d2                        * d2 = sdout
 move.b #SPI0_DI, d4                    * d4 = SPI_DI
 move.b #SPI0_CS, d5                    * d5 = SPI_CS
 move.b #SPI0_DO, d6                    * d6 = SPI_DO
 move.b #SPI0_CLK, d7                   * d7 = SPI_CLK
 lea sd1geo(a5), a6                     * Speicher fýr Grüsse...
 bra.s sdtst02
sdtst01:
 cmp.b #2, d4                           * SD-Card 1?
 bne sdtster                            * nein, dann Fehler
 move.b #$ff, d2
 move.b #SPI1_DI, d4
 move.b #SPI1_CS, d5
 move.b #SPI1_DO, d6
 move.b #SPI1_CLK, d7
 lea sd2geo(a5), a6
sdtst02:
 movea.l a6, a1                         * Adresse der Ausgabedaten sichern
 bsr sdinit
 tst.b d0
 bmi sdtster                            * Fehler SD-Card nicht gefunden
 lea idebuff(a5), a0
 lea spicmd9(pc), a2                    * CSD Kommando
 move #16, d0                           * 16 Byte
 bsr sdrdblk                            * CSD-Register lesen
 lea idebuff(a5), a0
 move.b 0(a0), d0                       * CSD Struct
 and.b #$c0, d0                         * nur oberen 2 Bit
 cmp.b #$40, d0                         * 01
 bne.s sdtst02a
 move #1, SDART(a6)
 lea sdhctxt(pc), a2
 bsr sdhcsize                           * SDHC-Card
 bra.s sdtst02d
sdtst02a:
 clr SDART(a6)
 cmp.b #$80, d0                         * MMC-Card?
 beq.s sdtst02b                         * nein dann SD-Card
 lea sdtxt(pc), a2
 bra.s sdtst02c
sdtst02b:
 lea mmctxt(pc), a2
sdtst02c:
 bsr sdcsize                            * sonst SD-/MMC-Card
sdtst02d:
 addq.l #SDNAME, a6                     * a6 auf SD-Name
sdtst02e:
 move.b (a2)+, (a6)+
 bne.s sdtst02e
 subq.l #1, a6                          * auf die Null
*cmp #512, d0                           * AV patched
*bne.s sdtster                          * nicht unterstýtzte Blockgrüsse
 clr.l d0
 lea spicmd10(pc), a2                   * CID Kommando
 move #16, d0                           * 16 Byte
 bsr sdrdblk                            * CID Bytes einlesen
 lea idebuff(a5), a0                    * Puffer zurýck
 addq.l #3, a0                          * a0 auch auf Name
 moveq #5-1, d3                         * 5 Bytes
sdtst03:
 move.b (a0)+, (a6)+
 dbra d3, sdtst03
 clr.b (a6)+                            * zum Schluþ ne Null
 movea.l a1, a0                         * Ausgabepuffer in a0
 clr.l d0                               * Alles OK
 movem.l (a7)+, d1-d7/a1/a2/a6
 bra carres
sdtster:
 moveq #-1, d0
 movem.l (a7)+, d1-d7/a1/a2/a6
 bra carset


sd1test:
 movem.l d1-d7/a1/a2/a6, -(a7)
 and #$0f, d4
 cmp.b #1, d4                           * SD-Card 0?
 bne.s sd1tst01                         * nein
 move.b #SDCTL, d2                        * d2 = sdout 20MHz
 move.b #SPIH0_CS, d5                   * d5 = SPI_CS
 lea sd1geo(a5), a6                     * Speicher fýr Grüsse...
 bra.s sd1tst02
sd1tst01:
 cmp.b #2, d4                           * SD-Card 1?
 bne sd1tster                           * nein, dann Fehler
 move.b #SDCTL, d2
 move.b #SPIH1_CS, d5
 lea sd2geo(a5), a6
sd1tst02:
 movea.l a6, a1                         * Adresse der Ausgabedaten sichern
 bsr sd1init
 tst.b d0
 bmi sd1tster                           * Fehler SD-Card nicht gefunden
 lea idebuff(a5), a0
 lea spicmd9(pc), a2                    * CSD Kommando
 move #16, d0                           * 16 Byte
 bsr sd1rdblk                           * CSD-Register lesen
 lea idebuff(a5), a0
 move.b 0(a0), d0                       * CSD Struct
 and.b #$c0, d0                         * nur oberen 2 Bit
 cmp.b #$40, d0
 bne.s sd1tst2a
 move #1, SDART(a6)
 lea sdhctxt(pc), a2
 bsr sdhcsize                           * SDHC-Card
 bra.s sd1tst2d
sd1tst2a:
 clr SDART(a6)
 cmp.b #$80, d0                         * MMC-Card?
 beq.s sd1tst2b                         * nein dann SD-Card
 lea sdtxt(pc), a2
 bra.s sd1tst2c
sd1tst2b:
 lea mmctxt(pc), a2
sd1tst2c:
 bsr sdcsize                            * sonst SD-/MMC-Card
sd1tst2d:
 addq.l #SDNAME, a6                     * a6 auf SD-Name
sd1tst2e:
 move.b (a2)+, (a6)+
 bne.s sd1tst2e
 subq.l #1, a6                          * auf die Null
*cmp #512, d0                           * AV patched
*bne.s sd1tster                         * nicht unterstýtzte Blockgrüsse
 clr.l d0
 lea spicmd10(pc), a2                   * CID Kommando
 move #16, d0                           * 16 Byte
 bsr sd1rdblk                           * CID Bytes einlesen
 lea idebuff(a5), a0                    * Puffer zurýck
 addq.l #3, a0                          * a0 auch auf Name
 moveq #5-1, d3                         * 5 Bytes
sd1tst05:
 move.b (a0)+, (a6)+
 dbra d3, sd1tst05
 clr.b (a6)+                            * zum Schluþ ne Null
 movea.l a1, a0                         * Ausgabepuffer in a0
 clr.l d0                               * Alles OK
 movem.l (a7)+, d1-d7/a1/a2/a6
 bra carres
sd1tster:
 moveq #-1, d0
 movem.l (a7)+, d1-d7/a1/a2/a6
 bra carset


sdcsize:
 move.b 6(a0), d0                       * MSB von C_SIZE
 and.b #$03, d0                         * nur Bit 0 und 1
 lsl.l #8, d0                           * 8 Bit nach Links
 move.b 7(a0), d0                       * die nûchsten 8 Bit
 lsl.l #8, d0                           * erstmal 8 Bit weiter
 move.b 8(a0), d0                       * hier kommt der Rest
 lsr.l #6, d0                           * wieder 6 Bit zurýck
 addq.l #1, d0                          * um 1 erhühen
 move.l d0, d1                          * C_SIZE nach d1 sichern
 clr.l d0
 move.b 9(a0), d0                       * die beiden MSBs von C_SIZE_MULT
 lsl.w #8, d0                           * jetzt im oberen Byte
 move.b 10(a0), d0                      * das letzte Bit
 lsr.w #7, d0                           * auf Bit 2-0
 and.w #$7, d0                          * nur 3 Bit
 addq.l #2, d0                          * Jetzt korrekter Wert
 asl.l d0, d1                           * (C_SIZE+1)*2^(C_SIZE_MULT+2)
 clr.l d0
 move.b 5(a0), d0                       * READ_BLK_LEN
 and.b #$0f, d0                         * nur unteren 4 Bit
 asl.l d0, d1                   * (C_SIZE+1)*2^(C_SIZE_MULT+2)*2^READ_BLK_LEN
 lsr.l #8, d1
 lsr.l #1, d1                           * /512 => in Sektoren
 move.l d1, sdsize(a6)                  * Grüsse (in Sektoren) abspeichern
 moveq.l #1, d1
 asl.l d0, d1
 move d1, d0
*move.w d0, sdbpblk(a6)                 * Bytes pro Block abspeichern
 move.w #512,sdbpblk(a6)                * AV patched

 rts


sdhcsize:
 clr.l d1
 move.b 7(a0), d1                       * MSB
 and.b #$3f, d1                         * oberen Byte nicht
 swap d1                                * jetzt in Byte #16 - #21
 move.b 8(a0), d1
 lsl #8, d1                             * nach Byte #15 - #8
 move.b 9(a0), d1                       * jetzt auch LSB
 move #10, d0
 lsl.l d0, d1                           * *1024 => in Sektoren
 move.l d1, sdsize(a6)
 move #512, d0
 move.w d0, sdbpblk(a6)                 * Bytes pro Block abspeichern
 rts


sdinit:                         * Initialisieren der SD-Card
 movem.l d3/a0/a2, -(a7)
 bset.b d5, d2                          * CS auf high
 move.b d2, spictrl.w
                                        * min. 74 Clocks an SD
 moveq #$16, d3                         * Anzahl
sdinit2:
 move.b #$ff, d0                        * dummy Daten
 bsr sdwrbyte                           * ein Byte schreiben
 dbra d3, sdinit2
 lea spicmd0(pc), a2                    * Kommando 0
 move #1000*cpu, d1                     * Timeout
sdinit3:
 bsr sdwrcmd                            * Kommando schreiben
 cmp.b #1, d0                           * OK?
 beq.s sdinit4
 dbra d1, sdinit3
 moveq #-1, d0
 bra.s sdinitex                         * Abbruch
sdinit4:
 lea spicmd1(pc), a2                    * Kommando 1
 move #1000*cpu, d1                     * Timeout
sdinit5:
 bsr sdwrcmd                            * Kommando schreiben
 tst.b d0                                 * OK?
 beq.s sdinit6
 dbra d1, sdinit5
 moveq #-1, d0
 bra.s sdinitex                         * Abbruch
sdinit6:
 clr.l d0
sdinitex:
 bset.b d5, d2                          * SD Disablen
 move.b d2, spictrl.w
 movem.l (a7)+, d3/a0/a2
 rts


sd1init:                        * Initialisieren der SD-Card
 movem.l d3/a0/a2, -(a7)
                                        * min. 74 Clocks an SD
 moveq #16, d3                          * Anzahl 136 Clocks
 bclr.b d5, d2                          * CS auf high
 move.b d2, spictrl.w
 move.b #$ff, d0                        * dummy Daten
sd1init2:
* bsr sd1wrbyte                          * ein Byte schreiben
 .sd1wrbyte d0                         * ein Byte schreiben
 dbra d3, sd1init2
 lea spicmd0(pc), a2                    * Kommando 0
 move #1000*cpu, d1                     * 1000*cpu Versuche
sd1init3:
 bsr sd1wrcmd                           * Kommando schreiben
 cmp.b #1, d0                           * OK?
 beq.s sd1init4
 dbra d1, sd1init3
 moveq #-1, d0
 bra.s sd1initx                         * Abbruch
sd1init4:
 lea spicmd1(pc), a2                    * Kommando 1
 move #1000*cpu, d1                     * 1000*cpu Versuche
sd1init5:
 bsr sd1wrcmd                           * Kommando schreiben
 tst.b d0                               * OK?
 beq.s sd1init6
 dbra d1, sd1init5
 moveq #-1, d0
 bra.s sd1initx                         * Abbruch
sd1init6:
 clr.l d0
sd1initx:
 bclr.b d5, d2                          * SD Disablen
 move.b d2, spictrl.w
 movem.l (a7)+, d3/a0/a2
 rts

sddiski:                       * interne SD IO-Routine
 moveq #1, d0                  * 1024 BPS
 bra.s sddisk1

sddisk:                        * SD IO-Routine
 moveq #0, d0                  * 512 BPS
sddisk1:
 movem.l d1-d7/a0-a3/a6, -(a7)
 bsr.s sdcomm                  * Hauptroutine aufrufen
 movem.l (a7)+, d1-d7/a0-a3/a6
rts

sdbeftab:                      * Tabelle der Befehle
 dc.w sdok-sdbeftab            * Auf Track 0
 dc.w sdbef1-sdbeftab          * Sektor lesen (d2.l/d3.b/a0.l)
 dc.w sdbef2-sdbeftab          * Sektor schreiben (d2.l/d3.b/a0.l)
 dc.w sdnok-sdbeftab           * Sektor + ECC lesen (d2.l/a0.l)
 dc.w sdnok-sdbeftab           * Sektor + ECC schreiben (d2.l/a0.l)
 dc.w sdok-sdbeftab            * Mode auswûhlen (d2.b/a0.l)
 dc.w sdok-sdbeftab            * Parameter des Laufwerks lesen (d2.b/d3.b/a0.l)
 dc.w sdok-sdbeftab            * Sektor suchen (d2.l)
 dc.w sdok-sdbeftab            * Laufwerk breit ?
 dc.w sdok-sdbeftab            * Park
 dc.w sdok-sdbeftab            * Unpark
 dc.w sdnok-sdbeftab           * Sektor lesen (d2.l/d3.w/a0.l)
 dc.w sdnok-sdbeftab           * Sektor schreiben (d2.l/d3.w/a0.l)
 dc.w sdnok-sdbeftab           * Buffer lesen (d2.w/a0.l)
 dc.w sdnok-sdbeftab           * Buffer schreiben (d2.w/a0.l)
 dc.w sdok-sdbeftab            * Einheit reservieren (d2.w/d3.w/a0.l)
 dc.w sdok-sdbeftab            * Einheit freigeben (d2.w)
 dc.w sdnok-sdbeftab           * Sektoren schreiben und prýfen (d2.l/d3.w/a0.l)
 dc.w sdnok-sdbeftab           * Sektor prýfen (d2.l/d3.w)
 dc.w sdok-sdbeftab            * Diagnostic senden
 dc.w sdnok-sdbeftab           * Sektor suchen (d2.l)
 dc.w sdok-sdbeftab            * Zûhler-Statistik lesen (a0.l)
 dc.w sdbef22-sdbeftab         * Grüþe der Platte lesen (d2.l/d3.b/a0.l)
 dc.w sdnok-sdbeftab           * Internen Test durchfýhren
 dc.w sdbef24-sdbeftab         * Laufwerksnamen lesen (a0.l)
 dc.w sdok-sdbeftab            * Liste der Defekte lesen (d2.b/d3.w/a0.l)
 dc.w sdok-sdbeftab            * Neue defekte Blücke schreiben (a0.l)
 dc.w sdok-sdbeftab            * Fehler lesen
 dc.w sdok-sdbeftab            * Formatieren (d2.b/d3.w/a0.l)


sdcomm:
 cmp #29, d1
 beq sdok                       * keine Eigenen Befehle
 bhi sderr                      * Wert zu gross
 and #$0f, d4
 cmp.b #1, d4                   * SD-Card0?
 bne.s sdc1                     * nü
 lea sd1geo(a5), a6
 bra.s sdc2
sdc1:
 cmp.b #2, d4                   * SD-Card1?
 bne.s sdnok                    * nü
 lea sd2geo(a5), a6
sdc2:
 add d1, d1                     * mal 2 da Wort
 btst.b #6, keydil(a5)          * GDP-FPGA da?
 bne.s sdc10                    * ja!
 move sdbeftab(pc,d1.w), d1     * Sprungwert laden
 jsr sdbeftab(pc,d1.w)
 bra carres
sdc10:
 move sdbeftb1(pc,d1.w), d1     * Sprungwert laden
 jsr sdbeftb1(pc,d1.w)
 bra carres

sdbeftb1:                      * Tabelle der Befehle fýr Hardware-SPI
 dc.w sdok-sdbeftb1            * Auf Track 0
 dc.w sd1bef1-sdbeftb1         * Sektor lesen (d2.l/d3.b/a0.l)
 dc.w sd1bef2-sdbeftb1         * Sektor schreiben (d2.l/d3.b/a0.l)
 dc.w sdnok-sdbeftb1           * Sektor + ECC lesen (d2.l/a0.l)
 dc.w sdnok-sdbeftb1           * Sektor + ECC schreiben (d2.l/a0.l)
 dc.w sdok-sdbeftb1            * Mode auswûhlen (d2.b/a0.l)
 dc.w sdok-sdbeftb1            * Parameter des Laufwerks lesen (d2.b/d3.b/a0.l)
 dc.w sdok-sdbeftb1            * Sektor suchen (d2.l)
 dc.w sdok-sdbeftb1            * Laufwerk breit ?
 dc.w sdok-sdbeftb1            * Park
 dc.w sdok-sdbeftb1            * Unpark
 dc.w sdnok-sdbeftb1           * Sektor lesen (d2.l/d3.w/a0.l)
 dc.w sdnok-sdbeftb1           * Sektor schreiben (d2.l/d3.w/a0.l)
 dc.w sdnok-sdbeftb1           * Buffer lesen (d2.w/a0.l)
 dc.w sdnok-sdbeftb1           * Buffer schreiben (d2.w/a0.l)
 dc.w sdok-sdbeftb1            * Einheit reservieren (d2.w/d3.w/a0.l)
 dc.w sdok-sdbeftb1            * Einheit freigeben (d2.w)
 dc.w sdnok-sdbeftb1           * Sektoren schreiben und prýfen (d2.l/d3.w/a0.l)
 dc.w sdnok-sdbeftb1           * Sektor prýfen (d2.l/d3.w)
 dc.w sdok-sdbeftb1            * Diagnostic senden
 dc.w sdnok-sdbeftb1           * Sektor suchen (d2.l)
 dc.w sdok-sdbeftb1            * Zûhler-Statistik lesen (a0.l)
 dc.w sdbef22-sdbeftb1         * Grüþe der Platte lesen (d2.l/d3.b/a0.l)
 dc.w sdnok-sdbeftb1           * Internen Test durchfýhren
 dc.w sdbef24-sdbeftb1         * Laufwerksnamen lesen (a0.l)
 dc.w sdok-sdbeftb1            * Liste der Defekte lesen (d2.b/d3.w/a0.l)
 dc.w sdok-sdbeftb1            * Neue defekte Blücke schreiben (a0.l)
 dc.w sdok-sdbeftb1            * Fehler lesen
 dc.w sdok-sdbeftb1            * Formatieren (d2.b/d3.w/a0.l)


sdok:                           * liefert nur ein OK zurýck
 clr.l d0
 bra carres

sdnok:                          * liefert einen Fehler zurýck
 moveq #-1, d0
 rts

sderr:                          * liefert Fehler und Carry zurýck
 moveq #-1, d0
 bra carset

sdbef1:                         * Sektoren lesen
 move.l d2, d1                  * Startsektor
 and.l #$000000ff, d3           * nur Byte gýltig
 bne.s sdb1a                    * falls Null, dann 256
 move.l #256, d3
sdb1a:
 asl.l d0, d1                   * Startsektor *2, falls 1024 BPS
 asl.l d0, d3                   * Anzahl * 2, falls 1024 BPS
sdb1b:
 subq.l #1, d3                  * Anzahl-1 als Zûhler
 cmp.b #1, d4                   * SD-Card 0?
 bne.s sdb1c                    * nein
 move.b #$ff, d2                * d2 = sdout
 move.b #SPI0_DI, d4            * d4 = SPI_DI
 move.b #SPI0_CS, d5            * d5 = SPI_CS
 move.b #SPI0_DO, d6            * d6 = SPI_DO
 move.b #SPI0_CLK, d7           * d7 = SPI_CLK
 bra.s sdb1d
sdb1c:
 cmp.b #2, d4                   * SD-Card 1?
 bne.s sdb1er                   * nein, dann Fehler
 move.b #$ff, d2
 move.b #SPI1_DI, d4
 move.b #SPI1_CS, d5
 move.b #SPI1_DO, d6
 move.b #SPI1_CLK, d7
sdb1d:
 move.l d1, d0                  * Sektor zurýck
 bsr sdrdsec                    * Lesen
 addq.l #1, d1                  * nûchsten Sektor
 dbra d3, sdb1d
 clr.l d0
 bra.s sdb1ex
sdb1er:
 moveq #-1, d0
sdb1ex:
 rts

sd1bef1:                        * Sektoren lesen Hardware SPI
 move.l d2, d1                  * Startsektor
 and.l #$000000ff, d3           * nur Byte gýltig
 bne.s sd1b1a                   * falls Null, dann 256
 move.l #256, d3
sd1b1a:
 asl.l d0, d1                   * Startsektor *2, falls 1024 BPS
 asl.l d0, d3                   * Anzahl * 2, falls 1024 BPS
sd1b1b:
 subq.l #1, d3                  * Anzahl-1 als Zûhler
 cmp.b #1, d4                   * SD-Card 0?
 bne.s sd1b1c                   * nein
 move.b #SDCTL, d2                * d2 = sdout 10MHz
 move.b #SPIH0_CS, d5           * SPI0 Select
 bra.s sd1b1d
sd1b1c:
 cmp.b #2, d4                   * SD-Card 1?
 bne.s sd1b1er                  * nein, dann Fehler
 move.b #SDCTL, d2                * d2 = sdout 10MHz
 move.b #SPIH1_CS, d5           * SPI1 Select
sd1b1d:
 move.l d1, d0                  * Sektor zurýck
 bsr sd1rdsec                   * Lesen
 addq.l #1, d1                  * nûchsten Sektor
 dbra d3, sd1b1d
 clr.l d0
 bra.s sd1b1ex
sd1b1er:
 moveq #-1, d0
sd1b1ex:
 rts

sdbef2:                         * Sektoren schreiben
 movea.l a0, a1                 * Buffer retten
 move.l d2, d1                  * Startsektor
 and.l #$000000ff, d3           * nur Byte gýltig
 bne.s sdb2a                    * falls Null, dann 256
 move.l #256, d3
sdb2a:
 asl.l d0, d1                   * Startsektor *2, falls 1024 BPS
 asl.l d0, d3                   * Anzahl * 2, falls 1024 BPS
sdb2b:
 subq.l #1, d3                  * Anzahl-1 als Zûhler
 cmp.b #1, d4                   * SD-Card 0?
 bne.s sdb2c                    * nein
 move.b #$ff, d2                * d2 = sdout
 move.b #SPI0_DI, d4            * d4 = SPI_DI
 move.b #SPI0_CS, d5            * d5 = SPI_CS
 move.b #SPI0_DO, d6            * d6 = SPI_DO
 move.b #SPI0_CLK, d7           * d7 = SPI_CLK
 bra.s sdb2d
sdb2c:
 cmp.b #2, d4                   * SD-Card 1?
 bne.s sdb2er                   * nein, dann Fehler
 move.b #$ff, d2
 move.b #SPI1_DI, d4
 move.b #SPI1_CS, d5
 move.b #SPI1_DO, d6
 move.b #SPI1_CLK, d7
sdb2d:
 moveq #10-1, d6                * 10 Versuche
sdb2e:
 movea.l a1, a0                 * Buffer zurýck
 move.l d1, d0                  * Sektor zurýck
 bsr sdwrsec                    * Schreiben
 tst.b d0
 dbeq d6, sdb2e                 * Hat nicht geklappt, nochmal
 bmi.s sdb2er                   * Fehler! Abbruch
 addq.l #1, d1                  * nûchsten Sektor
 adda.l #512, a1                * Buffer auch
 dbra d3, sdb2d
 clr.l d0
 movea.l a1, a0
 bra.s sdb2ex
sdb2er:
 moveq #-1, d0
sdb2ex:
 rts

sd1bef2:                        * Sektoren schreiben Hardware SPI
 movea.l a0, a1                 * Buffer retten
 move.l d2, d1                  * Startsektor
 and.l #$000000ff, d3           * nur Byte gýltig
 bne.s sd1b2a                   * falls Null, dann 256
 move.l #256, d3
sd1b2a:
 asl.l d0, d1                   * Startsektor *2, falls 1024 BPS
 asl.l d0, d3                   * Anzahl * 2, falls 1024 BPS
sd1b2b:
 subq.l #1, d3                  * Anzahl-1 als Zûhler
 cmp.b #1, d4                   * SD-Card 0?
 bne.s sd1b2c                   * nein
 move.b #SDCTL, d2                * d2 = sdout 10MHz
 move.b #SPIH0_CS, d5           * d5 = SPI_CS
 bra.s sd1b2d
sd1b2c:
 cmp.b #2, d4                   * SD-Card 1?
 bne.s sd1b2er                  * nein, dann Fehler
 move.b #SDCTL, d2
 move.b #SPIH1_CS, d5
sd1b2d:
 moveq #10-1, d6                * 10 Versuche
sd1b2e:
 movea.l a1, a0                 * Buffer zurýck
 move.l d1, d0                  * Sektor zurýck
 bsr sd1wrsec                   * Schreiben
 tst.b d0
 dbeq d6, sd1b2e                * Hat nicht geklappt, nochmal
 bmi.s sd1b2er                  * Fehler! Abbruch
 addq.l #1, d1                  * nûchsten Sektor
 adda.l #512, a1                * Buffer auch
 dbra d3, sd1b2d
 clr.l d0
 movea.l a1, a0
 bra.s sd1b2ex
sd1b2er:
 move.l #-1, d0
sd1b2ex:
 rts


sdbef22:                       * Kapazitût lesen
 clr.l d2
 move.l SDSIZE(a6), d2          * Grüsse a 512 Byte
 clr.l d1
 move sdbpblk(a6), d1           * 512 Byte/Sektor
 lsr.l d0, d2                   * Grüsse /2, falls 1024 BPS
 asl.l d0, d1                   * Anzahl * 2, falls 1024 BPS
sdb22ex:
 move.l d2, 0(a0)
 move.l d1, 4(a0)
 clr.l d0
 rts

sdbef24:                        * LW Name lesen
 move #36-1, d3                 * 36 Byte Buffer
 movea.l a0, a1
sdb24a:
 clr.b (a1)+                    * lüschen
 dbra d3, sdb24a
 move.b #1, 3(a0)               * ??? aus SCSI Bescheibung ýbernommen
 move.b #$3d, 4(a0)             * ??? aus SCSI Bescheibung ýbernommen
 move #15-1, d3                 * 15 Byte ýbertragen
 movea.l a6, a1                 * sd_geo
 adda.l #SDNAME, a1
 adda.l #8, a0
sdb24b:
 move.b (a1)+, (a0)+            * Name kopieren
 dbra d3, sdb24b
 rts


sdwrcmd:                        * Commando-Bytes an SD-Card ausgeben
 movem.l d1/d3/a0/a2, -(a7)
 bset.b d5, d2                          * CS auf high
 move.b d2, spictrl.w
 move.b #$ff, d0                        * dummy Daten
 bsr sdwrbyte                           * erzeugt 8 Clockzyklen
 bclr.b d5, d2                          * CS auf low (aktiv)
 move.b d2, spictrl.w
 moveq #6-1, d3                         * 6 Bytes
sdwrcmd1:
 move.b (a2)+, d0                       * CMD-Byte
 bsr sdwrbyte                           * Byte schreiben
 dbra d3, sdwrcmd1
 moveq #100, d1                         * Timeout
sdwrcmd2:
 bsr sdrdbyte                           * ein Byte lesen
 cmp.b #-1, d0                          * OK?
 bne.s sdwrcmdx
 dbra d1, sdwrcmd2
sdwrcmdx:
 movem.l (a7)+, d1/d3/a0/a2
 rts

sdrdbyte:                       * liest ein Byte von der SD-Card
 movem.l d3, -(a7)
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
 clr d0
 moveq #8-1, d3                         * 8 Bit
sdrdbt1:
 lsl.b #1, d0                           * Bit nach d0
 bclr.b d7, d2                          * Clock auf low
 move.b d2, spictrl.w
 btst.b d4, spictrl.w                   * Datenbit
 beq.s sdrdbt2                          * Daten low
 bset.b #0, d0
sdrdbt2:
 bset.b d7, d2                          * Clock auf high
 move.b d2, spictrl.w
 dbra d3, sdrdbt1
 move (a7)+, sr                 * Staus zurýck
 movem.l (a7)+, d3
 rts

sdwrbyte:                       * schreibt ein Byte auf die SD-Card
 movem.l d3, -(a7)
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
 moveq #8-1, d3                         * 8 Bit
sdwrbt1:
 lsl.b #1, d0                           * Bit in Carry
 bcs.s sdwrbt2                          * Bit ist high
 bclr.b d6, d2                          * Bit lüschen
 move.b d2, spictrl.w
 bra.s sdwrbt3
sdwrbt2:
 bset.b d6, d2                          * Bit setzten
 move.b d2, spictrl.w
sdwrbt3:
 bclr.b d7, d2                          * Clock auf low
 move.b d2, spictrl.w
 bset.b d7, d2                          * Clock auf high
 move.b d2, spictrl.w
 dbra d3, sdwrbt1
 bset.b d6, d2                          * Bit wieder auf high
 move.b d2, spictrl.w
 move (a7)+, sr                 * Staus zurýck
 movem.l (a7)+, d3
 rts

sdwrsec:                        * schreibt einen Sektor (512 Byte) auf die SD
                                * d0.l = Adresse, a0.l = Puffer
 movem.l d3/a2, -(a7)
 lea cmdbuff(a5), a2                    * Adresse CMD-Speicher
 move.b #$58, 0(a2)                     * Commando 24
 clr.b 1(a2)
 clr.b 2(a2)
 clr.b 3(a2)
 clr.b 4(a2)
 move.b #$ff, 5(a2)
 bsr sectocmd
 bsr sdwrcmd                            * Commando schreiben
 tst.b d0
 bne.s sdwrsece                         * Fehler
 bsr sdrdbyte                           * dummylesen fýr Clock
 move.b #$fe, d0                        * Startbyte
 bsr sdwrbyte                           * senden
 move #512-1, d3                        * 512 Bytes
sdwrsec2:
 move.b (a0)+, d0                       * Datenbyte
 bsr sdwrbyte                           * schreiben
 dbra d3, sdwrsec2
 move.b #$ff, d0                        * dummy CRC
 bsr sdwrbyte
 move.b #$ff, d0                        * dummy CRC
 bsr sdwrbyte
 move #100, d3                          * Timeout
sdwrsec6:
 bsr sdrdbyte
 and.b #$1f, d0
 cmp.b #$5, d0
 beq.s sdwrsec3
 dbra d3, sdwrsec6
 bra.s sdwrsece                         * Fehler bei Schreibvorgang
sdwrsec3:
 bsr sdrdbyte
 cmp.b #$ff, d0                         * wenn busy dann <> $ff
 beq.s sdwrsec4
 bra.s sdwrsec3
sdwrsec4:
 clr.l d0
 bra.s sdwrsecx
sdwrsece:
 moveq #-1, d0
sdwrsecx:
 bset.b d5, d2                          * SD disabled (auch im Fehlerfall!!!)
 move.b d2, spictrl.w
 movem.l (a7)+, d3/a2
 rts


sdrdblk:                        * liest einen d0 Byte Block
                                * a0 = Puffer
 movem.l d1, -(a7)
 move d0, d1                            * Byteanzahl sichern
 bsr sdwrcmd                            * Commando schreiben
 tst.b d0
 bne.s sdrdblkx
sdrdblk1:
 bsr sdrdbyte                           * Byte lesen
 cmp.b #$fe, d0                         * auf Startbyte warten
 bne.s sdrdblk1                         * ACHTUNG bei Fehler Endlosschleife!!!
 subq #1, d1                            * d1 als Zûhler
sdrdblk2:
 bsr sdrdbyte                           * Datenbyte lesen
 move.b d0, (a0)+                       * in Puffer kopieren
 dbra d1, sdrdblk2
 bsr sdrdbyte                           * Dummy CRC lesen
 bsr sdrdbyte                           * Dummy CRC lesen
 clr d0
sdrdblkx:
 bset.b d5, d2                          * SD disabled (auch im Fehlerfall!!!)
 move.b d2, spictrl.w
 movem.l (a7)+, d1
 rts


sdrdsec:                        * liest einen Sektor (512 Byte) von der SD
                                * d0.l = Adresse, a0.l = Puffer
 movem.l a2, -(a7)
 lea cmdbuff(a5), a2
 move.b #$51, 0(a2)                     * Commando Sektor lesen
 clr.b 1(a2)
 clr.b 2(a2)
 clr.b 3(a2)
 clr.b 4(a2)
 move.b #$ff, 5(a2)
 bsr sectocmd
 move #512, d0
 bsr sdrdblk
 movem.l (a7)+, a2
 rts


sd1wrcmd:                       * Commando-Bytes an SD-Card ausgeben
 movem.l d1/d3/a0/a2, -(a7)
 bclr.b d5, d2                          * CS auf high
 move.b d2, spictrl.w
* move.b #$ff, d0                        * dummy Daten
* bsr sd1wrbyte                          * erzeugt 8 Clockzyklen
.sd1wrbyte #$ff                         * erzeugt 8 Clockzyklen
 bset.b d5, d2                          * CS auf low (aktiv)
 move.b d2, spictrl.w
 moveq #6-1, d3                         * 6 Bytes
sd1wr1cmd:
* move.b (a2)+, d0                       * CMD-Byte
* bsr sd1wrbyte                          * Byte schreiben
 .sd1wrbyte (a2)+                         * Byte schreiben
 dbra d3, sd1wr1cmd
 moveq #100, d1                         * Timeout
sd1wr2cmd:
* bsr sd1rdbyte                          * ein Byte lesen
 .sd1rdbyte d0
 cmp.b #$FF, d0                         * OK?
 bne.s sd1wrxcmd                        * Ja
 dbra d1, sd1wr2cmd
sd1wrxcmd:
 movem.l (a7)+, d1/d3/a0/a2
 rts


*sd1rdbyte:                      * liest ein Byte von der SD-Card
**move sr, -(a7)                 * Status sichern
**ori #$0700, sr                 * Interrupts aus
* move.b #$ff, spidata.w                 * Dummybyte
*sd1rd1b:
* btst.b #0, spictrl.w                   * OK?
* beq.s sd1rd1b
* move.b spidata.w, d0
**move (a7)+, sr                 * Staus zurýck
* rts



*sd1wrbyte:                      * schreibt ein Byte auf die SD-Card
**move sr, -(a7)                 * Status sichern
**ori #$0700, sr                 * Interrupts aus
* move.b d0, spidata.w                   * Daten ausgeben
*sd1wr1byte:
* btst.b #0, spictrl.w                   * Bereit?
* beq.s sd1wr1byte
**move (a7)+, sr                 * Staus zurýck
* rts


sd1wrsec:                       * schreibt einen Sektor (512 Byte) auf die SD
                                * d0.l = Adresse, a0.l = Puffer
 movem.l d3/a2, -(a7)
 lea cmdbuff(a5), a2                    * Adresse CMD-Speicher
 move.b #$58, 0(a2)                     * Commando 24
 clr.b 1(a2)
 clr.b 2(a2)
 clr.b 3(a2)
 clr.b 4(a2)
 move.b #$ff, 5(a2)
 bsr sectocmd
 bsr sd1wrcmd                           * Commando schreiben
 tst.b d0
 bne.s sd1wrsce                         * Fehler
* bsr sd1rdbyte                          * dummylesen fýr Clock
 .sd1rdbyte d0
* move.b #$fe, d0                        * Startbyte
* bsr sd1wrbyte                          * senden
 .sd1wrbyte #$fe                        * senden
 move #512-1, d3                        * 512 Bytes
sd1wr2sec:
* move.b (a0)+, d0                       * Datenbyte
* bsr sd1wrbyte                          * schreiben
 .sd1wrbyte (a0)+                       * schreiben
 dbra d3, sd1wr2sec
 move.b #$ff, d0                        * dummy CRC
* bsr sd1wrbyte
.sd1wrbyte d0
* move.b #$ff, d0                        * dummy CRC
* bsr sd1wrbyte
 .sd1wrbyte d0
 move #100, d3                          * Timeout
sd1wr6sec:
* bsr sd1rdbyte
.sd1rdbyte d0
 and.b #$1f, d0
 cmp.b #$5, d0
 beq.s sd1wr3sec
 dbra d3, sd1wr6sec
 bra.s sd1wrsce                         * Fehler bei Schreibvorgang
sd1wr3sec:
* bsr sd1rdbyte
.sd1rdbyte d0
 cmp.b #$ff, d0                         * wenn busy dann <> $ff
 beq.s sd1wr4sec
 bra.s sd1wr3sec
sd1wr4sec:
 clr.l d0
 bra.s sd1wrscx
sd1wrsce:
 moveq #-1, d0
sd1wrscx:
 bclr.b d5, d2                          * SD disabled (auch im Fehlerfall!!!)
 move.b d2, spictrl.w
 movem.l (a7)+, d3/a2
 rts


sd1rdblk:                       * liest einen d0 Byte Block
                                * a0 = Puffer
 movem.l d1, -(a7)
 move d0, d1                            * Byteanzahl sichern
 bsr sd1wrcmd                           * Commando schreiben
 tst.b d0
 bne.s sd1rdxblk
sd1rd1blk:
* bsr sd1rdbyte                           * Byte lesen
.sd1rdbyte d0
 cmp.b #$fe, d0                          * auf Startbyte warten
 bne.s sd1rd1blk                         * ACHTUNG bei Fehler Endlosschleife!!!
 subq #1, d1                             * d1 als Zûhler
sd1rd2blk:
* bsr sd1rdbyte                           * Datenbyte lesen
.sd1rdbyte (a0)+
* move.b d0, (a0)+                        * in Puffer kopieren
 dbra d1, sd1rd2blk
* bsr sd1rdbyte                           * Dummy CRC lesen
* bsr sd1rdbyte                           * Dummy CRC lesen
moveq #1,d1
sd1rd3blk:
.sd1rdbyte d0
dbra d1,sd1rd3blk
 clr d0
sd1rdxblk:
 bclr.b d5, d2                           * SD disabled (auch im Fehlerfall!!!)
 move.b d2, spictrl.w
 movem.l (a7)+, d1
 rts


sd1rdsec:                       * liest einen Sektor (512 Byte) von der SD
                                * d0.l = Adresse, a0.l = Puffer
 movem.l a2, -(a7)
 lea cmdbuff(a5), a2
 move.b #$51, 0(a2)                     * Commando Sektor lesen
 clr.b 1(a2)
 clr.b 2(a2)
 clr.b 3(a2)
 clr.b 4(a2)
 move.b #$ff, 5(a2)
 bsr sectocmd
 move #512, d0
 bsr sd1rdblk
 movem.l (a7)+, a2
 rts


sectocmd:
 tst SDART(a6)
 bne.s stc01                            * SDHC
 lsl.l #1, d0
 move.b d0, 3(a2)
 lsr.l #8, d0
 move.b d0, 2(a2)
 lsr.l #8, d0
 move.b d0, 1(a2)
 bra.s stc02
stc01:
 move.b d0, 4(a2)
 lsr.l #8, d0
 move.b d0, 3(a2)
 lsr.l #8, d0
 move.b d0, 2(a2)
 lsr.l #8, d0
 move.b d0, 1(a2)
stc02:
 rts 


SDSIZE          equ     0
SDBPBLK         equ     4
SDART           equ     6
SDNAME          equ     8

SPI0_DI         equ     0               * Eingang (74LS245): DAT/DO der SD
SPI0_CS         equ     4               * Ausgang (74LS374): CS der SD
SPI0_DO         equ     0               * Ausgang (74LS374): CMD/DI der SD
SPI0_CLK        equ     3               * Ausgang (74LS374): CLK/SCLK der SD

SPI1_DI         equ     2               * Eingang (74LS245): DAT/DO der SD
SPI1_CS         equ     6               * Ausgang (74LS374): CS der SD
SPI1_DO         equ     2               * Ausgang (74LS374): CMD/DI der SD
SPI1_CLK        equ     1               * Ausgang (74LS374): CLK/SCLK der SD

SPIH0_CS        equ     5               * CS der ersten Hardware SD
SPIH1_CS        equ     6               * CS der zweiten Hardware SD

spicmd0:        dc.b $40, 0, 0, 0, 0, $95       * Reset
spicmd1:        dc.b $41, 0, 0, 0, 0, $ff       * Initialisierung
spicmd9:        dc.b $49, 0, 0, 0, 0, $ff       * CSD Auslesen
spicmd10:       dc.b $4a, 0, 0, 0, 0, $ff       * CID Auslesen

mmctxt:         dc.b 'MMC-Card ', 0
sdtxt:          dc.b 'SD-Card ', 0
sdhctxt:        dc.b 'SDHC-Card ', 0

ds 0
