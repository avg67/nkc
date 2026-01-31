setadr equ $60000               * Zieladresse des Programms
                                * Anpassung muß an eigenes Ram erfolgen

*******************************************************************************
*                      68000/68010 Grundprogramm varequ                       *
*                         (C) 1991 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                           Variablen und EQUs                                *
*******************************************************************************

ram equ $10000                  * Relativer Abstand Variable-Basis

rsreset                         * Counter vorsichtshalber auf Null setzen

vekdest:   DS.b 0               * INIT-Start für Transport

intlv2:    DS.b 6               * Auto-Interrupt LV2 (nmi)
intlv5:    DS.b 6               * Auto-Interrupt LV5 (int)
intlv7:    DS.b 6               * Auto-Interrupt LV7 (nmi+int)
trap0:     DS.b 6               * Trap0-Vektor

userci:    DS.b 6               * Vektor USER-CI
                                * d0 = 0 Zugriff ci2
                                * d0 = 1 Erster Zugriff auf ci2 nach ciinit2
                                * d0 = 2 Zugriff von ci
usercsts:  DS.b 6               * Vektor USER-CSTS
                                * d0 = 2 Zugriff von csts
userco:    DS.b 6               * Vektor USER-CO

iostat:    DS.b 1               * Flag für Ausgabe bei CO2 (Umschalter)
                                * 1 = Ausgabe auf CRT mit ERRFLAG-Abfrage
                                * 2 = Ausgabe auf CRT
                                * 3 = Auf Drucker
                                * 4 = Auf Drucker ohne LF
                                * 5 = USER-CO
                                * 6 = Ausgabe über serielle Schnitstelle
iostatb:   DS.b 1               * CI und CI2 Umschalter
                                * 5 = Umschaltung auf USERCI
iodir:     DS.b 1               * Für CTRL-A Umschaltung bei co2

akteprom:  DS.b 1               * Aktuelles Eprom für schnelle Wahl

flip:      DS.b 1               * Für Seitenumschaltung bei AUTOFLIP
flipcnt:   DS.b 1               * Flip ist für Zwei-Seiten-Umschaltung
flip1:     DS.b 1               * Flip1 für Vier-Seitenbetrieb
flip1cnt:  DS.b 1               * Null, dann Flip aus

passflag:  DS.w 1               * Aktueller PASS beim Assembler
                                * (1=erster Durchgang / 2=zweiter Durchgang)
errflag:   DS.w 1               * Fehlerflag (0 = Kein Fehler beim Assembler)

stxtxt:    DS.l 1               * Zeiger auf Textanfang
akttxt:    DS.l 1               * Zeiger auf Startzeile des Bildschirms
etxtxt:    DS.l 1               * Zeiger auf Textende
errzeile:  DS.l 1               * Zeiger auf erste fehlerhafte Zeile beim
                                * Assemblerdurchlauf

turx:      DS.w 1               * X-Position Turtle * 16
tury:      DS.w 1               * Y-Position Turtle * 32
turphi:    DS.w 1               * Winkel der Turtle
tur1x:     DS.w 1               * Merker der alten X-Position
tur1y:     DS.w 1               * Merker der alten Y-Position
tur1phi:   DS.w 1               * Merker des alten Winkels

pcstand:   DS.l 1               * Programmzählerstand beim Assembler
anfstand:  DS.l 1               * PC am Anfang einer Zeile
auspoi:    DS.l 1               * Pointer Ausgabe
einpoi:    DS.l 1               * Eingabepointer
auszahl:   DS.w 1               * Anzahl ausgegebener Bytes beim Assembler

stackmerk: DS.l 1               * Stack-Merker bei Trace

nametab:   DS.b 8               * Name für Symboltabelle
ausbuf:    DS.b 132             * Ausgabebuffer (überall nur lokal verwenden !)
einbuf:    DS.b 132             * Eingabebuffer (auch nur lokal verwenden !)

regsave:   DS.b 4*16            * d0-d7/a0-a7 bei Einzelschritt
tracflag:  DS.b 1               * Modi bei Einzelschrittbearbeitung
                                * Bit 0 = Regdump an/aus
                                * Bit 1 = Protokol an/aus
                                * Bit 2 = TRAP/JSR Direktausführung
                                * Bit 3 = (Nur 68020)
                                * Bit 4 = Trace aus/an
                                * Bit 6,7 = (Nur 68020)
gdpsave:   DS.b 15              * gdp1-gdp15
srsave:    DS.w 1               * Statusregister
pcsave:    DS.l 1               * PC nächster Befehl
uspsave:   DS.l 1               * User-Stack-Pointer
sspsave:   DS.l 1               * Supervisor-Stack-Pointer

tracmerk:  DS.b 6               * Merker für Werte bei Einzelschritt
trac1aus:  DS.b 1               * Auswahlmerker für Wiederholen
tracausw:  DS.b 1               * Auswahl bei trace
                                * 0 = Nichts
                                * 1 = Bis
                                * 2 = N-Mal
                                * 3 = Weiter bis ADRESSE mit MASKE WERT enthält
                                * 4 = Weiter bis zum nächsten RTS/RTE/RTR

modber:    DS.b 8               * Hilfsablage für Direktausführung eines Befehls

trac1mer:  DS.l 1               * Wert-Zwischenspeicher für Wiederholen
           DS.l 1               * FREI !!!

offset:    DS.l 1               * Für verschobene Programme
pcorg:     DS.l 1               * Default PC-Start, wenn kein ORG da
uhradr:    DS.w 1               * Wenn vorhanden, Smart-Watch Adresse/8 Kbyte
attcode:   DS.w 1               * Attribute für Befehlssatz
wordbyte:  DS.w 1               * Längenmerker für Assembler

errcnt:    DS.w 1               * Anzahl der Fehler
errart:    DS.w 1               * Fehlerart
errpoi:    DS.l 1               * Zeiger auf Fehlerquelle

debugst:   DS.l 1               * Start Debugger Info
debugak:   DS.l 1               * Nächste freie Zelle

oldx:      DS.w 1               * Alte X-Position bei FIGUR-Befehl
oldy:      DS.w 1               * Alte Y-Position
oldadr:    DS.l 1               * Adresse der Figur
oldsize:   DS.w 1               * Größe der Figur (Dx und Dy)

uhrausw:   DS.b 1               * Uhrauswahl
                                * Wenn keine Smart-Watch vorhanden und keine
                                * Uhrenbaugruppe gewählt :
                                * 0 = Es wird die Uhrenbaugruppe angesprochen,
                                * obwohl sie nicht vorhanden ist=>Kompatibilität
                                * 1 = E050-16 Uhrenbaugruppe vorhanden
                                * 2 = DS1216 (Smart-Watch) im Ram
                                * 3 = RTC

viewpage:  DS.b 1               * Aktuelle Leseseite 0..3
wrtpage:   DS.b 1               * Aktuelle Schreibseite 0..3

synstate:  DS.b 1               * Für Sync-Aufruf

menflag:   DS.b 1               * Menüumschaltung
                                * Bit 0 = frei
                                * Bit 1 = frei
                                * Bit 2 = Grundprogramm als Aufruf (nein,ja)
                                * Bit 6 = Hardcopy immer erlaubt (nein,ja)
                                * Bit 7 = Grundprogramm an (ja/nein)

groesse:   DS.b 1               * Größe bei CO-Ausgabe
           DS.b 1               * FREI !!!

first:     DS.b 1               * Für Turtle-Grafik (1 = first)
turdo:     DS.b 1               * Turtle down (0 = up)

zeilen:    DS.b 1               * Zeilenzähler
debug:     DS.b 1               * Debug-Flag (1 = dann gültige Info)

insl:      DS.b 1               * Einfügemode / Blockmerker beim Editor
                                * Bit 0 = Einfügemode (0 = aus)
                                * Bit 1 = Blockanfang markiert
                                * Bit 2 = Blockende markiert
                                * Bit 3 = Scroll-Art (Seitenweise/Zeilenweise)
                                * Bit 4 = Auf Zeilenanfang / Textanfang

curon:     DS.b 1               * 1 = CRT-Cursor aktiv
curx:      DS.b 1               * Cursor-Position 0..79
cury:      DS.b 1               * 0..23
escmerker: DS.b 1               * Escape Flag

lrand:     DS.b 1               * Linker Rand im Editor

cotempo:   DS.b 1               * Scrollgeschwindigkeit bei neuer GDP
                                * 0 = Software-Scroll
                                * 1-5 = Hardware-Scroll

optflag:   DS.b 1               * Zeichensatzmerker
                                * 0 = amerikanisch
                                * 1 = deutsch (default)
                                * 2 = User definiert

linecnt:   DS.b 24              * Zeichen-Zähler pro Zeile
lineptr:   DS.b 24              * Pointer auf reale Zeile
screen:    DS.b 80*24           * Bildschirmbuffer

           DS.b 41              * Freibereich für ersten Stack

stack:     DS.b 2               * Stack beim Reset bevor Rambereich ermittelt

trap2:     DS.b 6               * Vektoren für USER-Traps
trap3:     DS.b 6
trap6:     DS.b 6
trap7:     DS.b 6
trap8:     DS.b 6
trap9:     DS.b 6
trap10:    DS.b 6
trap11:    DS.b 6
trap12:    DS.b 6
trap13:    DS.b 6
trap14:    DS.b 6
trap15:    DS.b 6
trap1:     DS.b 6               * Grundprogrammtrap ins Ram geführt

linea:     DS.b 6               * linea,linef eingeführt, dadurch
linef:     DS.b 6               * Softareschnittstelle für FPU/PMMU
                                * realisierbar

intlv1:    DS.b 6               * Interrupt-Ebenen 1, 3, 4, 6
intlv3:    DS.b 6
intlv4:    DS.b 6
intlv6:    DS.b 6

                                * ACHTUNG !!!
                                * Ab hier Speicheraufbau verändert
steprate:  DS.b 1               * Steprate bei Floppy ( 0-7 )
flosr:     DS.b 1               * Statusregister FLO beim letzten Zugriff


drvat:     DS.b 1               * Merker für altes Laufwerk
drvtab:    DS.b 16              * Spurtabelle Laufwerke

ioflag:    DS.b 1               * Flag für verschiedene Baugruppen im IO-Bereich
                                * Bit 0 : 0 = GDP / 1 = GDPHS
                                * Bit 1 : 0 = Normale Key / 1 = Key3
                                * Bit 2 : 0 = Keine Ser / 1 = Ser vorhanden
                                * Bit 3 : 0 = Keine Ser2 / 1 = Ser2 vorhanden

rnd1var:   DS.w 1               * RANDOM Indizes
rnd2var:   DS.w 1               * Zufällig belegt für
rnd3var:   DS.w 1               * Knudt-Algorithmus

pagecnt:   DS.w 1               * Seitenzähler beim Assembler
hdtab:     DS.b 10              * Tabelle für HARDDISK

fgcolor:   DS.b 1               * Vordergrundfarbe für erweiterte GDP
xormode:   DS.b 1               * 0..15 XOR-Flag für neu GDP (Nur Bit 0 genutzt)
ci2flag:   DS.b 1               * 1 = Erster Zugriff bei USER-CI

coscroll:  DS.b 1               * Scrollwert der GDP Baugruppe bei Scroll
                                * mit der CO-Routine
                                * In Zweier-Schritten von Null bis 254

                                * Druckmodi für Druckersteuerung
dflag0:    DS.b 1               * Bit 0+1  Zeichensatzwahl
                                * (0=Amerikanisch/1=Deutsch/2=NDR)
                                * Bit 2    Zeichensatz des Druckers
                                * Bit 3    Papiererkennung
                                * Bit 4    Kursivdruck
                                * Bit 5    Proportionaldruck
                                * Bit 6    Doppeldruck
                                * Bit 7    Fettdruck
dflag1:    DS.b 1               * Bit 0+1  Druckart (Normal/Breit/Schmal)
                                * Bit 2    Schriftart
                                * Bit 3    Druckrichtung
                                * Bit 4    Druckgeschwindigkeit
                                * Bit 5-7  Anzahl Kopien

dflag2:    DS.b 1               * Seitenlänge
dflag3:    DS.b 1               * Linker Rand

drbeftab:  DS.b 3*22            * Tabelle der Druckerbefehle
                                * 22 Befehle mit maximal 3 Bytes Länge

serflag:   DS.b 1               * Bit 0 = ci/csts auf serielle Karte gelenkt
                                * Bit 1 = lo/lsts auf serielle Karte gelenkt
                                * Bit 2 = Floppy auf serielle Karte gelenkt
                                *       (Nur Sektor lesen und Sektor schreiben)

* grafflag:  DS.b 1               * Grafik Flag für Grafik-Paket
                                * 0 = GDP
                                * 1 = COL256 (512*256 Punkte 16 Farben)

gdpscroll: DS.b 1               * Scrollwert GDP-Karte
gdpxor:    DS.b 1               * Verknüpfungsmode GDP (0/1)
gdpvpage:  DS.b 1               * Leseseite GDP (0-3)
gdpwpage:  DS.b 1               * Schreibseite GDP (0-3)
gdpcolor:  DS.b 1               * Schreibfarbe GDP (0/1)
gdpcol:    DS.b 1               * 0= S/W-GDP, 1= Farb-GDP

* colxor:    DS.b 1               * Verknüpfungsmode bei der COL-Karte (0/1)
* colvpage:  DS.b 1               * Leseseite COL (0-3)
* colwpage:  DS.b 1               * Schreibseite COL (0-3)
* colcolor:  DS.b 1               * Schreibfarbe COL (0-15)
* colcol1:   DS.b 1               * Schreibfarbe COL Teil 1
* colcol2:   DS.b 1               * Schreibfarbe COL Teil 2

keydil:    DS.b 1               * Kopie der DIL-Schalter auf der KEY-Karte

bootflag:  DS.l 1               * Kennung, ob Boot erfolgte

poweron:   DS.l 1               * Poweron-Erkennung bei Reset

symnext:   DS.w 1               * Zeiger auf nächsten Eintrag bei Symtab
                                * 16 Bit vorzeichenlos

macrotab:  DS.l 1               * Enthält die Adresse der Tabelle der Macros
macroanf:  DS.l 1               * Hilfspeicher und Macrozieladresse

anfzeile:  DS.l 1               * Anfangsadresse der gerade übersetzten Zeile
                                * im Assembler
rscount:   DS.l 1               * RS-Zähler für den Assembler

           DS.l 3*5             * Nur bei 68020
           DS.l 1               * Nur bei 68020

mausadr0:  DS.b 6               * Eingabegerät initialisieren
mausadr1:  DS.b 6               * Eingabegerät abfragen

drsave:    DS.b 20              * Eigene Druckerbefehle beim Druckmenü

edittabs:  DS.b 80              * Feld für Tabs bei Edit
                                * Bit 7 gesetzt = Tab vorhanden

editmacro: DS.b 41*10           * Platz für 10 Macros

aktser:    DS.b 1               * Aktueller SER Kanal
                                * 0=keine SER, 1=SER
                                * 2=SER2 Kanal A, 3=SER2 Kanal B

scsi2ide:  DS.b 1               * SCSI Kommandos auf IDE umleiten
                                * 0=keine Umleitung,
                                * 1=Umleitung auf IDE aktiv
                                * 2=Umleitung auf SD-Card aktiv

idemgeo:   DS.b 32              * IDE Master Geometrie
idesgeo:   DS.b 32              * IDE Slave Geometrie

idebuff:   DS.b 512             * IDE Buffer

srdcap:    DS.w 1               * SRAMDISK Kapazität

flo2srd:   DS.b 1               * Floppy4 nach SRAMDISK umleiten

bootdel:   DS.b 1               * Wartezeit bis Laufwerk zum booten bereit

nvrbuff:   DS.b 32              * Kopie des NVRAMs

cmdbuff:   DS.b 6               * SD-Card Kommado-Puffer

sd1geo:    DS.b 24              * SD-Card 1 Geometrie
sd2geo:    DS.b 24              * SD-Card 2 Geometrie

fontname:  DS.b 4               * Name der User-Schriftart

bgcolor:   DS.b 1               * Hintergrundfarbe für GDP

transmod:  DS.b 1               * Transparent-Modus der GDP-FPGA


* dummy:     DS.b 1               * Wird benötigt um auf Word-Grenze zu kommen

                                * Folgende Variable ist frei nach hinten
                                * verschiebbar. Deshalb ist hier Platz für neue
                                * Variablen.
symtab:    DS.W 0               * Symboltabellenbereich bis 64 Kbyte

****************************** Ende der Variablen ******************************

cpu       equ 2                 * 68000/68010 Grundprogramm

page      equ $ffffff60*cpu     * Seitenport GDP
page1     equ $ffffff61*cpu     * Extraport für Scroll

gdp       equ $ffffff70*cpu     * GDP-Prozessor Basisadresse
colport   equ $ffffffa0*cpu     * 1. Farbport GDP (Vordergrund)
colport1  equ $ffffffa1*cpu     * 2. Farbport GDP (Hintergrund)

keyd      equ $ffffff68*cpu     * Daten Tastatur + Strobe
keys      equ $ffffff69*cpu     * Schalter + Rücksetzen
                                * Bit 0 = Reserve
                                * Bit 1 = 1 => Autoboot
                                * Bit 2 = 1 => Uhrenbaugruppe vorhanden
                                * Bit 3 = 1 => GDPHS
                                * Bit 4 = 1 => SCSI-Disk
                                * Bit 5 = 1 => IDE-Disk
                                * Bit 6 = 1 => GDP-FPGA

bankboot  equ $ffffffc8*cpu     * Bank-Boot-Karte

promd     equ $ffffff80*cpu     * Adressen für Eprom-Programmierer
proma1    equ $ffffff81*cpu     * Promer und Promer2
proma2    equ $ffffff82*cpu
proma3    equ $ffffff83*cpu
proma4    equ $ffffff84*cpu
proma5    equ $ffffff85*cpu
proma6    equ $ffffff86*cpu
proma7    equ $ffffff87*cpu

cmdcas    equ $ffffffca*cpu     * Cassettenrecorder Port
datcas    equ $ffffffcb*cpu

centdaten equ $ffffff48*cpu     * Datenport Drucker
centin    equ $ffffff49*cpu     * Busy-Status Bit 0
centstb   equ $ffffff49*cpu     * Strobe Ausgang Bit 0

flo0      equ $ffffffc0*cpu     * Floppy-Controller Kommandoregister
flo1      equ $ffffffc1*cpu     * Trackregister
flo2      equ $ffffffc2*cpu     * Sektorregister
flo3      equ $ffffffc3*cpu     * Datenregister
flo4      equ $ffffffc4*cpu     * Status und Steuerung

hddata    equ $ffffff24*cpu     * Harddisk Daten-Register
hdstat    equ $ffffff25*cpu     * Harddisk Status-Register
hdsel     equ $ffffff26*cpu     * Harddisk Selcect-Port
hdcode    equ $ffffff26*cpu     * Harddisk Port für Adresse-Codierung

srddata   equ $ffffff2c*cpu     * SRAMDISK Daten Register
srdsecl   equ $ffffff2d*cpu     * SRAMDISK Sektor Register Low Byte
srdsech   equ $ffffff2e*cpu     * SRAMDISK Sektor Register High Byte

idedor    equ $ffffff16*cpu     * GIDE Digitales Ausgabe-Register
idedat    equ $ffffff18*cpu     * GIDE Daten-Register
ideerr    equ $ffffff19*cpu     * GIDE Error-Register
idescnt   equ $ffffff1a*cpu     * GIDE Sektor-Zaehler
idesnum   equ $ffffff1b*cpu     * GIDE Sektor-Nummer
ideclo    equ $ffffff1c*cpu     * GIDE Zylinder Low-Byte
idechi    equ $ffffff1d*cpu     * GIDE Zylinder High-Byte
idesdh    equ $ffffff1e*cpu     * GIDE Sektor Groesse, Laufwerk, Kopf
idecmd    equ $ffffff1f*cpu     * GIDE Status(lesen) und Komandos(schreiben)

spictrl   equ $ffffff00*cpu     * SPI-Control / SPI per IOE
spidata   equ $ffffff01*cpu     * SPI Daten

ser0      equ $fffffff0*cpu     * Serielles Interface (SER)
ser1      equ $fffffff1*cpu
ser2      equ $fffffff2*cpu
ser3      equ $fffffff3*cpu

ser20     equ $ffffff90*cpu     * Mode Reg Channel A (SER2)
ser21     equ $ffffff91*cpu     * Status / Clock Select-Reg Channel A
ser22     equ $ffffff92*cpu     * Masked Interrupt Status / Cmd Reg Channel A
ser23     equ $ffffff93*cpu     * Rx Holding / Tx Holding Reg Channel A
ser24     equ $ffffff94*cpu     * Input Port Change / Auxilary Control Reg
ser25     equ $ffffff95*cpu     * Interrupt Status / Interrupt Mask Reg
ser26     equ $ffffff96*cpu     * Counter/Timer Upper Byte Reg
ser27     equ $ffffff97*cpu     * Counter/Timer Lower Byte Reg
ser28     equ $ffffff98*cpu     * Mode Reg Channel B
ser29     equ $ffffff99*cpu     * Status / Clock Select Reg Channel B
ser2a     equ $ffffff9a*cpu     * Reserved / Command Reg Channel B
ser2b     equ $ffffff9b*cpu     * Rx Holding / Tx Holding Reg Channel B
ser2c     equ $ffffff9c*cpu     * Interrupt Vector Reg
ser2d     equ $ffffff9d*cpu     * Input Port / Output Port Configuration Reg
ser2e     equ $ffffff9e*cpu     * Set Output Port Bits
ser2f     equ $ffffff9f*cpu     * Clear Output Port Bits

adc0816   equ $ffffffe0*cpu     * Analog-Digital-Wandler 16 Kanäle
adc1001   equ $fffffffc*cpu     * Analog-Digital-Wandler 1 Kanal
da0802    equ $fffffff8*cpu     * Digital-Analog-Wandler 2 Kanäle

ad12      equ $ffffffd0*cpu     * 12 Bit Analog-Digital-Wandler
da12      equ $ffffffd4*cpu     * 12 Bit Digital-Analog-Wandler

uhr       equ $fffffffe*cpu     * Uhrenkarte

rtcreg    equ $fffffffa*cpu     * RTC Adressregister
rtcdat    equ $fffffffb*cpu     * RTC Daten

spra0     equ $ffffffd8*cpu     * Sprachausgabe
spra1     equ $ffffffd9*cpu
spra2     equ $ffffffda*cpu
spra3     equ $ffffffdb*cpu
spra4     equ $ffffffdc*cpu

snd0      equ $ffffff50*cpu     * Sound-Baugruppe
snd1      equ $ffffff51*cpu

mtast     equ $ffffff8b*cpu     * Hardcopy-Maus-Baugruppe
mauf      equ $ffffff8c*cpu     * Mauspo rts
mab       equ $ffffff8d*cpu
mrechts   equ $ffffff8e*cpu
mlinks    equ $ffffff8f*cpu

kreuzlx   equ $ffffff89*cpu     * Po rts des Fadenkreuzes
kreuzhx   equ $ffffff88*cpu
kreuzly   equ $ffffff8b*cpu
kreuzhy   equ $ffffff8a*cpu

hardcad8  equ $ffffff89*cpu     * 8-Bit Port

hardclat  equ $ffffff8d*cpu     * Zähler übernehmen
hardcclr  equ $ffffff8e*cpu     * Zähler löschen

* colcrt     equ $ffffffac*cpu    * Register-Auswahl
* colcrtd    equ $ffffffad*cpu    * Register-Ansprech-Adresse
* colpage    equ $ffffffae*cpu    * Seiteneinstellung und Ein-Ausblenden der Kar

cluta      equ $ffffffa4*cpu    * FPGA-CLUT Adresse
cluth      equ $ffffffa5*cpu    * FPGA-CLUT Daten high
clutl      equ $ffffffa6*cpu    * FPGA-CLUT Daten low


******************************** Ende EQU-Anweisungen **************************

*******************************************************************************
*                         680xx Grundprogramm basbef                          *
*                         (C) 1991 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                          Basisstart und Befehle                             *
*******************************************************************************


 ORG 0                           * Auf Adresse Null übersetzen
 ;OFFSET setadr                   * Ablage wie voreingestellt

basis:
 DC.l stack+ram                 * Dummy Stack
 DC.l $1d0000+start                     * Startadresse bei Reset
 DC.l buserr                    * Busfehler
 DC.l adrerr                    * Adressfehler
 DC.l illins                    * Falscher Befehl
 DC.l zerdiv                    * Divison durch Null
 DC.l chkins                    * CHK-Befehl
 DC.l trapvins                  * Trapv-Befehl
 DC.l priv                      * Priviligierter Befehl
 DC.l tracein                   * Sprungadresse bei Trace
 DC.l linea+ram                 * Jetzt auch ins Ram gelenkt (Adresse für 08/00)
 DC.l linef+ram                 * Für Softwareschnittstelle mit FPU / PMMU
 DC.l $ffffffff                 * Reserviert
 DC.l $ffffffff                 * Coprozessor Protokol Verletzung (68020)
 DC.l format                    * Falsches Stackformat (Ab 68010)
 DC.l intlvx                    * Nicht initialisierter Interrupt
 DCB.l 8,$ffffffff               * Reserviert
 DC.l intlvx                    * Falscher Interrupt
 DC.l intlv1+ram                * Ebene 1
 DC.l intlv2+ram                * Ebene 2
 DC.l intlv3+ram                * Ebene 3
 DC.l intlv4+ram                * Ebene 4
 DC.l intlv5+ram                * Ebene 5
 DC.l intlv6+ram                * Ebene 6
 DC.l intlv7+ram                * Ebene 7
 DC.l trap0+ram                 * Alle Traps ins Ram geführt
 DC.l trap1+ram
 DC.l trap2+ram
 DC.l trap3+ram
 DC.l trap1+ram                 * Grundprogrammtrap unter CP/M
 DC.l trap1+ram                 * Reserve
 DC.l trap6+ram
 DC.l trap7+ram
 DC.l trap8+ram
 DC.l trap9+ram
 DC.l trap10+ram
 DC.l trap11+ram
 DC.l trap12+ram
 DC.l trap13+ram
 DC.l trap14+ram
 DC.l trap15+ram
 DC.l $ffffffff                 * FPU Sprung oder Setzen einer ungeordneten
                                * Bedingung (68020)
 DC.l $ffffffff                 * FPU Falsches Ergebnis (68020)
 DC.l $ffffffff                 * FPU Division durch Null (68020)
 DC.l $ffffffff                 * FPU Unterlauf (68020)
 DC.l $ffffffff                 * FPU Operanden Fehler (68020)
 DC.l $ffffffff                 * FPU Überlauf (68020)
 DC.l $ffffffff                 * FPU Not a Number (68020)
 DC.l $ffffffff                 * Reserviert
 DC.l $ffffffff                 * PMMU Konfiguration (68020)
 DC.l $ffffffff                 * PMMU Falscher Befehl (68020)
 DC.l $ffffffff                 * PMMU Zugriffs Level Verletzung (68020)
 DCB.l 5,$ffffffff               * Reserviert

* Tabelle der Unterprogramme

traptab:
 DC.l tschreite                 * Befehl 1
 DC.l tdrehe                    * Befehl 2
 DC.l thoch                     * Befehl 3
 DC.l trunter                   * Befehl 4
 DC.l figurxy                   * Befehl 5
 DC.l textprint                 * Befehl 6
 DC.l tmove                     * Befehl 7
 DC.l moveto                    * Befehl 8
 DC.l drawto                    * Befehl 9
 DC.l textaus                   * Befehl 10
 DC.l textein                   * Befehl 11
 DC.l ci                        * Befehl 12
 DC.l csts                      * Befehl 13
 DC.l ri                        * Befehl 14
 DC.l poo                       * Befehl 15
 DC.l clrall                    * Befehl 16
 DC.l clrinvis                  * Befehl 17
 DC.l wait                      * Befehl 18
 DC.l tschr16tel                * Befehl 19
 DC.l clrscreen                 * Befehl 20
 DC.l co                        * Befehl 21
 DC.l lo2                       * Befehl 22
 DC.l sin                       * Befehl 23
 DC.l cos                       * Befehl 24
 DC.l setgroe                   * Befehl 25
 DC.l cmd                       * Befehl 26
 DC.l newpage                   * Befehl 27
 DC.l sync                      * Befehl 28
 DC.l wert                      * Befehl 29
 DC.l zuweis                    * Befehl 30
 DC.l ciinit2                   * Befehl 31
 DC.l ci2                       * Befehl 32
 DC.l co2                       * Befehl 33
 DC.l setflip                   * Befehl 34
 DC.l delay                     * Befehl 35
 DC.l firsttime                 * Befehl 36
 DC.l setpen                    * Befehl 37
 DC.l erapen                    * Befehl 38
 DC.l grapoff                   * Befehl 39
 DC.l print                     * Befehl 40
 DC.l print2x                   * Befehl 41
 DC.l print4x                   * Befehl 42
 DC.l print6x                   * Befehl 43
 DC.l print8x                   * Befehl 44
 DC.l print8b                   * Befehl 45
 DC.l print4d                   * Befehl 46
 DC.l hide                      * Befehl 47
 DC.l show                      * Befehl 48
 DC.l crtex                     * Befehl 49
 DC.l lstex                     * Befehl 50
 DC.l usrex                     * Befehl 51
 DC.l nilex                     * Befehl 52
 DC.l seterr                    * Befehl 53
 DC.l geterr                    * Befehl 54
 DC.l setpass                   * Befehl 55
 DC.l edit                      * Befehl 56
 DC.l figur                     * Befehl 57
 DC.l setfig                    * Befehl 58
 DC.l getram                    * Befehl 59
 DC.l autoflip                  * Befehl 60
 DC.l cursorein                 * Befehl 61
 DC.l cursoraus                 * Befehl 62
 DC.l charhandler               * Befehl 63
 DC.l progzge                   * Befehl 64
 DC.l assemble                  * Befehl 65
 DC.l getstx                    * Befehl 66
 DC.l putstx                    * Befehl 67
 DC.l getorg                    * Befehl 68
 DC.l putorg                    * Befehl 69
 DC.l print8d                   * Befehl 70
 DC.l printv8d                  * Befehl 71
 DC.l muls32                    * Befehl 72
 DC.l divs32                    * Befehl 73
 DC.l flinit                    * Befehl 74
 DC.l floppy                    * Befehl 75
 DC.l getflop                   * Befehl 76
 DC.l setxor                    * Befehl 77
 DC.l getxor                    * Befehl 78
 DC.l setcolor                  * Befehl 79
 DC.l getcolor                  * Befehl 80
 DC.l curonein                  * Befehl 81
 DC.l curonaus                  * Befehl 82
 DC.l adj360                    * Befehl 83
 DC.l symbolaus                 * Befehl 84
 DC.l symloesche                * Befehl 85
 DC.l getsymtab                 * Befehl 86
 DC.l getnext                   * Befehl 87
 DC.l putnext                   * Befehl 88
 DC.l getbasis                  * Befehl 89
 DC.l getvar                    * Befehl 90
 DC.l seta5                     * Befehl 91
 DC.l aufxy                     * Befehl 92
 DC.l korxy                     * Befehl 93
 DC.l aufk                      * Befehl 94
 DC.l getk                      * Befehl 95
 DC.l rnd                       * Befehl 96
 DC.l getvers                   * Befehl 97
 DC.l getsn                     * Befehl 98
 DC.l crlfe                     * Befehl 99
 DC.l getline                   * Befehl 100
 DC.l getcurxy                  * Befehl 101
 DC.l setcurxy                  * Befehl 102
 DC.l getxy                     * Befehl 103
 DC.l si                        * Befehl 104
 DC.l so                        * Befehl 105
 DC.l sists                     * Befehl 106
 DC.l sosts                     * Befehl 107
 DC.l siinit                    * Befehl 108
 DC.l getad8                    * Befehl 109
 DC.l getad10                   * Befehl 110
 DC.l setda                     * Befehl 111
 DC.l speak                     * Befehl 112
 DC.l speak1                    * Befehl 113
 DC.l sound                     * Befehl 114
 DC.l getuhr                    * Befehl 115
 DC.l setuhr                    * Befehl 116
 DC.l lsts                      * Befehl 117
 DC.l relaisan                  * Befehl 118
 DC.l relaisaus                 * Befehl 119
 DC.l asserr                    * Befehl 120
 DC.l tnotimp                   * Befehl 121    Nur beim 68020
 DC.l tnotimp                   * Befehl 122    Nur beim 68020
 DC.l readaus                   * Befehl 123
 DC.l grund                     * Befehl 124
 DC.l hardcopy                  * Befehl 125
 DC.l grafik                    * Befehl 126
 DC.l gdpvers                   * Befehl 127
 DC.l seraus                    * Befehl 128
 DC.l serex                     * Befehl 129
 DC.l clutinit                  * Befehl 130
 DC.l clut                      * Befehl 131
 DC.l relais                    * Befehl 132
 DC.l relaisin                  * Befehl 133
 DC.l setda12                   * Befehl 134
 DC.l getad12                   * Befehl 135
 DC.l suchbibo                  * Befehl 136
 DC.l trapdisass                * Befehl 137
 DC.l si2                       * Befehl 138
 DC.l system                    * Befehl 139
 DC.l uhrprint                  * Befehl 140
 DC.l harddisk                  * Befehl 141
 DC.l hardtest                  * Befehl 142
 DC.l tnotimp                   * Befehl 143    Reserviert
 DC.l tnotimp                   * Befehl 144    Reserviert
 DC.l tnotimp                   * Befehl 145    Nur bei 68020
 DC.l tnotimp                   * Befehl 146    Nur bei 68020
 DC.l tnotimp                   * Befehl 147    Nur bei 68020
 DC.l tnotimp                   * Befehl 148    Nur bei 68020
 DC.l tnotimp                   * Befehl 149    Nur bei 68020
 DC.l setser                    * Befehl 150
 DC.l getser                    * Befehl 151
 DC.l sets2i                    * Befehl 152
 DC.l gets2i                    * Befehl 153
 DC.l idetest                   * Befehl 154
 DC.l idedisk                   * Befehl 155
 DC.l srdisk                    * Befehl 156
 DC.l setf2s                    * Befehl 157
 DC.l getf2s                    * Befehl 158
 DC.l getsrd                    * Befehl 159
 DC.l setsys                    * Befehl 160
 DC.l getsys                    * Befehl 161
 DC.l patch                     * Befehl 162
 DC.l sdtest                    * Befehl 163
 DC.l sddisk                    * Befehl 164
 DC.l setchar                   * Befehl 165
 DC.l settrans                  * Befehl 166
 DC.l gettrans                  * Befehl 167



trapende:

maxtraps EQU (trapende-traptab)/4       * Anzahl der Befehle

 DCB.l 192-maxtraps,tnotimp      * Auffüllen, dadurch weiter mit Adresse $400


 DC.l $5aa58001                 * Suchstring für Anfang

ramstart:
 DC.l ram                       * Ramanfang (Basis muß addiert werden)
 DC.l start                     * Pointer auf Startadresse
versnum:
 DC.l $00000710                 * Version 7.10
snnum:
 DC.l $00000005                 * Revisionsnummer (vormals Seriennummer)
cpuwert:
 DC.l cpu                       * CPU  (1,2,4 für 68008, 68000 und 68020)
 DC.l (ende-basis)/2            * Länge des Grundprogramms in Worten für Check
 DC.l 0                         * Checksumme (Wortweise gebildet)
                                * Alle Worte bis auf die 2 Worte der Prüfsumme

 bra trap_rts                    * Start-Trap mit RTS-Abschluß
 bra start                      * Kalt-Start
 bra exinit                     * Externes Init
 bra warmstart                  * Sprung in Menü

trapsym:                        * Symbole für Trap-Tabelle
 DC.b 'SCHREITE'                * 1
 DC.b 'DREHE   '                * 2
 DC.b 'HEBE    '                * 3
 DC.b 'SENKE   '                * 4
 DC.b 'FIGURXY '                * 5
 DC.b 'WRITELF '                * 6
 DC.b 'SET     '                * 7
 DC.b 'MOVETO  '                * 8
 DC.b 'DRAWTO  '                * 9
 DC.b 'WRITE   '                * 10
 DC.b 'READ    '                * 11
 DC.b 'CI      '                * 12
 DC.b 'CSTS    '                * 13
 DC.b 'RI      '                * 14
 DC.b 'PO      '                * 15
 DC.b 'CLR     '                * 16
 DC.b 'CLPG    '                * 17
 DC.b 'WAIT    '                * 18
 DC.b 'SCHR16TE'                * 19
 DC.b 'CLRSCREE'                * 20
 DC.b 'CO      '                * 21
 DC.b 'LO      '                * 22
 DC.b 'SIN     '                * 23
 DC.b 'COS     '                * 24
 DC.b 'SIZE    '                * 25
 DC.b 'CMD     '                * 26
 DC.b 'NEWPAGE '                * 27
 DC.b 'SYNC    '                * 28
 DC.b 'WERT    '                * 29
 DC.b 'ZUWEIS  '                * 30
 DC.b 'CIINIT2 '                * 31
 DC.b 'CI2     '                * 32
 DC.b 'CO2     '                * 33
 DC.b 'SETFLIP '                * 34
 DC.b 'DELAY   '                * 35
 DC.b 'FIRSTTIM'                * 36
 DC.b 'SETPEN  '                * 37
 DC.b 'ERAPEN  '                * 38
 DC.b 'GRAPOFF '                * 39
 DC.b 'CMDPRINT'                * 40
 DC.b 'PRINT2X '                * 41
 DC.b 'PRINT4X '                * 42
 DC.b 'PRINT6X '                * 43
 DC.b 'PRINT8X '                * 44
 DC.b 'PRINT8B '                * 45
 DC.b 'PRINT4D '                * 46
 DC.b 'HIDE    '                * 47
 DC.b 'SHOW    '                * 48
 DC.b 'CRT     '                * 49
 DC.b 'LST     '                * 50
 DC.b 'USR     '                * 51
 DC.b 'NIL     '                * 52
 DC.b 'SETERR  '                * 53
 DC.b 'GETERR  '                * 54
 DC.b 'SETPASS '                * 55
 DC.b 'EDIT    '                * 56
 DC.b 'FIGUR   '                * 57
 DC.b 'SETFIG  '                * 58
 DC.b 'GETRAM  '                * 59
 DC.b 'AUTOFLIP'                * 60
 DC.b 'CURSEIN '                * 61
 DC.b 'CURSAUS '                * 62
 DC.b 'CHAR    '                * 63
 DC.b 'PROGZGE '                * 64
 DC.b 'ASSEMBLE'                * 65
 DC.b 'GETSTX  '                * 66
 DC.b 'PUTSTX  '                * 67
 DC.b 'GETORG  '                * 68
 DC.b 'PUTORG  '                * 69
 DC.b 'PRINT8D '                * 70
 DC.b 'PRINTV8D'                * 71
 DC.b 'MULS32  '                * 72
 DC.b 'DIVS32  '                * 73
 DC.b 'FLINIT  '                * 74
 DC.b 'FLOPPY  '                * 75
 DC.b 'GETFLOP '                * 76
 DC.b 'SETXOR  '                * 77
 DC.b 'GETXOR  '                * 78
 DC.b 'SETCOLOR'                * 79
 DC.b 'GETCOLOR'                * 80
 DC.b 'CURON   '                * 81
 DC.b 'CUROFF  '                * 82
 DC.b 'ADJ360  '                * 83
 DC.b 'PRTSYM  '                * 84
 DC.b 'SYMCLR  '                * 85
 DC.b 'GETSYM  '                * 86
 DC.b 'GETNEXT '                * 87
 DC.b 'PUTNEXT '                * 88
 DC.b 'GETBASIS'                * 89
 DC.b 'GETVAR  '                * 90
 DC.b 'SETA5   '                * 91
 DC.b 'AUFXY   '                * 92
 DC.b 'KORXY   '                * 93
 DC.b 'AUFK    '                * 94
 DC.b 'GETK    '                * 95
 DC.b 'RND     '                * 96
 DC.b 'GETVERS '                * 97
 DC.b 'GETSN   '                * 98
 DC.b 'CRLF    '                * 99
 DC.b 'GETLINE '                * 100
 DC.b 'GETCURXY'                * 101
 DC.b 'SETCURXY'                * 102
 DC.b 'GETXY   '                * 103
 DC.b 'SI      '                * 104
 DC.b 'SO      '                * 105
 DC.b 'SISTS   '                * 106
 DC.b 'SOSTS   '                * 107
 DC.b 'SIINIT  '                * 108
 DC.b 'GETAD8  '                * 109
 DC.b 'GETAD10 '                * 110
 DC.b 'SETDA   '                * 111
 DC.b 'SPEAK   '                * 112
 DC.b 'SPEAK1  '                * 113
 DC.b 'SOUND   '                * 114
 DC.b 'GETUHR  '                * 115
 DC.b 'SETUHR  '                * 116
 DC.b 'LSTS    '                * 117
 DC.b 'RELAN   '                * 118
 DC.b 'RELAUS  '                * 119
 DC.b 'ASSERR  '                * 120
 DC.b '::::::::'                * 121           Nur für 68020
 DC.b '::::::::'                * 122           Nur bei 68020
 DC.b 'READAUS '                * 123
 DC.b 'GRUND   '                * 124
 DC.b 'HARDCOPY'                * 125
 DC.b 'GRAFIK  '                * 126
 DC.b 'GDPVERS '                * 127
 DC.b 'SER     '                * 128
 DC.b 'CO2SER  '                * 129
 DC.b 'CLUTINIT'                * 130
 DC.b 'CLUT    '                * 131
 DC.b 'RELAIS  '                * 132
 DC.b 'RELAISIN'                * 133
 DC.b 'SETDA12 '                * 134
 DC.b 'GETAD12 '                * 135
 DC.b 'SUCHBIBO'                * 136
 DC.b 'DISASS  '                * 137
 DC.b 'SI2     '                * 138
 DC.b 'SYSTEM  '                * 139
 DC.b 'UHRPRINT'                * 140
 DC.b 'HARDDISK'                * 141
 DC.b 'HARDTEST'                * 142
 DC.b '::::::::'                * 143           Reserviert
 DC.b '::::::::'                * 144           Reserviert
 DC.b '::::::::'                * 145           Nur bei 68020
 DC.b '::::::::'                * 146           Nur bei 68020
 DC.b '::::::::'                * 147           Nur bei 68020
 DC.b '::::::::'                * 148           Nur bei 68020
 DC.b '::::::::'                * 149           Nur bei 68020
 DC.b 'SETSER  '                * 150
 DC.b 'GETSER  '                * 151
 DC.b 'SETS2I  '                * 152
 DC.b 'GETS2I  '                * 153
 DC.b 'IDETEST '                * 154
 DC.b 'IDEDISK '                * 155
 DC.b 'SRDISK  '                * 156
 DC.b 'SETF2S  '                * 157
 DC.b 'GETF2S  '                * 158
 DC.b 'GETSRD  '                * 159
 DC.b 'SETSYS  '                * 160
 DC.b 'GETSYS  '                * 161
 DC.b 'PATCH   '                * 162
 DC.b 'SDTEST  '                * 163
 DC.b 'SDDISK  '                * 164
 DC.b 'SETCHAR '                * 165
 DC.b 'SETTRANS'                * 166
 DC.b 'GETTRANS'                * 167
 DC.l 0,0                       * Ende

*******************************************************************************
*                      68000/68010 Grundprogramm disass                       *
*                         (C) 1990 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                            68000 Disassembler                               *
*******************************************************************************


                                * a0 ist GERADE Ziel-Adresse für Text
trapdisass:                     * Disass über Trap aufgerufen
 movem.l d0-d7/a0-a4,-(a7)      * Alle Register retten
 movea.l a0,a4                  * Ziel-Adresse
 and.b #$fe,d0                  * Auf gerade Adresse bringen
 movea.l d0,a3                  * Adresse Befehl
 bsr.s disass1
 movem.l (a7)+,d0-d7/a0-a4      * Register zurück
 rts

disass:                         * a3 ist Adresse Befehl
 lea einbuf(a5),a4              * Ziel ist einbuf
disass1:                        * Einsprung, wenn anderes Ziel
 movea.l a4,a0                  * Es werden keine Register gerettet
 move (a3),d0                   * Befehl holen
 rol #5,d0                      * Bits 7-4 bestimmen Gruppe
 and #$1e,d0
 move beftab(pc,d0.w),d0
 jsr beftab(pc,d0.w)            * Gruppe aufrufen
 clr.b (a0)                     * Endekennung
 rts

beftab:                         * Adresstabelle der einzelnen Gruppen
 DC.w gruppe0-beftab
 DC.w gruppe1-beftab
 DC.w gruppe2-beftab
 DC.w gruppe3-beftab
 DC.w gruppe4-beftab
 DC.w gruppe5-beftab
 DC.w gruppe6-beftab
 DC.w gruppe7-beftab
 DC.w gruppe8-beftab
 DC.w gruppe9-beftab
 DC.w nobefehl-beftab           * Kein Befehl in dieser Gruppe beim 68008/68010
 DC.w gruppe11-beftab
 DC.w gruppe12-beftab
 DC.w gruppe13-beftab
 DC.w gruppe14-beftab
 DC.w nobefehl-beftab           * Kein Befehl in dieser Gruppe beim 68008/68010

gruppe0:
 move (a3),d0                   * MOVEP
 and #$f138,d0
 cmp #$0108,d0
 bne.s gr0001
 move.l #'MOVE',(a0)+
 move.w #'P.',(a0)+
 move (a3),d0
 moveq #'W',d1                  * Wort
 btst #6,d0                   * Bit 6 bestimmt Größe
 beq.s *+4
 moveq #'L',d1                  * oder Langwort
 move.b d1,(a0)+
 tst.b d0                       * Bit 7 bestimmt Richtung
 bpl.s gr0000
 moveq #9,d3                    * Register in Speicher
 bsr dareg1                     * Datenregister
 move.b #',',(a0)+
 move 2(a3),d0                  * Wert
 bsr put4x                      * Wert wandeln
 bra geta3                       * Adressregister
gr0000:                         * Speicher in Register
 move.b #' ',(a0)+
 move 2(a3),d0                  * Wert
 bsr put4x                      * Wert wandeln
 bsr geta3                      * Adressregister
 moveq #9,d3
 bra dareg0                      * Datenregister
gr0001:                         * CMPI
 move (a3),d0
 and #$ff00,d0
 cmp #$0c00,d0
 bne.s gr0002
 lea eatab6(pc),a2              * Verbotene Adressierungsarten
 move.l #'CMPI',(a0)+
 bra.s gr0007
gr0002:                         * ADDI
 lea    eatab4(pc),a2
 cmp #$0600,d0
 bne.s gr0003
 move.l #'ADDI',(a0)+
 bra.s gr0007
gr0003:                         * SUBI
 cmp #$0400,d0
 bne.s gr0004
 move.l #'SUBI',(a0)+
 bra.s gr0007
gr0004:                         * ANDI
 cmp #$0200,d0
 bne.s gr0005
 move.l #'ANDI',(a0)+
 bra.s gr0007
gr0005:                         * EORI
 cmp #$0a00,d0
 bne.s gr0006
 move.l #'EORI',(a0)+
 bra.s gr0007
gr0006:                         * ORI
 tst d0
 bne.s gr0008
 move.w #'OR',(a0)+
 move.b #'I',(a0)+
gr0007:                         * Einsprung für addi/subi/cmpi/andi/eori/ori
 bsr getgroess                  * Größe holen
 bcs.s gr0008
 bsr checkadr                   * Adressierungsart prüfen
 bcs.s gr0008
 move d0,d1                     * Größe merken
 lea 2(a3),a2
 move.b #' ',(a0)+
 bsr konstante                  * Konstante holen
 bcs.s gr0008
 adda d0,a2                     * Länge der Konstanten
 move d1,d0                     * Größe zurück
 move (a3),d3
 move.b #',',(a0)+
 bsr getadr3                    * Adressierungsart
 bcs nobefehl
 rts
gr0008:                         * ANDI
 movea.l a4,a0
 move (a3),d0
 and #$ff3f,d0
 cmp #$023c,d0
 bne.s gr0009
 move.l #'ANDI',(a0)+
 bra.s gr0011
gr0009:                         * EORI
 cmp #$0a3c,d0
 bne.s gr0010
 move.l #'EORI',(a0)+
 bra.s gr0011
gr0010:                         * ORI
 cmp #$003c,d0
 bne.s gr0013
 move.w #'OR',(a0)+
 move.b #'I',(a0)+
gr0011:                         * Einsprung für andi/eori/ori to sr/ccr
 bsr getgroess                  * Größe holen
 bcs.s gr0013
 tst d0                         * Dadurch Entscheidung ob CCR oder SR
 bne.s gr0012
 move 2(a3),d0                  * to ccr
 bsr konstb1                    * Byte-Konstante holen
 bcs.s gr0013                   * Kein Byte
 move.b #',',(a0)+
 move.b #'C',(a0)+
 move.b #'C',(a0)+
 move.b #'R',(a0)+
 rts
gr0012:                         * to sr
 cmp #1,d0                      * Nicht Wort, dann weiter
 bne.s gr0013
 move 2(a3),d0
 bsr konstw1                    * Wort-Konstante holen
 move.b #',',(a0)+
 move.b #'S',(a0)+
 move.b #'R',(a0)+
 rts
gr0013:
 movea.l a4,a0                  * BCHG/BSET/BCLR/BTST
 move (a3),d0
 btst #8,d0
 bne.s gr0014                   * Bit 8 muß gesetzt sein
 and #$ff00,d0
 cmp #$0800,d0
 bne gr0016                     * Bit 9,10,11 nicht gesetzt, wenn Bit 8 gesetzt
gr0014:                         * bchg/bset/bclr/btst
 move (a3),d0
 and #$00c0,d0
 lsr #3,d0                      * Erkennung, welcher Befehl
 lea gr0tab0(pc,d0.w),a1
 move.l (a1)+,(a0)+
 move.l (a1),d0
 lea gr0tab0(pc,d0.l),a2        * Tabelle erlaubter Adressierungen
 moveq #0,d0                    * Normalerweise Byte
 move (a3),d1
 lsr #3,d1
 and #$7,d1
 bne.s *+4                      * Bei Datenregister als Ziel Langwort
 moveq #2,d0
 bsr putgroess                  * Größe ausgeben
 bsr checkadr                   * Adressierungsart prüfen
 bcs.s gr0016
 btst.b #0,(a3)                 * Bit 0 bestimmt Art des Befehls
 bne.s gr0015
 move d0,d1                     * #konst,(ea)
 move 2(a3),d0
 bmi.s gr0016                   * Bereichsüberschreitung
 moveq #8,d2                    * Von Null bis 7 oder bis 31
 lsl d1,d2                      * ( Hängt von der Größe (Byte,Long) ab )
 cmp d2,d0
 bpl.s gr0016                   * Bereich zu groß
 bsr konstb1                    * Konstante ermitteln
 bcs.s gr0016
 move d1,d0                     * Größe zurück
 bsr getsadr0                   * Adressierungsart
 bcs nobefehl
 rts
gr0015:
 moveq #9,d3                    * dn,<ea>
 bsr dareg1                     * Datenregister
 bsr getadr0                    * Adressierungsart
 bcs nobefehl
 rts

gr0tab0:                        * Befehl und verbotene Adressierungsarten
 DC.l 'BTST',eatab6-gr0tab0
 DC.l 'BCHG',eatab4-gr0tab0
 DC.l 'BCLR',eatab4-gr0tab0
 DC.l 'BSET',eatab4-gr0tab0

gr0016:
 movea.l a4,a0
 move.l (a3),d0                 * moves
 and.l #$ff0007ff,d0
 cmp.l #$0e000000,d0
 bne.s gr0018                   * Nicht moves
 move.l #'MOVE',(a0)+
 move.b #'S',(a0)+
 bsr getgroess                  * Größe ausgeben
 bcs.s gr0018
 move 2(a3),d0
 btst #11,d0                    * Richtung
 beq.s gr0017
 addq.l #2,a3                   * moves rx,(ea)
 moveq #12,d3                   * Ziel Registernummer
 moveq #15,d4                   * Ziel D/A-Bit
 bsr reg1                       * Register ausgeben
 subq.l #2,a3                   * a3 auf alten Wert
 bsr    check2adr               * Adressierungsarten überprüfen
 bcs.s gr0018
 bsr getsadr0                   * Adressierungsart ausgeben
 bcs nobefehl
 rts
gr0017:                         * moves (ea),rx
 bsr    check2adr               * Adressierungsarten prüfen
 bcs.s gr0018
 bsr getsadr1                   * Adressierungsart ausgeben
 bcs nobefehl
 addq.l #2,a3
 moveq #12,d3
 moveq #15,d4
 bra reg0                        * Register ausgeben
gr0018:                         * Beim 68010 keine weiteren Befehle
 bra nobefehl

gruppe1:                        * MOVE.B
 move (a3),d0
 and #$f1c0,d0
 cmp #$1040,d0                  * MOVEA.B ist nicht erlaubt
 beq nobefehl
 moveq #0,d0                    * Byte
 bra.s movebef

gruppe2:
 moveq #2,d0                    * MOVE.L
 bra.s movebef

gruppe3:                        * MOVE.W
 moveq #1,d0

movebef:                        * Routinen für den Move-Befehl
 move.l #'MOVE',(a0)+           * Carry bei Fehler
 move (a3),d1                   * Größe in d0 übergeben
 and #$01c0,d1                  * d0=Länge des Befehls
 cmp #$0040,d1
 bne.s movebef0
 move.b #'A',(a0)+              * MOVEA
 bsr putgroess                  * Größe holen
 bsr getadr1                    * Adressierungsart
 bcs nobefehl
 moveq #9,d3
 bra adreg0                      * Adressregister als Ziel
movebef0:                       * MOVE
 bsr putgroess                  * Größe holen
 move d0,-(a7)
 bsr getadr1                    * Adressierungsart Quelle
 bcc.s *+8
 addq.l #2,a7
 bra carset
 move (a3),d2
 lea 2(a3,d0.w),a1              * Anfang Zieladresse
 move (a7)+,d0                  * Größe zurück
 move.l a3,-(a7)
 lsr #3,d2
 move d2,d1
 lsr #6,d2
 and #7,d2
 and #$38,d1
 add d1,d2
 lea einbuf+130(a5),a3          * Hilfspeicher
 move d2,(a3)                   * Opcode
 bsr    check4adr               * Prüfen Zieladressierungsart
 bcs.s movebef2
 move.b #',',(a0)+
 movea.l a1,a2
 move (a3),d3
 bsr getadr3                    * Adressierungsart Ziel
 bcs.s movebef2
 movea.l (a7)+,a3
 rts                             * Kein Fehler
movebef2:
 movea.l (a7)+,a3
 bra nobefehl                    * Fehler

gruppe4:
 lea gr4tab0(pc),a1             * Befehle aus Tabelle
 move (a3),d0
 moveq #7-1,d1                  * Anzahl der Befehle
gr4001:
 cmp (a1)+,d0                   * Befehl vergleichen
 bne.s gr4003
gr4002:
 move.b (a1)+,(a0)+             * OK, ASCII-Zeichen übertragen
 bne.s gr4002
 rts
gr4003:
 addq.l #8,a1                   * Nächster Befehl, wenn nicht gefunden
 dbra d1,gr4001
 and #$fff8,d0                  * SWAP
 cmp #$4840,d0
 bne.s gr4004
 move.l #'SWAP',(a0)+
 move.w #'.W',(a0)+
 moveq #0,d3
 bra dareg1                      * SWAP Datenregister

gr4tab0:                        * Tabelle der Behle
 DC.b $4a,$fc,'ILLEGAL',0
 DC.b $4e,$71,'NOP',0,0,0,0,0
 DC.b $4e,$70,'RESET',0,0,0
 DC.b $4e,$73,'RTE',0,0,0,0,0
 DC.b $4e,$77,'RTR',0,0,0,0,0
 DC.b $4e,$75,'RTS',0,0,0,0,0
 DC.b $4e,$76,'TRAPV',0,0,0


gr4004:                         * UNLK
 cmp #$4e58,d0
 bne.s gr4005
 move.l #'UNLK',(a0)+
 moveq #0,d3
 bra adreg1                      * Nur Adressregister
gr4005:                         * STOP
 cmp #$4e72,d0
 bne.s gr4006
 move.l #'STOP',(a0)+
 move 2(a3),d0
 bra konstw1                     * Konstante
gr4006:                         * TRAP
 and #$fff0,d0
 cmp #$4e40,d0
 bne.s gr4007
 move.l #'TRAP',(a0)+
 move (a3),d0
 and #$f,d0
 bra konstb1                     * Nummer Trap
gr4007:                         * MOVE USP
 cmp #$4e60,d0
 bne.s gr4009
 move.l #'MOVE',(a0)+
 move.w #'.L',(a0)+
 btst.b #3,1(a3)
 beq.s gr4008                   * MOVE USP,An
 move.l #' USP',(a0)+
 moveq #0,d3
 bra adreg0                      * Adressregister
gr4008:
 moveq #0,d3                    * MOVE An,USP
 bsr adreg1
 move.b #',',(a0)+
 move #'US',(a0)+
 move.b #'P',(a0)+
 rts
gr4009:
 move (a3),d0                   * LINK
 and #$fff8,d0
 cmp #$4e50,d0
 bne.s gr4010
 move.l #'LINK',(a0)+
 move.w #'.W',(a0)+
 moveq #0,d3
 bsr adreg1                     * Adressregister
 move 2(a3),d0
 bra konstw0                     * Konstante
gr4010:                         * EXT
 and #$ffb8,d0
 cmp #$4880,d0
 bne.s gr4011
 move.l #'EXT.',(a0)+
 moveq #'W',d1                  * Wort
 btst.b #6,1(a3)                * Größe ermitteln
 beq.s *+4
 moveq #'L',d1                  * oder Langwort
 move.b d1,(a0)+
 moveq #0,d3
 bra dareg1                      * Nur Datenregister
gr4011:
 move (a3),d0                   * JMP
 and #$ffc0,d0
 cmp #$4ec0,d0
 bne.s gr4012
 move.l #'JMP ',(a0)+
 bra.s gr4013
gr4012:
 cmp #$4e80,d0                  * JSR
 bne.s gr4014
 move.l #'JSR ',(a0)+
gr4013:                         * Einsprung jmp
 bsr    check3adr               * Adressierungsarten prüfen
 bcs.s gr4014
 moveq #1,d0                    * Wort, da nur gerade Adressen als Ziel erlaubt
 bsr getadr2                    * Adressierungsart prüfen
 bcs nobefehl
 rts
gr4014:
 movea.l a4,a0
 move (a3),d0                   * CHK.W
 and #$f1c0,d0
 cmp #$4180,d0
 bne.s gr4016
 move.l #'CHK.',(a0)+
 move.w #'W ',(a0)+
 bsr    check1adr               * Adressierungsart prüfen
 bcs.s gr4015
 moveq #1,d0                    * Wort
 bsr getadr2                    * Adressierungsart
 bcs nobefehl
 moveq #9,d3
 bra dareg0                      * Datenregister
gr4015:
 movea.l a4,a0
gr4016:
 move (a3),d0                   * LEA
 and #$f1c0,d0
 cmp #$41c0,d0
 bne.s gr4018
 move.l #'LEA.',(a0)+
 move.w #'L ',(a0)+
 bsr    check3adr               * Adressierungsart prüfen
 bcs.s gr4017
 moveq #0,d0                    * Byte, da alle Adressen erlaubt sind
 bsr getadr2                    * Adressierungsart
 bcs nobefehl
 moveq #9,d3
 bra adreg0                      * Adressregister
gr4017:
 movea.l a4,a0
gr4018:
 move (a3),d0                   * CLR
 and #$ff00,d0
 cmp #$4200,d0
 bne.s gr4019
 move.w #'CL',(a0)+
 move.b #'R',(a0)+
 bsr gr4026
 bcc carres                     * OK
 movea.l a4,a0
 move (a3),d0
 and #$ff00,d0
gr4019:
 cmp #$4400,d0                  * NEG
 bne.s gr4020
 move.w #'NE',(a0)+
 move.b #'G',(a0)+
 bsr gr4026
 bcc carres                     * OK
 movea.l a4,a0
 move (a3),d0
 and #$ff00,d0
gr4020:
 cmp #$4000,d0                  * NEGX
 bne.s gr4021
 move.l #'NEGX',(a0)+
 bsr gr4026
 bcc carres                     * OK
 movea.l a4,a0
 move (a3),d0
 and #$ff00,d0
gr4021:
 cmp #$4600,d0                  * NOT
 bne.s gr4022
 move.w #'NO',(a0)+
 move.b #'T',(a0)+
 bsr gr4026
 bcc carres                     * OK
 movea.l a4,a0
 move (a3),d0
 and #$ff00,d0
gr4022:
 cmp #$4a00,d0                  * TST
 bne.s gr4023
 move.w #'TS',(a0)+
 move.b #'T',(a0)+
 bsr.s gr4026
 bcc carres                     * OK
 movea.l a4,a0
gr4023:
 move (a3),d0                   * NBCD
 and #$ffc0,d0
 cmp #$4800,d0
 bne.s gr4024
 move.l #'NBCD',(a0)+
 move.w #'.B',(a0)+
 moveq #0,d0                    * Nur Byte als Größe
 bsr.s gr4027
 bcc carres                     * OK
 movea.l a4,a0
 move (a3),d0
 and #$ffc0,d0
gr4024:
 cmp #$4840,d0                  * PEA
 bne.s gr4025
 move.w #'PE',(a0)+
 move.b #'A',(a0)+
 moveq #0,d0                    * Byte, da alle Adressen erlaubt sind
 bsr    check3adr
 bsr.s gr4027a
 bcc carres                     * OK
 movea.l a4,a0
 move (a3),d0
 and #$ffc0,d0
gr4025:
 cmp #$4ac0,d0                  * TAS
 bne.s gr4028
 move.l #'TAS.',(a0)+
 move.b #'B',(a0)+
 moveq #0,d0                    * Byte
 bsr.s gr4027
 bcs.s gr4028                   * Fehler
 rts
gr4026:                         * Einsprung für clr/neg/negx/not/tst
 bsr getgroess                  * Größe feststellen
 bcs carset
gr4027:                         * Einsprung für nbcd/pea/tas
 bsr    check4adr               * Adressierungsart prüfen
gr4027a:
 bcs carset                     * Fehler
 bsr getadr1                    * Adressierungsart
 bcs carset                     * Fehler
 bra carres                      * OK
gr4028:
 movea.l a4,a0
 move (a3),d0                   * MOVE TO CCR
 and #$ffc0,d0
 cmp #$44c0,d0
 bne.s gr4029
 move.l #'MOVE',(a0)+
 move.w #'.W',(a0)+
 move (a3),d0
 and #$003f,d0
 cmp #%111100,d0                * move #wert,ccr ?
 bne.s *+10                     * Nein, weiter
 tst.b 2(a3)                    * Nur OK, wenn Byte-Groesse
 bne nobefehl
 bsr    check1adr               * Adressierungsart prüfen
 bcs.s gr4029
 moveq #1,d0                    * Größe ist Wort; obere 8 Bits werden ignoriert
 bsr getadr1                    * Adressierungsart
 bcs nobefehl
 move.b #',',(a0)+
 move.b #'C',(a0)+
 move.b #'C',(a0)+
 move.b #'R',(a0)+
 rts
gr4029:
 movea.l a4,a0                  * MOVE TO SR
 cmp #$46c0,d0
 bne.s gr4030
 move.l #'MOVE',(a0)+
 move.w #'.W',(a0)+
 bsr    check1adr               * Adressierungsart prüfen
 bcs.s gr4030
 moveq #1,d0                    * Wort-Größe
 bsr getadr1                    * Adressierungsart
 bcs nobefehl
 move.b #',',(a0)+
 move.b #'S',(a0)+
 move.b #'R',(a0)+
 rts
gr4030:
 movea.l a4,a0                  * MOVE FROM SR
 cmp #$40c0,d0
 bne.s gr4031
 move.l #'MOVE',(a0)+
 move.l #'.W S',(a0)+
 move.w #'R,',(a0)+
 bsr    check4adr               * Adressierungsart prüfen
 bcs.s gr4031
 moveq #1,d0                    * Wort-Größe
 bsr getadr2                    * Adressierungsart
 bcs nobefehl
 rts
gr4031:
 movea.l a4,a0                  * MOVEM
 move (a3),d0
 and #$fb80,d0
 cmp #$4880,d0
 bne gr4033
 move.l #'MOVE',(a0)+
 move.b #'M',(a0)+
 moveq #1,d0                    * Wort
 move (a3),d1
 btst #6,d1                     * Größe bestimmen
 beq.s *+4
 moveq #2,d0                    * oder Langwort
 bsr putgroess                  * Größe ausgeben
 btst #10,d1                    * Richtung der Übertragung
 beq.s gr4032
 bsr    check7adr               * Adressierungsart prüfen
 bcs gr4033
 bsr getsadr1                   * Adressierungsart
 bcs nobefehl
 moveq #0,d1                    * Normale Reihenfolge
 move.b #',',(a0)+
 bsr.s getlist
 bcs nobefehl                   * Liste holen
 rts
gr4032:                         * movem reglist,(ea)
 move.b #' ',(a0)+
 move (a3),d2
 and #$38,d2
 moveq #0,d1                    * Normalfall Registerfolge
 cmp #%100000,d2
 bne.s *+4
 moveq #1,d1                    * Spezialfall
 bsr.s getlist                  * Liste holen
 bcs nobefehl
 bsr    check8adr               * Adresierungsart prüfen
 bcs nobefehl
 bsr getsadr0                   * Adressierungsart
 bcs nobefehl
 rts

getlist:                        * a2 Adresse Liste
 move 2(a3),d0                  * d1 = 0 Normal / d1 = 1 (an)+,reglist
 beq carset                     * Keine Adresse
 tst d1
 beq.s getli2
 move d0,d1
 moveq #16-1,d7
getli1:
 roxl #1,d1
 roxr #1,d0
 dbra d7,getli1                  * Jetzt in der richtigen Reihenfolge
getli2:
 moveq #'D',d1                  * d0 ist jetzt immer richtig
 bsr.s getli3                   * Erst Datenregister
 rol #8,d0
 moveq #'A',d1
 bsr.s getli3                   * Dann Adressregiser
 subq.l #1,a0                   * '/' weg
 bra carres

getli3:
 moveq #0,d7
getli4:
 btst d7,d0                   * Anfang suchen
 beq.s getli8
 move d7,d2
getli5:
 btst d7,d0                   * Ende suchen
 beq.s getli6
 addq #1,d7
 cmp #8,d7                      * Kein Ende gefunden, dann nur ein Register
 bne.s getli5
getli6:
 move d7,d3
 add.b #'0'-1,d3                * In ASCII wandeln
 add.b #'0',d2
 move.b d1,(a0)+                * 'D' oder 'A'
 move.b d2,(a0)+                * Nummer Anfangsregister
 neg d2
 add d3,d2                      * Abstand feststellen
 beq.s getli7                   * Null, dann nur ein Register
 move.b #'-',(a0)               * Verbindung
 cmp #1,d2
 bne.s *+6
 move.b #'/',(a0)               * Abstand nur 1 Register
 addq.l #1,a0
 move.b d1,(a0)+                * 'D' oder 'A'
 move.b d3,(a0)+                * Nummer Endregister
getli7:
 move.b #'/',(a0)+
getli8:
 addq #1,d7
 cmp #8,d7                      * Wenn alle Register durch, dann Ende
 bmi.s getli4                    * Sonst weitersuchen
 rts

gr4033:
 movea.l a4,a0                  * rtd
 move (a3),d0
 cmp #$4e74,d0
 bne.s gr4034
 move.l #'RTD ',(a0)+
 move 2(a3),d0
 bra konstw2                     * Wort-Konstante
gr4034:
 and #$ffc0,d0                  * move from ccr
 cmp #$42c0,d0
 bne.s gr4035
 move.l #'MOVE',(a0)+
 move.l #'.W C',(a0)+
 move.w #'CR',(a0)+
 moveq #1,d0                    * Größe ist immer Wort
 bsr    check4adr               * Adressierungsarten prüfen
 bcs.s gr4035
 bsr getadr0                    * Adressierungsart holen
 bcs nobefehl
 rts
gr4035:
 move (a3),d0                   * movec
 and #$fffe,d0
 cmp #$4e7a,d0
 bne nobefehl                   * Beim 68010 keine weiteren Befehle
 move.l #'MOVE',(a0)+
 move.l #'C.L ',(a0)+
 move (a3)+,d0
 lsr #1,d0                      * Richtung
 bcc.s gr4036
 moveq #12,d3                   * rx,Steuerreg
 moveq #15,d4
 bsr reg2                       * Register
 move.b #',',(a0)+
 bsr.s gr4037                   * Controlregister als Ziel
 bcs nobefehl                   * Falsches Ziel
 rts
gr4036:                         * Steuerreg,rx
 bsr.s gr4037                   * Controlregister als Quelle
 bcs nobefehl                   * Falsches Register
 moveq #12,d3
 moveq #15,d4
 bra reg0                        * Zielregister

gr4037:                         * a3 auf Wort
 move (a3),d0
 and #$0fff,d0                  * Bits für Register
 lea gr4037tab(pc),a1
 moveq #4-1,d7                  * 4 Register
gr4038:
 cmp (a1)+,d0                   * Vergleich
 beq.s gr4039                   * OK, Register gefunden
 addq.l #4,a1                   * Weiter testen
 dbra d7,gr4038
 subq.l #2,a3                   * Alte Adresse
 bra carset                      * Fehler
gr4039:
 move.b (a1)+,(a0)+             * Übertragen
 move.b (a1)+,(a0)+
 move.b (a1)+,(a0)+
 bra carres                      * OK

gr4037tab:
 DC.b $00,$00,'SFC',0
 DC.b $00,$01,'DFC',0
 DC.b $08,$00,'USP',0
 DC.b $08,$01,'VBR',0

gruppe5:                        * DBCC
 move (a3),d0
 and #$f0f8,d0
 cmp #$50c8,d0
 bne.s gr5001
 move.w #'DB',(a0)+
 move (a3),d0
 lsr #7,d0
 and #$1e,d0                    * Bedingungen
 cmp.b #%0010,d0
 bne.s *+8
 move.w #'RA',(a0)+             * Dbf = Dbra
 bra.s gr5000
 lea gr5tab0(pc,d0.w),a1
 move.b (a1)+,(a0)+
 move.b (a1)+,(a0)+             * Bedingungen holen, wenn nicht dbra
 bne.s gr5000
 subq.l #1,a0                   * Wenn Null, dann eins zurück
gr5000:
 btst.b #0,3(a3)                * Keine ungerade Adressdistanz
 bne.s gr5001
 moveq #0,d3
 bsr dareg1                     * Datenregister
 move.b #',',(a0)+
 move 2(a3),d0
 ext.l d0
 add.l a3,d0                    * Adresse berechnen, da relativ
 addq.l #2,d0                   * Abstand Adresse zum Anfang des Befehls
 bra put8x                       * Adresse

gr5tab0:                        * Tabelle der Bedingungen
 DC.b 'T',0
 DC.b 'F',0
 DC.b 'HI'
 DC.b 'LS'
 DC.b 'CC'
 DC.b 'CS'
 DC.b 'NE'
 DC.b 'EQ'
 DC.b 'VC'
 DC.b 'VS'
 DC.b 'PL'
 DC.b 'MI'
 DC.b 'GE'
 DC.b 'LT'
 DC.b 'GT'
 DC.b 'LE'

gr5001:                         * SCC
 move (a3),d0
 and #$f0c0,d0
 cmp #$50c0,d0
 bne.s gr5003
 move.b #'S',(a0)+
 move (a3),d0
 lsr #7,d0
 and #$1e,d0                    * Bedingung
 lea gr5tab0(pc,d0.w),a1
 move.b (a1)+,(a0)+             * Bedingung holen
 move.b (a1)+,(a0)+
 bne.s gr5002
 subq.l #1,a0                   * Bei Null, eins zurück
gr5002:
 moveq #0,d0
 bsr putgroess                  * Größe ist immer Byte
 bsr    check4adr               * Adressierungsart prüfen
 bcs.s gr5003
 bsr getadr1                    * Adressierungsart
 bcs nobefehl
 rts
gr5003:
 movea.l a4,a0                  * ADDQ
 btst #0,(a3)
 bne.s gr5004
 move.l #'ADDQ',(a0)+
 bra.s gr5005
gr5004:                         * SUBQ
 move.l #'SUBQ',(a0)+
gr5005:
 bsr getgroess                  * Größe feststellen
 bcs nobefehl
 move d0,d1
 move (a3),d0
 rol #7,d0
 and #7,d0
 bne.s *+4
 moveq #%1000,d0                * Null = Acht
 bsr konstb1                    * Konstante
 move d1,d0
 bsr    check5adr               * Adressierungsart prüfen
 bcs nobefehl
 bsr getadr0                    * Adressierungsart
 bcs nobefehl
 rts

gruppe6:                        * BCC/BRA/BSR
 movea.l a3,a2
 move.b #'B',(a0)+
 move (a2)+,d0
 move d0,d2
 lsr #7,d0
 and #$1e,d0
 move.b gr6tab0(pc,d0.w),(a0)+  * Bedingung
 move.b gr6tab0+1(pc,d0.w),(a0)+
 tst.b d2
 beq.s gr6001                   * bcc.w
 btst #0,d2                   * Keine ungerade Adressdistanz
 bne nobefehl
 moveq #0,d0
 bsr putgroess                  * bcc.b
 move.b #' ',(a0)+
 move d2,d0
 ext d0
 ext.l d0
 add.l a2,d0
 bra put8x                       * Adresse
gr6001:
 move (a2),d2
 btst #0,d2
 bne nobefehl                   * Keine ungerade Adressdistanz
 moveq #1,d0                    * Wort
 bsr putgroess                  * bcc.w
 move.b #' ',(a0)+
 move d2,d0
 ext.l d0
 add.l a2,d0
 bra put8x                       * Adresse

gr6tab0:                        * Bedingungen
 DC.b 'RA'
 DC.b 'SR'
 DC.b 'HI'
 DC.w 'LS'
 DC.b 'CC'
 DC.b 'CS'
 DC.b 'NE'
 DC.b 'EQ'
 DC.b 'VC'
 DC.b 'VS'
 DC.b 'PL'
 DC.b 'MI'
 DC.b 'GE'
 DC.b 'LT'
 DC.b 'GT'
 DC.b 'LE'

gruppe7:                        * MOVEQ
 move (a3),d0
 btst #8,d0
 bne nobefehl
 move.l #'MOVE',(a0)+
 move.l #'Q.L ',(a0)+
 and #$ff,d0                    * Nur Byte-Konstante
 bsr konstb2                    * Konstante
 moveq #9,d3
 bra dareg0                      * Ziel ist Datenregister

gruppe8:
 move (a3),d0                   * SBCD
 and #$f1f0,d0
 cmp #$8100,d0
 bne.s gr8003
 move.l #'SBCD',(a0)+
gr8000:                         * Einsprung abcd
 move.w #'.B',(a0)+
gr8001:                         * Einsprung addx,subx
 move (a3),d0
 btst #3,d0                   * Bit 3 bestimmt Adressierungsart
 bne.s gr8002
 moveq #0,d3                    * Datenregister
 bsr dareg1
 moveq #9,d3
 bra dareg0                      * Datenregister
gr8002:
 move.b #' ',(a0)+              * -(an),-(am)
 move.w #'-(',(a0)+
 bsr adreg2                     * Adressregister
 move.l #'),-(',(a0)+
 moveq #9,d3
 bsr adreg2                     * Adressregister
 move.b #')',(a0)+
 rts
gr8003:
 move.l #'DIVS',(a0)+           * DIVS/DIVU
 move (a3),d0
 lsr #6,d0
 and #7,d0
 cmp.b #%111,d0
 beq.s gr8004                   * DIVS
 cmp.b #%011,d0
 bne.s gr8005
 move.b #'U',-1(a0)             * DIVU
gr8004:                         * Einsprung für divs
 move.w #'.W',(a0)+             * Immer Wort
 bsr    check1adr               * Adressierungsart prüfen
 bcs.s gr8005
 moveq #1,d0                    * Wort
 bsr getadr1                    * Adressierungsart
 bcs nobefehl
 moveq #9,d3
 bra dareg0                      * Ziel ist Datenregister
gr8005:
 movea.l a4,a0
 move.w #'OR',(a0)+             * OR
 bsr getgroess
 bcs nobefehl
 btst #0,(a3)                   * or <ea>,dn
 bne.s gr8006
 bsr    check1adr               * Adressierungsart prüfen
 bcs nobefehl
 bsr getadr1                    * Adressierungsart
 bcs nobefehl
 moveq #9,d3
 bra dareg0                      * Ziel ist Datenregister
gr8006:                         * or dn,<ea>
 moveq #9,d3
 bsr dareg1                     * Quelle ist Datenregister
 bsr    check2adr               * Adressierungart prüfen
 bcs nobefehl
 bsr getadr0                    * Adressierungsart
 bcs nobefehl
 rts

gruppe9:
 move (a3),d0                   * SUBX
 and #$f130,d0
 cmp #$9100,d0
 bne.s gr9001
 move.l #'SUBX',(a0)+
 move (a3),d0
 bsr getgroess                  * Größe holen
 bcc gr8001
gr9000:                         * Einsprung addx
 movea.l a4,a0
gr9001:                         * SUBA
 move (a3),d0
 and #$f0c0,d0
 cmp #$90c0,d0
 bne.s gr9002
 move.l #'SUBA',(a0)+
 moveq #1,d0                    * Wort
 btst #0,(a3)                   * Bit 0 bestimmt Größe
 beq.s *+4
 moveq #2,d0                    * Langwort
 bsr putgroess
 bsr getadr1                    * Adressierungsart
 bcs nobefehl
 moveq #9,d3
 bra adreg0                      * Ziel ist Adressregister
gr9002:
 movea.l a4,a0
gr9003:                         * SUB
 move.w #'SU',(a0)+
 move.b #'B',(a0)+
 bsr getgroess                  * Größe holem
 bcs nobefehl
 btst #0,(a3)                   * sub <ea>,dn
 bne.s gr9004
 bsr getadr1                    * Adressierungsart
 bcs nobefehl
 moveq #9,d3
 bra dareg0                      * Ziel ist Datenregister
gr9004:                         * sub dn,<ea>
 moveq #9,d3
 bsr dareg1                     * Quelle ist Datenregister
 bsr    check2adr               * Adressierungsart prüfen
 bcs nobefehl
 bsr getadr0                    * Adressierungsart
 bcs nobefehl
 rts

gruppe11:
 move (a3),d0                   * CMPM
 and #$f138,d0
 cmp #$b108,d0
 bne.s gr11000
 move.l #'CMPM',(a0)+
 bsr getgroess                  * Größe holen
 bcs.s gr11000
 move.b #' ',(a0)+
 bsr geta4                      * (an)+
 move.b #',',(a0)+
 move.b #'(',(a0)+
 moveq #9,d3
 bsr adreg2                     * (am)+
 move.b #')',(a0)+
 move.b #'+',(a0)+
 rts
gr11000:                        * EOR
 movea.l a4,a0
 btst #0,(a3)
 beq.s gr11001
 move.w #'EO',(a0)+
 move.b #'R',(a0)+
 bsr getgroess                  * Größe holen
 bcs.s gr11001
 moveq #9,d3
 bsr dareg1                     * Datenregister
 bsr    check4adr               * Adressierungsart prüfen
 bcs.s gr11001
 bsr getadr0                    * Adressierungsart
 bcs nobefehl
 rts
gr11001:                        * CMP
 movea.l a4,a0
 btst #0,(a3)
 bne.s gr11002
 move.w #'CM',(a0)+
 move.b #'P',(a0)+
 bsr getgr1                     * Größe holen
 bcs.s gr11002
 move (a3),d1
 and #$38,d1
 cmp #%001000,d1
 bne.s *+6                      * Kein Bytevergleich Adress- / Datenregister
 tst d0
 beq.s gr11002
 bsr putgroess                  * Größe ausgeben
 bsr getadr1                    * Adressierungsart
 bcs nobefehl
 moveq #9,d3
 bra dareg0                      * Datenregister
gr11002:
 movea.l a4,a0
 move (a3),d0                   * CMPA
 move.l #'CMPA',(a0)+
 and #$01c0,d0
 cmp #%011000000,d0
 bne.s gr11003
 moveq #1,d0                    * Wort
 bra.s gr11004
gr11003:
 cmp #%111000000,d0
 bne nobefehl
 moveq #2,d0                    * Langwort
gr11004:
 bsr putgroess                  * Größe ausgeben
 bsr getadr1                    * Adressierungsart
 bcs nobefehl
 moveq #9,d3
 bra adreg0                      * Adressregister

gruppe12:
 move (a3),d0                   * ABCD
 and #$f1f0,d0
 cmp #$c100,d0
 bne.s gr12000
 move.l #'ABCD',(a0)+
 bra gr8000                      * Auswertung wie sbcd
gr12000:                        * EXG.L
 move.l #'EXG.',(a0)+
 move #'L ',(a0)+
 move (a3),d0
 and #$f1f8,d0
 cmp #$c140,d0
 bne.s gr12001
 moveq #9,d3
 bsr dareg2                     * Datenregister
 moveq #0,d3
 bra dareg0                      * Tausch mit Datenregister
gr12001:
 cmp #$c148,d0
 bne.s gr12002
 moveq #9,d3
 bsr adreg2                     * Adressregister
 moveq #0,d3
 bra adreg0                      * Tausch mit Adressregister
gr12002:
 cmp #$c188,d0
 bne.s gr12003
 moveq #9,d3
 bsr dareg2                     * Datenregister
 moveq #0,d3
 bra adreg0                      * Tausch mit Adressregister
gr12003:                        * AND
 movea.l a4,a0
 move (a3),d0
 move.w #'AN',(a0)+
 move.b #'D',(a0)+
 bsr getgroess                  * Größe feststellen
 bcs.s gr12005
 btst #0,(a3)
 bne.s gr12004
 bsr    check1adr               * Adressierungsart prüfen
 bcs.s gr12005
 bsr getadr1                    * Adressierungsart
 bcs nobefehl
 moveq #9,d3
 bra dareg0                      * Datenregister
gr12004:                        * and dn,<ea>
 moveq #9,d3
 bsr dareg1                     * Datenregister
 bsr    check2adr               * Adressierungsart prüfen
 bcs.s gr12005
 bsr getadr0                    * Adressierungsart
 bcs nobefehl
 rts
gr12005:
 movea.l a4,a0
 move.w #'MU',(a0)+            * MULS/MULU
 move.b #'L',(a0)+
 move (a3),d0
 and #$01c0,d0
 cmp #%111000000,d0
 bne.s gr12006
 move.b #'S',(a0)+              * MULS
 bra.s gr12007
gr12006:
 cmp.b #%011000000,d0
 bne nobefehl
 move.b #'U',(a0)+              * MULU
gr12007:                        * Einsprung für muls
 move.w #'.W',(a0)+             * Immer Wort
 bsr    check1adr               * Adressierungsart prüfen
 bcs nobefehl
 moveq #1,d0                    * Wort
 bsr getadr1                    * Adressierungsart
 bcs nobefehl
 moveq #9,d3
 bra dareg0                      * Ziel ist Datenregister

gruppe13:                       * ADDX
 move (a3),d0
 and #$f130,d0
 cmp #$d100,d0
 bne.s gr13001
 move.l #'ADDX',(a0)+
 bsr getgroess                  * Größe feststellen
 bcc gr8001
gr13000:
 movea.l a4,a0
gr13001:                        * ADDA
 move (a3),d0
 and #$f0c0,d0
 cmp #$d0c0,d0
 bne.s gr13003
 move.l #'ADDA',(a0)+
 moveq #1,d0                    * Wort
 btst #0,(a3)                   * Bit 0 bestimmt Größe
 beq.s *+4
 moveq #2,d0                    * Langwort
 bsr putgroess                  * Größe nur Wort oder Langwort
 bsr getadr1                    * Adressierungsart
 bcs nobefehl
 moveq #9,d3
 bra adreg0                      * Ziel ist Adressregister
gr13002:
 movea.l a4,a0
gr13003:                        * ADD
 move.w #'AD',(a0)+
 move.b #'D',(a0)+
 bsr getgroess                  * Größe holen
 bcs nobefehl
 btst #0,(a3)                   * add <ea>,dn
 bne.s gr13004
 bsr getadr1                    * Adressierungsart
 bcs nobefehl
 moveq #9,d3
 bra dareg0                      * Ziel ist Datenregister
gr13004:                        * add dn,<ea>
 moveq #9,d3
 bsr dareg1                     * Quelle ist Datenregister
 bsr    check2adr               * Adressierungsart prüfen
 bcs nobefehl
 bsr getadr0                    * Adressierungsart
 bcs nobefehl
 rts

gruppe14:
 move (a3),d0
 and #%111111000000,d0
 cmp.b #%11000000,d0
 bne.s gr14000
 btst #11,d0
 bne nobefehl                   * asd/lsd/rod/roxd <ea>
 lsr #7,d0
 and #$c,d0
 lea gr14tab0(pc),a1
 adda d0,a1
 move.w (a1)+,(a0)+             * Rotationsbefehl
 move.b (a1)+,(a0)+
 bne.s *+4
 subq.l #1,a0
 moveq #'L',d1                  * Links
 btst #0,(a3)                   * Bit 0 bestimmt Richtung
 bne.s *+4
 moveq #'R',d1                  * Oder Rechts
 move.b d1,(a0)+
 moveq #1,d0
 bsr putgroess                  * Größe ist Wort
 bsr    check2adr               * Adressierungsart prüfen
 bcs nobefehl
 bsr getadr1                    * Adressierungsart
 bcs nobefehl
 rts
gr14000:                        * asd/lsd/rod/roxd #konst/dx,dy
 move (a3),d0
 lsr #1,d0
 and #$c,d0
 lea gr14tab0(pc,d0),a1
 move.w (a1)+,(a0)+
 move.b (a1)+,(a0)+             * Befehl feststellen
 bne.s *+4
 subq.l #1,a0
 moveq #'L',d1
 btst #0,(a3)
 bne.s *+4
 moveq #'R',d1                  * Richtung der Schiebeoperation
 move.b d1,(a0)+
 bsr getgroess                  * Größe feststellen
 bcs nobefehl
 move (a3),d0
 btst #5,d0
 bne.s gr14001
 rol #7,d0                      * #konst,dy
 and #$7,d0
 bne.s *+4
 moveq #8,d0
 bsr konstb1                    * Konstante
 bra.s gr14002
gr14001:                        * Dx,Dy
 moveq #9,d3
 bsr dareg1                     * Datenregister
gr14002:
 moveq #0,d3
 bra dareg0                      * Ziel ist Datenregister

gr14tab0:                       * Tabelle der Schiebebefehle
 DC.b 'AS',0,0
 DC.b 'LS',0,0
 DC.b 'ROX',0
 DC.b 'RO',0,0

getatab1:                       * Tabelle Adressierungsarten
 DC.w geta1-getatab1            * Datenregister direkt
 DC.w geta2-getatab1            * Adressregister direkt
 DC.w geta3-getatab1            * Adressregister indirekt
 DC.w geta4-getatab1            * Adressregister indirekt mit Postinkrement
 DC.w geta5-getatab1            * Adressregister indirekt mit Predekrement
 DC.w geta6-getatab1            * Adressregister indirekt mit Adressdistanz
 DC.w geta7-getatab1            * Adressregister indirekt mit Index
 DC.w geta8-getatab1            * Verteilung auf andere Adressierungsarten

getsadr0:                       * Adressierungsart auswerten
 move.b #',',(a0)+              * Abstand Befehl-Adresse = 4
 bra.s getsadr2
getsadr1:
 move.b #' ',(a0)+
getsadr2:
 move (a3),d3
 lea 4(a3),a2
 bra.s getadr3

getadr0:                        * d0.w = Größe
 move.b #',',(a0)+              * a3 zeigt auf Opcode
 bra.s getadr2                   * Carry bei Fehler
getadr1:
 move.b #' ',(a0)+
getadr2:
 lea 2(a3),a2                   * Normalerweise befinden sich die Adressen
                                * direkt hinter dem Opcode
 move (a3),d3                   * d3 Mode
getadr3:                        * Einsprung move-Befehl
 lsr #2,d3
 and #$e,d3                     * Adressierungsart steht hier
 move getatab1(pc,d3.w),d3
 jmp getatab1(pc,d3.w)

geta1:                          * Datenregister direkt
 moveq #0,d3
 bsr dareg2
 moveq #0,d0
 bra carres
geta2:                          * Adressregister direkt
 tst.b d0
 beq carset                     * Kein Byte-Zugriff auf Adressregister
 moveq #0,d3
 bsr adreg2
 moveq #0,d0
 bra carres
geta3:                          * ARI
 move.b #'(',(a0)+
 moveq #0,d3
 bsr adreg2                     * (an)
 move.b #')',(a0)+
 moveq #0,d0
 bra carres
geta4:                          * ARI mit Postinkrement
 bsr.s geta3
 move.b #'+',(a0)+              * (an)+
 bra carres
geta5:                          * ARI mit Predekrement
 move.b #'-',(a0)+              * -(an)
 bra.s geta3
geta6:                          * ARI mit Adressdistanz
 move (a2),d0
 bsr put4x
 bsr.s geta3
 moveq #2,d0                    * d(an)
 bra carres
geta7:                          * ARI mit Adressdistanz und Index
 move (a2),d0
 btst #8,d0
 bne carset
 bsr put2x                      * Adressdistanz
 move.b #'(',(a0)+
 moveq #0,d3
 bsr adreg2                     * Adressregister
geta700:                        * Einsprung PC relativ mit Adressdist. und Index
 exg.l a2,a3
 moveq #12,d3
 moveq #15,d4
 bsr reg0                       * Register
 exg.l a3,a2
 move.b #'.',(a0)+
 moveq #'W',d3                  * Wort
 move (a2),d2
 btst #11,d2                    * Bit 11 bestimmt Größe
 beq.s geta701
 moveq #'L',d3                  * Langwort
geta701:
 move.b d3,(a0)+
 rol.w #7,d2
 and #3,d2
 bne carset
 move.b #')',(a0)+
 moveq #2,d0
 bra carres                      * d(an,rx) oder d(pc,rx)
geta8:
 move (a3),d3
 and #7,d3
 lsl #1,d3
 move getatab2(pc,d3.w),d3
 jmp getatab2(pc,d3.w)

getatab2:                       * Weitere Adressierungsarten
 DC.w geta81-getatab2           * Absolut kurz
 DC.w geta82-getatab2           * Absolut lang
 DC.w geta83-getatab2           * PC relativ mit Adressdistanz
 DC.w geta84-getatab2           * PC relativ mit Index und Adressdistanz
 DC.w konstante-getatab2        * Konstante
 DC.w carset-getatab2           * Für Erweiterungen
 DC.w carset-getatab2           * Zur Zeit nicht genutzt
 DC.w carset-getatab2           *

geta81:                         * Absolut kurz
 move (a2),d2
 tst.b d0
 beq.s geta810
 btst #0,d2
 bne carset                     * Nicht auf ungerade Adressen bei Wort und Long
geta810:
 move d2,d0
 bsr put4x                      * Adressdistanz
 move.b #'.',(a0)+
 move.b #'W',(a0)+
 moveq #2,d0
 bra carres
geta82:                         * Absolut lang
 move.l (a2),d2
 tst.b d0
 beq.s geta820
 btst #0,d2                   * Ungerade Adresse ?
 bne carset                     * Dann Fehler
geta820:
 move.l d2,d0
 bsr put8x                      * Adressdistanz
 move.b #'.',(a0)+
 move.b #'L',(a0)+
 moveq #4,d0
 bra carres
geta83:                         * PC relativ mit Adressdistanz
 move (a2),d2
 tst.b d0
 beq.s geta830
 btst #0,d2                   * Ungerade Adressdistanz
 bne carset
geta830:
 ext.l d2
 move.l d2,d0
 add.l a2,d0                    * Zieladresse
 bsr put8x                      * Adressdistanz
 move.b #'(',(a0)+
 move.b #'P',(a0)+
 move.b #'C',(a0)+
 move.b #')',(a0)+              * d(PC)
 moveq #2,d0
 bra carres
geta84:                         * PC relativ mit Adressdistanz und Index
 move (a2),d0
 btst #8,d0
 bne carset
 ext.w d0
 ext.l d0
 add.l a2,d0                    * Zieladresse
 bsr put8x                      * Adressdistanz
 move.b #'(',(a0)+
 move.b #'P',(a0)+
 move.b #'C',(a0)+
 moveq #2,d0
 bra geta700

check1adr:                      * Adressierungsart prüfen mit verschiedenen
 lea    eatab1(pc),a2           * Tabellen
 bra.s   checkadr

check2adr:
 lea    eatab2(pc),a2           * Tabelle 2
 bra.s   checkadr

check3adr:
 lea    eatab3(pc),a2           * Tabelle 3
 bra.s   checkadr

check4adr:
 lea    eatab4(pc),a2           * Tabelle 4
 bra.s   checkadr

check5adr:
 lea    eatab5(pc),a2           * Tabelle 5
 bra.s   checkadr

check6adr:
 lea    eatab6(pc),a2           * Tabelle 6
 bra.s   checkadr

check7adr:
 lea    eatab7(pc),a2           * Tabelle 7
 bra.s   checkadr

check8adr:
 lea    eatab8(pc),a2           * Tabelle 8

checkadr:                       * a3 auf Opcode
 move (a3),d6                   * a2 Ziel für Tabelle für unerlaubten Opcode
chadr1:                         * Carry wenn falsch
 lsr #3,d6                      * Tabelle
 and #7,d6                      * DC.b Anzahl Mode-1
 move.b (a2)+,d7                * DC.b Unerlaubter Mode, unerlaubter Mode
 ext d7                         * DC.b Anzahl Reg-1
 bmi.s chadr3                   * DC.b Unerlaubtes Reg,unerlaubtes Reg
chadr2:
 cmp.b (a2)+,d6
 beq carset                     * Fehler
 dbra d7,chadr2
chadr3:
 cmp.b #%111,d6                 * PC-relative Adressierungsarten
 bne carres
 move (a3),d6
 and #7,d6
 cmp #5,d6                      * Gar nicht erlaubt
 bpl carset
 move.b (a2)+,d7
 ext d7
 bmi carres
chadr4:
 cmp.b (a2)+,d6
 beq carset                     * Fehler
 dbra d7,chadr4
 bra carres

getgroess:                      * Größe ermitteln und ausgeben
 bsr.s getgr1                   * Größe holen
 bcs carset                     * Fehler
putgroess:
 move.b #'.',(a0)+
 move.b putgrtab(pc,d0.w),(a0)+ * Zeichen B,W,L
 bra carres

getgr1:                         * Größe ermitteln
 move (a3),d0
 lsr #6,d0
 and #3,d0                      * Drei Bits bestimmen Größe
 cmp #3,d0
 beq carset                     * Fehler, 3 nicht erlaubt
 bra carres

putgrtab:
 DC.b 'BWL'
 ds 0

put2x:
 move.b #'$',(a0)+
 bra print2x

put4x:
 move.b #'$',(a0)+
 bra print4x

put8x:
 move.b #'$',(a0)+
 bra print8x

reg0:                           * d3=Bit Register/d4=Bit Da/Ad
 move.b #',',(a0)+              * a3 auf Adresse
 bra.s reg2
reg1:
 move.b #' ',(a0)+
reg2:
 move (a3),d7
 btst d4,d7                     * Daten- oder Adressregister ?
 beq.s reg3
 move.b #'A',(a0)+              * Adressregister
 bra.s dareg4
reg3:
 move.b #'D',(a0)+              * Datenregister
 bra.s dareg4

dareg0:                         * a3 zeigt auf Opcode d0 ist Bitnummer
 move.b #',',(a0)+              * Datenregisterausgabe
 bra.s dareg2
dareg1:
 move.b #' ',(a0)+
dareg2:
 move.b #'D',(a0)+
dareg3:                         * Einsprung Adressregister
 move (a3),d7
dareg4:
 lsr d3,d7
 and #7,d7                      * Nur 3 Bits bestimmen Nummer
 add.b #'0',d7                  * In ASCII wandeln
 move.b d7,(a0)+
 rts

adreg0:                         * Adressregisterausgabe
 move.b #',',(a0)+
 bra.s adreg2
adreg1:
 move.b #' ',(a0)+
adreg2:
 move.b #'A',(a0)+
 bra.s dareg3

nobefehl:                       * Gibt DC.w aus / Wenn kein Befehl
 movea.l a4,a0
 move.l #'!!! ',(a0)+           * ACHTUNG !!!
 move (a3),d0
 move.l #'DC.W',(a0)+
 move.w #' $',(a0)+
 bra print4x                     * Hexadezimalausgabe

konstante:                      * In d0 Größe/in a2 Wert
 tst d0                         * d0 ist Ergebnis Länge in Bytes
 bne.s konst1
 move.w (a2),d0
 bsr.s konstb2                  * Byte
 bcs carset
 moveq #2,d0                    * Länge
 bra carres
konst1:
 cmp #1,d0
 bne.s konst2
 move (a2),d0
 bsr.s konstw2                  * Wort
 moveq #2,d0                    * Länge
 bra carres
konst2:
 cmp #2,d0
 bne carset                     * Fehler
 move.l (a2),d0
 bsr.s konstlw2                 * Langwort
 moveq #4,d0                    * Länge
 bra carres

konstb1:                        * In d0.b Konstante
 move.b #' ',(a0)+              * Wird zerstört
konstb2:
 move.b #'#',(a0)+
 move d0,d7
 and #$ff00,d7
 bne carset                     * Kein Byte -> Fehler
 move.b #'$',(a0)+
 bsr print2x
 bra carres

konstlw0:
 move.b #',',(a0)+
 bra.s konstlw2
konstlw1:                       * In d0.l Konstante
 move.b #' ',(a0)+
konstlw2:
 move.b #'#',(a0)+
 move.b #'$',(a0)+
 bra print8x

konstw0:
 move.b #',',(a0)+
 bra.s konstw2
konstw1:                        * In d0.w Konstante
 move.b #' ',(a0)+
konstw2:
 move.b #'#',(a0)+
 move.b #'$',(a0)+
 bra print4x

eatab1:                         * Tabellen der nicht erlaubten Adresierungsarten
 DC.b 1-1
 DC.b %001                      * Dn
 DC.b 0-1

eatab2:
 DC.b 2-1
 DC.b %000                      * Dn
 DC.b %001                      * An
 DC.b 3-1
 DC.b %010                      * d(PC)
 DC.b %011                      * d(PC,Rx)
 DC.b %100                      * #

eatab3:
 DC.b 4-1
 DC.b %000                      * Dn
 DC.b %001                      * An
 DC.b %011                      * (An)+
 DC.b %100                      * -(An)
 DC.b 1-1
 DC.b %100                      * #

eatab4:
 DC.b 1-1
 DC.b %001                      * An
 DC.b 3-1
 DC.b %010                      * d(PC)
 DC.b %011                      * d(PC,Rx)
 DC.b %100                      * #

eatab5:
 DC.b 0-1
 DC.b 3-1
 DC.b %010                      * D(PC)
 DC.b %011                      * d(PC,Rx)
 DC.b %100                      * #

eatab6:
 DC.b 1-1
 DC.b %001                      * An
 DC.b 1-1
 DC.b %100                      * #

eatab7:
 DC.b 3-1
 DC.b %000                      * Dn
 DC.b %001                      * An
 DC.b %100                      * -(An)
 DC.b 1-1
 DC.b %100                      * #

eatab8:
 DC.b 3-1
 DC.b %000                      * Dn
 DC.b %001                      * An
 DC.b %011                      * (An)+
 DC.b 3-1
 DC.b %010                      * d(PC)
 DC.b %011                      * d(PC,Rx)
 DC.b %100                      * #

 DS.W 0
*******************************************************************************
*                     68000/68010 Grundprogramm speicher                      *
*                         (C) 1990 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                        Menüpunkt Speicherbereiche                           *
*******************************************************************************


getstack:                       * In a7 steht Anfangssuchadresse
 move.l a5,d0
 bsr.s getram1                  * Ram-Bereich holen
 move.l a0,d0                   * Ende des Rambereiches
 subq.l #2,d0
 and.b #$fe,d0                  * Auf geraden Wert bringen ( Zur Sicherheit )
 rts                             * Ergebnis auch in d0

                                * Ram-Bereich von a0 an suchen
                                * a0 ist Such-Anfang
                                * Ergebnis a0 = Nächste Nicht-Ram-Zelle
                                *          a1 = Erste Ram-Zelle
                                * Carry dann kein Bereich vorhanden

grenze  EQU     1024*1024*cpu-1024*cpu-1        * Obergrenze für Speicher

getram:
 move.l a0,d0
getram1:
 and.w #$fc00,d0                * Auf 1 Kbyte-Grenze bringen
 movea.l d0,a0
get1ram:
 cmpa.l #grenze,a0              *
 bhi carset                     * Wenn größer, dann Fehler
 bsr.s ramchk                   * Überprüfen, ob Ram
 bcc.s get2ram                  * Ja, Ram Anfang gefunden
 adda #$400,a0                  * Sonst
 bra.s get1ram                  * weitersuchen

get2ram:
 movea.l a0,a1                  * Erste Ram-Zelle merken
get3ram:
 cmpa.l #grenze,a0              * Noch mal Grenze testen
 bhi carres
 bsr.s ramchk                   * Ramende suchen
 bcs carres                     * Gefunden, dann Carry = 0
 adda #$400,a0                  * Sonst weitersuchen
 bra.s get3ram

ramchk:                         * Prüfen, ob Ram
 movem.l d0-d3,-(a7)            * Register retten
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
 movem.l (a0)+,d0-d3            * Speicher retten
 move.l #$5a5a0180,-(a0)        * Speicher beschreiben
 move.l #$5a01805a,-(a0)
 move.l #$01805a5a,-(a0)
 move.l #$805a5a01,-(a0)
 cmp.l #$805a5a01,(a0)          * Jetzt überprüfen, ob Werte gespeichert sind
 bne.s ramchk1                  * Nein !
 cmp.l #$01805a5a,4(a0)
 bne.s ramchk1                  * Nein !
 cmp.l #$5a01805a,8(a0)
 bne.s ramchk1                  * Nein !
 cmp.l #$5a5a0180,12(a0)
 bne.s ramchk1                  * Nein !
 movem.l d0-d3,(a0)             * OK, alle Werte gespeichert
 move (a7)+, sr                 * Staus zurück
 movem.l (a7)+,d0-d3            * Register zurück
 bra carres                     * Carry = 0
ramchk1:
 move (a7)+, sr                 * Staus zurück
 movem.l (a7)+,d0-d3            * Kein Ram
 bra carset                     * Carry = 1

romchk:                         * Testen, ob Rom
 movem.l d0-d3,-(a7)            * Register retten (Speicher nicht, da kein Ram)
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
 movem.l (a0)+,d0-d3            * Werte holen zum Vergleich
 move.l #$5a5a0180,-(a0)        * Speicher vollschreiben
 move.l #$5a01805a,-(a0)
 move.l #$01805a5a,-(a0)
 move.l #$805a5a01,-(a0)
 cmp.l (a0),d0                  * Werte müssen gleich sein, da keine
 bne.s romchk1                  * Veränderung im Eprom auftreten kann
 cmp.l 4(a0),d1
 bne.s romchk1
 cmp.l 8(a0),d2
 bne.s romchk1
 cmp.l 12(a0),d3
 bne.s romchk1                  * Werte sind gleich, also kein Ram
 cmp.l d0,d1                    * Jetzt Werte untereinander testen
 bne.s romchk0                  * Wenn gleich, dann kein Rom, da im Rom
 cmp.l d0,d2                    * normalerweise nicht 16 Werte hintereinander
 bne.s romchk0                  * gleich sind (Leeres Eprom wird nicht erkannt)
 cmp.l d0,d3
 beq.s romchk1
romchk0:
 move (a7)+, sr                 * Staus zurück
 movem.l (a7)+,d0-d3            * Ist Rom
 bra carres                     * Carry löschen
romchk1:
 move (a7)+, sr                 * Staus zurück
 movem.l (a7)+,d0-d3            * Kein Rom
 bra carset                     * Carry setzen

ausspber:                       * Speicherbereiche ausgeben
 lea spber1(pc),a0              * Überschrift
 bsr headaclr                   * ausgeben
 lea spber2(pc),a0              * Text für Arbeitsbereich
 moveq #$22,d0
 moveq #60,d1
 move #195,d2
 bsr textprint                  * Text ausgeben
 movea.l a5,a0                  * Beim Ram hinterm Grundprogramm anfangen
 bsr getram                     * Ram suchen
 move.l a1,d0                   * Anfang ausgeben
 move.l a0,d1                   * Ende merken
 lea ausbuf(a5),a0              * In ausbuf
 bsr print8x                    * Hexadezimal ausgeben
 move.b #'-',(a0)+              * Bis
 move.l d1,d0                   * Jetzt Ende ausgeben
 subq.l #1,d0                   * -1, da erste Nicht-Ram-Zelle angegeben war
 bsr print8x                    * Auch hexadezimal
 lea ausbuf(a5),a0              * ausbuf ausgeben
 moveq #$22,d0
 move #300,d1
 bsr textprint                  * Text ausgeben
 moveq #71,d1                   * Anfang X
 move #172,d2                   * Y-Pos
 clr d4                         * Mit Null beginnen
 moveq #16-1,d3                 * 16 Werte
ausspb1:
 move d4,d0                     * Wert holen
 lea ausbuf(a5),a0
 bsr print2x                    * In ASCII wandeln
 lea ausbuf(a5),a0
 moveq #$11,d0                  * Schriftgröße
 bsr textprint                  * Ausgabe
 add #28,d1                     * Neue X-Position
 addq #2,d4                     * Nächste Spalte
 dbra d3,ausspb1
 moveq #0,d3                    * Adresse
 moveq #0,d1                    * X-Pos
 move #170-8,d2                 * Jetzt erfolgt Ausgabe der Adressen an der
 moveq #16-1,d4                 * linken Seite
ausspb2:
 move.l d3,d0                   * Adresse
 lea ausbuf(a5),a0              * Ablage
 bsr print6x                    * Hexadezimal 6 Stellen
 lea ausbuf+1(a5),a0            * Aber nur 5 Stellen ausgeben
 moveq #$21,d0                  * Größe
 bsr textprint
 add.l #$1000*cpu,d3            * Nächste Adresse
 sub #10,d2                     * Y-Positon erniedrigen
 dbra d4,ausspb2                 * Schleifenende
 moveq #61,d1                   * X-Anfang
 moveq #10*2,d2                 * Y-Anfang
 move #16*28+3,d3               * Breite
 move #160*2+2,d4               * Höhe
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
 bsr gr1p5_                     * Rechteck leer
 move (a7)+, sr                 * Staus zurück
 bsr wait
 move.b #25,gdp+5*cpu.w         * Größe der Linien
 suba.l a0,a0                   * Anfangsadresse = 0
 moveq #64,d1                   * Anfangsposition X
 moveq #16-1,d5                 * 16 Bänke
ausbank:
 move #170,d2                   * Y-Anfangsposition
 moveq #$10,d0                  * Befehl Linie zeichnen
 moveq #32-1,d4                 * 32 Linien pro Bank
ausreihe:
 bsr wait
 and.b #$f0, gdp+2*cpu.w        * Linien durchgezogen
 bsr ramchk                     * für Ramtest
 bcc.s aus1reihe                * Ram, dann ausgeben
 bset.b #0,gdp+2*cpu.w          * Linien gestrichelt
 bsr romchk                     * für Romtest
 bcs.s aus3reihe                * Fehler, dann weder Ram noch Rom
aus1reihe:
 moveq #5-1,d3
aus2reihe:
 bsr moveto
 bsr cmd                        * Linie zeichnen
 subq #1,d2                     * Neue Y-Position
 dbra d3,aus2reihe
 addq #5,d2                     * d2 wieder auf alten Wert bringen
aus3reihe:
 adda #$1000,a0                 * Nächste Adresse
 subq #5,d2                     * Nächste Y-Position
 dbra d4,ausreihe
 add #28,d1                     * Nächste Bank
 dbra d5,ausbank
 bra finmenue
*******************************************************************************
*                         680xx Grundprogramm einzel                          *
*                         (C) 1990 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                         Menüpunkt Einzelschritt                             *
*******************************************************************************


einzel:                         * Einzelschrittverarbeitung mit DIS-Assembler
 btst.b #4,tracflag(a5)         * Trace nicht im Trace aufrufen
 bne carset
 lea tractxt0(pc),a0            * Überschrift ausgeben
 bsr headaclr
 lea tractxt1(pc),a0            * Befehlsübersicht
 moveq #$32,d0
 move #160,d2
 bsr centertxt                  * Überschrift
 lea tractxt2(pc),a0
 moveq #$21,d0
 moveq #5,d1
 move #140,d2
 bsr textprint                  * Befehle auflisten
 bsr getadr                     * Adresse Beginn holen
 bcs carset                     * Bei Fehler Abbruch
 move.l a7,stackmerk(a5)        * Stack merken, daher TRACE auch als Unterprogr
 or.b #%00010000,tracflag(a5)   * Trace ist jetzt an
 move.b #1,first(a5)            * Turtle erster Aufruf
 move.b #1,turdo(a5)            * Turtle down
 pea tracende(pc)               * Rücksprungadresse
*clr -(a7)                      * Bei 68010 muß der Befehl eingefügt werden !!!
 move.l d0,-(a7)                * Adresse RTE
 move sr,-(a7)                  * Statusregister merken
 bsr clrall                     * Bildschirm löschen
 clr.b tracausw(a5)             * Kein Extramodus
 clr.b trac1aus(a5)             * Kein Merker
 movem.l d0-d7/a0-a7,regsave(a5)* Alle Register merken
 bra traceb

tracein:                        * Einsprung Ausnahme-Bedingung durch TRACE-BIT
 move.l a5,-(a7)                * (a7) -> SR     2(a7) -> PC
 lea basis(pc),a5
 adda.l ramstart(pc),a5         * a5 in Ordnung bringen
 movem.l d0-d7/a0-a6,regsave(a5)* Register übergeben
 move.l (a7)+,regsave+4*13(a5)  * a5 jetzt auch ablegen
 move.l a7,regsave+4*15(a5)     * Jetzt erst a7 retten
 lea tracende(pc),a0            * Ist Ende des Programms erreicht ?
 cmpa.l 2(a7),a0
 beq tracende                   * Ja, also Ende TRACE
 tst.b tracausw(a5)             * Spezialmodus angeschaltet ?
 beq.s traceb                   * Nein, dann weiter
 cmp.b #1,tracausw(a5)          * n-Befehle ausführen
 bne.s tracea
 subq.l #1,tracmerk(a5)         * Tracmerk um Eins verringern
 bne traceok1                   * Wenn Null, dann Ende
 bra.s tracea3                   * Normal weiter
tracea:
 cmp.b #2,tracausw(a5)          * Bis Adresse ausführen
 bne.s tracea1
 move.l tracmerk(a5),d0         * Vergleich, ob
 sub.l 2(a7),d0                 * Bereich
 bpl.s tracea0
 neg.l d0                       * Nur positiver Bereich
tracea0:
 moveq #0,d1
 move tracmerk+4(a5),d1         * Bereich
 cmp.l d1,d0
 bhi traceok1                   * Bereich nicht erreicht
 bra.s tracea3                   * Normal weiter
tracea1:
 cmp.b #3,tracausw(a5)          * Ausführen bis ADRESSE & MASKE WERT annimmt
 bne.s tracea2
 movea.l tracmerk(a5),a0        * Adresse
 move.b (a0),d0                 * Maske
 and.b tracmerk+4(a5),d0
 cmp.b tracmerk+5(a5),d0        * Vergleich
 bne traceok1                   * Nein, Adresse hat nicht gewünschten Wert
 bra.s tracea3                   * Normal weiter
tracea2:
 cmp.b #4,tracausw(a5)          * Bis ENDE Unterprogramm
 bne.s traceb
 movea.l 2(a7),a0
 move (a0),d0
 cmp #$4e75,d0                  * RTS
 beq.s tracea3
 cmp #$4e73,d0                  * RTE
 beq.s tracea3
 cmp #$4e77,d0                  * RTR
 bne traceok1                   * Durchstarten, da nicht gefunden

tracea3:
 clr.b tracausw(a5)             * Spezialmodus aus, normal weiter

traceb:
 move (a7),srsave(a5)           * SR jetzt merken
 move.l 2(a7),pcsave(a5)        * PC jetzt merken
 move.l usp,a0                  * USP auch ablegen
 move.l a0,uspsave(a5)
 move.l a7,sspsave(a5)          * SSP ist a7
 lea gdp+1*cpu.w,a0             * GDP-Register retten, da zerstört
 lea gdpsave(a5),a1             * Register Null nicht retten
 bsr wait                       * Warten bis GDP fertig ist
 moveq #15-4-1,d1
tracec:
 move.b (a0),(a1)+              * Werte übertragen
 addq.l #cpu,a0
 dbra d1,tracec
                                * OK, Register gerettet
traced:                         * Status-Zeilen ausgeben
 bsr trdump                     * Alle Register / DEBUG oder DIS-ASsembler
 bcs.s tracee
 btst.b #1,tracflag(a5)         * Protokol auf Drucker ?
 beq.s tracee                   * Nein
 clr.b (a1)                     * Keine Leerzeichen mehr am Ende
 lea einbuf(a5),a0              * Ja, dann DEBUG oder DIS-Assembler ausgeben
 move.l pcsave(a5),d0           * Adresse Befehl
 bsr print8x                    * Hexadezimal ausgeben
 move #'  ',(a0)+               * Dann Leerzeichen
 clr.b (a0)                     * und Endekennung
 lea einbuf(a5),a0
 bsr prtlo                      * Auf Drucker ausgeben
 lea ausbuf(a5),a0
 bsr prtlo                      * Und Befehl auch auf Drucker ausgeben
 bsr locrlf                     * Dann Linefeed

tracee:                         * Befehlsabfrage
 bsr ki                         * Zeichen von Tastatur holen
 cmp.b #$d,d0                   * Return führt nächsten Befehl aus
 beq traceok

traceeb:                        * Bis ADRESSE + Bereich ausführen
 cmp.b #'B',d0
 bne.s traceec
 bsr wrtupd0                    * Eingabe
 movea.l a0,a4                  * Adresse merken
traceeb0:                       * Suchen bis ','
 tst.b (a4)
 beq.s traceeb1                 * Ende bei Null
 cmp.b #',',(a4)+
 bne.s traceeb0
 clr.b -1(a4)                   * Ende für ersten Wert
traceeb1:
 bsr wertmfeh                   * Ersten Wert holen
 bcs tracee                     * Ende bei Fehler
 move.l d0,tracmerk(a5)         * Adresse merken
 move.l d0,trac1mer(a5)         * Auch für WIEDERHOLEN
 clr tracmerk+4(a5)             * Bereich ist Null
 movea.l a4,a0                  * Adresse für eventuellen zweiten Wert
 bsr igbn
 tst.b (a0)
 beq.s traceeb2                 * Kein Bereich
 clr.b trac1aus(a5)            * Kein Wiederholen mehr möglich
 bsr wertmfeh                   * Bereich holen
 bcs tracee                     * Fehler
 move d0,tracmerk+4(a5)         * Bereich merken
traceeb2:
 move.b #2,tracausw(a5)         * Flag
 move.b #2,trac1aus(a5)         * Auch merken
 bra traceok                     * Durchstarten

traceec:                        * Screen löschen
 cmp.b #'C',d0
 bne.s traceed
 bsr clrall                     * Bildschirm löschen alle Seiten
 bsr trdump                     * Regdump neu ausgeben
 bra tracee

traceed:                        * TRAP/JSR direkt ausführen oder nicht
 cmp.b #'D',d0
 bne.s traceee
 bchg.b #2,tracflag(a5)         * Flag umschalten
 bsr trdump                     * Regdump neu
 bra tracee

traceee:
 cmp.b #'E',d0                  * Bis RTS/RTE/RTR
 bne.s traceef
 move.b #4,tracausw(a5)         * Code für Befehl
 move.b #4,trac1aus(a5)         * Für Wiederholen
 bra traceok

traceef:                        * Flags laden
 cmp.b #'F',d0
 bne.s traceeg
 bsr wrtupdate                  * Wert holen
 bcs tracee                     * Fehler ist Abbruch
 cmp #31,d0                     * Wert nicht neagtiv
 bhi tracee                     * und nicht größer als 31, da Flags nur 5 Bit
 move.b d0,srsave+1(a5)         * Flags abspeichern
 move.b d0,1(a7)                * Auch in Stack, damit bei RTE geladen wird
 bsr trdump                     * Regdump neu
 bra tracee

traceeg:                        * Grundprogrammroutinen aufrufen
 cmp.b #'G',d0
 bne.s traceei
 bsr wrtupdate                  * Wert holen
 bcs tracee                     * Bei Fehler Abbruch
 move d0,d1                     * Wert merken
 bpl.s traceeg1                 * Wenn Wert positiv, dann OK
 neg d1                         * Sonst positiv machen
 cmp #maxgrund,d1               * Und mit maximaler Anzahl vergleichen
 bhi tracee                     * Zu hoch, Abbruch
 cmp #21,d1                     * Trace kann nicht Trace aufrufen
 beq tracee
traceeg1:
 move.b menflag(a5),-(a7)       * Menüauswahl merken
 bsr grund                      * Aufrufen
 move.b (a7)+,menflag(a5)       * Auch wieder zurück
 bsr clrall                     * Danach wieder Bildschirm löschen
 bsr trdump                     * Regdump neu
 bra tracee

traceei:                        * Info an/aus
 cmp.b #'I',d0
 bne.s traceel
 bchg.b #0,tracflag(a5)         * Flag ändern
 bne.s *+10                     * Wenn jetzt auf Eins, dann nur ausgeben
 bsr trdump                     * Regdump neu
 bra tracee
 bsr.s traceei0                 * Sonst unten löschen
 bsr.s traceei0                 * Löschen
 bsr setpen                     * Wieder auf Schreiben
 bra tracee                      * Nächsten Befehl holen

traceei0:                       * Unten 6 Zeilen löschen
 bsr erapen                     * Auf Löschen schalten
 move.b #5,gdp.w                * X und Y auf Null
 move.b #$16,gdp+3*cpu.w        * Größe einstellen
 moveq #%1010,d0                * Kasten
 moveq #85-1,d3
traceei1:
 bsr cmd                        * Löschzeichen ausgeben
 dbra d3,traceei1
 eori.b #1,wrtpage(a5)          * Danach andere Seite
 bra aktpage                     * Da, zweimal aufgerufen, später wieder OK

traceel:                        * Extrafunktionen wiederholen
 cmp.b #'L',d0
 bne.s traceem
 move.b trac1aus(a5),tracausw(a5)       * Flag holen
 beq tracee                     * Kein Wiederholen möglich
 move.l trac1mer(a5),tracmerk(a5)       * Und Wert neu laden
 bra traceok                     * Durchstarten

traceem:                        * Tracende
 cmp.b #$1b,d0                  * <ESC> = Abbruch
 beq tracende
 cmp.b #'M',d0
 beq tracende                   * Abbruch

traceen:                        * n Befehle ausführen
 cmp.b #'N',d0
 bne.s traceep
 bsr wrtupdate                  * Anzahl holen
 bcs tracee                     * Abbruch bei Fehler
 tst.l d0                       * Wenn Null oder
 beq tracee                     * Negativ
 bmi tracee                     * dann Abbruch
 move.l d0,tracmerk(a5)         * Anzahl abspeichern
 move.l d0,trac1mer(a5)
 move.b #1,tracausw(a5)         * Flag für Befehl
 move.b #1,trac1aus(a5)
 bra traceok                     * Durchstarten

traceep:                        * PC neu laden (Achtung eventuell Stackchaos)
 cmp.b #'P',d0
 bne.s traceer
 bsr wrtupdate                  * Wert holen
 bcs tracee                     * Abbruch
 cmp.l #grenze,d0               * Maximale Speicherausbaumöglichkeit darf nicht
 bhi tracee                     * überschritten werden
 and.b #$fe,d0                  * Auf gerade Adresse bringen
 move.l d0,2(a7)                * Abspeichern für RTE
 move.l d0,pcsave(a5)           * Auch für Regdump
 bra traced                      * Regdump mit neuer Adresse

traceer:                        * Register einzeln laden
 cmp.b #'R',d0                  * Register + Nummer d0-d7/8 a0-a7
 bne tracees                    * Bei Eingabe einer 8 werden alle Register
 bsr wrtupd0                    * angezeigt
 bsr igbn
 move.b (a0)+,d0
 bsr bucheck
 move.b d0,d4                   * d4 ist Buchstabe für Register
 lea regsave(a5),a4             * Adresse in REGSAVE für Datenregister
 cmp.b #'D',d0                  * 'D' ?
 beq.s traceer0                 * Dann Datenregister ändern
 lea regsave+4*8(a5),a4         * Adresse für Adressregister
 cmp.b #'A',d0                  * 'A' ?
 bne tracee                     * Dann Adressregister ändern
traceer0:                       * d5 Tabellen-Offset
 bsr wertmfeh                   * d4 Buchstabe des Registers
 bcs tracee
 move d0,d6                     * d6 Nummer des Registers
 cmp #8,d0
 bhi tracee                     * Zu groß !
 beq.s traceer1
 bsr.s traceer3                 * Nur ein Register ändern
 bra tracee
traceer1:
 clr    d6                      * 7 Register ändern
traceer2:
 move   d6,-(a7)
 bsr.s  traceer3                * Register ändern
 move   (a7)+,d6
 addq   #1,d6
 cmp    #8,d6
 bne.s traceer2
 bra tracee                      * Ende

traceer3:
 move d6,d5
 add d5,d5
 add d5,d5                      * Nummer des Registers mal 4
 lea 0(a4,d5.w),a3              * Adresse des Registers in REGSAVE
traceer4:
 lea einbuf(a5),a0
 move.b d4,(a0)+
 move.b d6,(a0)
 add.b #'0',(a0)+
 move.w #':'*256,(a0)
 lea einbuf(a5),a0
 moveq #$11,d0
 moveq #2,d1
 move #245,d2
 bsr textaus                    * Ausgabe Registernummer mit Doppelpunkt
 move.l (a3),d0
 bsr put8x                      * Wert in Hexadezimal
 lea einbuf(a5),a0
 moveq #$11,d0
 moveq #20,d1
 moveq #12,d3
 move d4,-(a7)                  * d4 merken
 bsr readaus                    * Neuen Wert holen
 movem (a7)+,d4                 * d4 zurück
 bcs carres                     * Abbruch
 lea einbuf(a5),a0
 bsr igbn
 tst.b (a0)
 beq carres                     * Wenn nichts eingegeben wurde, dann Ende
 bsr wertmfeh                   * Wert ermitteln
 bcs.s traceer4                 * Fehler
 move.l d0,(a3)                 * Register abspeichern
 bra trdump

tracees:                        * Leseseite neu wählen
 cmp.b #'S',d0
 bne.s traceet
 bsr wrtupdate                  * Seite holen
 bcs tracee
 cmp.b #3,d0                    * Muß zwischen 0 und drei liegen
 bhi tracee
 clr.b flip(a5)                 * Keine Seitenumschaltung mehr
 clr.b flip1(a5)
 move.b d0,viewpage(a5)         * Und einstellen
 bsr aktpage
 bsr trdump                     * Regdump neu
 bra tracee

traceet:                        * Tabellieren auf Drucker (an/aus)
 cmp.b #'T',d0
 bne.s traceew
 bchg.b #1,tracflag(a5)         * Umschalten
 bsr trdump                     * Regdump neu
 bra tracee

traceew:                        * Weiter bis ADRESSE & MASKE WERT enthält
 cmp.b #'W',d0
 bne tracee
 bsr wrtupdate                  * Adresse holen
 bcs tracee                     * Bei Fehler Abbruch
 clr.b trac1aus(a5)             * Kein Wiederholen mehr möglich
 move.l d0,tracmerk(a5)         * Merken
 move.l d0,trac1mer(a5)
 bsr wrtupdate                  * Maske holen
 bcs tracee
 move.b d0,tracmerk+4(a5)       * Auch merken
 bsr wrtupdate                  * Wert holen
 bcs tracee
 move.b d0,tracmerk+5(a5)       * Auch merken
 move.b #3,tracausw(a5)         * Nummer des Befehls
 move.b #3,trac1aus(a5)

traceok:                        * Befehl ausführen
 lea gdp+1*cpu.w,a0             * GDP-Register zurück
 lea gdpsave(a5),a1
 bsr wait                       * Warten bis GDP fertig ist
 moveq #15-4-1,d1
traceok0:
 move.b (a1)+,(a0)              * Werte übertragen
 addq.l #cpu,a0
 dbra d1,traceok0
traceok1:
 btst.b #2,tracflag(a5)
 beq.s traceok2                 * TRAP/JSR geschlossen ausführen ?
 movea.l 2(a7),a0               * Ja, geschlossen ausführen
 move (a0),d0
 cmp #$4eb8,d0
 beq.s jsrkex                   * JSR.w Befehl
 cmp #$4eb9,d0
 beq.s jsrlex                   * JSR.l Befehl
 and #$fff0,d0
 cmp #$4e40,d0
 beq.s trapex                   * Trap
traceok2:
 or #$8000,(a7)                 * Tracflag neu setzen
 movem.l regsave(a5),d0-d7/a0-a6 * Register zurück
 rte                             * Zurück und nächsten Befehl ausführen

jsrkex:                         * JSR.w als Ganzes ausführen
 move.l (a0),modber(a5)
 move #$4e75,modber+4(a5)
 addq.l #4,2(a7)                * Befehl + RTS abgespeichert PC erhöht
 bra.s trapex1

jsrlex:                         * JSR.l als Ganzes ausführen
 move (a0),modber(a5)
 move.l 2(a0),modber+2(a5)
 move #$4e75,modber+6(a5)       * Befehl + RTS abgespeichert
 addq.l #6,2(a7)                * PC erhöht
 bra.s trapex1

trapex:                         * Trap als Ganzes ausführen
 move (a0),modber(a5)
 move #$4e75,modber+2(a5)
 addq.l #2,2(a7)                * Befehl + RTS abgespeichert PC erhöht
trapex1:
 move (a7),d0
 and #$3fff,d0
 move d0,sr                     * Altes Statusregister ohne TRACE
 pea jsrtrapex(pc)
 pea modber(a5)                 * Adresse der Befehlsausführung
 movem.l regsave(a5),d0-d7/a0-a6 * Register zurück
 rts

jsrtrapex:
 movem.w d0,-(a7)
 move sr,d0
 move.b d0,3(a7)                * Flags wie am Ende des Unterprogramms
 move.w (a7)+,d0
 bra tracein                     * Einsprung wie bei Exception

tracende:                       * Ende TRACE
 bclr.b #4,tracflag(a5)         * Trace aus
 movea.l stackmerk(a5),a7       * Stack zurück, falls mittendrin abgebrochen
 move.b #1,first(a5)            * Turtle auf first
 move.b #1,turdo(a5)            * Und down
 clr.b flip(a5)                 * Keine Seitenumschaltung
 clr.b flip1(a5)
 clr oldsize(a5)                * Keine alte Figur
 clr.b xormode(a5)              * XORMODE muß aus
 clr.b gdpscroll(a5)            * Merken
 btst.b #0,ioflag(a5)
 beq erakreuz
 clr.b page1.w                  * Bei neuer GDP Scroll ausschalten
 bra erakreuz                    * Kreuz sicherheitshalber aus

wrtupdate:                      * Wert nach d0 holen für Trace
 bsr.s wrtupd0
 bra wertmfeh                    * Wert berechnen mit Fehlerbehandlung

wrtupd0:
 move.b viewpage(a5),d0
 lsl.b #2,d0
 or.b viewpage(a5),d0
 lsl.b #4,d0
 bsr setpage                    * Leseseite = Schreibseite setzen
 lea einbuf(a5),a0
 moveq #$11,d0
 moveq #2,d1
 move #255-10,d2
 moveq #20,d3
 bsr textein                    * Text von der Tastatur holen
 bsr aktpage                    * Alte Seite einstellen
 lea einbuf(a5),a0
 rts

trdump:
 btst.b #0,tracflag(a5)
 beq carset                     * Kein Regdump
regdump:                        * Ausgabe aller Register und DEBUG
 lea ausbuf(a5),a0
 move.l #'Reg:',(a0)+           * Erste Zeile herstellen
 moveq #'0',d0
 moveq #8-1,d1
regdump0:
 move #'  ',(a0)+
 move.b d0,(a0)+                * Nummer des Registers 0-7
 addq.b #1,d0
 move.b #' ',(a0)+
 move #'  ',(a0)+
 move.l #'    ',(a0)+
 dbra d1,regdump0
 clr.b (a0)                     * Endekennung
 btst.b #4,tracflag(a5)
 beq.s regdump2                 * Kein Trace, dann weiter
 btst.b #2,tracflag(a5)         * TRAP/JSR direkt ausführen ?
 bne.s regdump1                 * Nein, dann weiter
 move.b #'D',-1(a0)             * Kennung, daß direkt ausgeführt wird
regdump1:
 btst.b #1,tracflag(a5)         * Protokol auf Drucker an ?
 beq.s regdump2                 * Nein, dann weiter
 move.l #'List',-6(a0)          * Kennung, daß Protokol an ist
regdump2:
 lea ausbuf(a5),a0
 moveq #$11,d0
 moveq #0,d1
 moveq #40,d2
 bsr textaus                    * Oberste Zeile ausgeben
 eori.b #1,wrtpage(a5)
 bsr aktpage                    * Andere Seite
 moveq #$11,d0
 bsr textaus                    * Auch dort
 lea ausbuf(a5),a0
 move.l #'Dn :',(a0)+           * Alle Datenregister
 lea regsave(a5),a1             * Dort liegen sie
 moveq #8-1,d1                  * 8 gibt es
regdump3:
 move #'  ',(a0)+               * Dazwischen Leerraum
 move.l (a1)+,d0                * Wert holen / liegt in regsave
 bsr print8x                    * Hexadezimal ausgeben
 dbra d1,regdump3
 addq.l #2,a0
 move.l #'An :',(a0)+           * Jetzt Adressregister
 moveq #8-1,d1                  * Auch 8
regdump4:
 move #'  ',(a0)+
 move.l (a1)+,d0
 bsr print8x
 dbra d1,regdump4
 addq.l #2,a0
 move.l #'SR :',(a0)+           * Statusregister
 move.w #'  ',(a0)+
 move srsave(a5),d0
 move d0,d1
 bsr print16b                   * 16 Stellen binär ausgeben
 move.b #'-',-15(a0)            * Unbenutzte Bits streichen
 move.b #'-',-13(a0)            * ist übersichtlicher
 move.b #'-',-12(a0)
 move #'--',-8(a0)
 move.b #'-',-6(a0)
 lea flags(pc),a2               * Gesetzte Flags als Buchstaben ausgeben
 lea 1(a0),a1                   * Zieladresse
 move.l #'    ',(a0)+
 move.l #'   U',(a0)+
 moveq #5-1,d0                  * 5 Flags gibt es
regdump5:
 btst d0,d1                     * Flag prüfen, ob gesetzt
 beq.s regd5a
 move.b (a2),(a1)+              * Gesetzt, also ausgeben
regd5a:
 addq.l #1,a2                   * Nächster Buchstabe
 dbra d0,regdump5                * Nächstes Bit
 move.l #'SP :',(a0)+           * Jetzt USP
 move.w #'  ',(a0)+
 move.l uspsave(a5),d0
 bsr print8x                    * Hexadezimal 8 Stellen
 move.l #'    ',(a0)+           * Leerraum
 move.l #' SSP',(a0)+
 move.l #' :  ',(a0)+
 move.l Sspsave(a5),d0          * Jetzt SSP
 bsr print8x                    * Auch 8 Stellen hexadezimal
 move.l #'    ',(a0)+           * Leerraum
 move.l #'  PC',(a0)+
 move.l #' :  ',(a0)+           * Jetzt PC
 move.l pcsave(a5),d0
 bsr print8x                    * 8 Stellen hexadezimal
 moveq #2-1,d3                  * Alles auf zwei Seiten ausgeben
regdump6:
 lea ausbuf(a5),a0              * Zweite Zeile
 moveq #$11,d0
 moveq #0,d1
 moveq #30,d2
 bsr textaus
 lea ausbuf+86(a5),a0           * Dritte Zeile
 moveq #20,d2
 bsr textaus
 lea ausbuf+172(a5),a0          * Vierte Zeile
 moveq #10,d2
 bsr textaus
 eori.b #1,wrtpage(a5)          * Andere Seite
 bsr aktpage
 dbra d3,regdump6
regdin:                         * Einsprung
 tst.b debug(a5)                * Debug an ?
 beq.s nodebugi                 * Nein, dann DIS-Assembler
 movea.l debugst(a5),a0         * Anfangsadresse
 movea.l pcsave(a5),a1          * Befehlsadresse
regdump7:
 move.l (a0),d0
 beq.s nodebugi                 * Ende der Debugtabelle erreicht
 cmp.l a1,d0                    * Stimmt Adresse
 beq.s regdump8                 * Ja, stimmt
 addq.l #8,a0                   * Nein, Tabellenpointer erhöhen
 bra.s regdump7                  * Weitersuchen

flags:
 DC.b 'XNZVC',0                 * Flags des Statusregister

regdump8:                       * Befehl in der Tabelle gefunden
 movea.l 4(a0),a1               * Adresse Text holen
 lea ausbuf(a5),a0              * In ausbuf ablegen
 moveq #85-1,d1                 * Maximal 85 Zeichen
regdump9:
 move.b (a1)+,d0
 beq.s nodebug2                 * Null ist Ende
 cmp.b #$d,d0
 beq.s nodebug2                 * $d auch
 cmp.b #$a,d0
 beq.s regdump9                 * $a ignorieren
 move.b d0,(a0)+                * Buchstaben ablegen
 dbra d1,regdump9                * Nächsten holen
 movea.l a0,a1                  * Merken für Druckerausgabe
 bra.s nodebugfi                 * Befehlstext ausgeben

nodebugi:                       * Wenn kein Debug, dann Disassembler
 movea.l pcsave(a5),a3          * Adresse des Befehls
 bsr disass                     * Dis-Assemblieren
nodebug0:
 lea einbuf(a5),a1              * In einbuf steht Dis-Assemblierter Befehl
 lea ausbuf(a5),a0              * Dort muß er hin
 moveq #85-1,d1
nodebug1:
 move.b (a1)+,(a0)+             * übertragen bis Null erreicht
 dbeq d1,nodebug1
 subq.l #1,a0
nodebug2:
 movea.l a0,a1                  * Adresse merken für Druckerausgabe
 tst d1
 bmi.s nodebugfi                * Ende, wenn Zeile voll
nodebug3:
 move.b #' ',(a0)+              * Rest mit Leerzeichen auffüllen
 dbra d1,nodebug3
nodebugfi:                      * Dis-Assembler oder DEBUG ausgeben
 clr.b (a0)                     * Endekennung
 lea ausbuf(a5),a0              * Dort steht Text
 moveq #$11,d0
 moveq #0,d1
 moveq #0,d2
 bsr textaus                    * Ausgeben
 eori.b #1,wrtpage(a5)
 bsr aktpage                    * Andere Seite
 moveq #$11,d0
 bsr textaus                    * Auch dort ausgeben
 btst.b #4,tracflag(a5)
 beq carres                     * Kein Trace, dann Ende
 btst.b #1,tracflag(a5)         * Protokol auf Drucker ?
 beq carres                     * Nein
 clr.b (a1)                     * Keine Leerzeichen mehr am Ende
 lea einbuf(a5),a0              * Ja, dann DEBUG oder DIS-Assembler ausgeben
 move.l pcsave(a5),d0           * Adresse Befehl
 bsr print8x                    * Hexadezimal ausgeben
 move #'  ',(a0)+               * Dann Leerzeichen
 clr.b (a0)                     * und Endekennung
 lea einbuf(a5),a0
 bsr prtlo                      * Auf Drucker ausgeben
 lea ausbuf(a5),a0
 bsr prtlo                      * Und Befehl auch auf Drucker ausgeben
 bsr locrlf                     * Dann Linefeed
 bra carres                      * Ausgabe erfolgte
*******************************************************************************
*                         680xx Grundprogramm portio                          *
*                         (C) 1990 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                     Menüpunkte IO-Lesen / IO-Setzen                         *
*******************************************************************************


ioread:                         * Wert von IO-Port lesen
 lea iomsg(pc),a0
 bsr headaclr                   * Überschrift
 lea io1msg(pc),a0
 moveq #$33,d0
 moveq #10,d2
 bsr centertxt                  * Befehle
 bsr getadr                     * Adresse holen
 bcs carset                     * Fehler
 tst.l d0
 bmi.s io1rda                   * negativer Wert
 cmp.l #256, d0
 bge.s io1rda                   * Adresse ist größer 255
 or.l #$ffffff00, d0
 move #cpu, d1
 lsr #1, d1                     * CPU-Wert/2
 beq.s io1rda                   * 0 = 68008
 lsl.l d1, d0                   * Adresse mit CPU-Wert multiplizieren
io1rda:
 movea.l d0,a1                  * Adresse merken
io1rd:
 bsr.s ioprint                  * Ausgabe des Wertes
 bsr ki                         * Zeichen von Tastatur holen
 cmp.b #'D',d0
 bne.s io2rd
io11rd:                         * Dauernd ausgeben
 bsr sync                       * Mit 20 ms Abstand, damit Wert nicht flimmert
 beq.s io11rd
 bsr.s ioprint                  * Wert ausgeben
 bsr csts                       * Auf Zeichen von Tastatur warten
 beq.s io11rd                   * OK, kein Zeichen, also weiter ausgeben
 bsr ki                         * Sonst Zeichen holen
 cmp.b #$1b,d0                  * <ESC> = Ende
 beq carres
 cmp.b #'M',d0                  * 'M' = Ende
 beq carres
 cmp.b #'S',d0                  * 'S' = Stop
 beq.s io1rd
 cmp.b #'R',d0                  * 'R' = Neue Adresse eingeben
 beq.s ioread
 bra.s io11rd                   * Sonst weiter ausgeben

io2rd:
 cmp.b #$1b,d0                  * <ESC> = Ende
 beq carres
 cmp.b #'M',d0                  * 'M' = Ende
 beq carres
 cmp.b #'R',d0                  * 'R' = Adresse neu eingeben
 beq ioread
 bra.s io1rd                    * Auf nächstes Zeichen warten

ioprint:                        * IO-Wert ausgeben
 lea ausbuf(a5),a0
 move.b (a1),d0
 bsr print2x                    * Hexadezimal ausgeben
 lea ausbuf(a5),a0
 moveq #$22,d0
 move #224,d1
 move #135,d2
 bsr textaus
 lea ausbuf(a5),a0
 move.b (a1),d0
 bsr print4d                    * Dezimal ausgeben
 move.b #' ',(a0)+
 move.b #' ',(a0)+              * Leerzeichen, damit bei weniger Stellen
 clr.b (a0)                     * gelöscht wird
 lea ausbuf(a5),a0
 moveq #$22,d0
 move #150,d1
 bsr textaus
 lea ausbuf(a5),a0
 move.b (a1),d0
 bsr print8b                    * Und binär ausgeben
 lea ausbuf(a5),a0
 moveq #$22,d0
 moveq #100,d2
 bra textaus

iowrite:                        * Wert an IO-Port ausgeben
 lea iopmsg(pc),a0
 bsr headaclr                   * Überschrift
 bsr getadr                     * Adresse holen
 bcs carset                     * Fehler
 tst.l d0
 bmi.s io1wr                    * negativer Wert
 cmp.l #256, d0
 bge.s io1wr
 or.l #$ffffff00, d0
 move #cpu, d1
 lsr #1, d1                     * CPU-Wert/2
 beq.s io1wr                    * 0 = 68008
 lsl.l d1, d0                   * Adresse mit CPU-Wert multiplizieren
io1wr:
 movea.l d0,a3                  * Adresse merken
 lea datamsg(pc),a0
 moveq #$22,d0
 moveq #20,d1
 move #150,d2
 bsr textprint                  * Text ausgeben 'DATA'
 lea einbuf(a5),a0
 moveq #90,d1
 moveq #30,d3
 bsr textein                    * Auszugebenden Wert holen
 bcs carset                     * Abbruch
 lea einbuf(a5),a0
 bsr wertmfeh                   * Wert berechnen
 bcs carset                     * Fehler
 move.b d0,(a3)                 * Wert ausgeben
 lea iop1msg(pc),a0
 moveq #$33,d0
 moveq #20,d2
 bsr centertxt                  * Befehle
iopw1:
 bsr ki                         * Auf Zeichen von Tastatur warten
 cmp.b #'R',d0                  * 'R' = neue Adresse eingeben
 beq.s iowrite
 cmp.b #$1b,d0                  * <ESC> = Ende
 beq.s iopw2
 cmp.b #'M',d0                  * 'M' = Ende
 bne.s iopw1
iopw2:
  rts
*******************************************************************************
*                      68000/68010 Grundprogramm promer                       *
*                         (C) 1990 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                             Menüpunkt Promer                                *
*******************************************************************************


promein:                        * Eprom und Karte auswählen
 movea.l a0,a1                  * a0 = Überschrift
 bsr headaclr                   * Überschrift ausgeben
 lea txtpein(pc),a0
 moveq #$21,d0
 moveq #20,d1
 move #203,d2
 bsr textprint                  * Auswahltext
 clr d3
 move.b akteprom(a5),d3
 muls #19,d3
 lea 4(a0,d3.w),a0              * Text für voreingestelltes Eprom
 moveq #68,d1
 moveq #23,d2
 bsr setprt                     * Voreinstellung für Textausgabe
promein0:
 move.b (a0)+,d0
 cmp.b #10,d0                   * Bis zum Linefeed ausgeben
 beq.s promein1
 bsr cmdput                     * Zeichen ausgeben
 bra.s promein0
promein1:
 lea einbuf(a5),a0
 moveq #$21,d0
 moveq #20,d1
 moveq #3,d2
 moveq #1,d3
 bsr textein                    * Einen Buchstaben lesen
 bcs carset                     * Abbruch
 move.b d5,d0
 bsr namecheck                  * In Großbuchstaben
 cmp.b #'Z',d0
 beq carset                     * 'Z' = Zurück
 cmp.b #'P',d0
 beq.s promein2                 * Alte Eprom-Einstellung
 sub.b #'A',d0                  * Muß zwischen
 bmi.s promein1                 * 0 und 14 liegen
 cmp.b #'O'-'A',d0
 bhi.s promein1
 move.b d0,akteprom(a5)         * Ergebnis 0 bis 14
promein2:
 bsr getpadr                    * a4 ist Adresse Leseroutine, Promer-Init OK
 movea.l a1,a0
 bsr headaclr                   * Nochmal Überschrift
promein3:                       * Einsprung bei falschen Adressen
 lea txtp3(pc),a0
 bsr get3par                    * 3 Werte lesen
 bcs carset
 lea einbuf(a5),a0
 bsr wertmfeh                   * Letzten Wert berechnen
 bcs carset                     * Fehler
 move.l d0,d5                   * d5 = Dritter Wert
promein4:
 moveq #$22,d0
 move #150,d1
 moveq #120,d2
 moveq #28,d3
 lea einbuf(a5),a0
 move #(cpu+$30)*256,(a0)       * Voreinstellung für CPU (1,2,4)
 move.l d5,-(a7)
 bsr readaus                    * Abstand der Bytes holen
 movem.l (a7)+,d5               * d5 nicht zerstören
 bcs carset                     * Abbruch
 lea einbuf(a5),a0
 bsr wertmfeh                   * Wert ermitteln
 bcs carset                     * Fehler
 move.l d0,d4
 beq.s promein4                 * Der Wert muß
 cmp #4,d4                      * 1, 2 oder 4 sein
 bhi.s promein4                 * Zu groß
 cmp #3,d4
 beq.s promein4                 * 3 ist nicht erlaubt
 moveq #0,d0                    * d4 ist jetzt Abstand der Bytes
 move.b akteprom(a5),d0
 move.b promtab0(pc,d0.w),d0    * Höchstes Byte des Eproms
 lsl.w #8,d0
 lsl.l #2,d0                    * Mal 1024
 subq.l #1,d0                   * -1, damit ist höchstes Bit markiert
 bra carres

promtab0:                       * Tabelle der Längen der Eproms
 DC.b 2,4,8                     * 2716,2732,2764
 DC.b 2,4,8                     * 2716,2732,2764
 DC.b 2,4,8,8,16,16,32,64,128   * 2716,2732,2764,2764,27128,27128,27256,27512
                                * 27010

promtab1:                       * Werte für Initialisierung beim Promer2
 DC.b $28,$90,$00,$00,$90,$90   * 2716
 DC.b $28,$80,$90               * Werte fürs Lesen
 DC.b $20,$90,$40,$40,$90,$90   * 2732
 DC.b $20,$80,$90
 DC.b $c0,$d2,$64,$60,$92,$92   * 2764a
 DC.b $c0,$82,$92
 DC.b $c0,$d2,$64,$60,$92,$92   * 2764b
 DC.b $c0,$82,$92
 DC.b $c0,$d2,$64,$60,$92,$92   * 27128a
 DC.b $c0,$82,$92
 DC.b $c0,$d2,$64,$60,$92,$92   * 27128b
 DC.b $c0,$82,$92
 DC.b $80,$d2,$64,$60,$92,$92   * 27256
 DC.b $80,$82,$92
 DC.b $00,$d2,$64,$60,$92,$92   * 27512
 DC.b $00,$82,$92
 DC.b $00,$fc,$60,$60,$dc,$9c   * 27010
 DC.b $00,$8c,$9c
 ds 0

getpadr:                        * Adresse für Lesen auswählen und Spannungen
 moveq #0,d0                    * sowie Werte für Lesen einstellen, wenn Promer2
 move.b akteprom(a5),d0
 subq #6,d0
 bpl.s getpadr0                 * OK
 move.b #%01000000,proma2.w     * Neutral stellen, wenn Promer
 lea getprom(pc),a4             * Adresse Promer-Routine fürs Lesen
 rts
getpadr0:                       * Promer2
 mulu #9,d0
 lea promtab1(pc,d0.w),a3       * Adresse in der Tabelle
 move.b (a3)+,proma3.w          * Jetzt alle Werte übertragen (Adresse $83)
 move.b (a3)+,proma4.w          * $84
 move.b (a3)+,proma5.w          * $85
 move.b (a3)+,proma5.w          * $85
 move.b (a3)+,proma4.w          * $84
 move.b (a3)+,proma4.w          * $84
 lea getprom2(pc),a4            * Adresse Leseroutine
 rts                             * a3 ist Zeiger auf Tabelle für Lesewerte

getprom:                        * d5.l ist Adresse (wird um 1 erhöht)
 move.b d5,proma1.w             * d0.b ist Ergebnis Wert
 move d5,d0
 lsr #8,d0
 or.b #%01000000,d0             * Neutral lassen
 move.b d0,proma2.w             * 2-tes Byte der Adresse
 addq.l #1,d5                   * Adresse erhöhen
 move.b promd.w,d0              * Wert nach d0.b
 rts

getprom2:                       * a3 = Adresse in Tabelle, d3 = Adresse im Eprom
 move.b d5,proma2.w             * Ergebnis d0.b = Wert
 move.l d5,d0
 lsr #8,d0
 or.b (a3)+,d0                  * Erstes Byte
 move.b d0,proma3.w             * Bits 8 bis 15 und eventuelle Spannungen
 swap d0
 or.b (a3)+,d0                  * Zweites Byte
 move.b d0,proma4.w             * Bits 16 bis 23 und eventuelle Spannungen
 addq.l #1,d5                   * Nächste Adresse
 nop                            * Sonst zu schnell
 move.b promd.w,d0              * Byte holen
 move.b (a3),proma4.w           * Neutral stellen
 subq.l #2,a3                   * Alte Adresse a3
 rts

promread:                       * Eprom lesen
 lea txtp2(pc),a0
 bsr promein                    * Eprom und Karte auswählen
 bcs carset                     * Ende
promr0:
 cmp.l d0,d6
 bhi.s promr1                   * Anfangsadresse falsch
 cmp.l d0,d7
 bls.s promr2                   * Endadresse richtig
promr1:
 bsr promein3                   * Eine Adresse falsch, deshalb neue Werte
 bcc.s promr0
 bra carset
promr2:
 movea.l d5,a0                  * Ziel nach a0
 move.l d6,d5                   * Quelle nach d5
promr3:
 jsr (a4)
 move.b d0,(a0)                 * Wert aus Eprom an Adresse geben
 adda.l d4,a0                   * Nächstes Byte
 cmp.l d5,d7                    * Bis Ende erreicht
 bpl.s promr3                   * Schleife fo rtsetzen
 bra carres                      * OK

promtab2:                       * Werte für Promer2 beim Schreiben
 DC.b $10,$10,$81,$81,$10       * 2716
 DC.b 02,$28,$00,$10,$40,70,195+1,$00,$40,$80,$10,$90,00
 DC.b $50,$50,$b0,$b0,$50       * 2732
 DC.b 02,$20,$00,$50,$40,70,195+1,$00,$40,$90,$40,$d0,00
 DC.b $52,$52,$a4,$a6,$12       * 2764a
 DC.b 29,$c0,$40,$12,$00,217,3+1,$40,$00,$80,$10,$90,05
 DC.b $52,$52,$e4,$e6,$12       * 2764b
 DC.b 29,$c0,$40,$12,$00,217,3+1,$40,$00,$80,$10,$90,05
 DC.b $52,$52,$a4,$a6,$12       * 27128a
 DC.b 29,$c0,$40,$12,$00,217,3+1,$40,$00,$80,$10,$90,05
 DC.b $52,$52,$e4,$e6,$12       * 27128b
 DC.b 29,$c0,$40,$12,$00,229,1+1,$40,$00,$80,$10,$90,06
 DC.b $52,$52,$e4,$e6,$52       * 27256
 DC.b 29,$80,$00,$52,$40,91,0+1,$00,$40,$90,$00,$90,07
 DC.b $52,$52,$e4,$f4,$52       * 27512
 DC.b 29,$00,$00,$52,$40,91,0+1,$00,$40,$10,$c0,$d0,07
 DC.b $5c,$7c,$e8,$e8,$3c       * 27010
 DC.b 29,$00,$00,$3c,$04,91,0+1,$00,$04,$80,$10,$90,07
 ds 0

putpadr:
 lea proma1.w,a2                * Schreibadresse Low-Byte (Promer)
 lea proma2.w,a3                * Schreibadresse High-Byte (Promer)
 moveq #0,d0
 move.b akteprom(a5),d0         * Eprom-Typ holen
 subq #3,d0
 bpl.s putpadr0
 lea putproml(pc),a4            * Promer langsam
 rts
putpadr0:
 subq #3,d0
 bpl.s putpadr1
 lea putproms(pc),a4            * Promer schnell
 rts
putpadr1:
 mulu #18,d0
 lea promtab2(pc),a3
 adda d0,a3                     * Adresse der Epromdaten
 move.b (a3)+,proma4.w          * $84
 move.b (a3)+,proma4.w          * $84
 bsr wawa                       * Mindestens 0.3 ms warten
 move.b (a3)+,proma5.w          * $85
 bsr wawa                       * Mindestens 0.3 ms warten
 move.b (a3)+,proma5.w          * $85
 move.b (a3)+,proma4.w          * $84
 lea putprom2(pc),a4            * Promer2
 move.b #$b0,proma7.w           * Steuerwort Timer ($87)
 rts
                                * Promer langsam
putproml:                       * d5 ist Adresse, d3 ist Wert
 move.b d3,promd.w              * a2, a3 sind Adressen Promer
 move d5,d2
 move.b d2,(a2)                 * Low Byte Adresse
 lsr #8,d2
 tas.b d2
 move.b d2,(a3)                 * High Byte Adresse
 or.b #%00100000,d2
 move.b d2,(a3)                 * Triggern
 and.b #%11011111,d2
 move.b d2,(a3)
 moveq #3-1,d1                  * 3*20 ms = 60 ms warten
putprl0:
 bsr sync                       * 20 ms warten
 beq.s putprl0
 dbra d1,putprl0
 and.b #%00011111,d2
 move.b d2,(a3)                 * Ohne Spannung
 nop                            * Sonst zu schnell
 cmp.b promd.w,d3               * Vergleichen, ob Wert richtig gebrannt ist
 beq carres
 bra carset
                                * Promer schnell
putproms:                       * d5 ist Adresse, d3 ist Wert
 moveq #29,d6                   * a2, a3 sind Adressen Promer
putprs0:
 move.b d3,promd.w              * Wert an Promer
 move d5,d1
 move.b d1,(a2)                 * Untere 8 Bit
 lsr #8,d1
putprs1:
 bsr.s putprs4                  * Programmierimpuls
 bcc.s putprs2
 dbra d6,putprs1                 * Durchgangszähler
 bra carset                      * Fehler !!
putprs2:
 moveq #6-1,d6                  * 5 Sicherheitsimpulse
putprs3:
 bsr.s putprs4                  * Impuls
 bcs carset                     * Doch noch Fehler !!
 dbra d6,putprs3
 bra carres                      * OK

putprs4:
 tas.b d1                       * Vorderstes Bit auf 1 setzen
 move.b d1,(a3)                 * Adresse übergeben
 or.b #%00100000,d1
 move.b d1,(a3)                 * Triggern
 and.b #%11011111,d1
 move.b d1,(a3)
putprs5:
 btst.b #0,(a2)                 * Warten bis Ende des Impuls
 bne.s putprs5
 and.b #%00011111,d1
 move.b d1,(a3)                 * Neutral stellen
 nop                            * Sonst zu schnell
 cmp.b promd.w,d3
 beq carres                     * OK
 bra carset

putprom2:                       * d5 = Adresse, d3.b = Wert, a3 = Tabelle
 movea.l a3,a2                  * a3 nicht zerstören
 moveq #0,d6
 move.b (a2)+,d6                * Maximale Schleifendurchgänge
 move.b d3,promd.w              * Zu programmierendes Byte
 move.l d5,d1                   * Low-Byte in d5
 swap d1                        * High-Byte in d1
 move.l d5,d2
 lsr #8,d2                      * Mid-Byte in d2
 move.b d5,proma2.w             * Low-Byte einstellen ($82)
 or.b (a2)+,d2
 move.b d2,proma3.w             * Mid-Byte einstellen ($83)
 bsr putp2wait                  * Etwas warten
putpr2a:                        * Programmierschleife
 bsr.s putpr2d                  * Programmierimpuls
 bcc.s putpr2b                  * OK, weiter
 dbra d6,putpr2a
 bra carset                      * Fehler
putpr2b:
 moveq #0,d6
 move.b 12(a3),d6               * Anzahl der Sicherheitsimpulse
 beq carres                     * Bei 2716 und 2732 keine Sicherheitsimpulse
putpr2c:
 bsr.s putpr2d                  * Impuls
 bcs carset                     * Doch noch Fehler
 dbra d6,putpr2c
 bra carres                      * OK

putpr2d:                        * Eigentlicher Impuls
 move.b (a2)+,d0
 eor.b d0,d2
 move.b d2,proma3.w             * Nochmal Mid-Byte ($83)
 or.b (a2)+,d1
 move.b d1,proma4.w             * High-Byte ($84)
 move.b (a2)+,d0
 move.b (a2)+,proma6.w          * Low-Byte Zähler ($86)
 eor.b d0,d1                    * Befehl hier, wegen Geschwindigkeit
 move.b (a2)+,proma6.w          * High-Byte Zähler $(86)
 move.b d1,proma4.w             * Nochmal High-Byte ($84)
 move.b (a2)+,d0
 eor.b d0,d2                    * Mid-Byte schon fertig, dadurch schneller, wenn
putpr2e:                        * Zeit um ist
 move.b #$80,proma7.w           * Zählerstand speichern
 tst.b proma6.w                 * Low-Byte wegwerfen
 tst.b proma6.w                 * Nur High-Byte lesen. Wenn Null, dann Zeit
 bne.s putpr2e                  * abgelaufen, da 256 us addiert wurden. So wird
                                * auf jeden Fall der Nullpunkt erkannt
 move.b d2,proma3.w             * Mid-Byte auf $83 (Bei einigen Ende Pr-Impuls)
 bsr.s putp2wait                * Etwas warten
 move.b (a2)+,d0
 eor.b d0,d1
 move.b d1,proma4.w             * High-Byte ($84) (Beim Rest hier Ende Impuls)
 bsr.s putp2wait                * Etwas warten
 move.b (a2)+,d0
 eor.b d0,d1
 move.b d1,proma4.w             * High-Byte
 bsr.s putp2wait                * Warten
 move.b (a2)+,d0
 eor.b d0,d1
 move.b d1,proma4.w             * High-Byte
 move.b (a2),d0
 eor.b d0,d1                    * High-Byte vorbereiten
 suba #9,a2                     * Alte Adresse für eventuellen neuen Durchgang
 bsr.s putp2wait                * Etwas warten
 cmp.b promd.w,d3               * Vergleichen, ob gebrannt
 sne.b d0                       * d0 danach setzen
 move.b d1,proma4.w             * High-Byte
 tst.b d0
 beq carres                     * OK
 bra carset                      * Fehler

putp2wait:                      * Ca. 2 us warten (Mit Aufruf und RTS)
 moveq #1,d0
putp2w0:
 dbra d0,putp2w0
 rts

promwrite:                      * Eprom programmieren
 lea txtp1(pc),a0
 bsr promein                    * Auswahl Eprom und Karte
 bcs carset
promw0:
 cmp.l d0,d5
 bhi.s promw1                   * Zieladresse zu groß
 sub.l d6,d7                    * Anzahl Bytes
 move.l d4,d1
 lsr.l #1,d1
 lsr.l d1,d7                    * Anzahl zu schreibender Bytes  
 add.l d5,d7                    * Anfangsadresse dazu
 cmp.l d0,d7
 bls.s promw2                   * Bereich ist im Eprom
promw1:
 bsr promein3                   * Nochmal Werte lesen
 bcc.s promw0
 bra carset
promw2:
 movea.l d6,a1                  * Quelladresse
 movem.l d5/a1,-(a7)            * Merken für später
promw3:
 jsr (a4)                       * Ein Byte holen und Adresse erhöhen
 cmp.b #$ff,d0
 beq.s promw4                   * Wenn $FF, dann OK
 lea txtp4(pc),a0
 moveq #$22,d0
 moveq #95,d2
 bsr centertxt                  * Meldung, daß Bereich nicht leer ist
 bra.s promw5
promw4:
 cmp.l d5,d7                    * Bis letztes Byte geprüft wurde
 bpl.s promw3
promw5:
 lea txtp5(pc),a0
 moveq #$32,d0
 moveq #75,d2
 bsr centertxt                  * Abfragetext fürs Starten
 bsr ki
 cmp.b #'M',d0
 bne.s promw5a                  * 'M' = Ende
 addq.l #8,a7                   * Stack reinigen
 bra carset
promw5a:
 cmp.b #'S',d0
 bne.s promw5                   * 'S' = Starten
 movem.l (a7),d5/a1             * Register wieder auf alten Wert
 lea txtp6(pc),a0               * d5 = Anfangsadresse Eprom
 moveq #$32,d0                  * d7 = Endadresse Eprom
 bsr centertxt                  * a1 = Anfangsadresse Ram
 bsr putpadr                    * Fürs Programmieren initialisieren
promw6:
 bsr csts
 beq.s promw7                   * Weiter, wenn kein Zeichen von Tastatur
 bsr ci
 cmp.b #$1b,d0
 bne.s promw7                   * ESC ist Abbruch
 bsr getpadr                    * Auf Lesen (Spannungen)
 addq.l #8,a7                   * Stack reinigen
 bra finmenue                    * Ende
promw7:
 move.b (a1),d3                 * Wert nach d3
 cmp.b #$ff,d3
 beq.s promw9                   * $FF nicht programmieren
 jsr (a4)                       * Wert Programmieren
 bcc.s promw9                   * Richtig Programmiert
 bsr promerror
 lea txtp7(pc),a0               * Fehler beim Programmieren
 moveq #$32,d0
 moveq #60,d1
 moveq #10,d2
 bsr textprint                  * Text ausgeben
 bsr ki                         * Zeichen holen
 cmp.b #'M',d0
 bne.s promw8                   * 'M', dann Ende
 bsr getpadr                    * Auf Lesen (Spannungen)
 addq.l #8,a7                   * Stack reinigen
 bra finmenue                    * Ende
promw8:
 lea txtp7(pc),a0               * Sonst Text löschen und weiter programmieren
 moveq #$32,d0
 bsr erapen
 bsr textprint                  * Text löschen
promw9:
 addq.l #1,d5                   * Nächste Adresse im Eprom
 adda.l d4,a1                   * Nächste Adresse im Ram
 cmp.l d5,d7
 bpl.s promw6                   * Bis letztes Byte programmiert
 bsr getpadr
 movem.l (a7)+,d5/a1            * Werte zurück
promw10:                        * Prüflesen
 jsr (a4)
 cmp.b (a1),d0                  * Wert aus Eprom an Adresse geben
 beq.s promw11                  * OK
 subq.l #1,d5                   * Alte Adresse
 bsr.s promerror                * Fehler beim Prüflesen
 lea txtp8(pc),a0               * Fehler beim Programmieren
 moveq #$32,d0
 moveq #10,d2
 bsr centertxt                  * Text ausgeben
 bra.s finmenue                  * Ende
promw11:
 adda.l d4,a1                   * Nächstes Byte
 cmp.l d5,d7                    * Bis Ende erreicht
 bpl.s promw10                  * Schleife fo rtsetzen
 lea txtp9(pc),a0               * OK
 moveq #$32,d0
 moveq #10,d2
 bsr centertxt                  * Text ausgeben, daß erfolgreich programmiert
 bra.s finmenue

promerror:                      * d5 = Zieladresse / a1 = Quelladresse
 lea ausbuf(a5),a0              * Adressen ausgeben
 move.l d5,d0
 bsr print6x                    * Zieladresse 5 Stellen
 move.w #'  ',(a0)+
 move.l a1,d0
 bsr print6x                    * Quelladresse 6 Stellen
 lea ausbuf+1(a5),a0
 moveq #$32,d0
 moveq #127,d1
 moveq #40,d2
 bra textaus                     * Jetzt Adressen ausgeben
*******************************************************************************
*                        680xx Grundprogramm finmenue                         *
*                         (C) 1990 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                            Menüpunkt Endemenü                               *
*******************************************************************************


finmenue:                       * Ende einiger Menüpunkte
 bsr erakreuz                   * Kreuz muß aus
 clr.b xormode(a5)              * XOR-Mode auf der GDP muß auch aus
 move.b #1,wrtpage(a5)          * Auf Seite 1 schreiben
 bsr aktpage
 clr.b gdpscroll(a5)            * Merken
 lea fimsg(pc),a0
 moveq #$11,d0
 move #430,d1
 moveq #0,d2
 bsr textaus                    * Text ausgeben
 clr.b wrtpage(a5)              * Und auf Seite Null auch
 bsr aktpage
 moveq #$11,d0
 bsr textaus
 btst.b #0,ioflag(a5)
 beq.s fin1m
 clr.b page1.w                  * Nur bei neuer GDP Scroll aus
fin1m:
 bsr ki
 cmp.b #'F',d0                  * 'F' schaltet Flip um
 bne.s fin2m
 tst.b flip(a5)                 * Wenn aus war, dann einschalten
 bne.s fin12m
 move.b #1,flip(a5)             * Schnellste Rate
 move.b #1,flipcnt(a5)          * Zwei-Seiten-Umschaltung
 bra.s fin1m                     * Nächste Eingabe abwarten
fin12m:
 clr.b flip(a5)                 * Flip ausschalten
 clr.b viewpage(a5)
 bsr aktpage                    * Seite Null ansehen
 bra.s fin1m
fin2m:
 cmp.b #$1b,d0                  * <ESC> = Ende
 beq.s fin3m
 cmp.b #'M',d0                  * 'M' ist Ende
 bne.s fin1m
fin3m:
 clr.b curon(a5)                * Kein Cursor
 clr.b flip(a5)                 * Keine Seitenumschaltung
 clr.b flip1(a5)
 move.b #1,first(a5)            * Turtle auf first
 clr oldsize(a5)                * Keine alte Figur
 rts
*******************************************************************************
*                        680xx Grundprogramm aendere                          *
*                         (C) 1990 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                             Menüpunkt Ändern                                *
*******************************************************************************


aendere:                        * Speicherstelle(n) ändern
 lea txta1(pc),a0
 bsr headaclr                   * Überschrift
aend0:
 bsr getadr                     * Adresse Ram
 bcs carset                     * Fehler ist Abbruch
 movea.l d0,a4                  * Adresse merken
aend1:
 lea txta2(pc),a0
 moveq #$22,d0
 moveq #10,d1
 moveq #25,d2
 bsr textprint                  * Befehle
aend2:
 lea ausbuf(a5),a0
 movea.l a0,a1                  * Ausbuf-Adresse merken
 move.l a4,d0
 bsr print8x                    * Adresse ausgeben
 move #': ',(a0)+
 movea.l a0,a2
 movea.l a4,a3
 moveq #5-1,d7                  * 5 Werte
aend3a:
 move.b (a3)+,d0
 bsr print2x                    * Hexadezimal
 move #'  ',(a0)+
 dbra d7,aend3a
 clr.b (a0)
 movea.l a1,a0
 moveq #$22,d0
 moveq #20,d1
 move #160,d2
 lea ausbuf(a5),a0
 bsr textaus                    * Hex-Ausgabe
 movea.l a2,a0
 movea.l a4,a3
 moveq #5-1,d7                  * 5 Werte
aend3b:
 move.b (a3)+,d0                * Bit 8-15 sind 0 !!
 move.l #'    ',(a0)            * Leerraum für verschiedene Anzahl Zeichen
 move.l a0,-(a7)                * a0 retten
 bsr print4d                    * Dezimal
 move.b #' ',(a0)               * Endekennung löschen
 movea.l (a7)+,a0               * a0 zurück
 addq.l #4,a0
 dbra d7,aend3b
 clr.b (a0)
 movea.l a1,a0
 moveq #$22,d0
 move #140,d2
 bsr textaus                    * Dez-Ausgabe
 movea.l a4,a3
 moveq #5-1,d7                  * 5 Werte
aend3c:
 move.b (a3)+,d0
 bsr putascii                   * ASCII
 move.b d0,(a2)+
 move.b #' ',(a2)+
 move #'  ',(a2)+
 dbra d7,aend3c
 clr.b (a2)
 movea.l a1,a0
 moveq #$22,d0
 moveq #120,d2
 bsr textaus                    * ASCII-Ausgabe
 lea einbuf(a5),a0
 clr.b (a0)
 move.l a4,d0                   * Adresse
 btst #0,d0
 bne.s aend4                    * Ungerade Adresse, dann kein DIS-Assembler
 bsr trapdisass                 * DIS-Assemblieren
aend4:
 moveq #82-1,d0
aend5:
 move.b (a0)+,(a1)+             * Maximal 82 Zeichen übertragen
 dbeq d0,aend5
 subq.l #1,a1                   * Zurück
 tst d0
 bmi.s aend7                    * Wenn Zeile voll, dann weiter
aend6:
 move.b #' ',(a1)+              * Rest mit Leerzeichen füllen
 dbra d0,aend6
aend7:
 clr.b (a1)                     * Ende markieren
 lea ausbuf(a5),a0
 moveq #$11,d0
 moveq #20,d1
 move #105,d2
 bsr textaus                    * Text ausgeben
aend8:
 lea einbuf(a5),a0
 moveq #$22,d0
 moveq #20,d1
 moveq #70,d2
 moveq #35,d3                   * Maximal 35 Zeichen
 bsr textein                    * Befehlseingabe
 bcs carset                     * Abbruch
 tst d4                         * Wenn mindestens 1 Zeichen, dann weiter
 bne.s aend9
 addq.l #1,a4                   * Sonst Adresse+1
 bra aend2
aend9:
 cmp #1,d4                      * Mehr als 1 Zeichen, dann weiter
 bne.s aend13
 move.b -(a0),d0                * Das Zeichen holen
 cmp.b #'-',d0                  * '-' = Adresse-1
 bne.s aend10
 subq.l #1,a4
 bra aend2
aend10:
 bsr bucheck
 cmp.b #'R',d0                  * 'R' = neue Adresse
 beq aend0
 cmp.b #'D',d0                  * 'D' = Zum Dump umschalten
 bne.s aend11
 lea txta1(pc),a0
 bsr headaclr                   * Alte Überschrift
 move.b #1,wrtpage(a5)
 bsr aktpage                    * Auf beiden Seiten ausgeben
 bsr headaus
 move.l a4,d0
 bsr spdump                     * Dump aufrufen
 bsr speich2                    * Befehle für Dump
 lea txta1(pc),a0
 bsr headaclr                   * Überschrift neu
 move.l a4,d0
 and.b #$f0,d0
 sub.l a3,d0
 suba.l d0,a4                   * Neue Adresse berechnet
 bra aend1
aend11:
 cmp.b #'F',d0                  * 'F' = Füllen
 bne.s aend12
 bsr fillspei
 bra aend2
aend12:
 cmp.b #'S',d0                  * 'S' = Suchen
 bne.s aend13
 bsr suchwert
 bcs aend8                      * Fehler, nicht gefunden
 bra aend2                       * OK, gefunden
aend13:
 cmp.b #$1b,d0                  * <ESC> = Ende
 beq.s *+8
 cmp.b #'M',d0                  * 'M' = Ende
 bne.s aend14
 rts
aend14:                         * Wert berechnen und ins Ram
 lea einbuf(a5),a0
 bsr igbn
 cmp.b #$27,(a0)
 bne.s aend15
 bsr.s getstring                * Ist String eingegeben worden ?
 bcs aend8                      * Fehler
 bra.s aend16                    * OK, String ausgeben
aend15:
 bsr zuweis                     * Symboldefinition ist erlaubt
 bcc aend8
 bsr wertmfeh                   * Keine Definition, dann Wert ausrechnen
 bcs aend8
 bsr putwert                    * Wert in ausbuf ablegen und d0 vorbereiten
aend16:
 move.l d0,d1                   * Anzahl der Bytes
 bsr fillsp0                    * Speicher füllen
 bra aend2                       * Wiederholen

*******************************************************************************
*                        680xx Grundprogramm mendiv1                          *
*                         (C) 1990 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                 Diverse Unterprogramme der Menüsteuerung                    *
*******************************************************************************


getstring:                      * Liefert String in ausbuf und d0 = Anzahl Bytes
 addq.l #1,a0                   * ' überspringen
 movea.l a0,a1
getstr1:
 tst.b (a1)+                    * Bis zur Endekennung suchen
 bne.s getstr1                  * Null ist Ende
 subq.l #1,a1                   * Null nicht beachten
getstr2:
 cmp.b #' ',-(a1)
 beq.s getstr2                  * Ende-Leerzeichen ignorieren
 cmp.b #$27,(a1)
 bne carset                     * ' muß am Ende vorhanden sein
 clr.b (a1)                     * ' löschen
 lea ausbuf(a5),a2              * Ziel
 moveq #-1,d0                   * d0 ist ab jetzt Zähler der Zeichen
getstr3:
 addq.l #1,d0                   * Ein Zeichen mehr vorhanden
 move.b (a0)+,(a2)+             * Ablegen
 bne.s getstr3                  * Bis Null
 tst.l d0                       * d0 testen
 beq carset                     * Wenn Null, dann kein String vorhanden
 bra carres                      * OK, String ist in Ordnung

getzahl:                        * a0 = Text / liefert Wert in d0.l
 moveq #$22,d0
 moveq #20,d1
 move #190,d2
 bsr textaus                    * Text ausgeben
getzahl1:
 lea einbuf(a5),a0
 moveq #116,d1
 move #190,d2
 moveq #29,d3
 bsr textein                    * Text einlesen
 bcs carset                     * Abbruch
 lea einbuf(a5),a0
 bsr igbn
 cmp.b #$27,(a0)                * Stringeingabe ist jetzt erlaubt
 beq.s getstring
 bsr zuweis                     * Zuweis erlaubt
 bcc.s getzahl1                 * Wenn Zuweis, dann wiederholen
 bra wertmfeh                    * Wert holen mit Fehlerbehandlung

zweiwert:                       * Zwei Werte einlesen(In ausbuf steht dann Wert)
 lea txta3(pc),a0               * d0 = Länge des Wertes/ d1 = Anzahl
 bsr.s getzahl                  * Erster Wert
 bcs carset
 lea einbuf(a5),a0              * Ziel
 bsr igbn                       * Leerzeichen ignorieren
 cmp.b #$27,(a0)
 beq carset                     * String ist nicht erlaubt
 tst.l d0                       * Wert darf nicht Null sein
 beq carset
 move.l d0,-(a7)                * Merken
 lea txta4(pc),a0
 bsr.s getzahl                  * Zweiter Wert
 movem.l (a7)+,d2               * Erster Wert zurück
 bcs carset                     * Carry = Fehler
 lea einbuf(a5),a0              * Ziel
 bsr igbn                       * Leerzeichen ignorieren
 cmp.b #$27,(a0)                * War ein String eingegeben worden ?
 beq.s zweiw1                   * Ja, dann weiter
 bsr putwert                    * Wert in ausbuf / d0 vorbereiten
zweiw1:
 move.l d2,d1                   * Anzahl der zu bearbeitenden Bytes
 rts

fillspei:
 bsr zweiwert                   * Zwei Werte holen
 bcs carset                     * Fehler
fillsp0:                        * In d0 steht Länge Wert in Bytes
 lea ausbuf(a5),a0              * In d1 steht Anzahl der zu füllenden Bytes
 clr d2                         * In ausbuf steht Wert
fillsp1:
 cmpa.l #grenze,a4              *
 bhi carset                     * Wenn größer, dann nicht weiterfüllen
 move.b (a0)+,(a4)+             * Wert in Speicher
 subq.l #1,d1                   * Erniedrigen
 beq carres                     * bis alle Werte ausgegeben
 addq #1,d2                     * Nächstes Zeichen in ausbuf
 cmp d0,d2                      * Alle Zeichen durch ?
 bne.s fillsp1                  * Nein, deshalb nächstes Zeichen übertragen
 bra.s fillsp0                   * Ja, deshalb von ausbuf an wiederholen

suchwert:                       * Wert suchen
 bsr.s zweiwert                 * Wie bei fillspeich
 bcs carset
 lea 1(a4),a3                   * Ab hier suchen
suchw1:
 lea ausbuf(a5),a0              * Ab hier steht Wert
 move.b (a0)+,d3
suchw2:
 cmpa.l #grenze,a3              *
 bhi carset                     * Wenn größer, dann nicht gefunden
 cmp.b (a3)+,d3                 * Erstes Byte suchen
 beq.s suchw3                   * Gefunden
 subq.l #1,d1                   * Weitersuchen
 bne.s suchw2                    * OK
 bra carset                      * Ende, nicht gefunden
suchw3:
 movea.l a3,a2                  * Rest vergleichen
 clr d2
suchw4:
 addq #1,d2                     * Nächstes Byte
 cmp d0,d2                      * Bis Ende des Suchwertes erreicht ist
 beq.s suchwfi                  * Dann ist Wert gefunden
 cmpm.b (a2)+,(a0)+             * So lange vergleichen, wie Werte gleich sind
 beq.s suchw4                   * Weitersuchen
 bra.s suchw1                    * Von vorne beginnen
suchwfi:
 lea -1(a3),a4                  * a4 = Adresse gefunden
 bra carres

putwert:                        * In d0 ist Wert
 lea ausbuf(a5),a0              * d1 ist Länge
 cmp #1,d1                      * Ergebnis d0 = Länge in Bytes
 bne.s putwert1
 move.b d0,(a0)                 * Byte
 moveq #1,d0                    * 1 Byte
 rts
putwert1:
 cmp #2,d1
 bne.s putwert2
 move d0,(a0)                   * Wort
 moveq #2,d0                    * 2 Bytes
 rts
putwert2:
 move.l d0,(a0)                 * Langwort
 moveq #4,d0                    * 4 Bytes
 rts

*******************************************************************************
*                          680xx Grundprogramm bibo                           *
*                         (C) 1990 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                           Menüpunkt Bibliothek                              *
*******************************************************************************


suchbibo:                       * Einen oder mehrere Bibliothekseinträge suchen
 cmp #1,d0                      * d0 = 0  Von a0 an suchen
 beq.s suchbibc                 * d1 = 1  Von $400 an suchen
 lea $400,a0                    * In d2 und d3 steht der zu suchende Name
 tst d0                         * d1-d7 enthalten dann Daten Carry = 0
 beq.s suchbibc                 * Sonst Carry = 1
 clr.l (a1)                     * Endekennung setzen
 bsr suchbibf                   * d1 = 2 Alle Einträge in einer Tabelle von a1
 bcs carset                     * an ablegen / Carry wenn kein Eintrag vorhanden
suchbiba:
 move.l a0,(a1)+                * Adresse Eintrag
 addq.l #4,a0                   * Kennung überspringen
 move.l (a0)+,(a1)+             * Name
 move.l (a0)+,(a1)+             * Name
 move.l (a0)+,d0                * Startadresse
 tst.b 4(a0)
 beq.s suchbibb
 add.l -12(a1),d0               * Relokativ, deshalb Adresse Eintrag addieren
suchbibb:
 move.l d0,(a1)+                * Startadresse ablegen
 move.l (a0)+,(a1)+             * Länge
 move.w (a0)+,(a1)+             * Relokativ-Flag und CPU
 adda #10,a0                    * Reservierung überspringen
 bsr.s suchbibf                 * Nächsten Eintrag suchen
 bcc.s suchbiba                 * Schleife
 clr.l (a1)                     * Endekennung
 bra carres                      * OK, mindestens ein Eintrag gefunden

wandled0:                       * Name (4 Buchstaben) in d0
 rol.l #8,d0                    * Alle Kleinbuchstaben werden in Großbuchstaben
 bsr bucheck                    * gewandelt
 rol.l #8,d0                    * Rest bleibt unverändert
 bsr bucheck
 rol.l #8,d0
 bsr bucheck
 rol.l #8,d0
 bra bucheck

suchbibc:
 move.l d2,d0                   * Namen wandeln
 bsr.s wandled0
 exg.l d0,d3
 bsr.s wandled0
 move.l d0,d2                   * Name liegt jetzt in Großbuchstaben vor
suchbibd:
 bsr.s suchbibf                 * Eintrag suchen
 bcs carset                     * Nicht gefunden
 move.l 4(a0),d0
 bsr.s wandled0                 * In Großbuchstaben wandeln
 cmp.l d0,d3                    * Vergleichen
 bne.s suchbibe                 * Falsch
 move.l 8(a0),d0
 bsr.s wandled0                 * In Großbuchstaben wandeln
 cmp.l d0,d2                    * Vergleichen
 bne.s suchbibe                 * Falsch
 move.l a0,d1                   * Adresse Eintrag
 addq.l #4,a0
 movem.l (a0)+,d2-d5            * Daten
 move.b (a0)+,d6                * Relokativ-Flag
 move.b (a0)+,d7                * CPU
 tst.b d6
 beq carres                     * OK, wenn absolut
 add.l d1,d4                    * Relokativ
 bra carres                      * OK
suchbibe:
 adda #32,a0                    * Reservierung überspringen
 bra.s suchbibd                  * Weiter suchen

suchbibf:
 cmp.l #$55aa0180,(a0)          * Kennung suchen
 beq.s suchbibh
suchbibg:
 move.l a0,d0
 and #$fc00,d0                  * Auf Grenze bringen
 movea.l d0,a0
 adda #$400,a0                  * 1 Kbyte weiter
 cmpa.l #grenze,a0              * Ende erreicht ?
 bls.s suchbibf                 * Nein, dann weiter
 bra carset
suchbibh:
 btst.b #0,15(a0)               * Sichheitstest
 bne.s suchbibg                 * Wenn ungerade, dann keine Startadresse
 tst.b 20(a0)
 beq.s suchbibi                 * OK, absolut
 cmp.b #1,20(a0)
 bne.s suchbibg                 * Fehler, da auch nicht relokativ
suchbibi:
 tst.b 21(a0)                   * Ohne Kennung
 beq carres
 cmp.b #cpu,21(a0)
 bne.s suchbibg                 * Falsche CPU
 bra carres                      * OK

bibo:
 lea einbuf(a5),a6              * Pointer auf Bildanfangsadresse
 move.l #$400,(a6)              * Von $400 an suchen
bibo0:
 lea bibotxt0(pc),a0
 bsr headaclr                   * Überschrift ausgeben
 lea bibotxt1(pc),a0
 moveq #$22,d0
 moveq #10,d1
 move #203,d2
 bsr textprint                  * Anzeige-Zeile
 lea bibotxt2(pc),a0
 moveq #$22,d0
 moveq #30,d1
 moveq #20,d2
 bsr textprint                  * Befehls-Zeile
 moveq #'A',d7                  * Kein Eintrag bisher
 moveq #16,d1                   * Anfang der Zeile
 move #188,d2                   * Auf oberste Zeile
 movea.l (a6),a4                * Anfangssuchadresse
 lea ausbuf(a5),a1              * Zieladresse Programmanfänge
bibo1:
 movea.l a4,a0
 bsr suchbibf                   * Eintrag suchen
 movea.l a0,a4
 bcs.s bibo3                    * Keinen gefunden
 moveq #0,d0                    * Nicht Verschiebbar
 lea bibotxt3(pc),a2            * NEIN
 tst.b 20(a4)                   * Null ?
 beq.s bibo2                    * Ja, dann OK
 addq.l #6,a2                   * JA
 move.l a4,d0                   * Verschiebeadresse
bibo2:
 addq.l #4,a4                   * Zeiger auf Name
 lea ausbuf+81(a5),a0           * Ziel für eine Zeile
 move.b d7,(a0)+                * Auswahlbuchstabe
 move.l #'    ',(a0)+           * Leerraum
 move.l (a4)+,(a0)+             * Name
 move.l (a4)+,(a0)+             * 8 Buchstaben
 move.w #'  ',(a0)+             * Leerraum
 add.l (a4)+,d0                 * Startadresse + Basisadresse (Falls nicht Null)
 move.l d0,(a1)+                * Ablegen
 bsr print6x                    * Und ausgeben
 move #'  ',(a0)+
 move.l (a4)+,d0                * Länge
 bsr print6x                    * Ausgeben
 move.l #'    ',(a0)+           * Leerraum
 move.l (a2),(a0)+              * JA oder NEIN
 clr.b (a0)                     * Ende
 moveq #$21,d0
 lea ausbuf+81(a5),a0
 bsr textprint                  * Ausgabe einer Zeile ohne Vorlöschen
 adda #12,a4                    * Auf eventuellen nächsten Eintrag
 sub #13,d2                     * Eine Zeile tiefer
 addq #1,d7                     * Ein Eintrag mehr vorhanden
 cmp #'M',d7
 bne.s bibo1                    * Wenn noch Platz, dann nächste Zeile
bibo3:
 move.l a4,4(a6)                * Suchadresse nächste Seite
 lea ausbuf+81(a5),a0
 clr.b 1(a0)                    * Nur ein Zeichen
 moveq #$22,d0
 move #306,d1
 moveq #0,d2
 bsr textaus                    * Ausgabe (A- ) = Starten
bibo4:
 bsr ki                         * Zeichen holen und in Großbuchstaben wandeln
 cmp.b #$1b,d0
 beq carres                     * Ende
 cmp.b #'M',d0
 beq carres                     * Ende
 cmp.b #'+',d0                  * Eine Seite weiter ?
 bne.s bibo5                    * Nein
 cmp.l #grenze,4(a6)            * Wenn schon ganz hinten, dann nicht weiter
 bhi.s bibo4
 addq.l #4,a6                   * Pointer eine Seite weiter
 bra bibo0                       * OK, neue Seite aufbauen
bibo5:
 cmp.b #'-',d0                  * Eine Seite zurück ?
 bne.s bibo6                    * Nein
 cmp.l #$400,(a6)               * Schon am Anfang ?
 beq.s bibo4                    * Ja, zurück zur Abfrage
 subq.l #4,a6                   * Pointer zurück
 bra bibo0                       * Ausgabe
bibo6:
 cmp.b #'A',d0                  * Bereich 0-
 bmi.s bibo4                    * Zu klein
 cmp.b d7,d0                    * Zu groß ?
 bpl.s bibo4                    * Ja, dann zurück
 lsl #2,d0                      * Mal 4, da Langwort
 lea ausbuf-'A'*4(a5),a0        * Tabellenbeginn
 movea.l 0(a0,d0),a0            * Zieladresse
 bsr clrall                     * Bildschirm löschen
 move.b menflag(a5),-(a7)       * Menü-Einstellungen retten
 bclr #7,menflag(a5)            * Ohne Hardcopy
 jsr (a0)                       * Programm aufrufen
 bsr seta5                      * Zur Sicherheit a5 auf alten Wert
 move.b (a7)+,menflag(a5)       * Zurück
* moveq #1,d0                    * nur 68020!!!
* movec.l d0,cacr                * Cache immer anschalten nur 68020!!!
 bra finmenue                    * Ende

*******************************************************************************
*                        680xx Grundprogramm mendiv2                          *
*                         (C) 1990 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                 Diverse Unterprogramme der Menüsteuerung                    *
*******************************************************************************


get3par:                        * 3 Werte lesen
 moveq #$22,d0                  * In a0 steht Text mit mindestens 3 Zeilen
 moveq #10,d1
 move #180,d2
 bsr textprint                  * Text ausgeben
 move #150,d1
 moveq #30,d3
 lea einbuf(a5),a0
 bsr textein                    * Ersten Wert holen
 bcs carset                     * Abbruch
 lea einbuf(a5),a0
 bsr wertmfeh                   * Berechnen mit Fehlerbehandlung
 bcs carset
 move.l d0,d6                   * d6 = Erster Wert
get3rest:
 moveq #$22,d0
 move #150,d1
 move #160,d2
 moveq #30,d3
 lea einbuf(a5),a0
 bsr textein                    * Zweiten Wert holen
 bcs carset                     * Abbruch
 lea einbuf(a5),a0
 bsr wertmfeh                   * Wert mit Fehlerbehandlung
 bcs carset
 move.l d0,d7                   * d7 = Zweiter Wert
 moveq #$22,d0
 move #150,d1
 move #140,d2
 moveq #30,d3
 lea einbuf(a5),a0
 bra textein                     * In einbuf steht dritter Wert oder Name

get2par:                        * Zwei Werte holen
 moveq #$22,d0
 moveq #10,d1
 move #160,d2
 bsr textprint                  * Text ausgeben
 bra.s get3rest                  * Die zwei letzten Werte von get3par holen

startex:                        * Programm starten
 lea stmsg1(pc),a0
 bsr headaclr                   * Überschrift
 bsr.s getadr                   * Adresse holen
 bcs carset                     * Fehler
 movea.l d0,a0                  * Startadresse
 bsr clrall                     * Bildschirm löschen
 move.b #1,first(a5)            * Turtle erster Aufruf
 move.b #1,turdo(a5)            * Turtle down
 move.b menflag(a5),-(a7)       * menflag merken
 bclr.b #7,menflag(a5)          * Grundprogramm ausgeschaltet (Hardcopy bei ci)
 jsr (a0)                       * Programm aufrufen
 bsr seta5                      * a5 wieder in Ordnung bringen, falls zerstört
 move.b (a7)+,menflag(a5)       * menflag zurück
 bra finmenue

getadr:                         * Adresse lesen
 lea adrmsg(pc),a0
 moveq #$22,d0
 moveq #20,d1
 move #190,d2
 bsr textaus                    * Aufforderung ausgeben
get1padr:
 lea einbuf(a5),a0
 moveq #$22,d0
 moveq #80,d1
 move #190,d2
 moveq #32,d3
 bsr textein                    * Text lesen
 bcs carset                     * Abbruch
 lea einbuf(a5),a0
 bsr zuweis                     * Zuweis ausführen
 bcc.s get1padr                 * OK Symbol zugewiesen, neuen Wert lesen
 bra wertmfeh                    * Kein Symbol, also Wert berechnen

putascii:                       * ASCII-Wert testen und nach d0 oder '.'
 tst.b d0
 bpl.s putasc3                  * Positiv, dann kein Sonderzeichen
 movem.l d7/a0,-(a7)            * Sonderzeichen
 lea ztab0(pc),a0               * Dort sind Zeichen
 moveq #anztab-2-1,d7           * Anzahl der Zeichen
putasc1:
 cmp.b (a0)+,d0                 * Vergleichen
 beq.s putasc2                  * OK, gefunden
 dbra d7,putasc1
 moveq #'.',d0                  * Nicht gefunden also '.'
putasc2:
 movem.l (a7)+,d7/a0
 rts                             * Ende Sonderzeichenauswertung
putasc3:
 cmp.b #32,d0                   * Kein Sonderzeichen
 bpl.s putasc4                  * Größer als 32, dann OK
 moveq #'.',d0                  * Kleiner, also CTRL-Zeichen
putasc4:
 rts                             * Ende

*******************************************************************************
*                        680xx Grundprogramm ansehen                          *
*                         (C) 1990 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                       Menüpunkt Speicher ansehen                            *
*******************************************************************************


speicheraus:                    * Speicher ansehen
 lea spmsg1(pc),a0
 bsr headaclr                   * Überschrift ausgeben
 eori.b #1,wrtpage(a5)
 bsr aktpage                    * Andere Seite
 bsr headaus                    * Auch dort ausgeben
speich1:
 move.b viewpage(a5),wrtpage(a5) * Leseseite = Schreibseite
 bsr aktpage
 bsr.s getadr                   * Adresse lesen
 bcs carset                     * Fehler
 bsr spdump                     * Dump ausgeben
speich2:
 bsr ki                         * Zeichen von Tastatur holen
 cmp.b #$1b,d0                  * <ESC> = Ende
 beq carset
 cmp.b #'M',d0                  * 'M' ist Ende
 beq carset
 cmp.b #'R',d0                  * 'R' = neue Adresse
 bne.s speich3
 bsr marke0                     * Alte Marke löschen
 bra.s speich1                   * Ausgeben
speich3:
 bsr.s speich4                  * Auswertung Rest
 bra.s speich2                   * Wiederholen

speich4:
 cmp.b #'+',d0                  * Halbe Seite vor
 bne.s speich5
 bsr marke0                     * Alte Marke weg
 adda #$40,a3                   * Neue Adresse
 bra spdump1                     * Dump ausgeben
speich5:
 cmp.b #'-',d0                  * Halbe Seite zurück
 bne.s speich6
 bsr marke0                     * Alte Marke weg
 suba #$40,a3                   * Neue Adresse
 bra spdump1                     * Dump ausgeben
speich6:
 cmp.b #'S',d0                  * Suchen
 bne.s speich7
 bsr marke1                     * Alte Marke weg
 bsr suchwert                   * Wert suchen
 move.l a4,d0                   * Neue Adresse, wenn gefunden
 bra spdump                      * Dump ausgeben
speich7:
 cmp.b #'F',d0                  * Speicher füllen
 bne.s speich8
 bsr marke1                     * Alte Marke weg
 bsr fillspei                   * Speicher füllen
 move.l a4,d0                   * Neue Adresse
 bra spdump                      * Dump ausgeben
speich8:
 cmp.b #'1',d0
 bne.s speich9                  * Ein Byte neu eingeben
 bsr spadr                      * Adresse holen und Wert berechnen
 bcs.s speich8a                 * Fehler = Ende
 bsr spdump                     * Dump, da neue Adresse
 moveq #0,d7                    * Bearbeitung mit Textein (1 mit Readaus)
 bsr.s speich8b                 * Marke eingeben
speich8a:
 move.l a4,d0                   * Neue Adresse
 bra spdump                      * Dump neu

speich8b:                       * Ein Byte neu oder ändern (d7 = Typ)
 bsr marke1                     * Marke löschen
 addq #6,d1                     * d1 = X-Position Byte
 lea einbuf(a5),a0
 move.b #'$',(a0)+              * Eingabe als Hexadezimalwert
 move.b (a4),d0                 * Alten Wert
 bsr print2x                    * holen und ablegen
 subq.l #2,a0                   * Alte Adresse
 moveq #$11,d0                  * Größe
 tst d7
 bne.s speich8c
 moveq #3,d3                    * Neu eingeben, deshalb textein
 bsr textein
 bra.s speich8d                  * Weiter
speich8c:
 moveq #0,d3                    * Ändern, deshalb readaus
 bsr readaus
speich8d:
 add #12,d1                     * Position drittes Zeichen
 bsr moveto                     * Positionieren
 bsr erapen                     * Auf Löschen
 move.b #10,(a6)                * Eventuell vorhandenes drittes Zeichen löschen
 lea einbuf+1(a5),a0
 cmp.b #$27,(a0)                * Wenn ', dann ASCII-Zeichen Eingabe
 beq.s speich8e
 subq.l #1,a0                   * sonst mit '$'
speich8e:
 bsr wertmfeh                   * Wert mit Fehleranalyse
 bcs.s speich8f                 * Fehler
 move.b d0,(a4)                 * Sonst abspeichern
speich8f:
 addq.l #1,a4                   * Neue Adresse
 rts

speich9:
 cmp #'2',d0
 bne.s speich10                 * Byte ändern
 bsr.s spadr                    * Adresse holen
 bcs.s speich8a                 * Fehler
 bsr spdump                     * Dump, da neue Adresse
 moveq #1,d7                    * Flag für Ändern
 bsr.s speich8b                 * Byte ändern
 bra.s speich8a                  * Ende mit Adressneueinstellung

speich10:
 cmp.b #'3',d0
 bne.s speich11                 * 16 Bytes neu eingeben
 bsr.s spadr                    * Adresse holen
 bcs.s speich8a                 * Fehler
 moveq #0,d7                    * Merker für eingeben
spei10a:
 and.b #$f0,d0                  * Adresse muß auf 16 Byte-Adresse liegen
 moveq #16-1,d1                 * 16 Bytes eingeben
spei10b:
 movem.l d0/d1/d7,-(a7)
 move d7,-(a7)                  * d7 merken
 bsr spdump                     * Dump ausgeben
 move (a7)+,d7                  * d7 zurück
 bsr speich8b                   * Byte neu eingeben
 movem.l (a7)+,d0/d1/d7
 addq.l #1,d0                   * Nächste Adresse
 dbra d1,spei10b
 bra spdump                      * Am Ende nochmals Dump

speich11:
 cmp.b #'4',d0
 bne carset                     * 16 Bytes ändern
 bsr.s spadr                    * Adresse holen
 bcs speich8a                   * Fehler
 moveq #1,d7                    * Merker für ändern
 bra.s spei10a                   * Ausführen

spadr:
 bsr.s marke1                   * Marke löschen
 bsr getadr                     * Adresse holen
 bcc carres                     * OK, alles klar
 lea einbuf(a5),a0
 bsr igbn                       * Leerzeichen ignorieren
 cmp.b #'=',(a0)+
 bne carset                     * Kein '=', dann Fehler
 bsr igbn                       * Leerzeichen ignorieren
 tst.b (a0)                     * Null muß danach kommen
 bne carset
 move.l a4,d0                   * '=' bedeutet alte Adresse
 bra carres

marke0:
 bsr.s marke1                   * Marke weg
 eori.b #1,wrtpage(a5)          * Neue Schreibseite
 bra aktpage                     * Und umschalten

marke1:
 bsr erapen                     * Auf Löschen
marke:
 move.l a4,d1                   * Adresse
 sub.l a3,d1                    * Seitenanfangsadresse
 bmi carset                     * Negativ, dann keine Marke vorhanden
 cmp.l #16*8,d1
 bpl carset                     * Auch nicht vorhanden
 move d1,d2
 lsr #4,d2                      * Durch 16, wegen Zeile (16 Byte pro Zeile)
 muls #-20,d2                   * Höhe berechnen
 add #160,d2                    * Hier oberste Zeile
 and #$f,d1                     * Berechnung X-Position
 mulu #24,d1                    * Abstand zwischen zwei Bytes
 add #54,d1                     * Anfangs X-Position
 bsr moveto                     * Positionieren
 move.b #'>',(a6)               * Marke ausgeben
 rts

spdump:                         * Dump durchführen
 movea.l d0,a4                  * d0 = Anfangsadresse
 and.b #$f0,d0                  * Zeilenanfangsadresse
 movea.l d0,a3                  * Merken
 lea spmsg2(pc),a0
 moveq #$22,d0
 moveq #20,d1
 move #190,d2
 bsr textaus                    * Überschrift
 lea spmsg3(pc),a0
 moveq #$21,d0
 moveq #0,d1
 move #175,d2
 bsr textprint                  * Byte-Einteilung
 eori.b #1,wrtpage(a5)
 bsr aktpage                    * Das gleiche auch auf Seite 1
 moveq #$21,d0
 bsr textprint
 lea spmsg2(pc),a0
 moveq #$22,d0
 moveq #20,d1
 move #190,d2
 bsr textaus
spdump1:
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupt aus
 bsr wait                       * Hier beginnt Dump
 lea gdp.w,a6                   * GDP-Basis-Register
 lea gdp+9*cpu.w,a2             * X-Register (Low Byte)
 moveq #2,d7                    * WAIT-Bit
 clr.b gdp+$a*cpu.w             * X-Koordinate einstellen
 move.b #160,gdp+$b*cpu.w
 move.b #$11,gdp+3*cpu.w        * Schriftgröße einstellen
 bsr erapen                     * Auf Löschen
 moveq #8-1,d5                  * 8 Reihen
spdump2:
 btst.b d7,(a6)                 * Ohne Sprung zu wait schneller
 beq.s spdump2
 move.b #$d,(a6)                * Anfangs X-Position
 moveq #10,d0
 bsr clr8                       * 8 Zeichen löschen
 add.b #12,(a2)                 * 2 Zeichen Platz lassen
 moveq #16-1,d4                 * 16 Zeichen
spdump3:
 btst.b d7,(a6)
 beq.s spdump3
 move.b d0,(a6)                 * 2 Zeichen löschen
spdump3a:
 btst.b d7,(a6)
 beq.s spdump3a
 move.b d0,(a6)
spdump3b:
 btst.b d7,(a6)                 * Ohne Sprung zu wait schneller
 beq.s spdump3b
 add.b #12,(a2)                 * 2 Zeichen Platz lassen
 dbra d4,spdump3
 bsr clr8                       * Wieder 8 Zeichen löschen
 move.b #$d,(a6)                * X-Anfangsposition
 sub.b #10,gdp+$b*cpu.w         * Eine Zeile runter
 bsr clr8                       * 8 Zeichen löschen
 add.b #12,(a2)                 * 2 Zeichen frei
 moveq #16-1,d4                 * 16 Zeichen
spdump4:
 btst.b d7,(a6)
 beq.s spdump4
 move.b d0,(a6)                 * Löschen
spdump4a:
 btst.b d7,(a6)                 * Ohne Sprung zu wait schneller
 beq.s spdump4a
 add.b #18,(a2)                 * 3 Zeichen frei
 dbra d4,spdump4
 bsr clr8                       * Dann wieder 8 löschen
 sub.b #10,gdp+$b*cpu.w         * Eine Zeile tiefer
 dbra d5,spdump2
 bsr setpen                     * Auf Schreiben
 move.b #160,gdp+$b*cpu.w       * Oberste Zeile
 lea prttab(pc),a1              * Zeichen für HEX-ASCII-Umwandlung
 moveq #8-1,d5                  * 8 Zeilen
spdump5:
 move.b #$d,(a6)                * X - Anfang
 move.l a3,d0                   * Zeilenanfangsadresse
 bsr set8                       * ausgeben
 moveq #0,d0                    * Für Prüfsummenbildung
 moveq #0,d3                    * Ebenfalls
 moveq #16-1,d4
spdump6:
 move.b (a3)+,d3                * Wert holen
 add.l d3,d0                    * Prüfsumme bilden
 move.b d3,d2
 lsr #4,d2
 and #$f,d2                     * Vorderen vier Bits
spdump6a:
 btst.b d7,(a6)                 * Ohne Sprung zu wait schenller
 beq.s spdump6a
 add.b #12,(a2)                 * 2 Zeichen Platz lassen
 move.b 0(a1,d2),(a6)           * Bits als Ascii-Zeichen ausgeben
 and #$f,d3                     * Restlichen vier Bits
spdump6b:
 btst.b d7,(a6)                 * Ohne Sprung schneller
 beq.s spdump6b
 move.b 0(a1,d3),(a6)           * Jetzt ausgeben
 dbra d4,spdump6
 move.l d0,d6                   * Prüfsumme merken
spdump7:
 btst.b d7,(a6)                 * Ohne Sprung schneller
 beq.s spdump7
 add.b #12,(a2)                 * 2 Zeichen Platz
 bsr.s set8                     * 8 Zeichen ausgeben
 sub.b #10,gdp+$b*cpu.w         * Eine Zeile runter
 move.b #$d,(a6)                * X auf Null für nächste Zeile
 suba #16,a3                    * a3 auf letzten Wert
 move.l a3,d0
 bsr.s set8                     * 8 Zeichen ausgeben (Adresse)
 add.b #12,(a2)                 * 2 Zeichen frei
 moveq #16-1,d4
spdump8:
 move.b (a3)+,d0                * Zeichen holen
 bsr putascii                   * In Ascii wandeln
 bsr cmdput                     * Und ausgeben mit Sonderzeichen
spdump9:
 btst.b d7,(a6)
 beq.s spdump9                  * Ohne Sprung zu wait schneller
 add.b #18,(a2)                 * 3 Zeichen frei
 dbra d4,spdump8
 move.l d6,d0                   * Prüfsumme holen
 bsr.s set8                     * 8 Zeichen ausgeben
 sub.b #10,gdp+$b*cpu.w         * Eine Zeile runter
 dbra d5,spdump5
 suba.l #16*8,a3                * Anfangsadresse Seite
 bsr marke                      * Marke setzen
 move (a7)+, sr                 * Status zurück
 move.b wrtpage(a5),viewpage(a5)
 bra aktpage                    * Seite sichtbar machen

set8:                           * 8 Zeichen ausgeben
 moveq #8-1,d3
set8a:
 rol.l #4,d0
 move.b d0,d2
 and #$f,d2                     * Nur 4 Bits
set8b:
 btst.b d7,(a6)
 beq.s set8b                    * Ohne Sprung zu wait schneller
 move.b 0(a1,d2),(a6)           * 4 Bits in ASCII ausgeben
 dbra d3,set8a
set8c:
 btst.b d7,(a6)                 * Ohne Sprung zu wait schneller
 beq.s set8c
 rts

clr8:                           * 8 Zeichen löschen
 moveq #8-1,d3                  * In d0 steht Zeichen zum Löschen
clr8a:
 btst.b d7,(a6)
 beq.s clr8a
 move.b d0,(a6)                 * Zeichen an GDP
 dbra d3,clr8a
clr8b:
 btst.b d7,(a6)                 * Ohne Sprung zu wair schneller
 beq.s clr8b
 rts

headaclr:                       * Überschrift ausgeben (a0=Adresse)
 bsr clrall                     * Screen löschen
headaus:                        * Ohne Löschen
 moveq #$33,d0                  * Größe
 move #225,d2                   * Y-Position
 bra centertxt                   * Mittig positionieren und ausgeben

*******************************************************************************
*                         680xx Grundprogramm init                            *
*                         (C) 1990 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                            Initialisierungen                                *
*******************************************************************************


vekdef:                         * Für Anwendervektoren
 jmp intlvx-basis               * Sprungbefehle werden auf Adressen
 jmp intlvx-basis               * geschrieben, die für Benutzeranwendungen
 jmp traperr-basis              * reserviert sind
 jmp trap0a-basis
 jmp ciin-basis
 jmp cstsin-basis
 jmp co-basis

linedef:                        * Auch hier, bloß sind dies Ausnahmebedingungen
 jmp trap1a-basis
 jmp lineaer-basis
 jmp linefer-basis

mausdef:                        * Eingabegerät initialisieren
 jmp mausaus0-basis
 jmp absmaus0-basis

trapdef:                        * RTE für Traps im RAM
 rte

exinit:                         * Init der Variablen und Init a5/a7
 bsr seta5                      * a5 setzen
init:                           * Internes Init
 movem.l d0-d7/a0-a7,regsave(a5)
 bsr flinit                     * Floppy-Init am Anfang wegen Floppy-Motor
 move.b keys.w,keydil(a5)       * Stellung der DIL-Schalter merken
 bsr uhrinit                    * UHR-Init, muss zu Anfang wg. NVRAM
 cmp.b #3, uhrausw(a5)
 bne.s init01
 lea nvrbuff(a5), a0
 clr (a0)
 bsr getsys
 tst d0
 bne.s init01                   * NVRAM Daten nicht korrekt
 lea nvrbuff(a5), a0
 move #$a5c3, (a0)              * als Kennung, dass Daten gelesen
 move.b 2(a0), keydil(a5)       * DIP-Key überschreiben
init01:
 bsr srdinit                    * SRAMDISK initialisieren
 bsr erakreuz                   * Fadenkreuz ausschalten
 move.b #%01000000,proma2.w     * Promer neutral stellen (Bei Promer2 egal)
 clr.b proma5.w                 * Promer2 neutral stellen (Bei Promer egal)
 clr.b iodir(a5)                * Kein CTRL-A bei CO2
 clr oldsize(a5)                * Keine alte Figur gültig
 clr.b synstate(a5)             * Kein Syncrol-Impuls abgefragt
 clr.b flip(a5)                 * Keine Seitenumschaltung
 clr.b flip1(a5)
 clr.b gdpcol(a5)               * S/W-GDP
 move.b #$0a, colport.w         * Testmuster schreiben
 move.b colport.w, d0
 cmp.b #$0a, d0                 * Testmuster übernommen?
 bne.s init01a                  * nein, dann S/W-GDP
 move.b #1, gdpcol(a5)          * sonst Farb-GDP
 move.b #1, colport.w           * Vordergrundfarbe wiederherstellen
init01a:
 move.b #$01, fgcolor(a5)       * Vordergrundfarbe für GDP (1 = weiß)
 clr.b bgcolor(a5)              * Hintergrundfarbe (0 = schwarz)
 clr.b xormode(a5)              * Kein Verknüpfungsmode
 clr.b transmod(a5)             * Transparentmode ein
 clr tur1x(a5)                  * Turtle auf Null
 clr tur1y(a5)
 clr tur1phi(a5)                * Winkel auf Null
 clr turx(a5)
 clr tury(a5)
 clr turphi(a5)
 move.b #1,turdo(a5)            * Turtle down
 move.b #1,first(a5)            * Turtle erster Aufruf
 move.b #1,iostat(a5)           * Nur Fehlerausgabe
 clr.b serflag(a5)              * Serielle Schnittstelle nicht ansprechen
 move.b #2,iostatb(a5)          * ci/csts/ci2 nicht umlenken
 move #2,passflag(a5)           * Ausgabe bei CO2 eingeschaltet
 move #2,errflag(a5)            * Ausgabe bei CO2, nur Fehlerausgabe bei ASS
 clr.b curon(a5)                * Cursor bei CO2 an
 clr.b escmerker(a5)            * Kein ESC bei CO
 tas.b menflag(a5)              * Nach Reset wieder mit Hardcopy
 bclr.b #2,menflag(a5)          * Grundprogramm nicht als Aufruf
 move.b #%00000101,tracflag(a5) * Mit Regdump / TRAP+JSR Direktausführung
                                * Ohne Listen
 clr.b coscroll(a5)             * Scroll immer auf Null stellen
 clr.b page1.w                  * Kein Scroll bisher

init1:
 lea basis(pc),a0
 movea.l a0, a2
 move.l a0,d1
 beq.s init3                    * Grundprogramm auf Null, dann nicht übertragen
 suba.l a1,a1                   * Zieladresse = 0
 move #$100-1,d2                * $100 Langworte übertragen
init2:
 move.l (a0)+,(a1)              * Wert übertragen
 add.l d1,(a1)+                 * Adresse addieren
 dbra d2,init2
init3:
 cmp.l #$a140557a,poweron(a5)   * Wenn Power an, dann Ende
 beq getstack                   * Stack nach d0
 bsr clrall                     * Bildschirm löschen
 bsr setpen                     * Schreiben
 lea copyr(pc),a0               * Copyright nur einmal am Anfang ausgeben
 moveq #$00,d0
 moveq #100,d2
 bsr centertxt                  * Copyright ausgeben

 lea copyr2(pc),a0
 moveq #$33,d0
 moveq #60,d2
 bsr centertxt

 lea ausbuf(a5), a0
 lea copyr3(pc), a1
init3a:
 move.b (a1)+, (a0)+            * Copyright3 nach ausbuf
 bne.s init3a
 subq.l #1, a0                  * Null raus
 bsr prtvers                    * Versionsnummer nach a0
 subq.l #1, a0                  * Null raus
 lea copyr4(pc), a1
init3b:
 move.b (a1)+, (a0)+            * Copyright4 nach ausbuf
 bne.s init3b
 lea ausbuf(a5), a0
 moveq #$11,d0
 moveq #20,d2
 bsr centertxt
 moveq #15,d0                   * 1,5 Sekunden
 ;moveq #1,d0                   * AV! 1,5 Sekunden
 bsr delay                      * warten

 cmpa.l #0, a2                  * Basis = 0 ?
 beq.s init3c                   * ja
 movea.l #$400, a0              * sonst Editorstart auf $400
 bra.s init3d
init3c:
 lea $2000(a5),a0               * Adresse für Editor
init3d:
 move.l a0,stxtxt(a5)           * Anfang
 move.l a0,akttxt(a5)           * und Aktuell
 move.l a0,etxtxt(a5)           * und Ende
 clr.b (a0)                     * Endekennung
 clr.b lrand(a5)                * Linker Rand im Editor auf Null
 clr.b insl(a5)                 * Voreinstellungen Editor
 adda.l #$A000, a0              * Assembler 40KB hinter Editor
 move.l a0,pcorg(a5)
 clr.b debug(a5)                * Debug aus
 move.b #$11,groesse(a5)        * Schriftgröße gleich auf 80 Zeichen
 btst.b #3, keydil(a5)
 beq.s init3e                   * keine GDP64HS
 move.b #$02, cotempo(a5)       * Standard Hardscrollwert
 bra.s init3f
init3e:
 clr.b cotempo(a5)              * Software-Scroll bei co2-Ausgabe
init3f:
 bsr editeiin                   * Init Tabulatoren
 bsr editem                     * Init Macros
 move.b #5,akteprom(a5)         * Promers 2764 voreingestellt
 lea vekdef(pc),a0              * Anwendervektoren
 lea vekdest(a5),a1             * Ziel
 lea basis(pc),a2               * Additionsadresse
 move.l a2,d1
 moveq #7-1,d2                  * 7 Werte
init4:
 move (a0)+,(a1)+               * JMP-Befehle übertragen
 move.l (a0)+,(a1)
 add.l d1,(a1)+                 * Basis addieren
 dbra d2,init4
 lea linedef(pc),a0
 lea trap1(a5),a1               * Jetzt trap1a, linea + linef definieren
 moveq #3-1,d2
init5:
 move (a0)+,(a1)+
 move.l (a0)+,(a1)
 add.l d1,(a1)+
 dbra d2,init5
 lea trapdef(pc), a0
 lea trap2(a5), a1              * Trap #2,3,6-15 im RAM
 move #12-1, d2                 * 12 mal RTE
init5a:
 move (a0), (a1)+
 addq.l #4, a1                  * da 6 Byte
 dbra d2, init5a
 move.l cpuwert(pc), d0
 cmp.l #1, d0
 beq.s init6a                   * init6 nicht für 68008
 lea vekdef(pc),a0
 lea intlv1(a5),a1              * Jetzt 68000-Interrupt-Ebenen
 moveq #4-1,d2
init6:
 move (a0),(a1)+
 move.l 2(a0),(a1)
 add.l d1,(a1)+
 dbra d2,init6
init6a:
 lea mausdef(pc),a0
 lea mausadr0(a5),a1
 moveq #2-1,d2                  * Jetzt Eingabegerät (Maus)
init7:
 move (a0)+,(a1)+
 move.l (a0)+,(a1)
 add.l d1,(a1)+
 dbra d2,init7                   * Übertragung aller Vektoren abgeschlossen
 move.b keydil(a5),d1           * DIL-Schalter holen
 move.b #$80,d0                 * Bit 7 setzen
 move.b d0,menflag(a5)          *
 lsr #3,d1                      * Bit 3 auf Bit 0
 and.b #1,d1                    * Nur Bit 0 lassen
 move.b d1, ioflag(a5)
 clr.b aktser(a5)
 move.b #$1e,ser3.w             * Standarteinstellung SER
 move.b #$0b,ser2.w
 cmp.b #$1e,ser3.w
 bne.s init7a                   * Nicht vorhanden
 cmp.b #$0b,ser2.w
 bne.s init7a                   * Nicht vorhanden
 bset.b #2, ioflag(a5)          * SER ist vorhanden
 move.b #1, aktser(a5)          * SER ist aktueller Kanal
 lea nvrbuff(a5), a0
 cmp #$a5c3, (a0)               * NVRAM Daten?
 bne.s init7a                   * nein
 move.b 8(a0), d0
 move.b 9(a0), d1
 bsr siinit
init7a:
 move.b ser2c.w, d0             * Interrupt Vector Reg SER2
 cmp.b #$0f, d0                 * Startwert nach RESET
 bne.s init8                    * keine SER2
 move.b #$5a, ser2c.w           * Testwert
 cmp.b #$5a, ser2c.w            * ist drinn?
 bne.s init8                    * nein, doch keinen SER2
 move.b d0, ser2c.w             * wieder herstellen
 move.b #$10, d0                * SER2 Kanal A initialisieren
 lea nvrbuff(a5), a0
 cmp #$a5c3, (a0)               * NVRAM Daten?
 bne.s init7b                   * nein
 adda.l #10, a0                 * Auf SER2 Kanal A
 bra.s init7c
init7b:
 lea s2bd9600(pc), a0           * 9600,E,8,1
init7c:
 bsr siinit
 move.b #$11, d0                * SER2 Kanal B initialisieren
 lea nvrbuff(a5), a0
 cmp #$a5c3, (a0)               * NVRAM Daten?
 bne.s init6d                   * nein
 adda.l #16, a0                 * Auf SER2 Kanal B
 bra.s init6e
init6d:
 lea s2bd9600(pc), a0           * 9600,E,8,1
init6e:
 bsr siinit
 bset.b #3, ioflag(a5)          * SER2-Bit
 tst.b aktser(a5)               * schon ne SER da?
 bne.s init8                    * jo, dann weiter
 move.b #2, aktser(a5)          * sonst Kanal A der SER2 aktuell
 move.b $01, ser2f.w            * LED Kanal A an
init8:
 move.b #1,optflag(a5)          * Deutscher Zeichensatz an
 move.l #'user',fontname(a5)    * Name des User-Zeichensatzes setzen
 move.b #2,dflag0(a5)           * Druckerinit nur einmal (Deutscher Zeichensatz)
 clr.b dflag1(a5)
 move.b #65,dflag2(a5)          * Zeilen pro Seite
 clr.b dflag3(a5)               * Linker Rand
 st drsave(a5)                  * Keine selbstdefinierten Befehle
                                * Init für Grafik-Paket
 clr.b gdpvpage(a5)             * Leseseite
 clr.b gdpwpage(a5)             * und Schreibseite auf Null
 clr.b gdpscroll(a5)            * Kein Scroll bisher
 clr.b gdpxor(a5)               * Kein XOR-Mode
 move.b #1,gdpcolor(a5)         * Farbe ist weiß
 bsr clutinit                   * CLUT auf Standartwerte einstellen
 bsr mausaus                    * Maus rücksetzen
 bsr drbefinit                  * Drucker-Befehle ins Ram kopieren
 bsr casinit                    * Kassetteninterface ein
 bsr loinit                     * Drucker init
 bsr ciinit2                    * ci2 init
 bsr mausaus                    * Maus rücksetzen
 bsr symloesche
 move.l #$a140557a,poweron(a5)  * Power ist an
 bra getstack                   * Stack in d0 zurückliefern

*******************************************************************************
*                        680xx Grundprogramm mendiv3                          *
*                         (C) 1990 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                 Diverse Unterprogramme der Menüsteuerung                    *
*******************************************************************************


getstx:                         * Adresse Editor holen
 move.l stxtxt(a5),d0
 rts

putstx:                         * Adresse Editor setzen
 move.l d0,stxtxt(a5)
 move.l d0,akttxt(a5)
 movea.l d0,a0                  * Adresse nach a0
put1stx:
 tst.b (a0)+                    * Bis Null gefunden
 bne.s put1stx
 subq.l #1,a0                   * 1 Byte zurück
 move.l a0,etxtxt(a5)           * Ende gesetzt
 rts

setxor:                         * XOR-Mode für GDP setzen
 and.b #$f,d0
 move.b d0,xormode(a5)
 bra aktpage                     * Aktuelle Seite setzen und XOR-Mode

getxor:                         * XOR-Mode nach d0
 moveq #0,d0
 move.b xormode(a5),d0
 rts

setcolor:                       * Farbe setzen
 move.b d0,fgcolor(a5)          * Farbe merken
 move.b d1,bgcolor(a5)
 bra aktpage                     * Seite und Farbe setzen

getcolor:                       * Farbe holen
 clr d0
 clr d1
 move.b fgcolor(a5),d0
 move.b bgcolor(a5),d1
 rts

settrans:                       * Tranparent-Modus der GDP-FPGA setzen/löschen
 and.b #$1, d0                  * nur Bit #0
 move.b d0,transmod(a5)
 bra aktpage

gettrans:                       * Transparent-Modus der GDP-FPGA holen
 moveq #0, d0
 move.b transmod(a5), d0
 rts
 
curonein:                       * Cursor einschalten
 move.b #1,curon(a5)
 rts

curonaus:                       * Cursor ausschalten
 clr.b curon(a5)
 rts

getbasis:                       * Basisadresse Grundprogramm laden
 lea basis(pc),a0
 move.l a0,d0
 rts

getvar:                         * Variablenadresse laden
 lea basis(pc),a0
 adda.l ramstart(pc),a0
 move.l a0,d0
 rts

seta5:                          * a5 neu setzen
 lea basis(pc),a5
 adda.l ramstart(pc),a5
 rts

getfrei:                        * Adresse hinter Symboltabelle ermitteln
 lea    symtab+symlen(a5),a0
 bsr.s  getnext
 adda.l d0,a0                   * Ende Symboltabelle + Sicherheitsabstand
 rts

getsymtab:                      * Adresse Symboltabelle holen
 lea symtab(a5),a0
 move.l a0,d0
 rts

getnext:                        * Länge Symboltabelle holen
 moveq #0,d0
 move symnext(a5),d0
 rts

putnext:                        * Adresse für nächsten Symboltabelleneintrag
 move d0,symnext(a5)            * setzen
 rts

getvers:                        * Versionsnummer laden
 move.l versnum(pc),d0
 rts

getsn:                          * Seriennummer laden
 move.l snnum(pc),d0
 rts

getorg:                         * Assemblerzieladresse holen
 move.l pcorg(a5),d0
 rts

putorg:                         * Adresse setzen
 move.l d0,pcorg(a5)
 rts

crtex:                          * Ausgabe auf Screen
 move.b #2,iostat(a5)
 rts

lstex:                          * Ausgabe auf Drucker
 move.b #3,iostat(a5)
 rts

usrex:                          * Ausgabe auf Benutzervektor
 move.b #5,iostat(a5)
 rts

serex:                          * co2 auf serielle Karte umlenken
 btst.b #2,ioflag(a5)           * SER?
 bne.s serex1
 btst.b #3,ioflag(a5)           * SER2?
 beq carset                     * Keine SER vorhanden
serex1:
 move.b #6,iostat(a5)
 bra carres                      * OK

nilex:                          * Ausgabe ins Leere
 clr errflag(a5)
erraus:                         * Nur Fehlerausgabe
 move.b #1,iostat(a5)
 rts

seraus:                         * Umlenkung auf serielle Karte
 btst.b #2,ioflag(a5)           * SER?
 bne.s seraus1
 btst.b #3,ioflag(a5)           * SER2?
 beq carset                     * Keine Umschaltung, wenn keine SER vorhanden
seraus1:
 move.b d0,serflag(a5)
 bra carres                      * OK

seterr:                         * Fehlerflag setzen
 move d0,errflag(a5)
 rts

geterr:                         * Fehlerflag holen
 move errflag(a5),d0
 rts

setpass:                        * Passflag setzen
 move d0,passflag(a5)
 rts

gdpvers:                        * GDP-Version abfragen
 moveq #0,d0
 move.b ioflag(a5),d0           * 0 = Alte GDP / 1 = Neue GDP
 and.b #1,d0
 rts

asserr:                         * Fehleranzahl nach d0.l
 moveq #0,d0                    * Wort innerhalb eines Langwortes
 move errcnt(a5),d0
 rts

getcurxy:                       * Cursor Position nach d1.l / d2.l
 moveq #0,d1                    * Byte innerhalb Langwort
 moveq #0,d2
 move.b curx(a5),d1
 move.b cury(a5),d2
 rts

setcurxy:                       * Neuer Cursor d1=curx d2=cury
 movem.l d1-d2,-(a7)
 move.b d1,curx(a5)
 move.b d2,cury(a5)
 bsr aktcur                     * Cursor mit neuen Werten setzen
 movem.l (a7)+,d1-d2
 rts

setflip:                        * Seitenumschaltung
 move.b d0,flip(a5)             * d0 = flip0
 move.b d0,flipcnt(a5)          * Doppelseite
 move.b d1,flip1(a5)            * d1 = flip1
 move.b d1,flip1cnt(a5)         * Viererseite
 rts

setgroe:                        * Setzt Zeichengröße für co2 etc.
 move.b d0,groesse(a5)          * Größe $11 und $21 sinnvoll
 move d0,-(a7)                  * Andere sind denkbar
 and #$f,d0                     * Y-Vergrößerung lassen
 cmp #1,d0                      * 1 ?
 beq.s setgroe1                 * Ja, dann OK
 clr.b cotempo(a5)              * Sonst nur Software-Scroll erlaubt
setgroe1:                       * ACHTUNG !!!
 move (a7)+,d0                  * Dieses Programm darf nicht während der CO2-
 rts                             * Ausgabe benutzt werden


*******************************************************************************
*                         680xx Grundprogramm dos1                            *
*                         (C) 1990 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                         Menüsteuerung für JADOS                             *
*******************************************************************************


*********************** Diskettenfunktionen unter JADOS ***********************
*      Hier ändern, wenn an anderes Betriebssystem angepasst werden soll      *
*                             Siehe auch dos2.asm                             *
*******************************************************************************

savedisk:                       * Daten auf Disk speichern
 bsr    dostest
 bcs    carset
 lea    menue31(pc),a0
 bsr    menueio
 cmp.b  #'1',d0
 beq.s  savedatei
 cmp.b  #'2',d0
 beq.s  saveedit                * Editordaten speichern
 cmp.b  #'3',d0
 beq    savedruck               * Druckerdaten speichern
 rts

savedatei:                      * Datei speichern
 lea    sadadt0(pc),a0
 lea    sadadt1(pc),a1
 move   #180,d3
 bsr    doswerte
 bcs    carset
 bsr    fillfcb                 * Namen eintragen
 bcs    doserr0
 lea    sadadt2(pc),a0
 moveq  #115,d2
 bsr    doswert0
 bcs    carset
 bsr    wertmfeh
 bcs    carset
 movea.l d0,a2                  * Quelladresse merken
 lea    sadadt3(pc),a0
 moveq  #50,d2
 bsr    doswert0
 bcs    carset
 bsr    wertmfeh
 bcs    carset
 subq   #1,d0                   * Anzahl Sektoren minus 1
 move   d0,d1
 lea    einbuf+40(a5),a1
 movea.l a2,a0
 bsr    filesave                * JADOS-Funktion
 bra     doserr

saveedit:
 lea    saeddt0(pc),a0          * Überschrift
 lea    saeddt1(pc),a1          * Frage-Text
 moveq  #125,d3                 * Y-Koordinate
 bsr    doswerte                * Namen holen
 bcs    carset
saveed0:
 bsr    fillfcb
 bcs    doserr0                 * a1 = Buffer
 bsr    getfrei
 movea.l a0,a2
 move.l #'RDED',(a2)+
 move.l #'ITOR',(a2)+           * Kennung, daß es Editordaten sind
 move.b groesse(a5),(a2)+       * Ausgabegröße
 move.b insl(a5),d0
 and.b  #%00011001,d0
 move.b d0,(a2)+                * Einfügemode, Scroll-Art, Anfangsposition
 move.b lrand(a5),(a2)+         * Linker Rand
 move.b optflag(a5),(a2)+       * Zeichensatz
 lea    edittabs(a5),a3
 moveq  #80-1,d0
saveed1:
 move.b (a3)+,(a2)+             * Alle Tab-Positionen
 dbra    d0,saveed1
 lea    editmacro(a5),a3
 move   #41*10-1,d0
saveed2:
 move.b (a3)+,(a2)+             * Alle Macros des Editors
 dbra    d0,saveed2
 move.l #'ENDE',(a2)+           * Endekennung
 moveq  #0,d1                   * 1 Sektor
 bsr    filesave                * JADOS-Funktion
 bra     doserr

savedruck:
 lea    sadrdt0(pc),a0          * Überschrift
 lea    sadrdt1(pc),a1          * Frage-Text
 moveq  #125,d3                 * Y-Koordinate
 bsr    doswerte                * Namen holen
 bcs    carset
 bsr    fillfcb
 bcs    doserr0                 * a1 = Buffer
 bsr    getfrei
 movea.l a0,a2
 move.l #'RDDR',(a2)+
 move.l #'UCKE',(a2)+           * Kennung, daß es Druckerdaten sind
 move.b dflag0(a5),(a2)+        * Druckmodi
 move.b dflag1(a5),(a2)+        * Druckmodi
 move.b dflag2(a5),(a2)+        * Seitenlänge
 move.b dflag3(a5),(a2)+        * Linker Rand
 lea    drbeftab(a5),a3
 moveq  #3*22-1,d0
savedr0:
 move.b (a3)+,(a2)+             * Alle Druckerbefehle
 dbra    d0,savedr0
 lea    drsave(a5),a3
 moveq  #20-1,d0
savedr1:
 move.b (a3)+,(a2)+             * Alle eigenen Befehle
 dbra    d0,savedr1
 move.l #'ENDE',(a2)+           * Endekennung
 moveq  #0,d1                   * 1 Sektor
 bsr    filesave                * JADOS-Funktion
 bra     doserr

loaddisk:                       * Daten von Disk laden
 bsr    dostest
 bcs    carset
 lea    menue31(pc),a0
 bsr    menueio
 cmp.b  #'1',d0
 beq.s  loaddatei
 cmp.b  #'2',d0
 beq.s  loadedit                * Editordaten laden
 cmp.b  #'3',d0
 beq    loaddruck               * Druckerdaten laden
 rts

loaddatei:                      * Datei laden
 lea    lodadt0(pc),a0
 lea    lodadt1(pc),a1
 move   #160,d3
 bsr    doswerte
 bcs    carset
 bsr    fillfcb                 * Namen eintragen
 bcs    doserr0
 lea    lodadt2(pc),a0
 moveq  #90,d2
 bsr    doswert0
 bcs    carset
 bsr    wertmfeh
 bcs    carset
 movea.l d0,a0                  * Zieladresse
 lea    einbuf+40(a5),a1
 bsr    fileload                * JADOS-Funktion
 bra     doserr

loadedit:
 lea    loeddt0(pc),a0          * Überschrift
 lea    loeddt1(pc),a1          * Frage-Text
 moveq  #125,d3                 * Y-Koordinate
 bsr    doswerte                * Namen holen
 bcs    carset
loaded0:
 bsr    fillfcb
 bcs    doserr0                 * a1 = Buffer
 bsr    getfrei
 bsr    fileload                * JADOS-Funktion
 bsr    doserr
 bcs    carset
 cmp.l  #'RDED',(a0)+
 bne    doserr0
 cmp.l  #'ITOR',(a0)+           * Kennung, daß es Editordaten sind
 bne    doserr0
 cmp.l  #'ENDE',494(a0)         * Endekennung
 bne    doserr0
 move.b (a0)+,groesse(a5)       * Ausgabegröße
 move.b insl(a5),d0
 and.b  #%00000110,d0
 or.b (a0)+,d0                  * Einfügemode, Scroll-Art, Anfangsposition
 move.b d0,insl(a5)
 move.b (a0)+,lrand(a5)         * Linker Rand
 move.b (a0)+,optflag(a5)       * Zeichensatz
 lea    edittabs(a5),a1
 moveq  #80-1,d0
loaded1:
 move.b (a0)+,(a1)+             * Alle Tab-Positionen
 dbra    d0,loaded1
 lea    editmacro(a5),a1
 move   #41*10-1,d0
loaded2:
 move.b (a0)+,(a1)+             * Alle Macrotexte
 dbra    d0,loaded2
 bra     carres

loaddruck:
 lea    lodrdt0(pc),a0          * Überschrift
 lea    lodrdt1(pc),a1          * Frage-Text
 moveq  #125,d3                 * Y-Koordinate
 bsr    doswerte                * Namen holen
 bcs    carset
 bsr    fillfcb
 bcs    doserr0                 * a1 = Buffer
 bsr    getfrei
 bsr    fileload                * JADOS-Funktion
 bsr    doserr
 bcs    carset
 cmp.l  #'RDDR',(a0)+
 bne    doserr0
 cmp.l  #'UCKE',(a0)+           * Kennung, daß es Druckerdaten sind
 bne    doserr0
 cmp.l  #'ENDE',90(a0)          * Endekennung
 bne    doserr0
 move.b (a0)+,dflag0(a5)        * Druckmodi
 move.b (a0)+,dflag1(a5)        * Druckmodi
 move.b (a0)+,dflag2(a5)        * Seitenlänge
 move.b (a0)+,dflag3(a5)        * Linker Rand
 lea    drbeftab(a5),a1
 moveq  #3*22-1,d0
loaddr0:
 move.b (a0)+,(a1)+             * Alle Druckerbefehle
 dbra    d0,loaddr0
 lea    drsave(a5),a1
 moveq  #20-1,d0
loaddr1:
 move.b (a0)+,(a1)+             * Alle eigenen Befehle
 dbra    d0,loaddr1
 bra     carres

loadfont:
 lea    loftdt0(pc),a0          * Überschrift
 lea    loftdt1(pc),a1          * Frage-Text
 moveq  #125,d3                 * Y-Koordinate
 bsr    doswerte                * Namen holen
 bcs    carset
loadft0:
 bsr    fillfcb
 bcs    doserr0                 * a1 = Buffer
 bsr    getfrei
 bsr    fileload                * JADOS-Funktion
 bsr    doserr
 bcs    carset
 cmp.l  #'NKCF',(a0)+
 bne    doserr0
 cmp.l  #'ONT ',(a0)+           * Kennung, daß es Fontdaten sind
 bne    doserr0
 cmp.l  #'ENDE',484(a0)         * Endekennung
 bne    doserr0
 movea.l a0, a1                 * Pointer sichern
 addq.l #4, a0                  * auf 1.Zeichen
 moveq #96-1, d3                * Anzahl der Zeichen-1
 move.b #' ', d2                * Bei Space beginnen
loadft1:
 move.b d2, d0
 bsr setchar
 bcs carset                     * Fehler beim Zeichen schreiben
 addq.b #1, d2                  * nächstes Zeichen
 dbra d3, loadft1
 move.l (a1)+, fontname(a5)     * erst zum Schluss, wg. Fehler
 bra     carres


inhdisk:                       * Inhaltsverzeichnis ausgeben
 lea    inhdt0(pc),a0
 lea    inhdt1(pc),a1
 moveq  #125,d3
 bsr    doswerte
 bcs    carset
catalog:                        * a1 = Suchmuster
 movea.l a1,a0
 moveq  #11,d7                  * UPPERCAS
 trap   #6
 bsr    getfrei
 move   #$1400,d1               * 5 Kbyte Freiraum
 moveq  #0,d2                   * Nur Name
 moveq  #5,d3                   * 5 Spalten
 move   #1,passflag(a5)         * Keine Ausgabe über JADOS
 moveq  #74,d7                  * DIRECTORY (JADOS-Funktion)
 trap   #6
 move   #2,passflag(a5)
 bsr    doserr
 bcs    carset
 bsr    clrscreen               * Ausgabe mit CO2
 bsr    prtco
 bsr    crlfe
 moveq  #6,d7                   * RESPONSE (JADOS-Funktion)
 trap   #6
 clr.b  flip(a5)                * Keine Seitenumschaltung
 bra     carres

deldatei:                       * Datei löschen
 lea    deldt0(pc),a0
 lea    deldt1(pc),a1
 moveq  #125,d3
 bsr    doswerte
 bcs    carset
 bsr    fillfcb
 bcs    doserr0
 move   #1,passflag(a5)         * Keine Ausgabe über JADOS
 moveq  #17,d7                  * ERASE (JADOS-Funktion)
 trap   #6
 move   #2,passflag(a5)
 bra     doserr

kopdatei:                       * Datei kopieren
 lea    kopdt0(pc),a0
 lea    kopdt1(pc),a1
 lea    kopdt2(pc),a2
 moveq  #15,d6                  * COPYFILE (JADOS-Funktion)
kopdat0:
 move   #160,d3
 bsr    doswerte                * Alten Namen holen
 bcs    carset
 bsr    fillfcb
 bcs    doserr0
 movea.l a2,a0
 moveq  #90,d2
 bsr    doswert0                * Neuer Name
 bcs    carset
 lea    ausbuf(a5),a1
 bsr    fillfcb0
 bcs    doserr0
 lea    einbuf+40(a5),a1
 lea    ausbuf(a5),a2
 move   #1,passflag(a5)         * Keine Ausgabe über JADOS
 moveq  #58,d7                  * GETLADDR (JADOS-Funktion)
 trap   #6                      * Diese Funktion wird bei rendatei nicht
                                * benötigt, stört aber nicht bei COPYFILE
 move   d6,d7                   * JADOS-Funktion
 trap   #6
 move   #2,passflag(a5)
 bra     doserr

rendatei:                       * Datei umbenennen
 lea    rendt0(pc),a0
 lea    rendt1(pc),a1
 lea    rendt2(pc),a2
 moveq  #21,d6                  * RENAME (JADOS-Funktion)
 bra.s kopdat0

fillfcb:                        * JADOS-Funktion
 lea    einbuf+40(a5),a1        * Ziel für Dateisteuerblock
fillfcb0:
 moveq  #11,d7                  * UPPERCAS
 trap   #6
 moveq  #18,d7                  * FILLFCB
 trap   #6
 tst.b  d0
 beq    carres                  * OK
 bra     carset                  * Fehler

doswerte:
 bsr    dostest
 bcs    carset
 bsr    headaclr                * Überschrift
 movea.l a1,a0
 move   d3,d2
doswert0:
 lea    einbuf+90(a5),a1        * Ziel für Namen
 moveq  #$33,d0
 moveq  #5,d1
 bsr    textaus                 * Frage-Text
 sub    #25,d2                  * etwas tiefer
 movea.l a1,a0                  * Adresse Ziel
 moveq  #$22,d0
 moveq  #40,d3                  * 40 Zeichen
 bsr    textein                 * Text holen
 bcs    carset                  * Abbruch
 tst    d4
 beq    carset                  * Kein Zeichen, dann Fehler
 movea.l a1,a0
 bra     carres                  * Sonst OK

doserr:                         * d0 sind Fehlermöglichkeiten
 moveq  #5,d7                   * Floppy-Motoren ausschalten
 trap   #6
 tst.b  d0                      * Fehler ?
 beq    carres                  * Nein
 lea    dostxt2(pc),a0          * Diskette voll
 cmp.b  #2,d0
 beq.s  doserr1
 lea    dostxt3(pc),a0          * Datei nicht vorhanden
 cmp.b  #3,d0
 beq.s  doserr1
 lea    dostxt4(pc),a0          * Neuer Name existiert bereits
 cmp.b  #4,d0
 beq.s  doserr1
 lea    dostxt5(pc),a0          * Diskette voll
 cmp.b  #5,d0
 beq.s  doserr1
 lea    dostxt99(pc),a0         * Nicht genug RAM
 cmp.b  #99,d0
 beq.s  doserr1
doserr0:
 lea    dostxt(pc),a0           * Fehler
doserr1:
 moveq  #$33,d0
 moveq  #10,d2
 bsr    centertxt               * Fehlertext mittig ausgeben
 moveq  #20,d0
 bsr    delay                   * 2 Sekunden warten
 bra     carset                  * Fehler

fileload:
 move   #1,passflag(a5)         * Keine Ausgabe über JADOS
 moveq  #44,d7
 trap   #6
 bra.s   files0

filesave:
 move   #1,passflag(a5)         * Keine Ausgabe über JADOS
 moveq  #45,d7
 trap   #6
files0:
 move   #2,passflag(a5)
 rts


*******************************************************************************
*                          680xx Grundprogramm sys                            *
*                         (C) 1990 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                             System Routinen                                 *
*******************************************************************************


system:                         * Wichtige System Informationen
 move.l d1,-(a7)
 moveq #cpu,d0                  * Bit 0-2 : CPU
 move.b ioflag(a5),d1
 and.b #1,d1
 lsl.b #3,d1
 add.b d1,d0                    * Bit 3   : GDP;  Bit 4   : Keine Bedeutung mehr
 move.b uhrausw(a5),d1
 lsl.b #5,d1
 add.b d1,d0                    * Bit 5-6 : Uhrenkonfiguration
 move.b tracflag(a5),d1
 and.b #%10000,d1
 lsl.b #7-4,d1
 add.b d1,d0                    * Bit 7   : Trace aus/an
 tst.b cotempo(a5)
 beq.s system1
 add #$0100,d0                  * Bit 8   : Hardscroll bei co aus/an
system1:
 move.b menflag(a5),d1
 and #1,d1
 ror #7,d1
 or d1,d0                       * Bit 9   : Keine Bedeutung mehr
 move.b menflag(a5),d1
 and #%01000000,d1
 lsl #4,d1
 or d1,d0                       * Bit 10  : Hardcopy über CI aus/an
 move.b serflag(a5),d1
 and #%1111,d1
 ror #5,d1                      * Bit 11-14 : Umlenkung auf SER
 or d1,d0
 move.b keydil(a5),d1
 and #%10000,d1
 ror #5,d1
 or d1,d0                       * Bit 15 : SCSI-Disk
 move.b ioflag(a5),d1
 lsr.b #1,d1
 and.w #%111,d1
 swap d1
 clr d1
 or.l d1,d0                     * Bit 16 : Key3, Bit 17 : SER, Bit 18 : SER2
 move.b keydil(a5),d1
 and #%100000,d1
 ror #2,d1
 swap d1
 clr d1
 or.l d1,d0                     * Bit 19 : IDE-Disk
 tst srdcap(a5)
 beq.s system2
 bset.l #20, d0                 * Bit 20 : SRAMDISK
system2:
 btst.b #6, keydil(a5)
 beq.s system3
 bset.l #21, d0                 * Bit 21 : GDP-FPGA
system3:
 tst.b gdpcol(a5)
 beq.s system4
 bset.l #22, d0                 * Bit 22 : Farbvariante der GDP-FPGA
system4:
 move.l (a7)+,d1
  rts

setsys:                         * Systemeinstellungen in das NVRAM
 cmp.b #$03, uhrausw(a5)
 bne.s setsys10                 * keine Dallas Uhr vorhanden
 movem.l a0/a1, -(a7)
 movea.l a0, a1                 * A0 sichern
 addq.l #2, a0                  * Datenbereich
 bsr nvrsum                     * Kontrollsumme der NVR-Daten
 move d0, (a1)                  * Kontrollsumme in Datenblock
 movea.l a1, a0
 bsr nvrwrite
 clr d0
 movem.l (a7)+, a0/a1
  rts
setsys10:
 move #-1, d0                   * -1 = keine Dallas Uhr
  rts

getsys:                         * Systemeinstellungen aus dem NVRAM
 cmp.b #$03, uhrausw(a5)
 bne.s getsys10                 * keine Dallas Uhr vorhanden
 movem.l a0/a1, -(a7)
 movea.l a0, a1                 * A0 sichern
 bsr nvrread                    * NVRAM lesen
 movea.l a1, a0
 addq.l #2, a0                  * Datenbereich
 bsr nvrsum                     * Kontrollsumme der NVR-Daten
 cmp (a1), d0
 bne.s getsys11                 * Daten nicht gültig
 movem.l (a7)+, a0/a1
 clr d0
  rts
getsys10:
 move #-1, d0                   * -1 = Keine Dallas Uhr
  rts
getsys11:
 move #-2, d0                   * NVRAM Daten ungültig
 movem.l (a7)+, a0/a1
  rts

nvrsum:                         * Kontrollsumme des NVRAMs berechnen
 move.l d3, -(a7)
 move #30-1, d3                 * Anzahl der NVRAM-Bytes -2
 clr.l d0
nvrsum01:
 add.b (a0)+, d0
 dbra d3, nvrsum01
 and.l #$0000FFFF, d0           * nur ein Wort
 move.l (a7)+, d3
  rts

nvrread:                        * lesen des NVRAMs nach a0
 movem.l d2/d3, -(a7)
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
 move #32-1, d3                 * 32 Byte
 move #$0e, d2                  * ab RTC-Adresse $0E
nvrread1:
 move.b d2, rtcreg.w            * RTC Adresse
 move.b rtcdat.w, (a0)+         * RTC Daten
 addq #1, d2                    * nächste Adresse
 bsr uwait                      * etwas warten
 dbra d3, nvrread1
 move (a7)+, sr                 * Staus zurück
 movem.l (a7)+, d2/d3
  rts

nvrwrite:                       * schreiben von a0 nach NVRAM
 movem.l d2/d3, -(a7)
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
 move #32-1, d3                 * 32 Byte
 move #$0e, d2                  * ab RTC-Adresse $0E
nvrw1:
 move.b d2, rtcreg.w            * RTC Adresse
 move.b (a0)+, rtcdat.w         * RTC Daten
 addq #1, d2                    * nächste Adresse
 bsr uwait                      * etwas warten
 dbra d3, nvrw1
 move (a7)+, sr                 * Staus zurück
 movem.l (a7)+, d2/d3
  rts

initnvrb:                       * NVR-Buffer (a0) initialisieren
 movem.l d3/a0-a2, -(a7)
 movea.l a0, a2
 move #32-1, d3
invrb01:
 clr.b (a0)+
 dbra d3, invrb01
 movea.l a2, a0
 addq.l #2, a0                  * Byte 0 und 1 = Checksumme
 move.b keydil(a5), (a0)+       * DIL; Byte 2
 move.b #0, (a0)+               * Bootdelay; Byte 3
 lea boottab(pc), a1
 move #4-1, d3
invrb02:
 move.b (a1)+, (a0)+            * Autoboot; Byte 4 bis 7
 dbra d3, invrb02
 move.b #$1e, (a0)+             * SER; Byte 8 und 9
 move.b #$0b, (a0)+
 lea s2bd9600(pc), a1
 move #6-1, d3
invrb03:
 move.b (a1)+, (a0)+            * SER2 Kanal A; Byte 10 bis 15
 dbra d3, invrb03
 lea s2bd9600(pc), a1
 move #6-1, d3
invrb04:
 move.b (a1)+, (a0)+            * SER2 Kanal B; Byte 16 bis 21
 dbra d3, invrb04
 movem.l (a7)+, d3/a0-a2
  rts

patch:
 cmp #192, d0                   * max. Trapnummer
 bhi.s patcher
 subq #1, d0                    * auf 0-...
 ble.s patcher                  * <=0? dann Fehler
 movem.l d1/a1, -(a7)           * A0 sichern
 lea traptab, a1
 add d0, d0
 add d0, d0                     * *4 da Langwort-Tabelle
 move.l 0(a1, d0.w), d1         * alten Wert auslesen
 move.l a0, 0(a1, d0.w)         * neuen Wert eintragen
 movea.l d1, a0                 * alter Wert für Rückgabe
 clr.l d0                       * D0 = 0 für OK
 movem.l (a7)+, d1/a1
  rts
patcher:
 move.l #-1, d0                 * d0 = -1 als Fehler
  rts

*******************************************************************************
*                         680xx Grundprogramm Except                          *
*                         (C) 1990 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                           Exceptionbehandlung                               *
*******************************************************************************


trap_rts:                        * Trap ausführen (Alte Version)
 lea basis(pc),a5
 adda.l ramstart(pc),a5         * a5 erstmal setzen
 cmp #192,d7
 bhi.s traprerr                 * Zu Groß -> Fehler
 add d7,d7
 add d7,d7                      * Mal 4, da Langwort
 lea traptab.w,a6
 movea.l -4(a6,d7.w),a6
 jmp (a6)                       * Sprung zum Unterprogramm

traprerr:
tnotimp:
  rts                            * Nicht initialisierter Trap

trap1a:                         * Trap-Routine jetzige Version
 lea basis(pc),a5
 adda.l ramstart(pc),a5         * a5 neu setzen
 cmp #192,d7
 bhi.s traperr                  * Außerhalb des Bereichs
 add d7,d7
 add d7,d7                      * Mal 4, da Langwort-Tabelle
 lea traptab.w,a6
 movea.l -4(a6,d7.w),a6
 jsr (a6)
 move sr,d7                     * Statusregister nach d7
 move.b d7,1(a7)                * Nur Flags ändern, Statusregister bleibt
traperr:                        * erhalten
trap0a:
 rte                            * Ende mit RTE nicht mit RTS

intlvx:                         * Falscher Interrupt
 lea inttxt(pc),a6
 bra.s error

buserr:                         * Busfehler
 lea bustxt(pc),a6
 bra.s spezerr

adrerr:                         * Adressfehler
 lea adrftxt(pc),a6
 bra.s spezerr

illins:                         * Falscher Befehl
 lea illtxt(pc),a6
 bra.s error

zerdiv:                         * Division durch Null
 lea zertxt(pc),a6
 bra.s error

chkins:                         * Check-Befehl
 lea chktxt(pc),a6
 bra.s error

trapvins:                       * Trap-Fehler
 lea traptxt(pc),a6
 bra.s error

priv:                           * Privilege-Verletzung
 lea privtxt(pc),a6
 bra.s error

lineaer:                        * Befehlscode $AXXX
 lea linatxt(pc),a6
 bra.s error

linefer:                        * Befehlscode $FXXX
 lea linftxt(pc),a6
 bra.s error

format:                         * Falsches Stackformat (Ab 68010)
 lea formattxt(pc),a6
 bra.s error

spezerr:                        * Einsprung Adress- und Busfehler
 addq.l #8,a7                   * Mehr Daten auf dem Stack, die abgebaut werden
                                * Beim 68010 muß der Befehl gestrichen werden

error:                          * Fehlerbehandlung
 move.l a5,-(a7)                * a5 retten
 lea basis(pc),a5               * a6 geht verloren
 adda.l ramstart(pc),a5         * a5 neu belegen für Grundprogramm Variablen
 movem.l d0-d7/a0-a5,regsave(a5)* Register retten
 move.l (a7)+,regsave+13*4(a5)  * a5 auch
 move (a7)+,srsave(a5)          * Statusregister
 move.l (a7)+,pcsave(a5)        * Programmcounter
 move.l a7,regsave+15*4(a5)     * a7 auch retten
 move.l usp,a0                  * USP holen
 move.l a0,uspsave(a5)          * und retten
 move.l a7,sspsave(a5)          * SSP extra retten
 lea stack(a5),a7               * Dummy Stack
 clr.b flip(a5)
 clr.b flip1(a5)                * Keine Seitenumschaltung
 clr.b page1.w                  * Kein Scroll mehr
 bsr erakreuz                   * Fadenkreuz aus
 movea.l a6,a0                  * a6 nach a0 für Textausgabe
 bsr headaclr                   * Text mittig ausgeben
 tas.b menflag(a5)              * Nach Reset wieder mit Hardcopy
 bsr regdump                    * Debug-Info ausgeben
errlp:
 bsr ki                         * Zeichen von Tastatur
 cmp.b #'M',d0                  * 'M' bringt Neustart
 beq start                      * Neu-Start
 cmp.b #'W',d0                  * 'W' bringt Warmstart
 bne.s errlp                    * Warm-Start
 bsr getstack                   * Stackbereich holen
 movea.l d0,a7                  * Ende des Rambereiches
 bclr.b #2,menflag(a5)          * Grundprogramm nicht als Aufruf
 bclr.b #4,tracflag(a5)         * Trace aus
 bra smenue
 *******************************************************************************
*                         680xx Grundprogramm Menue                           *
*                         (C) 1990 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                              Menüsteuerung                                  *
*******************************************************************************


grund:                          * Menüpunkte aufrufen
 movem.l d0-d7/a0-a6,-(a7)      * Register retten
 move.b menflag(a5),-(a7)       * menflag auch
 tst d0
 bmi.s grund1                   * d0 negativ bedeutet eine bestimmte Routine
 or.b #%10000100,d0             * Bits in menflag setzen
 move.b d0,menflag(a5)          *
 bsr smenue                     * Menüsteuerung aufrufen
 bra.s grund2                    * Ende

grund1:
 bclr.b #7,menflag(a5)          * Keine Hardcopy bei Einzelprogrammen
 neg d0                         * Negieren
 subq #1,d0                     * Bereich 1..33
 cmp #maxgrund,d0
 bhi.s grund2                   * Zu groß, kein Programm
 add d0,d0
 move grundtab(pc,d0),d0
 jsr grundtab(pc,d0)            * Programm aufrufen, da Adressberechnung OK
grund2:
 move.b (a7)+,menflag(a5)       * menflag zurück
 movem.l (a7)+,d0-d7/a0-a6      * Register zurück
 rts

grundtab:                       * d0 = -X
 DC.w aendere-grundtab          * 1
 DC.w startex-grundtab          * 2
 DC.w speicheraus-grundtab      * 3
 DC.w symbolaus-grundtab        * 4
 DC.w edit-grundtab             * 5
 DC.w mass-grundtab             * 6
 DC.w bibo-grundtab             * 7
 DC.w savedisk-grundtab         * 8
 DC.w loaddisk-grundtab         * 9
 DC.w inhdisk-grundtab          * 10
 DC.w deldatei-grundtab         * 11
 DC.w kopdatei-grundtab         * 12
 DC.w rendatei-grundtab         * 13
 DC.w boot-grundtab             * 14
 DC.w promwrite-grundtab        * 15
 DC.w promread-grundtab         * 16
 DC.w ausspber-grundtab         * 17
 DC.w druckmen-grundtab         * 18
 DC.w ioread-grundtab           * 19
 DC.w iowrite-grundtab          * 20
 DC.w einzel-grundtab           * 21
 DC.w sysmen-grundtab           * 22
 DC.w textalt-grundtab          * 23
 DC.w textneu-grundtab          * 24
 DC.w symloe-grundtab           * 25
 DC.w groess21-grundtab         * 26
 DC.w groess11-grundtab         * 27
 DC.w debugein-grundtab         * 28
 DC.w debugaus-grundtab         * 29
 DC.w erraus-grundtab           * 30
 DC.w crtex-grundtab            * 31
 DC.w lstex-grundtab            * 32
 DC.w lstolf-grundtab           * 33

grundtend:

maxgrund EQU (grundtend-grundtab)/2

start:                          * Grundprogramm Start beim Einschalten / Reset
 tst.b $7000.w                  * BOOT-Karte löschen
 move.l cpuwert(pc), d0
 cmp.l #1, d0
 bne.s start01
 move.b #$80,bankboot.w         * BANKBOOT-Karte löschen 68008
 bra.s start02
start01:
 move.w #$8080,bankboot.w       * Beide BANKBOOT-Karten löschen 68000
start02:
 lea basis(pc),a5
 adda.l ramstart(pc),a5         * a5 als Zeiger auf Variablen setzen
 lea stack(a5),a7               * Dummy Stack
 bsr init                       * Variablen init / Copyright ausgeben
 movea.l d0,a7                  * Stack festlegen (Wurde in d0 zurückgegeben)
warmstart:
 cmp.l #$a140557a,bootflag(a5)
 beq.s smenue                   * Wenn Computer schon an war, dann weiter
 move.l #$a140557a,bootflag(a5) * Flag, daß Computer an ist
 btst.b #1,keydil(a5)           * DIL-Schalter 1 auf Key angeschaltet ?
 beq.s smenue                   * Nein, dann normaler Start
 bsr autoboot                   * Ja, dann mit Autoboot beginnen

*******************************************************************************
*                         680xx Grundprogramm smenue                          *
*                         (C) 1990 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                            Hauptmenüsteuerung                               *
*******************************************************************************


smenue:                         * Spezialmenü mit allen Teilen auf einer Seite
 bsr clrall                     * Bildschirm löschen
 moveq #$ff,d7                  * Achtung !!! d7 ist lokaler Sekundenmerker
 lea ausbuf(a5), a0
 lea menue(pc),a1
smena00:
 move.b (a1)+, (a0)+            * menue Text nach ausbuf kopieren
 bne.s smena00
 subq.l #1, a0                  * Null raus
 bsr prtcpu
 subq.l #1, a0                  * Null raus
 bsr prtvers                    * Versionsnummer nach ausbuf
smena20:
 lea ausbuf(a5),a0
 moveq #$33,d0
 move #220,d2
 bsr centertxt                  * Überschrift
 lea smentxt(pc),a0
 moveq #$21,d0
 moveq #5,d1
 move #206,d2
 bsr textprint                  * Menü Teil 1
 lea smentxt0(pc),a0
 move #269,d1
 bsr textprint
 btst.b #2,menflag(a5)
 beq.s smen1                    * Grundprogramm nicht als Aufruf, dann weiter
 lea smentxt1(pc),a0
 moveq #$21,d0
 move #269,d1
 moveq #126,d2
 bsr textprint                  * Da Grundprogramm als Aufruf mit 'Z = BEENDEN'
smen1:
 lea smentxt4(pc),a0            * 1. Infozeile
 lea ausbuf(a5),a1              * Nach ausbuf bringen
smen2:
 move.b (a0)+,(a1)+             * Übertragen bis Null
 bne.s smen2
 lea ausbuf+10(a5),a0
 move.l stxtxt(a5),d0
 bsr print8x                    * Editoranfangsadresse einfügen
 move.b #' ',(a0)
 lea ausbuf+30(a5),a0
 move.l etxtxt(a5),d0
 bsr print8x                    * Editorendadresse
 move.b #' ',(a0)
 lea symtab(a5),a0
 move.l a0,d0
 lea ausbuf+50(a5),a0
 bsr print8x                    * Symboltabellenstart
 move.b #' ',(a0)
 moveq #0,d0
 move symnext(a5),d0
 lea symtab(a5),a0
 add.l a0,d0
 lea ausbuf+70(a5),a0
 bsr print8x                    * Symboltabellenende
 lea ausbuf(a5),a0
 moveq #$11,d0
 moveq #5,d1
 moveq #13,d2
 bsr textaus                    * Zeile ausgeben
 moveq #83,d3
 bsr umrande                    * Mit Umrandung
smen3:
 lea smentxt2(pc),a0            * 2. Infozeile
 lea ausbuf+2(a5),a1
smen4:
 move.b (a0)+,(a1)+
 bne.s smen4                    * Auch übertragen
 subq.l #1,a1                   * Null ignorieren
 moveq #0,d0
 move.b iostat(a5),d0           * Ausgabe-Kanal holen
 lsl #4,d0                      * Für Textberechnung
 lea smentxt3-16(pc),a0         * -16, da iostat Bereich  1..6 hat
 adda.l d0,a0                   * Adresse Text berechnet
smen5:
 move.b (a0)+,(a1)+             * Übertragen
 bne.s smen5
 clr d1
 move.b groesse(a5),d1
 lsr #4,d1                      * X-Größe holen
 bne.s smen50
 moveq #16,d1                   * Null ist Vergrößerung 16
smen50:
 moveq #80,d0
 divs d1,d0                     * Zeichen pro Zeile berechnen
 lea ausbuf(a5),a0
 bsr print4d                    * Und in Infozeile einfügen
 move.b #' ',(a0)
 tst.b debug(a5)
 beq.s smen6                    * Debug aus, dann nichts ändern
 move.l #'an  ',ausbuf+32(a5)   * Text, daß Debug an ist einfügen
smen6:
 lea ausbuf(a5),a0
 moveq #$11,d0
 moveq #5,d1
 moveq #2,d2
 bsr textaus                    * 2. Infozeile ausgeben
 moveq #83,d3
 bsr umrande                    * Mit Umrandung
smen7:
 tst.b uhrausw(a5)
 beq.s smen8                    * Keine Uhr an, dann weiter
 lea einbuf(a5),a0
 bsr getuhr                     * Uhrzeit holen
 move.b einbuf+6(a5),d0
 cmp.b d7,d0
 beq.s smen8                    * Alte Zeit = Neue Zeit, dann nicht ausgeben
 move.b d0,d7                   * Sekunden merken
 lea ausbuf(a5),a0
 moveq #2,d0                    * Anzahl Buchstaben für Tag
 bsr uhrprt0                    * Uhrzeit umwandeln
 lea ausbuf(a5),a0
 moveq #$11,d0
 move #365,d1
 moveq #2,d2
 bsr textaus                    * Uhrzeit ausgeben
smen8:
 bsr csts                       * Zeichen von Tastatur da
 beq.s smen7                    * Nein, nochmal
 bsr ki                         * Zeichen als Großbuchstaben holen
 btst.b #2,menflag(a5)
 beq.s smen9                    * Grundprogramm als Aufruf, dann weiter
 cmp.b #'Z',d0                  * Sonst ist 'Z' nicht erlaubt
 bne.s smen9
 rts
smen9:
 cmp.b #':',d0                  * Kleiner als ':', dann Optionen
 bmi.s smen10
 cmp.b #'A',d0                  * Kleiner als 'A', dann Fehler
 bmi smen7
 cmp.b #'Y',d0                  * Größer als 'Y', dann auch Fehler
 bhi smen7
 lea grundtab-'A'(pc),a1
 add d0,d0
 move -'A'(a1,d0),d1
 jsr 'A'(a1,d1)                 * Programm anspringen
 bra smenue                       * Zurück

smen10:
 sub.b #'0',d0
 bmi smen7                      * Kleiner als Null, dann Fehler
 bsr.s smenue1
 bra smen3

smenue1:
 tst.b d0                       * Maus an/aus
 bne.s smenue10
 rts

smenue10:
 cmp.b #1,d0
 beq groess21                   * 40 Zeichen pro Zeile
 cmp.b #2,d0
 beq groess11                   * 80 Zeichen pro Zeile
 cmp.b #3,d0
 beq debugein                   * Debug an
 cmp.b #4,d0
 beq debugaus                   * Debug aus
 cmp.b #9,d0
 beq.s smenue2                  * Uhr stellen
 subq.b #4,d0
 move.b d0,iostat(a5)           * Ausgabekanal wählen
 rts

smen2tab:                       * X-Pos, Nummer Zeichen, untere Grenze, obere Gr
 DC.w 365,5,1,7
 DC.w 389,2,1,31
 DC.w 407,3,1,12
 DC.w 425,4,0,99
 DC.w 449,0,0,23
 DC.w 467,1,0,59
 DC.w 485,6,0,59

smenue2:
 tst.b uhrausw(a5)
 beq carset                     * Keine Uhr an, dann Ende
 lea einbuf(a5),a0
 bsr getuhr                     * Uhrzeit holen
 lea smen2tab(pc),a6
 moveq #7-1,d7                  * 7 Werte holen
smenue21:
 movem (a6),d1/d2               * Daten holen
 lea einbuf(a5),a4
 adda.l d2,a4                   * Position des Uhrzeitwertes in einbuf
 move.b (a4),d0
 lea ausbuf(a5),a0
 bsr print2x                    * Alten Wert in ASCII wandeln
 lea ausbuf(a5),a0
 moveq #$11,d0
 moveq #2,d2
 moveq #0,d3
 bsr readaus                    * Wert ändern
 bcs carset                     * Abbruch
 lea ausbuf(a5),a0
 bsr wertmfeh                   * Wert berechnen
 bcs.s smenue21                 * Fehler
 movem 4(a6),d2/d3              * Vergleichswerte für obere und untere Grenze
 cmp d2,d0
 bmi.s smenue21                 * Falscher Wert
 cmp d0,d3
 bmi.s smenue21                 * Falscher Wert
 divu #10,d0
 move.b d0,d1
 lsl.b #4,d1
 swap d0
 add.b d1,d0
 move.b d0,(a4)                 * In BCD-Code gewandelt
 addq.l #8,a6                   * Tabelle weiter
 dbra d7,smenue21
 moveq #$ff,d7                  * Sekundenmerker rücksetzen
 lea einbuf(a5),a0
 bra setuhr                      * Uhrzeit setzen

lstolf:
 move.b #4,iostat(a5)           * Auf Drucker ohne LF
 rts

mass:
 bsr assemble                   * Assembler aufrufen
 bra finmenue                    * Ende

prtcpu:                         * CPU-Name nach a0
 movem.l d0/a1, -(a7)
 move.l cpuwert(pc), d0
 cmp.l #1, d0
 bne.s prtcpu01
 lea cpu1(pc), a1               * 68008
 bra.s prtcpu10
prtcpu01:
 cmp.l #2, d0
 bne.s prtcpu02
 lea cpu2(pc), a1               * 68000
 bra.s prtcpu10
prtcpu02:
 lea cpu4(pc), a1               * 68020
prtcpu10:
 move.b (a1)+, (a0)+            * CPU-Name nach ausbuf
 bne.s prtcpu10
 movem.l (a7)+, d0/a1
  rts

prtvers:                        * Versionsnummer als ASCII nach a0
 movem.l d0-d1, -(a7)
 move.l versnum(pc), d0         * Versionsnummer
 move.b #'V', (a0)+
 move.b #' ', (a0)+
 rol #4, d0                     * nur unteres Wort wird beachtet
 move.b d0, d1
 and.b #$0f, d1                 * 10er Stelle
 beq.s prt1vers                 * war Null, dann nicht
 add.b #'0', d1
 move.b d1, (a0)+
prt1vers:
 rol #4, d0
 move.b d0, d1
 and.b #$0f, d1                 * 1er Stelle
 add.b #'0', d1
 move.b d1, (a0)+
 move.b #'.', (a0)+             * Der Punkt
 rol #4, d0
 move.b d0, d1
 and.b #$0f, d1                 * 1/10 Stelle
 add #'0', d1
 move.b d1, (a0)+
 rol #4, d0
 and #$0f, d0
 add.b #'0', d0
 move.b d0, (a0)+               * 1/100 Stelle
 clr.b (a0)+                    * und ne Null
 movem.l (a7)+, d0-d1
  rts
*******************************************************************************
*                         680xx Grundprogramm sysmen                          *
*                         (C) 1990 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                                Systemmenü                                   *
*******************************************************************************


sysmen:                         * System Konfiguration
 lea systxt0(pc),a0
 bsr headaclr                   * Überschrift
 cmp.b #3, uhrausw(a5)          * NVRAM Daten?
 beq.s sysmen2
 lea systxt00(pc),a0            * Text: Kein NVRAM vorhanden
 moveq #$21,d0
 moveq #5,d1
 move #191,d2
 bsr textprint                  * Befehlsliste
sysmen1:
 bsr csts                       * Zeichen von Tastatur da
 beq.s sysmen1                  * Nein, nochmal
 bra carset                     * zurück
sysmen2:
 lea idebuff+32(a5), a2
 move #23-1, d3
 lea systxt1(pc),a0
 moveq #$21,d0
 moveq #5,d1
 move #191,d2
 bsr textprint                  * Befehlsliste
 lea nvrbuff(a5), a0
 cmp #$a5c3, (a0)               * Pufferdaten gültig?
 bne.s sysmen3a                 * nein
 lea idebuff(a5), a1
 move #32-1, d3
sysmen2a:
 move.b (a0)+, (a1)+
 dbra d3, sysmen2a
 bra.s sysmen3
sysmen3a:
 lea idebuff(a5), a0
 bsr initnvrb                   * sonst default Werte
sysmen3:
 move #191, d2
 bsr syszloe                    * Zeile löschen
 lea ausbuf(a5), a0
 move.b #'%', (a0)
 clr.b 1(a0)
 move.b #$21, d0
 move #221, d1
 move #191, d2
 bsr textprint                  * '%' Ausgeben
 lea idebuff(a5), a1
 move.b 2(a1), d0
 lea ausbuf(a5), a0
 bsr print8b
 lea ausbuf(a5), a0
 move.b #$21, d0
 move #233, d1
 move #191, d2
 bsr textprint                  * DIP-Key Ausgabe
 move #171, d2
 bsr syszloe                    * Zeile löschen
 lea ausbuf(a5), a0
 addq.l #4, a1
 moveq #4-1, d3
 bsr sysmenw
 lea ausbuf(a5), a0
 move.b #$21, d0
 move #221, d1
 move #171, d2
 bsr textprint                  * Autoboot Ausgabe
 move #151, d2
 bsr syszloe                    * Zeile löschen
 lea ausbuf(a5), a0
 moveq #2-1, d3
 bsr sysmenw
 lea ausbuf(a5), a0
 move.b #$21, d0
 move #221, d1
 move #151, d2
 bsr textprint                  * SER Ausgabe
 move #131, d2
 bsr syszloe                    * Zeile löschen
 lea ausbuf(a5), a0
 moveq #6-1, d3
 bsr sysmenw
 lea ausbuf(a5), a0
 move.b #$21, d0
 move #221, d1
 move #131, d2
 bsr textprint                  * SER2 Kanal A Ausgabe
 move #111, d2
 bsr syszloe                    * Zeile löschen
 lea ausbuf(a5), a0
 moveq #6-1, d3
 bsr sysmenw
 lea ausbuf(a5), a0
 move.b #$21, d0
 move #221, d1
 move #111, d2
 bsr textprint                  * SER2 Kanal B Ausgabe
 move #91, d2
 bsr syszloe                    * Zeile löschen
 lea ausbuf(a5), a0
 lea idebuff(a5), a1
 clr.l d0
 move.b 3(a1), d0
 bsr print4d
 lea ausbuf(a5), a0
 move.b #$21, d0
 move #221, d1
 move #91, d2
 bsr textprint                  * Bootdelay Ausgabe
sysmen4:
 lea einbuf(a5),a0
 moveq #$21,d0
 moveq #5,d1
 moveq #4,d2
 moveq #1,d3                    * Nur ein Zeichen
 bsr textein                    * Befehl einlesen
 bcs carset                     * Abbruch
 move d5,d0
 bsr bucheck                    * In Großbuchstaben wandeln
 cmp.b #'A', d0
 beq sysmena                    * 'A' = DIP-Key
 cmp.b #'B', d0
 beq sysmenb                    * 'B' = Autoboot
 cmp.b #'C', d0
 beq sysmenc                    * 'C' = SER
 cmp.b #'D', d0
 beq sysmend                    * 'D' = SER2 Kanal A
 cmp.b #'E', d0
 beq sysmene                    * 'E' = SER2 Kanal B
 cmp.b #'F', d0
 beq sysmenf                    * 'F' = Bootdelay
 cmp.b #'M', d0
 beq carres                     * 'M' = Zurück
 cmp.b #'S', d0
 beq sysmens                    * 'S' = Speichern
 cmp.b #'Z', d0
 beq carres                     * 'Z' = Zurück
 bra.s sysmen4

sysmena:
 lea idebuff+2(a5), a1
 move #221,d6                   * X
 move #191,d2                   * Y
 moveq #9,d3                    * Anzahl der Zeichen maximal
 moveq #1-1,d7                  * Maximal 1 Zeichen
 bsr sysmenx
 bra sysmen3

sysmenb:
 lea idebuff+4(a5),a1           * Ziel für Befehle
 move #221,d6                   * X
 move #171,d2                   * Y
 moveq #3,d3                    * Anzahl der Zeichen maximal
 moveq #4-1,d7                  * Maximal 4 Zeichen
 bsr sysmenx
 bra sysmen3

sysmenc:
 lea idebuff+8(a5),a1           * Ziel für Befehle
 move #221,d6                   * X
 move #151,d2                   * Y
 moveq #3,d3                    * Anzahl der Zeichen maximal
 moveq #2-1,d7                  * Maximal 2 Zeichen
 bsr sysmenx
 bra sysmen3

sysmend:
 lea idebuff+10(a5),a1          * Ziel für Befehle
 move #221,d6                   * X
 move #131,d2                   * Y
 moveq #3,d3                    * Anzahl der Zeichen maximal
 moveq #6-1,d7                  * Maximal 6 Zeichen
 bsr sysmenx
 bra sysmen3

sysmene:
 lea idebuff+16(a5),a1          * Ziel für Befehle
 move #221,d6                   * X
 move #111,d2                   * Y
 moveq #3,d3                    * Anzahl der Zeichen maximal
 moveq #6-1,d7                  * Maximal 6 Zeichen
 bsr sysmenx
 bra sysmen3

sysmenf:
 lea idebuff+3(a5), a1
 move #221,d6                   * X
 move #91,d2                    * Y
 moveq #4,d3                    * Anzahl der Zeichen maximal
 moveq #1-1,d7                  * Maximal 1 Zeichen
 bsr sysmenx
 bra sysmen3

sysmens:
 lea idebuff(a5), a1
 lea nvrbuff(a5), a0
 move #32-1, d3
sysmens1:
 move.b (a1)+, (a0)+
 dbra d3, sysmens1
 lea nvrbuff(a5), a0
 bsr setsys
 lea nvrbuff(a5), a0
 move #$a5c3, (a0)
 bra carres

sysmenw:
 move.b #'$', (a0)+
 move.b (a1)+, d0
 bsr print2x
 move.b #' ', (a0)+
 dbra d3, sysmenw
 move.b #0, -1(a0)              * Endnull schreiben
  rts

sysmenx:
 lea einbuf(a5),a0
 moveq #$21,d0
 move d6,d1
 bsr textein                    * Zeichen lesen
 bcs.s sysmenx1                 * Ende
 tst d4
 beq.s sysmenx1                 * Ende
 lea einbuf(a5),a0
 bsr wertmfeh                   * Wert berechnen
 bcs.s sysmenx                  * Fehler, noch einmal eingeben
 move.b d0,(a1)+                * Wert ablegen
 add #48,d6                     * Neue Position
 dbra d7,sysmenx
sysmenx1:
  rts

syszloe:
 moveq #$21,d0                  * Schriftgröße
 move #221,d1                   * X-Position
 bsr setprt                     * Werte einstellen
 bsr erapen                     * Auf Löschen
 moveq #%1010,d0                * Befehl für Block
 moveq #20-1,d3                 * 20 Zeichen löschen
syszloe0:
 bsr cmd                        * Befehl an GDP
 dbra d3,syszloe0
 bsr setpen
  rts

*******************************************************************************
*                         680xx Grundprogramm mendiv                          *
*                         (C) 1990 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                     Diverse Punkte der Menüsteuerung                        *
*******************************************************************************


symloe:
 lea menue23(pc),a0             * Symbole löschen
 bsr menueio
 cmp.b #'1',d0
 beq symloesche                 * Löschen
 rts

textalt:                        * Alten Text feststellen
 lea txtdefa(pc),a0
 bsr headaclr                   * Überschrift
 bsr getadr                     * Adresse holen
 bcc putstx                     * Editor Variablen belegen
 rts                             * Fehler bei Wert

textneu:                        * Neuen Editor einrichten
 lea txtdefn(pc),a0
 bsr headaclr                   * Überschrift
 bsr getadr                     * Adresse holen
 bcs.s textn1                   * Fehler
 movea.l d0,a1                  * Adresse merken
 lea txtm2(pc),a0
 moveq #$22,d0
 moveq #20,d2
 bsr centertxt                  * Abfrage, ob wirklich neuer Text eingerichtet
 bsr ki                         * werden soll
 cmp.b #'J',d0
 bne.s textn1                   * Kein 'J', dann Abbruch
 move.l a1,stxtxt(a5)
 move.l a1,akttxt(a5)
 move.l a1,etxtxt(a5)           * Editor Variablen neu belegt
 clr.b (a1)                     * Null für Endekennung
textn1:
 rts

groess21:
 move.b #$21,groesse(a5)        * 40 Zeichen
 rts

groess11:
 move.b #$11,groesse(a5)        * 80 Zeichen
 rts

debugein:                       * Debug einstellen
 move.b #1,debug(a5)
initdebug:
 move.l etxtxt(a5),d0           * Ende der Texte
 addq.l #3,d0
 and.b #$fe,d0                  * Auf gerade Adresse bringen
 move.l d0,debugst(a5)
 move.l d0,debugak(a5)          * Debug Variablen
 movea.l d0,a0
 clr.l (a0)                     * Null ist Endekennung
 rts

debugaus:
 clr.b debug(a5)                * Debug ausschalten
 rts

*******************************************************************************
*                         680xx Grundprogramm boot                            *
*                         (C) 1990 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                                 Bootmenü                                    *
*******************************************************************************


autoboot:
 lea nvrbuff(a5), a0
 cmp #$a5c3, (a0)               * NVRAM Daten?
 bne.s autob01                  * nein
 move.b 3(a0), bootdel(a5)      * Boot Delayzeit
 adda.l #4, a0                  * auf Autoboot Daten
 bra.s autob02
autob01:
 lea boottab(pc), a0            * Boot-Reihenfolge-Tabelle
autob02:
 move #4-1, d3                  * 4 Einträge in der Tabelle
autob03:
 move.b (a0)+, d0               *
 bsr aboot
 bcc.b autobex                  * Boot war erfolgreich
 dbra d3, autob03
autobex:
  rts

aboot:
 cmp.b #3, d0
 bhi.s aboot01
 moveq #1,d4                    * Ein Bit
 lsl d0,d4                      * An die richtige Stelle schieben
 bsr floboot                    * Floppy
 bra.s abootex
aboot01:
 cmp.b #4, d0
 bhi.s aboot02
 bsr abtdel
 bsr scsiboot                   * SCSI-Disk
 bra.s abootex
aboot02:
 cmp.b #5, d0
 bhi.s aboot03
 bsr abtdel
 bsr ideboot1                   * IDE-Disk
 bra.s abootex
aboot03:
 cmp.b #6, d0
 bhi carset
 bsr sdboot                     * SD-Card
abootex:
  rts

abtdel:                         * Bootdelay, warten auf Laufwerk
 move.b bootdel(a5), d3
 beq.s abtdelx                  * Bootdelay 0 = Fertig
 lea abtdtxt0(pc),a0            * Bootdelay Text
 bsr headaclr
 lea abtdtxt1(pc), a0
 moveq #$33, d0
 move #40, d1
 move #120, d2
 bsr textaus
 lea abtdtxt2(pc), a0
 moveq #$33, d0
 move #202, d1
 move #120, d2
 bsr textaus

 move.b d3, d0
 divu #10, d0                   * /10 auf Sekunden
 and.l #$1f, d0
 lea ausbuf(a5), a0
 bsr print4d
 lea ausbuf(a5), a0
 move.b #$33, d0
 move #148, d1
 move #120, d2
 bsr textaus

 clr.l d0
 move.b d3, d0
 bsr delay                      * warten
 
 clr.b bootdel(a5)              * Nur einmal warten!
abtdelx:
  rts

boottab:                        * wird nur verwendet, wenn kein NVRAM da
 DC.b 0, 4, 5, 3                * Bootreihenfolge: Floppy1, SCSI, IDE, SRAMDISK

boot:                           * Boot-Menü
 tst.b flo2srd(a5)              * Floppy4 nach SRAMDISK aktiv?
 beq.b boota                    * nein
 lea menue34a(pc),a0
 bra.b bootb
boota:
 lea menue34(pc),a0
bootb:
 bsr menueio
 sub.b  #'1',d0
 cmp.b  #3,d0
 bhi.s hardboot                 * 0-3 ist Floppy-Boot
 moveq #1,d4                    * Ein Bit
 lsl d0,d4                      * An die richtige Stelle schieben

floboot:                        * Diskette booten in d4 steht Laufwerk
 bsr getflop                    * Floppy Format feststellen
 bcs.s floboot1                 * Fehler oder keine Floppy geladen
 lea $1800(a5),a0               * Hinter Eprom laden
 moveq #1,d1
 moveq #1,d2
 moveq #0,d3
 bsr floppy                     * Spur 0, Sektor 1 lesen
 bcs.s floboot1
 moveq #0,d0                    * Kennung, daß FLOPPY BOOT
 cmp #$4e71,(a0)                * Erster Befehl muß NOP sein für BOOT Kennung
 bne.s floboot1                 * Fehler
floboot0:
 move.b menflag(a5),-(a7)       * menflag merken
 and.b #%01111011,menflag(a5)   * Kein Grundprogramm mehr
 jsr (a0)                       * Programm aufrufen
 bsr seta5                      * a5 zur Sicherheit auf alten Wert
 move.b (a7)+,menflag(a5)       * menflag zurück
 bra carres                      * Boot wurde durchgeführt
floboot1:
 move.b #$60,flo4.w             * Floppy-Motoren aus
 bra carset                      * Boot wurde nicht ausgeführt

hardboot:
 cmp.b  #4,d0                   * SCSI Disk-Boot
 bne.s  ideboot

scsiboot:
 clr.b scsi2ide(a5)             * SCSI nach IDE Umleitung loeschen
 moveq #1,d4                    * Harddisk 0
 bsr hardtest                   * Testen, ob vorhanden
 bcs carset                     * Nicht vorhanden
 cmp #2,d0
 beq.s scsiboot                 * Warte, bis Laufwerk richtig läuft
 cmp #4,d0
 beq.s scsiboot                 * Warte, bis Laufwerk bereit
 lea $1800(a5),a0               * Zieladresse für Daten
 clr (a0)                       * Sicherheitshalber
 moveq #1,d1                    * Sektor lesen
 moveq #0,d2                    * Sektor 0 lesen
 moveq #1,d3                    * Einen Sektor lesen
 bsr harddisk                   * Keine Fehlerabfrage, da zu aufwendig
 cmp #$4e71,(a0)
 bne carset                     * Fehler
 moveq #1,d0                    * Kennung für SCSI-BOOT
 bra.s floboot0

ideboot:
 cmp.b #5,d0                    * IDE Disk-Boot
 beq ideboot1
 bra.s sdboot

ideboot1:
 clr.b scsi2ide(a5)             * erstmal löschen
 moveq #1, d4                   * IDE Master Laufwerk
 bsr idetest                    * Testen, ob vorhanden
 bcs carset                     * IDE Disk nicht vorhanden
 lea $1800(a5),a0               * Zieladresse für Daten
 clr (a0)                       * Sicherheitshalber
 moveq #1,d1                    * Sektor lesen
 moveq #0,d2                    * Sektor 0 lesen
 moveq #1,d3                    * Einen Sektor lesen
 bsr idedisk                    * Keine Fehlerabfrage, da zu aufwendig
 cmp #$4e71,(a0)                * NOP = NDR Boot?
 bne.s ideboota                 * nein
 lea $1a00(a5),a0               * Zieladresse für 2.Sektor
 moveq #1, d2                   * Sektor 1 lesen
 bsr idedisk
 move.b #1, scsi2ide(a5)        * SCSI nach IDE Umleitung setzen
 moveq #1,d0                    * Kennung für "SCSI"-BOOT
 lea $1800(a5),a0               * hier beginnt der Bootsektor
 bra.s idebootb
ideboota:
 cmp.w #$4e71, 4(a0)            * NOP als 3. Wort?
 bne carset                     * nein, dann nichts weiter tun
 moveq #2,d0                    * Kennung für IDE-BOOT
idebootb:
 move.b menflag(a5),-(a7)       * menflag merken
 and.b #%01111011,menflag(a5)   * Kein Grundprogramm mehr
 jsr (a0)                       * Programm aufrufen
 bsr seta5                      * a5 zur Sicherheit auf alten Wert
 move.b (a7)+,menflag(a5)       * menflag zurück
 clr.b scsi2ide(a5)             * SCSI nach IDE Umleitung loeschen
 bra carres                      * Boot wurde durchgeführt

sdboot:
 cmp.b #6,d0                    * SD-Card Boot
 beq.s sdboot1
 bra carset

sdboot1:
 clr.b scsi2ide(a5)             * erstmal löschen
 moveq #1, d4                   * 1. SD Laufwerk
 bsr sdtest                     * Testen, ob vorhanden
 bcs carset                     * SD-Card nicht vorhanden
 lea $1800(a5),a0               * Zieladresse für Daten
 clr (a0)                       * Sicherheitshalber
 moveq #1,d1                    * Sektor lesen
 moveq #0,d2                    * Sektor 0 lesen
 moveq #1,d3                    * Einen Sektor lesen
 bsr sddisk                     * Keine Fehlerabfrage, da zu aufwändig
 cmp #$4e71,(a0)                * NOP = NDR Boot?
 bne.s sdboota                  * nein
 lea $1a00(a5),a0               * Zieladresse für 2.Sektor
 moveq #1, d2                   * Sektor 1 lesen
 bsr sddisk
 move.b #2, scsi2ide(a5)        * SCSI nach SD Umleitung setzen
 moveq #1,d0                    * Kennung für "SCSI"-BOOT
 lea $1800(a5),a0               * hier beginnt der Bootsektor
 bra.s sdbootb
sdboota:
 cmp.w #$4e71, 4(a0)            * NOP als 3. Wort?
 bne carset                     * nein, dann nichts weiter tun
 moveq #3,d0                    * Kennung für SD-BOOT
sdbootb:
 move.b menflag(a5),-(a7)       * menflag merken
 and.b #%01111011,menflag(a5)   * Kein Grundprogramm mehr
 jsr (a0)                       * Programm aufrufen
 bsr seta5                      * a5 zur Sicherheit auf alten Wert
 move.b (a7)+,menflag(a5)       * menflag zurück
 clr.b scsi2ide(a5)             * SCSI nach SD Umleitung löschen
 bra carres                      * Boot wurde durchgeführt


*******************************************************************************
*                         680xx Grundprogramm drmenue                         *
*                         (C) 1990 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                               Druckermenü                                   *
*******************************************************************************


druckmen:                       * Druckersteuerung
 lea drtxt0(pc),a0
 bsr headaclr                   * Überschrift
 lea drtxt1(pc),a0
 moveq #$21,d0
 moveq #5,d1
 move #207,d2
 bsr textprint                  * Befehlsliste
 bsr.s drall                    * Aktuelle Einstellungen
drmen0:
 lea einbuf(a5),a0
 moveq #$21,d0
 moveq #5,d1
 moveq #4,d2
 moveq #1,d3                    * Nur ein Zeichen
 bsr textein                    * Befehl einlesen
 bcs carset                     * Abbruch
 move d5,d0
 bsr bucheck                    * In Großbuchstaben wandeln
 cmp.b #'Z',d0
 beq carset                     * 'Z' = Zurück
 cmp.b #'A',d0                  * Bereich 'A'
 bmi.s drmen0
 cmp.b #'S',d0                  * bis 'S'
 bhi.s drmen0
 add d0,d0
 move drucktab-2*'A'(pc,d0.w),d1
 jsr drucktab(pc,d1.w)          * Befehl ausführen
 bra.s drmen0

drucktab:                       * Tabelle der Befehle zur Druckereinstellung
 DC.w drmena-drucktab           * Seitenlänge
 DC.w drmenb-drucktab           * Linker Rand
 DC.w drmenc-drucktab           * Druckart
 DC.w drmend-drucktab           * Schriftart
 DC.w drmene-drucktab           * Druck
 DC.w drmenf-drucktab           * Langsamer Druck
 DC.w drmeng-drucktab           * Fettdruck
 DC.w drmenh-drucktab           * Doppeldruck
 DC.w drmeni-drucktab           * Proportionaldruck
 DC.w drmenj-drucktab           * Kursivdruck
 DC.w drmenk-drucktab           * Papiererkennung
 DC.w drmenl-drucktab           * Zeichensatz
 DC.w drmenm-drucktab           * Kopienanzahl
 DC.w drmenn-drucktab           * Eigene Befehle
 DC.w drmeno-drucktab           * Werte rücksetzen
 DC.w initdr-drucktab           * Druckerinit
 DC.w drmenq-drucktab           * Seitenvorschub
 DC.w drmenr-drucktab           * Ausdrucken
 DC.w drbefneu-drucktab         * Druckerbefehle ändern

drmeno:                         * Werte rücksetzen
 move.b #2,dflag0(a5)
 clr.b dflag1(a5)
 move.b #65,dflag2(a5)
 clr.b dflag3(a5)

drall:                          * Druckereinstellungen ausgeben
 bsr.s drmenaa
 bsr.s drmenba
 bsr drmenca
 bsr drmenda
 bsr drmenea
 bsr drmenfa
 bsr drmenga
 bsr drmenha
 bsr drmenia
 bsr drmenja
 bsr drmenka
 bsr drmenla
 bsr drmenma
 bra drmenna

drmena:                         * Seitenlänge
 addq.b #1,dflag2(a5)           * + 1
 and.b #$7f,dflag2(a5)          * Bis 127
 bne.s drmenaa
 addq.b #5,dflag2(a5)           * Von 5 an
drmenaa:
 moveq #0,d0
 move.b dflag2(a5),d0
 moveq #1,d2                    * Zeile 1
drmenab:
 lea ausbuf(a5),a0
 bsr print4d                    * In ASCII wandeln
 move.b #' ',(a0)+
 move.b #' ',(a0)+              * Falls Wechsel von 127 auf 5
 clr.b (a0)                     * Endekennung
 lea ausbuf(a5),a0
 bra draus                       * Ausgeben

drmenb:                         * Linker Rand
 addq.b #1,dflag3(a5)           * + 1
 and.b #$7f,dflag3(a5)          * Bereich 0 bis 127
drmenba:
 moveq #0,d0
 move.b dflag3(a5),d0
 moveq #2,d2                    * Zeile 2
 bra.s drmenab

drmenc:                         * Druckart
 btst.b #1,dflag1(a5)           * Drei Möglichkeiten (%00,%01,%10)
 beq.s drmenc0
 and.b #$fc,dflag1(a5)          * Nach %11 kommt wieder %00
 bra.s drmenca
drmenc0:
 addq.b #1,dflag1(a5)           * Sonst 1 weiter
drmenca:
 lea drtxtc(pc),a0
 move.b dflag1(a5),d0
 and #3,d0                      * Bit 0 und 1
 mulu #7,d0                     * Jeweils 7 Buchstaben
 moveq #3,d2                    * Zeile 3
 bra drausadd

drmend:                         * Schriftart
 bchg.b #2,dflag1(a5)           * Bit 2 bestimmt sie
drmenda:
 lea drtxtd(pc),a0
 move.b dflag1(a5),d0
 lsr #2,d0
 and #1,d0
 mulu #6,d0
 moveq #4,d2                    * Zeile 4
 bra drausadd

drmene:                         * Druck
 bchg.b #3,dflag1(a5)           * Bit 3
drmenea:
 lea drtxte(pc),a0
 move.b dflag1(a5),d0
 lsr #3,d0
 and #1,d0
 mulu #15,d0
 moveq #5,d2                    * Zeile 5
 bra drausadd

drmenf:                         * Langsamer Druck
 bchg.b #4,dflag1(a5)           * Bit 4
drmenfa:
 move.b dflag1(a5),d0
 lsr #2,d0
 moveq #6,d2                    * Zeile 6
 bra drausand

drmeng:                         * Fettdruck
 bchg.b #7,dflag0(a5)           * Bit 7
drmenga:
 move.b dflag0(a5),d0
 lsr #5,d0
 moveq #7,d2                    * Zeile 7
 bra drausand

drmenh:                         * Doppeldruck
 bchg.b #6,dflag0(a5)           * Bit 6
drmenha:
 move.b dflag0(a5),d0
 lsr #4,d0
 moveq #8,d2                    * Zeile 8
 bra drausand

drmeni:                         * Proportionaldruck
 bchg.b #5,dflag0(a5)           * Bit 8
drmenia:
 move.b dflag0(a5),d0
 lsr #3,d0
 moveq #9,d2                    * Zeile 9
 bra drausand

drmenj:                         * Kursivdruck
 bchg.b #4,dflag0(a5)           * Bit 4
drmenja:
 move.b dflag0(a5),d0
 lsr #2,d0
 moveq #10,d2                   * Zeile 10
 bra.s drausand

drmenk:                         * Papiererkennung
 bchg.b #3,dflag0(a5)           * Bit 3
drmenka:
 move.b dflag0(a5),d0
 lsr #1,d0
 bchg   #2,d0                   * Wechseln, da AN/AUS vertauscht
 moveq #11,d2                   * Zeile 11
 bra.s drausand

drmenl:                         * Zeichensatz (%00,%01,%10)
 btst.b #1,dflag0(a5)           * Bit 1
 bne.s drmenl0
 addq.b #1,dflag0(a5)           * + 1
 bra.s drmenla
drmenl0:
 and.b #$fc,dflag0(a5)          * Von %10 Wechsel auf %00
drmenla:
 lea drtxtl(pc),a0
 move.b dflag0(a5),d0
 and #3,d0
 mulu #13,d0
 moveq #12,d2                   * Zeile 12
 bra.s drausadd

drmenm:                         * Anzahl Kopien
 cmp.b #%11011111,dflag1(a5)    * Bit 5-7
 bhi.s drmenm0                  * Wert ist 7
 add.b #%00100000,dflag1(a5)    * Nicht 7, also plus 1
 bra.s drmenma
drmenm0:
 and.b #%00011111,dflag1(a5)    * Von 7 auf 0
drmenma:
 moveq #0,d0
 move.b dflag1(a5),d0
 lsr #5,d0
 lea ausbuf(a5),a0
 bsr print4d
 lea ausbuf(a5),a0
 moveq #13,d2
 bra.s draus

drausand:                       * Ausgabe mit Addition d0,a0
 lea    drtxtf(pc),a0           * Text AN/AUS
 and #%00000100,d0              * Nur Bit 2 behalten ( Entweder Null oder 4 )
drausadd:                       * Nur Addition
 adda d0,a0

draus:                          * Info ausgeben d2 ist Zeile
 muls #-10,d2                   * Zeilenabstand
 add #217,d2                    * Berechnung oberste Zeile
 move #320,d1                   * X-Position
 moveq #$21,d0                  * Zeichengröße
 bra textaus                     * Text ausgeben

drmenn:
 lea drsave(a5),a1              * Ziel für Befehle
 moveq #53,d6                   * X
 moveq #77,d2                   * Y
 moveq #3,d3                    * Anzahl der Zeichen maximal
 moveq #19-1,d7                 * Maximal 20 Zeichen
drmenn0:
 lea einbuf(a5),a0
 moveq #$11,d0
 move d6,d1
 bsr textein                    * Zeichen lesen
 bcs.s drmenn1                  * Ende
 tst d4
 beq.s drmenn1                  * Ende
 lea einbuf(a5),a0
 bsr wertmfeh                   * Wert berechnen
 bcs.s drmenn0                  * Fehler, noch einmal eingeben
 move.b d0,(a1)+                * Wert ablegen
 add #24,d6                     * Neue Position
 dbra d7,drmenn0
drmenn1:
 st (a1)                        * Endekennung

drmenna:                        * Ausgabe der selbstdefinierten Befehle
 moveq #$11,d0                  * Schriftgröße
 moveq #53,d1                   * X-Position
 moveq #77,d2                   * Y-Position
 bsr setprt                     * Werte einstellen
 bsr erapen                     * Auf Löschen
 moveq #%1010,d0                * Befehl für Block
 moveq #76,d7                   * 30 Zeichen löschen
drmenna0:
 bsr cmd                        * Befehl an GDP
 dbra d7,drmenna0
 bsr setpen
 lea drsave(a5),a1              * Dort stehen Druckerbefehle
drmenna1:
 lea ausbuf(a5),a0
 move.b (a1)+,d0                * Befehle holen
 cmp.b #$ff,d0                  * $ff ist Ende
 beq.s drmenna2
 bsr print2x                    * In hexadezimal wandeln
 lea ausbuf(a5),a0
 moveq #$11,d0
 bsr textprint                  * Zeichen ausgeben
 add #24,d1                     * Nächste Position
 bra.s drmenna1                  * Wiederholen
drmenna2:
 rts                             * Ende

drmenq:                         * Seitenvorschub
 moveq #$c,d0
 bra lo2

drmenr:                         * Editor ausdrucken
 moveq #0,d2
 move.b dflag1(a5),d2
 lsr #5,d2                      * 3 Bit für Anzahl
 bra.s drmenr1
drmenr0:
 tst d3                         * Zeile Null ?
 beq.s drmenr1                  * Ja, dann kein Seitenvorschub
 bsr.s drmenq                   * Seitenvorschub
drmenr1:
 moveq #0,d3                    * Zeile Null
 movea.l stxtxt(a5),a1          * Anfangsadresse
drmenr2:
 move.b (a1)+,d1                * Zeichen holen
 beq.s drmenr5                  * Null ist Ende
 cmp.b #$a,d1                   * Linefeed ?
 bne.s drmenr3                  * Nein
 addq #1,d3                     * Nächste Zeile erreicht
 cmp.b dflag2(a5),d3            * Ende der Seite erreicht ?
 bne.s drmenr3                  * Nein, dann nur Linefeed ausführen
 clr d3
 bsr.s drmenq                   * Ja, Seitenvorschub ausführen
 bra.s drmenr2                   * Nächstes Zeichen
drmenr3:
 bsr csts                       * Zeichen von Tastatur ?
 beq.s drmenr4                  * Nein !!!
 bsr ci                         * Zeichen holen
 cmp.b #$1b,d0
 beq carset                     * ESC = Abbruch
drmenr4:
 bsr lsts
 beq.s drmenr3                  * Warten bis Drucker fertig
 move.b d1,d0                   * Auszugebendes Zeichen
 bsr lo                         * Zeichen ausgeben
 bra.s drmenr2                   * Nächstes Zeichen
drmenr5:
 dbra d2,drmenr0                 * Kopien
 bra carres

drbefneu:                       * Druckerbefehle ändern
 addq.l #4,a7                   * Rücksprungadresse löschen
 bsr clrall                     * Bildschirm löschen
drbefn0:
 lea drtxt2(pc),a0              * Ausgabetext
 moveq #$21,d0
 moveq #2,d1
 move #245,d2
 bsr textprint
 lea drbeftab(a5),a1            * Tabelle der Druckerbefehle
 move #245,d2                   * Anfangs Y-Position
 move #360,d1                   * X-Position
 moveq #22-1,d7                 * Anzahl der Befehle
drbefn1:
 movea.l a1,a2                  * Adresse merken
 lea ausbuf(a5),a0              * Ziel
 move.l #'    ',(a0)+           * Vorlöschen
 move.l #'    ',(a0)+
 move.l #'    ',(a0)+
 clr.b (a0)
 lea ausbuf(a5),a0              * Ziel
 moveq #3-1,d6                  * Maximal 3 Bytes pro Befehl
drbefn2:
 move.b (a2)+,d0                * Byte holen
 bmi.s drbefn3                  * Negativ, dann Ende
 bsr print2x                    * In ASCII wandeln
 move.b #' ',(a0)               * Null am Ende überschreiben
 addq.l #2,a0                   * Zieladresse erhöhen
 dbra d6,drbefn2
drbefn3:
 addq.l #3,a1                   * Adresse nächster Befehl
 moveq #$21,d0
 lea ausbuf(a5),a0
 bsr textaus                    * Text ausgeben
 sub #10,d2                     * Nächste Y-Position
 dbra d7,drbefn1
drbefn4:
 lea einbuf(a5),a0
 moveq #$21,d0
 moveq #2,d1
 moveq #2,d2
 moveq #1,d3                    * Nur 1 Zeichen
 bsr textein                    * Befehl einlesen
 bcs druckmen                   * Abbruch
 move d5,d0
 bsr bucheck                    * In Großbuchstaben wandeln
 cmp.b #'Z',d0
 beq druckmen                   * 'Z' = Zurück
 cmp.b #'W',d0
 bne.s drbefn5                  * 'W' = Druckbefehle initialisieren
 bsr drbefinit
 bra drbefn0
drbefn5:
 cmp.b #'A',d0                  * Bereich 'A'
 bmi.s drbefn4
 cmp.b #'V',d0                  * bis 'V'
 bhi.s drbefn4
 move d0,d2                     * Merken für Y-Position
 mulu #3,d0                     * 3 Bytes pro Befehl
 lea drbeftab-3*'A'(a5),a4      * Tabelle der Befehle
 adda.l d0,a4                   * Ablageadresse errechnet
 muls #-10,d2                   * Zeilenabstand
 add #245+10*'A',d2             * Oberste Zeile
 move #360,d6                   * X-Position
 moveq #3-1,d7
drbefn6:
 moveq #$21,d0                  * Schriftgröße
 move d6,d1
 moveq #3,d3                    * Maximal 3 Zeichen
 lea einbuf(a5),a0
 bsr textein                    * Zeichen einlesen
 bcs.s drbefn7                  * Abbruch
 tst d4
 beq.s drbefn7                  * Wenn kein Zeichen, dann Ende
 lea einbuf(a5),a0
 bsr wertmfeh                   * Wert berechnen
 bcs.s drbefn6                  * Fehler, noch einmal lesen
 tst d0
 bmi.s drbefn6                  * Negative Werte sind nicht erlaubt
 move.b d0,(a4)+                * Im Speicher ablegen
 add #12*4,d6                   * Nächste X-Position
 dbra d7,drbefn6
 bra drbefn0
drbefn7:
 st (a4)                        * Endekennung, da nicht 3 Zeichen
 bra drbefn0

*******************************************************************************
*                         680xx Grundprogramm texte                           *
*                         (C) 1990 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                                  Texte                                      *
*******************************************************************************


************************ Texte außer für Editor und Assembler ******************

inttxt:                         * Falscher Interrupt
 dc.b 'INTERRUPT',0

bustxt:                         * Busfehler
 dc.b 'BUS-FEHLER',0

adrftxt:                        * Adressfehler
 dc.b 'ADRESS-FEHLER',0

illtxt:                         * Diesen Befehl gibt es nicht
 dc.b 'FALSCHER BEFEHL',0

zertxt:                         * Durch Null teilen ist nie erlaubt
 dc.b 'DIVISION DURCH NULL',0

chktxt:                         * Bei einem Check Befehl erfolgt Exception
 dc.b 'CHK-BEFEHL',0

traptxt:                        * TRAP bei Überlauf
 dc.b 'TRAPV-BEFEHL',0

privtxt:                        * Dieser Befehl ist im USER-Modus nicht erlaubt
 dc.b 'PRIVILEGE-VERLETZUNG',0

linatxt:                        * Falscher Befehl mit Anfang $A
 dc.b 'BEFEHLSCODE $A EMULATOR',0

linftxt:                        * Falscher Befehl mit Anfang $F
 dc.b 'BEFEHLSCODE $F EMULATOR',0

formattxt:
 dc.b 'FALSCHES STACKFORMAT',0  *

copyr:
 dc.b 'NKC',0

copyr2:                          * Copyright
 dc.b 'Die Legende lebt!',0

copyr3:
 dc.b '                                                  ',0

copyr4:
 dc.b ' Jens Mewes',0

cpu1:
 dc.b '68008 ',0

cpu2:
 dc.b '68000 ',0

cpu4:
 dc.b '68020 ',0

menue:                          * Überschrift erstes Menü
 dc.b 'Grundprogramm ',0

menue23:                        * Löschen Symbole
 dc.b '1 = L',$fc,'schen',10
 dc.b '    aller Symbole',0

menue31:
 dc.b '1 = Datei',10
 dc.b '2 = Editordaten',10
 dc.b '3 = Druckerdaten',0

sadadt0:
 dc.b 'Speichern Datei',0

sadadt2:
 dc.b 'Quelladresse',0

sadadt3:
 dc.b 'Sektorenanzahl',0

saeddt0:
 dc.b 'Speichern Editordaten',0

sadadt1:
saeddt1:
sadrdt1:
lodadt1:
loeddt1:
lodrdt1:
loftdt1:
deldt1:
 dc.b   'Laufwerk und Name',0

sadrdt0:
 dc.b   'Speichern Druckerdaten',0

lodadt0:
 dc.b   'Laden Datei',0

lodadt2:
 dc.b   'Zieladresse',0

loeddt0:
 dc.b   'Laden Editordaten',0

lodrdt0:
 dc.b   'Laden Druckerdaten',0

loftdt0:
 dc.b   'Laden Fontdaten',0
 
inhdt0:
 dc.b   'Inhalt DISK',0

deldt0:
 dc.b   'Datei l',$fc,'schen',0

kopdt0:
 dc.b   'Datei kopieren',0

rendt0:
 dc.b   'Namen ',$fb,'ndern',0

rendt1:
 dc.b   'Alter Name',0

rendt2:
 dc.b   'Neuer Name',0

dostxt2:
 dc.b   'Datei nicht vorhanden',0

dostxt3:
 dc.b   'Neuer Name existiert schon',0

dostxt4:
 dc.b   'Laufwerke unterschiedlich',0

dostxt5:
 dc.b   'Diskette voll',0

dostxt99:
 dc.b   'Nicht genug RAM',0

dostxt:
 dc.b   'Allgemeiner Fehler',0

menue34:                        * Booten
 dc.b '1 = Floppy 1',10
 dc.b '2 = Floppy 2',10
 dc.b '3 = Floppy 3',10
 dc.b '4 = Floppy 4',10
 dc.b '5 = SCSI-Disk',10
 dc.b '6 = IDE-Disk',10
 dc.b '7 = SD-Card',0

menue34a:                       * Booten
 dc.b '1 = Floppy 1',10
 dc.b '2 = Floppy 2',10
 dc.b '3 = Floppy 3',10
 dc.b '4 = SRAMDISK',10
 dc.b '5 = SCSI-Disk',10
 dc.b '6 = IDE-Disk',10
 dc.b '7 = SD-Card',0

spmsg1:
 dc.b 'Speicher ansehen',0

spmsg2:
 dc.b 'Befehle: +  -   R  F  S   1  2   3  4',0

spmsg3:
 dc.b 'Adr. 0 1 2 3 4 5 6 7 8 9 A B C D E F Pr',$fd,'f',0

adrmsg:
 dc.b 'Adr :',0

stmsg1:
 dc.b 'Programm starten',0

fimsg:
 dc.b 'F=Flip M=Men',$fd,0

spber1:
 dc.b 'RAM-Bereiche',0

spber2:
 dc.b 'Arbeitsbereich :',0

txtdefa:
 dc.b 'Text alt',0

txtdefn:
 dc.b 'Text neu',0

txtm2:
 dc.b 'Wirklich ?  J = Ja',0

txta1:
 dc.b 'Speicher ',$fb,'ndern',0

txta2:
 dc.b 'CR = Weiter    - = Zurück   S = Suchen',10
 dc.b ' R = Adresse   D = Dump     F = F',$fd,'llen',0

txta3:
 dc.b 'Anzahl :',0

txta4:
 dc.b 'Wert   :',0

bibotxt0:
 dc.b 'Bibliothek',0

bibotxt1:
 dc.b 'Wahl  Name      Anfang  Länge   Relokativ',0

bibotxt2:
 dc.b '+ = Vorwärts            - = R',$fd,'ckwärts',10
 dc.b 'M = Ende            (A- ) = Starten',0
 ds 0

bibotxt3:
 dc.b 'Nein',0,0
 dc.b ' Ja ',0

txtp1:
 dc.b 'EPROM programmieren',0

txtp2:
 dc.b 'EPROM lesen',0

txtp3:
 dc.b 'Von      :',10
 dc.b 'Bis      :',10
 dc.b 'Nach     :',10
 dc.b 'Abstand  :',0

txtp4:
 dc.b 'Bereich ist nicht leer !!',0

txtp5:
 dc.b 'S = Starten    M = Men',$fd,0

txtp6:
 dc.b 'Programmierung l',$fb,'uft !!',0

txtp7:
 dc.b 'EPROM-Fehler  M = Menü',0

txtp8:
 dc.b 'FEHLER BEIM PR',$dd,'FEN !',0

txtp9:
 dc.b 'EPROM OK',0

txtpein:
 dc.b 'A = Promerl 2716  ',10
 dc.b 'B = Promerl 2732  ',10
 dc.b 'C = Promerl 2764 ',10,10
 dc.b 'D = Promers 2716  ',10
 dc.b 'E = Promers 2732  ',10
 dc.b 'F = Promers 2764 ',10,10
 dc.b 'G = Promer2 2716  ',10
 dc.b 'H = Promer2 2732  ',10
 dc.b 'I = Promer2 2764a ',10
 dc.b 'J = Promer2 2764b ',10
 dc.b 'K = Promer2 27128a',10
 dc.b 'L = Promer2 27128b',10
 dc.b 'M = Promer2 27256 ',10
 dc.b 'N = Promer2 27512 ',10
 dc.b 'O = Promer2 27010 ',10
 dc.b 10
 dc.b 'P =',10
 dc.b 10
 dc.b '    Z = Zur',$fd,'ck',0

iomsg:
 dc.b 'IO lesen',0

io1msg:
 dc.b 'R=Adr D=Dauer S=Stop M=Men',$fd,0

iopmsg:
 dc.b 'IO setzen',0

datamsg:
 dc.b 'Data:',0

iop1msg:
 dc.b 'M = Men',$fd,'    R = Adr',0

tractxt0:
 dc.b 'Einzelschritt',0

tractxt1:
 dc.b 'Befehlsm',$fc,'glichkeiten',0

tractxt2:                       * Diese Befehle gibt es im Einzelschritt
 dc.b 'B = Bis ADRESSE / BEREICH ausf',$fd,'hren',10
 dc.b 'C = Bildschirm l',$fc,'schen',10
 dc.b 'D = TRAP/JSR direkt/indirekt',10
 dc.b 'E = Bis zum n',$fb,'chsten RTS/RTE/RTR',10
 dc.b 'F = Flags (CCR) laden',10
 dc.b 'G = Grundprogrammroutinen aufrufen',10
 dc.b 'I = Info an/aus',10
 dc.b 'L = B/E/N/W wiederholen',10
 dc.b 'M = Zur',$fd,'ck zum Menü',10
 dc.b 'N = n Befehle ausf',$fd,'hren',10
 dc.b 'P = PC neu laden (Neue Adresse)',10
 dc.b 'R = Register laden (Dx,Ax  x=0-7/8)',10
 dc.b 'S = Leseseite ausw',$fb,'hlen',10
 dc.b 'T = Tabelle der Befehle auf Drucker',10
 dc.b 'W = Weiter bis ADRESSE & MASKE = WERT',0

smentxt:
 dc.b 'A = ',$DB,'ndern',10 * Ändern
 dc.b 'B = Starten',10
 dc.b 'C = Ansehen',10
 dc.b 'D = Symboltabelle',10
 dc.b 'E = Editor',10
 dc.b 'F = Assembler',10
 dc.b 'G = Bibliothek',10
 dc.b 'H = Speichern Disk',10
 dc.b 'I = Laden Disk',10
 dc.b 'J = Inhalt Disk',10
 dc.b 'K = L',$fc,'schen Datei',10
 dc.b 'L = Kopieren Datei',10
 dc.b 'M = Umbenennen Datei',10
 dc.b 'N = Booten',10
 dc.b 'O = Eprom prog.',10
 dc.b 'P = Eprom lesen',10
 dc.b 'Q = Speicherbereiche',0

smentxt0:
 dc.b 'R = Druckersteuerung',10
 dc.b 'S = IO lesen',10
 dc.b 'T = IO setzen',10
 dc.b 'U = Einzelschritt',10
 dc.b 'V = System Konfig.',10
 dc.b 'W = Alter Text',10
 dc.b 'X = Neuer Text',10
 dc.b 'Y = Symbole l',$fc,'schen',10    * löschen
 dc.b 10
 dc.b '1 = 40 Zeichen/Zeile',10
 dc.b '2 = 80 Zeichen/Zeile',10
 dc.b '3 = Debug-Info an',10
 dc.b '4 = Debug-Info aus',10
 dc.b '5 = Fehlerausgabe',10
 dc.b '6 = Ausgabe auf CRT',10
 dc.b '7 = Ausgabe auf LST',10
 dc.b '8 = Auf LST ohne LF',10
 dc.b '9 = Uhr stellen',0

smentxt1:
 dc.b 'Z = Beenden',0

smentxt2:
 dc.b ' Zeichen/Zeile    Debug-Info: aus     ',0

smentxt3:
 dc.b 'Fehlerausgabe  ',0
 dc.b 'Ausgabe auf CRT',0
 dc.b 'Ausgabe auf LST',0
 dc.b 'Auf LST ohne LF',0
 dc.b 'Ausgabe auf USR',0
 dc.b 'Ausgabe auf SER',0

smentxt4:
 dc.b 'Editanf: $          Editend: $          Symbanf: $          Symbend: $',0

systxt0:
 dc.b 'System Konfiguration',0

systxt00:
 dc.b 'Diese Funktion ist nur verf',$fd,'gbar,', 10
 dc.b 'wenn eine Uhr mit Dallas DS12887 IC', 10
 dc.b 'vorhanden ist!', 0

systxt1:
 dc.b 'A = DIP-Key', 10, 10
 dc.b 'B = Autoboot', 10, 10
 dc.b 'C = SER', 10, 10
 dc.b 'D = SER2 Kanal A', 10, 10
 dc.b 'E = SER2 Kanal B', 10, 10
 dc.b 'F = Bootdelay', 10, 10, 10
 dc.b 'S = Speichern und Zur',$fd,'ck', 10, 10
 dc.b 'Z = Zur',$fd,'ck', 0 * zurück

abtdtxt0:
 dc.b 'Autoboot Delay', 0

abtdtxt1:
 dc.b 'bitte ', 0

abtdtxt2:
 dc.b 'Sekunden warten', 0

drtxt0:
 dc.b 'Druckersteuerung',0

drtxt1:                         * Befehle der Druckersteuerung
 dc.b 'A = Seitenl',$fb,'nge',10    * Seitenlänge
 dc.b 'B = Linker Rand',10
 dc.b 'C = Druckart',10
 dc.b 'D = Schriftart',10
 dc.b 'E = Druck',10
 dc.b 'F = Langsamer Druck',10
 dc.b 'G = Fettdruck',10
 dc.b 'H = Doppeldruck',10
 dc.b 'I = Proportionaldruck',10
 dc.b 'J = Kursivdruck',10
 dc.b 'K = Papiererkennung',10
 dc.b 'L = Zeichensatz',10
 dc.b 'M = Anzahl Kopien',10
 dc.b 'N >',10
 dc.b 10
 dc.b 'O = Werte r',$fd,'cksetzen',10   *rücksetzen
 dc.b 'P = Werte an Drucker',10
 dc.b 'Q = Seitenvorschub',10
 dc.b 'R = Editor ausdrucken',10
 dc.b 'S = Druckerbefehle ',$fb,'ndern',10
 dc.b '    Z = Zur',$fd,'ck',0   * zurück

drtxt2:                         * Befehle für den Drucker
 dc.b 'A = Drucker initialisieren',10
 dc.b 'B = Linker Rand',10
 dc.b 'C = Schmaldruck',10
 dc.b 'D = Breitdruck',10
 dc.b 'E = Pica',10
 dc.b 'F = Elite',10
 dc.b 'G = Bidirektional',10
 dc.b 'H = Unidirektional',10
 dc.b 'I = Schneller Druck',10
 dc.b 'J = Langsamer Druck',10
 dc.b 'K = Fettdruck aus',10
 dc.b 'L = Fettdruck an',10
 dc.b 'M = Doppeldruck aus',10
 dc.b 'N = Doppeldruck an',10
 dc.b 'O = Proportionaldruck aus',10
 dc.b 'P = Proportionaldruck an',10
 dc.b 'Q = Kursivdruck aus',10
 dc.b 'R = Kursivdruck an',10
 dc.b 'S = Papiererkennung an',10
 dc.b 'T = Papiererkennung aus',10
 dc.b 'U = Amerikanischer Z-Satz',10
 dc.b 'V = Deutscher Zeichensatz',10
 dc.b 'W = Alle Werte rücksetzen',10
 dc.b 'Z = Zur',$fd,'ck',0

drtxtc:
 dc.b 'Normal',0
 dc.b 'Schmal',0
 dc.b 'Breit ',0

drtxtd:
 dc.b 'Pica ',0
 dc.b 'Elite',0

drtxte:
 dc.b 'Bidirektional ',0
 dc.b 'Unidirektional',0

drtxtf:
 dc.b 'Aus',0
 dc.b 'An ',0

drtxtl:
 dc.b 'Amerikanisch',0
 dc.b 'Deutsch     ',0
 dc.b 'NDR         ',0

 DS.W 0

*******************************************************************************
*                           680xx Grundprogramm IO                            *
*                         (C) 1990 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                          Ein- Ausgaberoutinen                               *
*******************************************************************************


csts:
 cmp.b #6,iostatb(a5)           * Userstatus
 beq.s uscsts                   * Wenn 6, dann USER-Routine
cstsin:
 btst.b #0,serflag(a5)          * Auf serielle Karte gelegt ?
 bne sists                      * Ja, dann dort prüfen
 moveq #0,d0                    * Langwort gültig
 tst.b keyd.w                   * Strobe vorhanden ?
 spl d0                         * $ff wenn Zeichen da / $00 wenn kein Zeichen da
 tst.b d0                       * Flags auch setzen
 rts

uscsts:                         * Routine für USER aufrufen
 moveq #2,d0                    * Flag für CSTS von CI-Seite
 jmp usercsts(a5)               * 0=frei $ff=belegt
                                * als Ergebnis in d0.l liefern

ciusext:
 moveq #2,d0                    * Kennung an USERCI, daß Data an CI geht und
 jmp userci(a5)                 * nicht an CI2
                                * Achtung !! Keine Register zerstören außer d0.l
                                * Laden wegen CP/M 68K etc.

ki:                             * Zeichen holen
 bsr.s ci
 bra bucheck                     * Mit Großbuchstaben-Wandler

ci:
 cmp.b #6,iostatb(a5)           * User CI ?
 beq.s ciusext                  * Dann USER-Routine aufrufen
ciin:
 and.b #%11111011,iodir(a5)     * Freigabe letztes Zeichen
 btst.b #1,iodir(a5)            * Test, ob Daten aus Buffer da sind
 bne ci14                       * Ja, dann aus Buffer holen
 bsr cursorein                  * Mit Cursorausgabe
ci0:
 btst.b #0,serflag(a5)          * Auf serielle Karte gelegt ?
 beq.s ci1                      * Nein, dann Zeichen von der Tastatur holen
ci0a:
 bsr autoflip                   * Flip-Mode
 bsr sists                      * Zeichen da ?
 beq.s ci0a                     * Nein, dann Schleife
 bsr si                         * Zeichen holen
 bra.s ci1a                      * Auswerten
ci1:
 bsr autoflip                   * Flip-Mode
 moveq #0,d0                    * Langwort ist gültig
 move.b keyd.w,d0               * Test, ob Daten da
 bmi.s ci1                      * Bit 7 bestimmt dies
 tst.b keys.w                   * Rücksetzen des Strobesignals
ci1a:
 tst.b d0                       * Ctrl @ ?
 bne cursoraus                  * Nein, dann Ende
 move.b menflag(a5),d0
 and.b  #%11000000,d0           * Bit 7 oder 6 gesetzt ?
 beq    cursoraus               * Nein, dann keine Hardcopy erlaubt
 movem.l d7/a0/a1,-(a7)
 bsr    getfrei                 * 16 Kbyte müssen hinter Symboltabelle frei sein
 bsr.s ci11                     * Hardcopyabfrage
 movem.l (a7)+,d7/a0/a1
 bra.s ci1                       * Jetzt nächstes Zeichen holen, da jetzt Abfrage

ci11:                           * Hardcopyfunktion
 btst.b #0,serflag(a5)          * Auf serielle Karte gelenkt  ?
 beq.s ci11a                    * Nein, Zeichen von Key holen
 bsr si                         * Zeichen von serieller Karte holen
 bra.s ci11b                     * Auswerten
ci11a:
 move.b keyd.w,d0
 bmi.s ci11a                    * Warten auf Zeichen
 tst.b keys.w                   * Rücksetzen Strobe
ci11b:
 sub.b #'1',d0                  * Bei "1" Hardcopy 8 Nadeln
 beq stdruck8                   * Standardhardcopy 8 Nadeln
 subq.b #1,d0                   * Bei "2" Hardcopy 24 Nadeln
 beq stdruck24                  * Standardhardcopy 24 Nadeln
 subq.b #1,d0                   * Bei '3' Bildschirm im Speicher ablegen
 beq ramcopy                    * Copy vom Screen erstellen
 rts

ci14:
 move.l a0,-(a7)                * a0 retten
 movea.l einpoi(a5),a0          * Quelle
 moveq #0,d0                    * Langwort ist gültig
 move.b (a0)+,d0                * Nächstes Zeichen holen
 bne.s ci15                     * Null, dann Leerzeichen ausgeben
 and.b  #%11111001,iodir(a5)
 addq.b #4,iodir(a5)            * Flag, daß letztes Zeichen
 moveq #' ',d0                  * Leerzeichen, wenn Null
ci15:
 move.l a0,einpoi(a5)           * Adresse merken
 movea.l (a7)+,a0               * a0 zurück
 rts

ciinit2:                        * Init vorbereiten
 move.l stxtxt(a5),akttxt(a5)   * Zeilenanfang=Textanfang
 move.b #1,ci2flag(a5)          * flag first aktiv
 rts

ci2:
 cmp.b #5,iostatb(a5)           * Zeichen holen von Quelle ggf über Schalter
 beq.s ci2ext                   * anwählbar sonst AKTTXT
 move.l a0,-(a7)                * Wert=0 wenn Ende erreicht (ETXTXT)
 movea.l akttxt(a5),a0          * AKTTXT holen
 move.b (a0)+,d0                * a0 auch erhöhen
 beq.s ci2a                     * 0, dann Ende erreicht
 move.l a0,akttxt(a5)           * Adresse neues Zeichen
 movea.l (a7)+,a0
 bra carres                      * Carry nur bei Fehler
ci2a:
 move #2,errflag(a5)            * Ende, deshalb errflag auf 2 setzen
 movea.l (a7)+,a0
 bra carset                      * Carry da Fehler

ci2ext:                         * d0 muß Ergebnis sein
 movem.l d1-d7/a0-a6,-(a7)
 moveq #0,d0                    * Langwort ist gültig
 move.b ci2flag(a5),d0          * 1 = erstes Zeichen holen
 clr.b ci2flag(a5)              * Nun Zeichen gelesen ok=0
ci21ext:
 jsr userci(a5)                 * Sprung mit Parameter in d0.l
 movem.l (a7)+,d1-d7/a0-a6
ci2final:
 tst.b d0                       * d0=0 dann errflag
 bne carres
 move #2,errflag(a5)            * Endekennung
 bra carset

co2test:                        * ESC = Abbruch (Carry = 1)
 bsr csts                       * Ctrl-S = Warten (Ctrl-Q Ende Warten)
 beq carres                     * <Space> Geschwindkeitsumschaltung
 bsr ci
 cmp.b #$1b,d0
 beq carset                     * Abbruch
 cmp.b #' ',d0
 bne.s co2test1
 btst.b #0,ioflag(a5)
 beq carres                     * Bei alter GDP nicht umschalten
 eori.b #%100,cotempo(a5)       * Geschwindigkeit umschalten
 bra carres                      * OK
co2test1:
 cmp.b #19,d0                   * CTRL-S bedeutet STOP
 bne carres                     * Nicht CTRL-S, dann OK
co2test2:
 bsr ci
 cmp.b #17,d0                   * Warten bis CTRL-Q kommt
 bne.s co2test2
 bra carres                      * OK

prtco2:                         * Ganzen Text ausgeben
 move.b (a0)+,d0                * Null als Endekennung
 beq carres
 bsr.s co2                      * Ausgabe über CO2
 bra.s prtco2

crlfe:                          * Ausgabe CR LF über die co2 Schnittstelle
 moveq #$d,d0                   * CR
 bsr.s co2
 moveq #$a,d0                   * LF

co2:                            * Zeichen ausgeben nur wenn pass = 2
 cmp #2,passflag(a5)
 bne carset                     * Nein, keine Ausgabe
co3:
 cmp.b #1,d0                    * CTRL-A ist Escape für Sonderfunktion
 beq co2ctrla
 btst.b #0,iodir(a5)            * CTRL-A  an ?
 bne co2ctaan                   * Mode ist an, dann Aufspeichern bis Ende
 btst.b #2,iodir(a5)            * Last char
 beq.s co2aus
 and.b #%11111001,iodir(a5)     * Nur einmal last char
 bra carres                      * Auch nicht bei letztem Leerzeichen

co2aus:
 btst.b #1,iodir(a5)
 bne carres                     * Keine Ausgabe wenn GET-Befehl
 cmp.b #1,iostat(a5)            * Ausgabe mit Errflag-Abfrage ?
 bne.s co2ausa                  * Nein, dann weiter
 tst errflag(a5)
 beq carres                     * Errflag ist Null -> Ende
 cmp.b #$a,d0                   * Linefeed ?
 bne.s cocrt                    * Nein, dann Ausgabe
 addq.b #1,zeilen(a5)           * Zeilenzähler nur erhöhen, wenn
 bra.s cocrt                     * wirklich Ausgabe erfolgt

co2ausa:
 cmp.b #$a,d0
 bne.s coausb
 addq.b #1,zeilen(a5)           * Zeilenzähler nur bei Ausgabe erhöhen
coausb:
 cmp.b #2,iostat(a5)            * 2 = CRT-Ausgabe
 bne.s co2lo
cocrt:
 movem.l d0/a0-a2,-(a7)
 bsr co                         * Zeichen ausgeben
 clr.b wrtpage(a5)              * Schreibseite auf Null
 bsr aktpage                    * Wichtig für nachfolgende Programme
 movem.l (a7)+,d0/a0-a2
 bra carres

co2lo:
 cmp.b #3,iostat(a5)            * 3 = LST
 bne.s co2lolf
 bsr lo2                        * Zeichen auf Drucker
 bra carres

co2lolf:
 cmp.b #4,iostat(a5)            * 4 = LST ohne LF
 bne.s co2user
 bsr lolf                       * Zeichen auf Drucker / LF ignorieren
 bra carres

co2user:                        * 5 = USER-CO
 cmp.b #5,iostat(a5)
 bne.s co2ser
 movem.l d0-d7/a0-a6,-(a7)      * Alle Register retten
 jsr userco(a5)                 * Sprung dorthin
 movem.l (a7)+,d0-d7/a0-a6
 rts

co2ser:                         * 6 = Zeichen an serielle Karte
 cmp.b #6,iostat(a5)
 bne.s cocrt
 bsr so
 bra carres

co2ctrla:                       * CTRL-A
 or.b #1,iodir(a5)              * Setzen
 move.l a0,-(a7)
 lea ausbuf(a5),a0
 clr.b (a0)                     * Endekennung, falls nichts mehr folgt
 move.l a0,auspoi(a5)           * Ziel auf Anfang
 movea.l (a7)+,a0
 bra carset

co2ctaan:
 cmp.b #$a,d0                   * Ende-Zeichen ist LF
 beq.s co2spez                  * Dort weiter, wenn ja
 move.l a0,-(a7)
 movea.l auspoi(a5),a0
 move.b d0,(a0)+                * Zeichen abspeichern
 clr.b (a0)                     * Ende markieren
 move.l a0,auspoi(a5)
 movea.l (a7)+,a0
 bra carset

co2spez:                        * CTRL-A Auswertung
 and.b #%11111110,iodir(a5)     * Aufspeichern ausschalten
 movem.l d0-d7/a0-a6,-(a7)
 lea ausbuf(a5),a0              * In Ausbuf liegen Werte
co2speza:
 move.b (a0)+,d0                * Leerzeichen ignorieren
 cmp.b #' ',d0
 beq.s co2speza
 cmp.b #'E',d0                  * Programm mit folgender Adresse aufrufen
 bne.s co2spezc
 bsr wertmfeh                   * E adr val val val
 bcs.s co2spezf                 * d0...d7       Keine Adressregister
 moveq #8-1,d7
co2spezb:
 move.l d0,-(a7)                * Retten Adresse
 bsr wert                       * Nun Parameter (d0.l bis d7.l)
 dbra d7,co2spezb
 move.l d0,d7
 move.l (a7)+,d6                * Werte vom Stack holen und in den Registern
 move.l (a7)+,d5                * ablegen
 move.l (a7)+,d4
 move.l (a7)+,d3
 move.l (a7)+,d2
 move.l (a7)+,d1
 move.l (a7)+,d0
 movea.l (a7)+,a6               * Ziel
 jsr (a6)                       * Sprung dorthin Parameter sind übergeben
 bra.s co2spezf                  * Danach Ende
co2spezc:
 cmp.b #'G',d0                  * Get
 bne.s co2spezd
 bsr wert                       * d1=0 Fehler 5=undef.
 movea.l d0,a0                  * Auch bei Fehler
 clr d0                         * Wort gültig
 move.b (a0),d0                 * Wert
 lea einbuf(a5),a0
 move.l a0,einpoi(a5)
 bsr print4d                    * Als Zahl 0...255
 or.b #2,iodir(a5)              * Umschalten ci
 bra.s co2spezf
co2spezd:
 cmp.b #'P',d0                  * Poke
 bne.s co2spezf
 bsr wertmfeh                   * Adresse holen
 bcs.s co2spezf                 * Bei Fehler nicht
 move.l d0,-(a7)                * Adresse merken
 bsr wertmfeh                   * Poke-Wert
 bcs.s co2speze
 movea.l (a7)+,a0               * P adr byte
 move.b d0,(a0)                 * Wert ablegen
 bra.s co2spezf
co2speze:
 addq.l #4,a7                   * Stack in Ordnung bringen
co2spezf:
 movem.l (a7)+,d0-d7/a0-a6
 bra carset

*******************************************************************************
*                          680xx Grundprogramm cas                            *
*                         (C) 1990 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                          Kassettenrecorder IOs                              *
*******************************************************************************


* Unterprogramme für die Kassettenbedienung

casinit:
 move.b #$53,cmdcas.w           * Kassetteninterface an
relaisan:
 move.b #$50,cmdcas.w           * Relais anschalten
 rts

relaisaus:
 move.b #$10,cmdcas.w           * Relais ausschalten
 rts

ri:                             * Zeichen von Kassette lesen
 bsr.s poorichk
 btst.b #0,cmdcas.w             * Warten bis Zeichen da
 beq.s ri
 moveq #0,d0                    * Byte innerhalb Langwort gültig
 move.b datcas.w,d0             * Zeichen holen
 bra carres

poo:                            * Zeichen auf Kassette schreiben
 bsr.s poorichk
 btst.b #1,cmdcas.w             * Warten bis letztes Zeichen geschrieben
 beq.s poo
 move.b d0,datcas.w             * Zeichen ausgeben
 bra carres

poorichk:                       * Wenn CTRL-C, dann Abbruch mit Carry=1
 move.l d0,-(a7)
 bsr csts                       * Wenn Zeichen da, dann abfragen
 beq.s pooric1                  * Sonst OK
 bsr ci
 cmp.b #$1b,d0                  * CTRL-C
 bne.s pooric1
 addq.l #4+4,a7
 bra carset                      * Abbruch
pooric1:
 move.l (a7)+,d0
 rts                             * Zurück

*******************************************************************************
*                          680xx Grundprogramm cent                           *
*                         (C) 1990 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                           Centronicsroutinen                                *
*******************************************************************************


* Unterprogramme Drucker über Centronics

loinit:                         * Druckerinit
 move.b #1,centstb.w
 rts

locrlf:                         * Ausgabe eines Linefeed über die Drucker-
 moveq #$d,d0                   * schnittstelle
 bsr.s lo2
 moveq #$a,d0
 bra.s lo2

lolf:                           * Zeichen auf Drucken ausgeben ohne LF
 cmp.b #$a,d0
 bne.s lo2                      * Ignorieren wenn LF
 rts

prtlo:                          * Zeichenfolge auf Drucker ausgeben
 move.b (a0)+,d0
 beq carres                     * Null ist Ende
 bsr.s lo2                      * An Drucker ohne Zeichensatzumschaltung
 bra.s prtlo

lo:                             * Alle Zeichen auf Drucker ausgeben
 btst.b #1,dflag0(a5)           * Zeichensatzumschaltung
 beq.s lo1                      * Wenn Bit 1=0, dann keine Umschaltung
 tst.b d0
 bmi.s lo0                      * Springen, wenn deutsches Zeichen
 btst.b #2,dflag0(a5)           * Bit 2 testen
 beq.s lo1                      * Kein Umschalten
 bsr amerdr                     * Amerikanischen Zeichensatz an
 bra.s lo1                       * Zeichen ausgeben
lo0:
 btst.b #2,dflag0(a5)           * Deutsches Zeichen
 bne.s lo1                      * Aber nicht umschalten
 bsr deutdr                     * Deutschen Zeichensatz an
lo1:
 and.b #$7f,d0                  * Bit 7 löschen

lo2:                            * Einsprung Ausgabe ohne Sonderfunktion
 btst.b #1,serflag(a5)          * lo auf serielle Karte geschaltet ?
 bne so                         * Ja
lo3:
 btst.b #0,centin.w
 bne.s lo3                      * Warten bis Busy = Low-Signal
 move.b d0,centdaten.w          * Ausgabe Datenport
 nop                            * Für schnelle CPU
 clr.b centstb.w
 nop
 nop                            * Für schnelle CPU

 move.b #1,centstb.w            * ---...--- Strobeform
 rts

lsts:
 btst.b #1,serflag(a5)          * Auf serielle Karte geschaltet ?
 bne sosts                      * Ja
 moveq #0,d0                    * Testen, ob Drucker fertig
 btst.b #0,centin.w             * Byte innerhalb Langwort gültig
 seq d0                         * $ff = Bereit / 0 = Nicht bereit
 tst.b d0                       * Auch Flags setzen
 rts
*******************************************************************************
*                         680xx Grundprogramm turtle                          *
*                         (C) 1990 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                              Turtle Befehle                                 *
*******************************************************************************


thoch:                          * Hebe
 clr.b turdo(a5)
 rts

trunter:                        * Senke
 move.b #1,turdo(a5)
 rts

turtab:
 DC.b 0,5,12,17,24,29,36,41

turtab1:
 DC.b $fa,$fd,$ff,$fa,$00
 DC.b $d3,$d0,$d0,$d4,$d4,$d3,$00
 DC.b $fe,$f9,$fd,$fe,$00
 DC.b $d7,$d2,$d2,$d0,$d0,$d7,$00
 DC.b $fc,$fb,$f9,$fc,$00
 DC.b $d5,$d6,$d6,$d2,$d2,$d5,$00
 DC.b $f8,$ff,$fb,$f8,$00
 DC.b $d1,$d4,$d4,$d6,$d6,$d1,$00

turtle:                         * Turtle auf Screen ausgeben
 movem.l d0/a0,-(a7)
 move tur1phi(a5),d0            * Alter Wert
 ext.l d0                       * Auf 32 Bit
 divu #45,d0                    * In 45-Grad-Schritten
 and #7,d0                      * Sicherheitshalber
 move.b turtab(pc,d0),d0        * Zeiger auf Tabelle
 lea turtab1(pc,d0),a0          * Anfang Werte
turlp:
 move.b (a0)+,d0
 beq.s turend                   * Wenn 0, dann Ende
 bsr cmd                        * Kurzvektor ausgeben
 bra.s turlp                     * Und Schleife fo rtsetzen
turend:
 movem.l (a7)+,d0/a0
 rts

grapoff:
 move.b #1,first(a5)            * Keine Turtle mehr sichtbar
 rts

hide:                           * Turtle aus
 tst.b first(a5)
 beq.s hide1
 bsr.s firsttime                * Erster Aufruf
hide1:
 clr.b flip(a5)                 * Keine Seitenumschaltung mehr
 clr.b flip1(a5)
 clr.b viewpage(a5)             * Seite 0
 bra aktpage                     * als Leseseite

show:                           * Turtle an
 tst.b first(a5)
 bne.s firsttime
 move.b #1,flip(a5)             * Seitenumschaltung an
 move.b #1,flipcnt(a5)
 clr.b viewpage(a5)             * Leseseite = 0
 clr.b wrtpage(a5)              * Schreibseite = 0
 bra aktpage

firsttime:                      * Erster Aufruf der Turtle
 movem.l d0-d3,-(a7)
 move #256,d1                   * X = 256
 move #256,d2                   * Y = 256
 moveq #90,d3                   * Phi = 90 Grad
 bsr.s tmove                    * Turtle positionieren
 clr.b wrtpage(a5)              * Seite 0 wird eingestellt
 clr.b viewpage(a5)
 bsr aktpage                    * Seite anwählen
 movem.l (a7)+,d0-d3
 rts

tmove:                          * Turtle positionieren
 movem.l d1-d2,-(a7)
 asl #4,d1                      * x*16
 asl #4,d2                      * y*16
 move d1,turx(a5)
 move d2,tury(a5)               * X, Y ablegen
 move d3,d0
 bsr adj360                     * Winkel normieren
 move d0,turphi(a5)             * OK
 move.b #1,flip(a5)             * Schnellste Rate
 move.b #1,flipcnt(a5)
 clr.b first(a5)                * Nicht mehr first
 movem.l (a7)+,d1-d2
 rts

aufk:                           * Aufkurs Winkel d0.w
 clr turphi(a5)
tdrehe:                         * d0.w = deltaphi
 tst.b first(a5)
 beq.s tdreh1
 bsr.s firsttime                * First, falls erster Aufruf
tdreh1:
 add turphi(a5),d0              * phi = phi+deltaphi
 bsr adj360
 move d0,turphi(a5)             * Ergebnis Drehung
 bra autoflip

tschreite:                      * d0 = delta w
 asl.w #4,d0
tschr16tel:                     * Feine Schritte
 tst.b first(a5)
 beq.s tsch1
 bsr.s firsttime                * Eventuell first
tsch1:
 movem.l d1-d4,-(a7)
 move turx(a5),d1               * Alte Position
 move tury(a5),d2
 move d0,d3
 move turphi(a5),d0
 bsr cos
 muls d3,d0
 divs #256,d0
 add d0,turx(a5)                * cos256(phi)*dw/256+xold
 move turphi(a5),d0
 bsr sin
 muls d3,d0
 divs #256,d0
 add d0,tury(a5)                * sin(phi)*dw/256+yold
 tst.b turdo(a5)
 beq.s tsch2
 asr #4,d1                      * /16
 asr #5,d2                      * /32
 bsr moveto                     * Alte Position für drawto
 move turx(a5),d3
 move tury(a5),d4
 asr #4,d3                      * /16 in x-Richtung
 asr #5,d4                      * /32 in y-Richtung
 bsr drawt0                     * Linie zeichnen ohne getxy da bekannt
tsch2:
 movem.l (a7)+,d1-d4
 bra autoflip                    * Flip-Mode

setturt:                        * Turtle zeichnen
 tst.b first(a5)
 bne carset                     * Ausgeschaltet
 movem.l d0-d2,-(a7)
 move tur1x(a5),d1
 move tur1y(a5),d2
 asr #4,d1
 asr #5,d2                      * Normieren
 bsr moveto                     * GDP positionieren
 move.b gdp+1*cpu.w,-(a7)       * Penstatus merken
 or.b #1,wrtpage(a5)
 bsr aktpage                    * Seite 1...3
 bsr erapen                     * Löschen
 bsr turtle                     * Alte Turtle löschen
 move turphi(a5),tur1phi(a5)
 move turx(a5),d1
 move tury(a5),d2
 move d1,tur1x(a5)              * Neue Werte = Alte Werte
 move d2,tur1y(a5)
 asr #4,d1
 asr #5,d2
 bsr moveto
 bsr setpen                     * Schreiben
 bsr turtle                     * Neue Turtle ausgeben
 and.b #%11111110,wrtpage(a5)
 bsr aktpage
 move.b (a7)+,gdp+1*cpu.w       * Penstatus zurück
 movem.l (a7)+,d0-d2
 rts

getk:                           * Winkel nach d0
 move turphi(a5),d0
 rts

aufxy:                          * d1 = x   d2 = y
 tst.b first(a5)                * Linie zeichnen zu absoluter Position
 beq.s auf1xy
 bsr firsttime                  * Eventuell First
auf1xy:
 movem.l d1-d4,-(a7)
 move d1,d3                     * X
 move d2,d4                     * und Y merken
 tst.b turdo(a5)
 beq.s auf1exe                  * Bei HEBE nicht zeichnen
 move turx(a5),d1
 move tury(a5),d2
 asr #4,d1                      * /16
 asr #5,d2                      * /32
 bsr moveto                     * Anfang Linie
 movem.l d3/d4,-(a7)
 asr #1,d4                      * Nur Wort gültg Rev 6.0
 bsr drawt0                     * Linie zeichnen ohne getxy, da bekannt
 movem.l (a7)+,d3/d4
auf1exe:
 asl #4,d3
 move d3,turx(a5)
 asl #4,d4
 move d4,tury(a5)               * Neue Position abgespeichert
 movem.l (a7)+,d1-d4
 bra autoflip

korxy:                          * Position der Turtle holen
 move turx(a5),d1
 move tury(a5),d2
 asr #4,d1
 asr #4,d2
 ext.l d1                       * Langwort gültig
 ext.l d2
 rts
*******************************************************************************
*                          680xx Grundprogramm rnd                            *
*                         (C) 1990 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                             Zufallsgenerator                                *
*******************************************************************************



rnd:                            * Zufallszahlgenerator liefert 0...$ffff in d0.l




                                * d0.w gibt den Bereich n+1 an, damit Limit
                                * festlegbar
                                * Knudt-Algorithmus
                                * Wenn d0=0, dann maximaler Bereich verfügbar
 movem.l d1/d2,-(a7)
 move d0,d1                     * Bereich merken
 move rnd3var(a5),d2
 mulu #31413,d2
 add #27182,d2
 move d2,rnd3var(a5)
 addq #1,rnd1var(a5)
 moveq #0,d0
 move rnd2var(a5),d0
 add rnd1var(a5),d0
 divu #360,d0                   * Schneller bei großen Zahlen (sonst ADJ360)
 clr d0
 swap d0
 bsr sin
 add rnd2var(a5),d0
 rol #3,d0
 eor d1,d0
 move d0,rnd2var(a5)
 eor d2,d0                      * d0 jetzt Zufallszahl
 tst d1                         * d1 = Bereich
 beq.s rnd1                     * Null ist maximaler Bereich
 divu d1,d0                     * Teilen
 clr d0                         * Ergebnis löschen
 swap d0                        * Rest ist Ergebnis
rnd1:
 movem.l (a7)+,d1/d2
 rts
*******************************************************************************
*                      68000/68010 Grundprogramm gdpio                        *
*                         (C) 1990 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                               GDP-Routinen                                  *
*******************************************************************************


* Unterprogramme GDP EF 9366

wait:                           * Warten bis GDP fertig
 btst.b #2, gdp.w               * Bit 2 prüfen
 beq.s wait                     * Warten bis auf 1
  rts

cmdput:                         * Zeichen an GDP schicken
 tst.b d0                       * Wenn negativ dann putchar
 bmi putchar                    * Sonderzeichenausgabe
cmd:                            * Wert an GDP schicken, alles erlaubt
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
cmd0:
 btst.b #2, gdp.w               * Ohne Sprung zu wait schneller
 beq.s cmd0
 move.b d0, gdp.w               * Befehl ausgeben
 move (a7)+, sr                 * Staus zurück
  rts

erapen:
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
erapen0:
 btst.b #2, gdp.w               * Pen auf Löschen schalten
 beq.s erapen0
 move.b #1, gdp.w               * Schreiben
 bra.s setpen1                  * Stift aktiv

setpen:
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
setpen0:
 btst.b #2, gdp.w               * Pen auf Schreiben schalten
 beq.s setpen0
 clr.b gdp.w                    * Löschen
setpen1:
 btst.b #2, gdp.w
 beq.s setpen1
 move.b #2, gdp.w               * Stift aktiv
 move (a7)+, sr                 * Staus zurück
  rts

clear:
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
clear0:
 btst.b #2, gdp.w               * Seite in d0
 beq.s clear0                   * Warten bis GDP fertig
 and.b #$f0, d0
 move.b d0, page.w              * Seite einstellen
 or.b #4, gdp+1*cpu.w           * Blank
 move.b #6, gdp.w               * Befehl Schirm löschen
clear1:
 btst.b #2, gdp.w
 beq.s clear1                   * Warten bis GDP fertig
 and.b #$fb, gdp+1*cpu.w        * Sichtbar
 move (a7)+, sr                 * Staus zurück
  rts

clrall:
 clr.b viewpage(a5)             * Alle Bildschirmseiten löschen, danach Seite 0
 clr.b wrtpage(a5)              * als Lese und Schreibseite
 moveq #%01010000,d0            * Seite 1
 bsr.s clear
 moveq #%10100000,d0            * Seite 2
 bsr.s clear
 moveq #%11110000,d0            * Seite 3
 bsr.s clear
 moveq #%00000000,d0            * Seite 0
 bsr.s clear
 btst.b #0,ioflag(a5)
 beq.s setpage
 clr.b coscroll(a5)
 clr.b page1.w                  * Nur bei neuer GDP Scroll aus
 bra.s setpage

clrinvis:                       * Aktuelle Schreibseite löschen
 movem.l d0-d1,-(a7)
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
 bsr erapen                     * Löschen
 move.b gdp+3*cpu.w,-(a7)       * Größe beibehalten
 and.b #$f0, gdp+2*cpu.w        * Line = 0
 clr.b gdp+3*cpu.w              * size = max
 move.b #$e,gdp.w               * Y-Register auf Null
 moveq #5-1,d0                  * Counter
clri1:
 clr.b  gdp+8*cpu.w
 clr.b  gdp+9*cpu.w             * Auf Zeilenanfang
 moveq #8-1,d1
clri2:
 move.b #$b,gdp.w               * Befehl Löschen ausgeben
clri3:
 btst.b #2, gdp.w
 beq.s clri3                    * Warten bis GDP fertig
 dbra d1,clri2
 add.b #64,gdp+$b*cpu.w         * Nächste Zeile
 dbra d0,clri1
 bsr setpen                     * Auf Schreiben danach
 move.b (a7)+,gdp+3*cpu.w       * Alte Größe beibehalten
 move (a7)+, sr                 * Staus zurück
 movem.l (a7)+,d0-d1
 rts

newpage:                        * d0 = wrtpage   d1 = viewpage
 move.b d0, wrtpage(a5)
 move.b d1, viewpage(a5)
aktpage:
 move.b viewpage(a5), d0
 ror.b #2,d0                    * 0..3
 or.b wrtpage(a5), d0
 ror.b #2, d0                   * 0..3
setpage:                        * Ausgabe d0 wwrr0000
 or.b xormode(a5), d0           * XOR-Mode anwählen
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
setpage1:
 btst.b #2, gdp.w               * Ohne Sprung zu wait schneller
 beq.s setpage1
 move.b d0, page.w              * Seite einstellen
 btst.b #0, transmod(a5)
 beq.s setpage2
 bset.b #5, gdp+2*cpu.w
 bra.s setpage3
setpage2:
 bclr.b #5, gdp+2*cpu.w
setpage3:
 move.b fgcolor(a5), colport.w  * Auch Farbe neu setzen
 move.b bgcolor(a5), colport1.w * natürlich auch Hintergrund
 move (a7)+, sr                 * Staus zurück
  rts

sync:                           * Horizontalen SYNC abfragen
 clr d0                         * Flag auf Null
 btst.b #1,gdp.w                * gdp syncbit
 beq.s sync1
 tst.b synstate(a5)
 bne.s sync2                    * sync schon abgefragt
 not d0                         * Flag setzen, da Sync
sync1:
 move.b d0,synstate(a5)         * Auch dorthin
 rts
sync2:
 tst d0                         * Kein SYNC
 rts

* Verzögerungsschleife mit Quarzgenauigkeit, da der GDP64 als Zeitbasis
* verwendet wird.

delay:                          * d0 / 100 Sekunden warten
 tst.l d0
 beq.s delfin                   * Wenn d0=0, dann kein delay
 btst.b #6, keydil(a5)          * GDP-FPGA vorhanden
 beq.s delay0a                  * nein
 move.l d0,-(a7)                * GDP-FPGA, dann d0.l * 6 !!!!!
 add.l d0,d0                    * *2
 add.l (a7)+,d0                 * *3
 add.l d0,d0                    * *6
 bra.s delay0                   * und dann weiter bei delay0
delay0a:
 move.l d0,-(a7)                * hier GDP!
 add.l d0,d0
 add.l d0,d0
 add.l (a7)+,d0                 * d0.l * 5 damit 100 Milisekunden
delay0:
 move.l d0,-(a7)
delay1:
 bsr.s sync                     * Warten auf Syncronisation
 beq.s delay1
 bsr.s autoja                   * Auch autoflip aufrufen
 move.l (a7)+,d0
 subq.l #1,d0                   * Runterzählen
 bne.s delay0
delfin:
 rts

autoflip:                       * Automatische Bildseitenumschaltung
 bsr.s sync                     * Nur bei SYNC aktiv
 beq.s auto2                    * Kein sync
autoja:                         * Einsprung delay
 tst.b flip1(a5)                * 4 fach swap
 beq.s auto1
 bsr setturt                    * Nur wenn first
 cmp.b #1,flip1cnt(a5)
 bne.s auto11
 move.b flip1(a5),flip1cnt(a5)  * Zähler neu laden
 addq.b #1,viewpage(a5)         * Leseseite ändern
 and.b #3,viewpage(a5)
 bsr aktpage                    * Neue Seite
 bra.s auto1
auto11:
 subq.b #1,flip1cnt(a5)         * Verringern
auto1:
 tst.b flip(a5)                 * 2 fach swap
 beq.s auto2
 bsr setturt                    * Nur wenn first
 cmp.b #1,flipcnt(a5)
 bne.s auto22
 move.b flip(a5),flipcnt(a5)    * Zähler neu laden
 eor.b #1,viewpage(a5)          * Leseseite ändern
 bra aktpage
auto22:
 subq.b #1,flipcnt(a5)          * Verringern
auto2:
 rts

grmoveto:                       * MOVETO für Grafik-Paket
 asr #1, d2
moveto:                         * Schreibstift der GDP positionieren
 btst.b #2, gdp.w               * d1 = X  d2 = Y
 beq.s moveto                   * Ohne Sprung zu wait schneller
movetoo:                        * Ohne wait
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
 move.l a0, -(a7)               * ==> Nur für 68000/68010
 lea gdp.w, a0
 movep.w d1, 8*cpu(a0)          * X Register gesetzt
 movep.w d2, $a*cpu(a0)         * Y Register gesetzt
 movea.l (a7)+, a0
 move (a7)+, sr                 * Staus zurück
  rts

getxy:
 move sr, -(a7)                 * Staus sichern
 ori #$0700, sr                 * Interrupts aus
getxy0:
 btst.b #2, gdp.w               * d1.l = x  d2.l = y
 beq.s getxy0                   * Ohne Sprung zu wait schneller
 move.l a0, -(a7)               * ==> Nur für 68000/68010
 lea gdp.w, a0
 movep.w 8*cpu(a0), d1          * X Register geladen
 movep.w $a*cpu(a0), d2         * Y Register geladen
 movea.l (a7)+, a0
 asl #4, d1
 ext.l d1
 asr #4, d1                     * Vorzeichen X
 asl #4, d2
 ext.l d2
 asr #4, d2                     * Vorzeichen Y
 move (a7)+, sr                 * Staus zurück
  rts

drawto:                         * Linie ziehen d1 = X  d2 = Y
 movem.l d0-d4, -(a7)           * Innerer Aufruf, da auch spezielle Anwendung
 bsr.s drawtoa
 movem.l (a7)+, d0-d4
  rts

drawtoa:
 move d1, d3                    * X und Y merken
 move d2, d4
 bsr.s getxy                    * d3 = dx     d4 = dy
drawt0:
 moveq #$17, d0                 * Vektor ohne Richtung
 sub d3, d1
 bpl.s drawt1                   * Delta X positiv ?
 neg d1                         * Nein, dann negieren
 subq.b #2, d0                  * Richtung X
drawt1:
 sub d4, d2
 bpl.s drawt2                   * Delta Y positiv ?
 neg d2                         * Nein, dann negieren
 subq.b #4, d0                  * Richtung Y
drawt2:
 cmp #255, d1                   * Teilen nötig ?
 bhi.s drawt3                   * Ja
 cmp #255, d2                   * Teilen ?
 bhi.s drawt3                   * Ja
drawt20:
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
drawt21:
 btst.b #2, gdp.w               * Warten bis gdp fertig
 beq.s drawt21
 move.b d1, gdp+5*cpu.w         * Dx
 move.b d2, gdp+7*cpu.w         * Dy
 move.b d0, gdp.w               * Befehl Linie zeichnen
 move (a7)+, sr                 * Staus zurück
  rts

drawt3:                         * Teilen
 move d1, d3                    * Dx und Dy merken
 move d2, d4
drawt4:
 asr #1, d3                     * Durch zwei teilen
 asr #1, d4
 cmp #255, d3                   * Eventuell weiter teilen
 bhi.s drawt4
 cmp #255, d4                   * Teilen ?
 bhi.s drawt4
drawt40:
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
drawt41:
 btst.b #2, gdp.w               * Warten bis gdp fertig
 beq.s drawt41
 move.b d3, gdp+5*cpu.w         * Dx
 move.b d4, gdp+7*cpu.w         * Dy
 move.b d0, gdp.w               * Linie zeichnen
 move (a7)+, sr                 * Staus zurück
 sub d3, d1
 sub d4, d2
 bra.s drawt2                   * Rest der Linie

setfig:                         * Alte Figur fest setzen
 clr oldsize(a5)
  rts

figur:                          * Figur ausgeben und Alte löschen, wenn da
 move d1, -(a7)
 move.b d0, d1
 lsl #8, d0
 move.b d1, d0                  * X-Vergrößerung = Y-Vergrößerung
 move (a7)+, d1
figurxy:                        * Figur-Befehl mit getrennter Vergrößerung
 movem.l d0-d2/a0, -(a7)
 move oldsize(a5), d0
 beq.s figur1                   * Keine alte Figur vorhanden
 bsr erapen
 move oldx(a5), d1
 move oldy(a5), d2
 movea.l oldadr(a5), a0
 bsr.s figset                   * Alte Figur löschen
figur1:
 movem.l (a7)+, d0-d2/a0
 move d0, oldsize(a5)
 beq.s figur2                   * Keine neue Figur
 move d1, oldx(a5)
 move d2, oldy(a5)
 move.l a0, oldadr(a5)
 bsr setpen
 bra.s figset                   * Neue Figur setzen
figur2:
  rts

figset:                         * Figur setzen
 movem.l d0/a0/a1, -(a7)
 lea gdp.w, a1
 bsr moveto                     * Positionieren
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
 move.b d0, gdp+7*cpu.w
 asr #8, d0
 move.b d0, gdp+5*cpu.w         * Vergrößerung eingestellt
figsch:
 move.b (a0)+, d0               * Richtung holen
 ext d0
 move.b figtab(pc,d0), d0       * Neu kodieren
 beq.s figsetf                  * Null ist Ende
figseta:
 btst.b #2, (a1)                * Warten, bis GDP fertig
 beq.s figseta
 move.b d0, (a1)                * An GDP ausgeben
 bra.s figsch                    * Schleife
figsetf:
 move (a7)+, sr                 * Staus zurück
 movem.l (a7)+, d0/a0/a1
  rts                                  * Figur gesetzt

figtab:                         * Tabelle für Richtungskodierung
 DC.b %00010000                 * Rechts
 DC.b %00010001                 * Rechts-Oben
 DC.b %00010010                 * Oben
 DC.b %00010011                 * Links-Oben
 DC.b %00010110                 * Links
 DC.b %00010111                 * Links-Unten
 DC.b %00010100                 * Unten
 DC.b %00010101                 * Rechts-Unten
 DC.b 3                         * Senken
 DC.b 2                         * Heben
 DC.b 0                         * Ende
 ds 0

setchar:                        * Zeichen im USER-Zeichensatz
                                * der GDP-FPGA setzen
 btst.b #6, keydil(a5)          * GDP-FPGA da?
 beq.s setchare                 * nein
 and #$ff, d0                   * nur Byte gültig
 sub.b #' ', d0                 * auf 0 bis setzen
 bmi.s setchare                 * Fehler < 0
 cmp.b #$60, d0
 bge.s setchare                 * Fehler > $5f
 movem.l d1-d4, -(a7)           * retten
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
 move.b gdp+2*cpu.w, d2         *
 move.b gdp+8*cpu.w, d3         * GDP-Register retten
 move.b gdp+9*cpu.w, d4         *
 bset.b #4, gdp+2*cpu.w         * User-Zeichensatz auswählen
 move.b d0, d1
 asl #2, d0                     * *4
 add d1, d0                     * => *5
 move.b d0, gdp+9*cpu.w         * X LSB
 lsr #8, d0
 move.b d0, gdp+8*cpu.w         * X MSB
 move #5-1, d1                  * 5 Byte
setchar1:
 move.b (a0)+, gdp+$e*cpu.w     * übertragen
 dbra d1, setchar1
 move.b d4, gdp+9*cpu.w         *
 move.b d3, gdp+8*cpu.w         * GDP-Register zurück
 move.b d2, gdp+2*cpu.w         *
 move (a7)+, sr                 * Staus zurück
 movem.l (a7)+, d1-d4
 clr d0
 bra carres
setchare:
 move #-1, d0
 bra carset

*******************************************************************************
*                     68000/68010 Grundprogramm screen                        *
*                        (C) 1990 Ralph Dombrowski                            *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                            Bildschirmroutinen                               *
*******************************************************************************


cursorein:
 tst.b  curon(a5)
 beq.s  curf                    * Ende, wenn Cursor aus
 movem.l d0-d2/a0-a2,-(a7)
 bsr    calccur
 lea    erapen(pc),a0
 lea    setpen(pc),a1
 bra.s   cursorneu

cursoraus:
 tst.b  curon(a5)
 beq.s  curf                    * Ende, wenn Cursor aus
 movem.l d0-d2/a0-a2,-(a7)
 bsr    calccur
 lea    setpen(pc),a0
 lea    erapen(pc),a1

cursorneu:
 clr.b  wrtpage(a5)
 bsr    aktpage                 * Cursor auf Seite 0 (ohne autoflip sichtbar)
 bsr    aktcur
 tst.b  cotempo(a5)             * Hardscroll an ?
 bne.s  cursorn0                * Ja, dann weiter
 cmp    #11,d2                  * Zu tief ?
 bpl.s  cursorn1                * Nein, dann weiter
 bra.s   nocursor
cursorn0:
 cmp    #249,d2
 bmi.s  cursorn1                * Zweimal ausgeben, wenn auf Bildschirmrand
 bsr.s  cursorn2
 sub    #256,d2
 bsr    moveto
cursorn1:
 bsr.s  cursorn2
nocursor:
 movem.l (a7)+,d0-d2/a0-a2
 bra     setpen
curf:
 rts

cursorn2:
 jsr    (a1)
 move.b #10,gdp.w               * Befehl Block setzen
 bsr    moveto
 jsr    (a0)
 move.b (a2),d0
 bra cmdput                      * Und Ausgabe mit Sonderzeichen

aktcur:                         * Achtung d1/d2 werden nicht gerettet
 move.l d0,-(a7)                * Nur d0 retten
 moveq #0,d1
 move.b groesse(a5),d1          * Größe nach d1.l
 cmp.b #$11,d1                  * Größe $11 hat extra Routine
 beq.s akt1cur
 moveq #0,d0
 move.b curx(a5),d0             * X-Position nach d0.l
 add d0,d0
 move d0,d2
 add d0,d0
 add d2,d0                      * Curx * 6
 move d1,d2
 lsr #4,d1                      * SizeX
 mulu d0,d1                     * Position X = curx * sizex * 6
 and #$f,d2                     * SizeY
 neg d2
 move d2,d0
 add d2,d2
 add d2,d2
 add d0,d2
 add d2,d2                      * SizeY * -10
 moveq #1,d0
 add.b cury(a5),d0
 muls d0,d2
 add #256,d2                    * Position Y = 256 - 10 * sizey * (1+cury)
 add.b coscroll(a5),d2          * H-Scroll berücksichtigen
 bsr moveto                     * Positionieren
 move.b groesse(a5),gdp+3*cpu.w * Größe auch gleich einstellen
 move.l (a7)+,d0                * d0 zurück
 rts

akt1cur:                        * Schnelle Routine für Größe $11
 moveq #0,d1
 move.b curx(a5),d1
 move d1,d0
 add d1,d1
 add d0,d1
 add d1,d1                      * Position X = curx * 6
 move.b cury(a5),d0
 move d0,d2
 add d0,d0
 add d0,d0
 add d2,d0
 add d0,d0
 move #256-10,d2                * Position Y = 256-10-cury*10
 sub d0,d2
 add.b coscroll(a5),d2          * H-Scroll berücksichtigen
 bsr moveto
 move.b groesse(a5),gdp+3*cpu.w * Auch hier Größe einstellen
 move.l (a7)+,d0
 rts

calccur:                        * cury ist Zeile
 move.b cury(a5),d0
getline:                        * d0 ist Zeile
 lea lineptr(a5),a0             * Zeiger auf Zeilenadresse
 lea linecnt(a5),a1             * Zeiger auf Anzahl Zeichen in Zeile
 and #$ff,d0
 move.b 0(a0,d0.w),d0           * Wirkliche Zeilennummer im Speicher
 adda d0,a1                     * a1 zeigt auf Zeichenzähler der Zeile
 lsl #4,d0
 move d0,-(a7)
 add d0,d0
 add d0,d0
 add (a7)+,d0                   * d0 * 80
 lea screen(a5),a0              * Adresse Bildschirmspeicher
 adda d0,a0                     * a0 = Adresse Zeilenanfang
 movea.l a0,a2
 moveq #0,d0
 move.b curx(a5),d0             * X-Position Cursor
 adda.l d0,a2                   * Adresse des Zeichens auf Cursorposition
 rts

clrscreen:
 move.l d0,-(a7)                * Bildschirm löschen und Bildschirmspeicher auch
 clr.b xormode(a5)              * Kein XOR-Mode erlaubt
 move.b #1,curon(a5)            * Cursor anschalten
 bsr clrall                     * Alle Bildschirmseiten löschen
 move.b groesse(a5),gdp+3*cpu.w * Größe einstellen
 clr.b curx(a5)                 * Cursor steht links oben
 clr.b cury(a5)
 clr.b flip1(a5)                * Keine Vier-Seiten-Umschaltung
 move.b #10,flip(a5)            * Zwei-Seiten-Umschaltung anschalten
 move.b #10,flipcnt(a5)
 move.l (a7)+,d0
clrscr:                         * Einsprung Bildschirmspeicher löschen
 movem.l d0/d1/a0/a1,-(a7)
 lea screen(a5),a0              * Bildschirmbereich
 moveq #' ',d1                  * Space
 move #80*24-1,d0               * 24 Zeilen mit je 80 Zeichen
clrlp:
 move.b d1,(a0)+                * Bildschirmspeicher mit Leerzeichen füllen
 dbra d0,clrlp
 lea lineptr+24(a5),a0
 lea linecnt(a5),a1
 moveq #24-1,d0
clrlp1:
 move.b d0,-(a0)                * Zeilen durchnummerieren
 clr.b (a1)+                    * Anzahl der Zeichen in jeder Zeile ist Null
 dbra d0,clrlp1
 movem.l (a7)+,d0/d1/a0/a1
 rts

homepos:                        * Bildschirmkoordinate links oben
 clr d1                         * X-Pos ist Null
 move.b groesse(a5),d2          * Größe holen
 and #$f,d2                     * Nur Höhe lassen
 muls #-10,d2                   * Mal 10 für Höhe
 add #256,d2                    * Ecke links oben berechnet
 rts

prt79hs:                        * prt79 aber Hardscroll fähig
 tst.b cotempo(a5)
 beq.s prt79                    * Normal, wenn ohne Hardscroll
 cmp #249,d2
 bmi.s prt791                   * OK, da nicht auf Seitenrand
 bsr.s prt791                   * Jetzt zweimal ausgeben
 sub #256,d2
 bsr moveto
 add #256,d2
 bra.s prt791

prt79:                          * Zeile ausgeben; maximal 79 Zeichen
 cmp #11,d2                     * Zu tief ?
 bmi.s prtlfi                   * Ja, dann Ende
prt791:
 movem.l d0/d1/a0-a2,-(a7)
 bsr calccur                    * Zeileninfo holen
 move.b (a1),d1                 * Anzahl Zeichen holen
 cmp.b #80,d1                   * Wenn kleiner als 80,
 bmi.s prtx                     * dann ausgeben
 subq.b #1,d1                   * Sonst auf 79 setzen
 bra.s prtx                      * Dann ausgeben

prtlinehs:                      * prtline aber Hardscroll fähig
 tst.b cotempo(a5)
 beq.s prtline                  * Normal, wenn ohne Hardscroll
 cmp #249,d2
 bmi.s prtline1                 * OK, da nicht auf Seitenrand
 bsr.s prtline1                 * Jetzt zweimal ausgeben
 sub #256,d2
 bsr moveto
 add #256,d2
 bra.s prtline1

prtline:                        * Eine Zeile ausgeben
 cmp #11,d2                     * Zu tief ?
 bmi.s prtlfi                   * Ja, dann keine Ausgabe
prtline1:
 movem.l d0/d1/a0-a2,-(a7)
 bsr calccur                    * Zeileninfo holen
 move.b (a1),d1                 * Anzahl Zeichen nach d1
prtx:
 sub.b curx(a5),d1              * Aktuelle Position subtrahieren
 bls.s prtx1                    * Ende, da keine Zeichen hinter Cursor vorhanden
prtllp:
 cmp.b #1,gdp+8*cpu.w           * Schreibstift außerhalb des Screens ?
 bhi.s prtx1                    * Ja, dann Ende
 move.b (a2)+,d0                * Zeichen holen
 bsr cmdput                     * Ausgabe mit Sonderzeichen
 subq.b #1,d1                   * Erniedrigen bis
 bne.s prtllp                    * alle Zeichen ausgegeben sind
prtx1:
 movem.l (a7)+,d0/d1/a0-a2
prtlfi:
 rts

prtdy:                          * Zeilenabstand berechnen
 move.b groesse(a5),d5          * Schriftgröße holen
 and #$f,d5
 muls #10,d5                    * Zeilenabstand berechnet
 rts

prtr23:                         * Bis Zeile 23 ausgeben
 movem.l d0-d5/a0-a2,-(a7)
 moveq #23,d1                   * End-Zeile
 bra.s prt2

prtrest:                        * Von aktueller Position bis Ende der Seite
 movem.l d0-d5/a0-a2,-(a7)      * ausgeben
 moveq #24,d1                   * End-Zeile
prt2:
 bsr calccur                    * Zeileninfo holen
 movea.l a2,a0                  * Adresse des Zeichens an Cursorposition nach a0
 move.b cury(a5),d2             * Anfangszeile
 move.b curx(a5),d4             * Anfangsspalte
 bsr.s prtdy                    * Zeilenabstand holen
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
 bra.s prt1x

prttop:                         * Zeile 1 bis 24 ausgeben
 movem.l d0-d5/a0-a2,-(a7)
 moveq #24,d1                   * End-Zeile
 moveq #1,d2                    * Anfangszeile
 bsr.s prtdy                    * Zeilenabstand
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
 bra.s prtlp1

prtall:                         * Ganzen Bildschirm ausgeben
 movem.l d0-d5/a0-a2,-(a7)
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
 bsr.s prtdy                    * Zeilenabstand berechnen
 moveq #24,d1                   * End-Zeile
 clr d2                         * Anfangszeile
prtlp1:
 move d2,d0
 bsr getline                    * Zeileninfo holen
 clr d4                         * Anfangsspalte
prt1x:
 move.b (a1),d3                 * Anzahl Zeichen holen
 beq.s p_rtskp                   * Null, dann nächste Zeile
prtlp2:
 cmp.b #1,gdp+8*cpu.w           * Schreibstift außerhalb des Screen ?
 bhi.s p_rtskp                   * Ja, dann nächste Zeile
 move.b (a0)+,d0                * Zeichen holen
 bsr cmdput                     * Ausgabe mit Sonderzeichen
 addq.b #1,d4                   * Erhöhen
 cmp.b d3,d4                    * Bis Ende der Zeile
 bne.s prtlp2                   * erreicht
 p_rtskp:
 addq.b #1,d2                   * Nächste Zeile
 cmp.b d1,d2                    * Bis Ende
 beq.s prtallfi                 * erreicht
 p_rtskp1:
 btst.b #2,gdp.w                * Warten bis GDP fertig
 beq.s p_rtskp1
 move.b #$d,gdp.w               * Auf Anfang der Zeile
 move.b gdp+$a*cpu.w,d0
 lsl #8,d0
 move.b gdp+$b*cpu.w,d0         * Y-Position holen
 asl #4,d0
 asr #4,d0
 sub d5,d0                      * Neue Y-Position
 move.b d0,gdp+$b*cpu.w         * Nur LSB neu setzen, da Rest nicht verändert
 cmp #11,d0                     * Schreibstift zu tief ?
 bpl.s prtlp1                   * Nein, dann nächste Zeile
prtallfi:
 move (a7)+, sr                 * Staus zurück
 movem.l (a7)+,d0-d5/a0-a2
 rts

putchar:                        * Sonderzeichenausgabe
 btst.b #6, keydil(a5)          * GDP-FPGA?
 beq.s ptchr10                  * nein
 cmp.b #$a0, d0                 * Druckbares Zeichen?
 blt.s ptchr10                  * nein, dann Sonderbehandlung
 and.b #$7f, d0                 * Bit 7 = 0
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
putchar1:                       * Wert an GDP schicken, alles erlaubt
 btst.b #2, gdp.w               * Ohne Sprung zu wait schneller
 beq.s putchar1
 bset.b #4, gdp+2*cpu.w         * 2. Zeichensatz setzen
 move.b d0, gdp.w               * Befehl ausgeben
putchar2:
 btst.b #2, gdp.w               * GDP fertig?
 beq.s putchar2                 * sonst Darstellungsfehler
 bclr.b #4, gdp+2*cpu.w         * wieder 1. Zeichensatz
 or.b #$80, d0                  * Bit 7 = 1
 move (a7)+, sr                 * Staus zurück
  rts

ptchr10:
 movem.l d1/a0-a1, -(a7)
 lea ztab0(pc), a1              * Zeichencode
 lea ztab2(pc), a0              * Bit-Tabelle
 moveq #anztab-1, d1
ptchr11:
 cmp.b (a1)+, d0                * Vergleich, ob es dieses Zeichen ist
 beq.s ptchr12                  * Ja, dann Ausgabe
 addq.l #5, a0                  * Sonst auch neue Einstellung der Bit-Tabelle
 dbra d1, ptchr11
 bra.s ptchr13                  * Ende, da nicht gefunden
ptchr12:
 bsr.s progzge                  * Ausgabe des Sonderzeichens
ptchr13:
 movem.l (a7)+, d1/a0-a1
  rts

getcode:                        * Bei deutschem Zeichensatz, Bit 7 setzen
 tst.b optflag(a5)              * Amerikanischer Zeichensatz an ?
 beq carset                     * Ja, dann keine Wandlung
getcodeo:
 movem.l d1/a0,-(a7)
 cmp.b #2, optflag(a5)          * User Zeichensatz?
 beq.s getcode2                 * Ja, dann Bit 7 setzen
 lea ztab1(pc),a0               * Tabelle der Zeichen
 moveq #anztab-1,d1             * Anzahl der Zeichen
getcode1:
 cmp.b (a0)+,d0                 * Vergleich
 beq.s getcode2                 * OK, Zeichen gefunden
 dbra d1,getcode1
 bra.s getcode3                  * Nein, kein deutsches Zeichen
getcode2:
 bset #7,d0                     * Bit 7 setzen, da deutsches Zeichen
getcode3:
 movem.l (a7)+,d1/a0
 rts

anztab EQU 9                    * Anzahl der Sonderzeichen

ztab0:                          * Sonderzeichen
 DC.b $db,$dc,$dd,$fb,$fc,$fd,$fe
 DC.b $81,$82
 ds 0
ztab1:                          * Sonderzeichen für Umcodierung
 DC.b $5b,$5c,$5d,$7b,$7c,$7d,$7e
 DC.b 1,2

ztab2:                          * Bitcode Sonderzeichen
 DC.b $7d,$0a,$09,$0a,$7d       * Ä
 DC.b $3d,$42,$42,$42,$3d       * Ö
 DC.b $7d,$40,$40,$40,$7d       * Ü
 DC.b $71,$54,$54,$78,$41       * ä
 DC.b $00,$39,$44,$44,$39       * ö
 DC.b $3d,$40,$40,$7d,$40       * ü
 DC.b $00,$7f,$01,$4d,$32       * ß

 DC.b $00,$7f,$3e,$1c,$08
 DC.b $08,$1c,$3e,$7f,$00

progzge:                        * Programmierbarer Zeichengenerator
 movem.l d0-d7/a0/a1, -(a7)
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
 lea gdp.w, a1
 bsr getxy                      * Aktuelle Position holen
 move.b gdp+3*cpu.w, d4         * Schriftgröße auch
 cmp.b #$11, d4                 * Bei Größe $11
 beq.s prog11zge                * schnelle Extraroutine
 move.b gdp+5*cpu.w, -(a7)      * GDP-Register merken, da zerstört
 move.b d4, d3                  * Größe merken
 lsr #4, d3                     * SizeX
 and #$f, d3                    * Nur 4 Bit
 subq #1, d3                    * -1 wegen Linienlänge
 and #$f, d3                    * Wieder nur 4 Bit
 move.b d3, gdp+5*cpu.w         * Länge der Linien in X-Richtung
 and #$f, d4                    * Das gleiche mit SizeY
 subq #1, d4
 and #$f, d4                    * Aber nur merken für Dbra
 moveq #5-1, d6                 * Breite 5 Punkte, da letzte Spalte leer
progzlp0:
 move.b (a0)+, d0               * Zeichen holen
 beq.s progz3                   * Wenn Null, dann kein Punkt in dieser Reihe
 moveq #8-1, d5                 * Höhe 8 Punkte
progzlp1:
 move d4, -(a7)                 * d4 retten, da für Schleife benötigt
progzlp2:
 btst d5, d0                  * Bit testen
 beq.s progz2                   * Null, dann nicht zeichnen
 movep.w 8*cpu(a1), d7          * ==> Nur für 68000/68010
progz0:
 btst.b #2, (a1)                * Warten bis GDP fertig
 beq.s progz0
 move.b #$10, (a1)              * Linie zeichnen
progz1:
 btst.b #2, (a1)                * Warten bis GDP fertig
 beq.s progz1
 movep.w d7, 8*cpu(a1)          * ==> Nur für 68000/68010
progz2:
 movep.w $a*cpu(a1), d7         * ==> Nur für 68000/68010
 addq #1, d7                    * Y-Position erhöhen
 movep.w d7, $a*cpu(a1)         * ==> Nur für 68000/68010
 dbra d4, progzlp2
 move (a7)+, d4                 * d4 zurück
 dbra d5, progzlp1              * Nächste Reihe
progz3:
 add d3, d1                     * Neue X-Position
 addq #1, d1
 bsr movetoo                    * Nächste Spalte / Kein Wait
 dbra d6, progzlp0
 add d3, d1
 addq #1, d1                    * Am Ende noch eine Spalte für Abstand zwischen
 bsr movetoo                    * den Buchstaben
 move.b (a7)+, gdp+5*cpu.w      * GDP-Register zurück
 move (a7)+, sr                 * Staus zurück
 movem.l (a7)+, d0-d7/a0/a1
  rts

prog11zge:                      * Schnelle Routine für Schriftgröße $11
 moveq #2, d3                   * WAIT-Bit GDP
 moveq #$80, d4                 * Befehl Punkt setzen
 moveq #5-1, d6                 * Breite
pro1g1zg:
 move.b (a0)+, d0               * Eine Spalte holen
 beq.s pro1g4zg                 * Wenn Null, dann kein Punkt in dieser Spalte
 moveq #8-1, d5                 * 8 Punkte Höhe
pro1g2zg:
 btst d5, d0                  * Bit testen
 beq.s pro1g3zg                 * Wenn nicht gesetzt, dann nächstes Bit testen
 move.b d4, (a1)                * Befehl Punkt setzen ausführen
pro1w1:
 btst.b d3, (a1)                * Warten bis GDP fertig
 beq.s pro1w1
pro1g3zg:
 movep.w $a*cpu(a1), d7         * ==> Nur für 68000/68010
 addq #1, d7                    * Y-Position erhöhen
 movep.w d7, $a*cpu(a1)         * ==> Nur für 68000/68010
 dbra d5, pro1g2zg
pro1g4zg:
 addq #1, d1                    * X-Position erhöhen für nächste Spalte
 bsr movetoo
 dbra d6, pro1g1zg
 addq #1, d1
 bsr movetoo                    * Abstand zwischen den Buchstaben beachten
 move (a7)+, sr                 * Staus zurück
 movem.l (a7)+, d0-d7/a0/a1
  rts

scroll:                         * Screen nach oben scrollen
 movem.l d0-d2/a0-a2,-(a7)
 bsr homepos                    * Obere Kante des Bildschirms
 tst.b cotempo(a5)              * Hardware-Scroll eingeschaltet ?
 beq sscroll                    * Nein, dann weiter
 add.b coscroll(a5),d2          * Scroll-Wert bedenken
 move.b curx(a5),-(a7)          * Retten
 move.b cury(a5),-(a7)
 clr.b cury(a5)                 * Auf Null setzen, da oberste Zeile angesprochen
 clr.b curx(a5)                 * werden soll
 bsr erapen                     * Auf Löschen
 moveq #%00010000,d0            * Schreibseite 0
 bsr setpage                    * Leseseite 1
 cmp #246,d2                    * Überlappt Zeile den Bildschirm ?
 bmi.s hscroll3                 * Nein, dann normale Ausgabe
 movem.l d3/d4/a6,-(a7)
 move.b groesse(a5),d3          * Größe holen
 and #$f0,d3                    * Nur X-Vergrößerung lassen, da Dy immer 1
 lsr #3,d3                      * /16*2
 move d3,d4
 add d3,d3
 add d4,d3                      * Dx*6
 moveq #0,d0
 bsr getline                    * Zeileninfo der zu löschenden Zeile
 clr d1
 move.b (a1),d1                 * Anzahl der Zeichen
 muls d1,d3                     * Zeilenlänge in Pixel berechnet
 cmp #512,d3
 bmi.s hscroll0                 * Sollte nicht über rechten Rand gehen
 move #511,d3                   * Maximal bis 511
hscroll0:
 clr d1
 lea gdp.w,a6                   * Wird bei gr1xline verlangt
 moveq #8-1,d4                  * Zeichenhöhe ist 8
hscroll1:
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
 bsr gr1xline                   * Zeile löschen
 move (a7)+, sr                 * Staus zurück
 addq.b #1,d2                   * Nächste Zeile
 dbra d4,hscroll1
 sub.b #10,coscroll(a5)         * Scrollwert ändern
 moveq #%01000000,d0            * Andere Seite
 move.b coscroll(a5),page1.w    * Scroll einstellen
 bsr setpage                    * Seite umschalten
 moveq #8-1,d4                  * Auch dort 8 Zeilen löschen
hscroll2:
 subq.b #1,d2
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
 bsr gr1xline                   * Zeile löschen
 move (a7)+, sr                 * Staus zurück
 dbra d4,hscroll2
 movem.l (a7)+,d3/d4/a6         * Register zurück
 bra.s hscroll4                 * Jetzt normal weiter
hscroll3:
 bsr movetoo                    * Positionieren
 bsr prtline1                   * Oberste Zeile löschen mit Bildschirmrand
 sub.b #10,coscroll(a5)         * Scroll-Wert
 moveq #%01000000,d0
 move.b coscroll(a5),page1.w    * An GDP
 bsr setpage                    * Seite 1 als Schreibseite
 bsr movetoo                    * Neu Positionieren
 bsr prtline1                   * Andere Seite Zeile löschen
hscroll4:
 bsr setpen                     * Wieder auf Schreiben
 move.b (a7)+,cury(a5)          * Register zurück
 move.b (a7)+,curx(a5)
 moveq #5,d1                    * Maximal 4 Sync-Impulse
 sub.b cotempo(a5),d1           * cotempo ist nämlich maximal 5
 bra.s hscroll6                 * Wegen Abfrage auf -1
hscroll5:
 bsr sync                       * Warten
 beq.s hscroll5                 * Tempobestimmung beim Scroll
hscroll6:
 dbra d1,hscroll5
 bra.s sscroll1                 * Bildschirmspeicher in Ordnung bringen
sscroll:
 moveq #%01000000,d0            * Seite einstellen
 bsr setpage
 bsr movetoo                    * Anfangsposition für Ausgabe
 bsr.s scrolupr                 * Eine Seite scrollen
 bsr seite0                     * Andere Seite wählen
 bsr.s scrolupr                 * Auch scrollen
sscroll1:                       * Einsprung von hscroll
 moveq #0,d0                    * Zeile Null wählen
 bsr getline                    * Daten errechnen
 move.b (a1),d0                 * Anzahl der Zeichen holen
 beq.s sscroll2                 * Leerzeile, dann OK
 subq #1,d0                     * Sonst -1 für dbra
 clr.b (a1)                     * Anzahl der Zeichen ist jetzt Null
sscrolp:
 move.b #' ',(a0)+              * Mit Leerzeichen füllen
 dbra d0,sscrolp                * bis alle Zeichen überschrieben sind
sscroll2:
 lea lineptr(a5),a0             * Pointer auf Zeile
 move.b (a0),d0                 * Erste Zeile merken
 moveq #23-1,d1                 * 23 mal schieben
sscroll3:
 move.b 1(a0),(a0)+             * Schieben
 dbra d1,sscroll3
 move.b d0,(a0)                 * Ehemalige erste Zeile ist jetzt letzte Zeile
 movem.l (a7)+,d0-d2/a0-a2
  rts

scrolupr:
 bsr erapen                     * Auf Löschen
 bsr prtall                     * Seite löschen
 bsr setpen                     * Auf Schreiben
 bsr movetoo                    * Neue Position
 bra prttop                     * Von Zeile 1 bis 24 ausgeben

charhandler:                    * Buchstabenverwaltung
 bsr.s char1han                 * Buchstaben ausgeben
 addq.b #1,curx(a5)             * X-Position erhöhen
 cmp.b #79,curx(a5)             * Wenn kleiner als Position 79, dann OK
 bls.s charhanfi
 clr.b curx(a5)                 * Sonst auf Anfang nächste Zeile
 addq.b #1,cury(a5)             * Und Y-Position erhöhen
 cmp.b #23,cury(a5)             * Auf unterster Zeile ?
 bls.s charhanfi                * Nein, dann OK
 move.b #23,cury(a5)            * Sonst auf unterste Zeile setzen
 bra scroll                     * und scrollen
charhanfi:
  rts

charoscr:                       * Buchstaben ausgeben ohne Scroll
 bsr.s char1han                 * Ausgabe
 cmp.b #79,curx(a5)             * Am Ende der Zeile angelangt ?
 bpl   carset                   * Ja, dann Ende
 addq.b #1,curx(a5)             * Sonst neue X-Position
 bra     carres

char1han:                       * Achtung Register werden zerstört
 movem.l d1-d3,-(a7)
 move.b d0,d3                   * Zeichen merken
 clr.b wrtpage(a5)              * Schreibseite
 clr.b viewpage(a5)             * Und Leseseite auf Null
 bsr aktpage                    * einstellen
 bsr aktcur                     * Auf aktuelle Cursorposition
 bsr calccur                    * Zeileninfo holen
 move.b curx(a5),d0             * Cursorposition holen
 addq.b #1,d0                   * und erhöhen
 cmp.b (a1),d0                  * Wenn hier noch kein Zeichen vorhanden war
 bcs.s char0
 move.b d0,(a1)                 * Dann Zeichenzähler erhöhen
char0:
 cmp #511,d1                    * Wenn zu weit rechts, dann
 bhi.s charfi                   * keine Ausgabe
 tst.b cotempo(a5)              * Hard-Scroll an ?
 bne.s char1                    * Ja, dann Ausgabe
 cmp #11,d2                     * Zu tief ?
 bmi.s charfi                   * Ja, dann keine Ausgabe
char1:
 bsr.s char2                    * Ausgabe des Zeichens
 move.b #1,wrtpage(a5)          * Andere Seite
 bsr aktpage
 bsr movetoo                    * Positionieren
 bsr.s char2                    * Ausgabe
charfi:
 move.b d3,(a2)                 * Zeichen auch in den Bildschirmspeicher
 movem.l (a7)+,d1-d3
  rts

char2:
 cmp.b #' ',(a2)                * Leerzeichen an aktueller Stelle ?
 beq.s char3                    * Ja, dann kein Vorlöschen
 bsr erapen                     * Auf Löschen
 move.b #10,gdp.w               * Block ausgeben
 tst.b cotempo(a5)              * Hardscroll an ?
 beq.s char3                    * Nein, weiter
 cmp #249,d2                    * Ausgabe-Wert im Bildschirm-Bereich ?
 bmi.s char3                    * Ja, dann weiter
 sub #256,d2                    * Andere Hälfte des Buchstaben ausgeben
 bsr moveto                     * Positionieren
 move.b #10,gdp.w               * Wieder Löschen
 add #256,d2                    * Alte Position
char3:
 bsr moveto                     * Neu positionieren
 bsr setpen                     * Auf Schreiben
 move.b d3,d0                   * Zeichen ausgeben
 tst.b cotempo(a5)              * Hardscroll an ?
 beq cmdput                     * Nein, dann Ausgabe Zeichen
 bsr cmdput                     * Ausgabe mit Sonderzeichen
 cmp #249,d2                    * Y-Pos im Screen-Bereich ?
 bmi.s char4                    * Ja, dann Ende
 sub #256,d2                    * Andere Hälfte des Buchstaben ausgeben
 bsr moveto                     * Positionieren
 add #256,d2                    * Alte Position
 bra cmdput                     * Ausgabe Zeichen
char4:
  rts

seite0:
 clr.b wrtpage(a5)              * Seite Null als Schreibseite
 move.b #1,viewpage(a5)         * Und Seite 1 als Leseseite
 bsr aktpage                    * einstellen
 bra movetoo                    * Und positionieren

seite1:
 clr.b viewpage(a5)             * Seite 1 als Leseseite
 move.b #1,wrtpage(a5)          * Seite 0 als Schreibseite
 bsr aktpage
 bsr erapen                     * Auf Löschen
 bra aktcur                     * Cursorposition berechnen

eraeoln:                        * Ende der Zeile löschen
 movem.l d0-d2/a0-a2,-(a7)
 bsr.s seite1                   * Seite 1 wählen
 bsr prtlinehs                  * Ende der Zeile löschen
 bsr.s seite0                   * Seite 0
 bsr prtlinehs                  * Ende der Zeile löschen
 bsr.s eraln                    * Auch Speicher in Ordnung bringen
 movem.l (a7)+,d0-d2/a0-a2
  rts

eraln:
 bsr calccur                    * Zeileninfo holen
 move.b curx(a5),(a1)           * Anzahl der Zeichen bis zur Cursorposition
 moveq #80-1,d0                 * Maximal 80 Zeichen (-1 wegen dbra)
 sub.b (a1),d0                  * Cursorposition abziehen
eral1:
 move.b #' ',(a2)+              * Im Speicher löschen
 dbra d0,eral1
  rts

eraeos:                         * Ende der Seite löschen
 movem.l d0-d2/a0-a2,-(a7)
 bsr.s seite1                   * Seite 1
 bsr prtrest                    * Löschen
 bsr.s seite0                   * Seite 0
 bsr prtrest                    * Löschen
 bsr.s eraln                    * Rest der Zeile im Speicher in Ordnung bringen
 move.b cury(a5),d1             * Y-Position holen
eraxlp:
 addq.b #1,d1                   * Um eins erhöhen, da erste Zeile bereits OK ist
 cmp.b #24,d1                   * Wenn letzte Zeile erreicht war, dann Ende
 beq.s erafx1
 move.b d1,d0                   * Nummer der Zeile
 bsr getline                    * Zeileninfo holen
 move.b (a1),d0                 * Anzahl der vorherigen Zeichen holen
 beq.s eraxlp                   * Kein Zeichen, dann nächste Zeile
 clr.b (a1)                     * Anzahl der Zeichen ist jetzt Null
erax1lp:
 move.b #' ',(a0)+              * Zeichen im Speicher löschen
 subq.b #1,d0                   * Zeichenzähler erniedrigen
 bne.s erax1lp                  * Bis alle Zeichen gelöscht
 bra.s eraxlp                   * Nächste Zeile
erafx1:
 movem.l (a7)+,d0-d2/a0-a2
  rts

inschar:                        * Ein Zeichen einfügen
 movem.l d0-d3/a0-a2,-(a7)
 bsr calccur                    * Zeileninfo holen
 tst.b (a1)                     * Anzahl der Zeichen testen
 beq.s insend                   * Null, dann kein Einfügen nötig
 move.b curx(a5),d0             * Wenn Cursorposition
 cmp.b (a1),d0                  * größer ist als
 bhi.s insend                   * Anzahl der Zeichen, dann auch Ende
 bsr seite1                     * Seite 1 anwählen
 move d1,d3
 bsr.s ins1                     * Einfügen
 move d3,d1
 bsr seite0                     * Seite 0 anwählen
 bsr erapen                     * Auf Löschen schalten
 bsr.s ins1                     * Einfügen
 bsr calccur                    * Zeileninfo holen
 cmp.b #80,(a1)                 * Mehr Zeichen als 80 sind
 bpl.s ins2                     * nicht möglich
 addq.b #1,(a1)                 * Sonst ein Zeichen mehr vorhanden
ins2:
 lea 79(a0),a0                  * Letztes Zeichen der Zeile
ins3:
 cmpa.l a2,a0                   * Wenn Cursorposition erreicht ist,
 beq.s ins4                     * ist alles verschoben
 move.b -(a0),1(a0)             * sonst weiter schieben
 bra.s ins3
ins4:
 move.b #' ',(a0)               * Leerzeichen an aktueller Stelle
insend:
 movem.l (a7)+,d0-d3/a0-a2
  rts

ins1:
 bsr prtlinehs                  * Zeile löschen
 move.b groesse(a5),d0
 lsr #3,d0
 and #$1e,d0
 add d0,d1
 add d0,d0
 add d0,d1
 bsr moveto                     * Neu positionieren
 bsr setpen                     * Auf Schreiben
 cmp.b #79,curx(a5)             * Cursor an letzter Position ?
 bmi prt79hs                    * Nein, dann Rest ausgeben
  rts

delchar:                        * Ein Zeichen löschen
 movem.l d0-d2/a0-a2,-(a7)
 bsr calccur                    * Zeileninfo holen
 tst.b (a1)                     * Wenn Anzahl der Zeichen Null ist, ist kein
 beq.s delend                   * Löschen nötig
 move.b curx(a5),d0             * Wenn Cursor hinter letztem Zeichen steht
 cmp.b (a1),d0                  * auch nicht
 bpl.s delend
 bsr seite1                     * Seite 1
 bsr.s del1                     * Löschen
 bsr seite0                     * Seite Null
 bsr erapen                     * Auf Löschen
 bsr.s del1                     * Auch Löschen
 bsr calccur                    * Zeileninfo holen
 subq.b #1,(a1)                 * Anzahl der Zeichen ist eins weniger
 move.b curx(a5),d0             * Cursorposition holen
del2:
 cmp.b #79,d0                   * Wenn Ende der Zeile erreicht
 bpl.s del3                     * dann Ende
 move.b 1(a2),(a2)+             * Sonst schieben
 addq.b #1,d0                   * Cursorposition erhöhen für Test
 bra.s del2                     * Schleife
del3:
 move.b #' ',(a2)               * Hinten Leerzeichen setzen
delend:
 movem.l (a7)+,d0-d2/a0-a2
  rts

del1:
 bsr prtlinehs                  * Zeile vorlöschen
 bsr setpen                     * Auf Schreiben
 cmp.b #79,curx(a5)             * Wenn Cursor am Ende der Zeile steht, ist keine
 bpl.s del10                    * Ausgabe mehr nötig
 bsr movetoo                    * Sonst neu positionieren
 addq.b #1,curx(a5)             * Ab nächstem Zeichen
 bsr prtlinehs                  * Ausgabe der Zeile (verschoben)
 subq.b #1,curx(a5)             * Cursorposition wieder herstellen
del10:
  rts

insline:                        * Eine Zeile einfügen
 movem.l d0-d2/a0-a2,-(a7)
 clr.b curx(a5)                 * Cursor steht danach auf erstem Zeichen
 bsr seite1                     * Seite 1
 bsr prtrest                    * Rest des Bildschirms löschen
 cmp.b #23,cury(a5)             * Wenn Cursor auf letzter Zeile, dann weiter
 bpl.s insl1
 addq.b #1,cury(a5)             * Sonst eine Zeile runter und Position holen
 movem d1-d2,-(a7)              * Rev 6.0 muß gerettet werden, weil seit Rev 6.0
 bsr aktcur                     * d1/d2 in aktcur zerstört werden
 movem (a7)+,d1-d2
 subq.b #1,cury(a5)             * Cursorposition wieder in Ordnung bringen
 bsr setpen                     * Auf Schreiben
 bsr prtr23                     * Rest ausgeben
insl1:
 bsr seite0                     * Das gleiche nochmal auf der anderen Seite
 bsr erapen
 bsr prtrest                    * Rest löschen
 bsr setpen
 cmp.b #23,cury(a5)
 bpl.s insl2
 addq.b #1,cury(a5)
 bsr aktcur
 subq.b #1,cury(a5)
 bsr prtr23                     * Ausgabe wenn nötig
insl2:
 lea lineptr(a5),a0             * Zeiger auf Zeile im Bildschirmbereich
 moveq #0,d0
 move.b cury(a5),d0
 adda.l d0,a0                   * Von Cursorposition an verschieben
 lea lineptr+23(a5),a1
 move.b (a1),d1                 * Letzte Zeile merken
insl3:
 cmpa.l a1,a0                   * Letzte Zeile ?
 beq.s insl4                    * Ja, Ende
 move.b -(a1),1(a1)             * Verschieben
 bra.s insl3
insl4:
 move.b d1,(a1)                 * Letzte Zeile ist jetzt Zeile an Cursorposition
 bra.s delline0                 * ( Im Speicher )

delline:                        * Eine Zeile löschen
 movem.l d0-d2/a0-a2,-(a7)
 clr.b curx(a5)                 * Cursor ist danach auf Zeilenanfang
 bsr seite1                     * Auf Seite 1
 bsr.s dell1                    * ausgeben
 bsr seite0                     * Dann auf Seite Null
 bsr erapen                     * Auf Löschen
 bsr.s dell1                    * Ausgabe
 lea lineptr(a5),a0             * Zeiger auf Zeile
 moveq #0,d0
 move.b cury(a5),d0
 adda.l d0,a0                   * Von Cursorposition an verschieben
 move.b (a0),d1                 * Merken
dell3:
 move.b 1(a0),(a0)+             * Verschieben
 addq.b #1,d0                   * Bis Ende der Seite
 cmp.b #24,d0                   * erreicht
 bne.s dell3
 move.b d1,-(a0)                * Zurück
 moveq #23,d0                   * Zeileninfo letzte Zeile
delline0:
 bsr getline                    * Zeileninfo holen
 move.b (a1),d0                 * Anzahl der Zeichen holen
 beq.s dell5                    * Null, dann kein Löschen
 clr.b (a1)                     * Anzahl, der Zeichen ist Null
dell4:
 move.b #' ',(a0)+              * Mit Leerzeichen füllen
 subq.b #1,d0                   * Bis alle gelöscht
 bne.s dell4
dell5:
 movem.l (a7)+,d0-d2/a0-a2
  rts

dell1:
 bsr prtrest                    * Rest der Seite löschen
 bsr setpen                     * Auf Schreiben
 cmp.b #23,cury(a5)             * Wenn letzte Zeile, dann kein Ausgeben mehr
 bpl.s dell2
 bsr movetoo                    * Sonst neu positionieren
 addq.b #1,cury(a5)             * Von nächster Zeile an
 bsr prtrest                    * Ausgabe
 subq.b #1,cury(a5)             * Y-Koordinate wieder auf alten Wert
dell2:
  rts

eschandler:
 move.b #1,escmerker(a5)        * Escape anschalten
  rts

esc1:
 cmp.b #2,escmerker(a5)         * Merker auf 2 ?
 bne.s esc2                     * Nein, dann weiter
 sub.b #32,d0                   * Sonst Befehl Y-Position einstellen
 and.l #$ff,d0                  * Für Divs Langwort nötig
 divu #24,d0                    * Dividieren
 swap d0                        * Rest nehmen, damit nicht über 24
 move.b d0,cury(a5)             * Cursor einstellen
 move.b #3,escmerker(a5)        * Flag, daß dann X-Position folgt
  rts

esc2:
 cmp.b #3,escmerker(a5)         * Jetzt X einstellen ?
 bne.s esc3                     * Nein, weiter
 clr.b escmerker(a5)            * Auf Null setzen, da Escape-Sequenz zu Ende
 sub.b #32,d0                   * Wandeln, da Eingabe als ASCII-Zeichen
 and.l #$ff,d0                  * Langwort nötig
 divu #80,d0                    * Auch hier Division
 swap d0                        * Und Rest nehmen
 move.b d0,curx(a5)             * Nach curx
 movem.l d1-d2,-(a7)
 bsr aktcur                     * Und Position einstellen
 movem.l (a7)+,d1-d2
  rts

esc3:
 cmp.b #'=',d0                  * Befehl Cursor setzen
 bne.s esc4
 move.b #2,escmerker(a5)        * Flag dafür
  rts

esc4:
 bsr.s esc5                     * Alles abfragen
 clr.b escmerker(a5)            * Danach Flag löschen, da ESC-Befehl zu Ende
  rts

esc5:
 bsr wait                       * Warten, bis GDP fertig
 move.b groesse(a5),gdp+3*cpu.w * Größe einstellen zur Sicherheit
 cmp.b #'Q',d0
 beq inschar                    * Zeichen einfügen
 cmp.b #'W',d0
 beq delchar                    * Zeichen löschen
 cmp.b #'E',d0
 beq insline                    * Zeile einfügen
 cmp.b #'R',d0
 beq delline                    * Zeile löschen
 cmp.b #'T',d0
 beq eraeoln                    * Rest der Zeile löschen
 cmp.b #'Y',d0
 beq eraeos                     * Rest der Seite löschen
 cmp.b #'$',d0
 bne.s esc6
 move.b #1,optflag(a5)          * Zeichensatz auf deutsch umschalten
  rts

esc6:
 cmp.b #'%',d0
 bne.s esc6a
 clr.b optflag(a5)              * Zeichensatz auf amerikanisch
  rts

esc6a:
 btst.b #6, keydil(a5)          * GDP-FPGA da?
 beq.s esc7                     * nein, dann kein Umschalten
 cmp.b #'&',d0
 bne.s esc7
 move.b #2,optflag(a5)          * Zeichensatz auf User-Definiert
  rts

esc7:
 cmp.b #'0',d0                  * Auf Software-Scroll umschalten
 bne.s esc8
 tst.b cotempo(a5)              * War schon, dann nichts machen
 beq carres
 movem.l d1-d2,-(a7)
 clr.b cotempo(a5)              * Auf Software-Scroll
 bsr homepos                    * Position links oben
 moveq #%01000000,d0
 bsr setpage                    * Seite 0
 bsr clrinvis                   * Seite löschen
 bsr moveto                     * Neue Position
 bsr prtall                     * Ausgabe
 clr.b page1.w                  * Scroll aus
 clr.b coscroll(a5)             * Auch Merker aus
 moveq #%00010000,d0            * Andere Seite
 bsr setpage
 bsr clrinvis                   * Löschen
 bsr moveto                     * Positionieren
 bsr prtall                     * Ausgabe neu
 bsr aktpage                    * Alte Seite
 movem.l (a7)+,d1-d2
  rts

esc8:
 cmp.b #'1',d0                  * Hardware-Scroll verschiedene Geschwindigkeiten
 bmi.s esc10
 cmp.b #'5',d0
 bhi.s esc10
 btst.b #0,ioflag(a5)           * Neue GDP ?
 beq.s esc9                     * Nein, dann sind die Befehle verboten
 swap d0                        * d0 nicht zerstören
 move.b groesse(a5),d0          * Größe holen
 and.b #$f,d0                   * Nur Y-Vergrößerung
 cmp.b #1,d0                    * Nicht 1 ?
 bne.s esc9                     * Ja, dann ist Hard-Scroll nicht erlaubt
 swap d0
 and #7,d0
 move.b d0,cotempo(a5)          * Merken der neuen Scroll-Art

esc9:
  rts

esc10:
 cmp.b #'O',d0                  * Hardcopy-Funktionen
 bne.s esc11
esc10a:
 movem.l d6/d7/a3,-(a7)
 lea lo2(pc),a3                 * Ohne Zeichensatzumschaltung
 bsr.s esc12
 movem.l (a7)+,d6/d7/a3
  rts

esc11:
 cmp.b #'P',d0
 bne.s esc13
esc11a:
 movem.l d6/d7/a3,-(a7)
 bsr initdr                     * Initialisierung
 lea lo(pc),a3                  * Mit Zeichensatzumschaltung
 bsr.s esc12
 bsr drmenq                     * Seitenvorschub
 movem.l (a7)+,d6/d7/a3
  rts

esc12:
 moveq #24-1,d7                 * 24 Zeilen ausgeben
esc12a:
 moveq #23,d0
 sub d7,d0                      * Von 0 bis 23
 bsr getline                    * Zeileninfo holen
 move.b (a1),d6                 * Anzahl der Zeichen
 beq.s esc12c                   * Null, dann nur Zeilenvorschub
esc12b:
 move.b (a0)+,d0                * Zeichen holen
 jsr (a3)                       * Ausgabe über Drucker
 subq.b #1,d6
 bne.s esc12b                   * Bis Zeile ausgegeben ist
esc12c:
 bsr locrlf                     * Zeilenvorschub
 dbra d7,esc12a                 * Bis alle Zeilen ausgegeben sind

esc13:
  rts

ctrlhandler:                    * Controlzeichen-Auswertung
 cmp.b #$8,d0                   * BS ?
 bne.s ctr1                     * Nein, weiter ?
 tst.b curx(a5)                 * Schon am Anfang der Zeile ?
 beq.s ctr01                    * Ja, dann weiter
 subq.b #1,curx(a5)             * Sonst X-Position erniedrigen
  rts

ctr01:
 tst.b cury(a5)                 * Obere Zeile erreicht ?
 beq.s ctr02                    * Ja, dann OK
 move.b #79,curx(a5)            * Sonst ans Ende der
 subq.b #1,cury(a5)             * vorherigen Zeile
ctr02:
  rts

ctr1:
 cmp.b #$1a,d0                  * Ctrl-Z
 beq clrscreen                  * Bildschirm löschen

ctr2:
 cmp.b #$1e,d0                  * Ctrl-^
 bne.s ctr3
ctr2a:
 clr.b curx(a5)                 * X-Position ist Null
 clr.b cury(a5)                 * Y-Position auch
  rts

ctr3:
 cmp.b #$b,d0                   * Ctrl-K
 bne.s ctr4
 tst.b cury(a5)                 * Oberste Zeile erreicht ?
 beq.s ctr31                    * Ja, dann nichts ändern
 subq.b #1,cury(a5)             * Sonst Cursor eine Zeile hoch
ctr31:
  rts

ctr4:
 cmp.b #$a,d0                   * Ctrl-J
 bne.s ctr5
 cmp.b #23,cury(a5)             * Unterste Zeile erreicht ?
 bpl scroll                     * Ja, dann scrollen
 addq.b #1,cury(a5)             * Sonst Cursor eine Zeile runter
  rts

ctr5:
 cmp.b #$16,d0                  * Ctrl-V
 bne.s ctr6
 cmp.b #23,cury(a5)             * Wie Ctrl-J aber ohne Scroll
 bpl.s ctr51
 addq.b #1,cury(a5)
ctr51:
  rts

ctr6:
 cmp.b #$c,d0                   * Ctrl-L
 beq.s ctr61
 cmp.b #$9,d0                   * Und Ctrl-I
 bne.s ctr7
ctr61:
 cmp.b #79,curx(a5)             * Letztes  Zeichen in einer Reihe erreicht ?
 bne.s ctr62                    * Nein, dann weiter
 clr.b curx(a5)                 * An Anfang der Zeile
 cmp.b #23,cury(a5)             * Letzte Zeile erreicht ?
 bpl scroll                     * Ja, dann Scroll
 addq.b #1,cury(a5)             * Sonst nur erhöhen
  rts

ctr62:
 addq.b #1,curx(a5)             * Cursor nach rechts
  rts

ctr7:
 cmp.b #$d,d0                   * Ctrl-M
 bne.s ctr8
 clr.b curx(a5)                 * An Anfang der Zeile

ctr8:
  rts

prtco:                          * Text von a0 an über co ausgeben
 move.b (a0)+,d0                * Zeichen holen
 beq.s prt1co                   * Null ist Ende
 move.l a0,-(a7)                * a0 retten, da zerstört
 bsr.s co                       * Ausgabe Zeichen
 movea.l (a7)+,a0               * a0 zurück
 bra.s prtco                    * Schleife
prt1co:
  rts

co:                             * Bildschirmverwaltungsroutine ohne Umlenkung
 tst.b escmerker(a5)            * Wurde ESC eingschaltet
 bne esc1                       * Ja, dann aufrufen
 cmp.b #$1b,d0                  * ESCAPE ?
 beq eschandler                 * Ja, dann Auswertung
 bsr wait                       * Warten, bis GDP fertig
 move.b groesse(a5),gdp+3*cpu.w * Größe einstellen zur Sicherheit
 cmp.b #' ',d0                  * Kleiner als ' ', dann
 bcs ctrlhandler                * CTRL-Zeichen
 bra charhandler                * Sonst normales ASCII-Zeichen


*******************************************************************************
*                         680xx Grundprogramm sincos                          *
*                         (C) 1990 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                         Sinus und Cosinus Routinen                          *
*******************************************************************************


* Unterprogramme für sin/cos

adj360:                         * Bereich 0..359 wandeln
 tst d0
 bmi.s adj1                     * Negativ, dann addieren
adjlp:
 cmp #360,d0
 bmi.s adjfin                   * Kleiner 360, dann OK
 sub #360,d0                    * Sonst subtrahieren
 bra.s adjlp
adj1:
 add #360,d0                    * So lange addieren, bis größer 0
 bmi.s adj1
adjfin:
 rts

cos:                            * Cosinus berechnen
 add #90,d0
sin:                            * Sinus berechnen
 bsr.s adj360                   * 0..359 wandeln
 add d0,d0                      * Mal zwei für Tabellenverwaltung
 cmp #540,d0
 bpl.s sin3
 cmp #360,d0
 bpl.s sin2
 cmp #180,d0
 bpl.s sin1
sin0:                           * 0 <= X < 90
 move sintab(pc,d0),d0
 rts
sin1:                           * 90 <= X < 180
 sub #360,d0
 neg d0
 move sintab(pc,d0),d0
 rts
sin2:                           * 180 <= X < 270
 sub #360,d0
 move sintab(pc,d0),d0
 neg d0
 rts
sin3:                           * 270 <= X < 360
 sub #720,d0
 neg d0
 move sintab(pc,d0),d0
 neg d0
 rts

sintab:
 DC.w 0,4,9,13,18,22,27,31,36,40,44,49,53,58,62,66,71,75,79,83,88,92,96,100,104
 DC.w 108,112,116,120,124,128,132,136,139,143,147,150,154,158,161,165,168
 DC.w 171,175,178,181,184,187,190,193,196,199,202,205,207,210,212,215,217,219
 DC.w 222,224,226,228,230,232,234,236,237,239,241,242,243,245,246,247,248,249
 DC.w 250,251,252,253,254,254,255,255,255,256,256,256,256
*******************************************************************************
*                         680xx Grundprogramm textio                          *
*                         (C) 1990 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                        Text- Ein- Ausgaberoutinen                           *
*******************************************************************************


print:                          * Werte in Folge an GDP übersenden
 bsr.s setprt                   * Alles erlaubt, auch Kurzvektoren
printlp:                        * Ohne Vorlöschen
 move.b (a0)+,d0                * Wert holen
 beq.s printfi                  * 0 ist Endekennung
 bsr cmd                        * An GDP ausgeben / Auch Vektoren erlaubt
 bra.s printlp
printfi:
 rts

setprt:                         * Positionieren
 bsr moveto
 and.b #$f0, gdp+2*cpu.w        * Zeichen gerade aufrecht
 move.b d0,gdp+3*cpu.w          * Scalierung x,y
 rts

centertxt:
 moveq #-1,d1                   * Gibt Text genau in der Mitte des Bildschirms
centtxt1:                       * aus / Für Überschriften bei Menüsteuerung
 addq #1,d1                     * Anzahl+1
 tst.b 0(a0,d1.w)               * Anzahl der Zeichen feststellen
 bne.s centtxt1                 * Bis Null erreicht
 move d0,-(a7)
 lsr #4,d0                      * X-Vergrößerung
 and #$f,d0
 bne.s centtxt2
 moveq #16,d0                   * Bei 0, Vergrößerung mal 16
centtxt2:
 muls #-3,d0                    * Mal Zeichengröße / 2
 muls d0,d1                     * Mal Anzahl der Zeichen
 move (a7)+,d0
 add #256,d1                    * Hälfte Bildschirmbreite
                                * Position berechnet, jetzt Text ausgeben

textaus:                        * Text ausgeben mit Vorlöschen und Sonderzeichen
 movem.l d0-d2/a0,-(a7)
 bsr.s setprt                   * Positionieren und Schriftgröße
 move d0,d2
 lsr #4,d2
 and #$f,d2
 bne.s texta0
 moveq #16,d2                   * Null ist Vergrößerung 16
texta0:
 mulu #6,d2                     * Abstand der Buchstaben
texta1:
 tst.b (a0)
 beq.s textaend                 * Null ist Ende
 bsr erapen                     * Erst vorlöschen
 move.b #10,gdp.w
 bsr setpen                     * Dann setzen
 move d1,d0
 move.b d0,gdp+9*cpu.w
 lsr #8,d0
 move.b d0,gdp+8*cpu.w          * Neue X-Position
 move.b (a0)+,d0
 bsr cmdput                     * Dann ausgeben
 add d2,d1                      * Neue Position feststellen / nicht mit getxy
 bra.s texta1                    * Nächstes Zeichen
textaend:
 movem.l (a7)+,d0-d2/a0
 rts

textprint:                      * Wie textaus aber mit $a = CRLF
 movem.l d0/d2/d3/a0,-(a7)      * Ohne Vorlöschen
 bsr.s setprt                   * Mit Sonderzeichen
 move d0,d3
textpr1:
 move.b (a0)+,d0                * Null ist Endekennung
 beq.s textprend
 cmp.b #$a,d0                   * $a ist Linefeed
 bne.s textpr3
 move d3,d0                     * CR LF
 and #$f,d0
 bne.s textpr2
 moveq #16,d0                   * Null ist Vergrößerung 16
textpr2:
 mulu #10,d0                    * Schrifthöhe
 sub d0,d2
 bsr moveto                     * Wieder neu Positionieren
 bra.s textpr1
textpr3:
 bsr cmdput                     * Mit Sonderzeichenausgabe
 bra.s textpr1
textprend:
 movem.l (a7)+,d0/d2/d3/a0
 rts

menueio:
 bsr clrall                     * Mit Bildschirmlöschen
menueio0:                       * a0 = Ausgabetext
 moveq #$22,d0                  * Menütext ausgeben von $33 auf $22 verringert
 moveq #30,d1
 move #190,d2
 bsr.s textprint                * Auch Linefeed erlaubt ohne Vorlöschen, da clr
menueio1:
 moveq #$22,d0                  * Dann maximal ein Zeichen einlesen
 moveq #30,d1
 moveq #3,d2
 moveq #1,d3                    * Nur ein Zeichen lesen
 lea einbuf(a5),a0
 bsr.s textein
 bcc.s menueio2
 moveq #'Z',d5                  * ESC
menueio2:
 move.b d5,d0                   * Eingegebenes Zeichen nach d0
 bsr namecheck                  * In Großbuchstaben wandeln
 bcs.s menueio1
 rts

umrande:                        * d0=size d1=x d2=y d3=Anzahl Zeichen
 movem.l d1-d4,-(a7)
 move d0,d4
 lsr #4,d4
 and #$f,d4
 bne.s umrande1
 moveq #16,d4                   * Vergrößerung 16
umrande1:
 mulu d4,d3                     * Anzahl Zeichen
 mulu #6,d3                     * Zeichenbreite
 addq #3,d3                     * d3=size x * anzahl * 6 + 3
 move d0,d4
 and #$f,d4
 bne.s umrande2
 moveq #16,d4                   * Vergrößerung 16
umrande2:
 asl #4,d4                      * Zeichenhöhe
 addq #8,d4                     * d5= size y * 8 * 2 + 8
 subq #2,d1                     * Anfang etwas versetzt, damit Umrandung etwas
 subq #2,d2                     * entfernt ist
 asl #1,d2
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
 bsr gr1p5                      * Rechteck leer
 move (a7)+, sr                 * Staus zurück
 movem.l (a7)+,d1-d4
 bra moveto                     * Alte Position

readaus:                        * Text einlesen mit vorheriger Ausgabe eines
 movem.l d0/d1/d3/d6/d7/a2-a4,-(a7) * beliebigen Textes
 bra.s txtein0

textein:                        * Routine zum Einlesen eines Textes
 movem.l d0/d1/d3/d6/d7/a2-a4,-(a7) * d3 = Anzahl der maximal möglichen Zeichen
 clr.b (a0)                     * Cursorsteuerung mit Ctrl-S, Ctrl-D, Ctrl-H
 subq #1,d3                     * Außerdem DEL, Ctrl-T, Ctrl-V, Ctrl-U, Ctrl-P
txtein0:                        * ESC = Ende wie RETURN aber mit Carry = 1
 move d3,d5                     * Sonst Carry = 0
 movea.l a0,a3                  * a3 = Anfangsadresse (Zeigt auf erstes Zeichen)
 movea.l a0,a2                  * a2 = Cursorposition (Zeigt auf Cursorzeichen)
txtein1:
 addq #1,d3
 tst.b (a2)+                    * Ende suchen
 bne.s txtein1
 subq.l #1,a2
 movea.l a2,a4
txtein2:
 move.b #' ',(a4)+              * Feld löschen
 dbra d5,txtein2
 clr.b (a4)                     * a4 = Endadresse (Zeigt auf Null)
 bsr textaus                    * Text und Leerzeichen ausgeben (Vorlöschen)
 bsr umrande                    * Rand ausgeben
 clr.b curon(a5)                * Keinen Cursor zeigen
 move d1,d6                     * d6 = Anfangskoordinate
 move d0,d7
 lsr #4,d7
 and #$f,d7                     * X-Vergrößerung
 bne.s txtein3
 moveq #16,d7                   * 0 ist Vergrößerung 16
txtein3:
 mulu #6,d7                     * d7 = Abstand zwischen zwei Zeichen
txtein4:                        * Schleife für Cursordarstellung
 move a2,d1
 sub a3,d1
 mulu d7,d1
 add d6,d1                      * Aktuelle Bildschirmposition des Cursors
 bsr setpen
 bsr movetoo                    * Positionieren
 move.b #10,gdp.w               * Weißer Hintergrund
 bsr erapen
 bsr movetoo
 move.b (a2),d0
 bsr cmdput                     * Invers ausgeben
 bsr txtecsts
 bcc.s txtein5                  * OK, wenn Zeichen
 moveq #1,d4
 bsr txteaus                    * Zeichen normal ausgeben
 bsr txtecsts
 bcs.s txtein4                  * Schleife, wenn kein Zeichen
txtein5:
 bsr.s txtein6                  * Zeichen auswerten
 bra.s txtein4                   * Schleife, falls nicht unten beendet

txtecsts:
 moveq #13-1,d5                 * Auf Zeichen warten
txtecst0:
 bsr csts
 bne carres                     * OK, Zeichen da
 bsr sync
 beq.s txtecst0                 * Syncronimpuls abwarten
 dbra d5,txtecst0
 bra carset                      * Kein Zeichen da

txtein6:
 bsr ci                         * Zeichen holen
 cmp.b #1,d0                    * Ctrl-A
 bne.s txtein7
 moveq #1,d4
 bsr txteaus
 movea.l a3,a2                  * Cursor nach ganz vorne
 rts
txtein7:
 cmp.b #4,d0                    * Ctrl-D
 bne.s txtein8
 tst.b 1(a2)
 beq.s txtein7a                 * Cursor schon ganz hinten, dann nicht bewegen
 moveq #1,d4
 bsr txteaus                    * Aktuelles Zeichen ausgeben
 addq.l #1,a2                   * Cursor weiter
txtein7a:
 rts
txtein8:
 cmp.b #6,d0                    * Ctrl-F
 bne.s txtein9
 moveq #1,d4
 bsr txteaus
 lea -1(a4),a0
txte8a:
 cmpa.l a2,a0                   * Nicht vor Cursor
 beq.s txte8b
 cmp.b #' ',-(a0)               * Endeleerzeichen ignorieren
 beq.s txte8a
 addq.l #1,a0                   * Auf Zeichen hinter Leerzeichen
txte8b:
 movea.l a0,a2                  * Cursor setzen
 rts
txtein9:
 cmp.b #7,d0                    * Ctrl-G
 bne.s txtein10
txtein9a:
 movea.l a2,a0                  * Cursoradresse
txtein9b:
 move.b 1(a0),(a0)+             * Zeichen übertragen
 bne.s txtein9b                 * Bis Ende
 move.b #' ',-1(a0)             * Leerzeichen ganz hinten
 moveq #-1,d4
 bra txteaus                     * Alle Zeichen ab Cursor neu ausgeben
txtein10:
 cmp.b #$7f,d0                  * DEL
 bne.s txtein11
 bsr.s txte12a                  * Ctrl-S
 bra.s txtein9a                  * Dann löschen
txtein11:
 cmp.b #16,d0                   * Ctrl-P
 bne.s txtein12
 btst.b #6, keydil(a5)          * GDP-FPGA da?
 bne.s txten11b                 * ja, dann auch user Zeichensatz
 eori.b #1, optflag(a5)
 bra.s txten11a
txten11b:
 addq.b #1,optflag(a5)          * einen Zeichensatz weiter
 cmp.b #3,optflag(a5)           * schon bei 3?
 blt.s txten11a                 * nein, dann OK
 clr.b optflag(a5)              * sonst wieder amerikanisch
txten11a:
 rts

txtein12:
 cmp.b #8,d0                    * Ctrl-H
 beq.s txte12a
 cmp.b #19,d0                   * Ctrl-S
 bne.s txtein13
txte12a:
 cmpa.l a3,a2
 beq.s txte12b                  * Cursor schon ganz vorne, dann nicht bewegen
 moveq #1,d4
 bsr txteaus                    * Ein Zeichen ausgeben
 subq.l #1,a2                   * Cursor zurück
txte12b:
 rts
txtein13:
 cmp.b #20,d0                   * Ctrl-T
 bne.s txtein14
 movea.l a2,a0                  * Cursoradresse
txte13a:
 move.b #' ',(a0)+              * Alle Zeichen hinter Cursor löschen
 cmpa.l a0,a4
 bne.s txte13a                  * Bis hinten
 moveq #-1,d4
 bra txteaus                     * Alle zeichen ab Cursor ausgeben
txtein14:
 cmp.b #21,d0                   * Ctrl-U
 bne.s txtein15
txte14a:
 movea.l a4,a0                  * Endadresse
txte14b:
 move.b -(a0),1(a0)             * Zeichen verschieben
 cmpa.l a0,a2
 bne.s txte14b                  * Bis Cursorposition
 clr.b (a4)                     * Ende wieder setzen
 move.b #' ',(a0)               * Zeichen eifügen
 moveq #-1,d4
 bra txteaus                     * Alle Zeichen ab Cursor ausgeben
txtein15:
 cmp.b #22,d0                   * Ctrl-V
 bne.s txtein16
 eori.b #$01,insl(a5)           * Einfügen an/aus
 rts
txtein16:
 cmp.b #$d,d0                   * <RETURN>
 beq.s *+8
 cmp.b #$1b,d0                  * <ESC>
 bne.s txtein17
 move.l d0,d5
 moveq #1,d4
 bsr txteaus                    * Zeichen an Cursorstelle ordentlich ausgeben
 bra.s txteinfi
txtein17:
 cmp.b #' ',d0                  * Controlzeichen ?
 bmi.s txtein19                 * Ja, dann zurück zur Abfrage
 bsr getcode                    * Zeichensatz überprüfen
 move.l d0,d5                   * Zeichen merken
 btst.b #0,insl(a5)
 beq.s txtein18                 * Kein Einfügemodus
 bsr.s txte14a                  * Erst einfügen
txtein18:
 move.b d5,(a2)                 * Zeichen ablegen
 moveq #1,d4
 bsr txteaus                    * Zeichen ausgeben
 addq.l #1,a2                   * Cursor weiter
 cmpa.l a2,a4
 beq.s txteinfi                 * Wenn ganz hinten, dann Ende
txtein19:
 rts
txteinfi:
 addq.l #4,a7                   * Stack reinigen, da kein Rücksprung
 move.l (a7),d0                 * Größe holen
 move d6,d1
 bsr erapen
 bsr umrande                    * Umrandung löschen
txtefi:
 cmpa.l a2,a4
 beq.s txtefi0                  * Endeleerzeichen bis Cursorposition ignorieren
 cmp.b #' ',-(a4)
 beq.s txtefi
 addq.l #1,a4                   * Adressausgleich
txtefi0:
 clr.b (a4)                     * Endemarkierung genau hinter letztes Zeichen
 cmp.b #$d,d5
 beq.s txtefi1
 cmp.b #$1b,d5
 beq.s txtefi1
 move.b -1(a4),d5               * Wenn nicht mit <RETURN> oder <ESC> beendet,
txtefi1:                        * dann enthält d5 letztes Zeichen
 movea.l a4,a0
 suba.l a3,a4
 move.l a4,d4                   * Anzahl der Zeichen im Buffer
 bsr setpen                     * Wieder auf Schreiben
 movem.l (a7)+,d0/d1/d3/d6/d7/a2-a4
 cmp.b #$1b,d5
 beq carset                     * Ende mit <ESC>, dann Carry =1
 bra carres

txteaus:                        * Ausgabe für textein d0/d1/d4/a0 zerstört
 movea.l a2,a0                  * a2 = Aktuelle Adresse
 move a2,d1                     * a3 = Anfangsadresse Text
 sub a3,d1                      * d4 = Maximale Anzahl auszugebender Zeichen
 mulu d7,d1                     * d7 = Abstand zwischen zwei Zeichen
 add d6,d1                      * d6 = Anfangsposition X
 bra.s txteaus2                 * d2 = Y-Postion
txteaus1:
 bsr erapen                     * Vorlöschen
 bsr movetoo                    * Positionieren
 move.b #10,gdp.w               * Löschzeichen
 bsr setpen                     * Setzen
 bsr movetoo                    * Positionieren
 bsr cmdput                     * Zeichen ausgeben
 add d7,d1                      * Neue Position
txteaus2:
 move.b (a0)+,d0                * Nächstes Zeichen
 dbeq d4,txteaus1                * Wenn Null, oder d3 =-1, dann Ende
 rts

printv8d:                       * 32 Bit dezimal ausgeben
 tst.l d0                       * a0 -> Ziel d0.l Wert
 bpl.s print8d                  * Ausgabe dezimal mit Vorzeichen
 neg.l d0                       * d0.l zerstört
 move.b #'-',(a0)+
print8d:                        * Ausgabe ohne Vorzeichen
 movem.l d1/d2,-(a7)
 clr.b -(a7)                    * Ende-Zeichen
prt8d2:
 moveq #0,d1
 moveq #32-1,d2                 * 32 Bit
prt8d3:
 asl.l #1,d0
 roxl.l #1,d1
 cmp #10,d1                     * Bis 10 aufspeichern
 bcs.s prt8d4
 sub #10,d1
 addq #1,d0
prt8d4:
 dbra d2,prt8d3
 add.b #'0',d1                  * Als ASCII-Zeichen abspeichern
 move.b d1,-(a7)
 tst.l d0
 bne.s prt8d2                    * Bis alle Ziffern fertig
prt8d5:
 move.b (a7)+,(a0)+             * In (a0)+ ablegen, da verkehrt im Stack
 bne.s prt8d5
 subq.l #1,a0                   * a0 zeigt auf Null
 movem.l (a7)+,d1/d2
 rts

print4d:
 clr.b -(a7)                    * Ausgabe d0.w 4 Stellen dezimal
 swap d0                        * Ausgabe ohne Vorzeichen
 clr d0                         * a0 -> Ziel
 swap d0                        * d0 zerstört
print4d1:
 divu #10,d0                    * Durch 10 teilen
 swap d0                        * Rest holen
 add.b #'0',d0                  * In ASCII-Zeichen wandeln
 move.b d0,-(a7)                * Abspeichern
 clr d0                         * REST löschen
 swap d0                        * Bis d0=Null
 bne.s print4d1
print4d2:
 move.b (a7)+,(a0)+             * In (a0)+ ablegen, da verkehrt im Stack
 bne.s print4d2
 subq.l #1,a0                   * a0 zeigt auf Null
 rts

print16b:                       * 16 Stellen binär für Trace
 move.l d1,-(a7)
 moveq #16-1,d1
 bra.s prt8b0

print8b:
 move.l d1,-(a7)                * Ein Byte binär ausgeben
 moveq #8-1,d1                  * a0 -> Ziel
prt8b0:
 btst d1,d0                     * Bit 7, dann Bit 6, usw. abfragen
 seq (a0)                       * 0 oder -1
 add.b #'1',(a0)+               * In ASCII wandeln
 dbra d1,prt8b0
prt8b2:
 clr.b (a0)                     * Endekennung
 move.l (a7)+,d1
 rts                             * Ende

print8x:
 move.l d1,-(a7)                * 8 Stellen Hexadezimal ausgeben
 moveq #8-1,d1                  * a0 -> Ziel
 bra.s print1x                   * d0 zerstört
print6x:                        * 6 Stellen
 move.l d1,-(a7)
 moveq #6-1,d1
 rol.l #8,d0
 bra.s print1x
print4x:                        * 4 Stellen
 move.l d1,-(a7)
 moveq #4-1,d1
 swap d0
 bra.s print1x
print2x:                        * 2 Stellen
 move.l d1,-(a7)
 moveq #2-1,d1
 ror.l #8,d0
print1x:                        * d1 = Anzahl Stellen-1
 swap d1                        * d1 retten
 rol.l #4,d0
 move d0,d1
 and.w #$f,d1
 move.b prttab(pc,d1.w),(a0)+   * Aus der Tabelle Wert holen
 swap d1                        * d1 zurück
 dbra d1,print1x
 clr.b (a0)                     * Endekennung
 move.l (a7)+,d1
 rts

prttab:                         * Tabelle für hexadezimale Ausgabe
 DC.b '0123456789ABCDEF'

uhrprint:
 clr.b (a0)                     * Endekennung, wenn keine Uhr vorhanden
 tst.b uhrausw(a5)
 beq carset                     * Carry = 1, da keine Uhr
 move.l a0,-(a7)
 lea einbuf(a5),a0
 bsr getuhr                     * Uhrzeit holen
 movea.l (a7)+,a0
uhrprt0:                        * Einsprung, wenn Uhrzeit schon gelesen
 movem.l d0-d3/a1/a2,-(a7)
 move.b einbuf+5(a5),d1
 and #7,d1                      * Nur 1 bis 7
 move.b uhrtab0(pc,d1),d1
 lea uhrtab0(pc,d1),a1          * Adresse des Tages
uhrprt1:
 move.b (a1)+,(a0)+
 dbeq d0,uhrprt1                 * Anzahl Buchstaben übertragen oder bis Ende
 subq.l #1,a0
 lea uhrtab1(pc),a1
 lea einbuf(a5),a2              * Zeiger auf Uhrdaten
 moveq #'.',d3                  * Trennzeichen für Datum
 moveq #2-1,d1
uhrprt2:
 move.b #' ',(a0)+              * Leeraum
 move.b #' ',(a0)+
 moveq #3-1,d2
uhrprt3:
 clr d0
 move.b (a1)+,d0                * Zeiger holen
 move.b 0(a2,d0),d0             * Wert holen
 bsr print2x                    * Umwandeln
 move.b d3,(a0)+                * Trennzeichen ablegen
 dbra d2,uhrprt3
 clr.b -(a0)                    * Endekennung
 moveq #':',d3                  * Trennzeichen für Uhrzeit
 dbra d1,uhrprt2
 movem.l (a7)+,d0-d3/a1/a2
 bra carres                      * OK, Uhrzeit geholt

uhrtab0:
 DC.b 8,8,15,24,33,44,52,60

 DC.b 'Montag',0
 DC.b 'Dienstag',0
 DC.b 'Mittwoch',0
 DC.b 'Donnerstag',0
 DC.b 'Freitag',0
 DC.b 'Samstag',0
 DC.b 'Sonntag',0

uhrtab1:                        * Zeiger auf Bytes zur Ordnung der Uhrdaten
 DC.b 2,3,4,0,1,6

 ds 0

*******************************************************************************
*                         680xx Grundprogramm symbol                          *
*                         (C) 1989 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                          Symboltabellenverwaltung                           *
*******************************************************************************


* Symboltabellenverwaltung
* Es können bis 64 Kbyte verwaltet werden
* Sie muß auf einer Wortgrenze beginnen
* a1 ist der globale Zeiger auf den Start der Tabelle
*
* Record
*  symtab :
*         kleiner.w   : Zeiger auf Record der kleiner ist
*         groesser.w  : Zeiger auf Record der größer ist
*         datenwert.l : Daten
*         attribut.w  : Attribut des Datenwertes
*         name 64 Bit : Name in ASCII mit 8 Zeichen mit Leerzeichen am Ende,
*                       wenn weniger als 8 Zeichen
* groesser=kleiner = 0 dann NIL

kleiner EQU 0
groesser EQU 2
datenwert EQU 4
attribut EQU 8
name EQU 10

symlen EQU 18

namecheck:                      * Überprüfung ob Name
 cmp.b #'0',d0
 bcs carset                   * Nein
 cmp.b #'9'+1,d0
 bcs carres                   * Ja
bucheck:                        * Überprüfung ob Buchstabe
 tst.b d0                       * Sonderzeichen auch testen
 bmi.s bucheck1
 cmp.b #'_',d0
 beq carres                   * Ja
 cmp.b #'A',d0
 bcs carset                   * Nein
 cmp.b #'Z'+1,d0
 bcs carres                   * Ja
 cmp.b #'a',d0
 bcs carset                   * Nein
 cmp.b #'z'+1,d0
 bcc carset                   * Nein
 add.b #'A'-'a',d0              * Ja, und gleich in Großbuchstaben gewandelt
 bra carres
bucheck1:                       * Auch Sonderzeichen
 cmp.b #'ß',d0
 beq carres                   * ß ist Extracode
 movem.l d1/a0,-(a7)
 lea ztab0(pc),a0
 moveq #anztab-2-1-1,d1         * ß ist schon getestet, deshalb noch -1
bucheck2:
 cmp.b (a0)+,d0                 * Vergleich
 beq.s bucheck3                 * OK, gefunden
 dbra d1,bucheck2
 movem.l (a7)+,d1/a0
 bra carset                    * Fehler, nicht dabei
bucheck3:
 and.b #$df,d0                  * OK, gefunden und in Großbuchstaben gewandelt
 movem.l (a7)+,d1/a0
 bra carres                    * OK

setigname:                      * Wie setupname, Leerzeichen werden ignoriert
 bsr igbn

setupname:                      * Name in Register d2,d3
                                * Aufbereiten von a0 an
                                * a0 zeigt auf das Ende des Namens
                                * Carry, wenn Fehler kein gültiger Namenswert
 move.b (a0),d0                 * A..Z erlaubt an erster Stelle
 bsr.s bucheck
 bcs carset                   * Nicht OK
 lea nametab+8(a5),a2           * Zwischenspeicher
 move.l #'    ',-(a2)
 move.l #'    ',-(a2)           * gelöscht
 moveq #8-1,d1                  * Maximal 8 Zeichen
setu1:
 move.b d0,(a2)+                * Zeichen ablegen
 addq.l #1,a0                   * Neues Zeichen
 move.b (a0),d0
 bsr namecheck                  * Prüfen
 bcs.s setu3                    * Ende Name
 dbra d1,setu1                   * Bis Maximal erreicht
setu2:
 addq.l #1,a0                   * Weiter, da OK
 move.b (a0),d0                 * Weiter abfragen
 bsr namecheck
 bcc.s setu2                    * Bis Ende erreicht
setu3:                          * Fertig a0 zeigt auf nächstes Zeichen
 move.l nametab(a5),d2
 move.l nametab+4(a5),d3
 bra carres                      * Ohne Carry

getval:                         * Holt Wert aus der Symboltabelle
 lea symtab(a5),a1              * a0 = Name start
                                * Nachher d0.l = Wert   d1.w = Attribut
                                * Carry wenn Fehler
                                * d2 = Kennung
                                * 0 = gefunden 1 = Wenn kleiner Teil nil
                                * 2 = wenn groesser Teil nil
                                * a3 Pointer auf Record

sucheeintrag:                   * Ergebnis d2.l
                                * Hauptprogramm Basis und erster Suchteil
                                * a0 zeigt auf fraglichen Text
                                * a1 zeigt auf Symboltabellenstart
                                * Basis fest
                                * Carry wenn Fehler
                                * d2 = 1 nicht gefunden / Name kleiner
                                * d2 = 2 nicht gefunden / Name groesser
                                * Sonst d0.l = Datenwert  d1.w = Attribut
                                * a3 zeigt auf Record nach der Ausführung
 bsr.s setupname                * Carry dann Fehler
 bcs carset                     * Stoppen, Name ungültig
suchein:
 moveq #0,d0
suche:                          * Namen nur einmal festlegen
 lea 0(a1,d0.l),a3
 cmp.l name(a3),d2
 bmi.s suchklei                 * Kleiner Teil suchen
 bhi.s suchgroe                 * Groesser
 cmp.l name+4(a3),d3
 bmi.s suchklei
 bhi.s suchgroe                 * Nun muß gleich sein
 move.l datenwert(a3),d0        * Langwort
 move attribut(a3),d1           * Nur Wort
 moveq #0,d2
 bra carres                      * OK Symbol in Ordnung

suchklei:
 move (a3),d0                   * Eigentlich kleiner(a3) aber kleiner=0
 bne.s suche                    * Weiter suchen
 moveq #1,d2
 bra carres                      * Nicht gefunden

suchgroe:
 move groesser(a3),d0
 bne.s suche                    * Weiter suchen
 moveq #2,d2                    * Nicht gefunden
 bra carres

setval:                         * Setzt Parameter neu wie getval
 lea symtab(a5),a1              * Name noch nicht da

ueberschreibe:                  * Eintragen von Datenwerten wenn ein Name schon
 movem.l d0/d1,-(a7)            * da ist a0=Name a1=Symboltabelle d0.l=Datenwert
 bsr.s sucheeintrag             * d1.w=Attribut
 movem.l (a7)+,d0/d1
 bcs carset                     * Fehler, da Name falsch
 tst d2                         * =0 dann gefunden
 bne carset                     * Sonst Eintrag nicht möglich
 move.l d0,datenwert(a3)        * Langwort
 move d1,attribut(a3)           * Wort
 bra carres

                                * Achtung Rev 6.0 geändert
newval:                         * trägt Symbol neu ein Paramter wie setval
 lea symtab(a5),a1              * allerdings muß Name in d2/d3 vorhanden sein

eintrage:                       * Rev 6.0 a3 wird zestört
                                * Eintragen eines Namens wenn er nicht existiert
                                * a0 zeigt auf Namen a1 auf Symboltabelle
                                * d3 gibt freien Platz an wird erneuert
 movem.l d0/d1,-(a7)
 bsr.s suchein
 movem.l (a7)+,d0/d1
 tst d2                         * =0 dann war schon da
 beq carset
eint0:
 cmp #1,d2                      * Kleiner
 bne.s eint1
 move symnext(a5),d2            * Langwort gültig, da d2.l = 1
 move d2,(a3)                   * Eigentlich kleiner(a3) aber kleiner=0
 bra.s eint2                    * OK, abgespeichert
eint1:
 cmp #2,d2
 bne carset                     * Fatal Fehler
 move symnext(a5),d2            * Langwort gültig, da d2.l = 2
 move d2,groesser(a3)           * Zeiger auf Eintrag
eint2:
 lea 0(a1,d2.l),a3              * Berechnung Adresse absolut bis 64 Kilobyte
 clr.l (a3)+                    * Schnellere Adressierung
 move.l d0,(a3)+
 move d1,(a3)+                  * a3 zerstört aber schneller
 move.l nametab(a5),(a3)+
 move.l nametab+4(a5),(a3)+
 add #symlen,symnext(a5)        * Neuer Zeiger auf Ende Symboltabelle
 bra carres                      * OK alles abgespeichert

symloesche:                     * Symboltabelle löschen
 clr symnext(a5)
 lea symtab+18(a5),a0
 clr.l -(a0)
 clr.l -(a0)
 clr.l -(a0)
 clr.l -(a0)
 clr -(a0)
 rts

symbolaus:                      * Symboltabelle ausgeben
 movem.l d0-d3/a0-a2/a6,-(a7)
 move.b cotempo(a5),-(a7)       * Geschindigkeit merken
 move #2,passflag(a5)           * Auf jeden Fall ausgeben
 bsr clrscreen                  * Bildschirm vorher löschen
 moveq #'1',d0                  * Scroll-Geschwindigkeit einstellen
 bsr esc8                       * Immer Hardware-Scroll, wenn möglich
 bsr.s p_rtsymb
 moveq #'0',d0
 bsr esc7                       * Software-Scroll an danach
 move.b (a7)+,cotempo(a5)       * Alte Geschwindigkeit
 bsr finmenue                   * Ende
 movem.l (a7)+,d0-d3/a0-a2/a6
 rts

gettrap:                        * Trap-Nummer holen
 move.l d1,-(a7)
 bsr setupname                  * Name in Ordnung bringen
 movem.l (a7)+,d1
 bcs carset                     * Fehler
 lea trapsym(pc),a1             * Dort stehen Adressen
 moveq #0,d0                    * Nummer des Traps
gettr1:
 addq.l #1,d0                   * Nummer erhöhen
 tst.l (a1)                     * Null ist Ende Tabelle
 beq carset
 cmp.l (a1)+,d2                 * Name erster Teil
 bne.s gettr2
 cmp.l (a1)+,d3                 * Name zweiter Teil
 bne.s gettr1
 move.l d0,d2                   * Name ist verglichen und OK
 add.l d0,d0                    * d2 ist Trap-Nummer
 add.l d0,d0                    * Adresse holen
 lea traptab-4(pc),a1
 move.l 0(a1,d0.l),d0           * Adresse der Routine
 lea basis(pc),a1
 add.l a1,d0                    * Basis berücksichtigen
 bra carres

gettr2:                         * a1 um 4 erhöhen für nächsten Wert
 addq.l #4,a1
 bra.s gettr1

p_rtsymb:                        * Abbruch mit CTRL C
 lea symtab(a5),a1              * Tabelle maximal 64 Kbyte
 movea.l a7,a6                  * Stackmerker bei Abbruch
 moveq #0,d3
p_rtsymb1:
 tst kleiner(a1,d3.l)           * Hier kleinsten Wert suchen
 beq.s p_rtsymb2                 * Gefunden
 move d3,-(a7)                  * Weiter suchen
 move kleiner(a1,d3.l),d3       * Rekursiv aufrufen
 bsr.s p_rtsymb1                 * Hier
 move (a7)+,d3                  * d3 zurück
p_rtsymb2:
 movem.l d3/a1,-(a7)
 lea ausbuf(a5),a0              * Symbol und Werte ausgeben
 move.l name(a1,d3.l),(a0)+
 move.l name+4(a1,d3.l),(a0)+   * Namen ablegen
 move #'  ',(a0)+
 move.l datenwert(a1,d3.l),d0   * Dann Datenwert
 bsr print8x                    * Hexadezimal
 move #'  ',(a0)+
 move attribut(a1,d3.l),d0      * Attribut auch
 move d0,d1
 bsr print4x                    * Auch hexadezimal
 move.l #'    ',(a0)+
 cmp #6,d1                      * Attribut entschlüsseln / Wenn größer als 6
 bmi.s p_rtsymb3                 * Dann nur Striche ausgeben, da unbekannt
 moveq #6,d1
p_rtsymb3:
 move.b symatxt(pc,d1),d1       * Anfangswert Text
 lea symatxt(pc,d1),a2          * Adresse Text berechnet
p_rtsymb4:
 move.b (a2)+,(a0)+             * Text in Buffer übertragen
 bne.s p_rtsymb4
 lea ausbuf(a5),a0              * Text
 bsr prtco2                     * ausgeben
 bsr crlfe                      * Danach CR LF ausführen
 movem.l (a7)+,d3/a1
 bsr co2test                    * Abbruch abfragen
 bcs.s p_rtsymb6
 tst groesser(a1,d3.l)          * Jetzt nächsten Wert suchen
 beq.s p_rtsymb5
 move d3,-(a7)
 move groesser(a1,d3.l),d3
 bsr p_rtsymb1                   * Wieder rekursiv
 move (a7)+,d3
p_rtsymb5:
 rts
p_rtsymb6:
 movea.l a6,a7                  * a6 war Merker Stack für Abbruch
 rts

symatxt:
 DC.b 7,14,19,24,33,39,51       * Byte innerhalb der Tabelle für Textberechnung
 DC.b 'FEHLER',0
 DC.b 'BYTE',0
 DC.b 'WORT',0
 DC.b 'LANGWORT',0
 DC.b 'GETEA',0
 DC.b 'UNDEFINIERT',0
 DC.b '-----------',0

 DS.W 0



****************** Hilflabels, wenn für direkte Sprünge zu weit ***************

gr1p5_: bra gr1p5

*******************************************************************************
*                          680xx Grundprogramm wert                           *
*                         (C) 1989 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                             Wert-Berechnung                                 *
*******************************************************************************


zuweis:                 * Trägt ein Symbol in die Symboltabelle ein
 move.l a0,-(a7)        * a0 zeigt auf Text
 bsr setigname          * Carry wenn nicht OK
 bcs.s zuwf             * Fehler, dann Ende
 bsr.s igbn             * Leerzeichen ignorieren
 cmp.b #':',(a0)+       * Check ob :=
 bne.s zuwf             * Wenn nicht, dann Fehler
 cmp.b #'=',(a0)+
 bne.s zuwf
 movem.l d2/d3,-(a7)    * Namen retten
 bsr.s wert             * Wert holen
 movem.l (a7)+,d2/d3
 bcs.s zuwf             * Abbruch bei Fehler
 addq.l #4,a7           * a0 auf Stack nicht mehr wichtig
 movem.l d2/d3,nametab(a5)  * Namenstabelle wieder herstellen
 bsr newval             * Neues Symbol ?
 bcc.s zuw1             * OK, Wert eingetragen
 move.l d0,datenwert(a3) * War schon da einfach setzen
 move d1,attribut(a3)
zuw1:
 bra carres              * OK, zugewiesen
zuwf:
 movea.l (a7)+,a0
 bra carset              * Fehler

igbn:                   * Leerzeichen ignorieren
 cmp.b #' ',(a0)+
 beq.s igbn
 subq.l #1,a0
 rts

wertmfeh:                       * Wert mit Fehlertest und ohne zerstörte
 movem.l d2/d3/a1-a3,-(a7)      * Register außer d1
 bsr.s wert                     * Wert berechnen
 movem.l (a7)+,d2/d3/a1-a3
 bcs carset                     * Fehler
 cmp #5,d1
 beq carset                     * Undefiniertes Symbol ist auch Fehler
 bra carres

wert:
 bsr.s igbn                     * Leerzeichen nicht beachten
 bsr.s expr                     * Expression holen
 tst d1                         * Rev 6.0 d1.w
 beq carset                     * Syntaxfehler
 cmp #5,d1                      * Bei undefiniertem Symbol carres
 beq carres
 cmp.b #'.',(a0)                * Größenangabe ?
 bne.s werta                    * Nein, dann weiter
 addq.l #1,a0                   * Sonst auswerten
 move.b (a0)+,d1
 and.b #$df,d1                  * Großbuchstabe
 cmp.b #'L',d1                  * Langwort
 beq.s wertlo
 cmp.b #'W',d1                  * Wort
 beq.s wertwo
 cmp.b #'B',d1                  * Byte
 beq.s wertby
 subq.l #2,a0                   * Wieder auf '.'
werta:
 swap d0                        * Eingang wenn nicht .B .W .L
 tst d0                         * =0 dann Wort oder Byte
 beq.s wertb
 swap d0
wertlo:                         * Langwort
 moveq #3,d1
 bra.s wertend

wertb:
 swap d0
 move d0,d1
 and #$ff00,d1                  * =0 dann Byte
 beq.s wertby
wertwo:                         * Wort
 moveq #2,d1
 bra.s wertend
wertby:                         * Byte
 moveq #1,d1

wertend:
 tst.b (a0)                     * Endekennung mit Null ?
 beq carres                     * Ja, dann weiter
 cmp.b #' ',(a0)                * Oder mit Leerzeichen
 beq carres
 moveq #0,d1                    * Sonst Syntaxfehler
 bra carset                      * Und carry

expr:                           * Expression auswerten
 moveq #3,d1                    * Bisher kein Fehler
exprin:
 bsr.s term                     * Term auswerten
exprwh:
 cmp.b #'+',(a0)                * Addition
 beq.s expradd
 cmp.b #'-',(a0)                * Subtraktion
 beq.s exprsub
 cmp.b #'!',(a0)                * Oder-Verknüpfung
 beq.s expror
 rts

expradd:                        * Addition
 addq.l #1,a0
 move.l d0,-(a7)
 bsr.s term                     * Wert holen
 add.l (a7)+,d0                 * Alten Wert addieren
 bra.s exprwh

exprsub:                        * Subtraktion
 addq.l #1,a0                   * Nächstes Zeichen
 move.l d0,-(a7)
 bsr.s term                     * Wert holen
 neg.l d0                       * Negieren
 add.l (a7)+,d0                 * Alten Wert addieren
 bra.s exprwh

expror:                         * Oder-Verknüpfung
 addq.l #1,a0                   * Nächstes Zeichen
 move.l d0,-(a7)
 bsr.s term                     * Wert holen
 or.l (a7)+,d0                  * ODER-Verknüpfung
 bra.s exprwh

term:                           * Term berechnen
 bsr.s faktor                   * Faktor berechnen
termwh:
 cmp.b #'*',(a0)                * Multiplikation
 beq.s termmul
 cmp.b #'/',(a0)                * Division
 beq.s termdiv
 cmp.b #'\',(a0)                * Modulo
 beq.s termmod
 cmp.b #'&',(a0)                * UND-Verknüpfung
 beq.s termand
 rts

termmul:                        * Multiplikation
 addq.l #1,a0
 move.l d0,-(a7)
 bsr.s faktor                   * Wert holen
 move.l (a7)+,d2
 move.l d1,-(a7)
 bsr muls32                     * Multiplizieren
 move.l (a7)+,d1
 bra.s termwh

termdiv:                        * Division
 addq.l #1,a0
 move.l d0,-(a7)
 bsr.s faktor                   * Wert holen
 move.l (a7)+,d2
 tst.l d0                       * Durch Null, dann Unendlich als Ergebnis
 beq.s term1div
 exg d0,d2                      * Austauschen für Division
 move.l d1,-(a7)
 bsr divs32                     * Dividieren
 move.l (a7)+,d1
 bra.s termwh
term1div:
 move.l #$7fffffff,d0           * Unendlich, da Division durch Null
 bra.s termwh

termmod:                        * Modulo
 addq.l #1,a0
 move.l d0,-(a7)
 bsr.s faktor                   * Wert holen
 move.l (a7)+,d2
 tst.l d0                       * Soll durch Null geteilt werden ?
 beq.s term1div                 * Dann Unendlich als Ergebnis
 exg d0,d2                      * Austauschen
 move.l d1,-(a7)
 bsr divs32                     * Division durchführen
 move.l d1,d0                   * Aber Rest nehmen
 move.l (a7)+,d1
 bra.s termwh

termand:                        * UND-Verknüpfung
 addq.l #1,a0
 move.l d0,-(a7)
 bsr.s faktor                   * Wert holen
 and.l (a7)+,d0                 * Verknüpfen
 bra.s termwh

faktor:                         * Faktor berechnen
 cmp.b #$27,(a0)                * Wenn ' -Zeichen, dann ASCII-Folge
 bne.s fakto11
 addq.l #1,a0
 moveq #0,d0                    * d0 löschen fürs Aufaddieren
fakto12:                        * Auch ''' erlaubt
 cmp.b #$27,(a0)                * ' - Zeichen, dann Extratest
 bne.s fakto13
 cmp.b #$27,1(a0)               * Wenn '', dann ' übernehmen
 bne.s fakto14                  * Wenn ' dann Ende
fakto13:
 cmp.b #' ',(a0)                * Wenn Ctrl-Zeichen, dann Abbruch
 bcs.s fakto15
 rol.l #8,d0                    * Sonst Zeichen übernehmen
 move.b (a0)+,d0                * Nach d0
 bra.s fakto12                   * Nächstes Zeichen testen

fakto14:
 addq.l #1,a0
fakto15:                        * Fehlerbehandlung
 cmp #5,d1                      * Bei undefinert, so lassen
 beq carres
 moveq #3,d1                    * Sonst Long annehmen
 rts

fakto11:                        * Programmstand beim Assembler
 cmp.b #'*',(a0)
 bne.s faktok1
 move.l anfstand(a5),d0         * Zeilenanfangsadresse
 bra.s fakto14

faktok1:                        * Textanfangsadresse
 cmp.b #'?',(a0)
 bne.s fakto1
 move.l stxtxt(a5),d0           * Anfangsadresse Editor
 bra.s fakto14

fakto1:                         * A..Z zugelassen
 move.b (a0),d0                 * 0..nn sind Zahlen
 bsr bucheck                    * Nur A..Z und a..z als Namensanfang zugelassen
 bcs.s fakt10
 cmp #5,d1                      * Wenn undefiniert, dann lassen
 beq.s faktoo1
 bsr getval                     * a0 zeigt dann hinter Namen
 tst d2                         * =0 dann Name gefunden
 bne.s fakt101
 rts

faktoo1:
 bsr getval                     * Symbol holen
 tst d2
 bne.s fakt101                  * Nicht gefunden, dann weiter
 moveq #5,d1                    * Da vorher undefiniert so lassen
 rts

fakt101:                        * Name nicht eingetragen
 moveq #0,d0                    * Wert ist Null
 moveq #5,d1                    * Attribut=5 Referenz ohne Definition
 bra eint0                       * Symbol nur setzen

fakt10:                         * Kein Name
 cmp.b #'(',(a0)
 bne.s fakt1
 addq.l #1,a0
 bsr exprin                     * Rekursiv
 cmp.b #')',(a0)                * Muß schließen, sonst Fehler
 bne.s fakerr
 addq.l #1,a0                   * a0 ein Zeichen weiter
 rts

fakt1:
 cmp.b #'~',(a0)                * Nicht-Operation
 bne.s faktoa11
 addq.l #1,a0
 bsr faktor                     * Wert holen
 not.l d0
 rts

faktoa11:
 cmp.b #'-',(a0)                * Vorzeichen
 bne.s fakt2
 addq.l #1,a0
 bsr faktor                     * Rekursiv
 neg.l d0                       * Vorzeichen ändern
 rts

fakt2:
 cmp.b #'$',(a0)                * Hexadezimalwert
 bne.s fakt3
 addq.l #1,a0
 move.b (a0),d2                 * $xxxx muß sedezimal sein
 bsr sedcheck
 bcs.s fakerr                   * Fehler
 moveq #0,d0
fakt32:
 addq.l #1,a0                   * Nächstes Zeichen
 asl.l #4,d0                    * Mal 16
 add.b d2,d0                    * Aufaddieren
 move.b (a0),d2                 * Nächstes Zeichen
 bsr sedcheck
 bcc.s fakt32                   * So lange bis nicht mehr sedezimal
 bra fakto15

fakerr:
 moveq #0,d0                    * Fehler im Wert, deshalb Null
 moveq #0,d1                    * Syntaxfehler
 rts

fakt3:
 cmp.b #'%',(a0)
 bne.s fakt3a                   * Binäre Eingabe
 addq.l #1,a0
 move.b (a0),d2                 * Wert holen
 sub.b #'0',d2
 cmp.b #1,d2
 bhi.s fakerr                   * Fehler, wenn nicht 0/1
 moveq #0,d0                    * Ergebnis
fakt310:
 asl.l #1,d0                    * d0*2
 add.b d2,d0                    * Wert addieren
 addq.l #1,a0
 move.b (a0),d2                 * Nächstes Zeichen
 sub.b #'0',d2
 cmp.b #1,d2
 bls.s fakt310                  * Fehler, wenn nicht 0/1
 bra fakto15                     * Ende Binärdaten

fakt3a:
 cmp.b #'@',(a0)                * Symbol aus Traptabelle
 bne.s fakt3b                   * Adresse von Trapsymbol
 addq.l #1,a0
 bsr gettrap                    * a0-> Ende d0=Wertadresse d2=Index
 bcc fakto15

fakundef:
 moveq #5,d1                    * Undefiniertes Symbol
 rts

fakt3b:
 cmp.b #'!',(a0)
 bne.s fakt3c                   * Index von Trapsymbol
 addq.l #1,a0
 bsr gettrap
 bcs.s fakundef
 move.l d2,d0                   * Jetzt #!Name richtig
 bra fakto15

fakt3c:
 moveq #0,d2                    * Jetzt kann nur Dezimalzahl folgen
 move.b (a0),d2
 bsr dezcheck                   * Check ob dezimal
 bcs.s fakerr                   * Nein, dann Fehler
 moveq #0,d0                    * Ergebnis = 0 setzen
fakt21:
 move.l d0,d3
 add.l d0,d0
 add.l d0,d0
 add.l d3,d0
 add.l d0,d0                    * d0.l * 10
 add.l d2,d0
 addq.l #1,a0
 move.b (a0),d2                 * Nächstes Zeichen
 bsr dezcheck
 bcc.s fakt21                   * Wiederholen bis keine Zahl mehr
 bra fakto15

muls32:                         * Multiplikation 32 Bit
 movem.l d2-d5,-(a7)            * d0.l * d2.l -> d1.l, d0.l Ergebnis
 moveq #0,d5                    * Vorzeichenmerker
 tst.l d0                       * d0 positiv ?
 bpl.s muls32a                  * Ja, dann OK
 neg.l d0                       * Sonst negieren
 not.w d5                       * Vorzeichen ist negativ
muls32a:
 tst.l d2                       * d2 positiv ?
 bpl.s muls32b                  * Ja, dann OK
 neg.l d2                       * Sonst negieren
 not.w d5                       * Vorzeichen umdrehen
muls32b:                        * Neue Berechnungs-Routine
 move.l d0,d1                   * Teilt d0 und d2 jeweils in zwei 16 Bit Zahlen
 swap d1                        * auf, die dann getrennt multipliziert werden
 move.l d2,d3                   * Diese werden dann addiert und in d1 und d0
 swap d3                        * abgespeichert. Das Ergebnis liegt in d0
 move.l d2,d4                   * In d1 ist der vorzeichenbehaftete Überlauf
 mulu d1,d2                     * a2*b1 = m1   (Mittlere Zahl, Teil 1)
 mulu d3,d1                     * b2*a2 = u    (Obere Zahl)
 mulu d0,d3                     * a1*b2 = m2   (Mittlere Zahl, Teil 2)
 mulu d4,d0                     * b1*a1 = l    (Untere Zahl)
 add.l d3,d2                    * (a1*b2)+(a2*b1) = m   (Mittlere Zahl)
 move.l d2,d3
 swap d2
 clr d2                         * ml  (Unterer Teil Mittlere Zahl)
 clr d3
 swap d3                        * mu  ( Oberer Teil Mittlere Zahl)
 add.l d2,d0                    * ml+l (d0 fertig Untere 32 Bit der 64 Bit Zahl)
 addx.l d3,d1                   * mu+u (d1 fertig Obere 32 Bit der 64 Bit Zahl)
 tst d5                         * Vorzeichentest
 beq.s muls32c                  * Null, also positiv
 neg.l d0                       * Nicht Null, also Vorzeichen umdrehen
 negx.l d1                      * Auch Vorzeichen von d1
muls32c:
 movem.l (a7)+,d2-d5
 rts

divs32:                         * 32 Bit Division
 movem.l d2-d4,-(a7)            * d0.l / d2.l ->  d0.l Ergebnis, d1.l Rest
                                * Vorzeichen Rest wie Vorzeichen d0 vorher
 moveq #0,d4                    * Vorzeichenmerker
 tst.l d0                       * d0 positiv ?
 bpl.s divs32a
 neg.l d0                       * Nein, dann negieren
 not.l d4                       * Vorzeichen umdrehen
divs32a:
 tst.l d2                       * d2 positiv ?
 bpl.s divs32b
 neg.l d2                       * Nein, dann negieren
 not.w d4                       * Vorzeichen umdrehen
divs32b:
 moveq #0,d1                    * Überlauf ist Null
 moveq #32-1,d3
divs32c:
 asl.l #1,d0                    * 1 Bit von d0
 roxl.l #1,d1                   * nach d1 übernehmen
 cmp.l d2,d1
 bcs.s divs32d                  * So lange bis Wert erreicht
 sub.l d2,d1                    * Subtrahieren
 addq #1,d0                     * Ergebnis + 1
divs32d:
 dbra d3,divs32c                 * Weiter, bis alle Bit übertragen
 tst d4                         * Vorzeichen positiv ?
 bpl.s divs32e
 neg.l d0                       * Nein, dann Ergebnis negieren
divs32e:                        * d1 ist Rest
 tst.l d4
 bpl.s divs32f
 neg.l d1
divs32f:
 movem.l (a7)+,d2-d4
 rts

dezcheck:                       * Test, ob Zahl zwischen
 cmp.b #'0',d2                  * Null
 bcs.s carset
 cmp.b #'9'+1,d2                * und Neun liegt
 bcc.s carset
 sub.b #'0',d2                  * Aus ASCII-Zeichen wird Zahl
 bra.s carres

sedcheck:                       * Wert ASCII in d2
 cmp.b #'0',d2                  * Carry wenn Fehler sonst Zahl
 bcs.s carset
 cmp.b #'9'+1,d2
 bcc.s sed1
 sub.b #'0',d2                  * Aus ASCII-Zeichen wird Hexadezimalwert
 bra.s carres

sed1:
 cmp.b #'A',d2
 bcs.s carset
 cmp.b #'F'+1,d2
 bcc.s sed2
 sub.b #'A'-10,d2               * Hier zwischen A und F / Jetzt Zahl
 bra.s carres                    * OK

sed2:
 cmp.b #'a',d2                  * Auch kleine Buchstaben
 bcs.s carset
 cmp.b #'f'+1,d2
 bcc.s carset
 sub.b #'a'-10,d2               * Ebenfalls Zahl

carres:                         * Carry-Flag auf 0 setzen
 and #$fe,ccr
 rts

carset:                         * Carry-Flag auf 1 setzen
 or #1,ccr
 rts
*******************************************************************************
*                        680xx Grundprogramm floppy                           *
*                        (C) 1990 Ralph Dombrowski                            *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                            Floppy-Routinen                                  *
*******************************************************************************


flinit:
 movem.l d0/a0,-(a7)
 move.b #$80,steprate(a5)       * Steprate auf den schnellsten Wert
 st drvat(a5)                   * Kein altes Laufwerk gültig
 lea drvtab(a5),a0              * Spurtabelle der Laufwerke
 moveq #16-1,d0
flinitlp:
 st (a0)+                       * Laufwerkstabellen entwerten
 dbra d0,flinitlp
 move.b #$60,flo4.w             * Floppy-Motoren aus
 movem.l (a7)+,d0/a0
 rts

getflop:                        * Floppyformat feststellen d4=Laufwerksnummer
 tst.b flo2srd(a5)              * Floppy nach SRAMDISK aktiv?
 beq.s getaflop                 * Nein
 btst #3, d4                  * Floppy4 angesprochen?
 bne flook                      * Ja!, dann fertig ;)
getaflop:
 move.b #$d0,flo0.w             * Controller rücksetzen
 tst.b flo0.w                   * Interrupts löschen
 and.b #$8f,d4                  * Nur Seitenbit und Laufwerkscodierung lassen
 bsr wawa
 or.b #%00110000,d4
 bsr.s get1flop                 * Mini SD
 bcc flook
 and.b #%10101111,d4
 bsr.s get1flop                 * Mini DD
 bcc flook
 eori.b #%00110000,d4
 bsr.s get1flop                 * Maxi SD
 bcc flook
 and.b #%10001111,d4            * Maxi DD

get1flop:
 move.b d4,flo4.w               * Laufwerkscode übertragen
 move.b steprate(a5),d0
 and.b #3,d0                    * Geschwindigkeit
 add.b #$c,d0
 move.b d0,flo0.w               * Restore mit Verify und Headload
 move.l #100000*cpu, d1         * maximale Wartezeit
get2flop:
 btst.b #6,flo4.w
 bne.s get3flop
 subq.l #1, d1
 bge.s get2flop                 * Warten bis Ready
 move #-1, d0
 clr.l d1
 bra floerr
get3flop:
 clr.l d1
 move.b flo0.w,d0               * Status einlesen und Interrupts löschen
 move.b d0,d1                   * Merken für Analyse
 and.b #%10011000,d0
 bne floerr
 bra flook


* d1 = Befehlscode
*  0 = Steprate setzen (0-7)
*  1 = Sektor lesen     2 = Sektor schreiben
*  3 = Track lesen      4 = Track schreiben
*  5 = Startkopf lesen  6 = Restore
*  7 = Seek             8 = Step in
*  9 = Step out        10 = Statusregister beim letzten Zugriff
* d2 = Sektor (Bei d1 = 3,4,6,8,9 ignoriert)
* d3 = Track oder Steprate + SSO Bit 7  (Bei d1 = 6,8,9 ignoriert)
* d4 = Laufwerkscode

floppy:
 tst.b flo2srd(a5)              * Floppy nach SRAMDISK aktiv?
 beq.s floppy1                  * Nein
 btst #3, d4                  * Floppy4 angesprochen?
 bne srdisk                     * Ja!
floppy1:
 movem.l d1-d6/a0-a3,-(a7)
 move sr,-(a7)
 move.l $7c.w,-(a7)             * Interrupt-Ebene 7 Adresse merken
 move.l intlv7(a5),-(a7)        * Ebene 7 im Ram
 lea trap0a(pc),a1              * Sprungadresse für RTE
 move.l a1,intlv7(a5)           * Adresse ablegen zur Sicherheit
 move.l a1,$7c.w                * Adresse ablegen
 or #%0000011100000000,sr       * Interrupt Level 7 setzen
 move.b #$d0,flo0.w             * Floppy Controler rücksetzen
 tst.b flo0.w                   * Interrupts löschen
 bsr.s softex                   * Befehlsauswertung aufrufen
 move sr,d1                     * Statusregister merken
 move.l (a7)+,intlv7(a5)        * Level 7 zurück
 move.l (a7)+,$7c.w             * Level 7 Adresse zurück
 move (a7)+,sr                  * Statusregister zurück
 move d1,ccr                    * Flags zurück
 movem.l (a7)+,d1-d6/a0-a3      * MOVEM, damit Flags erhalten bleiben
 rts

softex:                         * Kernroutine zur Befehlsausführung
 btst.b #2,serflag(a5)          * Floppy umgelenkt ?
 beq.s softex4                  * Nein
 cmp #1,d1                      * Lesen ?
 bne.s softex2                  * Nein, weiter
 bsr.s floanser                 * Sektorinformation übertragen
 move #1024-1,d1                * 1024 Zeichen
softex1:
 bsr si                         * Zeichen von serieller Karte holen
 move.b d0,(a0)+                * Abspeichern
 dbra d1,softex1
 bra flook                       * OK, kein Fehler

softex2:
 cmp #2,d1                      * Schreiben ?
 bne floerr                     * Nein, dann Fehler
 bsr.s floanser                 * Sektorinformation übertragen
 move #1024-1,d1                * 1024 Zeichen
softex3:
 move.b (a0)+,d0                * Zeichen holen
 bsr so                         * An serielle Karte geben
 dbra d1,softex3
 bra flook                       * OK, kein Fehler

softex4:
 tst.b d1                       * Ausgabe über Floppy-Karte auf Diskette
 bne.s soft1
 and.b #$87,d3                  * Steprate setzen
 move.b d3,steprate(a5)         * 0..7 erlaubt
 rts

floanser:                       * Daten für serielles Laufwerk
 move.b d1,d0
 bsr so                         * Lesen oder Schreiben
 move.b d2,d0
 bsr so                         * Sektor
 move.b d3,d0
 bsr so                         * Spur
 move.b d4,d0
 and.b #%10001111,d0            * Nur Seite und Laufwerk lassen
 bra so                          * Laufwerk und Seite

soft1:
 lea flo3.w,a3                  * Daten-Übertragungs-Register
 lea flo4.w,a2                  * Auswahlregister
 move.b d4,(a2)                 * Floppyformat und Laufwerkscode setzen
 moveq #0,d6                    * Keine Fehler bisher
 move.b d4,d5
 and.w #$f,d5                   * Laufwerksnummer
 clr d0
 move.b drvat(a5),d0            * Altes Laufwerks
 cmp.b #$ff,d0
 beq.s notdef                   * Kein altes Laufwerk gültig
 cmp.b d0,d5
 beq.s nurseek                  * Gleiches Laufwerk, dann nur suchen
 lea drvtab(a5),a1
 move.b flo1.w,0(a1,d0.w)       * Alte Spur altes Laufwerk merken
notdef:
 lea drvtab(a5),a1
 move.b 0(a1,d5.w),flo1.w       * Alte Spur aktuelles Laufwerk holen
 lea flo0.w,a1                  * Statusregister
 move.b d5,drvat(a5)            * Aktuelles Laufwerk
 cmp #5,d1
 bhi soft2                      * Extra Befehle
 bra.s nur1
nurseek:
 lea flo0.w,a1
 cmp #5,d1                      * Statusregister
 bhi soft2                      * Extra Befehle
 btst.b #5,(a2)
 bne.s nodum                    * Wenn HEAD down, dann kein Dummy Seek
nur1:
 bsr seek                       * Selektiert als Dummy
 tst.b d0
 bmi.s nur1                     * Warten bis Ready
nodum:
 cmp.b #$ff,flo1.w
 beq.s trv1                     * Wenn Track undefiniert, dann Restore
 cmp.b flo1.w,d3
 beq.s sk11                     * Wenn Floppytrack = Aktueller Track, dann kein
trv:                            * Seek
 bsr seek
 and.b #%10010000,d0            * Mögliche Fehler
 beq.s sk11                     * OK
trv1:
 cmp.b #10,d6                   * 10 mal versuchen
 bhi floerr                     * Sonst Fehler
 bsr restore                    * Spur Null anfahren
 addq.b #1,d6
 bra.s trv

sk11:
 move.b d2,flo2.w               * Sektor setzen
 moveq #8,d0                    * Sektorenlänge
 tst.b steprate(a5)
 bpl.s set1up                   * SSO nicht gesetzt, dann Seite 0
 tst.b d4
 bpl.s set1up                   * SSO und Seite 1 gesetzt, dann Seite 1
 addq #2,d0                     * Seite 1
set1up:
 btst.b #5,(a2)
 bne.s noset                    * HEAD schon geladen, dann OK
 addq #4,d0                     * Sonst Head laden
noset:
 move.l a0,-(a7)
 cmp #1,d1                      * 1 = Sektor lesen
 beq.s rdflp
 cmp #2,d1                      * 2 = Sektor schreiben
 beq.s wrflp
 eori.b #%01001000,d0           * Bit 6 setzen, Bit 3 löschen
 cmp #4,d1
 bne.s sk12
 or.b #%00010000,d0             * 4 = Track schreiben
 bra.s wrflp
sk12:
 cmp #3,d1                      * 5 = Sektorinfo lesen
 bne.s rdflp
 or.b #%00100000,d0             * 3 = Track lesen

rdflp:                          * Sektor, Track oder Sektorinfo lesen
 add.b #$80,d0                  * Bit für LESEN
 move.b d0,(a1)                 * Befehl ausführen
rd1:
 move.b (a2),d0                 * Status prüfen  *** AV TG68 hangs here in this loop where DRQ never comes***
 rol.b #1,d0                    * und setzen der Flags
 bmi.s rd1e                     * Lesen beendet durch Interrupt
 bcc.s rd1                      * DRQ noch nicht da
 move.b (a3),(a0)+              * Daten ablegen
 bra.s rd1                      * Bis alles gelesen
rd1e:
 move.b (a1),d0                 * Status einlesen
 or.b #1,d0                     * Befehl Gruppe 2,3
 move.b d0,flosr(a5)            * Status merken
 movea.l (a7)+,a0
 and.b #%10011100,d0            * Mögliche Fehler
 beq flook                      * Alles OK
 and.b #%00010000,d0
 bne trv1                       * Bei Record not found neu suchen
 addq.b #1,d6                   * Sonst Fehlerzahl erhöhen
 cmp.b #5,d6
 bcs.s sk11                     * Fünfmal Befehl wiederholen
 cmp.b #10,d6
 bcs trv1                       * Dann Seek ausführen
 bra floerr                      * Erst dann erfolgt Fehlermeldung

wrflp:                          * Sektor oder Track schreiben
 add.b #$a0,d0                  * Bits für SCHREIBEN
 move.b d0,(a1)                 * Befehl ausführen
wr1:
 move.b (a2),d0                 * Status prüfen
 rol.b #1,d0                    * und Flags setzen
 bmi.s wr1e                     * Interrupt beendet
 bcc.s wr1                      * Kein DRQ vorhanden
 move.b (a0)+,(a3)              * Daten übertragen
 bra.s wr1                      * Bis alles geschrieben
wr1e:
 move.b (a1),d0                 * Status einlesen
 or.b #1,d0                     * Befehl Gruppe 2,3
 move.b d0,flosr(a5)            * Status merken
 movea.l (a7)+,a0
 btst #6,d0                   * Schreibschutz ?
 bne floerr                     * Dann gleich Ende
 and.b #%10111100,d0            * Mögliche Fehler
 beq flook
 and.b #%00010000,d0
 bne trv1                       * Bei Record not found neu suchen
 addq.b #1,d6                   * Fehler, also Fehlerflag erhöhen
 cmp.b #5,d6
 bcs trv1                       * Bis maximal viermal
 bra floerr                      * Dann erst Fehlermeldung

soft2:                          * Auswertung der neuen Befehle
 cmp #10,d1
 beq.s soft4                    * Statusregister lesen
 bhi floerr                     * Befehl größer 10 gibt es nicht
 bsr.s soft3                    * Befehlsauswertung
 and.b #%10011000,d0
 beq flook                      * OK, kein Fehler
 addq.b #1,d6
 cmp.b #5,d6                    * 5 mal probiert ?
 bhi.s soft2                    * Nein, also nochmal versuchen
 bra floerr                      * Fehler, Befehl wurde nicht richtig ausgeführt

soft3:
 cmp #6,d1                      * Restore
 beq.s restore
 cmp #7,d1                      * Seek
 beq.s seek
 bsr.s setstep                  * Steprate setzen, da Schreib-Lesekopf bewegt
 or.b #$58,d0                   * wird
 cmp #8,d1
 beq.s seek1                    * Step in
 or.b #$20,d0
 bra.s seek1                     * Step out

soft4:
 moveq #0,d0                    * Langwort gültig
 move.b flosr(a5),d0            * Statusregister für Fehlerabfrage
 rts

setstep:                        * Steprate setzen
 bsr.s wawa                     * Warten
 move.b steprate(a5),d0
 and.b #7,d0                    * Steprate ohne SSO
 cmp.b #4,d0
 bmi.s setstep0                 * Kleiner als 4, dann alte Stepraten
 and.b #3,d0
 cmp #2,d1
 beq.s setstep0                 * Langsam bei SEKTOR SCHREIBEN
 cmp #4,d1
 beq.s setstep0                 * Und bei TRACK SCHREIBEN
 move.b d4,d5                   * Sonst auf
 and.b #$df,d5                  * 8 Zoll
 move.b d5,(a2)                 * Floppy Steprate umschalten
 rts                             * Bei schnellem Step ohne Prüflesen
setstep0:
 addq.b #4,d0                   * Spur Prüfen durch Anlesen
 rts

seek:                           * Spur suchen
 bsr.s setstep                  * Steprate setzen
 move.b d3,(a3)                 * Spur setzen
 move.b d2,flo2.w               * Sektor setzen
 or.b #$18,d0                   * Befehl SEEK
seek1:
 move.b d0,(a1)                 * Befehl ausführen
ready:
 btst.b #6,(a2)
 beq.s ready                    * Warten bis Befehl ausgeführt
 move.b (a1),d0                 * Status lesen und Interrupts löschen
 and.b #$fe,d0                  * Befehl Gruppe 1
 move.b d0,flosr(a5)            * Status merken
 move.b d4,(a2)                 * Altes Floppyformat setzen
 rts

restore:                        * Spur Null anfahren
 bsr.s setstep                  * Steprate setzen
 addq.b #8,d0                   * Befehl RESTORE
 bra.s seek1                     * Befehl ausführen

wawa:                           * Warten, da Floppy Controler nicht so schnell
 move #500*cpu,d0
wawa1:
 dbra d0,wawa1
 rts

floerr:
 moveq #-1,d0                   * Error Code
 bra carset                      * Carry auch setzen

flook:
 moveq #0,d0                    * Kein Fehler
 bra carres                      * Carry löschen


*******************************************************************************
*                        680xx Grundprogramm srdio                            *
*                        (C) 1990 Ralph Dombrowski                            *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                           SRAMDISK-Routinen                                 *
*******************************************************************************


srdinit:                        * SDRAMDISK initialisieren
 clr.b flo2srd(a5)
 clr srdcap(a5)
 movem.l d0/a0/a1, -(a7)
 lea srddata.w, a1              * Lade Datenregisteradresse
 move #0, d0                    * Sektor #0
 bsr.s sridtst                  * Teste, ob Sektor vorhanden
 bcc.s srdinit1                 * OK, weiter testen
 move #0, d0                    * Ergebnis 'nicht vorhanden'
 bra.s srdinitx
srdinit1:
 move #512, d0                  * Sektor #512
 bsr.s sridtst                  * Teste, ob Sektor vorhanden
 bcc.s srdinit2                 * OK, weiter testen
 move #511, d0                  * Ergebnis 'Kapazitaet 512 kB'
 bra.s srdinite
srdinit2:
 move #1024, d0                 * Sektor #1024
 bsr.s sridtst                  * Teste, ob Sektor vorhanden
 bcc.s srdinit3                 * OK, weiter testen
 move #1023, d0                 * Ergebnis 'Kapazitaet 1024 kB'
 bra.s srdinite
srdinit3:
 move #1536, d0                 * Sektor #1536
 bsr.s sridtst                  * Teste, ob Sektor vorhanden
 bcc.s srdinit4                 * OK, Baugruppe voll bestueckt
 move #1535, d0                 * Ergebnis 'Kapazitaet 1536 kB'
 bra.s srdinite
srdinit4:
 move #2047, d0                 * Ergebnis 'Kapazitaet 2048 kB'
srdinite:
 move.b #1, flo2srd(a5)         * Umleitung für Floppy4 auf SRD
srdinitx:
 move d0, srdcap(a5)
 movem.l (a7)+, d0/a0/a1
  rts

sridtst:
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
 move.b d0, srdsecl.w           * Setze Sektornummer Low Byte
 lsr #8, d0
 move.b d0, srdsech.w           * Setze Sektornummer High Byte
 lea idebuff(a5), a0            * IDEBUFFER als Hilfspeicher
 move.b (a1), (a0)+             * Sichere aktuelle Inhalt
 move.b (a1), (a0)+
 move.b (a1), (a0)+
 move.b (a1), (a0)+
 move.b d0, srdsech.w           * Setze Bytezaehler zuröck
 lea srdkenn(pc), a0
 move.b (a0)+, (a1)             * Schreibe Kennung in Sektor
 move.b (a0)+, (a1)
 move.b (a0)+, (a1)
 move.b (a0)+, (a1)
 move.b d0, srdsech.w           * Setze Bytezaehler zuröck
 lea idebuff+4(a5), a0
 move.b (a1), (a0)+             * Lese Kennung wieder in Puffer
 move.b (a1), (a0)+
 move.b (a1), (a0)+
 move.b (a1), (a0)+
 move.b d0, srdsech.w           * Setze Bytezaehler zuröck
 lea idebuff(a5), a0
 move.b (a0)+, (a1)             * Stelle Inhalt des Sektor wieder her
 move.b (a0)+, (a1)
 move.b (a0)+, (a1)
 move.b (a0)+, (a1)
 move.l idebuff+4(a5), d0       * Vergleiche Kennung nach Schreiben
 cmp.l srdkenn(pc), d0          * und Lesen aus Sektor
 beq.s sridtst1                 * -> Sektor vorhanden
 move (a7)+, sr                 * Staus zurück
 bra carset                     * Sektor nicht vorhanden, C = 1

sridtst1:
 move (a7)+, sr                 * Staus zurück
 bra carres                     * Sektor vorhanden, C = 0


srdkenn:
 DC.l $55AA33CC                 * Kennung fuer Pruefung


srdisk:                         * Schreib- und Lesezugriffe
                                * auf SRAMDISK
 movem.l d1-d2/a0, -(a7)
 subq #1, d1                    * Befehl -1
 bmi.s srderr                   * nur Befehl Sektor lesen 1(0)
 cmp #1, d1                     * und Sektor schreiben 2(1) zulässig
 bgt.s srderr
 subq.l #1, d2                  * Sektor auf 0-n
 bmi.s srderr                   * Es gibt keinen Sektor 0
 clr.l d0
 move d3, d0                    * Spur nach d0
 lsl.l #3, d0                   * Spur *8
srd01:
 add.l d2, d0
 cmp srdcap(a5), d0             * Sektor gültig?
 bhi.s srderr                   * Nein, Fehler!
 tst d1                         * Sektor lesen?
 bne.s srd02                    * nein, dann schreiben
 bsr srdread
 bra.s srdex
srd02:
 bsr srdwrite
 bra.b srdex
srderr:
 move #-1, d0
 movem.l (a7)+, d1-d2/a0
 bra carset
srdex:
 clr d0
 movem.l (a7)+, d1-d2/a0
 bra carres
  rts


srdread:                        * Sektor von SRAMDISK lesen
                                * d0 = Sektornummer
                                * a0 = Zieladresse
 movem.l a1, -(a7)
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
 lea srddata.w, a1              * Lade Datenregisteradresse
 move.b d0, srdsecl.w           * Setze Sektornummer Low Byte
 lsr #8, d0
 move.b d0, srdsech.w           * Setze Sektornummer High Byte
 move #255, d0                  * Anzahl Bloecke fuer Zaehler
srdrdlp:
 move.b (a1), (a0)+             * Übertrage ein Byte in den Puffer
 move.b (a1), (a0)+
 move.b (a1), (a0)+
 move.b (a1), (a0)+
 dbra d0, srdrdlp               * Lese gesamten Sektor
 move (a7)+, sr                 * Staus zurück
 movem.l (a7)+, a1
 rts


srdwrite:                       * Sektor auf SRAMDISK schreiben
                                * d0 = Sektor
                                * a0 = Quelladresse
 movem.l a1, -(a7)
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
 lea srddata.w, a1              * Lade Datenregisteradresse
 move.b d0, srdsecl.w           * Setze Sektornummer Low Byte
 lsr #8, d0
 move.b d0, srdsech.w           * Setze Sektornummer High Byte
 move #255, d0                  * Anzahl Bloecke fuer Zaehler
srdwrlp:
 move.b (a0)+, (a1)             * Übertrage ein Byte zur SRAMDISK
 move.b (a0)+, (a1)
 move.b (a0)+, (a1)
 move.b (a0)+, (a1)             * Block geschrieben
 dbra d0, srdwrlp               * Schreibe gesamten Sektor
 move (a7)+, sr                 * Staus zurück
 movem.l (a7)+, a1
 rts

setf2s:                         * Floppy4 nach SRAMDISK Umleitung setzen
 move.b d0, flo2srd(a5)
  rts

getf2s:                         * Floppy4 nach SRAMDISK Umleitung laden
 move.b flo2srd(a5), d0
  rts

getsrd:                         * Grösse der SRAMDISK abfragen
 move srdcap(a5), d0
  rts
*******************************************************************************
*                         680xx Grundprogramm hardd                           *
*                         (C) 1990 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                            Harddisk-Routinen                                *
*******************************************************************************


* d1 = Befehlscode (SB = Basis-Befehlssatz / SE = Erweiterter Befehlssatz)
*  0 = Rezero Unit        (SB)
*  1 = Read               (SB)     2 = Write                      (SB)
*  3 = Read Long          (SE)     4 = Write Long                 (SE)
*  5 = Mode Select        (SB)     6 = Mode Sense                 (SB)
*  7 = Seek               (SB)     8 = Test Unit Ready            (SB)
*  9 = Park               (SB)    10 = Unpark                     (SB)
* 11 = Extended Read      (SE)    12 = Extended Write             (SE)
* 13 = Read Buffer        (SE)    14 = Write Buffer               (SE)
* 15 = Reserve            (SB)    16 = Release                    (SB)
* 17 = Write + Verify     (SE)    18 = Verify                     (SE)
* 19 = Send Diagnostic    (SB)    20 = Extended Seek              (SE)
* 21 = Read Usage Counter (SB)    22 = Read Capacity              (SB)
* 23 = Rec. Diagnostic R. (SE)    24 = Inquiry                    (SB)
* 25 = Read Defect Data   (SB)    26 = Reassign Blocks            (SB)
* 27 = Request Sense      (SB)    28 = Format Unit                (SB)
* 29 = Eigene Befehle

* d2, d3 Je nach Befehl verschieden
* d4 = Laufwerksnummer
* a0.l = Adresse Daten, wenn verlangt
* a1.l = Bei Funktion 29 Adresse des Befehls

harddisk:
 cmp.b #1, scsi2ide(a5)         * Umleitung aktiv?
 beq idediski                   * interne IDEDISK
 cmp.b #2, scsi2ide(a5)
 beq sddiski                    * interne SDDISK
 btst.b #4,keydil(a5)           * Harddisk vorhanden ?
 beq hderr                      * Nein, dann Fehler
 movem.l d1-d5/a0-a3,-(a7)
 bsr.s hdcommand                * Befehlsauswertung aufrufen
 movem.l (a7)+,d1-d5/a0-a3
 rts

hdbeftab:                       * Tabelle der Befehle
 DC.w hdgrup0-hdbeftab          * Auf Track 0
 DC.w hdgrup0b-hdbeftab         * Sektor lesen (d2.l/d3.b/a0.l)
 DC.w hdgrup0b-hdbeftab         * Sektor schreiben (d2.l/d3.b/a0.l)
 DC.w hdgrup0a-hdbeftab         * Sektor + ECC lesen (d2.l/a0.l)
 DC.w hdgrup0a-hdbeftab         * Sektor + ECC schreiben (d2.l/a0.l)
 DC.w hdbef5-hdbeftab           * Mode auswählen (d2.b/a0.l)
 DC.w hdbef6-hdbeftab           * Parameter des Laufwerks lesen (d2.b/d3.b/a0.l)
 DC.w hdgrup0a-hdbeftab         * Sektor suchen (d2.l)
 DC.w hdgrup0-hdbeftab          * Laufwerk breit ?
 DC.w hdgrup0-hdbeftab          * Park
 DC.w hdbef10-hdbeftab          * Unpark
 DC.w hdgrup1b-hdbeftab         * Sektor lesen (d2.l/d3.w/a0.l)
 DC.w hdgrup1b-hdbeftab         * Sektor schreiben (d2.l/d3.w/a0.l)
 DC.w hdbef13-hdbeftab          * Buffer lesen (d2.w/a0.l)
 DC.w hdbef14-hdbeftab          * Buffer schreiben (d2.w/a0.l)
 DC.w hdbef15-hdbeftab          * Einheit reservieren (d2.w/d3.w/a0.l)
 DC.w hdbef16-hdbeftab          * Einheit freigeben (d2.w)
 DC.w hdgrup1b-hdbeftab         * Sektoren schreiben und prüfen (d2.l/d3.w/a0.l)
 DC.w hdgrup1b-hdbeftab         * Sektor prüfen (d2.l/d3.w)
 DC.w hdbef19-hdbeftab          * Diagnostic senden
 DC.w hdgrup1a-hdbeftab         * Sektor suchen (d2.l)
 DC.w hdgrup1-hdbeftab          * Zähler-Statistik lesen (a0.l)
 DC.w hdbef22-hdbeftab          * Größe der Platte lesen (d2.l/d3.b/a0.l)
 DC.w hdgrup0-hdbeftab          * Internen Test durchführen
 DC.w hdbef24-hdbeftab          * Laufwerksnamen lesen (a0.l)
 DC.w hdbef25-hdbeftab          * Liste der Defekte lesen (d2.b/d3.w/a0.l)
 DC.w hdgrup0-hdbeftab          * Neue defekte Blöcke schreiben (a0.l)
 DC.w hdbef27-hdbeftab          * Fehler lesen
 DC.w hdbef28-hdbeftab          * Formatieren (d2.b/d3.w/a0.l)

hdcomtab:                       * Tabelle der Kommandos
 DC.b $01,$08,$0A,$E5,$E6,$15,$1A,$0B,$00,$1B,$1B,$28,$2A,$3C,$3B,$16
 DC.b $17,$2E,$2F,$1D,$2B,$11,$25,$1C,$12,$37,$07,$03,$04
 ds 0

hdcommand:                      * Befehl aufbereiten und aufrufen
 cmp #29,d1
 beq.s hdcomm                   * Falls Befehl selber durchgeführt werden soll
 bhi hderr                      * Wert ist zu groß
 lea hdtab(a5),a1               * Hier wird Befehl abgelegt
 moveq #0,d0                    * d0.l muß 0 sein, da als Langwort addiert wird
 move.b hdcomtab(pc,d1.w),d0    * Befehl
 add d1,d1
 move hdbeftab(pc,d1.w),d1
 jsr hdbeftab(pc,d1.w)          * Befehl aufbereiten
 clr.b (a1)                     * Ende ist immer gleich
 lea hdtab(a5),a1               * Adresse Befehl

hdcomm:                         * d4=Laufwerk / a0=Daten / a1=Adresse Command
 lea hddata.w,a2                * Adresse Daten-Übertragungsregister
 lea hdstat.w,a3                * Adresse Status-Register
hdcom0:
 btst.b #1,(a3)                 * Warten, bis nicht mehr BUSY
 bne.s hdcom0
 move.b d4,(a2)                 * Laufwerks ID
 clr.b hdsel.w                  * Laufwerk aktivieren
hdcomin:                        * Einsprung für Hardtest
 moveq #0,d0                    * Löschen für Status, da Langwort gültig
*move.b (a3),d0                 * Hier Abfrage für schnelle Erweiterung der
*and.b #%01100000,d0            * Harddisk (Hardware-Codierung)
*cmp.b #%00100000,d0            * Kennung für spezielle Codierung
*beq.s hdcom8                   * Hier besonders schnelle Routine
 moveq #0,d5                    * Request-Bit
 moveq #3,d4                    * Data/Command
 moveq #4,d3                    * Input/Output
 moveq #2,d2                    * Message-Bit
hdcom1:
 btst.b #1,(a3)                 * Warten, bis ausgewählt
 beq.s hdcom1
hdcom2:                         * Ohne Erweiterung (normale Geschwindigkeit)
 move.b (a3),d1
 btst d5,d1
 beq.s hdcom2                   * Schleife, bis Request vorhanden
 btst d4,d1                     * Auswahl Daten oder Command
 bne.s hdcom4
 btst d3,d1                     * Auswahl Input oder Output
 beq.s hdcom3
 move.b (a2),(a0)+              * Data in
 bra.s hdcom2
hdcom3:
 move.b (a0)+,(a2)              * Data out
 bra.s hdcom2

hdcom4:                         * Command
 btst d2,d1                     * Message oder Command/Status
 bne.s hdcom6
 btst d3,d1                     * Input oder Output
 bne.s hdcom5
 move.b (a1)+,(a2)              * Command
 bra.s hdcom2
hdcom5:                         * Status
 move.b (a2),d0                 * Merken für Fehlerabfrage
 bra.s hdcom2

hdcom6:                         * Message
 btst d3,d1                     * Input oder Output
 bne.s hdcom7
 move.b #$08,(a2)               * Message out (NO OPERATION)
 bra.s hdcom2

hdcom8:                         * Hier für Hardware-Codierung
*btst.b #1,(a3)                 * Warten, bis ausgewählt
*beq.s hdcom8
*moveq #0,d1                    * Langwort soll gültig sein
*lea hdcode.w,a3                * Diese Adresse ist für die Erweiterung
hdcom9:
*move.b (a3),d1                 * Relative Sprungadresse holen
*jmp hdcom9(pc,d1.l)            * hinspringen

* Von hier an darf nichts verändert werden *

*move.b (a2),(a0)+              * Data in
*bra.s hdcom9
*move.b (a0)+,(a2)              * Data out
*bra.s hdcom9
*move.b (a1)+,(a2)              * Command
*bra.s hdcom9
*move.b (a2),d0                 * Status
*bra.s hdcom9
*move.b #$08,(a2)               * Message out
*bra.s hdcom9
hdcom7:
 tst.b (a2)                     * Message in (Ende)
 bra carres                      * Immer Carry=0 (Fehlercode in d0)

* Bis hierhin darf nichts geändert werden *

hdbef5:                         * Mode Auswahl
 moveq #0,d3                    * d2.b = Länge der Parameter Liste/a0.l = Daten
 move.b d2,d3                   * Keine Sekorenauswahl
 moveq #0,d2
 bra.s hdgrup0b

hdbef6:                         * Laufwerksdaten lesen
 and.l #$ff,d2                  * d2.b = PC + Page-Code
 lsl.l #8,d2                    * d3.b = Länge der Daten
 and.w #$ff,d3
 bra.s hdgrup0b

hdbef10:                        * Unpark
 moveq #0,d2                    * Meldung erst, wenn wirklich zurück
 moveq #1,d3                    * Auf Track 0
 bra.s hdgrup0b

hdbef13:                        * Buffer lesen
hdbef14:                        * Buffer schreiben
 move d2,d3                     * d2.w = Maximale Länge
 moveq #0,d2
 bra.s hdgrup0b

hdbef16:                        * Einheit freigeben
 moveq #0,d3                    * Keine Längenangabe
hdbef15:                        * Einheit reservieren
 lsl.l #8,d2                    * d2.b = Identifikation
 bra.s hdgrup0b                  * d3.w = Länge der Daten

hdbef19:                        * Diagnostic senden
 moveq #4,d2
 swap d2                        * $00040000 -> d2
 moveq #0,d3
 bra.s hdgrup0b

hdbef22:                        * Größe der Platte lesen
 and.w #1,d3                    * d2.l = Sektornummer / d3.b = PMI
 bra.s hdgrup1b                  * a0.l = Adresse Ergebnis

hdbef24:                        * Laufwerksdaten lesen
 moveq #0,d2
 moveq #35,d3                   * Alle Daten lesen
 bra.s hdgrup0b

hdbef25:                        * Liste der Defekte lesen
 and.l #3,d2                    * d2.b = Auswahl
 ror.l #5,d2                    * d3.w = Maximale Länge
 bra.s hdgrup1b                  * a0.l = Adresse Daten

hdbef27:                        * Fehler lesen
 moveq #0,d2                    * Keine Sektornummer
 moveq #27,d3                   * Maximal 27 Bytes übertragen
 bra.s hdgrup0b

hdbef28:                        * Formatieren
 move.b d0,(a1)+                * d2.b = Format der Defect-List
 and #$1f,d2                    * a0.l = Defect List
 move.b d2,(a1)+                * d3.w = Interleave
 bra.s hdgrup1c                  * Rest

hdgrup0:
 moveq #0,d2                    * Keine Sektornummer erforderlich
hdgrup0a:
 moveq #0,d3                    * Keine Anzahl erforderlich
hdgrup0b:
 and.l #$001fffff,d2            * Sektornummer o.ä.
 ror.l #8,d0
 add.l d0,d2                    * Befehlscode dazu
 move.l d2,(a1)+                * Ablage
 move.b d3,(a1)+                * Anzahl Blöcke oder Daten
 rts

hdgrup1:
 moveq #0,d2                    * Keine Sektoranzahl erforderlich
hdgrup1a:
 moveq #0,d3                    * Keine Anzahl erforderlich
hdgrup1b:
 move.b d0,(a1)+                * Befehlscode
 clr.b (a1)+                    * LUN und Reserve
 move.l d2,(a1)+                * Sektornummer o.ä.
hdgrup1c:
 clr.b (a1)+                    * Reserviert
 rol #8,d3
 move.b d3,(a1)+
 rol #8,d3
 move.b d3,(a1)+                * Anzahl Blöcke oder Daten
 rts

hardtest:                       * Test, ob das Laufwerk vorhanden ist
 cmp.b #1, scsi2ide(a5)         * Umleitung aktiv?
 beq idetest                    * IDETEST
 cmp.b #2, scsi2ide(a5)
 beq sdtest                     * SDTEST
 btst.b #4,keydil(a5)           * Harddisk vorhanden ?
 beq hderr                      * Nein, dann Fehler
hardt0:
 btst.b #1,hdstat.w             * d4.b = Laufwerksnummer
 bne.s hardt0                   * Warten, bis nicht mehr BUSY
 move.b d4,hddata.w             * Laufwerks ID
 clr.b hdsel.w                  * Laufwerk aktivieren
 move #2000*cpu,d0              * Schleifendurchläufe sind CPU-abhängig
hdtest1:
 btst.b #1,hdstat.w             * Warten, bis ausgewählt
 bne.s hdtest2                  * OK, Laufwerk vorhanden
 dbra d0,hdtest1
 bra hderr                       * Laufwerk nicht vorhanden (antwortet nicht)
hdtest2:
 movem.l d1-d5/a0-a3,-(a7)
 lea hdtab+4(a5),a1             * TEST UNIT READY
 clr.w (a1)
 clr.l -(a1)
 lea hddata.w,a2                * Adresse Daten-Übertragungsregister
 lea hdstat.w,a3                * Adresse Status-Register
 bsr hdcomin
 movem.l (a7)+,d1-d5/a0-a3
 rts

hderr:
 moveq #-1,d0                   * Error Code
 bra carset                      * Carry auch setzen
*******************************************************************************
*                         680xx Grundprogramm ideio                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                            IDE-Disk-Routinen                                *
*******************************************************************************


idetest:                        * Test, ob Laufwerk vorhanden
                                * d4 enthaelt Laufwerk
 btst.b #5,keydil(a5)           * IDE vorhanden ?
 beq.s hderr                    * Nein, dann Fehler
 tst.b d4
 beq.s hderr                    * Kein LW angegeben
 and.b #$0f, d4
 movem.l d1-d4/a1/a6, -(a7)
 cmp.b #1, d4
 bne.s idt01
 lea idemgeo(a5), a6            * Variablenspeicher LW1
 move #$a0, d4                  * d4 jetzt Master-Flag
 bra.s idt02
idt01:                          * Slave-Laufwerk
 cmp.b #2, d4
 bne.s idterr                   * kein gueltiges Laufwerk
 lea idesgeo(a5), a6            * Variablenspeicher Slave
 move #$b0, d4                  * d4 jetzt Slave-Flag
idt02:
 bsr ideid                      * LW Identifizieren
 tst d0
 bmi.s idterr                   * Fehler bei Identifizieren
 bsr ideinit                    * LW initialisieren
 tst d0
 bmi.s idterr                   * Fehler beim Initialisieren
 movea.l a6, a0
 movem.l (a7)+, d1-d4/a1/a6
 bra carres

idterr:
 movem.l (a7)+, d1-d4/a1/a6
 bra.s hderr

ideid:                          * Identifiziert ein Laufwerk
 move.b d4, idesdh.w            * Master / Slave
idlp01:
 clr numcyl(a6)                 * LW-Parameter löschen
 clr.b numhead(a6)
 clr.b numsec(a6)
 bsr idewr
 tst d0
 bmi idlp20
 move.b #cmdident, idecmd.w     * LW Identifizierung
 bsr idewd                      * Daten bereit?
 tst d0
 bmi idlp20                     * nein, dann Fehler
 lea idebuff(a5),a0             * Puffer für Transfer
 lea idedat.w, a1
 move #(512/4)-1, d3
idlp04:
 move.b (a1), (a0)+             * Ident-Daten einlesen
 move.b (a1), (a0)+
 move.b (a1), (a0)+
 move.b (a1), (a0)+
 dbra d3, idlp04
 bsr idewr                      * LW fertig?
 tst d0
 bmi idlp20                     * nein, dann Fehler
 lea idebuff(a5),a0             * Puffer für Transfer
 clr.l d0
 move.b 3(a0), d0               * Zylinder High-Byte
 lsl #8, d0
 move.b 2(a0), d0               * Zylinder Low-Byte
 move d0, numcyl(a6)            * speichern
 clr.l d0
 move.b 6(a0), numhead(a6)      * Anzahl der Köpfe
 move.b 12(a0), numsec(a6)      * Anzahl der Sektoren/Spur
 movea.l a6, a1
 adda.l #idename, a1            * a1 auf LW-Name-Speicher
 adda.l #54, a0                 * A0 auf Namensquelle
 move #12-1, d3                 * nur die ersten 24 Zeichen
idlp10:
 move.b 1(a0), (a1)+            * Transfer mit Byteswap
 move.b 0(a0), (a1)+
 addq.l #2, a0
 dbra d3, idlp10
 move #$0, (a1)+                * noch ne 0 zum Abschluss
 bra.b idex
idlp20:
 move #-1, d0
idex:
  rts

ideinit:                        * Initialisiert das Laufwerk
 move.b #6, idedor.w
 move.l #255, d3
ideilp01:
 dbra d3, ideilp01              * ein bisschen warten
 move.b #2, idedor.w
 bsr idewr                      * LW bereit?
 tst d0
 beq.b ideilp03                 * ja
 bra ideiex
ideilp03:
 move.b numsec(a6), idescnt.w   * Anzahl Sektoren
 move.b numcyl+1(a6), ideclo.w  * Zylinder Low-Byte
 move.b numcyl(a6), idechi.w    * Zylinder High-Byte
 move.b numhead(a6), d0         * Anzahl Köpfe
 subq.b #1, d0                  * -1
 or.b d4, d0                    * mit LW Kennung verodert
 move.b d0, idesdh.w            * und ausgeben
 move.b #cmdinit, idecmd.w      * nun weis das LW was es ist ;)
 clr d0
ideiex:
  rts

idediski:                       * interne IDE IO-Routine
 moveq #1, d0                   * 1024 BPS
 bra.s idedisk1

idedisk:                        * IDE IO-Routine
 moveq #0, d0                   * 512 BPS
idedisk1:
 btst.b #5,keydil(a5)           * IDE vorhanden ?
 beq hderr                      * Nein, dann Fehler
 movem.l d1-d5/a0-a3/a6, -(a7)
 bsr.s idecomm                  * Hauptroutine aufrufen
 movem.l (a7)+, d1-d5/a0-a3/a6
 rts

idebeftab:                      * Tabelle der Befehle
 DC.w ideok-idebeftab           * Auf Track 0
 DC.w idebef1-idebeftab         * Sektor lesen (d2.l/d3.b/a0.l)
 DC.w idebef2-idebeftab         * Sektor schreiben (d2.l/d3.b/a0.l)
 DC.w idenok-idebeftab          * Sektor + ECC lesen (d2.l/a0.l)
 DC.w idenok-idebeftab          * Sektor + ECC schreiben (d2.l/a0.l)
 DC.w ideok-idebeftab           * Mode auswählen (d2.b/a0.l)
 DC.w ideok-idebeftab           * Parameter des Laufwerks lesen (d2.b/d3.b/a0.l)
 DC.w ideok-idebeftab           * Sektor suchen (d2.l)
 DC.w idebef8-idebeftab         * Laufwerk breit ?
 DC.w ideok-idebeftab           * Park
 DC.w ideok-idebeftab           * Unpark
 DC.w idenok-idebeftab          * Sektor lesen (d2.l/d3.w/a0.l)
 DC.w idenok-idebeftab          * Sektor schreiben (d2.l/d3.w/a0.l)
 DC.w idenok-idebeftab          * Buffer lesen (d2.w/a0.l)
 DC.w idenok-idebeftab          * Buffer schreiben (d2.w/a0.l)
 DC.w ideok-idebeftab           * Einheit reservieren (d2.w/d3.w/a0.l)
 DC.w ideok-idebeftab           * Einheit freigeben (d2.w)
 DC.w idenok-idebeftab          * Sektoren schreiben und prüfen (d2.l/d3.w/a0.l)
 DC.w idenok-idebeftab          * Sektor prüfen (d2.l/d3.w)
 DC.w ideok-idebeftab           * Diagnostic senden
 DC.w idenok-idebeftab          * Sektor suchen (d2.l)
 DC.w ideok-idebeftab           * Zähler-Statistik lesen (a0.l)
 DC.w idebef22-idebeftab        * Größe der Platte lesen (d2.l/d3.b/a0.l)
 DC.w idenok-idebeftab          * Internen Test durchführen
 DC.w idebef24-idebeftab        * Laufwerksnamen lesen (a0.l)
 DC.w ideok-idebeftab           * Liste der Defekte lesen (d2.b/d3.w/a0.l)
 DC.w ideok-idebeftab           * Neue defekte Blöcke schreiben (a0.l)
 DC.w ideok-idebeftab           * Fehler lesen
 DC.w ideok-idebeftab           * Formatieren (d2.b/d3.w/a0.l)

idecomm:
 cmp #29, d1
 beq ideok                      * keine Eigenen Befehle
 bhi hderr                      * Wert zu gross
 and #$0f, d4
 cmp #1, d4                     * Master?
 bne.s idec1                    * nö
 lea idemgeo(a5), a6
 bra.s idec2
idec1:
 cmp #2, d4                     * Slave?
 bne.s idenok                   * nö
 lea idesgeo(a5), a6
idec2:
 add d1, d1                     * mal 2 da Wort
 move idebeftab(pc,d1.w), d1    * Sprungwert laden
 jsr idebeftab(pc,d1.w)
 bra carres

ideok:                          * liefert nur ein OK zurück
 clr d0
 bra carres

idenok:                         * liefert einen Fehler zurück
 moveq #-1, d0
  rts

idebef1:                        * Sektoren lesen
 cmp #1, d4                     * Master LW?
 bne.s idb1a                    * nein
 move #$a0, d4
 bra.s idb1b
idb1a:
 cmp #2, d4                     * Slave LW?
 bne idb1err                    * nein, dann Fehler
 move #$b0, d4
idb1b:
 asl.l d0, d2                   * Sta rtsektor *2, falls 1024 BPS
 asl.l d0, d3                   * Anzahl * 2, falls 1024 BPS
 move.l d2, d0                  * Sta rtsektor
 move d3, d1                    * Anzahl
 tst d1                         * Null?
 bne.s idb1e                    * NEIN! dann keine 512 Sektoren
 move.l #256, d2
 bra.s idb1f
idb1e:
 cmp #256, d1                   * < 256?
 blt.s idb1c                    * ja
idb1d:
 clr.l d2
 lsr #1, d1                     * Anzahl /2, da 2 Aufrufe
 move d1, d2                    * sichern
idb1f:
 move.l d0, d3                  * sichern
 bsr iderdsek                   * 1. Lesen, bei mehr als 256 Sektoren
 tst d0
 bne.s idb1err
 move.l d3, d0                  * Sta rtsektor zurück
 add.l d2, d0                   * um Anzahl Sektoren erhöhen
 mulu #512, d2                  * Anzahl * Grösse
 adda.l d2, a0                  * Puffer erhöhen
idb1c:
 bsr iderdsek                   * Lesen, zum 2. bei Sektoren > 256
 tst d0
 beq.s idb1ex
idb1err:
 move #-1, d0
idb1ex:
  rts

idebef2:                        * Sektoren schreiben
 cmp #1, d4                     * Master LW?
 bne.s idb2a                    * nein
 move #$a0, d4
 bra.s idb2b
idb2a:
 cmp #2, d4                     * Slave LW?
 bne idb2err                    * nein, dann Fehler
 move #$b0, d4
idb2b:
 asl.l d0, d2                   * Sta rtsektor *2, falls 1024 BPS
 asl.l d0, d3                   * Anzahl * 2, falls 1024 BPS
 move.l d2, d0                  * Sta rtsektor
 move d3, d1                    * Anzahl
 tst d1                         * Null?
 bne.s idb2e                    * NEIN! dann keine 512 Sektoren
 move.l #256, d2
 bra.s idb2f
idb2e:
 cmp #256, d1                   * < 256?
 blt.s idb2c                    * ja
idb2d:
 clr.l d2
 lsr #1, d1                     * Anzahl /2, da 2 Aufrufe
 move d1, d2                    * sichern
 addq #1, d2                    * Anzahl + 1 (1...n)
idb2f:
 move.l d0, d3                  * sichern
 bsr idewrsek                   * 1. Schreiben, bei mehr als 256 Sektoren
 tst d0
 bne.s idb2err
 move.l d3, d0                  * Sta rtsektor zurück
 add.l d2, d0                   * um Anzahl Sektoren erhöhen
 mulu #512, d2                  * Anzahl * Grösse
 adda.l d2, a0                  * Puffer erhöhen
idb2c:
 bsr idewrsek                   * Schreiben, zum 2. bei Sektoren > 256
 tst d0
 beq.s idb2ex
idb2err:
 move #-1, d0
idb2ex:
  rts

idebef8:                        * Laufwerk bereit?
 btst.b #7, idecmd.w            * Busy-Flag abfragen
 beq.s idb8a
 move.l #4, d0                  * und entsprechend SCSI setzen
 bra.s idb8ex
idb8a:
 clr.l d0                       * oder löschen
idb8ex:
  rts

idebef22:                       * Kapazität lesen
 clr.l d2
 move.b numsec(a6), d2
 move.l #512, d1                * 512 Byte/Sektor
 cmp #1, d3                     * Sektoren pro Spur
 bne.s idb22a                   * nein
 lsr.l d0, d2                   * /2 da 1024 Byte pro Sektor
 asl.l d0, d1                   * auf 1024 Bytes setzen
 bra.s idb22ex
idb22a:
 move.b numhead(a6), d3
 mulu d3, d2                    * Köpfe * Sektoren
 move numcyl(a6), d3
 mulu d3, d2                    * Köpfe * Sektoren * Spuren
 lsr.l d0, d2                   * /2 da 1024 Byte pro Sektor
 asl.l d0, d1                   * auf 1024 Bytes setzen
idb22ex:
 move.l d2, 0(a0)
 move.l d1, 4(a0)
 clr.l d0
  rts

idebef24:                       * LW Name lesen
 move #36-1, d3                 * 36 Byte Buffer
 movea.l a0, a1
idb24a:
 clr.b (a1)+                    * löschen
 dbra d3, idb24a
 move.b #1, 3(a0)               * ??? aus SCSI Bescheibung übernommen
 move.b #$3d, 4(a0)             * ??? aus SCSI Bescheibung übernommen
 move #24-1, d3                 * 24 Byte übertragen
 movea.l a6, a1                 * ide_geo
 adda.l #idename, a1
 adda.l #8, a0
idb24b:
 move.b (a1)+, (a0)+            * Name kopieren
 dbra d3, idb24b
  rts


iderdsek:                * Sektor(en) lesen D0=Sektornr., D1=Anzahl, A0=Puffer
 movem.l d1-d5/a1-a2, -(a7)
 move.l d0, d2                          * sichern
 move.l d1, d5                          * sichern
 bsr idewr                              * LW bereit?
 tst d0
 beq.b rdlp01                           * ja
 bra rderr                              * sonst Fehler
rdlp01:
 move.b d5, idescnt.w                   * d5 Sektor(en)
 move.l d2, d0                          * Sektor zurück
 bsr lba2chs                            * nach CHS umrechnen
 move.b d2, idesnum.w                   * Start-Sektor
 move.b d3, ideclo.w                    * Start Spur Low-Byte
 lsr #8, d3
 move.b d3, idechi.w                    * Start-Spur High-Byte
 or.b d4, d1                            * Anzahl Köpfe mit LW verodert
rdlp10:
 move.b d1, idesdh.w                    * und übergeben
 tst d5                                 * Sektorenanzahl=0?
 bne.s rdlp11                           * nein
 move #256, d5                          * sonst = 256
rdlp11:
 move #10-1, d2                         * 10 Versuche
 movea.l a0, a2                         * retten
 subq #1, d5                            * als Zähler
 move d5, d4                            * retten
 lea idedat.w, a1                       * Transferadresse nach a1
rdlp12:
 move d4, d5                            * wiederherstellen
 movea.l a2, a0                         * dito
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
 move.b #cmdrd, idecmd.w                * Lese-Befehl
rdlp12a:
 move #(512/4)-1, d3                    * Anzahl Bytes -1
 bsr idewd                              * Daten bereit?
 tst d0
 beq.s rdlp13				* ja, kein Fehler
 move (a7)+, sr                 * Staus zurück
 bra.s rderr                            * Fehler
rdlp13:
 move.b (a1), (a0)+                     * lesen
 move.b (a1), (a0)+
 move.b (a1), (a0)+
 move.b (a1), (a0)+
 dbra d3, rdlp13                        * nächstes Byte
 dbra d5, rdlp12a                       * nächsten Sektor
 move (a7)+, sr                 * Staus zurück
 bsr idewr                              * LW fertig?
 tst d0
 bne rderr                              * nein, dann Fehler
 move.b idecmd.w, d0
 and.b #%10001001, d0                   * irgend welche weiteren Fehler?
 beq.b rdlp20                           * nö, dann fertig
 dbra d2, rdlp12                        * sonst nochmal
rderr:
 moveq #-1, d0
 bra.b rdex
rdlp20:
 clr d0
rdex:
 movem.l (a7)+, d1-d5/a1-a2
  rts


idewrsek:            * Sektor(en) schreiben D0=Sektornr., d1=Anzahl, A0=Puffer
 movem.l d1-d5/a1-a2, -(a7)
 move.l d0, d2                          * sichern
 move.l d1, d5
 bsr idewr
 tst d0
 beq.b wrlp01
 bra wrerr
wrlp01:
 move.b d5, idescnt.w                   * d5 Sektor(en)
 move.l d2, d0                          * Sektor zurück
 bsr lba2chs                            * in CHS umrechnen
 move.b d2, idesnum.w
 move.b d3, ideclo.w
 lsr #8, d3
 move.b d3, idechi.w
 or.b d4, d1
 move.b d1, idesdh.w
 tst d5
 bne.s wrlp11
 move #256, d5
wrlp11:
 move #10-1, d2                         * 10 Versuche
 movea.l a0, a2                         * retten
 subq #1, d5                            * -1 als Zähler
 move d5, d4                            * retten
 lea idedat.w, a1
wrlp12:
 move d4, d5                            * wiederherstellen
 movea.l a2, a0
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
 move.b #cmdwr, idecmd.w
wrlp12a:
 move #(512/4)-1,d3                     * Anzahl Bytes -1
 bsr idewd
 tst d0
 bne.s wrlp13				* kein Fehler
 move (a7)+, sr                 * Staus zurück 
 bra.s wrerr
wrlp13:
 move.b (a0)+, (a1)                     * schreiben
 move.b (a0)+, (a1)
 move.b (a0)+, (a1)
 move.b (a0)+, (a1)
 dbra d3, wrlp13                        * nächstes Byte
 dbra d5, wrlp12a                       * nächster Sektor
 move (a7)+, sr                 * Staus zurück
 bsr idewr
 tst d0
 bne wrerr
 move.b idecmd.w, d0
 and.b #%10001001, d0                   * irgend welche Fehler?
 beq.b wrlp20                           * nö, fertig
 dbra d2, wrlp12                        * sonst noch'n Versuch
wrerr:
 moveq #-1, d0
 bra.b wrex
wrlp20:
 clr d0
wrex:
 movem.l (a7)+, d1-d5/a1-a2
  rts


lba2chs:                        * Rechenet LBA (d0.l) in Head (d1.b),
                                * Sektor (d2.b) und Zylinder (d3.w) um
                                * a6 = Master/Slave-Buffer
 clr.l d1
 move.b numsec(a6), d1
 divu d1, d0                            * log. Sektor / Sektoren pro Spur
 swap d0                                * nur der Rest
 move.b d0, d2                          * Sektor
 addq.b #1, d2                          * +1
 clr d0
 swap d0                                * Divisionsergebnis
 move.b numhead(a6), d1
 divu d1, d0                            * durch Anzahl der Köpfe
 move d0, d3                            * Zylinder
 swap d0                                * Köpfe
 move.b d0, d1
  rts

idewr:                                  * Warten bis Laufwerk ready
 move.l #idedel*cpu, d0                 * Delaywert laden
iwr01:
 subq.l #1, d0
 bmi iwr02                              * Abbruch
 btst.b #7, idecmd.w                    * Busy?
 bne.b iwr01                            * ja!
 clr d0                                 * ist ready
 bra.b iwrex
iwr02:
 move #-1, d0                           * ist NICHT ready
iwrex:
  rts

idewd:                                  * Warten bis LW bereit für Daten
 move.l #idedel*cpu, d0                 * Delaywert laden
iwd01:
 subq.l #1, d0
 bmi iwd02                              * Abbruch
 btst.b #3, idecmd.w                    * bereit für Datentransfer?
 beq.b iwd01                            * ja
 clr d0                                 * Daten bereit
 bra.b iwdex
iwd02:
 move #-1, d0                           * Daten NICHT bereit
iwdex:
  rts


numcyl     EQU 0
numhead    EQU 2
numsec     EQU 3
nkcmode    EQU 4
idename    EQU 8

idedel     EQU 40000

cmdrd      EQU $20
cmdwr      EQU $30
cmdinit    EQU $91
cmdident   EQU $ec


sets2i:                         * SCSI nach IDE/SD Umleitung setzen
 move.b d0, scsi2ide(a5)
 clr d0
  rts

gets2i:                         * SCSI nach IDE/SD Umleitung laden
 move.b scsi2ide(a5), d0
  rts
*******************************************************************************
*                          680xx Grundprogramm sdio                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                             SD-Card-Routinen                                *
*******************************************************************************

SDCTL equ $82

*sd1rdbyte MACRO 
*    IFNE NARG-1                       ;if not 1 arguments
*      FAIL ERROR, MAC requires 2 arguments
*      MEXIT
*    ENDC    
* move.b #$FF, spidata.w                 * Dummybyte
*sd1rd1b\@:
* btst.b #0, spictrl.w                   * OK?
* beq.s sd1rd1b\@
* move.b spidata.w, \1
* ENDM


sdtest:                         * Test, ob Laufwerk vorhanden
                                        * d4 enthält Laufwerk
 btst.b #6, keydil(a5)                  * GDP-FPGA da?
 beq.s sdtst00                          * nein, dann Softwarelösung
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
 lea sd1geo(a5), a6                     * Speicher für Grösse...
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
 cmp #512, d0
 bne.s sdtster                          * nicht unterstützte Blockgrösse
 clr.l d0
 lea spicmd10(pc), a2                   * CID Kommando
 move #16, d0                           * 16 Byte
 bsr sdrdblk                            * CID Bytes einlesen
 lea idebuff(a5), a0                    * Puffer zurück
 addq.l #3, a0                          * a0 auch auf Name
 moveq #5-1, d3                         * 5 Bytes
sdtst03:
 move.b (a0)+, (a6)+
 dbra d3, sdtst03
 clr.b (a6)+                            * zum Schluß ne Null
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
 move.b #SDCTL, d2                      * d2 = sdout 20MHz
 move.b #SPIH0_CS, d5                   * d5 = SPI_CS
 lea sd1geo(a5), a6                     * Speicher für Grösse...
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
 cmp #512, d0                          ;; AV patched ;;
 bne.s sd1tster                         * nicht unterstützte Blockgrösse
 clr.l d0
 lea spicmd10(pc), a2                   * CID Kommando
 move #16, d0                           * 16 Byte
 bsr sd1rdblk                           * CID Bytes einlesen
 lea idebuff(a5), a0                    * Puffer zurück
 addq.l #3, a0                          * a0 auch auf Name
 moveq #5-1, d3                         * 5 Bytes
sd1tst05:
 move.b (a0)+, (a6)+
 dbra d3, sd1tst05
 clr.b (a6)+                            * zum Schluß ne Null
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
 move.b 7(a0), d0                       * die nächsten 8 Bit
 lsl.l #8, d0                           * erstmal 8 Bit weiter
 move.b 8(a0), d0                       * hier kommt der Rest
 lsr.l #6, d0                           * wieder 6 Bit zurück
 addq.l #1, d0                          * um 1 erhöhen
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
 move.l d1, sdsize(a6)                  * Grösse (in Sektoren) abspeichern
 moveq.l #1, d1
 asl.l d0, d1
 move d1, d0
 move.w d0, sdbpblk(a6)                 * Bytes pro Block abspeichern
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
 bset d5, d2                          * CS auf high
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
 bset d5, d2                          * SD Disablen
 move.b d2, spictrl.w
 movem.l (a7)+, d3/a0/a2
  rts


sd1init:                        * Initialisieren der SD-Card
 movem.l d3/a0/a2, -(a7)
                                        * min. 74 Clocks an SD
 moveq #16, d3                          * Anzahl 136 Clocks
 bclr d5, d2                          * CS auf high
 move.b d2, spictrl.w
 move.b #$ff, d0                        * dummy Daten
sd1init2:
 bsr sd1wrbyte                          * ein Byte schreiben
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
 bclr d5, d2                          * SD Disablen
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
 DC.w sdok-sdbeftab            * Auf Track 0
 DC.w sdbef1-sdbeftab          * Sektor lesen (d2.l/d3.b/a0.l)
 DC.w sdbef2-sdbeftab          * Sektor schreiben (d2.l/d3.b/a0.l)
 DC.w sdnok-sdbeftab           * Sektor + ECC lesen (d2.l/a0.l)
 DC.w sdnok-sdbeftab           * Sektor + ECC schreiben (d2.l/a0.l)
 DC.w sdok-sdbeftab            * Mode auswählen (d2.b/a0.l)
 DC.w sdok-sdbeftab            * Parameter des Laufwerks lesen (d2.b/d3.b/a0.l)
 DC.w sdok-sdbeftab            * Sektor suchen (d2.l)
 DC.w sdok-sdbeftab            * Laufwerk breit ?
 DC.w sdok-sdbeftab            * Park
 DC.w sdok-sdbeftab            * Unpark
 DC.w sdnok-sdbeftab           * Sektor lesen (d2.l/d3.w/a0.l)
 DC.w sdnok-sdbeftab           * Sektor schreiben (d2.l/d3.w/a0.l)
 DC.w sdnok-sdbeftab           * Buffer lesen (d2.w/a0.l)
 DC.w sdnok-sdbeftab           * Buffer schreiben (d2.w/a0.l)
 DC.w sdok-sdbeftab            * Einheit reservieren (d2.w/d3.w/a0.l)
 DC.w sdok-sdbeftab            * Einheit freigeben (d2.w)
 DC.w sdnok-sdbeftab           * Sektoren schreiben und prüfen (d2.l/d3.w/a0.l)
 DC.w sdnok-sdbeftab           * Sektor prüfen (d2.l/d3.w)
 DC.w sdok-sdbeftab            * Diagnostic senden
 DC.w sdnok-sdbeftab           * Sektor suchen (d2.l)
 DC.w sdok-sdbeftab            * Zähler-Statistik lesen (a0.l)
 DC.w sdbef22-sdbeftab         * Größe der Platte lesen (d2.l/d3.b/a0.l)
 DC.w sdnok-sdbeftab           * Internen Test durchführen
 DC.w sdbef24-sdbeftab         * Laufwerksnamen lesen (a0.l)
 DC.w sdok-sdbeftab            * Liste der Defekte lesen (d2.b/d3.w/a0.l)
 DC.w sdok-sdbeftab            * Neue defekte Blöcke schreiben (a0.l)
 DC.w sdok-sdbeftab            * Fehler lesen
 DC.w sdok-sdbeftab            * Formatieren (d2.b/d3.w/a0.l)


sdcomm:
 cmp #29, d1
 beq sdok                       * keine Eigenen Befehle
 bhi sderr                      * Wert zu gross
 and #$0f, d4
 cmp.b #1, d4                   * SD-Card0?
 bne.s sdc1                     * nö
 lea sd1geo(a5), a6
 bra.s sdc2
sdc1:
 cmp.b #2, d4                   * SD-Card1?
 bne.s sdnok                    * nö
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

sdbeftb1:                      * Tabelle der Befehle für Hardware-SPI
 DC.w sdok-sdbeftb1            * Auf Track 0
 DC.w sd1bef1-sdbeftb1         * Sektor lesen (d2.l/d3.b/a0.l)
 DC.w sd1bef2-sdbeftb1         * Sektor schreiben (d2.l/d3.b/a0.l)
 DC.w sdnok-sdbeftb1           * Sektor + ECC lesen (d2.l/a0.l)
 DC.w sdnok-sdbeftb1           * Sektor + ECC schreiben (d2.l/a0.l)
 DC.w sdok-sdbeftb1            * Mode auswählen (d2.b/a0.l)
 DC.w sdok-sdbeftb1            * Parameter des Laufwerks lesen (d2.b/d3.b/a0.l)
 DC.w sdok-sdbeftb1            * Sektor suchen (d2.l)
 DC.w sdok-sdbeftb1            * Laufwerk breit ?
 DC.w sdok-sdbeftb1            * Park
 DC.w sdok-sdbeftb1            * Unpark
 DC.w sdnok-sdbeftb1           * Sektor lesen (d2.l/d3.w/a0.l)
 DC.w sdnok-sdbeftb1           * Sektor schreiben (d2.l/d3.w/a0.l)
 DC.w sdnok-sdbeftb1           * Buffer lesen (d2.w/a0.l)
 DC.w sdnok-sdbeftb1           * Buffer schreiben (d2.w/a0.l)
 DC.w sdok-sdbeftb1            * Einheit reservieren (d2.w/d3.w/a0.l)
 DC.w sdok-sdbeftb1            * Einheit freigeben (d2.w)
 DC.w sdnok-sdbeftb1           * Sektoren schreiben und prüfen (d2.l/d3.w/a0.l)
 DC.w sdnok-sdbeftb1           * Sektor prüfen (d2.l/d3.w)
 DC.w sdok-sdbeftb1            * Diagnostic senden
 DC.w sdnok-sdbeftb1           * Sektor suchen (d2.l)
 DC.w sdok-sdbeftb1            * Zähler-Statistik lesen (a0.l)
 DC.w sdbef22-sdbeftb1         * Größe der Platte lesen (d2.l/d3.b/a0.l)
 DC.w sdnok-sdbeftb1           * Internen Test durchführen
 DC.w sdbef24-sdbeftb1         * Laufwerksnamen lesen (a0.l)
 DC.w sdok-sdbeftb1            * Liste der Defekte lesen (d2.b/d3.w/a0.l)
 DC.w sdok-sdbeftb1            * Neue defekte Blöcke schreiben (a0.l)
 DC.w sdok-sdbeftb1            * Fehler lesen
 DC.w sdok-sdbeftb1            * Formatieren (d2.b/d3.w/a0.l)


sdok:                           * liefert nur ein OK zurück
 clr.l d0
 bra carres

sdnok:                          * liefert einen Fehler zurück
 moveq #-1, d0
  rts

sderr:                          * liefert Fehler und Carry zurück
 moveq #-1, d0
 bra carset

sdbef1:                         * Sektoren lesen
 move.l d2, d1                  * Sta rtsektor
 and.l #$000000ff, d3           * nur Byte gültig
 bne.s sdb1a                    * falls Null, dann 256
 move.l #256, d3
sdb1a:
 asl.l d0, d1                   * Sta rtsektor *2, falls 1024 BPS
 asl.l d0, d3                   * Anzahl * 2, falls 1024 BPS
sdb1b:
 subq.l #1, d3                  * Anzahl-1 als Zähler
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
 move.l d1, d0                  * Sektor zurück
 bsr sdrdsec                    * Lesen
 addq.l #1, d1                  * nächsten Sektor
 dbra d3, sdb1d
 clr.l d0
 bra.s sdb1ex
sdb1er:
 moveq #-1, d0
sdb1ex:
  rts

sd1bef1:                        * Sektoren lesen Hardware SPI
 move.l d2, d1                  * Sta rtsektor
 and.l #$000000ff, d3           * nur Byte gültig
 bne.s sd1b1a                   * falls Null, dann 256
 move.l #256, d3
sd1b1a:
 asl.l d0, d1                   * Sta rtsektor *2, falls 1024 BPS
 asl.l d0, d3                   * Anzahl * 2, falls 1024 BPS
sd1b1b:
 subq.l #1, d3                  * Anzahl-1 als Zähler
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
 move.l d1, d0                  * Sektor zurück
 bsr sd1rdsec                   * Lesen
 addq.l #1, d1                  * nächsten Sektor
 dbra d3, sd1b1d
 clr.l d0
 bra.s sd1b1ex
sd1b1er:
 moveq #-1, d0
sd1b1ex:
  rts

sdbef2:                         * Sektoren schreiben
 movea.l a0, a1                 * Buffer retten
 move.l d2, d1                  * Sta rtsektor
 and.l #$000000ff, d3           * nur Byte gültig
 bne.s sdb2a                    * falls Null, dann 256
 move.l #256, d3
sdb2a:
 asl.l d0, d1                   * Sta rtsektor *2, falls 1024 BPS
 asl.l d0, d3                   * Anzahl * 2, falls 1024 BPS
sdb2b:
 subq.l #1, d3                  * Anzahl-1 als Zähler
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
 movea.l a1, a0                 * Buffer zurück
 move.l d1, d0                  * Sektor zurück
 bsr sdwrsec                    * Schreiben
 tst.b d0
 dbeq d6, sdb2e                 * Hat nicht geklappt, nochmal
 bmi.s sdb2er                   * Fehler! Abbruch
 addq.l #1, d1                  * nächsten Sektor
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
 move.l d2, d1                  * Sta rtsektor
 and.l #$000000ff, d3           * nur Byte gültig
 bne.s sd1b2a                   * falls Null, dann 256
 move.l #256, d3
sd1b2a:
 asl.l d0, d1                   * Sta rtsektor *2, falls 1024 BPS
 asl.l d0, d3                   * Anzahl * 2, falls 1024 BPS
sd1b2b:
 subq.l #1, d3                  * Anzahl-1 als Zähler
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
 movea.l a1, a0                 * Buffer zurück
 move.l d1, d0                  * Sektor zurück
 bsr sd1wrsec                   * Schreiben
 tst.b d0
 dbeq d6, sd1b2e                * Hat nicht geklappt, nochmal
 bmi.s sd1b2er                  * Fehler! Abbruch
 addq.l #1, d1                  * nächsten Sektor
 adda.l #512, a1                * Buffer auch
 dbra d3, sd1b2d
 clr.l d0
 movea.l a1, a0
 bra.s sd1b2ex
sd1b2er:
 move.l #-1, d0
sd1b2ex:
  rts


sdbef22:                       * Kapazität lesen
 clr.l d2
 move.l SDSIZE(a6), d2          * Grösse a 512 Byte
 clr.l d1
 move sdbpblk(a6), d1           * 512 Byte/Sektor
 lsr.l d0, d2                   * Grösse /2, falls 1024 BPS
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
 clr.b (a1)+                    * löschen
 dbra d3, sdb24a
 move.b #1, 3(a0)               * ??? aus SCSI Bescheibung übernommen
 move.b #$3d, 4(a0)             * ??? aus SCSI Bescheibung übernommen
 move #15-1, d3                 * 15 Byte übertragen
 movea.l a6, a1                 * sd_geo
 adda.l #SDNAME, a1
 adda.l #8, a0
sdb24b:
 move.b (a1)+, (a0)+            * Name kopieren
 dbra d3, sdb24b
  rts


sdwrcmd:                        * Commando-Bytes an SD-Card ausgeben
 movem.l d1/d3/a0/a2, -(a7)
 bset d5, d2                          * CS auf high
 move.b d2, spictrl.w
 move.b #$ff, d0                        * dummy Daten
 bsr sdwrbyte                           * erzeugt 8 Clockzyklen
 bclr d5, d2                          * CS auf low (aktiv)
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
 bclr d7, d2                          * Clock auf low
 move.b d2, spictrl.w
 btst.b d4, spictrl.w                   * Datenbit
 beq.s sdrdbt2                          * Daten low
 bset #0, d0
sdrdbt2:
 bset d7, d2                          * Clock auf high
 move.b d2, spictrl.w
 dbra d3, sdrdbt1
 move (a7)+, sr                 * Staus zurück
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
 bclr d6, d2                          * Bit löschen
 move.b d2, spictrl.w
 bra.s sdwrbt3
sdwrbt2:
 bset d6, d2                          * Bit setzten
 move.b d2, spictrl.w
sdwrbt3:
 bclr d7, d2                          * Clock auf low
 move.b d2, spictrl.w
 bset d7, d2                          * Clock auf high
 move.b d2, spictrl.w
 dbra d3, sdwrbt1
 bset d6, d2                          * Bit wieder auf high
 move.b d2, spictrl.w
 move (a7)+, sr                 * Staus zurück
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
 bsr sdrdbyte                           * dummylesen für Clock
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
 bset d5, d2                          * SD disabled (auch im Fehlerfall!!!)
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
 subq #1, d1                            * d1 als Zähler
sdrdblk2:
 bsr sdrdbyte                           * Datenbyte lesen
 move.b d0, (a0)+                       * in Puffer kopieren
 dbra d1, sdrdblk2
 bsr sdrdbyte                           * Dummy CRC lesen
 bsr sdrdbyte                           * Dummy CRC lesen
 clr d0
sdrdblkx:
 bset d5, d2                          * SD disabled (auch im Fehlerfall!!!)
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
 bclr d5, d2                          * CS auf high
 move.b d2, spictrl.w
 move.b #$ff, d0                        * dummy Daten
 bsr sd1wrbyte                          * erzeugt 8 Clockzyklen
 bset d5, d2                          * CS auf low (aktiv)
 move.b d2, spictrl.w
 moveq #6-1, d3                         * 6 Bytes
sd1wr1cmd:
 move.b (a2)+, d0                       * CMD-Byte
 bsr sd1wrbyte                          * Byte schreiben
 dbra d3, sd1wr1cmd
 moveq #100, d1                         * Timeout
sd1wr2cmd:
 bsr sd1rdbyte                          * ein Byte lesen
* sd1rdbyte d0
 cmp.b #$FF, d0                         * OK?
 bne.s sd1wrxcmd                        * Ja
 dbra d1, sd1wr2cmd
sd1wrxcmd:
 movem.l (a7)+, d1/d3/a0/a2
  rts


sd1rdbyte:                      * liest ein Byte von der SD-Card
* move sr, -(a7)                 * Status sichern   ;; AV Patched ;;
* ori #$0700, sr                 * Interrupts aus
 move.b #$ff, spidata.w                 * Dummybyte
sd1rd1b:
 btst.b #0, spictrl.w                   * OK?
 beq.s sd1rd1b
 move.b spidata.w, d0
* move (a7)+, sr                 * Staus zurück ;; AV Patched ;;
 rts


sd1wrbyte:                      * schreibt ein Byte auf die SD-Card
* move sr, -(a7)                 * Status sichern   ;; AV Patched ;;
* ori #$0700, sr                 * Interrupts aus
 move.b d0, spidata.w                   * Daten ausgeben
sd1wr1byte:
 btst.b #0, spictrl.w                   * Bereit?
 beq.s sd1wr1byte
* move (a7)+, sr                 * Staus zurück ;; AV Patched ;;
  rts


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
 bsr sd1rdbyte                          * dummylesen für Clock
* sd1rdbyte d0
 move.b #$fe, d0                        * Startbyte
 bsr sd1wrbyte                          * senden
 move #512-1, d3                        * 512 Bytes
sd1wr2sec:
 move.b (a0)+, d0                       * Datenbyte
 bsr sd1wrbyte                          * schreiben
 dbra d3, sd1wr2sec
 move.b #$ff, d0                        * dummy CRC
 bsr sd1wrbyte
 move.b #$ff, d0                        * dummy CRC
 bsr sd1wrbyte
 move #100, d3                          * Timeout
sd1wr6sec:
 bsr sd1rdbyte
* sd1rdbyte d0
 and.b #$1f, d0
 cmp.b #$5, d0
 beq.s sd1wr3sec
 dbra d3, sd1wr6sec
 bra.s sd1wrsce                         * Fehler bei Schreibvorgang
sd1wr3sec:
 bsr sd1rdbyte
* sd1rdbyte d0
 cmp.b #$ff, d0                         * wenn busy dann <> $ff
 beq.s sd1wr4sec
 bra.s sd1wr3sec
sd1wr4sec:
 clr.l d0
 bra.s sd1wrscx
sd1wrsce:
 moveq #-1, d0
sd1wrscx:
 bclr d5, d2                          * SD disabled (auch im Fehlerfall!!!)
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
 bsr sd1rdbyte                           * Byte lesen
* sd1rdbyte d0
 cmp.b #$fe, d0                          * auf Startbyte warten
 bne.s sd1rd1blk                         * ACHTUNG bei Fehler Endlosschleife!!!
 subq #1, d1                             * d1 als Zähler
sd1rd2blk:
 bsr sd1rdbyte                           * Datenbyte lesen
 move.b d0, (a0)+                        * in Puffer kopieren
* sd1rdbyte (a0)+

 dbra d1, sd1rd2blk
 bsr sd1rdbyte                           * Dummy CRC lesen
 bsr sd1rdbyte                           * Dummy CRC lesen
* moveq #1,d1
*sd1rd3blk:
* sd1rdbyte d0
* dbra d1,sd1rd3blk
 clr d0
sd1rdxblk:
 bclr d5, d2                           * SD disabled (auch im Fehlerfall!!!)
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


SDSIZE          EQU     0
SDBPBLK         EQU     4
SDART           EQU     6
SDNAME          EQU     8

SPI0_DI         EQU     0               * Eingang (74LS245): DAT/DO der SD
SPI0_CS         EQU     4               * Ausgang (74LS374): CS der SD
SPI0_DO         EQU     0               * Ausgang (74LS374): CMD/DI der SD
SPI0_CLK        EQU     3               * Ausgang (74LS374): CLK/SCLK der SD

SPI1_DI         EQU     2               * Eingang (74LS245): DAT/DO der SD
SPI1_CS         EQU     6               * Ausgang (74LS374): CS der SD
SPI1_DO         EQU     2               * Ausgang (74LS374): CMD/DI der SD
SPI1_CLK        EQU     1               * Ausgang (74LS374): CLK/SCLK der SD

SPIH0_CS        EQU     5               * CS der ersten Hardware SD
SPIH1_CS        EQU     6               * CS der zweiten Hardware SD

spicmd0:        DC.b $40, 0, 0, 0, 0, $95       * Reset
spicmd1:        DC.b $41, 0, 0, 0, 0, $ff       * Initialisierung
spicmd9:        DC.b $49, 0, 0, 0, 0, $ff       * CSD Auslesen
spicmd10:       DC.b $4a, 0, 0, 0, 0, $ff       * CID Auslesen

mmctxt:         DC.b 'MMC-Card ', 0
sdtxt:          DC.b 'SD-Card ', 0
sdhctxt:        DC.b 'SDHC-Card ', 0

 DS.W 0
*******************************************************************************
*                          680xx Grundprogramm ser                            *
*                         (C) 1990 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                 Routinen für die seriellen Schnittstellen                   *
*******************************************************************************


siinit:                         * INIT seriellen Schnittstellen
 btst #4, d0                  * externer Takt bei SER nicht vorhanden,
 beq.s siinit20                 * daher muss es die SER2 sein!
 move.b d0,ser3.w               * Controlregister übertragen
 move.b d1,ser2.w               * Command Register
 rts

siinit20:                       * SER2 initialisieren
 move.l d1, -(a7)
 move.b #$03, ser2e.w           * LEDs ausschalten
 move.b cpu(a5), d1             * fuer Warteschleife
 btst #0, d0
 bne.s siinit30                 * Kanal B initialisieren
 move.b (a0)+, ser21.w          * Setze Baudrate
 bsr siwait
 move.b (a0)+, ser20.w          * Parity, Anzahl Bits
 bsr siwait
 move.b (a0)+, ser20.w          * Stop Bits
 bsr siwait
 move.b (a0)+, ser22.w          * Setze Extent Bit fuer Rx Cha A
 bsr siwait
 move.b (a0)+, ser22.w          * Setze Extent Bit fuer Tx Cha A
 bsr siwait
 move.b (a0)+, ser22.w          * Starte Channel A
 move.l (a7)+, d1
  rts

siinit30:
 move.b (a0)+, ser29.w          * Setze Baudrate
 bsr siwait
 move.b (a0)+, ser28.w          * Parity, Anzahl Bits
 bsr siwait
 move.b (a0)+, ser28.w          * Stop Bits
 bsr siwait
 move.b (a0)+, ser2a.w          * Setze Extent Bit fuer Rx Cha B
 bsr siwait
 move.b (a0)+, ser2a.w          * Setze Extent Bit fuer Tx Cha B
 bsr siwait
 move.b (a0)+, ser2a.w          * Starte Channel B
 move.l (a7)+, d1
  rts

siwait:
 cmp.b #1, d1                   * 68008
 beq.s siwaitex
 nop
 cmp.b #2, d1                   * 68000
 beq.b siwaitex
 nop                            * 68020
 nop
 nop
siwaitex:
  rts

si:                             * Zeichen von serieller Schnittstelle
 cmp.b #1, aktser(a5)
 beq.s si11                     * SER1
 bhi.s si21                     * SER2?
 bra.s siex                     * keine SER!!!
si21:
 cmp.b #2, aktser(a5)
 bhi.s si31                     * SER2 Kanal B
si211:
 btst.b #0, ser21.w             * Stehen Daten in Empfangsfifo Kanal A ?
 beq.s si211                    * nein, warten
 move.b ser23.w, d0             * Byte aus Empfangsfifo holen
 bra.s siex
si31:
 btst.b #0, ser29.w             * Stehen Daten in Empfangsfifo Kanal B ?
 beq.s si31                     * nein, warten
 move.b ser2b.w, d0             * Byte aus Empfangsfifo holen
 bra.s siex
si11:
 btst.b #3,ser1.w
 beq.s si11                     * Warten bis Zeichen vorhanden
 moveq #0,d0
 move.b ser0.w,d0               * Zeichen holen
siex:
  rts

si2:
 cmp.b #1, aktser(a5)
 bhi.s si21                     * SER2?, dann ohne RTS weiter
 bset.b #3,ser2.w               * RTS auf High
si2a:                           * Zeichen von serieller Schnittstelle holen
 btst.b #3,ser1.w               * Prüfen, ob ein Zeichen da ist
 beq.s si2a                     * Versuchen bis OK
 bclr.b #3,ser2.w               * RTS auf Low
 moveq #0,d0                    * Langwort gültig
 move.b ser0.w,d0               * Datenbyte holen
  rts

so:                             * Zeichen an serielle Schnittstelle
 cmp.b #1, aktser(a5)
 beq.s so11                     * SER1
 bhi.s so21                     * SER2?
 bra.s soex                     * keine SER!!!
so21:
 cmp.b #2, aktser(a5)
 bhi.s so31                     * SER2 Kanal B
 btst.b #2, ser21.w             * Ausgaberegister Kanal A leer ?
 beq.s so21                     * Nein -> weiter warten
 move.b d0, ser23.w             * Byte ins Ausgaberegister
 bra.b soex
so31:
 btst.b #2, ser29.w             * Ausgaberegister Kanal B leer ?
 beq.s so31                     * Nein -> weiter warten
 move.b d0, ser2b.w             * Byte ins Ausgaberegister
 bra.b soex
so11:
 btst.b #6,ser1.w               * Warten bis bereit
 bne.s so11
so12:
 btst.b #4,ser1.w               * Warten bis SERbuffer frei ist
 beq.s so12
 move.b d0,ser0.w               * Dann Zeichen ausgeben
soex:
  rts

sists:                          * Prüfen, ob Zeichen von SER vorliegt
 cmp.b #1, aktser(a5)
 beq.s sists11                  * SER1
 bhi.s sists21                  * SER2?
 bra.s sisno                    * keine SER!!! also keine Daten ;)
sists21:
 cmp.b #2, aktser(a5)
 bhi.s sists31                  * SER2 Kanal B
 btst.b #0, ser21.w             * Stehen Daten in Empfangsfifo Kanal A ?
 beq.s sisno                    * nein
 bra.s sisyes
sists31:
 btst.b #0, ser29.w             * Stehen Daten in Empfangsfifo Kanal B ?
 beq.s sisno                    * nein
 bra.s sisyes
sists11:
 btst.b #3,ser1.w               * vorliegt
 beq.s sisno
sisyes:
 moveq #-1,d0                   * Zeichen vorhanden
 rts
sisno:
sosno:
 moveq #0,d0                    * Kein Zeichen
 rts

sosts:                          * Test, ob Zeichen gesendet werden kann
 cmp.b #1, aktser(a5)
 beq.s sosts11                  * SER1
 bhi.s sosts21                  * SER2?
 bra.s sosno                    * keine SER!!! also keine Daten ;)
sosts21:
 cmp.b #2, aktser(a5)
 bhi.s sosts31                  * SER2 Kanal B
 btst.b #2, ser21.w             * Ausgaberegister Kanal A leer ?
 beq.s sosno                    * Nein
 bra.b sosyes
sosts31:
 btst.b #2, ser29.w             * Ausgaberegister Kanal B leer ?
 beq.s sosno                    * Nein
 bra.b sosyes
sosts11:
 btst.b #6,ser1.w
 bne.s sosno
sosyes:
 moveq #-1,d0                   * Zeichen kann gesendet werden
 rts

setser:                         * Der aktuelle SER-Kanal wird gesetzt
 move.l d1, -(a7)
 clr d1
 btst.b #2, ioflag(a5)          * SER da?
 beq.s setser01
 moveq #1, d1
setser01:
 btst.b #3, ioflag(a5)          * SER2 da?
 beq.s setser02
 moveq #3, d1
setser02:
 and d1, d0                     * z.Zt. nur bis Kanal 3
 beq.s setserer                 * kein gültiger Kanal
 cmp.b #1, d0
 bhi.s setser20                 * SER2 ist gemeint
 btst.b #2, ioflag(a5)          * SER da?
 beq.s setserer                 * nein, dann Fehler
 move.b d0, aktser(a5)
 move.b #$03, ser2e.w           * LEDs ausschalten
 bra.s setserex                 * Fertig
setser20:
 btst.b #3, ioflag(a5)          * SER2 vorhanden?
 beq.s setserer                 * nein, dann Fehler
 move.b d0, aktser(a5)
 subq.b #1, d0                  * auf 1 oder 2
 move.b d0, ser2f.w             * und LED an
 addq.b #1, d0                  * wieder herstellen
 bra.s setserex
setserer:
 moveq #-1, d0
setserex:
 move.l (a7)+, d1
  rts

getser:                         * Lade den aktuellen SER-Kanal
 clr d0
 move.b aktser(a5), d0
  rts

s2bd2400:                       * SER2 2400,N,8,1
 DC.b $88, $13, $07, $90, $b0, $15

s2bd9600:                       * SER2 9600,N,8,1
 DC.b $bb, $13, $07, $80, $a0, $15

s2bd19k2:                       * SER2 19k2,N,8,1
 DC.b $cc, $13, $07, $80, $a0, $15

s2bd28k8:                       * SER2 28k8,N,8,1
 DC.b $66, $13, $07, $80, $a0, $15

s2bd57k6:                       * SER2 57k6,N,8,1
 DC.b $77, $13, $07, $80, $a0, $15

s2bd115k:                       * SER2 115k,N,8,1
 DC.b $88, $13, $07, $80, $a0, $15
*******************************************************************************
*                          680xx Grundprogramm uhr                            *
*                         (C) 1990 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                             Uhren-Routinen                                  *
*******************************************************************************


uhrinit:
 bsr uhr2init                   * RTC Uhr
 cmp.b #3, uhrausw(a5)
 bne.s uhrinit1                 * nächste Uhr
 bset.b #2, keydil(a5)          * soll ja auch ohne DIL-Key laufen :-P
 bra.s uhrinitx
uhrinit1:                       * Ab hier "normal" weiter
 move.b keydil(a5), d0          * DIL-Schalter holen
 lsr.b #2, d0                   * Bit 2 nach Bit 0
 and.b #1, d0                   * Nur Bit 0 übriglassen
 move.b d0, uhrausw(a5)         * Bestimmung, ob Uhrenbaugruppe vorhanden ist
 beq.s uhrinitx                 * keine Uhr
 bsr swinit                     * sonst Smart-Watch oder Uhr(E050)
uhrinitx:
  rts

swinit:                         * Smart-Watch Identifizierung/Initialisierung
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
 suba.l a0, a0                  * Von Null an suchen
 clr uhradr(a5)                 * Adressenmerker
 move.l #$5ca33ac5, d0          * Wert für Uhrerkennung
 moveq #128-1, d1               * Adressbereich, der durchsucht werden muß
swinit1:
 bsr ramchk                     * Smart-Watch muß unter Ram liegen
 bcs.s swinit4                  * Kein Ram, dann weiter
 move.b (a0), d2                * Wert merken, damit kein Ram zerstört wird
 moveq #64-1, d3                * 64 Bit-Muster
swinit2:
 move.b d0, (a0)                * Bit übertragen
 ror.l #1, d0                   * Nächstes Bit
 dbra d3, swinit2
 moveq #8*8-1, d3
swinit3:
 cmp.b #$8a, (a0)               * Wenn einmal nicht $8a, dann Uhr vorhanden
 bne.s swinit6                  * Sonst Uhr nicht vorhanden
 dbra d3, swinit3
 move.b d2, (a0)                * Ram zurück
swinit4:
 adda.l #8*1024*cpu, a0         * 8*cpu Kbyte weiter
 addq #cpu, uhradr(a5)          * Uhradresse zeigt im Abstand von 8*cpu Kbyte an
 dbra d1, swinit1               * Schleife
 move (a7)+, sr                 * Staus zurück
  rts
 
swinit5:
 tst.b (a0)                     * Nur abfragen, damit Smart-Watch ausgeschaltet
swinit6:                        * wird
 dbra d3, swinit5
 move.b d2, (a0)                * Reparieren
 move.b #2, uhrausw(a5)         * Merker für Smart-Watch
 move (a7)+, sr                 * Staus zurück
  rts

uhr2init:
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
 clr.b uhrausw(a5)              * noch keine Uhr
 move.b #$0b, rtcreg.w
 move.b #$03, rtcdat.w          * BCD und Co
 bsr uwait                      * ein bisschen warten
 move.b #$7f, rtcreg.w          * RAM Adr. $7F zum testen
 move.b rtcdat.w, d0            * Inhalt sichern
 bsr uwait
 move.b #$7f, rtcreg.w
 move.b #$a5, rtcdat.w          * $A5 erster Testwert
 bsr uwait
 move.b #$7f, rtcreg.w
 cmp.b #$a5, rtcdat             * Stimmt es?
 bne.s u2i01                    * nein -> keine Uhr
 bsr uwait
 move.b #$7f, rtcreg.w
 move.b #$3c, rtcdat.w          * $3C zweiter Testwert
 bsr uwait
 move.b #$7f, rtcreg.w
 cmp.b #$3c, rtcdat.w           * stimmts noch?
 bne.s u2i01                    * nein
 bsr uwait
 move.b #$7f, rtcreg.w
 move.b d0, rtcdat              * Inhalt zurück
 move.b #3, uhrausw(a5)         * die Uhr läuft
u2i01:
 move (a7)+, sr                 * Staus zurück
  rts

***  Uhr E050 Bereich  ***

getuhr:                         * Uhrzeit lesen
 cmp.b #1, uhrausw(a5)          * Baugruppe eingestellt ?
 bhi getuhr1                    * Baugruppe nicht vorhanden, dann weiter
 movem.l d0-d4, -(a7)
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
 moveq #4-1, d1                 * Viermal 1 (0 invers) ausgeben
getuhra:
 clr d0
 bsr.s pulswr                   * Bit ausgeben
 dbra d1, getuhra
 moveq #7-1, d1                 * Dann Daten lesen
getuhrb:
 moveq #8-1, d2                 * Datenbits
 clr d3                         * Ergebnis
getuhrc:
 move.b #4, uhr.w               * CS setzen
 bsr.s uwait
 move.b #6, uhr.w
 bsr.s uwait
 move.b uhr.w, d0               * Ein Bit einlesen
 and.b #1, d0                   * Nur ein Bit
 or.b d0, d3
 ror.b #1, d3                   * Einzelbits einlesen
 dbra d2, getuhrc
 move.b d3, (a0)+               * Byte ablegen
 dbra d1, getuhrb
 clr.b (a0)+                    * Null, damit kompatibel zur Smart-Watch
 clr.b uhr.w                    * CS ausschalten
 move (a7)+, sr                 * Staus zurück
 movem.l (a7)+, d0-d4
  rts

pulswr:
 addq #4, d0
 move.b d0, uhr.w               * CS setzen
 addq #2, d0
 bsr.s uwait
 move.b d0, uhr.w               * Wert ausgeben

uwait:
 moveq #5*cpu, d4               * Ein bißchen warten, da Baugruppe nicht so
uwait0:                         * schnell (Zeit ist CPU-abhängig)
 dbra d4, uwait0
  rts

setuhr:                         * Uhrzeit setzen
 cmp.b #1, uhrausw(a5)          * Baugruppe ?
 bhi setuhr1                    * Keine Uhrenbaugruppe, dann weiter
 movem.l d0-d4, -(a7)
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
 moveq #3-1, d1                 * Start Info
setuhra:
 clr d0
 bsr.s pulswr                   * 0 0 0 ausgeben
 dbra d1, setuhra
 moveq #1, d0                   * 1 danach als
 bsr.s pulswr                   * Kennung
 moveq #7-1, d1                 * Anzahl Bytes
setuhrb:
 moveq #8-1, d2                 * Anzahl Bits
 move.b (a0)+, d3               * Data holen
 not.b d3                       * Invers ausgeben
setuhrc:
 rol.b #1, d3                   * Einzelbits ausgeben
 move.b d3, d0
 and.b #1, d0                   * Nur ein Bit
 bsr.s pulswr                   * ausgeben
 dbra d2, setuhrc               * Alle Bits
 dbra d1, setuhrb               * Alle Bytes
 clr.b uhr.w                    * CS neutral stellen
 addq.l #1, a0                  * Hinter letzten Wert
 move (a7)+, sr                 * Staus zurück
 movem.l (a7)+, d0-d4
  rts

*** Smart-Watch Bereich ***

getuhr1:
 cmp.b #2, uhrausw(a5)          * Smart-Watch ?
 bhi getuhr2                    * Keine Smart-Watch, dann weiter
 movem.l d0-d5/a1, -(a7)
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
 bsr.s uhr1ein                  * Smart-Watch einschalten
getuhr1a:
 clr d4
 moveq #8-1, d1                 * Anzahl Bits
getuhr1b:
 moveq #8-1, d2                 * Anzahl Bytes
 clr d0
getuhr1c:
 move.b (a1), d3                * Bit holen
 and.b #1, d3                   * Nur ein Bit
 or.b d3, d0
 ror.b #1, d0                   * Bit rotieren
 dbra d2, getuhr1c              * Ein Bit gelesen
 move.b uhrtab(pc,d1), d4       * Umkodieren, damit kompatibel zur Baugruppe
 move.b d0, 0(a0,d4)            * Byte ablegen
 dbra d1, getuhr1b
 move.b d5, (a1)                * Byte im Ram reparieren
 addq.l #8, a0                  * Hinter letzten Wert setzen
 move (a7)+, sr                 * Staus zurück
 movem.l (a7)+, d0-d5/a1
  rts

uhr1ein:                        * Smart-Watch einschalten
 moveq #0, d0
 move uhradr(a5), d0            * Adresse der Smart-Watch holen
 moveq #13, d1
 lsl.l d1, d0                   * Im 8 Kbyte Abstand
 movea.l d0, a1                 * Adresse der Uhr berechnet
 move.b (a1), d5                * Wert merken, damit kein Ram zerstört wird
 move.l #$5ca33ac5, d0          * Wert für Erkennung
 moveq #64-1, d1                * 64 Bit-Muster
uhr1eina:
 move.b d0, (a1)                * Bit übertragen
 ror.l #1, d0                   * Nächstes Bit
 dbra d1, uhr1eina
  rts                            * OK, Uhr eingeschaltet

uhrtab:
 DC.b 4,3,2,5,0,1,6,7           * Umkodiertabelle für Kompatibelität

setuhr1:
 cmp.b #2, uhrausw(a5)          * Smart-Watch ?
 bhi setuhr2                    * Keine Smart-Watch, dann weiter
 movem.l d0-d5/a1, -(a7)        * Smart-Watch setzen
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
 bsr.s uhr1ein                  * Uhr einschalten
 clr d4
 moveq #8-1, d2                 * Anzahl Bytes
setuhr1a:
 move.b uhrtab(pc,d2), d4       * Umkodieren (kompatibel zur Baugruppe)
 move.b 0(a0,d4), d1            * Byte holen
 moveq #8-1, d3                 * Anzahl Bits
setuhr1b:
 move.b d1, (a1)                * Bit übertragen
 ror.b #1, d1                   * Nächstes Bit
 dbra d3, setuhr1b
 dbra d2, setuhr1a
 move.b d5, (a1)                * Ram reparieren
 addq.l #8, a0                  * Hinter letzten Wert
 move (a7)+, sr                 * Staus zurück
 movem.l (a7)+, d0-d5/a1
  rts

*** neue Uhr Bereich ***

getuhr2:                        * neue Uhr
 cmp.b #3, uhrausw(a5)          * RTC?
 bne.s getuhrxx                 * keine Uhr
 movem.l d3/a1, -(a7)
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
getuhr2b:
 bsr uwait
 move.b #$0a, rtcreg.w
 move.b rtcdat.w, d3            * RTC bereit?
 bmi.s getuhr2b                 * nein
 move #7-1, d3                  * 7 Byte
 lea uhr2tab(pc), a1
getuhr2a:
 move.b (a1)+, rtcreg.w         * Adresse
 move.b rtcdat.w, (a0)+         * Daten
 bsr uwait                      * etwas warten
 dbra d3, getuhr2a
 clr.b (a0)+                    * keine 1/100 Sekunden
 move (a7)+, sr                 * Staus zurück
 movem.l (a7)+, d3/a1
getuhrxx:
  rts

setuhr2:                        * neue Uhr
 cmp.b #3, uhrausw(a5)          * RTC?
 bne.s setuhrxx                 * keine Uhr
 movem.l d3/a1, -(a7)
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
setuhr2b:
 bsr uwait
 move.b #$0a, rtcreg.w
 move.b rtcdat.w, d3            * RTC bereit?
 bmi.s setuhr2b                 * nein
 move #7-1, d3                  * 7 Byte
 lea uhr2tab(pc), a1
setuhr2a:
 move.b (a1)+, rtcreg.w         * Adresse
 move.b (a0)+, rtcdat.w         * Daten
 bsr uwait                      * etwas warten
 dbra d3, setuhr2a
 addq.l #1, a0                  * keine 1/100 Sekunden
 move (a7)+, sr                 * Staus zurück
 movem.l (a7)+, d3/a1
setuhrxx:
  rts

uhr2tab:
 DC.b $04, $02, $07, $08, $09, $06, $00
 ds 0
*******************************************************************************
*                          680xx Grundprogramm adda                           *
*                         (C) 1990 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                       AD- und DA-Wandler Routinen                           *
*******************************************************************************


getad8:
 movem.l d1/a0,-(a7)            * d0.b = Kanalnummer
 lea adc0816.w,a0               * Adresse
 and #$f,d0                     * Nur Kanal 0 bis 15 erlaubt
 move #cpu, d1
 lsr #1, d1                     * CPU-Wert/2
 beq.s get0ad8                  * 0 = 68008
 lsl d1, d0                     * Kanalnummer mit CPU-Wert multiplizieren
get0ad8:
 clr.b 0(a0,d0)                 * Wandler starten
get1ad8:
 tst.b (a0)                     * Warten bis gestartet
 bpl.s get1ad8
get2ad8:
 tst.b (a0)                     * Warten bis gewandelt
 bmi.s get2ad8
 moveq #0,d0                    * Langwort gültig
 move.b cpu(a0),d0              * Wert holen
 movem.l (a7)+,d1/a0
 rts

getad10:
 clr.b adc1001.w                * Starten des Wandlers
 moveq #0,d0                    * Langwort gültig
get1ad10:
 tst.b adc1001.w                * Warten bis gewandelt
 bne.s get1ad10
 move.b adc1001.w,d0            * Wert holen
 lsl #8,d0
 move.b adc1001+1*cpu.w,d0      * Wert OK
 rts

setda:                          * d1.b = DA Kanal 0   d2.b = DA Kanal 1
 move.b d1,da0802.w
 move.b d2,da0802+1*cpu.w
 rts

setda12:
 move d0,-(a7)                  * Retten
 move.b d0,da12.w               * Kanal 1 LSB
 lsr #8,d0
 move.b d0,da12+1*cpu.w         * Kanal 1 MSB
 move d1,d0
 move.b d0,da12+2*cpu.w         * Kanal 2 LSB
 lsr #8,d0
 move.b d0,da12+3*cpu.w         * Kanal 2 MSB
 move (a7)+,d0                  * Zurück
 rts

getad12:
 move d1,d0                     * In d1 stehen Voreinstellungen
 clr.b ad12+1*cpu.w             * Offset
 and #%11111,d0                 * Nur Kanal und WAIT lassen
 move.b d0,ad12+3*cpu.w         * Einstellen
 clr.b ad12.w                   * Starten
 btst #4,d1                     * WAIT oder Status-Bit ?
 beq.s getad12b                 * Über WAIT-Leitung
getad12a:
 tst.b ad12+2*cpu.w             * Warten bis
 bmi.s getad12a                 * gewandelt
getad12b:
 move.b ad12+1*cpu.w,d0         * MSB holen
 lsl #8,d0
 move.b ad12.w,d0               * LSB holen
 btst #5,d1                     * Offset ?
 beq.s getad12c                 * Ja
 lsl #4,d0                      * Zweierkomplementdarstellung
 asr #4,d0                      * Vorzeichen beachten
getad12c:
 rts
*******************************************************************************
*                         680xx Grundprogramm sound                           *
*                         (C) 1990 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                         Speak- und Sound-Routinen                           *
*******************************************************************************


sprachein:
 clr.b spra0.w                  * Stop
 move.b #$50,spra1.w            * Defaultwerte für sinnvolle Sprache
 move.b #$a8,spra2.w
 move.b #$5c,spra3.w
 move.b #$e9,spra4.w
  rts

speak:
 movem.l d0/a0,-(a7)
 bsr.s sprachein                * Voreinstellungen
 move (a0)+,d0                  * Anzahl laden
 subq #1,d0                     * Wegen DBRA
spk0lp:
 tst.b spra0.w
 bpl.s spk0lp                   * Bit 7 = 1, dann fertig
 move.b (a0)+,spra0.w           * Werte übertragen
 move.b (a0)+,spra1.w
 move.b (a0)+,spra2.w
 move.b (a0)+,spra3.w
 move.b (a0)+,spra4.w
 dbra d0,spk0lp                  * Nächster Wert
 movem.l (a7)+,d0/a0
 rts

speak1:
 movem.l d0/a0,-(a7)
 bsr.s sprachein                * Voreinstellungen
 move (a0)+,d0                  * Anzahl Bytes
 subq #1,d0                     * Wegen Dbra
spk1lp:
 tst.b spra0.w
 bpl.s spk1lp                   * Bit 7 = 1, dann fertig
 move.b (a0)+,spra0.w           * Wert übertragen
 dbra d0,spk1lp                  * Nächster Wert
 movem.l (a7)+,d0/a0
 rts

sound:
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
 move.l d0, -(a7)
 moveq #16-1, d0                * Anzahl der Parameter
 lea 16(a0), a0                 * Von hinten übertragen
sound1:
 move.b d0, snd0.w              * Nummer Port
 move.b -(a0), snd1.w           * Byte übertragen
 dbra d0, sound1
 move.l (a7)+, d0
 move (a7)+, sr                 * Staus zurück
  rts
*******************************************************************************
*                      68000/68010 Grundprogramm hardcopy                     *
*                         (C) 1990 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                       Hardcopy- und Maus-Routinen                           *
*******************************************************************************


hardcopy:                       * Ansteuerung der Hardcopy-Maus-Baugruppe
 cmp.b #3, d0                   * Von FarbGDP nicht unterstützt Unterprogramm
 ble.b hardc01                  * nein
 tst.b gdpcol(a5)               * FarbGDP?
 bne carset                     * Ja, dann Abbruch
hardc01:
 move d0,d7                     * d7 wird zerstört
 and #$f,d7                     * d0 bestimmt das Unterprogramm
 add d7,d7
 move hardctab(pc,d7.w),d7
 jmp hardctab(pc,d7)            * Unterprogramm anspringen

hardctab:                       * Adresstabelle der Unterprogramme
 DC.w relmaus-hardctab          * d0 = %00000000 Maus relativ
 DC.w absmaus-hardctab          * d0 = %00000001 Maus absolut
 DC.w mausaus-hardctab          * d0 = %00000010 Maus rücksetzen
 DC.w setkreuz-hardctab         * d0 = %00000011 Fadenkreuz setzen
 DC.w erakreuz-hardctab         * d0 = %00000100 Fadenkreuz löschen
 DC.w bewkreuz-hardctab         * d0 = %00000101 Fadenkreuz mir Maus steuern
 DC.w getadw-hardctab           * d0 = %00000110 Wert vom Analog-Digital-Wandler
 DC.w putcopy-hardctab          * d0 = %X0000111 Copy bei Ci an oder aus
                                * X = Spezialbit
 DC.w ramcopy-hardctab          * d0 = %XXXX1000 Bildschirm in Speicher
 DC.w ladbild-hardctab          * d0 = %XXXX1001 Speicher auf Bildschirm
 DC.w copy8-hardctab            * d0 = %XXXX1010 Hardcopy auf Drucker 8 Nadeln
 DC.w copy24-hardctab           * d0 = %XXXX1011 Hardcopy auf Drucker 24 Nadeln
 DC.w stdruck8-hardctab         * d0 = %XXXX1100 Standarthardcopy 8 Nalden
 DC.w stdruck24-hardctab        * d0 = %XXXX1101 Standarthardcopy 24 Nadeln
 DC.w druck8-hardctab           * d0 = %00001110 Speicher auf Drucker 8 Nadeln
 DC.w druck24-hardctab          * d0 = %00001111 Speicher auf Drucker 24 Nadeln

relmaus:                        * d0 = Tastencode
 clr d1                         * d1 = Schritte in X-Richtung
 clr d2                         * d2 = Schritte in Y-Richtung

absmaus:                        * d1, d2 enthalten letzte Position der Maus
 jmp mausadr1(a5)

absmaus0:                       * Wenn Default-Maus angesprochen werden soll
 clr.b hardclat.w               * d0 enthält danach Tastencode
 clr.b hardcclr.w               * d1 und d2 enthalten die neue Position
 move.b mrechts.w,d0
 sub.b mlinks.w,d0              * Schritte in X-Richtung
 ext d0
 add d0,d1                      * Auf letzten Wert addiert
 move.b mauf.w,d0
 sub.b mab.w,d0                 * Schritte in Y-Richtung
 ext d0
 add d0,d2                      * Auf letzten Wert addiert
 moveq #0,d0                    * Langwort gültig
 move.b mtast.w,d0              * Maustasten lesen
 rts

mausaus:                        * Maus Register auf Null setzen
 jmp mausadr0(a5)

mausaus0:                       * Rücksprung von mausadr0
 clr.b hardcclr.w               * Zähler auf Null
 rts

bewkreuz:                       * Kreuz mit Maus bewegen
 bsr.s absmaus                  * Absoluten Wert holen
 tst    d1                      * d1 und d2 werden auf den Bildschirmbereich
 bpl.s  bewk0                   * angepasst
 clr    d1
 bra.s   bewk1
bewk0:
 cmp    #512,d1
 bmi.s  bewk1
 move   #511,d1
bewk1:
 tst    d2
 bpl.s  bewk2
 clr    d2
 bra.s   setkreuz
bewk2:
 cmp    #256,d2
 bmi.s  setkreuz
 move   #255,d2
setkreuz:                       * d1, d2 Enthalten Position des Kreuzes
 move d0,-(a7)                  * Keine Randabfrage
 move.b ioflag(a5),d0
 and #1,d0
 neg d0                         * Bei neuer GDP sind die Pixel um 1 verschoben
 add #-1-191,d0
 sub d1,d0
 move.b d0,kreuzlx.w
 ror #8,d0
 move.b d0,kreuzhx.w            * X-Position Kreuz übertragen
 move #-257,d0
 add d2,d0
 move.b d0,kreuzly.w
 ror #8,d0
 move.b d0,kreuzhy.w            * Y-Position Kreuz übertragem
 move (a7)+,d0
 rts

erakreuz:                       * Kreuz wird ausgeblendet
 clr.b kreuzlx.w
 clr.b kreuzhx.w
 clr.b kreuzly.w
 clr.b kreuzhy.w                * Alle Werte auf Null setzen
 rts

getadw:                         * Wert vom AD-Wandler nach d0.b d0.l gültig
 moveq #0,d0                    * Langwort gültig
 move.b hardcad8.w,d0           * Wert holen
 rts

putcopy:                        * Bit 7 = 0 Keine Copy
 and.b #$80,d0                  * Bit 7 = 1 Mit Copy
 lsr.b #1,d0                    * Bit 7 nach Bit 6
 and.b #%10111111,menflag(a5)   * Bit 6 bei menflag löschen
 or.b d0,menflag(a5)            * Bit einfügen
 rts

ramcopy:                        * a0 zeigt auf Speicherplatz
 move d0,d7
 and.b #$f0,d7                  * Mit Extrafunktion ?
 bne.s ramcopy0                 * Ja, dann weiter
 btst.b #0,ioflag(a5)           * Neue GDP ?
 beq.s ramcopy0                 * Nein, dann keine schnelle Hardcopy
 move.l a6,-(a7)                * a6 retten, da im Grafikpaket zerstört
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
 bsr gr1p20                     * Schnelle Hardcopy
 move (a7)+, sr                 * Staus zurück
 movea.l (a7)+,a6               * a6 zurück
  rts

ramcopy0:
 movem.l d1-d6/a0-a1,-(a7)      * d0 ist Spezialcode
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
 move.b #$fe,kreuzly.w          * Bit 4 = Spiegelung an Y=128
 move.b #$ff,kreuzhy.w          * Bit 5 = Spiegelung an X=256
 moveq #63,d1                   * Bit 6 = Invers
ramcopya:                       * Bit 7 = Einsetzen
 moveq #-1,d7
 moveq #63,d2
 sub d1,d2                      * Rechts nach Links
 btst #5,d0
 beq.s ramcopyb
 moveq #1,d7                    * Links nach Rechts
 move d1,d2
ramcopyb:
 lsl #3,d2                      * Mal 8, da 8 Bits pro Zeile geholt werden
 move.b ioflag(a5),d5
 and.b #1,d5
 add.b d5,d2                    * Bei neuer GDP sind die Pixel um 1 verschoben
 neg d2
 sub #192,d2                    * Position des Kreuzes berechnet
 moveq #8-1,d3                  * 8 Punkte pro Durchgang
ramcopyc:
 lea -356(a7),a1                * Ablageadresse
 move d2,d5
 move.b d5,kreuzlx.w
 ror #8,d5
 move.b d5,kreuzhx.w            * X-Position des Kreuzes setzen
 move #256-1,d4                 * 256 Zeilen
ramcopyd:
 tst.b hardclat.w               * Ready-Flag löschen
 move.b (a1),d6                 * Altes Byte holen
ramcopye:
 move.b kreuzhy.w,d5            * Warten bis Punkt gefunden
 bpl.s ramcopye
 lsl.b #2,d5                    * Bildpunkt ins X-Flag schieben
 roxl.b #1,d6                   * Bit einfügen
 move.b d6,(a1)+                * Und ablegen von Oben nach Unten
 dbra d4,ramcopyd                * Nächstes Zeile
 add d7,d2
 dbra d3,ramcopyc                * Nächste Spalte
 lea -356(a7),a1
 moveq #1,d3                    * Von Oben nach Unten
 btst #4,d0
 beq.s ramcopyf
 moveq #-1,d3                   * Von Unten nach Oben
 adda #255,a1
ramcopyf:
 move #256-1,d2                 * 256 Bytes
ramcopyg:
 move.b (a1),d4                 * Byte holen
 adda.l d3,a1                   * Von Oben nach Unten oder umgekehrt
 btst #6,d0
 bne.s ramcopyh
 not.b d4                       * Invers
ramcopyh:
 tst.b d0
 bmi.s ramcopyi                 * Bit 7 gesetzt, dann odern
 move.b d4,(a0)                 * Sonst ins Speicherfeld setzen
 bra.s ramcopyj
ramcopyi:
 or.b d4,(a0)                   * Odern
ramcopyj:
 adda #64,a0                    * Nächste Adresse
 dbra d2,ramcopyg
 suba #64*256-1,a0              * a0 wieder reparieren
 dbra d1,ramcopya
 move (a7)+, sr                 * Staus zurück
 movem.l (a7)+,d1-d6/a0-a1
 bra erakreuz                    * Kreuz ausschalten

ladbild:                        * d0 ist Extracode wie bei Ramcopy
 movem.l d0-d6/a0-a2,-(a7)      * Bit 7 hier XOR-Mode
 move.b xormode(a5),-(a7)       * Funktioniert nur mit erweiterter GDP-Karte
 move.b d0,d7
 rol.b #1,d0                    * Bit für XOR-Mode an richtige Stelle
 and.b #1,d0                    * Nur an oder aus erlaubt
 move.b d0,xormode(a5)          * XOR merken für aktpage
 bsr aktpage                    * Seite einstellen, dabei Color und XOR setzen
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
 lea gdp.w,a1                   * GDP-Basis für WAIT
 lea gdp+$9*cpu.w,a2            * X-Low
 clr.b gdp+$a*cpu.w             * Y-High immer auf Null, da nicht größer als 255
 move #$01ff,d3                 * Anfang links
 moveq #1,d1                    * Richtung positiv
 btst #5,d7                   * Spiegelung X ?
 beq.s ladbild0
 moveq #0,d3                    * Anfang rechts
 moveq #-1,d1                   * Richtung negativ
ladbild0:
 move d3,d4
 lsr #8,d4                      * X-High
 move.b d4,gdp+$8*cpu.w
 moveq #0,d4                    * Anfang oben
 moveq #-1,d2                   * Richtung negativ
 btst #4,d7                   * Spiegelung Y ?
 beq.s ladbild1
 moveq #-1,d4                   * Anfang unten
 moveq #1,d2                    * Richtung positiv
ladbild1:
 lsl #2,d7                      * Invers Bit jetzt Bit 8
 move.b d3,d7                   * X-Low nach d7
 move.b d4,gdp+$b*cpu.w         * Y-Low
 move #256-1,d3                 * 256 Reihen
ladbild2:
 btst.b #2,(a1)                 * Warten
 beq.s ladbild2
 add.b d2,gdp+$b*cpu.w          * Eine Reihe weiter
 moveq #2-1,d4                  * X geteilt in zwei Hälften wegen 256-Grenze
ladbild3:
 btst.b #2,(a1)                 * Warten
 beq.s ladbild3
 eori.b #1,gdp+$8*cpu.w         * Hälfte ändern
 moveq #8-1,d5                  * 8*32*2 = 512
ladbild4:
 move.l (a0)+,d0                * 32 Pixel
 btst #8,d7
 beq.s ladbild5                 * Invers  ?
 not.l d0                       * Ja
ladbild5:
 moveq #32-1,d6                 * 32 Bits
ladbild6:
 add.b d1,d7
 btst d6,d0                   * Test, ob Punkt gesetzt
 beq.s ladbild8
ladbild7:
 btst.b #2,(a1)                 * Warten
 beq.s ladbild7
 move.b d7,(a2)                 * Neue X-Koordinate
 move.b #$80,(a1)               * Punkte setzen
ladbild8:
 dbra d6,ladbild6
 dbra d5,ladbild4
 dbra d4,ladbild3
 dbra d3,ladbild2
 move.b (a7)+,xormode(a5)       * XOR-Mode zurück
 bsr aktpage                    * Seite und xormode einstellen
 move (a7)+, sr                 * Staus zurück
 movem.l (a7)+,d0-d6/a0-a2      * Register zurück
 rts

nad8tab:                        * Tabelle für den Grafikdruck mit 8 Nadeln
 DC.b $1b,'<'                   * Unidirektionaler Druck für eine Zeile
 DC.b $1b,'A',8                 * Zeilenvorschub auf 8/60 Zoll
 DC.b $1b,'L',0,2               * 8-Punkt-Grafik doppelte Punktdichte
 DC.b $ff                       * Keine Vergrößerung

stdruck8:                       * Hier nur d0 / a0 vorbelegen
 lea nad8tab(pc),a1             * Ausdruck auf RX80-kompatiblen Drucker 8 Nadeln
 bsr.s copy8                    * Ausdruck aufrufen
stdrucka:
 moveq #$1b,d0                  * Zeilenabstand wieder einstellen
 bsr lo2
 moveq #'2',d0                  * auf 1/6 Zoll
 bra lo2

copy8:                          * d0 = Kennung wie bei Ramcopy
 bsr ramcopy                    * wenn aus Bildspeicher gedruckt wird
druck8:                         * sonst einfach Ausdruck aus Speicher ohne d0
 movem.l d0-d6/a2-a4/a6,-(a7)
 movea #8-1,a3                  * 8 Bits pro Zeile (9 Nadeln)
 lea druck8a(pc),a4             * Adresse Ausgaberoutine
 bsr.s drucke                   * Ausgabe
 movem.l (a7)+,d0-d6/a2-a4/a6
 rts

druck8a:                        * Ausgabe mit Vergrößerung X für 9 Nadeln
 bsr lo2
 dbra d2,druck8a
 rts

nad24tab:                       * Druckerbefehle für 24 Nadel-Drucker
 DC.b $1b,'<'                   * Unidirektionaler Druck für eine Zeile
 DC.b $1b,'A',8                 * Zeilenvorschub 8/60 Zoll
 DC.b $1b,'*',40,0,10           * 24 Nadeln sechsfache Dichte
 DC.b %10110011                 * Vergrößerung 4 für X und Y
 ds 0

stdruck24:                      * Ausdruck mit 24 Nadeln, Werte wie stdruck8
 lea nad24tab(pc),a1            * Adresse Druckerbefehle
 bsr.s copy24
 bra.s stdrucka                  * Zeilenabstand wieder einstellen

copy24:                         * d0 = Kennung wie bei Ramcopy
 bsr ramcopy                    * wenn aus Bildspeicher gedruckt wird
druck24:                        * sonst einfach Ausdruck aus Speicher ohne d0
 movem.l d0-d6/a2-a4/a6,-(a7)
 movea #24-1,a3                 * 24 Bits pro Zeile (24 Nadeln)
 lea druck24a(pc),a4            * Adresse Ausgaberoutine
 bsr.s drucke                   * Ausgabe
 movem.l (a7)+,d0-d6/a2-a4/a6
 rts

druck24a:                       * Ausgabe mit Vergrößerung X für 24 Nadeln
 swap d0
 bsr lo2                        * Erstes Byte
 swap d0
 rol #8,d0
 bsr lo2                        * Zweites Byte
 rol #8,d0
 bsr lo2                        * Drittes Byte
 dbra d2,druck24a
 rts

drucke:                         * a0 = Rambereich, a1 = Druckerbefehle
 movea.l a1,a2                  * a3 = Anzahl Bits pro Zeile, a4 = Druckroutine
druckea:
 move.b (a2)+,d0
 bpl.s druckea                  * Endekennung suchen
 move d0,d4
 lsr #4,d4
 and #$7,d4                     * Nur %xxx übrig lassen
 cmp #$7,d4
 bne.s druckeb
 moveq #-1,d4
druckeb:
 addq #1,d4                     * Bereich 0 bis 7 (Für Vergrößerung 1 bis 8)
 and #$7,d0                     * Nur %yyy übrig lassen
 cmp #$7,d0
 bne.s druckec
 moveq #-1,d0
druckec:
 addq #2,d0                     * Bereich 1 bis 8 (Für Vergrößerung 1 bis 8)
 move.l #840,d3
 divu d0,d3
 moveq #0,d7                    * Zeilenzähler
drucked:
 movea.l a1,a2
druckee:
 move.b (a2)+,d0                * Zeileninitialisierung
 bmi.s druckef
 bsr lo2
 bra.s druckee
druckef:
 movea.l a0,a2
 moveq #64-1,d6                 * Anzahl Bytes pro Zeile
druckeg:
 moveq #8-1,d5                  * Anzahl Bits pro Byte
druckeh:
 move a3,d2
 movea.l d7,a6
 moveq #0,d0                    * Alle Bits auf Null
druckei:
 lsl.l #1,d0                    * Weiterschieben
 move.l a6,d1
 divu #840,d1
 cmp #256,d1
 beq.s druckek                  * Außerhalb des Bildschirms
 asl #6,d1                      * Zeilenadresse berechnet
 btst.b d5,0(a2,d1.w)
 beq.s druckej                  * Bit nicht gesetzt, dehalb weiter
 addq #1,d0                     * Bit setzen
druckej:
 adda d3,a6                     * Nächste Zeile
druckek:
 dbra d2,druckei
 move d4,d2                     * Vergrößerung X
 jsr (a4)
 dbra d5,druckeh
 addq.l #1,a2
 dbra d6,druckeg
 bsr locrlf                     * Zeilenvorschub
 move.l a6,d7                   * Neue Zeile
 cmp.l #256*840,d7
 bne.s drucked                  * Bis Ende erreicht
 rts
*******************************************************************************
*                          680xx Grundprogramm clut                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                              Clut-Routinen                                  *
*******************************************************************************


clutinit:                       * CLUT initialisieren
 movem.l a0, -(a7)
 btst.b #6, keydil(a5)          * GDP-FPGA da?
 beq.s clutinex                 * Nein!
 tst.b gdpcol(a5)               * Farbvariante
 beq.s clutinex                 * Nein, dann Ende
 lea cluttab(pc), a0            * Standard Farben
 bsr clut                       * Laden
clutinex:
 movem.l (a7)+, a0
 rts

clut:                           * Farben der CLUT beliebig einstellen
 movem.l d0, -(a7)
 btst.b #6, keydil(a5)          * GDP-FPGA da?
 beq.s clutex                   * Nein
 tst.b gdpcol(a5)               * Farbvariante?
 beq.s clutex                   * Nein, dann Ende
 clr.b cluta.w                  * FPGA-CLUT Adresse 0
 moveq #16-1, d0
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
clut01:
 move.b (a0)+, cluth.w          * FPGA-CLUT Daten high
 move.b (a0)+, clutl.w          * FPGA-CLUT Daten low
 dbra d0, clut01
 move (a7)+, sr                 * Status zurück
clutex:
 movem.l (a7)+, d0
 rts

cluttab:
 DC.w $000                       * 0  Schwarz        RGB 0,0,0
 DC.w $1ff                       * 1  Weiß           RGB 255,255,255
 DC.w $1f8                       * 2  Gelb           RGB 255,255,0
 DC.w $038                       * 3  Grün           RGB 0,255,0
 DC.w $1c0                       * 4  Rot            RGB 255,0,0
 DC.w $007                       * 5  Blau           RGB 0,0,255
 DC.w $1c7                       * 6  Violett        RGB 255,0,255
 DC.w $03f                       * 7  Zyan           RGB 0,255,255
 DC.w $092                       * 8  Dunkelgrau     RGB 64,64,64
 DC.w $124                       * 9  Hellgrau       RGB 128,128,128
 DC.w $0d8                       * 10 Dunkelgelb     RGB 96,96,0
 DC.w $018                       * 11 Dunkelgrün     RGB 0,96,0
 DC.w $0c0                       * 12 Dunkelrot      RGB 96,0,0
 DC.w $003                       * 13 Dunkelblau     RGB 0,0,96
 DC.w $0c3                       * 14 Violett dunkel RGB 96,0,96
 DC.w $01b                       * 15 Zyan dunkel    RGB 0,96,96
*******************************************************************************
*                         680xx Grundprogramm relais                          *
*                         (C) 1990 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                             Relais-Routinen                                 *
*******************************************************************************


relais:                         * In a0 steht Adresse
 movem.l d1/d2,-(a7)            * d0.b = Wert (Jedes Bit bestimmt ein Relais)
 move.l #cpu, d1
 lsr.l #1, d1                   * CPU-Wert/2
 beq.s relais1                  * 68008
 move.l a0, d2                  * Adresse für Berechnung kopieren
 asl.l d1, d2                   * Adresse mit CPU-Wert/2 multiplizieren
 movea.l d2, a0                 * Adresse zurück
relais1: 
 moveq #8-1,d1                  * d0 = 1 aus Tabelle (a1)
relais2:                        * <-- Nur für 68008
 move d1,d2                     * Bit-Nummer
 add d2,d2
 btst d1,d0                     * Bit testen
 beq.s relais3                  * Relais rücksetzen
 addq #1,d2                     * Relais setzen
relais3:
 move.b d2,(a0)                 * Relais einstellen
 dbra d1,relais2
 movem.l (a7)+,d1/d2
 rts

relaisin:                       * Wert vom Port der Relaiskarte lesen
 movem.l d1/d2,-(a7)            * d0.b = Wert (Jedes Bit bestimmt ein Relais)
 move.l #cpu, d1
 lsr.l #1, d1                   * CPU-Wert/2
 beq.s relais1i                 * 68008
 move.l a0, d2                  * Adresse für Berechnung kopieren
 asl.l d1, d2                   * Adresse mit CPU-Wert/2 multiplizieren
 movea.l d2, a0                 * Adresse zurück
relais1i: 
 moveq #0,d0                    * d0.l gültig
 move.b (a0),d0                 * 
 movem.l (a7)+, d1/d2
 rts
*******************************************************************************
*                        680xx Grundprogramm drucker                          *
*                         (C) 1990 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                           Drucker-Ansteuerung                               *
*******************************************************************************


* Druckeransteuerungen

* Für Epson oder kompatiblen Drucker ausgelegt (Befehle können geändert werden)

druckbef:
 DC.b $1b,'@',$ff               * Drucker initialisieren
 DC.b $1b,'l',$ff               * Linker Rand
 DC.b $1b,15,$ff                * Schmaldruck an
 DC.b $1b,'W',1                 * Breitdruck an
 DC.b $1b,'P',$ff               * Pica
 DC.b $1b,'M',$ff               * Elite
 DC.b $1b,'U',0                 * Bidirektional
 DC.b $1b,'U',1                 * Unidirektional
 DC.b $1b,'s',0                 * Normale Druckgeschwindigkeit
 DC.b $1b,'s',1                 * Halbe Druckgeschwindigkeit
 DC.b $1b,'F',$ff               * Fettdruck aus
 DC.b $1b,'E',$ff               * Fettdruck an
 DC.b $1b,'H',$ff               * Doppeldruck aus
 DC.b $1b,'G',$ff               * Doppeldruck an
 DC.b $1b,'p',0                 * Proportionaldruck aus
 DC.b $1b,'p',1                 * Proportionaldruck an
 DC.b $1b,'5',$ff               * Kursivdruck aus
 DC.b $1b,'4',$ff               * Kursivdruck an
 DC.b $1b,9,$ff                 * Papiererkennung an
 DC.b $1b,8,$ff                 * Papiererkennung aus
 DC.b $1b,'R',0                 * Amerikanischer Zeichensatz
 DC.b $1b,'R',2                 * Deutscher Zeichensatz

drbefanz EQU (*-druckbef)/3

drbefinit:                      * Tabelle der Druckerbefehle ins Ram übertragen
 lea druckbef(pc),a0            * Quelle
 lea drbeftab(a5),a1            * Ziel
 moveq #drbefanz*3-1,d7         * 22 Befehle mit je 3 Byte
drbefilp:
 move.b (a0)+,(a1)+             * Übertragen
 dbra d7,drbefilp
 rts

amerdr:                         * Zeichensatz auf amerikanisch
 movem.l d0/d7/a0,-(a7)
 bclr.b #2,dflag0(a5)           * Bit löschen als Merker
 lea drbeftab+3*20(a5),a0
 bsr.s drbeflo                  * Amerikanischer Zeichensatz eingeschaltet
 movem.l (a7)+,d0/d7/a0
 rts

deutdr:                         * Zeichensatz auf deutsch
 movem.l d0/d7/a0,-(a7)
 bset.b #2,dflag0(a5)           * Bit setzen als Merker
 lea drbeftab+3*21(a5),a0
 bsr.s drbeflo                  * Deutscher Zeichensatz eingeschaltet
 movem.l (a7)+,d0/d7/a0
 rts

drbeflo:                        * Einen Befehl übertragen
 moveq #3-1,d7                  * Maximal 3 Byte
drbeflo0:
 move.b (a0)+,d0                * Byte holen
 cmp.b #$ff,d0
 beq.s drbeflo1                 * $ff, dann Ende
 bsr lo2                        * An Drucker
 dbra d7,drbeflo0
drbeflo1:
 rts

initdr:                         * Alle Druckerbefehle initialisieren
 lea drbeftab(a5),a0
 bsr.s drbeflo                  * Druckerinit
 lea drbeftab+3(a5),a0
 bsr.s drbeflo                  * Linker Rand
 move.b dflag3(a5),d0
 bsr lo2
 move.b dflag1(a5),d0
 and.b #3,d0
 beq.s initdr1                  * Kein Breit- oder Schmaldruck
 lea drbeftab+3*2(a5),a0        * Schmaldruck
 btst #1,d0
 beq.s initdr0
 addq.l #3,a0                   * Breitdruck
initdr0:
 bsr.s drbeflo
initdr1:
 lea drbeftab+3*4(a5),a1
 moveq #3-1,d6                  * Pica/Elite
initdr2:                        * Bidirektional/Unidirektional
 movea.l a1,a0                  * Normale Geschwindigkeit/ Langsamer Druck
 moveq #4,d0
 sub d6,d0
 btst.b d0,dflag1(a5)
 beq.s initdr3
 addq.l #3,a0
initdr3:
 bsr.s drbeflo
 addq.l #6,a1
 dbra d6,initdr2
 moveq #5-1,d6                  * Fettdruck aus/an
initdr4:                        * Doppeldruck aus/an
 movea.l a1,a0                  * Proportionaldruck aus/an
 move d6,d0                     * Kursivdruck aus/an
 addq #3,d0                     * Papiererkennung an/aus
 btst.b d0,dflag0(a5)
 beq.s initdr5
 addq.l #3,a0
initdr5:
 bsr.s drbeflo
 addq.l #6,a1
 dbra d6,initdr4
 lea drsave(a5),a0
 moveq #19-1,d7
 bsr drbeflo0                   * Selbstdefinierte Werte übergeben
 btst.b #0,dflag0(a5)
 bne deutdr                     * Deutscher Zeichensatz
 bra amerdr                      * Amerikanischer Zeichensatz oder NDR

*******************************************************************************
*                         680xx Grundprogramm dos2                            *
*                        (C) 1991 Ralph Dombrowski                            *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                               JADOS Teil 2                                  *
*******************************************************************************


*********************** DOS-Funktionen unter JADOS ****************************
*  Zur Anpassung an ein anderes DOS müssen diese Funktionen geändert werden   *
*                             Siehe auch dos1.asm                             *
*******************************************************************************

dostest:                        * Überprüfung, ob Jados initialisiert ist
 cmp #$4ef9,trap6(a5)
 bne    carset                  * NEIN
 moveq  #87,d7                  * SETOVWRT (JADOS-Funktion)
 trap   #6                      * Überschreiben erlaubt
 bra carres                      * JA

fillup:                         * FILLFCB + UPPERCAS
 move.l a0,-(a7)
 lea    einbuf+90(a5),a0
 bsr    fillfcb
 movea.l (a7)+,a0
 rts

getflen:                        * Länge des Files nach d1.l (a0=File)
 bsr.s  fillup
 bcs    doserr0                 * Fehler im Namen
 moveq #19,d7
 trap #6                        * OPEN
 tst.b  d0
 bne    doserr                  * Fehler
 move einbuf+40+26(a5),d1
 mulu #1024,d1
 bra carres                      * OK, aber Motor nicht aus !!!

tload:                          * In a0 steht Zieladresse
 bsr.s  fillup
 bcs    doserr0                 * Fehler im Namen
 move.l stxtxt(a5),-(a7)        * Datei laden
 moveq #9,d7
 trap #6                        * TLOAD
 move.l (a7)+,stxtxt(a5)
 bra     doserr

tsave:                          * a0 = Adresse
 bsr.s  fillup
 bcs    doserr0                 * Fehler im Namen
 moveq #10,d7
 trap #6                        * TSAVE
 bra     doserr


*******************************************************************************
*                          680xx Grundprogramm edit1                          *
*                          (C) 1990 Ralph Dombrowski                          *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                              Editor Teil 1                                  *
*******************************************************************************


blkstart EQU $81                * Zeichen für Blockstart
blkende  EQU $82                * Zeichen für Blockende
blkins   EQU $83                * Zeichen für Ziel

edit:
 move.b optflag(a5),-(a7)       * Schrifart sichern
 move.b cotempo(a5),-(a7)       * Hardscrolltempo sichern
 clr.b cotempo(a5)              * Software-Scroll
 clr.b ausbuf(a5)               * Kein Suchen oder Ersetzen
 and.b #$f9,insl(a5)            * Keine Blockmarkierungen
 move.l stxtxt(a5),akttxt(a5)   * Anfangsadresse
 bsr getscreen                  * Bildschirm holen
editlp:
 bsr ci
 cmp.b #$7f,d0                  * Zeichen für Delete
 bne.s edit2                    * Nein, weiter
 move.b curx(a5),d0
 cmp.b lrand(a5),d0             * Cursor ganz links
 beq editlp                     * Ja, dann kein Löschen
 subq.b #1,curx(a5)             * Cursor zurück
 bsr delchar                    * Zeichen löschen
 bra.s editlp
edit2:
 cmp.b #' ',d0                  * Kleiner als ' ' ?
 bcs.s edit4                    * Dann Ctrl-Zeichen
 btst.b #0,insl(a5)
 beq.s edit3
 bsr inschar                    * Bei Einfügemode Zeichen einfügen
edit3:
 bsr getcode                    * Gegebenenfalls in deutsches Zeichen wandeln
 bsr charoscr                   * Zeichen ausgeben
 cmp.b #'',(a0)                * Wenn $7f am Anfang einer Zeile
 bne.s editlp
 move.b curx(a5),d4             * Dann muß es gelöscht werden
 clr.b curx(a5)
 moveq #' ',d0                  * Falls ein Zeichen eingegeben wird, wird
 bsr charoscr                   * die Zeile automatisch aktiv
 move.b d4,curx(a5)
 bra.s editlp

edit4:
 cmp #27,d0                     * Größer als Ctrl-Z ?
 bhi.s editlp                   * Dann zurück
 add    d0,d0
 move edittab(pc,d0.w),d0
 jsr edittab(pc,d0)             * Unterprogramm aufrufen
 bra.s editlp

edittab:
 DC.w carset-edittab
 DC.w editcta-edittab           * Ctrl-A (Wort links)
 DC.w carset-edittab
 DC.w screenup-edittab          * Ctrl-C (Seite vor)
 DC.w editctd-edittab           * Ctrl-D (Zeichen rechts)
 DC.w editcte-edittab           * Ctrl-E (Zeichen hoch)
 DC.w editctf-edittab           * Ctrl-F (Wort rechts)
 DC.w delchar-edittab           * Ctrl-G (Zeichen löschen)
 DC.w editcts-edittab           * Ctrl-H (Ein Zeichen zurück)
 DC.w editcti-edittab           * Ctrl-I (Auf Tab rechts)
 DC.w editctj-edittab           * Ctrl-J (Befehlsverzeichnis)
 DC.w editctk-edittab           * Ctrl-K (Spezielle Befehle)
 DC.w editctl-edittab           * Ctrl-L (Ctrl-QA und Ctrl-QF wiederholen)
 DC.w editctm-edittab           * Ctrl-M (Carriage Return)
 DC.w editctn-edittab           * Ctrl-N (Zeile einfügen)
 DC.w editcto-edittab           * Ctrl-O (Auf Tab links)
 DC.w editctp-edittab           * Ctrl-P (Zeichensatz ändern)
 DC.w editctq-edittab           * Ctrl-Q (Spezielle Befehle)
 DC.w screendown-edittab        * Ctrl-R (Seite zurück)
 DC.w editcts-edittab           * Ctrl-S (Zeichen links)
 DC.w eraeoln-edittab           * Ctrl-T (Löschen rechts)
 DC.w inschar-edittab           * Ctrl-U (Ein Zeichen einfügen)
 DC.w editctv-edittab           * Ctrl-V (Einfügemode umschalten)
 DC.w editctw-edittab           * Ctrl-W (Zeile ab)
 DC.w editctx-edittab           * Ctrl-X (Cursor runter)
 DC.w editcty-edittab           * Ctrl-Y (Zeile löschen)
 DC.w editctz-edittab           * Ctrl-Z (Zeile hoch)
 DC.w editesc-edittab           * ESC-Funktionen

editcta:                        * Ctrl-A
 move.b lrand(a5),d1
editcta0:
 cmp.b curx(a5),d1              * Cursor am Anfang der Zeile ?
 beq editcts1                   * Ja, dann nur ans Ende der letzen Zeile
 subq.b #1,curx(a5)             * Sonst Cursor zurück
 bsr calccur
 cmp.b #' ',(a2)                * Bei Leerzeichen wiederholen
 beq.s editcta
editcta1:
 cmp.b curx(a5),d1              * Ende, wenn am Zeilenanfang
 beq carset
 subq.b #1,curx(a5)             * Cursor zurück
 cmp.b #' ',-(a2)               * Bis Leerzeichen wiederholen
 bne.s editcta1
                                * Jetzt wieder ein Zeichen nach rechts

editctd:                        * Ctrl-D
 bsr curright                   * Cursor um ein Zeichen nach rechts und testen
 bcs.s editctd1                 * Hinter letzem Zeichen, deshalb nächste Zeile
 rts
editctd1:
 move.b lrand(a5),curx(a5)      * Cursor auf linken Rand
 bra editctx                     * Eine Zeile runter

editcte:                        * Ctrl-E
 tst.b cury(a5)                 * Weiter, wenn Cursor in oberster Zeile
 beq.s editcte1
 subq.b #1,cury(a5)             * Eine Zeile hoch
 bra curtoend                    * Test der Cursorposition
editcte1:
 bsr crtdown                    * Scrollen
 bra curtoend                    * Test der Cursorposition

editctf:                        * Ctrl-F
 bsr curright                   * Cursor um ein Zeichen nach rechts und testen
 bcs.s editctd1                 * Hinter letztem Zeichen, dann auf nächste Zeile
 bra.s editctf2                  * Anfang Wort rechts suchen
editctf1:
 bsr curright                   * Cursor ein Zeichen nach rechts und testen
 bcs adjcurx                    * Ja, dann Endetest
editctf2:
 bsr calccur                    * Zeileninfo holen
 cmp.b #' ',(a2)
 beq.s editctf1                 * Suchen bis kein Leerzeichen mehr
 cmp.b #' ',-1(a2)
 beq carset                     * Leerzeichen vor Zeichen, dann OK
editctf3:
 bsr curright                   * Cursor ein Zeichen nach rechts und testen
 bcs adjcurx                    * Endetest, wenn hinter letztem Zeichen
 cmp.b #' ',1(a2)               * Wenn Leerzeichen folgt, dann von vorne
 bne.s editctf3                 * Sonst suchen, bis Leerzeichen
 bra.s editctf

editcti:                        * Ctrl-I (Tab)
 lea    edittabs+1(a5),a0       * Adresse der Tabs
 moveq  #0,d0
 move.b curx(a5),d0             * Cursorposition
 adda.l d0,a0                   * Adresse des Tab
 clr    d1                      * Zähler für Sprung
editcti0:
 addq   #1,d1                   * 1 weiter
 addq   #1,d0                   * Nächste Position
 cmp    #80,d0
 bne.s  editcti1                * Weiter, wenn nicht hinten
 rts
editcti1:
 tst.b  (a0)+
 bpl.s  editcti0                * Weitersuchen, da nicht Tab
 btst.b #0,insl(a5)             * Einfügemode an ?
 beq.s editcti3                 * Nein, weiter
 move   d1,d0
editcti2:
 bsr inschar                    * Zeichen einfügen
 subq #1,d0
 bne.s editcti2                 * Bis Null erreicht
editcti3:
 add.b d1,curx(a5)              * Neue Cursorposition
 bra adjcurx                     * Zeilenende-Test

editctj:                        * HELP
 moveq #%00110011,d0
 bsr setpage                    * Seite 3 zeigen
 bsr editci                     * Auf Taste warten
 bra aktpage                     * Alte Seite

editctk:                        * Extrafunktionen
 bsr ci
 and #%11111,d0                 * Ctrl, Groß und Kleinschreibung erlaubt
 cmp #26,d0
 bhi carset                     * Größer als 26 geht nicht
 add    d0,d0
 move edctktab(pc,d0.w),d0
 jmp edctktab(pc,d0.w)           * Unterprogramm aufrufen

edctktab:
 DC.w carset-edctktab
 DC.w editka-edctktab           * Assembleraufruf (Nicht sinnvoll bei DOS)
 DC.w editkb-edctktab           * Block-Anfang markieren
 DC.w editkc-edctktab           * Block kopieren
 DC.w editkd-edctktab           * Block drucken
 DC.w carset-edctktab
 DC.w editkf-edctktab           * Einstellungen speichern
 DC.w editkg-edctktab           * Einstellungen laden
 DC.w markeweg-edctktab         * Marken löschen
 DC.w editki-edctktab           * Inhaltsverzeichnis
 DC.w carset-edctktab
 DC.w editkk-edctktab           * Block-Ende markieren
 DC.w editkl-edctktab           * Block von Disk lesen
 DC.w carset-edctktab
 DC.w carset-edctktab
 DC.w carset-edctktab
 DC.w editkp-edctktab           * Fontdaten laden
 DC.w editkq-edctktab           * Ende
 DC.w editkr-edctktab           * Block lesen
 DC.w editks-edctktab           * Block auf Disk speichern
 DC.w editkt-edctktab           * Text auf Disk
 DC.w carset-edctktab
 DC.w editkv-edctktab           * Block verschieben
 DC.w editkw-edctktab           * Block speichern
 DC.w editkx-edctktab           * Ende
 DC.w editky-edctktab           * Block löschen

editka:                         * Assembleraufruf
 bsr putscreen                  * Bildschirm abspeichern
 bsr assemble                   * Assembler aufrufen
 scs.b d7                       * Carry-Flag merken
 clr.b ausbuf(a5)               * Nach Assembleraufruf kein ^L mehr
 bsr editci
 tst.b d7
 bne editqr1                    * Assembler wurde abgebrochen
 tst errcnt(a5)                 * Wenn kein Fehler, dann Ende
 beq.s editka1
 movea.l errzeile(a5),a0        * Zeiger auf Fehler nach akttxt
 cmp.b #$a,(a0)+
 beq.s editka0                  * OK, $a übersprungen
 subq.l #1,a0                   * Es war nicht $a
editka0:
 move.l a0,akttxt(a5)           * Adresse merken
 bra getscreen                   * Fehlerhafte Zeile ist erste Zeile im Screen

editka1:
 addq.l #4,a7                   * Stack reinigen
 bsr editkx1
 move.b (a7)+,cotempo(a5)       * Alte Geschwindigkeit
 move.b (a7)+,optflag(a5)       * Schrifart wiederherstellen
 bra carset                      * Editor mit KA verlassen

editkb:                         * Block-Anfang setzen
 btst.b #1,insl(a5)             * Marke schon gesetzt ?
 beq.s editkb1                  * Nein, weiter
 bsr markeweg                   * Sonst alle Marken entfernen
editkb1:
 bset.b #1,insl(a5)             * Merker, daß Marke gesetzt
 moveq #blkstart,d0             * Zeichen für Block-Anfang
 bsr inschar                    * Zeichen einfügen
 bra charoscr                    * Zeichen ausgeben

editkc:
 bsr.s editkc0                  * Block kopieren
 bcs carset
 cmpa.l a2,a3                   * Blockmarken hinter Screen
 bls.s editkc6                  * Ja, dann OK
 subq.l #2,a3                   * Sonst akttxt erniedrigen, da zwei Zeichen
editkc6:                        * entfernt werden
 move.l a1,akttxt(a5)           * Ziel
 lea 1(a1),a0                   * Block-Marke
 bsr clrram                     * Anfangsmarke vom Originalblock löschen
 lea -1(a2),a0                  * Ziel
 subq.l #2,a2                   * Block-Marke
 move.l a2,akttxt(a5)
 bsr clrram                     * Endmarke vom Originalblock löschen
 bra editkv1                     * akttxt in Ordnung bringen und Screen lesen

editkc0:                        * Block kopieren
 move.b insl(a5),d0
 and.b #%110,d0
 cmp.b #%110,d0
 bne carset                     * Kein Block markiert
 bsr editadr                    * Adresse des Cursors holen
 move.b curx(a5),-(a7)
 move.b cury(a5),-(a7)
 bsr savescreen                 * Screen in Speicher
 bsr getblock                   * Block-Adressen holen
 bcs editkc5                    * Fehler
 addq.l #1,a2                   * Blockende-Marke auch mit nehmen
 cmpa.l a3,a1                   * Wenn Ziel innerhalb des
 bpl.s editkc1                  * Blocks liegt
 cmpa.l a3,a2                   * so erfolgt
 bpl.s editkc5                  * Abbruch
editkc1:
 addq.l #4,a7                   * a1 = Anfang
 move.l a3,akttxt(a5)           * a2 = Ende
 move.l a2,d0                   * a3 = Ziel
 sub.l a1,d0                    * Anzahl der einzufügenden Zeichen
 cmp.b #blkins,(a3)             * Wenn Ins-Marke vorhanden ist, wird ein Zeichen
 bne.s editkc2                  * weniger eingefügt, so daß Ins-Marke
 subq.l #1,d0                   * automatisch verschwindet
editkc2:
 cmpa.l a2,a3                   * Wenn Ziel vor dem Block liegt, so werden
 bhi.s editkc3                  * die Blockadressen verschoben, da sie ja
 adda.l d0,a1                   * durchs Einfügen verschoben werden
 adda.l d0,a2
editkc3:
 move.l d0,d1                   * Anzahl der Zeichen nach d1
 bsr einschub                   * Einfügen
 movea.l a1,a0                  * Quelle
editkc4:
 move.b (a0)+,(a3)+             * Übertragen
 cmpa.l a0,a2                   * Bis Ende Block erreicht ist
 bhi.s editkc4
 bra carres                      * OK, alles richtig ausgeführt
                                * Ist wichtig für editkv und editkc
editkc5:
 cmp.b #blkins,(a3)             * 'blkins' an aktueller Stelle ?
 bne editkw3                    * Nein, weiter
 move.b #' ',(a3)               * Ja, deshalb mit Leerzeichen überschreiben
 bra editkw3                     * Ende

editkd:                         * Block drucken
 move.b insl(a5),d0
 and.b  #%110,d0
 cmp.b  #%110,d0
 bne    carset                  * Kein Block markiert
 move.b curx(a5),-(a7)
 move.b cury(a5),-(a7)
 bsr savescreen                 * Screen in Speicher
 bsr getblock                   * Block-Adressen holen
 lea    1(a1),a0                * Von dort ab drucken
 move.l stxtxt(a5),-(a7)
 move.l a0,stxtxt(a5)           * Anfang des Textes nicht ändern
 clr.b  (a2)
 bsr    drmenr                  * Ausdrucken mit Einstellungen
 bsr    locrlf                  * Eine Zeile Vorschub
 move.b #blkende,(a2)
 move.l (a7)+,stxtxt(a5)
 bra     editkw3

editkf:                         * Einstellungen speichern
 bsr    dostest                 * DOS vorhanden ?
 bcs    carset
 lea    saeddt1(pc),a0          * Frage-Text
 bsr    editabuf
 bcs    edits1buf               * Fehler bei der Eingabe
 bsr    saveed0                 * Abspeichern
 bra     edits1buf               * Alte Seite

editkg:                         * Einstellungen laden
 bsr    dostest
 bcs    carset
 lea    loeddt1(pc),a0
 bsr    editabuf
 bcs    edits1buf
 move.b curx(a5),-(a7)          * Position merken
 move.b cury(a5),-(a7)
 bsr    savescreen              * Screen abspeichern
 lea    einbuf+90(a5),a0
 bsr    loaded0                 * Laden
 bra editkw3                     * Screen wieder holen

editki:
 bsr dostest                    * Test, ob DOS vorhanden
 bcs carset
 lea disktxt(pc),a0
 bsr editabuf                   * Laufwerk holen
 bcs edits1buf                  * Dann Ende
 move.b curx(a5),-(a7)
 move.b cury(a5),-(a7)
 bsr savescreen                 * Screen abspeichern
 lea    einbuf+90(a5),a1
 bsr catalog                    * Inhaltsverzeichnis ausgeben
 bra editkw3                     * Screen wieder holen

editkk:                         * Block-Ende markieren
 btst.b #2,insl(a5)             * Marke gesetzt ?
 beq.s editkk1                  * Nein, weiter
 bsr markeweg                   * Ja, alle Marken löschen
editkk1:
 bset.b #2,insl(a5)             * Merker, daß Marke gesetzt
 moveq #blkende,d0              * Zeichen für Block-Ende
 bsr inschar                    * Zeichen einfügen
 bra charoscr                    * Marke ausgeben

editkl:                         * Block von Disk lesen
 bsr dostest                    * Test, ob DOS vorhanden
 bcs carset
 lea nametxt2(pc),a0
 bsr editabuf                   * Namen des Files holen
 bcs edits1buf                  * Fehler
 bsr getflen                    * Länge des Files holen
 bcs edits1buf                  * Fehler
 bsr editadr                    * Adresse des Cursors holen
 lea 0(a3,d1.l),a2              * Endadresse des einzufügenden Bereichs
 move.l d1,d7
 bsr putscreen                  * Screen in Speicher
 move.l a3,akttxt(a5)           * Ziel des Blocks ist akttxt
 move.l d7,d0
 bsr einschub                   * Einfügen
 movea.l a3,a0                  * Ziel
 bsr tload                      * Block laden
 movea.l a3,a0                  * Alte Adresse
 bcs.s editkl2                  * Fehler
editkl1:
 tst.b (a0)+                    * Ende-Null suchen
 bne.s editkl1                  * Schleife
 subq.l #1,a0                   * Ein Zeichen weniger wegen (a0)+
editkl2:
 move.l a0,akttxt(a5)           * Ist jetzt aktuelle Adresse
 movea.l a2,a0                  * Von dort an schieben, wurde oben berechnen
 cmp.b #blkins,(a0)             * Wenn Ins-Marke gesetzt,
 bne.s editkl3                  * dann ein Zeichen mehr löschen,
 addq.l #1,a0                   * dann ist Ins-Marke gelöscht
editkl3:
 bsr clrram                     * Löschen
 lea 1(a3),a0                   * Adresse, wo Block eingefügt wurde
 bsr ptzurueck                  * An Anfang der Zeile
 move.l a0,akttxt(a5)           * Ist aktuelle Adresse
 bra getscreen                   * Screen holen

editkp:                         * Font laden
 bsr    dostest
 bcs    carset
 lea    loftdt1(pc),a0
 bsr    editabuf
 bcs    edits1buf
 move.b curx(a5),-(a7)          * Position merken
 move.b cury(a5),-(a7)
 bsr    savescreen              * Screen abspeichern
 lea    einbuf+90(a5),a0
 bsr    loadft0                 * Laden
 bra editkw3                     * Screen wieder holen

editkq:                         * Ende
 addq.l #4,a7                   * Stack reinigen
 bsr editkx0
 move.b (a7)+,cotempo(a5)       * Alte Scroll-Geschwindigkeit
 move.b (a7)+,optflag(a5)       * Schriftart wiederherstellen
 moveq #$ff,d0                  * Kennung für KQ
 bra carres

editkr:                         * Block lesen
 lea quelltxt(pc),a0
 bsr editzahl                   * Adresse holen
 bcs carset                     * Fehler
 cmp.l stxtxt(a5),d0            * Liegt Quelladresse innerhalb
 bmi.s editkr0                  * des Editorbereichs ?
 cmp.l etxtxt(a5),d0            * Wenn ja, dann Ende
 bmi carset
editkr0:
 movea.l d0,a4
 tst.b (a4)                     * Wenn leer, dann Ende
 beq carset
 bsr editadr                    * Adresse Cursorposition holen
 bsr putscreen                  * Screen im Ram ablegen
 movea.l a4,a0
editkr1:
 tst.b (a0)+                    * Länge des Quellblocks feststellen
 bne.s editkr1                  * Bis Null
 suba.l a4,a0                   * Länge des Blocks
 move.l a0,d0                   * Nach d0
 subq.l #1,d0                   * -1 wegen (a0)+
 cmp.b #blkins,(a3)             * Ins-Marke gesetzt ?
 bne.s editkr2                  * Nein, dann weiter
 subq.l #1,d0                   * Sonst 1 Byte weniger einfügen, dann ist
editkr2:                        * Ins-Marke verschwunden
 tst.l d0
 beq.s editkr3                  * Nichts einfügen
 move.l a3,akttxt(a5)           * Ziel
 bsr einschub                   * Einfügen
editkr3:
 lea 1(a3),a0                   * Ziel
 bsr ptzurueck                  * Adresse auf Anfang der Zeile
 move.l a0,akttxt(a5)           * Adresse merken
editkr4:
 move.b (a4)+,d0                * Übertragen Quelle nach d0
 beq getscreen                  * Wenn Null, dann Screen holen
 move.b d0,(a3)+                * Wert in Editor eintragen
 bra.s editkr4                   * Schleife

editks:                         * Block auf Diskette schreiben
 bsr dostest                    * Test, ob DOS vorhanden
 bcs carset
 move.b insl(a5),d0
 and.b #%110,d0
 cmp.b #%110,d0
 bne carset                     * Ende, da kein Block markiert ist
 bsr savescreen                 * Screen in Speicher
 move.b curx(a5),-(a7)
 move.b cury(a5),-(a7)
 bsr getblock                   * Blockadressen holen
 bcs editkw3
 addq.l #1,a1                   * Anfangsmarke nicht mit abspeichern
 clr.b (a2)                     * Ende
 movea.l a1,a3                  * Anfang
 lea nametxt1(pc),a0
 bsr editabuf                   * Namen des Files holen
 bcs.s editks1                  * Fehler
 movea.l a3,a0                  * Adresse
 bsr tsave                      * Speichern (Fehlermeldung erfolgt direk)
editks1:
 move.b #blkende,(a2)           * Endemarke wieder setzen
 bra editkw3                     * Screen einrichten

editkt:                         * Sicherheitskopie auf Diskette
 bsr dostest                    * Test, ob DOS vorhanden
 bcs carset
 lea nametxt1(pc),a0
 bsr editabuf                   * Namen holen
 bcs edits1buf
 move.b curx(a5),-(a7)
 move.b cury(a5),-(a7)
 bsr savescreen                 * Screen in Speicher
 bsr markrweg                   * Marken entfernen
 movea.l stxtxt(a5),a0          * Dort ist Anfang Text
 bsr tsave                      * Abspeichern (Fehlermeldung erfolgt direkt)
 bra editkw3

editkv:                         * Block verschieben
 bsr editkc0                    * Block kopieren
 bcs carset
 move.l a1,akttxt(a5)
 movea.l a2,a0
 bsr clrram                     * Alten Block löschen
 cmpa.l a2,a3
 bls.s editkv1                  * Wenn gelöschter Block hinter Screen, dann OK
 suba.l d1,a3                   * Sonst akttxt verschieben
editkv1:
 lea 1(a3),a0
 suba.l d1,a0
 bsr ptzurueck                  * Pointer auf Anfang Block
 move.l a0,akttxt(a5)
 bra getscreen                   * Screen holen

editkw:                         * Block speichern
 move.b insl(a5),d0
 and.b #%110,d0
 cmp.b #%110,d0
 bne carset                     * Ende, da kein Block markiert ist
 bsr savescreen                 * Screen in Speicher
 move.b curx(a5),-(a7)
 move.b cury(a5),-(a7)
 bsr getblock                   * Blockadressen holen
 bcs.s editkw3                  * Fehler
 lea 1(a1),a3                   * a3 ist Anfang Block
 subq.l #1,a2                   * Ende Block
 cmpa.l a2,a3
 bhi.s editkw3                  * Block ist leer oder falsch markiert
 lea zieltxt(pc),a0
 bsr editzahl                   * Zieladresse holen
 bcs.s editkw3                  * Fehler
 movea.l d0,a0
 cmp.l stxtxt(a5),d0            * Liegt Zieladresse innerhalb
 bmi.s editkw1                  * des Editorbereichs ?
 cmp.l etxtxt(a5),d0            * Wenn ja, dann Ende
 bmi.s editkw3
editkw1:
 add.l a2,d0                    * Ende des Blocks bestimmen
 sub.l a3,d0                    * Ende Block, wenn abgespeichert
 cmp.l stxtxt(a5),d0            * Liegt Ende des Blocks im Editorbereich ?
 bmi.s editkw2                  * Ja, dann auch Ende
 cmp.l etxtxt(a5),d0
 bmi.s editkw3
editkw2:
 move.b (a3)+,(a0)+             * Übertragen
 cmpa.l a3,a2                   * Bis Ende Block
 bpl.s editkw2
 clr.b (a0)                     * Ende setzen
editkw3:
 bsr getscreen                  * Screen holen
 move.b (a7)+,cury(a5)          * Alte Cursorposition
 move.b (a7)+,curx(a5)
 bra carset                      * Fehleranzeige für editkv

editkx:                         * Ende
 addq.l #4,a7                   * Stack reinigen
 bsr.s editkx0
 move.b (a7)+,cotempo(a5)       * Alte Scroll-Geschwindigkeit
 move.b (a7)+,optflag(a5)       * Schrifart wiederherstellen
 moveq #0,d0                    * Kennung für KX
 bra carres

editkx0:
 bsr putscreen                  * Screen in Speicher
 bsr initdebug                  * Debug neu initialisieren
editkx1:
 bsr clrall                     * Immer Bildschirm löschen
 clr.b curon(a5)                * Kein Cursor aktiv
 clr.b flip(a5)                 * Keine Seitenumschaltung
 bra markrweg                    * Marken im Ram entfernen

editky:                         * Block löschen
 move.b insl(a5),d0
 and.b #%110,d0
 cmp.b #%110,d0
 bne carset                     * Ende, wenn kein Block vorhanden
 move.b curx(a5),-(a7)
 move.b cury(a5),-(a7)
 bsr savescreen                 * Screen in Speicher
 bsr getblock                   * Blockadressen holen
 bcs.s editkw3                  * Fehler
 addq.l #4,a7                   * Cursorposition ist unwichtig
 move.l a1,akttxt(a5)
 addq.l #1,a2                   * Endemarke auch löschen
 movea.l a2,a0
 bsr clrram                     * Block löschen
 movea.l akttxt(a5),a0
 addq.l #1,a0
 bsr ptzurueck                  * An Blockanfang setzen
 move.l a0,akttxt(a5)           * akttxt setzen
 and.b #%11111001,insl(a5)      * Keine Block-Marken mehr vorhanden
 bra getscreen                   * Screen holen

editctl:                        * QA und QF wiederholen
 tst.b ausbuf(a5)
 beq carres                     * Kein Ctrl-L
 tst.b ausbuf+90(a5)            * Ersetzeflag Null ?
 beq suchedit                   * Dann nur suchen
 bra sucherse                    * Sonst Suchen und Ersetzen

editctm:                        * Ctrl-M (CR)
 bsr editctx
 btst.b #0,insl(a5)
 bne.s editctn                  * Zeile einfügen, da Einfügemode an ist
editqs:                         * An Zeilenanfang
 btst.b #4,insl(a5)
 beq.s editctm3                 * Ende, wenn ohne Autotab
 move.b cury(a5),d2             * Auf Cursorzeile
editctm0:
 move.b lrand(a5),curx(a5)      * Ab dort suchen
 move.b d2,d0
 bsr getline                    * Zeileninfo holen
 cmp.b #$7f,(a2)
 beq.s editctm2                 * Wenn Leerzeile
 move.b (a1),d0                 * Maximale Zeichenzahl
editctm1:
 cmp.b #' ',(a2)+               * Ende, wenn kein Leerzeichen
 bne.s editctm4
 addq.b #1,curx(a5)             * Nach rechts
 cmp.b curx(a5),d0
 bhi.s editctm1                 * Weiter, wenn noch nicht Zeilenende
editctm2:
 subq.b #1,d2
 bpl.s editctm0                 * Zeile hoch, wenn nicht schon ganz oben
editctm3:
 move.b lrand(a5),curx(a5)      * Auf linken Rand
editctm4:
 rts

editctn:                        * Ctrl-N
 moveq #23,d0
 bsr getplatz                   * Platz schaffen zum Einfügen der Zeile
 move.l akttxt(a5),-(a7)        * akttxt nicht ändern
 moveq #23,d0
 bsr zeiscrsp                   * Zeile in den Speicher
 move.l (a7)+,akttxt(a5)
 bsr insline                    * Zeile einfügen
 bsr.s editqs                   * An Zeilenanfang
 bra crtstatus                   * Statuszeile neu

editcto:                        * Ctrl-O (Tab links)
 lea    edittabs(a5),a0         * Adresse der Tabs
 moveq  #0,d0
 move.b curx(a5),d0             * Cursorposition
 adda.l d0,a0                   * Adresse des Tab
 clr    d1                      * Zähler für Sprung
editcto0:
 addq   #1,d1                   * 1 vor
 subq   #1,d0                   * Nächste Position
 bpl.s  editcto1                * Weiter, wenn nicht vorne
 rts
editcto1:
 tst.b  -(a0)
 bpl.s  editcto0                * Weitersuchen, da nicht Tab
 sub.b d1,curx(a5)              * Neue Cursorposition
 bra adjcurx                     * Zeilenende-Test

editctp:                        * Ctrl-P
 btst.b #6, keydil(a5)          * GDP-FPGA da?
 bne.s editctp2                 * ja, dann auch user Zeichensatz
 eori.b #1, optflag(a5)
 bra.s editctp1
editctp2:
 addq.b #1,optflag(a5)          * einen Zeichensatz weiter
 cmp.b #3,optflag(a5)           * schon bei 3?
 blt.s editctp1                 * nein, dann OK
 clr.b optflag(a5)              * sonst wieder amerikanisch
editctp1:
 bra crtstatus                   * Statuszeile ausgeben

editctq:                        * Ctrl-Q
 bsr    ci                      * Zeichen holen
 and.b  #%11111,d0              * Ctrl, Groß- und Kleinschreibung erlaubt
 cmp #24,d0
 bhi carset                     * Nicht größer als 24
 add    d0,d0
 move edctqtab(pc,d0.w),d0
 jmp edctqtab(pc,d0.w)           * Unterprogramm aufrufen

edctqtab:
 DC.w carset-edctqtab
 DC.w editqa-edctqtab           * Suchen + Ersetzen
 DC.w carset-edctqtab
 DC.w editqc-edctqtab           * An Textende
 DC.w editcts3-edctqtab         * An Zeilenende
 DC.w ctr2a-edctqtab            * Home
 DC.w editqf-edctqtab           * Suchen
 DC.w carset-edctqtab
 DC.w carset-edctqtab
 DC.w carset-edctqtab
 DC.w carset-edctqtab
 DC.w carset-edctqtab
 DC.w carset-edctqtab
 DC.w carset-edctqtab
 DC.w carset-edctqtab
 DC.w carset-edctqtab
 DC.w carset-edctqtab
 DC.w carset-edctqtab
 DC.w editqr-edctqtab           * An Textanfang
 DC.w editqs-edctqtab           * An Zeilenanfang
 DC.w editqt-edctqtab           * Zeile trennen
 DC.w carset-edctqtab
 DC.w editqv-edctqtab           * Zeile verschmelzen
 DC.w carset-edctqtab
 DC.w editqx-edctqtab           * Auf unterste Zeile

editqa:
 clr.b ausbuf+90(a5)            * Kein Ersetzen
 lea sutxt(pc),a0               * Text
 lea ausbuf(a5),a1              * Ziel
 move #180,d2
 bsr editab0                    * Suchtext holen
 bcs.s  editqf1                 * Fehler
 lea ertxt(pc),a0
 lea ausbuf+42(a5),a1
 moveq #100,d2
 bsr editebuf                   * Ersetzetext holen
 st ausbuf+90(a5)               * Ersetzen aktiv
 bsr sucherse                   * Jetzt Suchen und Ersetzen
 bra crtstatus

editqc:
 bsr putscreen                  * Screen in Speicher
 movea.l etxtxt(a5),a0          * Endadresse
 moveq #15-1,d0
editqc1:
 bsr ptzurueck                  * Pointer eine Zeile zurück
 bcc.s editqc2                  * Falls Anfang Text erreicht
 addq.l #1,a0                   * a0 immer dort halten
editqc2:
 dbra d0,editqc1
 move.l a0,akttxt(a5)           * Ist Anfangsadresse Screen
 bra getscreen                   * Screen holen

editqf:
 clr.b ausbuf+90(a5)            * Kein Ersetzen
 lea sutxt(pc),a0
 lea ausbuf(a5),a1              * Ziel
 moveq  #125,d2
 bsr    editab0                 * Text holen
 bcs.s  editqf1
 bsr    edits1buf               * Alte Seite
 bra     suchedit                * Suchen
editqf1:
 clr.b  (a1)                    * Kein Text gültig
 bra     edits1buf               * Bildschirm wieder alte Seite

editqr:
 bsr putscreen                  * Screen in Speicher
editqr1:
 move.l stxtxt(a5),akttxt(a5)   * Anfang ist aktuelle Adresse
 bra getscreen                   * Screen holen

editqt:                         * Zeile trennen
 move.b curx(a5),-(a7)
 bsr    calccur                 * Zeileninfo holen
 movea.l a2,a3                  * a3 = Zeiger auf aktuelle Position
 lea    80(a0),a4               * Zeiger hinter die Zeile
 addq.b #1,cury(a5)
 bsr    editctn                 * Zeile einfügen
 bsr    calccur                 * Zeileninfo holen
editqt0:
 move.b (a3)+,(a0)+
 cmpa.l a3,a4
 bne.s  editqt0                 * Bis Ende der Zeile übertragen
 bsr    editcts3                * Zeichen pro Zeile richtig einstellen
 clr.b  curx(a5)                * Für Zeilenausgabe ganz an Anfang
 bsr    lineaus                 * Neue Zeile ausgeben
 subq.b #1,cury(a5)             * Auf alte Zeile
 move.b (a7)+,curx(a5)
 bra     eraeoln                 * Ende der Zeile löschen

editqv:                         * Zeile verschmelzen
 bsr    editcts3                * Cursor ans Ende der Zeile
 move.b #80,d1
 sub.b (a1),d1                  * Anzahl der freien Zeichen
 movea.l a2,a3                  * Cursorposition
 addq.b #1,cury(a5)
 bsr    calccur
 move.b curx(a5),-(a7)
 clr.b  curx(a5)
 movea.l a0,a4                  * Adresse nächste Zeile
editqv1:
 move.b (a4),(a3)+
 bsr    delchar
 subq.b #1,d1
 bne.s editqv1
 subq.b #1,cury(a5)
 bsr    editcts3                * Anzahl Zeichen richtig
 move.b (a7)+,curx(a5)
 bra    lineaus

editqx:                         * Auf unterste Zeile
 clr.b  curx(a5)
 move.b #22,cury(a5)
 rts

editcts:                        * Zeichen links
 move.b lrand(a5),d0
 cmp.b curx(a5),d0              * Cursor am linken Rand ?
 beq.s editcts1                 * Ja, dann weiter
 subq.b #1,curx(a5)             * Sonst nur nach links
 rts
editcts1:
 tst.b cury(a5)                 * Weiter, wenn in oberster Zeile
 beq.s editcts2
 subq.b #1,cury(a5)             * Sonst eine Zeile hoch
 bra.s   editcts3                * Hinter letztes Zeichen
editcts2:
 bsr    crtdown                 * Scrollen
editcts3:
 move.b #79,curx(a5)
 bra     curtoend                * Hinter letztes Zeichen

editctv:                        * Ctrl-V
 eori.b #1,insl(a5)             * Einfügemode umschalten
 bra crtstatus                   * Statuszeile neu ausgeben

editctw:                        * Ctrl-W
 bsr crtdown                    * Immer Scrollen
 cmp.b #22,cury(a5)             * Ist Cursor am untersten Rand angelangt ?
 bcc.s editctw0                 * Ja, dann Ende
 addq.b #1,cury(a5)             * Sonst Cursor runter
editctw0:
 rts

editctx:                        * Ctrl-X
 cmp.b #21,cury(a5)             * Cursor unten ?
 bhi.s editctx1                 * Ja, dann muß gescrollt werden
 addq.b #1,cury(a5)             * Sonst nur Cursor runter
 bra curtoend                    * Mit Endabfrage
editctx1:
 bsr crtup                      * Scrollen
 bra curtoend                    * Endabfrage

editcty:                        * Ctrl-Y
 bsr.s  editcty1
 bra     crtstatus               * Statuszeile neu

editcty1:
 bsr delline                    * Zeile, auf der Cursor steht, löschen
 movea.l akttxt(a5),a0          * Aktuelle Adresse holen
 moveq #23,d0                   * Auf Zeile 23
 bsr zeispscr                   * Zeile vom Speicher auf den Screen
 move.b cury(a5),-(a7)
 move.b #23,cury(a5)            * Auf Zeile 23
 bsr lineaus                    * Zeile auch auf den Bildschirm
 move.b (a7)+,cury(a5)
 bsr clrram                     * Ram verschieben
 bra adjcurx1

editctz:                        * Ctrl-Z
 bsr crtup                      * Scrollen
 tst.b cury(a5)                 * Cursor ganz oben ?
 beq carres                     * Ja, dann Ende
 subq.b #1,cury(a5)             * Sonst Cursor auch nach oben
 rts

editesc:                        * ESC-Funktionen
 bsr ci
 cmp.b #'A'-1,d0
 bhi.s edite2                   * Größer als A, dann normale Funktion
 sub.b  #'0',d0
 cmp.b  #9,d0
 bhi    carset                  * Falsche Nummer
 mulu   #41,d0
 lea    editmacro(a5),a3
 adda.l d0,a3                   * Adresse des Textes
 bsr    calccur                 * Zeileninfo holen
 cmpa.l a0,a2
 beq.s  edite0                  * Cursor ist ganz vorne
 cmp.b  #'',(a0)               * Wenn $7f am Anfang einer Zeile
 bne.s  edite0                  * dann weiter
 move.b curx(a5),d4             * Position merken
 clr.b  curx(a5)                * An Zeilenanfang
 moveq  #' ',d0
 bsr    charoscr                * Zeil aktivieren
 move.b d4,curx(a4)             * Alte Position
edite0:
 move.b (a3)+,d0                * Nächstes Zeichen holen
 beq    carset
 btst.b #0,insl(a5)
 beq.s  edite1
 bsr    inschar                 * Bei Einfügemode Zeichen einfügen
edite1:
 bsr    charoscr
 bcc.s   edite0                  * Nur wenn noch Platz
 rts

edite2:                         * Alle anderen ESC-Funktionen
 and.b  #%11111,d0              * Ctrl, Groß- und Kleinschreibung erlaubt
 cmp #23,d0
 bhi carset                     * Nicht größer als 22
 add    d0,d0
 move edesctab(pc,d0.w),d0
 jmp edesctab(pc,d0.w)           * Unterprogramm aufrufen

edesctab:
 DC.w carset-edesctab
 DC.w editea-edesctab           * Alter Text
 DC.w carset-edesctab
 DC.w editec-edesctab           * Tabulatoren löschen
 DC.w edited-edesctab           * Definiere Macro
 DC.w carset-edesctab
 DC.w carset-edesctab           * Macrofunktion ???
 DC.w carset-edesctab
 DC.w carset-edesctab
 DC.w editei-edesctab           * Init Tabulatoren
 DC.w carset-edesctab
 DC.w carset-edesctab
 DC.w editel-edesctab           * Linker Rand
 DC.w editem-edesctab           * Init Macros
 DC.w editen-edesctab           * Neuer Text
 DC.w esc10a-edesctab           * Hardcopy einfach
 DC.w esc11a-edesctab           * Hardcopy mit Zeichensatzumschaltung
 DC.w carset-edesctab
 DC.w carset-edesctab
 DC.w edites-edesctab           * Scrollart
 DC.w editet-edesctab           * Autotab
 DC.w carset-edesctab
 DC.w carset-edesctab
 DC.w editew-edesctab           * Tabulator an/aus

editea:
 bsr savescreen                 * Screen abspeichern
 clr.b flip(a5)                 * Keine Seitenumschaltung
 bsr textalt                    * Adresse alter Text
 bra getscreen                   * Neuen Screen laden

editec:                         * Tabulatoren löschen
 lea    edittabs(a5),a0
 moveq  #20-1,d0
editec0:
 clr.l  (a0)+                   * Alle Tabs löschen
 dbra    d0,editec0
 bra     editei1                 * Anzeige

edited:                         * Macros ausgeben und definieren
 moveq #%10000000,d0            * Seite 2
 bsr    setpage                 * setzen
 bsr    clrinvis                * und löschen
 moveq  #$11,d0                 * Schriftgröße
 move   #245,d2
 moveq  #10-1,d3                * 10 Macros
edited0:
 sub    #10,d2                  * Y-Position
 moveq  #9,d4
 sub    d3,d4
 lea    einbuf+90(a5),a0        * Ziel
 move.l #'0 ='*256,(a0)
 add.b  d4,(a0)                 * Nummer
 moveq  #25,d1                  * X = 0
 bsr    textprint               * Ausgabe
 mulu   #41,d4
 lea    editmacro(a5),a0
 adda.l d4,a0                   * Macroadresse
 moveq  #60,d1                  * X-Position
 bsr    textprint               * Macro ausgeben
 dbra    d3,edited0              * Nächster Macro
 lea    macrtxt0(pc),a0
 moveq  #$22,d0
 moveq  #110,d2
 bsr    centertxt               * Aufforderungstext
 moveq  #%10100000,d0
 bsr    setpage                 * Seite 2 anzeigen
 bsr    editci                  * Nummer eingeben
 sub.b  #'0',d0
 cmp.b  #'9',d0
 bhi    carset                  * Fehler, da nicht im Bereich 0..9
 mulu   #41,d0
 lea    editmacro(a5),a2
 adda.l d0,a2                   * Zieladresse
 lea    einbuf+90(a5),a1
 lea    macrtxt1(pc),a0
 moveq  #50,d2
 bsr    editbuf1
 bcs    edits1buf               * Ende, wenn leer oder ESC
 bsr    edits1buf               * Alte Seite
edited1:
 move.b (a1)+,(a2)+             * Abspeichern
 bne.s  edited1
 rts

editei:                         * Init Tabulatoren
 bsr.s editeiin
editei1:
 bsr    erapen                  * Auf Löschen
 moveq  #1,d1                   * X-Anfang
 move.b #254,gdp+5*cpu.w        * Delta-X
 bsr.s  editei2
 eori.b #1,wrtpage(a5)
 bsr    aktpage                 * Andere Seite
 bsr.s  editei2
 bsr    setpen
 bra crtstatus                   * Anzeige der neuen Tabs

editei2:
 moveq  #$10,d0                 * Befehl Vektor zeichnen
 moveq  #12,d2
 bsr    moveto
 bsr    cmd
 bsr    cmd                     * Linie
 addq   #1,d2
 bsr    moveto
 bsr    cmd
 bra     cmd                     * Linie

editeiin:                       * Init Tabulatoren
 lea    edittabs(a5),a0
 moveq  #10-1,d0
editei0:
 move.l #$80000000,(a0)+
 clr.l  (a0)+                   * Alle Tabs löschen
 dbra    d0,editei0
 clr.b  edittabs(a5)            * Erster nicht
 move.b #$80,-1(a0)             * Letzter schon
 rts

editel:
 lea werttxt(pc),a0             * Text
 bsr editzahl                   * Zahl holen
 bcs carset
 and.b #%111111,d0              * 0..63
 move.b d0,lrand(a5)            * Abspeichern
 cmp.b curx(a5),d0
 bmi carset
 move.b d0,curx(a5)             * Wenn links vom Rand, dann auf Rand setzen
 rts

editem:                         * Init Macros
 lea    macrotxt(pc),a0         * Dort steht Init-Tabelle
 moveq  #10-1,d0                * 10 Macros (0-9)
editem0:
 moveq  #9,d1
 sub    d0,d1
 mulu   #41,d1                  * Adresse relativ
 lea    editmacro(a5),a1
 adda.l d1,a1                   * Zieladresse für Macro
editem1:
 move.b (a0)+,(a1)+             * Übertragen bis Endekennung
 bne.s  editem1
 dbra    d0,editem0              * Nächster Macro
 rts

editen:
 bsr savescreen                 * Screen abspeichern
 clr.b flip(a5)                 * Keine Seitenumschaltung
 bsr textneu                    * Adresse neuer Text
 bra getscreen                   * Screen laden

edites:
 bchg.b #3,insl(a5)             * Scrollart ändern
 bra crtstatus                   * Statuszeile neu ausgeben

editet:                         * Autotab
 bchg.b #4,insl(a5)
 bra crtstatus                   * Statuszeile neu

editew:                         * Tabulator ändern
 lea edittabs(a5),a0
 moveq  #0,d0
 move.b curx(a5),d0             * Cursorposition
 bchg.b #7,0(a0,d0.l)
 bra     editei1                 * Tabulatoren neu anzeigen


*******************************************************************************
*                         680xx Grundprogramm edit2                           *
*                        (C) 1991 Ralph Dombrowski                            *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                              Editor Teil 2                                  *
*******************************************************************************


curtoend:                       * Endabfrage
 bsr calccur                    * Zeileninfo holen
 move.b curx(a5),d0             * Position holen
 cmp.b (a1),d0                  * Steht Cursor hinter letztem Zeichen
 bcs.s adjcurx1                 * Nein, dann weiter
 cmp.b  #$7f,(a0)               * Leerzeile, dann ganz nach vorne
 bne.s  curtoe0
 move.b lrand(a5),curx(a5)      * Cursor nach vorne
 rts
curtoe0:
 cmp.b  #' ',(a2)
 bne.s curtoe1                  * Nicht weiter, wenn kein Leerzeichen gefunden
 subq.l #1,a2                   * Zeichen zurück
 subq.b #1,d0                   * Ein Zeichen weniger
 bpl.s curtoe0
curtoe1:
 addq.l #1,a2
 addq.b #1,d0                   * Angleich
 move.b d0,curx(a5)             * Sonst genau dahinter setzen
 move.b d0,(a1)                 * Zeichenzähler neu
adjcurx:
 cmp.b #80,curx(a5)             * Cursor auf Position 80 ?
 bcs.s adjcurx1                 * Nein, dann weiter
 move.b #79,curx(a5)            * Nur bis 79 ist erlaubt
 rts
adjcurx1:
 move.b lrand(a5),d0            * Linker Rand
 cmp.b curx(a5),d0              * Position
 bmi carres                     * Cursor steht dahinter, dann OK
 move.b d0,curx(a5)             * Sonst auf Rand setzen
 rts

curright:                       * Cursor um ein Zeichen nach rechts und
 bsr calccur                    * testen, ob Cursur hinter letztem Zeichen
 addq.b #1,curx(a5)
 move.b curx(a5),d0             * oder auf Position 80
 cmp.b (a1),d0                  * Ja, dann Carry = 1
 bhi carset
 cmp.b #80,d0
 beq carset
 bra carres                      * Sonst Carry = 0

getscreen:
 bsr clrscreen                  * Bildschirm löschen
 moveq #%11000000, d0           * HELP
 bsr setpage                    * Seite 3 als Schreibseite
 move.l a1, -(a7)               * a1 retten
 lea helptxt0(pc), a1
 lea idebuff(a5), a0            * ausbuf wird schon benötigt
get1scr:
 move.b (a1)+, (a0)+            * helptxt0 nach ausbuf
 bne.s get1scr
 subq.l #1, a0                  * Null raus
 bsr prtvers                    * Versionsnummer nach a0
 movea.l (a7)+, a1
 lea idebuff(a5), a0            * ausbuf wird schon benötigt
 moveq #$22,d0
 move #240,d2
 bsr centertxt                  * Überschrift
 lea helptxt1(pc), a0
 moveq #$11, d0
 moveq #0, d1
 move #229, d2
 bsr textprint                  * Erste Spalte
 move #170 ,d1
 lea helptxt2(pc), a0
 bsr textprint                  * Zweite Spalte
 move #340, d1
 lea helptxt3(pc), a0
 bsr textprint                  * Dritte Spalte
 movea.l akttxt(a5), a0         * Von dort an steht Text
 clr d0                         * Von Zeile Null an
getscr0:
 bsr zeispscr                   * Zeile vom Speicher in den Screen-Speicher
 addq #1, d0                    * Nächste Zeile
 cmp #24, d0                    * Bis ganz unten
 bne.s getscr0
 bsr.s clrram                   * Ram verschieben
 bsr seite1                     * Seite 1
 bsr setpen                     * Auf Schreiben
 bsr prtall                     * Ausgabe
 bsr seite0                     * Seite 0
 bsr prtall                     * Ausgabe
 move.b lrand(a5), curx(a5)     * Cursor auf linken Rand
 bra crtstatus                   * Statuszeile ausgeben

savescreen:                     * Wie putscreen, aber aktuelle Anfangsadresse
 move.l akttxt(a5), -(a7)       * des Bildschirms bleibt erhalten
 bsr.s putscreen                * Screen in Ram bringen
 move.l (a7)+, akttxt(a5)
 rts

putscreen:
 moveq #24-1,d1                 * Bildschirm zurück in den Speicher
 moveq #0,d2                    * Zähler der einzufügenden Zeichen
putscr0:
 move d1,d0                     * Zeilennummer
 bsr.s getzlen                  * Länge ermitteln
 add d0,d2                      * Länge addieren
 dbra d1,putscr0
 move.l d2,d0                   * Länge nach d0
 beq carset                     * Wenn Null, dann war Screen leer
 bsr.s einschub                 * Ram verschieben
 moveq #0,d1
putscr2:
 move d1,d0
 bsr.s zeiscrsp                 * Zeile in Speicher
 addq #1,d1
 cmp #24,d1                     * Bis letzte Zeile erreicht
 bne.s putscr2
 rts

clrram:                         * a0 zeigt auf Quelle
 movea.l akttxt(a5),a1          * Ziel ist akttxt
clrram1:                        * Ende wird neu gesetzt
 move.b (a0)+,(a1)+
 bne.s clrram1
 subq.l #1,a1
 move.l a1,etxtxt(a5)           * Ende merken
 rts

getzlen:                        * In d0.w steht Zeile
 movem.l a1-a2,-(a7)            * Ergebnis d0 Anzahl Zeichen
 bsr getline                    * a0 Adresse Zeile
 moveq #0,d0                    * Voreinstellung ist 0 Zeichen
 cmp.b #$7f,(a0)                * Ist erstes Zeichen '' ?
 beq.s getzlen3                 * Nein, dann weiter
 move.b (a1),d0                 * Anzahl der Zeichen holen
getzlen1:
 subq #1,d0                     * Genau auf letztes Zeichen
 bmi.s getzlen2                 * Wenn negativ dann kein Zeichen vorhanden
 cmp.b #' ',0(a0,d0.w)          * Leerzeichen am Ende einer Zeile entfernen
 beq.s getzlen1                 * Ja, Leerzeichen, weiter suchen
getzlen2:
 addq #1,d0                     * Ein Zeichen mehr, wegen subq vor der Abfrage
 move.b d0,(a1)                 * Neue Anzahl der Zeichen
 addq #2,d0                     * 2 Zeichen $d, $a
getzlen3:
 movem.l (a7)+,a1-a2
 rts

getplatz:                       * Platz für eine Zeile (d0) im Speicher schaffen
 bsr.s getzlen                  * d0 ist Nummer Zeile
 tst d0                         * Leerzeile
 beq carset                     * Ergebnis d0 Länge der Zeile

einschub:                       * d0 = Länge der Zeile
 movem.l a1-a2,-(a7)            * Es wird von akttxt an verschoben
 movea.l etxtxt(a5),a1
 add.l d0,etxtxt(a5)            * d0 zerstört
 lea 1(a1,d0.l),a2              * Ziel+1 wegen -(an)
 move.l a1,d0
 sub.l akttxt(a5),d0            * Anzahl der zu verschiebenden Zeichen
 addq.l #1,a1                   * +1  wegen -(am)
einsch1:
 move.b -(a1),-(a2)             * Verschieben
 dbra d0,einsch1                 * Schleife
 clr d0                         * $ffff, das durch dbra entstanden ist, löschen
 subq.l #1,d0                   * Obere Hälfte testen, wenn Null, dann OK
 bpl.s einsch1                   * Sonst ist Text größer als 64 Kbyte
 movem.l (a7)+,a1-a2
 rts

zeiscrsp:                       * Zeile vom Screen in den Speicher (d0=Nummer)
 bsr.s getzlen                  * Ziel ist akttxt (wird auch erhöht)
 tst d0
 beq carset                     * Zeile leer
 movea.l akttxt(a5),a1          * d0,a0,a1 zerstört
 subq #3,d0                     * Drei Zeichen weniger/ 2 für $0d0a, 1 für Dbra
 bmi.s zscrsp2                  * Negativ, dann nur $0d0a
zscrsp1:
 move.b (a0)+,(a1)+             * In Speicher
 dbra d0,zscrsp1
zscrsp2:
 move.b #$0d,(a1)+
 move.b #$0a,(a1)+              * Endekennung einer Zeile
 move.l a1,akttxt(a5)           * akttxt aktualisieren
 rts

zeispscr:                       * Zeile vom Speicher auf den Bildschirm
 movem.l d0-d2/a1-a3,-(a7)      * Ohne schieben
 movea.l a0,a3                  * a0 merken
 bsr getline                    * Zeileninfo holen
 moveq #0,d0                    * Zeichenzähler
 cmpa.l stxtxt(a5),a3           * Wenn vor Textanfang, dann ausgleichen
 bpl.s zspscr0
 addq.l #1,a3                   * Ausgleich
 bra.s zspscr7                   * Zeiger für Leerzeile
zspscr0:
 moveq #80-1,d0                 * d0 = Zeile
 moveq #' ',d1
zspscr1:                        * a0 ist Quelle
 cmp.b (a3),d1                  * Ergebnis a0 = Nächste Zeile
 bhi.s zspscr2                  * a0 nächste Zeile
 move.b (a3)+,(a0)+             * So lange holen, bis Controlzeichen erscheint
zspscr1a:
 dbra d0,zspscr1                 * Prüfen, ob Zeile voll ist
 bra.s zspscr5
zspscr2:
 move.b (a3),d2                 * Null ist Ende
 beq.s zspscr5
 cmp.b #$d,d2                   * $d auch
 beq.s zspscr5
 addq.l #1,a3                   * Zeichen auf jeden Fall überspringen
 cmp.b #9,d2                    * TAB ?
 bne.s zspscr1                  * Nein, dann Zeichen ignorieren
 move.l d0,d2
 divu #8,d2
 swap d2                        * d1 = Anzahl der einzufügenden Leerzeichen
zspscr3:
 move.b #' ',(a0)+              * Leerzeichen einfügen
 dbra d2,zspscr4                 * Prüfen, ob Position erreicht
 bra.s zspscr1a                  * JA !
zspscr4:
 dbra d0,zspscr3                 * Prüfen, ob Zeile voll ist
zspscr5:
 neg d0
 add #79,d0                     * Anzahl der Zeichen in dieser Zeile
zspscr6:
 tst.b (a3)                     * War es eine Null
 beq.s zspscr7                  * Ja, dann ist Zeile zu Ende
 cmp.b #$a,(a3)+                * Ist es $a ?
 bne.s zspscr6                  * Nein, dann bis $a suchen
 bra.s zspscr8                   * Zeile ist zu Ende
zspscr7:
 tst d0                         * Anzahl der Zeichen gleich Null ?
 bne.s zspscr8                  * Nein, dann weiter
 move.b #$7f,(a0)               * Ja, Zeile ist leer
 addq #1,d0                     * Ein Zeichen mehr vorhanden
zspscr8:
 move.b d0,(a1)                 * Anzahl der Zeichen abspeichern
 movea.l a3,a0                  * a3 zurück
 movem.l (a7)+,d0-d2/a1-a3
 rts

ptzurueck:                      * a0 zeigt auf Zeilenanfang
 subq.l #1,a0
 cmpa.l stxtxt(a5),a0           * a0 zeigt danach auf Anfang vorherige Zeile
 bmi carset                     * Bei Textanfang nur ein Zeichen abziehen
ptzur1:                         * und Carry setzen
 cmpa.l stxtxt(a5),a0           * Wenn auf Textanfang
 beq carres                     * Dann Ende
 cmp.b #$a,-(a0)                * Sonst bis Zeilenanfang suchen
 bne.s ptzur1
 addq.l #1,a0
 bra carres                      * OK, nicht am Textanfang

screenup:
 btst.b #3,insl(a5)             * Scrollart
 bne screenue
 bsr page1clr
 movea.l akttxt(a5),a0
 movea.l a0,a2
 moveq #9-1,d0                  * 9 Zeilen aufwä rts
screenua:
 bsr.s ptzurueck                * Eine Zeile zurück
 bcs.s screenub
 movea.l a0,a2                  * Merken, wenn nicht am Anfang
screenub:
 bsr zeispscr                   * Zeile in Bildschirmspeicher
 movea.l a2,a0
 dbra d0,screenua
 movea.l akttxt(a5),a1
 move.l a0,akttxt(a5)           * Adresse merken
 movea.l a1,a0
 moveq #9,d0                    * Jetzt die restlichen Zeilen
screenuc:
 bsr zeispscr                   * Zeile in Bildschirmspeicher
 addq #1,d0
 cmp #24,d0                     * Bis alle Zeilen fertig
 bne.s screenuc
screenud:                       * Einsprung screendown
 bsr clrram                     * Ram löschen
 move d7,d2
 clr d1
 bsr setpen                     * Wieder Position links oben
 bsr movetoo                    * Positionieren
 bsr prtall                     * Seite 1 neu beschreiben
 moveq #%00010000,d0            * Seite 0
 bsr setpage
 bsr clrinvis                   * Löschen
 clr d1
 move d7,d2
 bsr moveto                     * Positionieren
 bsr prtall                     * Ausgabe
 bra crtstatus                   * Statuszeile

screenue:
 moveq #15-1,d1                 * Eine Seite weiter (Zeilenweise)
scrup0:                         * Einsprung crtup
 move.b cury(a5),-(a7)          * Retten
 move.b curx(a5),-(a7)
 clr.b curx(a5)
 move.b #23,cury(a5)            * Auf Anfang Zeile 23 positionieren
 moveq #0,d2
 move d1,d7
scrup1:
 move d1,d0
 bsr getzlen                    * Alle Zeichen zusammenzählen
 add d0,d2
 dbra d1,scrup1
 move.l d2,d0                   * Kein Zeichen
 beq.s scrup3                   * Ja, dann weiter
 bsr einschub                   * Sonst Einfügen
 move d7,d1                     * Anzahl der Durchläufe
scrup2:
 move d7,d0
 sub d1,d0                      * Alle Zeilen in den Speicher
 bsr zeiscrsp
 dbra d1,scrup2
scrup3:
 movea.l akttxt(a5),a0
scrup4:
 bsr scroll                     * Scrollen auf dem Bildschirm
 moveq #23,d0
 bsr zeispscr                   * Letzte Zeile vom Speicher auf den Bildschirm
 bsr lineaus
 dbra d7,scrup4
 move.b (a7)+,curx(a5)          * Position zurück
 move.b (a7)+,cury(a5)
 bsr clrram                     * Ram löschen
 bra crtstatus                   * Statuszeile neu

crtup:                          * Scroll umm eine Zeile
 moveq #1-1,d1
 bra.s scrup0

screendown:
 btst.b #3,insl(a5)             * Scrollart
 bne.s screendd
 move.l akttxt(a5),-(a7)
 bsr page1clr
 movea.l (a7),a0
 movea.l a0,a2
 moveq #15-1,d0                 * 15 Zeilen aufwä rts
screenda:
 bsr ptzurueck                  * Eine Zeile zurück
 bcs.s screendb
 movea.l a0,a2                  * Merken, wenn nicht am Anfang
screendb:
 bsr zeispscr                   * Zeile in Bildschirmspeicher
 movea.l a2,a0
 dbra d0,screenda
 move.l a0,akttxt(a5)
 movea.l (a7)+,a0
 moveq #15,d0                   * Jetzt die restlichen Zeilen
screendc:
 bsr zeispscr                   * Zeile in Bildschirmspeicher
 addq #1,d0
 cmp #24,d0                     * Bis alle Zeilen fertig
 bne.s screendc
 bra screenud                    * Rest des Bildschirms aufbauen

screendd:
 moveq #15-1,d1                 * Eine Seite scrollen (Zeilenweise)
scrdown0:
 move.b cury(a5),-(a7)
 move.b curx(a5),-(a7)          * Retten
 clr.b cury(a5)                 * Auf Zeile Null
 moveq #0,d2                    * Zeichenzähler
 move d1,d7                     * Anzahl der Scrolldurchgänge merken
scrdown1:
 moveq #23,d0
 sub d1,d0                      * Zeile berechnen
 bsr getzlen                    * Zeilenlänge holen
 add d0,d2                      * Zeichen zusammenzählen
 dbra d1,scrdown1                * Nächste Zeile
 move.l akttxt(a5),-(a7)
 move.l d2,d0
 beq.s scrdown3                 * Kein Zeichen, dann weiter
 bsr einschub                   * Einfügen
 move d7,d1
scrdown2:
 moveq #23,d0
 sub d1,d0
 bsr zeiscrsp                   * Alle Zeilen vom Bildschirm in den Speicher
 dbra d1,scrdown2
scrdown3:
 move.l (a7),akttxt(a5)
scrdown4:
 bsr insline                    * Oberste Zeile einfügen
 movea.l akttxt(a5),a0
 bsr ptzurueck                  * Pointer eine Zeile zurück
 bcs.s scrdown5
 move.l a0,akttxt(a5)           * Wenn nicht vor Textanfang neue Adresse merken
scrdown5:
 moveq #0,d0
 bsr zeispscr                   * Zeile vom Speicher auf den Bilschirm
 bsr.s lineaus
 dbra d7,scrdown4
 movea.l (a7)+,a0
 move.b (a7)+,curx(a5)
 move.b (a7)+,cury(a5)          * Zurück
 bsr clrram                     * Ram löschen
 bra crtstatus                   * Statuszeile neu

crtdown:
 moveq #1-1,d1                  * Eine Zeile scrollen
 bra.s scrdown0

page1clr:
 bsr putscreen
 bsr homepos                    * Position links oben
 move d2,d7
 moveq #%01000000,d0
 bsr setpage                    * Seite 1
 bsr movetoo                    * Positionieren
 bsr erapen
 bsr prtall                     * Löschen, was dort stand
 bra clrscr                      * Bildschirmspeicher löschen

lineaus:                        * Eine Zeile auf beiden Seiten ausgeben
 bsr seite1                     * Seite 1
 bsr setpen                     * Auf Schreiben
 bsr prtline                    * Ausgabe
 bsr seite0                     * Seite 0
 bra prtline                     * Ausgabe

crtstatus:                      * Statuszeile ausgeben
 lea c_rtsttxt(pc),a0            * Text
 lea einbuf+40(a5),a1           * Ziel
crtst1:
 move.b (a0)+,(a1)+             * Übertragen
 bne.s crtst1
 lea einbuf+40+8(a5),a0         * Startadresse
 move.l stxtxt(a5),d0
 bsr print6x                    * Einsetzen
 move.b #' ',(a0)               * Null überschreiben
 lea einbuf+40+26(a5),a0        * Anfangsadresse Ziel
 move.l akttxt(a5),d0
 bsr print6x                    * Einsetzen
 move.b #' ',(a0)               * Null überschreiben
 lea einbuf+40+40(a5),a0        * Endadresse Editor
 move.l etxtxt(a5),d0
 bsr print6x                    * Einsetzen
 move.b #' ',(a0)               * Null überschreiben
 btst.b #0,insl(a5)             * Einfügemodus an ?
 beq.s c_rtst2                   * Nein, weiter
 move.l #'einf',einbuf+40+48(a5)
 c_rtst2:
 tst.b optflag(a5)              * Amerikanischer Zeichensatz ?
 beq.s c_rtst3                   * Ja, weiter
 cmp.b #1,optflag(a5)           * Deutscher Zeichensatz?
 bne.s c_rtst2a                  * nein, dann User Zeichensatz
 move.l #'DE  ',einbuf+40+54(a5)
 bra.s c_rtst3
c_rtst2a:
 move.l fontname(a5),einbuf+40+54(a5)
c_rtst3:
 btst.b #3,insl(a5)             * Scrollart
 beq.s c_rtst4                   * Seitenweise, dann weiter
 move.b #'Z',einbuf+40+70(a5)
c_rtst4:
 btst.b #4,insl(a5)             * Auf Zeilenanfang / Auf Textanfang
 beq c_rtst5
 move.l #'Auto',einbuf+40+60(a5) * Auf Textanfang
c_rtst5:
 lea einbuf+40(a5),a0
 moveq #$11,d0
 moveq #2,d1
 moveq #2,d2
 moveq #84,d3                   * Umrandung um 84 Zeichen
 bsr textaus                    * Und Text ausgeben
 bsr    umrande
 moveq  #0,d6
 move.b groesse(a5),d6
 lsr    #4,d6                   * Nur Größe-X
 mulu   #6,d6                   * Abstand zwischen zwei Zeichen
 bsr.s  tabsaus
 eori.b #1,wrtpage(a5)          * Andere Seite auch
 bsr aktpage
 moveq #$11,d0                  * Größe neu einstellen
 moveq #2,d1
 moveq #2,d2
 bsr umrande
 bsr textaus                    * Und neu ausgeben

tabsaus:                        * Anzeige der Tabs
 move.w d6,d1
 lsr    #1,d1
 subq   #1,d1                   * Anfangsposition X
 moveq  #12,d2                  * Y-Position
 lea    edittabs(a5),a1         * Tab-Feld
 moveq  #80-1,d0
tabsaus0:
 tst.b  (a1)+
 bpl.s  tabsaus1                * Bit nicht gesetzt => Kein Tab
 bsr    moveto                  * Positionieren
 move.b #%10001010,gdp.w        * Kleiner Strich zum Anzeigen
tabsaus1:
 add    d6,d1
 cmp    #510,d1                 * Außerhalb des Bildschirms ?
 dbhi    d0,tabsaus0             * Weiter, wenn nicht Position 80 und noch im
tabsaus2:                       * Bildschirmbereich
 rts

editzahl:                       * Zahl einlesen
 bsr.s editabuf                 * ASCII-Zeichen holen
 bsr.s edits1buf                * Alte Seite
 movea.l a1,a0                  * Adresse nach a0
 bra wertmfeh                    * Wert holen

editebuf:                       * Eingabe mit Bildschirm anschalten
 moveq #%10100000,d0
 bsr setpage
 bsr.s editbuf1
edits1buf:
 move.b #10,flip(a5)            * Original-Seite einschalten
 move.b #1,curon(a5)
 bsr    aktpage
 move.b groesse(a5),gdp+3*cpu.w * Vorsichtshalber richtige Größe einstellen
 rts
                                * Eingabe mit Screen ausschalten
editabuf:                       * a0 = Adresse Text
 lea    einbuf+90(a5),a1
 moveq  #125,d2
editab0:                        * Einsprung
 moveq #%10000000,d0            * a1 Adresse Ziel
 bsr setpage                    * Ziel ist einbuf+40
 bsr clrinvis                   * d2 ist Höhe
editbuf1:                       * d3 ist Anzahl Zeichen
 clr.b flip(a5)                 * Keine Seitenumschaltung
 moveq #5,d1
 moveq #$33,d0
 bsr textprint                  * Text ausgeben
 sub #30,d2
 movea.l a1,a0
 moveq #%10100000,d0
 bsr setpage                    * Seite 2 ist jetzt Lese- und Schreibseite
 moveq #$22,d0
 moveq #40,d3
 bsr textein                    * Text holen
 bcs carset                     * Abbruch
 tst d4
 beq carset                     * Kein Zeichen, dann Fehler
 movea.l a1,a0
 bra carres                      * Sonst OK

editci:                         * Zeichen von Tastatur ohne Seitenumschaltung
 clr.b flip(a5)                 * Flip aus
 clr.b curon(a5)                * Cursor aus
 bsr ci                         * Zeichen holen
 move.b #10,flip(a5)            * Flip an
 move.b #1,curon(a5)            * Cursor an
 rts

sucherse:                       * String suchen und auf Abfrage ersetzen
 bsr.s suchedit                 * Suchen
 bcs.s  suchersfi
 bsr ki                         * Tastaturabfrage
 cmp.b #'J',d0
 beq.s ersetze                  * Ersetzen
 cmp.b #'N',d0
 beq.s  sucherse                * Weitersuchen
suchersfi:                      * Ende bei falscher Eingabe oder wenn nicht mehr
 rts                             * gefunden

ersetze:                        * String ersetzen
 move.b d1,curx(a5)             * Dort fängt String an
 lea ausbuf(a5),a0
ersetze1:
 tst.b (a0)+                    * Anzahl Zeichen
 beq.s ersetze2
 bsr delchar                    * Löschen
 bra.s ersetze1
ersetze2:
 lea ausbuf+42(a5),a0
ersetze3:
 move.b (a0)+,d0                * Zeichen holen
 beq.s sucherse                 * Weitersuchen
 bsr inschar                    * Einfügen
 move.l a0,-(a7)
 bsr charoscr                   * Ausgeben
 movea.l (a7)+,a0
 bra.s ersetze3

suchedit:
 move.b curx(a5),-(a7)          * Wenn nicht gefunden, dann an aktueller Stelle
 move.b cury(a5),-(a7)          * bleiben
 bsr.s suchscr                  * Nur innerhalb des Screens suchen
 bcs.s suched1
 addq.l #4,a7                   * Ergebnis curx hinter Wort
 cmp.b #23,cury(a5)
 bne    carres                  * OK
 move.b d1,-(a7)
 bsr    editctz                 * Cursor nicht auf letzte Zeile
 move.b (a7)+,d1
 bra carres
suched1:
 bsr.s suchram                  * Im Ram hinter Screen suchen
 bcs.s suched2                  * a0 ist Ergebnis
 move.l akttxt(a5),-(a7)
 move.l a0,-(a7)
 bsr putscreen                  * Screen im Ram ablegen
 movea.l akttxt(a5),a0
 adda.l (a7)+,a0                * Neue Adresse
 suba.l (a7)+,a0
 addq.l #1,a0
 bsr ptzurueck                  * Auf Anfang der Zeile
 move.l a0,akttxt(a5)
 bsr getscreen                  * Screen holen
 addq.l #4,a7                   * Stack reinigen
 bra.s suchedit                  * Neu suchen
suched2:
 move.b (a7)+,cury(a5)
 move.b (a7)+,curx(a5)
 bra carset                      * Nicht gefunden

suchscr:
 bsr calccur                    * Zeileninfo
 lea ausbuf(a5),a0
 move.b curx(a5),d0
suchscr1:
 cmpm.b (a2)+,(a0)+             * Suchen
 bne.s suchscr2
 addq.b #1,d0                   * Gefunden, dann nächstes Zeichen
 tst.b (a0)                     * Ende String ?
 beq.s  tstcurend               * Dann gefunden
 cmp.b (a1),d0
 bcs.s suchscr1                 * Weitersuchen

suchscr2:
 addq.b #1,curx(a5)             * Nächste Position
 move.b curx(a5),d1
 cmp.b (a1),d1
 bcs.s suchscr                  * Weitersuchen
 move.b lrand(a5),curx(a5)      * Neue
 addq.b #1,cury(a5)             * Zeile
 cmp.b #24,cury(a5)             * Auf letzter Zeile
 bne.s suchscr                  * Nein, dann weitersuchen
 bra carset                      * Ende, nicht gefunden

suchram:                        * Im Ram suchen
 movea.l akttxt(a5),a0
suchram0:
 tst.b (a0)                     * Nicht gefunden
 beq carset
 movea.l a0,a2
 lea ausbuf(a5),a1
suchram1:
 move.b (a1)+,d0                * OK, gefunden
 beq.s  suchram3
 cmp.b (a2)+,d0                 * Vergleich
 beq.s suchram1                 * Gleich, also weitersuchen
suchram2:
 addq.l #1,a0                   * Neue Adresse
 bra.s suchram0                  * Neu suchen
suchram3:
 move.b lrand(a5),d0            * Linker Rand
 beq    carres
 movea.l a0,a1
suchram4:
 cmp.b  #$0a,-(a1)              * Ende der letzten Zeile suchen
 beq.s  suchram2                * Gefunden, deshalb Cursor vor linkem Rand
 cmpa.l akttxt(a5),a1
 bmi.s  suchram2                * Vor Textanfang
 subq.b #1,d0
 bne.s  suchram4                * Ende der letzten Zeile suchen
 bra     carres                  * OK, Cursor ist hinter linkem Rand

tstcurend:
 move.b curx(a5),d1             * Gefundener String
 move.b d0,curx(a5)             * Cursor dahinter
 cmp.b  #80,d0                  * Cursor auf Position 80 ?
 bcs    carres                  * Nein, dann weiter
 move.b #79,curx(a5)            * Nur bis 79 ist erlaubt
 bra     carres

editadr:                        * Adresse der Cursorposition holen, wenn Screen
 movem.l d0-d2,-(a7)            * im Speicher wäre
 moveq #0,d1
 moveq #0,d2
editadr1:
 cmp.b cury(a5),d1              * Wenn Cursorzeile erreicht ist, dann weiter
 beq.s editadr2                 * Ja, weiter
 move d1,d0                     * Zeile
 bsr getzlen                    * Zeileninfo holen
 add d0,d2                      * Zeichenzahl addieren
 addq #1,d1                     * Nächste Zeile
 bra.s editadr1                  * Schleife
editadr2:
 bsr calccur                    * Cursorposition holen
 cmp.b #$7f,(a0)
 beq.s editadr3                 * Bei Leerzeile weiter
 move.b d1,d0
 bsr getzlen                    * Wirkliche Zeilenlänge holen
 subq #2,d0                     * CR LF weg
 move.b curx(a5),d1
 add d1,d2
 cmp.b d0,d1                    * Cursor hinter Zeilenende ?
 bmi.s editadr3                 * Nein, weiter
 move.b #blkins,(a2)            * 'blkins' in Speicher als Endemarke der Zeile,
                                * da Leerzeichen am Ende gelöscht würden und
                                * der neue Text dann an eine falsche Stelle käme
 addq.b #1,d1                   * Anzahl der Zeichen erhöhen
 move.b d1,(a1)                 * Ablage
editadr3:                       * 'blkins' wird automatisch wieder gelöscht
 movea.l d2,a3                  * Anzahl der Zeichen nach a3
 adda.l akttxt(a5),a3           * Anfang des Screen-Bereichs addieren
 movem.l (a7)+,d0-d2            * a3 ist jetzt Adresse der Cursorposition nach
 rts                             * Aufruf von PUTSCREEN

getblock:                       * Blockadressen suchen
 lea $ffff.w,a1                 * Kein Blockanfang
 movea.l stxtxt(a5),a0          * Von Anfang an
getblk1:
 move.b (a0)+,d0                * Zeichen holen
 beq carset                     * Null ist Ende und Fehler
 bpl.s getblk1                  * Positiv, dann weiter
 cmp.b #blkstart,d0             * Blockstart ?
 beq.s getblk2                  * Ja
 cmp.b #blkende,d0              * Blockende ?
 bne.s getblk1                  * Nein
 lea -1(a0),a2                  * a2 ist Blockende
 cmpa.l a1,a2                   * Blockende muß hinter Blockanfang liegen
 bhi carres                     * OK
 bra carset                      * Fehler
getblk2:
 lea -1(a0),a1                  * a1 ist Blockanfang
 bra.s getblk1

markeweg:                       * Marken entfernen
 move.b insl(a5),d0             * Sind Marken markiert ?
 and.b #%110,d0
 beq carres                     * Nein, Ende
 move.b cury(a5),-(a7)
 move.b curx(a5),-(a7)
 moveq #24-1,d1                 * Alle Zeilen durchtesten
mark0weg:
 move.b d1,cury(a5)             * Zeilennummer
 bsr calccur                    * Zeileninfo holen
 clr.b curx(a5)                 * Auf Zeichen Null
mark1weg:
 move.b (a0)+,d0                * Zeichen holen
 bpl.s mark3weg
 cmp.b #blkstart,d0             * Blockstart ?
 beq.s mark2weg                 * Ja
 cmp.b #blkende,d0              * Blockende ?
 bne.s mark3weg                 * Nein, weiter
mark2weg:
 bsr delchar                    * Zeichen entfernen
 subq.l #1,a0                   * Weitersuchen
 bra.s mark1weg
mark3weg:
 addq.b #1,curx(a5)             * Cursor weiter
 move.b curx(a5),d0
 cmp.b (a1),d0                  * Hinter letztem Zeichen ?
 bmi.s mark1weg                 * Nein, wiederholen
 dbra d1,mark0weg                * Nächste Zeile
 move.b (a7)+,curx(a5)
 move.b (a7)+,cury(a5)

markrweg:                       * Marken im Ram entfernen
 move.b insl(a5),d0
 and.b #%110,d0
 beq carres                     * Keine Marken vorhanden
 and.b #%11111001,insl(a5)      * Merker, daß alle entfernt sind
 movea.l stxtxt(a5),a0          * Anfangsadresse
mark4weg:
 move.b (a0)+,d0                * Zeichen holen
 beq carres                     * Ende
 bpl.s mark4weg                 * Keine Marke
 cmp.b #blkstart,d0
 beq.s mark5weg                 * Blockstart
 cmp.b #blkende,d0
 bne.s mark4weg                 * Keine Marke
mark5weg:
 movea.l a0,a2                  * Adresse nach a2
 lea -1(a0),a1                  * Zieladresse
mark6weg:
 move.b (a2)+,(a1)+             * Bis Null übertragen
 bne.s mark6weg
 subq.l #1,etxtxt(a5)           * Endemerker erniedrigen
 cmpa.l akttxt(a5),a0           * Lag Marke hinter Screen ?
 bpl.s mark4weg                 * Nein, Schleife fortführen
 subq.l #1,akttxt(a5)           * akttxt erniedrigen, da gelöschtes Byte vor
 bra.s mark4weg                  * Screen-Bereich lag

helptxt0:
 DC.b 'Editorfunktionen ',0

helptxt1:
 DC.b   '^E = Zeile hoch',10
 DC.b   '^X = Zeile runter',10
 DC.b   '^S = Zeichen links',10
 DC.b   '^D = Zeichen rechts',10
 DC.b   '^A = Wort links',10
 DC.b   '^F = Wort rechts',10
 DC.b   '^Z = Zeile auf',10
 DC.b   '^W = Zeile ab',10
 DC.b   '^C = Seite vor',10
 DC.b   '^R = Seite zur',$fd,'ck',10
 DC.b   '^Y = Zeile l',$fc,'schen',10
 DC.b   '^N = Zeile einf',$fd,'gen',10
 DC.b   '^G = Zeichen l',$fc,'schen',10
 DC.b   '^U = Zeichen einf',$fd,'gen',10
 DC.b   '^T = Löschen rechts',10
 DC.b   '^I = Auf Tab rechts',10
 DC.b   '^O = Auf Tab links',10
 DC.b   '^L = Suchen wiederholen',10
 DC.b   10
 DC.b   '^V = Einf',$fd,'gemode',10
 DC.b   '^P = Zeichensatz',0

helptxt2:
 DC.b   '^KB = Block Anfang',10
 DC.b   '^KK = Block Ende',10
 DC.b   '^KH = Marken l',$fc,'schen',10
 DC.b   '^KY = Block l',$fc,'schen',10
 DC.b   '^KV = Block verschieben',10
 DC.b   '^KC = Block kopieren',10
 DC.b   '^KR = Block lesen',10
 DC.b   '^KW = Block schreiben',10
 DC.b   '^KD = Block drucken',10
 DC.b   '^KS = Block auf Disk',10
 DC.b   '^KL = Block von Disk',10
 DC.b   '^KT = Text auf Disk',10
 DC.b   '^KI = Inhalt der Disk',10
 DC.b   '^KF = Editordaten speichern',10
 DC.b   '^KG = Editordaten laden',10
 DC.b   '^KP = Schriftart laden',10
 DC.b   '^KX = Ende (^KQ)',10
 DC.b   '^KA = Assembler',0

helptxt3:
 DC.b   '^QR = An Textanfang',10
 DC.b   '^QC = An Textende',10
 DC.b   '^QE = Oberste Zeile',10
 DC.b   '^QX = Unterste Zeile',10
 DC.b   '^QS = An Zeilenanfang',10
 DC.b   '^QD = An Zeilenende',10
 DC.b   '^QF = Suchen (^L)',10
 DC.b   '^QA = Ersetzen (^L)',10
 DC.b   '^QT = Zeile trennen',10
 DC.b   '^QV = Zeile verschmelzen',10
 DC.b   10
 DC.b   'ESC A = Alter Text',10
 DC.b   'ESC N = Neuer Text',10
 DC.b   'ESC I = Init Tabs',10
 DC.b   'ESC C = L',$fc,'schen Tabs',10
 DC.b   'ESC W = Tab an/aus',10
 DC.b   'ESC P = Ausdruck mit',10
 DC.b   'ESC O = Ausdruck ohne',10
 DC.b   'ESC L = Linker Rand',10
 DC.b   'ESC T = Autotab',10
 DC.b   'ESC S = Scrollart',10
 DC.b   'ESC D = Definiere Macro',10
 DC.b   'ESC M = Init Macros',10
 DC.b   'ESC 0-9 = Macrofunktionen',0

macrotxt:
 DC.b   'move',0
 DC.b   'clr',0
 DC.b   'add',0
 DC.b   'sub',0
 DC.b   'bsr',0
 DC.b   'bra',0
 DC.b   'dbra',0
 DC.b   'tst',0
 DC.b   'trap',0
 DC.b   ' rts',0

macrtxt0:
 DC.b   'Bitte Nummer (0-9) wählen',0

macrtxt1:
 DC.b   'Neuer Macrotext',0

c_rtsttxt:
 DC.b 'Start= $        Fenster= $        Tor= $              US        '
 DC.b '      S CTRL-J=Hilfe',0

sutxt:
 DC.b 'Suche',0

ertxt:
 DC.b 'Ersetze',0

nametxt1:
kopdt2:
 DC.b 'Name '

zieltxt:
 DC.b 'Ziel',0

nametxt2:
kopdt1:
 DC.b 'Name '

quelltxt:
 DC.b 'Quelle',0

werttxt:
 DC.b 'Wert',0

disktxt:
inhdt1:
 DC.b 'Laufwerk und Dateiauswahl',0

 ds 0

*******************************************************************************
*                      68000/68010 Grundprogramm ass1                         *
*                         (C) 1991 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                             Assembler Teil 1                                *
*******************************************************************************


assemble:
 move.b cotempo(a5),-(a7)       * Scrollart merken
 movea.l a7,a6                  * Merker für Abbruch
 bsr initdebug                  * Debug initialisieren
 bsr clrscreen
 moveq #'1',d0                  * Scroll-Geschwindigkeit einstellen
 bsr esc8                       * Hardware-Scroll an, wenn möglich
 move #1,passflag(a5)           * 1. Durchgang
 move.l etxtxt(a5),d0           * Ende des Textes
 addq.l #3,d0                   * 3 addieren für Abstand
 and.b #$fe,d0                  * Nur auf gerader Adresse
 move.l d0,macrotab(a5)         * Adresse Macrotabelle
 bsr assinit                    * Variablen initialisieren
 move.l a0,macroanf(a5)         * Adresse für Macrotext
ass1:
 bsr geteinbuf
 bsr assline                    * Zeile assemblieren
 cmp #2,errflag(a5)
 bne.s ass1                     * Nicht Ende, dann nächste Zeile
 clr pagecnt(a5)                * Seite 0
 clr errcnt(a5)                 * Kein Fehler bisher
 addq #1,passflag(a5)           * 2. Durchgang
 bsr assinit                    * Variablen initialisieren
 lea ausbuf(a5),a0
 moveq #-1,d0                   * Alle Buchstaben für Tag
 bsr uhrprint                   * Uhrzeit ausgeben
 bcs.s ass1a                    * Keine Uhr vorhanden
 lea ausbuf(a5),a0
 bsr prtco2                     * Zeile ausgeben
 bsr crlfe
ass1a:
 move.l a1, -(a7)
 lea kopftxt+1(pc),a1
 lea ausbuf(a5), a0
ass1b:
 move.b (a1)+, (a0)+            * Überschrift nach ausbuf
 bne.s ass1b
 subq.l #1, a0                  * Null raus
 bsr prtcpu
 subq.l #1, a0                  * Null raus
 lea kopftxt1(pc), a1
ass1c:
 move.b (a1)+, (a0)+            * Überschrift 2.Teil nach ausbuf
 bne.s ass1c
 subq.l #1, a0                  * Null raus
 bsr prtvers                    * Versionsnummer nach ausbuf
 subq.l #1, a0                  * Null raus
 lea kopftxt2(pc), a1
ass1d:
 move.b (a1)+, (a0)+            * Überschrift 3.Teil nach ausbuf
 bne.s ass1d
 movea.l (a7)+, a1
 lea ausbuf(a5), a0
 bsr kopfaus1                   * Überschrift ausgeben am Anfang
 clr.b ausbuf(a5)
 tst.b uhrausw(a5)
 beq.s ass2                     * Keine Uhr vorhanden, dann weiter
 addq.b #1,zeilen(a5)           * Uhr ist vorhanden, also eine Zeile mehr
ass2:
 move.l akttxt(a5),anfzeile(a5) * Anfangsadresse der Zeile
 tst errcnt(a5)                 * Fehler vorhanden, dann nicht verändern
 bne.s ass2a
 move.l anfzeile(a5),errzeile(a5) * Adresse der Zeile merken für Editor
ass2a:
 bsr getquelle                  * Neue Zeile holen und letzte Zeile ausgeben
 bsr assline                    * Zeile übersetzen
 cmp.b #1,debug(a5)             * Wenn Debug aus, dann weiter
 bne.s ass2b
 move.l anfstand(a5),d0
 cmp.l pcstand(a5),d0           * Hat sich der PC-Stand verändert ?
 beq.s ass2b                    * Nein, dann weiter
 movea.l debugak(a5),a0
 move.l d0,(a0)+                * PC-Stand merken
 move.l anfzeile(a5),(a0)+      * Zeilenanfang
 clr.l (a0)                     * Endekennung
 move.l a0,debugak(a5)          * Debug-Pointer aktualisieren
ass2b:
 and.b #1,debug(a5)             * Debug jetzt aktiv, wenn DEBUGAN erfolgte
 cmp #2,errflag(a5)             * Merker für Ende
 bne.s ass2
 bsr putausba                   * Letzte Zeile ausgeben
 bsr crlfe
 move.l pcstand(a5),d0          * PC-Adresse
 lea ausbuf(a5),a0
 bsr print6x                    * Hexadezimal
 lea ausbuf(a5),a0
 bsr prtco2                     * Ausgabe
 lea fintxt(pc),a0
 bsr put1lp                     * Text ausgeben
 move.l pcstand(a5),d0          * PC
 add.l offset(a5),d0            * + Ablageadresse
 lea ausbuf(a5),a0
 bsr print6x                    * Hexadezimal
 lea ausbuf(a5),a0
 bsr prtco2                     * Ausgabe
 lea fin1txt(pc),a0
 bsr put1lp                     * Textausgabe
 lea ausbuf(a5),a1              * Ziel
 lea fin2txt(pc),a0             * Quelle
ass3a:
 move.b (a0)+,(a1)+
 bne.s ass3a
 move errcnt(a5),d0             * Anzahl Fehler
 lea ausbuf(a5),a0
 bsr print4d                    * Dezimal ausgeben
 move.b #' ',(a0)+
 bsr putausba                   * Ausgabe
 moveq #0,d0                    * Langwort-Berechnung
 move symnext(a5),d0            * Ende der Symboltabelle
 move.l d0,d1                   * Merken
 divs #symlen,d1                * Länge eines Eintrags
 lea symtab(a5),a0
 add.l a0,d0                    * Endadresse Symboltabelle
 lea ausbuf(a5),a0
 bsr print6x                    * Hexadezimal
 lea ausbuf(a5),a0
 bsr prtco2                     * Ausgeben
 lea fin3txt(pc),a0
 bsr prtco2                     * Text ausgeben
 lea ausbuf(a5),a0
 move d1,d0
 bsr print4d                    * Anzahl Symbole ablegen
 lea ausbuf(a5),a0
 bsr prtco2                     * Buffer ausgeben
 bsr crlfe
 tst.b debug(a5)
 beq.s ass3c                    * Wenn Debug an, dann Ende Debug-Tab. ausgeben
 lea ausbuf(a5),a0              * Ziel
 lea fin4txt(pc),a1             * Quelltext
ass3b:
 move.b (a1)+,(a0)+             * Text übertragen
 bne.s ass3b                    * Null ist Ende
 lea ausbuf(a5),a0
 move.l debugak(a5),d0          * Adresse holen
 bsr print6x                    * In ASCII wandeln
 move.b #' ',(a0)               * Null am Ende überschreiben
 bsr putausba                   * und ausgeben
ass3c:
 bsr crlfe                      * Eine Zeile Freiraum
 moveq #$c,d0
 bsr co2ausa                    * Seitenvorschub
 moveq #'0',d0
 bsr esc7                       * Jetzt auf jeden Fall wieder Software-Scroll
 move.b (a7)+,cotempo(a5)       * Für spätere Ausgaben alte Scrollart
 bra carres                      * Ende

assinit:                        * Initialisieren der Variablen für Assembler
 clr.l rscount(a5)              * RS-Zähler auf Null
 clr.l offset(a5)               * Kein Offset bisher
 move.l pcorg(a5),pcstand(a5)   * Anfangs PC-Stand
 move.l stxtxt(a5),akttxt(a5)   * Anfang des Textes
 movea.l macrotab(a5),a0        * Macrotabelle
 clr (a0)+                      * rücksetzen
 rts                             * Adresse der Tabelle zurückliefern

kopfaus:                        * Überschrift ausgeben
 move.l a1, -(a7)
 lea kopftxt(pc),a1
 lea ausbuf(a5), a0
kpfaus1a:
 move.b (a1)+, (a0)+            * Überschrift nach ausbuf
 bne.s kpfaus1a
 subq.l #1, a0                  * Null raus
 bsr prtcpu                     * CPU-Name nach ausbuf
 subq.l #1, a0                  * Null raus
 lea kopftxt1(pc), a1
kpfaus1b:
 move.b (a1)+, (a0)+            * Überschrift 3.Teil nach ausbuf
 bne.s kpfaus1b
 subq.l #1, a0                  * Null raus
 bsr prtvers                    * Versionsnummer nach ausbuf
 lea kopftxt2(pc), a1
kpfaus1c:
 move.b (a1)+, (a0)+            * Überschrift 3.Teil nach ausbuf
 bne.s kpfaus1c
 movea.l (a7)+, a1
 lea ausbuf(a5), a0             * Mit Seitenvorschub
kopfaus1:
 clr.b zeilen(a5)               * Wieder erste Zeile
 bsr prtco2                     * Text ausgeben
 addq #1,pagecnt(a5)            * Eine Seite mehr vorhanden
 lea ausbuf(a5),a0
 move pagecnt(a5),d0            * Seitennummer
 bsr print4d                    * Nummer der Seite ausgeben
 lea ausbuf(a5),a0
 bsr prtco2                     * Text ausgeben
 bsr crlfe
 bra crlfe                       * Eine Zeile frei

kopftxt:
 DC.b $c
 DC.b '(C) 1991 Ralph Dombrowski / 2009 Jens Mewes ',0

kopftxt1:
 DC.b 'Assembler ',0

kopftxt2:
 DC.b ' Seite ',0

fintxt:
 DC.b '  Endadresse PC',$d

fin1txt:
 DC.b '  Endadresse PC + OFFSET',$d

fin2txt:
 DC.b '        Fehler entdeckt',$d,0

fin3txt:
 DC.b '  Ende-Symboltabelle / Anzahl Symbole : ',0

fin4txt:
 DC.b '        Ende-Debug-Tabelle',$d,0

 ds 0

insst EQU 24                    * Start Befehlsteil

expr1:
 bsr igbn                       * Leerzeichen ignorieren
 bsr expr                       * Arithmetischen Ausdruck auswerten
 tst d1
 beq errs1                      * Syntax-Fehler
 cmp #5,d1
 beq erru1                      * Undefiniertes Symbol
 rts

geteinbuf:                      * Eine Zeile holen
 clr errflag(a5)                * Kein Fehler in dieser Zeile bisher
 lea einbuf(a5),a0              * Ziel
 lea ausbuf+insst(a5),a1        * Ziel für Ausgabe
 movea.l akttxt(a5),a2          * Zeilenanfang
 moveq #0,d1                    * Bisher kein Zeichen
getein1:
 move.b (a2)+,d0                * Zeichen holen
 bne.s getein1a                 * Nicht Null, also weiter
 moveq #$d,d0
 move #2,errflag(a5)            * Ende erreicht
getein1a:
 cmp.b #$27,d0                  * Texte
 beq.s getein2b
 cmp.b #$a,d0                   * LF ignorieren
 beq.s getein1
 cmp.b #' '-1,d0
 bhi.s getein1b
 cmp.b #$d,d0                   * CR nicht wandeln !!!
 beq.s getein1b
 moveq #' ',d0                  * Controlzeichen in Leerzeichen wandeln
getein1b:
 addq #1,d1
 cmp #131-insst,d1              * Zeilenlänge
 bpl.s getein1c
 move.b d0,(a1)+
getein1c:
 cmp #131,d1                    * Zeilenlänge
 bpl.s getein1d
 bsr bucheck                    * In Großbuchstaben wandeln
 move.b d0,(a0)+                * Ablegen
getein1d:
 cmp.b #$d,d0
 bne.s getein1                   * Ende Schleife
 move.b #$d,ausbuf+131(a5)      * Sicherheitsende
 move.l a2,akttxt(a5)           * Adresse der nächsten Zeile merken
 rts
getein2:
 move.b (a2)+,d0                * Text-Zeichen holen
 bne.s getein2a                 * Nicht Null, also weiter
 moveq #$d,d0
 move #2,errflag(a5)            * Ende erreicht
getein2a:
 cmp.b #$27,d0                  * Text-Ende
 beq.s getein1b
 cmp.b #$a,d0                   * LF ignorieren
 beq.s getein2
getein2b:
 addq #1,d1
 cmp #131-insst,d1              * Zeilenlänge
 bpl.s getein2c
 move.b d0,(a1)+
getein2c:
 cmp #131,d1                    * Zeilenlänge
 bpl.s getein2d
 move.b d0,(a0)+                * Ablegen (nicht in Großbuchstaben wandeln)
getein2d:
 cmp.b #$d,d0
 bne.s getein2                   * Ende
 move.b #$d,ausbuf+131(a5)      * Sicherheitsende
 move.l a2,akttxt(a5)           * Adresse der nächsten Zeile merken
 rts

putausbuf:                      * ausbuf ausgeben
 cmp #2,passflag(a5)            * Zweiter Durchgang ?
 bne.s putausbfi                * Nein, dann keine Ausgabe
 cmp.b #1,iostat(a5)            * Nur Fehlerausgabe ?
 bne.s putausba                 * Nein, dann Ausgabe
 tst errflag(a5)                * Fehler vorhanden ?
 beq.s putausbfi                * Nein, dann Ende
putausba:
 lea ausbuf(a5),a0              * Quelle
put1lp:
 move.b (a0)+,d0                * Zeichen holen
 beq carset                     * Ende durch Null -> Leerzeile ohne Ausgabe
 bsr co2ausa                    * Ausgabe ohne Spezialabfragen
 cmp.b #$d,d0
 bne.s put1lp                    * Schleife fo rtsetzen, bis CR kommt
 moveq #$a,d0                   * Danach LF ausgeben
 bsr co2ausa                    * Ausgabe ohne Spezialabfragen
 move.b dflag2(a5),d0
 cmp.b zeilen(a5),d0
 beq kopfaus                    * Überschrift ausgeben, falls neue Seite
putausbfi:
 rts

initcode:                       * ausbuf vorbereiten
 lea ausbuf+8(a5),a0            * Ab dort gilt
 move.l a0,auspoi(a5)           * Pointer für Ablage
 move #8,auszahl(a5)            * Anzahl der ausgegebenen Zeichen(wegen Adresse)
 moveq #insst/4-1,d1            * Anzahl
 lea ausbuf(a5),a0              * Ziel
init1c:
 move.l #'    ',(a0)+           * Vorlöschen
 dbra d1,init1c
 move.b #$d,(a0)+               * Endekennung
 rts

putlong:
 cmp #2,passflag(a5)            * 2. Durchgang ?
 beq.s putlong1                 * Ja
 addq.l #4,pcstand(a5)          * Nein, deshalb nur PC erhöhen
 rts
putlong1:
 movem.l d1/a0,-(a7)            * Register retten
 cmp #insst-9,auszahl(a5)       * Abfrage, ob noch Platz
 bcs.s put1lg
 bsr newput                     * Nein, deshalb alte Zeile ausgeben und Init
put1lg:
 movea.l auspoi(a5),a0          * Zeiger auf Ausgabeadresse
 bsr print8x                    * Dort Code ablegen für Ausgabe
 move.b #' ',(a0)+              * Danach Leerzeichen lassen
 move.l a0,auspoi(a5)           * Neuer Pointer
 add #9,auszahl(a5)             * 9 Zeichen weiter
 movea.l pcstand(a5),a0         * Zieladresse
 move a0,d1
 lsr #1,d1                      * Test, ob ungerade
 bcc.s put12lg                  * Wenn nicht, dann OK
 addq.l #1,a0                   * Sonst Adresse in Ordnung bringen
 pea einbuf(a5)
 move.l (a7)+,errpoi(a5)        * Zeiger auf Fehler
 move #1,errflag(a5)            * Fehler aufgetreten
 move #5,errart(a5)             * Art des Fehlers
 addq #1,errcnt(a5)             * Ein Fehler mehr vorhanden
put12lg:
 addq.l #4,pcstand(a5)          * PC erhöhen
 adda.l offset(a5),a0           * OFFSET addieren
 move.l d0,(a0)+                * Wert ablegen
 movem.l (a7)+,d1/a0
 rts

putword:                        * Wie putlong nur mit Wortausgabe
 cmp #2,passflag(a5)
 beq.s putword1
 addq.l #2,pcstand(a5)
 rts
putword1:
 movem.l d1/a0,-(a7)
 movea.l auspoi(a5),a0
 cmp #insst-5,auszahl(a5)
 bcs.s put1wo
 bsr newput
put1wo:
 bsr print4x
 move.b #' ',(a0)+
 move.l a0,auspoi(a5)
 addq #5,auszahl(a5)
put2wo:
 movea.l pcstand(a5),a0
 move a0,d1
 lsr #1,d1
 bcc.s put12wo
 addq.l #1,a0
 pea einbuf(a5)
 move.l (a7)+,errpoi(a5)
 move #1,errflag(a5)
 move #5,errart(a5)
 addq #1,errcnt(a5)
put12wo:
 addq.l #2,pcstand(a5)
 adda.l offset(a5),a0
 move.w d0,(a0)+
 movem.l (a7)+,d1/a0
 rts

putbyte:                        * Wie putword nur mit Byte und mit ungeraden
 cmp #2,passflag(a5)            * Adressen
 beq.s putbyte1
 addq.l #1,pcstand(a5)
 rts
putbyte1:
 movem.l d1/a0,-(a7)
 movea.l auspoi(a5),a0
 cmp #insst-3,auszahl(a5)
 bcs.s put1by
 bsr.s newput
put1by:
 bsr print2x
 move.b #' ',(a0)+
 addq #3,auszahl(a5)
put2by:
 move.l a0,auspoi(a5)
 movea.l pcstand(a5),a0
 addq.l #1,pcstand(a5)
 adda.l offset(a5),a0
 move.b d0,(a0)+
 movem.l (a7)+,d1/a0
 rts

putobyte:                       * Wie putbyte ohne Leerzeichen nach Ausgabe
 cmp #2,passflag(a5)
 beq.s puto1byte
 addq.l #1,pcstand(a5)
 rts
puto1byte:
 movem.l d1/a0,-(a7)
 movea.l auspoi(a5),a0
 cmp #insst-3,auszahl(a5)
 bcs.s put1oby
 bsr.s newput
put1oby:
 bsr print2x
 move.b #' ',(a0)
 addq #2,auszahl(a5)
 bra.s put2by

newput:
 move.l d0,-(a7)
 bsr putausbuf                  * Alte Zeile ausgeben
 bsr initcode                   * Init Buffer
 bsr.s getq1                    * Adresse ausgeben
 move.l (a7)+,d0
 addq.l #2,a0                   * a0 zwei Zeichen hinter Adresse
 rts

getquelle:
 bsr putausbuf                  * Alte Zeile ausgeben
 bsr initcode                   * Init ausbuf
 bsr geteinbuf                  * Neue Zeile holen
getq1:
 move.l pcstand(a5),d0
 lea ausbuf(a5),a0
 bsr print6x                    * Adresse ausgeben
 move.b #' ',(a0)               * Null am Ende überschreiben
 rts

absl   EQU  $2000               * Codierung der einzelnen Adressierungsarten
absw   EQU  $1000               * Jede Art hat ihr eigenes Bit
indir  EQU  $0800               * Dadurch sind auch Kombinationen in der Abfrage
decre  EQU  $0400               * und Erstellung möglich
incre  EQU  $0200
dreg   EQU  $0100
areg   EQU  $0080
displ  EQU  $0040
pcadr  EQU  $0020
indx   EQU  $0010

* d0 = ist Datenwert, falls einer vorhanden
* d2 = Modecode nach A68K
* d3 = Extensioncode für Index-Mode
* d4 = Bitcode

getea:                          * Adressierungsart feststellen
 bsr igbn                       * Leerzeichen ignorieren
 cmp.b #'-',(a0)                * Predecrement
 bne.s getea1
 cmp.b #'(',1(a0)               * Dann muß Klammer folgen
 bne getea5                     * Nicht, dann nur negative Zahl möglich
 addq.l #2,a0
 bsr checkan                    * Adressregister muß folgen
 bcs getea50                    * Sonst nur Klammerrechnung möglich
 bsr igbn                       * Leerzeichen ignorieren
 cmp.b #')',(a0)
 bne errs1                      * Wenn nicht Klammer zu, dann Fehler
 addq.l #1,a0
 move d5,d2                     * Registernummer nach d2
 or #%100000,d2                 * Und Code dazu
 move #decre,d4                 * Adressierungsart ist decrement
 rts

getea1:                         * Indirekt oder Postincrement
 cmp.b #'(',(a0)                * Klammer auf am Anfang
 bne.s getea3                   * Nein, dann weiter
 addq.l #1,a0
 bsr checkan                    * Jetzt muß Adressregister folgen
 bcs.s getea501                 * Sonst nur Klammerrechnung möglich
 bsr igbn
 cmp.b #')',(a0)                * Klammer zu muß kommen
 bne errs1                      * Sonst Fehler
 addq.l #1,a0
 cmp.b #'+',(a0)                * Jetzt Entscheidung ob postincrement
 bne.s getea2                   * Nein, dann weiter
 addq.l #1,a0
 move d5,d2                     * Register
 or #%011000,d2                 * Plus Mode
 move #incre,d4                 * Adressierungsart ist postincrement
 rts

getea2:                         * Indirekt
 move d5,d2                     * Register
 or #%010000,d2                 * Mode
 move #indir,d4                 * Adressierungsart ist indirekt
 rts

getea3:                         * Keine Klammer am Anfang
 bsr checkdn                    * Vielleicht Datenregister
 bcs.s getea4                   * Nein
 move d5,d2                     * Ja, Registernummer nach d2
 move #dreg,d4                  * Register direkt
 rts

getea4:
 bsr checkan                    * Vielleicht Adressregister
 bcs.s getea5                   * Nein
 move d5,d2                     * Nummer
 or #%001000,d2                 * Mode
 move #areg,d4                  * Adressregister direkt
 rts

getea50:
 subq.l #1,a0
getea501:
 subq.l #1,a0
getea5:
 bsr expr1                      * Arithmetischen Ausdruck auswerten
 tst d1
 beq carset                     * Syntax-Fehler
 bsr igbn                       * Leerzeichen ignorieren
 cmp.b #'(',(a0)
 beq.s getea6                   * Jetzt kann Klammer folgen
 cmp.b #'.',(a0)
 bne.s getea53                  * Oder Größenangabe
 addq.l #1,a0
 cmp.b #'L',(a0)                * Langwort ?
 beq.s getea52
 cmp.b #'W',(a0)                * Oder Wort
 beq.s getea51
 cmp.b #'S',(a0)                * W oder S ist egal
 bne errs1                      * Sonst Fehler
getea51:
 addq.l #1,a0                   * Wort-Größe
 move #absw,d4                  * Adressierungsart ist absolut kurz
 moveq #%111000,d2              * Mode
 rts

getea52:
 addq.l #1,a0
getea53:
 move #absl,d4                  * Adressierungsart ist absolut lang
 moveq #%111001,d2              * Mode
 rts

getea6:
 addq.l #1,a0                   * Mit Klammer nach Wert
 bsr igbn
 cmp.b #'P',(a0)                * PC-relativ ?
 bne.s getea62                  * Nein
 cmp.b #'C',1(a0)
 bne.s getea62                  * Nein
 addq.l #2,a0
 bsr igbn
 cmp.b #',',(a0)                * Danach noch ein Register ?
 beq.s getea61                  * Ja
 cmp.b #')',(a0)                * Klammer zu muß folgen
 bne errs1                      * Sonst Fehler
 addq.l #1,a0
 move #displ!pcadr!indir,d4     * Adressierungsart ist PC-relativ mit Displacemt
 moveq #%111010,d2              * Mode
 rts

getea61:
 addq.l #1,a0
 move #displ!pcadr!indir!indx,d4 * Adressierungsart ist PC-relativ mit Displacemt
 moveq #%111011,d2              * und Index
 bra.s getea64

getea62:
 bsr checkan                    * Nicht PC-relativ also dann Adressregister
 bcs errs1                      * Fehler
 move d5,d2                     * Nummer merken
 bsr igbn
 cmp.b #',',(a0)                * Wenn nicht ',', dann OK
 beq.s getea63
 cmp.b #')',(a0)                * Dann muß aber auch Klammer folgen
 bne errs1
 addq.l #1,a0
 move #displ!indir,d4           * Adressierungsart ist Adressregister indirekt
 or #%101000,d2                 * Mit Displacement
 rts

getea63:
 addq.l #1,a0
 move #displ!indir!indx,d4      * Jetzt Indirekt mit Displacement und Index
 or #%110000,d2

getea64:
 bsr.s checkan                  * Also muß jetzt ein Register folgen
 bcs.s getea65                  * Nicht Adressregister
 move d5,d3                     * Nummer Adressregister
 ror #4,d3                      * An richtige Stelle
 or #$8000,d3                   * Und Bit, daß Adressregister
 bra.s getea66                  * OK, jetzt weiter testen
getea65:
 bsr.s checkdn                  * Es muß jetzt Datenregister sein
 bcs errs1                      * Fehler
 move d5,d3
 ror #4,d3                      * Nummer an richtige Stelle
getea66:
 cmp.b #'.',(a0)                * Längenangabe ?
 bne.s getea68                  * Nein
 addq.l #1,a0                   * Ja, also muß W oder L folgen
 cmp.b #'W',(a0)
 beq.s getea67                  * Es ist W
 cmp.b #'L',(a0)
 bne errs1                      * Nicht W oder L, also Fehler
 or #$0800,d3                   * Es ist L
getea67:
 addq.l #1,a0
getea68:
 bsr igbn                       * Leerzeichen ignorieren
 cmp.b #')',(a0)+               * Jetzt muß Klammer folgen
 beq carres                     * OK
 subq.l #1,a0
 bra errs1                       * Fehler

kommack:                        * Test, ob Komma folgt
 bsr igbn                       * Ohne Leerzeichen
 cmp.b #',',(a0)
 bne errs1                      * Kein Komma, also Fehler
 addq.l #1,a0                   * OK, also a0 erhöhen
 rts

checkan:                        * Test, ob Adressregister
 bsr igbn
 cmp.b #'A',(a0)
 bne carset                     * Nein
 bra.s checkda                   * Ja, jetzt Nummer holen

checkdn:                        * Test, ob Datenregister
 bsr igbn
 cmp.b #'D',(a0)
 bne carset                     * Nein
checkda:
 cmp.b #'0',1(a0)               * Es ist Register, deshalb Nummer holen
 bcs carset                     * Fehler
 cmp.b #'7'+1,1(a0)
 bcc carset                     * Fehler
 addq.l #1,a0                   * Zahl ist OK
 move.b (a0)+,d5                * ASCII-Zeichen holen
 and #7,d5                      * Wandeln
 bra carres                      * OK

putorea:                        * Aus Befcode und d2 Mode bilden und ausgeben
 move d0,-(a7)
 move d6,d0
 or d2,d0                       * Verodern
 bsr putword                    * Ausgeben
 move (a7)+,d0
 rts

codea:
 bsr.s putorea                  * Befehlscode und Adressmode verknüpft ausgeben

putea:                          * Adressierungsart ausgeben
 move d2,d5                     * Adressierungsart merken
 and.b #%111000,d5              * Nur Mode, ohne Register
 cmp.b #%101000,d5
 bne.s *+10                     * Wort ausgeben
 bsr rangewck
 bra putword

 cmp.b #%110000,d5
 bne.s put1ea
 bsr rangebck
 and #$ff,d0
 or d3,d0
 bra putword                     * Displacement ausgeben  ( Ist nur Byte )

put1ea:
 cmp.b #%111000,d2
 beq putword                    * Absolut Kurz (Wort)

 cmp.b #%111001,d2
 beq putlong                    * Absolut Lang (Langwort)

 cmp.b #%111010,d2
 bne.s put2ea
 sub.l pcstand(a5),d0           * PC relativ / d(pc)
 bsr rangew1ck                  * Bereich testen
 bra putword                     * Wort ausgeben

put2ea:
 cmp.b #%111011,d2
 bne carres
 sub.l pcstand(a5),d0           * PC mit Displacement / d(pc,rx)
 bsr rangeb1ck                  * Bereichstest
 and #$ff,d0
 or d3,d0                       * Nur Byte
 bra putword                     * Displacement ausgeben ( Ist nur Byte )

assline:                        * Eine Zeile übersetzen
 bsr co2test                    * Ctrl-C, Ctrl-S, Ctrl-Q oder <Space>
 bcs abbruch
 cmp #2,errflag(a5)             * Ende
 beq carres                     * Ja
 move.l pcstand(a5),anfstand(a5) * PC merken
 lea einbuf(a5),a0              * Quelle der Zeile
 bsr igbn                       * Leerzeichen ignorieren
 move.l a0,-(a7)
 bsr setupname                  * Ist es ein Name ?
 bcs assline5                   * Nein !
 cmp.b #':',(a0)                * Ja, dann kann ':' folgen
 bne.s assline2                 * Nicht, dann vielleicht EQU
 addq.l #4,a7                   * Stack reinigen
 addq.l #1,a0                   * ':' überspringen
 movem.l d2/d3/a0,-(a7)         * Register retten
 bsr setigname                  * Nächster Name
 move.l d2,d4                   * Namen merken
 movem.l (a7)+,d2/d3/a0         * Register zurück
 move.l d2,nametab(a5)          * Namen zurück
 move.l d3,nametab+4(a5)
 cmp.l #'RS  ',d4               * RS-Anweisung ?
 beq codrs                      * Ja, dann auswerten
 move.l pcstand(a5),d0          * Das ist Wert für Zuweisung
 moveq #3,d1                    * Als Langwort definiert
 bsr newval                     * Symbol setzen, wenn neu
 bcc.s assline1                 * OK, eingetragen
 cmp.l datenwert(a3),d0         * Ist schon definiert, deshalb Vergleich, ob
 bsr errnmult                   * es der selbe Wert ist, wenn nein, dann Fehler
 move.l d0,datenwert(a3)        * Jetzt mit neuem Wert eintragen
 move d1,attribut(a3)           * Als Langwort
assline1:
 bsr igbn
 bra.s assline6                  * Weiter, vielleicht folgt noch etwas
assline2:
 move.l d2,d4                   * Namen
 move.l d3,d5                   * merken
 bsr setigname                  * Jetzt weiter testen
 bcs.s assline5                 * Weiter, da kein Name folgt
 moveq #0,d7                    * Kennung EQU
 cmp.l #'EQU ',d2               * Kommt eine EQU-Definition ?
 beq.s assline3                 * Ja
 cmp.l #'NEWE',d2               * Kommt eine NEWEQU-Definition ?
 bne.s assline5                 * Nein
 cmp.l #'QU  ',d3
 bne.s assline5                 * Nein
 moveq #1,d7                    * Kennung NEWEQU
assline3:
 bsr expr1                      * Ja, deshalb jetzt arithmetischen Ausdruck
 move.l d4,d2                   * berechnen
 move.l d5,d3
 move.l a0,(a7)                 * a0 auf Stand bringen
 lea ausbuf(a5),a0
 move #'= ',(a0)+
 bsr print8x                    * Für Ausgabe
 move.b #' ',(a0)               * Null überschreiben
 movea.l (a7)+,a0
 move.l d2,nametab(a5)          * Namen abspeichern
 move.l d3,nametab+4(a5)
 bsr newval                     * Und in Symboltabelle eintragen
 bcc.s assline7                 * OK
 tst d7                         * NEWEQU ?
 bne.s assline4                 * Ja, dann nur überschreiben
 cmp.l datenwert(a3),d0
 bsr errnmult                   * Mehrfach definiert
assline4:
 move.l d0,datenwert(a3)        * Schon vorhanden, deshalb einfach überschreiben
 move d1,attribut(a3)           * Länge eintragen
 bra.s assline7

assline5:
 movea.l (a7)+,a0               * a0 zurück
assline6:
 cmp.b #'.',(a0)
 beq macro
 cmp.b #$d,(a0)
 beq.s assline8                 * Ende
 cmp.b #'*',(a0)
 beq.s assline8                 * Ende
 cmp.b #';',(a0)
 beq.s assline8                 * Ende
 bsr verteile                   * Sonst Befehl auswerten
 cmp #2,errflag(a5)
 beq carres                     * Ende wenn END
assline7:
 cmp #2,passflag(a5)            * Alles folgende nur beim zweiten Durchlauf
 bne carres
 bsr igbn                       * Leerzeichen ignorieren
 cmp.b #$d,(a0)
 beq.s assline9                 * Ende
 cmp.b #'*',(a0)
 beq.s assline9                 * Ende
 cmp.b #';',(a0)
 beq.s assline9                 * Ende
 bsr errs1                      * Fehler
 bra erranalyse                  * Und Fehleranalyse
assline8:
 cmp #2,passflag(a5)
 bne carres                     * Beim ersten Durchlauf Ende
assline9:
 tst errflag(a5)
 bne erranalyse                 * Fehler, deshalb Auswertung
 rts

checkcc:                        * Bedingung testen und berechnen der Bits
 move.b (a0),d0                 * Ersten Wert holen
 bsr bucheck                    * Muß Buchstabe sein
 bcs errs1                      * Sonst Fehler
 asl #8,d0                      * Verschieben
 move d0,d1                     * Und merken
 move.b 1(a0),d0                * Nächsten Wert holen
 bsr bucheck                    * Kann auch Buchstabe sein
 bcs.s checkcc1                 * Wenn nicht, dann OK
 or d0,d1                       * Sonst zu einem Wort verbinden
 move.b 2(a0),d0                * Nächsten Wert holen
 bsr bucheck                    * Darf nicht mehr Buchstabe sein
 bcc errs1                      * Sonst Fehler
 addq.l #2,a0                   * a0 erhöhen
 bra.s checkcc2
checkcc1:
 addq.l #1,a0                   * a0 erhöhen
 move.b #' ',d1                 * Zweiter Buchstabe ist Leerzeichen
checkcc2:
 lea cctab(pc),a1               * Adresse Tabelle
 moveq #16-1,d6                 * 18 Werte prüfen
checkcc3:
 cmp (a1)+,d1                   * Vergleich
 beq.s checkcc4                 * OK, gefunden
 dbra d6,checkcc3                * Nächsten Wert suchen
 moveq #%0100,d6
 cmp #'HS',d1                   * HS
 beq.s checkcc4
 moveq #%0101,d6
 cmp #'LO',d1                   * und LO extra
 bne errs1                      * Fehler, nicht gefunden
checkcc4:
 lsl #8,d6
 rts

cctab:                          * Tabelle der Bedingungen
 DC.b 'LE'
 DC.b 'GT'
 DC.b 'LT'
 DC.b 'GE'
 DC.b 'MI'
 DC.b 'PL'
 DC.b 'VS'
 DC.b 'VC'
 DC.b 'EQ'
 DC.b 'NE'
 DC.b 'CS'
 DC.b 'CC'
 DC.b 'LS'
 DC.b 'HI'
 DC.b 'F '
 DC.b 'T '

checkno:                        * Fehler, wenn Größenangabe
 bsr.s setsbw                   * Größe holen
 bcs errsize                    * Fehler
 rts

checkb:                         * Fehler, wenn nicht Byte
 bsr.s setsbw
 bcc.s checksifi                * Wenn keine Angabe, dann OK
 tst wordbyte(a5)
 bne errsize
 rts

checkw:                         * Fehler, wenn nicht Wort
 bsr.s setsbw
 bcc.s checksifi                * Wenn keine Angabe, dann OK
 cmp #1,wordbyte(a5)
 bne errsize
 rts

checkl:                         * Fehler, wenn nicht Long
 bsr.s setsbw
 bcc.s checksifi                * Wenn keine Angabe, dann OK
 cmp #2,wordbyte(a5)
 bne errsize
 rts

checkbw:                        * Fehler, wenn nicht Byte oder Wort
 bsr.s setsbw
 bcc.s checkwset
 cmp #1,wordbyte(a5)
 beq.s checksifi
 tst wordbyte(a5)
 bne errsize
 rts

checkwl:                        * Fehler, wenn nicht Wort oder Long
 bsr.s setsbw
 bcc.s checkwset
 cmp #1,wordbyte(a5)
 beq.s checksifi
 cmp #2,wordbyte(a5)
 bne errsize
 rts

checkbwl:                       * Alles erlaubt
 bsr.s setsbw                   * Setzt auf Wort, wenn keine Angabe
 bcs.s checksifi
checkwset:                      * Wenn keine Angabe, dann Wort
 move #1,wordbyte(a5)
checksifi:
 rts

setsbw:                         * Größe holen
 move #3,wordbyte(a5)           * Voreinstellung keine Größe
 cmp.b #'.',(a0)                * Nur nach '.' kann Größenangabe kommen
 bne carres
 cmp.b #'S',1(a0)               * Vielleicht 'S'
 beq.s setsbw1
 cmp.b #'B',1(a0)               * Oder 'B'
 bne.s setsbw2
setsbw1:
 addq.l #2,a0
 clr wordbyte(a5)               * Nur Byte
 bra carset
setsbw2:
 cmp.b #'L',1(a0)               * 'L' ?
 bne.s setsbw3
 addq.l #2,a0                   * Ja
 move #2,wordbyte(a5)           * Langwort
 bra carset
setsbw3:
 cmp.b #'W',1(a0)               * Oder 'W'
 bne.s setsbw4                  * Nein, dann Fehler
 addq.l #2,a0
 move #1,wordbyte(a5)           * Wort
 bra carset
setsbw4:
 bsr errs1                      * Syntaxfehler
 bra carres                      * Keine Größe

symcode EQU 8
symtype EQU 8+2
symadr  EQU 8+2+2
symlg   EQU 8+2+2+2

verteile:                       * Befehl auswerten
 move.l a0,d6
 bsr setupname
 bcs errs1                      * Fehler
 moveq #1,d0                    * Erster Befehl
 moveq #symzahl,d1              * Letzter Befehl
suchkey:
 move d0,d4                     * Erster Wert
 add d1,d4                      * Letzter Wert
 lsr #1,d4                      * Arithmetisches Mittel bilden
 move d4,d7
 mulu #symlg,d7                 * Länge eines Eintrags
 lea befehle-symlg(pc,d7.w),a3  * Adresse Befehl
 cmp.l (a3)+,d2                 * Vergleich
 bmi.s suchkl1                  * Kleiner
 bhi.s suchgr1                  * Größer
 cmp.l (a3),d3                  * Zweiter Teil
 bmi.s suchkl1                  * Kleiner
 bhi.s suchgr1                  * Größer
 move symcode-4(a3),d6          * Code für Befehl
 move symtype-4(a3),attcode(a5) * Alternativ
 move symadr-4(a3),d0           * Adresse berechnen
 jmp befehle(pc,d0)              * Und aufrufen

suchkl1:                        * Ist kleiner
 subq #1,d4
 move d4,d1                     * Also im ersten Teil weitersuchen
 cmp d0,d1                      * Letzen Wert geprüft
 bpl.s suchkey
 bra.s verteil0                  * Nicht gefunden

suchgr1:                        * Ist größer
 addq #1,d4
 move d4,d0                     * Also im zweiten Teil weitersuchen
 cmp d0,d1                      * Letzten Wert geprüft
 bpl.s suchkey
                                * Nicht gefunden
verteil0:
 movea.l d6,a0                  * Nicht gefunden, deshalb spezieller Test
 cmp.b #'S',(a0)                * Folgt 'S'
 bne.s verteil1                 * Nein
 addq.l #1,a0
 bsr checkcc                    * Test, ob Bedingung
 or #%0101000011000000,d6       * Code für SCC
 bra codtas                      * Und Befehl auswerten

verteil1:
 cmp.b #'B',(a0)               * Ist es BCC ?
 bne.s verteil2                 * Nein
 addq.l #1,a0
 bsr checkcc                    * Bedingungen holen
 or #%0110000000000000,d6       * Code für BCC
 bra codbra                      * Auswerten

verteil2:
 cmp.b #'D',(a0)                * Jetzt kann es nur noch dbra sein
 bne errs1                      * oder Fehler
 cmp.b #'B',1(a0)
 bne errs1                      * Fehler
 addq.l #2,a0
 bsr checkcc                    * Bedingung holen
 or #%0101000011001000,d6       * Code für dbcc
 bra coddbcc                     * Auswerten

befehle:                        * Tabelle der Befehle
 DC.b 'ABCD    '                * Befehl
 DC.w %1100000100000000         * Code
 DC.w 0                         * Alternativcode ( add/addi )
 DC.w codabcd-befehle           * Adresse

 DC.b 'ADD     '
 DC.w %1101000000000000
 DC.w %0000011000000000         * Addi
 DC.w codadd-befehle

 DC.b 'ADDA    '
 DC.w %1101000011000000
 DC.w 0
 DC.w codadda-befehle

 DC.b 'ADDI    '
 DC.w %0000011000000000
 DC.w 0
 DC.w codaddi-befehle

 DC.b 'ADDQ    '
 DC.w %0101000000000000
 DC.w 0
 DC.w codaddq-befehle

 DC.b 'ADDX    '
 DC.w %1101000100000000
 DC.w 0
 DC.w codaddx-befehle

 DC.b 'AND     '
 DC.w %1100000000000000
 DC.w %0000001000000000         * andi
 DC.w codand-befehle

 DC.b 'ANDI    '
 DC.w %0000001000000000
 DC.w 0
 DC.w codeori-befehle

 DC.b 'ASL     '
 DC.w %1110000100000000
 DC.w %1110000111000000
 DC.w codshift-befehle

 DC.b 'ASR     '
 DC.w %1110000000000000
 DC.w %1110000011000000
 DC.w codshift-befehle

 DC.b 'BCHG    '
 DC.w %0000000101000000
 DC.w %0000100001000000
 DC.w codbchg-befehle

 DC.b 'BCLR    '
 DC.w %0000000110000000
 DC.w %0000100010000000
 DC.w codbchg-befehle

 DC.b 'BRA     '
 DC.w %0110000000000000
 DC.w 0
 DC.w codbra-befehle

 DC.b 'BSET    '
 DC.w %0000000111000000
 DC.w %0000100011000000
 DC.w codbchg-befehle

 DC.b 'BSR     '
 DC.w %0110000100000000
 DC.w 0
 DC.w codbra-befehle

 DC.b 'BTST    '
 DC.w %0000000100000000
 DC.w %0000100000000000
 DC.w codbtst-befehle

 DC.b 'CHK     '
 DC.w %0100000110000000
 DC.w 0
 DC.w codchk-befehle

 DC.b 'CLR     '
 DC.w %0100001000000000
 DC.w 0
 DC.w codneg-befehle

 DC.b 'CMP     '
 DC.w %1011000000000000
 DC.w %0000110000000000         * cmpi
 DC.w codcmp-befehle

 DC.b 'CMPA    '
 DC.w %1011000011000000
 DC.w 0
 DC.w codadda-befehle

 DC.b 'CMPI    '
 DC.w %0000110000000000
 DC.w 0
 DC.w codaddi-befehle

 DC.b 'CMPM    '
 DC.w %1011000100001000
 DC.w 0
 DC.w codcmpm-befehle

 DC.b 'CO2SER  '                * Ausgabe über serielle Schnittstelle
 DC.w 6
 DC.w 0
 DC.w ausmode-befehle

 DC.b 'CRT     '                * Ausgabe auf Bildschirm
 DC.w 2
 DC.w 0
 DC.w ausmode-befehle

 DC.b 'DBRA    '
 DC.w %0101000111001000
 DC.w 0
 DC.w coddbcc-befehle

 DC.b 'DC      '
 DC.w 0
 DC.w 0
 DC.w coddc-befehle

 DC.b 'DEBUGAN '                * Debug anschalten
 DC.w 0
 DC.w 0
 DC.w debugon-befehle

 DC.b 'DEBUGAUS'                * Debug ausschalten
 DC.w 0
 DC.w 0
 DC.w debugoff-befehle

 DC.b 'DF      '
 DC.w 0
 DC.w 0
 DC.w coddf-befehle

 DC.b 'DIVS    '
 DC.w %1000000111000000
 DC.w 0
 DC.w codmuls-befehle

 DC.b 'DIVU    '
 DC.w %1000000011000000
 DC.w 0
 DC.w codmuls-befehle

 DC.b 'DS      '
 DC.w 0
 DC.w 0
 DC.w codds-befehle

 DC.b 'END     '
 DC.w 0
 DC.w 0
 DC.w codend-befehle

 DC.b 'EOR     '
 DC.w %1011000100000000
 DC.w %0000101000000000         * eori
 DC.w codeor-befehle

 DC.b 'EORI    '
 DC.w %0000101000000000
 DC.w 0
 DC.w codeori-befehle

 DC.b 'EXG     '
 DC.w %1100000100000000
 DC.w 0
 DC.w codexg-befehle

 DC.b 'EXT     '
 DC.w %0100100000000000
 DC.w 0
 DC.w codext-befehle

 DC.b 'ILLEGAL '
 DC.w %0100101011111100
 DC.w 0
 DC.w codall-befehle

 DC.b 'JMP     '
 DC.w %0100111011000000
 DC.w 0
 DC.w codjmp-befehle

 DC.b 'JSR     '
 DC.w %0100111010000000
 DC.w 0
 DC.w codjmp-befehle

 DC.b 'LEA     '
 DC.w %0100000111000000
 DC.w 0
 DC.w codlea-befehle

 DC.b 'LINK    '
 DC.w %0100111001010000
 DC.w 0
 DC.w codlink-befehle

 DC.b 'LSL     '
 DC.w %1110000100001000
 DC.w %1110001111000000
 DC.w codshift-befehle

 DC.b 'LSR     '
 DC.w %1110000000001000
 DC.w %1110001011000000
 DC.w codshift-befehle

 DC.b 'LST     '                * Ausgabe auf Drucker
 DC.w 3
 DC.w 0
 DC.w ausmode-befehle

 DC.b 'MACRO   '
 DC.w 1
 DC.w 0
 DC.w defmacro-befehle

 DC.b 'MOVE    '
 DC.w %0000000000000000
 DC.w 0
 DC.w codmove-befehle

 DC.b 'MOVEA   '
 DC.w %0010000001000000
 DC.w 0
 DC.w codmovea-befehle

 DC.b 'MOVEC   '
 DC.w %0100111001111010
 DC.w 0
 DC.w codmovec-befehle

 DC.b 'MOVEM   '
 DC.w %0100100010000000
 DC.w 0
 DC.w codmovem-befehle

 DC.b 'MOVEP   '
 DC.w %0000000000001000
 DC.w 0
 DC.w codmovep-befehle

 DC.b 'MOVEQ   '
 DC.w %0111000000000000
 DC.w 0
 DC.w codmoveq-befehle

 DC.b 'MOVES   '
 DC.w %0000111000000000
 DC.w 0
 DC.w codmoves-befehle

 DC.b 'MULS    '
 DC.w %1100000111000000
 DC.w 0
 DC.w codmuls-befehle

 DC.b 'MULU    '
 DC.w %1100000011000000
 DC.w 0
 DC.w codmuls-befehle

 DC.b 'NBCD    '
 DC.w %0100100000000000
 DC.w 0
 DC.w codtas-befehle

 DC.b 'NEG     '
 DC.w %0100010000000000
 DC.w 0
 DC.w codneg-befehle

 DC.b 'NEGX    '
 DC.w %0100000000000000
 DC.w 0
 DC.w codneg-befehle

 DC.b 'NEWMACRO'
 DC.w 0
 DC.w 0
 DC.w defmacro-befehle

 DC.b 'NIL     '                * Ausgabe abschalten
 DC.w 1
 DC.w 0
 DC.w ausmode-befehle

 DC.b 'NOP     '
 DC.w %0100111001110001
 DC.w 0
 DC.w codall-befehle

 DC.b 'NOT     '
 DC.w %0100011000000000
 DC.w 0
 DC.w codneg-befehle

 DC.b 'OFFSET  '
 DC.w 0
 DC.w 0
 DC.w codoff-befehle

 DC.b 'OR      '
 DC.w %1000000000000000
 DC.w %0000000000000000         * ori
 DC.w codand-befehle

 DC.b 'ORG     '
 DC.w 0
 DC.w 0
 DC.w codorg-befehle

 DC.b 'ORI     '
 DC.w %0000000000000000
 DC.w 0
 DC.w codeori-befehle

 DC.b 'PEA     '
 DC.w %0100100001000000
 DC.w 0
 DC.w codpea-befehle

 DC.b 'RESET   '
 DC.w %0100111001110000
 DC.w 0
 DC.w codall-befehle

 DC.b 'ROL     '
 DC.w %1110000100011000
 DC.w %1110011111000000
 DC.w codshift-befehle

 DC.b 'ROR     '
 DC.w %1110000000011000
 DC.w %1110011011000000
 DC.w codshift-befehle

 DC.b 'ROXL    '
 DC.w %1110000100010000
 DC.w %1110010111000000
 DC.w codshift-befehle

 DC.b 'ROXR    '
 DC.w %1110000000010000
 DC.w %1110010011000000
 DC.w codshift-befehle

 DC.b 'RS      '
 DC.w 0
 DC.w 0
 DC.w codrsin-befehle

 DC.b 'RSRESET '
 DC.w 0
 DC.w 0
 DC.w codrsreset-befehle

 DC.b 'RSSET   '
 DC.w 0
 DC.w 0
 DC.w codrsset-befehle

 DC.b 'RTD     '
 DC.w %0100111001110100
 DC.w 0
 DC.w codstop-befehle           * Wie stop behandeln

 DC.b 'RTE     '
 DC.w %0100111001110011
 DC.w 0
 DC.w codall-befehle

 DC.b 'RTR     '
 DC.w %0100111001110111
 DC.w 0
 DC.w codall-befehle

 DC.b 'RTS     '
 DC.w %0100111001110101
 DC.w 0
 DC.w codall-befehle

 DC.b 'SBCD    '
 DC.w %1000000100000000
 DC.w 0
 DC.w codabcd-befehle

 DC.b 'STOP    '
 DC.w %0100111001110010
 DC.w 0
 DC.w codstop-befehle

 DC.b 'SUB     '
 DC.w %1001000000000000
 DC.w %0000010000000000         * subi
 DC.w codadd-befehle

 DC.b 'SUBA    '
 DC.w %1001000011000000
 DC.w 0
 DC.w codadda-befehle

 DC.b 'SUBI    '
 DC.w %0000010000000000
 DC.w 0
 DC.w codaddi-befehle

 DC.b 'SUBQ    '
 DC.w %0101000100000000
 DC.w 0
 DC.w codaddq-befehle

 DC.b 'SUBX    '
 DC.w %1001000100000000
 DC.w 0
 DC.w codaddx-befehle

 DC.b 'SWAP    '
 DC.w %0100100001000000
 DC.w 0
 DC.w codswap-befehle

 DC.b 'SYMCLR  '                * Symboltabelle löschen
 DC.w 0
 DC.w 0
 DC.w symclr-befehle

 DC.b 'TAS     '
 DC.w %0100101011000000
 DC.w 0
 DC.w codtas-befehle

 DC.b 'TRAP    '
 DC.w %0100111001000000
 DC.w 0
 DC.w codtrap-befehle

 DC.b 'TRAPV   '
 DC.w %0100111001110110
 DC.w 0
 DC.w codall-befehle

 DC.b 'TST     '
 DC.w %0100101000000000
 DC.w 0
 DC.w codneg-befehle

 DC.b 'UNLK    '
 DC.w %0100111001011000
 DC.w 0
 DC.w codunlk-befehle

 DC.b 'USR     '
 DC.w 5
 DC.w 0
 DC.w ausmode-befehle

lastsym:
symzahl EQU (lastsym-befehle)/symlg     * Anzahl der Befehle

*** MACRO-Verarbeitung ***

defmacro:
 bsr setigname                  * Namen des Macros holen
 bcc.s defmacr0                 * OK, Name richtig definiert
 bsr errs1                      * Syntax-Fehler
 bsr assline7                   * Fehler ausgeben
 moveq #1,d5                    * Fehler bei Macro-Definition
 bra.s defmacr4                  * Nur Ende suchen
defmacr0:
 moveq #0,d5                    * OK, Macroname in Ordnung
 movea.l macrotab(a5),a1        * Tabelle der Macros
 movea.l a1,a3                  * Adresse merken
 move (a3)+,d0                  * Anzahl
 beq.s defmacr3                 * Null, dann OK
defmacr1:
 cmp.l (a3)+,d2                 * Vergleich, ob Macro schon vorhanden
 bne.s defmacr2                 * Nein, dann weitersuchen
 cmp.l (a3),d3
 bne.s defmacr2                 * Nein, dann weitersuchen
 subq.l #4,a3                   * Pointer zurück
 subq #1,(a1)                   * Ausgleich für unten, da schon vorhanden
 tst d6
 bsr errnmult                   * Mehrfach definiert, wenn d6 <> 0
 bra.s defmacr3                  * Weiter
defmacr2:
 adda #12,a3                    * Pointer auf nächsten Namen
 subq #1,d0                     * Nächster Macro
 bne.s defmacr1                 * Schleife
defmacr3:
 addq #1,(a1)                   * Ein Macro mehr vorhanden
 move (a1)+,d0                  * Anzahl holen
 muls #16,d0                    * Mal Länge eines Eintrags
 adda.l d0,a1                   * Plus Anfangsadresse der Macrotabelle+2
 move.l a1,macroanf(a5)         * Macro-Anfang neu festlegen (Ans Ende Macrotab)
 move.l d2,(a3)+                * Neuen Macro eintragen (Oder überschreiben)
 move.l d3,(a3)+
 move.l akttxt(a5),(a3)+        * Anfangsadresse des Macro
 bsr assline7                   * Zeilenende ? (Fehler, wenn noch etwas folgt)
 moveq #-1,d7                   * Keine Zeile bisher
defmacr4:
 bsr co2test                    * Extraabfrage für Abbruch
 bcs abbruch
 bsr getquelle                  * Zeile holen und Alte ausgeben
 cmp #2,errflag(a5)
 bne.s *+10
 lea txtmacro(pc),a0
 bra errabbr                     * Ende Text und kein Ende Macro -> Abbruch
 addq #1,d7                     * Eine Zeile mehr vorhanden
 lea einbuf(a5),a0              * Zeilenanfang
 bsr setigname                  * Namen holen
 bcs.s defmacr4                 * Fehler
 cmp.l #'ENDM',d2
 bne.s defmacr4                 * Kein Ende
 cmp.l #'ACRO',d3
 bne.s defmacr4                 * Kein Ende
 tst d5
 bne.s defmacr5                 * Nicht abspeichern, da kein Name vorhanden
 move d7,(a3)+                  * Anzahl Zeilen merken
 clr (a3)+                      * Bisher kein Aufruf
 cmp #2,passflag(a5)
 beq.s defmacr5                 * Bei zweitem Durchgang weiter
 cmpa.l debugst(a5),a3          * Wenn Überlagerung Macro-Tabelle mit
 bmi.s defmacr5                 * Debug-Tabelle, dann Debug-Tabelle verschieben
 move.l a3,debugst(a5)          * Debug-Anfang neu festlegen
 move.l a3,debugak(a5)
defmacr5:
 rts

macro:                          * Macro übersetzen
 movea.l a0,a1                  * Adresse merken
 addq.l #1,a0                   * '.' überspringen
 bsr setupname                  * Namen holen
 bcc.s macro0                   * OK, dann weiter
 bsr errs1                      * Syntax-Fehler
 bra assline7                    * Ende der Zeile bearbeiten
macro0:
 movea.l macrotab(a5),a2        * Adresse der Definitionstabelle
 move (a2)+,d0                  * Anzahl der Macros
 bne.s macro1                   * Nicht Null, dann Macro suchen
 bsr erru1                      * Undefiniert
 bra assline7                    * Ende der Zeile bearbeiten
macro1:
 cmp.l (a2)+,d2                 * Macro suchen
 bne.s macro2                   * Nicht gefunden
 cmp.l (a2),d3
 beq.s macro3                   * OK, gefunden
macro2:
 adda #12,a2                    * Zum nächsten Eintrag
 subq #1,d0                     * Weitersuchen, falls noch
 bne.s macro1                    * ein Eintrag vorhanden ist
 bsr erru1                      * Undefiniert
 bra assline7                    * Rest der Zeile bearbeiten
macro3:
 lea einbuf(a5),a3
 suba.l a3,a0
 suba.l a3,a1
 lea ausbuf+insst(a5),a3
 adda.l a3,a0                   * Aktuelle Adresse
 adda.l a3,a1                   * Adresse des '.'
 move.b #' ',(a1)               * '.' überschreiben
 move.b #'{',(a3)               * Anfang der Zeile markieren
 movea.l a0,a3                  * Aktuelle Zeilenposition merken
 addq.l #4,a2                   * Pointer auf Anfangsadresse
 move.l akttxt(a5),-(a7)        * Alte Textadresse merken
 movea.l macroanf(a5),a0        * Zieladresse der Befehlsfolge
 move.l a0,-(a7)                * Merken falls Aufruf innerhalb eines Aufrufs
 move.l a0,akttxt(a5)           * Pointer setzen für Übersetzung
 move.l d3,-(a7)
 move.l d2,-(a7)                * Namen merken
 movea.l (a2)+,a1               * Anfangsadresse im Text holen
 move (a2)+,d7                  * Anzahl der Zeilen
 beq macrofi                    * Null, dann Ende
 subq #1,d7                     * -1 wegen Dbra
 move (a2),d4                   * Nummer des Aufrufs
 addq #1,(a2)                   * Einmal mehr aufgerufen
macro4:
 movea.l a0,a4                  * Adresse merken, falls später gelöscht wird
 move.l a1,(a0)+                * Adresse der Original-Zeile
macro5:
 move.b (a1)+,d0                * Zeichen holen
 cmp.b #'|',d0                  * Wenn nicht |,
 bne.s macro11                  * dann weiter
 move.b (a1)+,d1                * Nächstes Zeichen holen
 cmp.b #'|',d1                  * Ist es auch | ?
 bne.s macro5a                  * Nein, dann weiter
 move d4,d0                     * Zähler nach d0
 bsr print4d                    * Ausgabe
 bra.s macro5                    * Schleife
macro5a:
 move.b d1,d2                   * Merken
 exg d0,d1                      * Tauschen, damit unten richtig herum abgelegt
 bsr dezcheck                   * Ist es eine Dezimalzahl ?
 bcs.s macro10                  * Nein, dann so lassen
 movea.l a3,a2                  * Adresse der aktuellen Zeilenposition merken
 tst.b d2                       * Platzhalternummer = 0
 beq.s macro8                   * Ja, dann weiter
macro6:
 move.b (a2)+,d3                * Zeichen holen
 cmp.b #',',d3                  * , ist Abgrenzung
 beq.s macro7                   * OK, weitersuchen
 cmp.b #$d,d3                   * Ende der Zeile ?
 beq.s macro10                  * Ja, dann nicht ersetzen
 bra.s macro6                    * Schleife
macro7:
 subq.b #1,d2                   * Schleife bis richtiger
 bne.s macro6                   * Wert gefunden
macro8:
 cmp.b #' ',(a2)+               * Leerzeichen
 beq.s macro8                   * ignorieren
 cmp.b #$d,-(a2)                * Ende der Zeile ?
 beq.s macro10                  * Ja, dann weiter
 cmp.b #'|',(a2)                * Als erstes Zeichen |
 bne.s macro9                   * Nein, dann weiter
 movea.l a4,a0                  * Alte Zeilenanfangsadresse
macro8a:
 cmp.b #$d,(a1)+
 bne.s macro8a                  * Rest der Zeile ignorieren
 bra.s macro12                   * Normal weiter
macro9:
 move.b (a2)+,d3                * Zeichen holen
 cmp.b #$d,d3                   * Ende der Zeile ?
 beq.s macro5                   * Ja, dann weiter übertragen
 cmp.b #',',d3                  * , ist Abgrenzung
 beq.s macro5                   * OK
 move.b d3,(a0)+                * Zeichen ablegen
 bra.s macro9                    * Schleife
macro10:                        * Fehler
 move.b d1,(a0)+                * Zwei Zeichen wieder übertragen
macro11:
 move.b d0,(a0)+                * Zeichen ablegen
 cmp.b #$d,d0                   * $d ?
 bne.s macro5                   * Nein, dann nächstes Zeichen holen
 move.w a0,d0                   * Zieladresse
 btst #0,d0                   * Zeigt a0 auf ungerade Adresse ?
 beq.s macro12                  * Nein, dann weiter
 move.b #$a,-1(a0)              * $a als Lückenfüller, da nicht beachtet
 move.b #$d,(a0)+               * $d als neue Endemarkierung
macro12:
 dbra d7,macro4                  * Nächste Zeile
 clr.l (a0)+                    * Lückenfüller für Adresse (damit Ende erkannt)
 clr (a0)+                      * Endemarkierung
 move.l a0,macroanf(a5)         * Ziel für neuen Macro (für Aufruf im Aufruf)
 cmp #2,passflag(a5)            * Zweiter Durchgang ?
 beq.s macro14                  * Ja, dann weiter
 cmpa.l debugst(a5),a0          * Überlagerung mit der Debug-Tabelle
 bmi.s macro13                  * Nein, dann weiter
 move.l a0,debugst(a5)          * Tabelle neu setzen
 move.l a0,debugak(a5)
macro13:
 addq.l #4,akttxt(a5)           * Adresse der alten Zeile überspringen
 bsr geteinbuf                  * Zeile holen
 bsr assline                    * Übersetzen
 cmp #2,errflag(a5)             * Ende ?
 bne.s macro13                  * Nein, dann Schleife
 clr.b ausbuf(a5)               * Buffer ist leer
 bra.s macrofi                   * Ende
macro14:
 movea.l akttxt(a5),a0          * Anfangsadresse der Zeile
 move.l (a0)+,anfzeile(a5)      * Anfangsadresse der Original-Zeile
 move.l a0,akttxt(a5)           * Neu einstellen
 tst errcnt(a5)                 * Fehler vorhanden
 bne.s macro15                  * OK, dann nicht verändern
 move.l anfzeile(a5),errzeile(a5) * Alte Zeile für Fehler merken
macro15:
 bsr getquelle                  * Neue Zeile holen und letzte Zeile ausgeben
 bsr assline                    * Zeile übersetzen
 cmp.b #1,debug(a5)             * Debug an ?
 bne.s macro16                  * Nein, dann weiter
 move.l anfstand(a5),d0
 cmp.l pcstand(a5),d0           * Hat sich der PC-Stand verändert ?
 beq.s macro16                  * Nein, dann weiter
 movea.l debugak(a5),a0         * Adresse Debug
 move.l d0,(a0)+                * PC-Stand merken
 move.l anfzeile(a5),(a0)+      * Adresse der Zeile
 clr.l (a0)                     * Endekennung
 move.l a0,debugak(a5)          * Merken
macro16:
 and.b #1,debug(a5)             * Debug jetzt aktiv, wenn DEBUGAN erfolgte
 cmp #2,errflag(a5)             * Merker für Ende
 bne.s macro14                  * Kein Ende, dann Schleife
 clr.b ausbuf(a5)               * Buffer ist leer
macrofi:
 clr errflag(a5)                * Endemerker wieder löschen
 bsr putausbuf                  * Letzte Zeile ausgeben
 lea ausbuf(a5),a0              * Ausgabebuffer
 move.l pcstand(a5),d0          * Adresse PC
 bsr print6x                    * Adresse ausgeben
 move.b #' ',(a0)               * Null am Ende überschreiben
 lea ausbuf+insst(a5),a0
 move.l (a7)+,(a0)+
 move.l (a7)+,(a0)+             * Name des Macros
 move #'}'*256+$0d,(a0)+        * Ende des Macros
 bsr putausbuf                  * Ausgeben
 clr.b ausbuf(a5)               * Ausbuf ist leer
 move.l (a7)+,macroanf(a5)      * Adressen zurück
 move.l (a7)+,akttxt(a5)
 rts

 DC.W 0
*******************************************************************************
*                      68000/68010 Grundprogramm ass2                         *
*                         (C) 1990 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                             Assembler Teil 2                                *
*******************************************************************************


codabcd:
 bsr checkb                     * Nur Byte als Größe
codabcd0:
 bsr checkdn                    * Datenregister am Anfang ?
 bcs.s cod1abcd                 * Nein
 or d5,d6                       * Einbauen
 bsr kommack                    * Komma muß folgen
 bsr checkdn                    * Dann muß wieder Datenregister folgen
 bsr errcsyntax                 * Fehlertest
 ror #7,d5                      * An richtige Stelle
 or d6,d5                       * Einbauen
 move d5,d0                     * Nach d0
 bra putword                     * Und ausgeben

cod1abcd:
 bsr getea                      * Adressmode ermitteln
 cmp #decre,d4                  * Muß decrement sein
 bsr errnsyntax                 * Sonst Fehler
 and #7,d2                      * Nur %111 übrig lassen
 addq #8,d2                     * Und plus 8
 or d2,d6                       * Einbauen
 bsr kommack                    * Komma muß folgen
 bsr getea                      * Dann wieder Adressmode feststellen
 cmp #decre,d4                  * Muß auch decrement sein
 bsr errnsyntax                 * Sonst Fehler
 and #7,d2                      * Nummer des Datenregisters
 ror #7,d2                      * An richtige Stelle
 or d6,d2                       * Einbauen
 move d2,d0                     * Nach d0
 bra putword                     * Und ausgeben

codand:
 bsr checkbwl                   * Alle Größen erlaubt
 bsr igbn                       * Leerzeichen ignorieren
 cmp.b #'#',(a0)                * Folgt '#' ?
 bne.s cod1and                  * Nein
 move attcode(a5),d6            * Es ist andi
 bra codeori0                    * Wie codeori behandeln

cod1and:
 bsr checkdn                    * Folgt Datenregister ?
 bcc.s codanaadd                * Ja, dann weiter
cod2and:
 bsr getea                      * Sonst Adressmode holen
 and #areg,d4                   * Adressregister direkt
 bsr errnadress                 * ist nicht erlaubt
 bsr kommack                    * Komma muß folgen
 bsr checkdn                    * Dann muß Datenregister folgen
 bsr errcsyntax                 * Sonst Fehler
 bsr sizeudn                    * Size und Register einbauen
 bra codea                       * Und ausgeben

codadd:
 bsr checkbwl                   * Alle Größen erlaubt
 bsr igbn                       * Leerzeichen ignorieren
 cmp.b #'#',(a0)                * Folgt '#', dann addi
 bne.s codadd1
 move attcode(a5),d6            * Alternativbefehl
 bra codaddi0                    * Wie addi behandeln

codadd1:
 bsr checkdn                    * Datenregister am Anfang ?
 bcs.s codadd3                  * Nein, weiter
codanaadd:
 ror #7,d5                      * Registernummer an richtige Stelle
 move wordbyte(a5),d0           * Größe holen
 addq #4,d0
 rol #6,d0                      * An richtige Stelle
 or d0,d6                       * Einbauen
 or d5,d6                       * Einbauen
 bsr kommack                    * Komma muß folgen
 bsr getea                      * Adressmode holen
 cmp #dreg,d4                   * Ist es Datenregister direkt ?
 beq.s codadd2                  * Ja, dann weiter
 and #areg!pcadr,d4             * Adressregister direkt und PC nicht als
 bsr errnadress                 * Zieladresse erlaubt
 bra codea                       * Ausgeben

codadd2:
 and #%1111111011111111,d6      * Nur ein Bit löschen
 move d6,d0                     * Nach d0
 and #%0000111000000000,d0      * Nur drei Bit lassen
 rol #7,d0                      * An richtige Stelle
 or d6,d0                       * Zusammensetzen
 and #%1111000111111111,d0      * Drei Bits löschen
 and #7,d2                      * Datenregisternummer
 ror #7,d2                      * An richtige Stelle
 or d2,d0                       * Einbauen
 bra putword                     * Ausgeben

codadd3:
 bsr getea                      * Adressmode ermitteln
 bsr kommack                    * Komma muß folgen
 bsr checkdn                    * Dann muß Datenregister folgen
 bsr errcsyntax                 * Sonst Fehler
 bsr sizeudn                    * Size und Register einbauen
 bra codea                       * Und ausgeben

codadda:
 bsr checkwl                    * Nur Wort oder Langwort
 bsr immeck                     * '#' am Anfang ?
 bcs.s codadda2                 * Nein, dann weiter
 bsr expr1                      * Arithmetischen Ausdruck auswerten
 bsr kommack                    * Komma muß folgen
 bsr checkan                    * Dann muß Adressregister folgen
 bsr errcsyntax                 * Sonst Fehler
 exg d0,d5                      * d0 und d5 vertauschen
 rol #2,d0                      * Nummer des Registers an richtige Stelle
 or wordbyte(a5),d0             * Größe einbauen
 rol #7,d0                      * An richtige Stelle
 or d6,d0                       * d6 einfügen
 or #%111100,d0                 * Mode einsetzen
 bsr putword                    * Und ausgeben
 cmp #2,wordbyte(a5)            * Langwort ?
 beq.s codadda1                 * Ja, dann weiter
 move.l d5,d0                   * d5 nach d0
 bsr rangewck                   * Bereichstest
 bra putword                     * Wort ausgeben

codadda1:
 move.l d5,d0                   * d5 nach d0
 bra putlong                     * Ausgeben

codadda2:
 bsr getea                      * Adressmode ermitteln
 bsr kommack                    * Komma muß folgen
 bsr checkan                    * Dann Adressregister
 bsr errcsyntax                 * Sonst Fehler
 rol #2,d5                      * Nummer Register an richtige Stelle
 or wordbyte(a5),d5             * Größe einsetzen
 rol #7,d5                      * An richtige Stelle
 or d5,d6                       * Einbauen
 bra codea                       * Ausgeben

codaddi:
 bsr checkbwl                   * Alle Größen erlaubt
codaddi0:
 bsr.s sizeein                  * Größe an richtige Stelle
 bsr immeck                     * '#' muß folgen
 bsr errcsyntax                 * Sonst Fehler
 bsr expr1                      * Arithmetischen Ausdruck auswerten
 bsr kommack                    * Komma muß folgen
 move.l d0,-(a7)
 bsr getea                      * Effektive Adresse holen
codeoaddi:
 and #areg!pcadr,d4             * Adressregister direkt und PC sind
 bsr errnadress                 * nicht erlaubt
 bsr putorea                    * Adressmode verknüpft mit Befehl ausgeben
 move.l d0,d6
 move.l (a7)+,d0
 cmp #1,wordbyte(a5)            * Wort ?
 beq.s codaddi1                 * Ja, weiter
 cmp #2,wordbyte(a5)            * Langwort ?
 beq.s codaddi2                 * Ja, weiter
 and #$ff,d0                    * Nur Byte-Größe

codaddi1:
 bsr putword                    * Wort ausgeben
 move.l d6,d0
 bra putea                       * Zieladressmode

codaddi2:
 bsr putlong                    * Langwort ausgeben
 move.l d6,d0
 bra putea                       * Zieladressmode

sizeudn:                        * Size und Register einbauen
 ror #7,d5
 or d5,d6                       * Register an richtiger Stelle einbauen
sizeein:                        * Size einbauen
 move wordbyte(a5),d7           * Größe holen
 rol #6,d7                      * An richtige Stelle
 or d7,d6                       * Mit Befehlscode verknüpfen
 rts

codaddq:
 bsr checkbwl                   * Alle Größen erlaubt
 movea.l a0,a4                  * a0 merken
 bsr.s sizeein                  * Größe an richtige Stelle
 bsr immeck                     * '#' muß  folgen
 bsr errcsyntax                 * Sonst Fehler
 bsr expr1                      * Wert holen
 bsr kommack                    * Komma muß folgen
 move.l d0,-(a7)
 bsr getea                      * Adressmode holen
 and #pcadr,d4                  * PC ist als Ziel nicht
 bsr errnadress                 * erlaubt
 cmp #areg,d4                   * Adressregister als Ziel ?
 bne.s codaddq0                 * Nein, dann weiter
 exg.l a0,a4                    * Alte Position
 tst wordbyte(a5)               * Byte als Größe ?
 bsr erresize                   * Ja, dann Fehler
 exg.l a0,a4
codaddq0:
 move.l (a7)+,d5
 cmp #2,passflag(a5)            * Beim zweiten Durchgang
 bne.s codaddq1                 * Bereichstest des Wertes
 move.l d5,d4
 subq.l #1,d4                   * Bereich 1 bis
 and.l #$fffffff8,d4            * 8 ist erlaubt
 bsr errnber                    * Sonst Fehlerausgabe
codaddq1:
 ror #7,d5                      * Wert an richtige Stelle
 and #$0e00,d5                  * Nur 3 Bits ( 8 ist 0 )
 or d5,d6                       * Verknüpfen mit Befehlscode
 bra codea                       * Und ausgeben

codaddx:
 bsr checkbwl                   * Alle Größen erlaubt
 bsr sizeein                    * Größe an richtige Stelle
 bra codabcd0                    * Wie abcd behandeln

codshift:
 bsr checkbwl                   * Alle Größen erlaubt
 bsr igbn                       * Leerzeichen ignorieren
 movea.l a0,a4                  * a0 merken
 cmp.b #'#',(a0)                * Jetzt könnte '#' folgen
 beq.s codsh1
 bsr getea                      * Adressmode holen
 cmp #dreg,d4                   * Ist es Datenregister direkt ?
 bne.s codsh2                   * Nein
 bsr kommack                    * Ja, dann muß Komma folgen
 bsr sizeein                    * Größe einbauen
 and #7,d2
 ror #7,d2
 or #%100000,d2                 * Bit einsetzen
 move d2,d0                     * Nach d0
 bra.s codsh1a                   * Weiter wie unten

codsh1:
 bsr sizeein                    * Größe einbauen
 addq.l #1,a0                   * '#' überspringen
 bsr expr1                      * Wert ermitteln
 subq.l #1,d0                   * Bereich 1 bis 8
 bsr range07                    * Bereich Null bis Sieben testen
 addq.l #1,d0                   * Jetzt wieder 0..8
 and #7,d0                      * Nur 0..7 erlaubt (8 wird zu Null)
 ror #7,d0                      * An richtige Stelle
 bsr kommack                    * Komma muß folgen
codsh1a:
 bsr checkdn                    * Dann muß Datenregister kommen
 bsr errcsyntax                 * Sonst Fehlerausgabe
 or d6,d0                       * Befehlscode dazu
 or d5,d0                       * Zusammensetzen
 bra putword                     * Und ausgeben

codsh2:
 and #areg!dreg!pcadr,d4        * Adress- und Datenregister direkt sowie
 bsr errnadress                 * PC sind nicht erlaubt
 exg.l a0,a4
 cmp #1,wordbyte(a5)            * Größe muß Wort sein
 bsr errnsize                   * Sonst Fehler
 exg.l a0,a4
 move attcode(a5),d6            * Alternativcode
 bra codea                       * Mit Adressmode verknüpfen und ausgeben

codbtst:
 bsr checkbwl                   * Alle Größen erlaubt
 bsr igbn                       * Leerzeichen ignorieren
 cmp.b #'#',(a0)                * Es könnte '#' folgen
 bne.s codbtst1                 * Nein, dann weiter
 addq.l #1,a0                   * '#' auslassen
 move attcode(a5),d6            * Alternativcode
 bsr expr1                      * Wert holen
 bsr rangebck                   * Bereichstest
 bsr kommack                    * Komma muß folgen
 move.l d0,-(a7)
 bsr getea                      * Zieladresse bestimmen
 move.l (a7)+,d5
 and #areg,d4                   * Adressregister direkt ist als Ziel nicht
 bsr errnadress                 * erlaubt
 bsr putorea                    * Befehlscode ausgeben
 move.l d0,-(a7)
 move d5,d0
 and #$1f,d0
 bsr putword                    * Bitnummer ausgeben
 move.l (a7)+,d0
 bra putea                       * Zieladressmode ausgeben

codbtst1:
 bsr checkdn                    * Bitnummer im Datenregister
 bsr errcsyntax                 * Kein Datenregister also Fehler
 ror #7,d5                      * Nummer an richtige Stelle
 or d5,d6
 bsr kommack                    * Komma muß folgen
 bsr getea                      * Zieladresse holen
 and #areg,d4                   * Adressregister direkt ist nicht erlaubt
 bsr errnadress                 * Fehler
 bra codea                       * Ausgabe

codbchg:
 bsr checkbwl                   * Alle Größen erlaubt
 bsr igbn                       * Leerzeichen ignorieren
 cmp.b #'#',(a0)                * Es könnte '#' folgen
 bne.s codbchg1                 * Nein, dann weiter
 addq.l #1,a0                   * '#' überspringen
 move attcode(a5),d6            * Alternativcode
 bsr expr1                      * Wert holen
 bsr rangebck                   * Bereichstest
 bsr kommack                    * Komma muß folgen
 move.l d0,-(a7)
 bsr getea                      * Zieladressmode holen
 move.l (a7)+,d5
 and #areg!pcadr,d4             * Adressregister direkt und PC relativ sind
 bsr errnadress                 * als Ziel nicht zugelassen
 bsr putorea                    * Verknüpfen Ausgabe
 move.l d0,-(a7)
 move d5,d0
 and #$1f,d0
 bsr putword                    * Ausgabe der Bits
 move.l (a7)+,d0
 bra putea                       * Ausgabe der Zieladresse

codbchg1:
 bsr checkdn                    * Adressregister muß folgen
 bsr errcsyntax                 * Fehlertest
 ror #7,d5
 or d5,d6
 bsr kommack                    * Komma muß folgen
 bra codtas1                     * Weiter wie TAS

codbra:
 bsr checkbw                    * Nur Byte oder Wort
 tst wordbyte(a5)               * Wenn Wort, dann weiter
 bne.s codbra1
 bsr expr1                      * Wert berechnen
 sub.l pcstand(a5),d0           * Relativen Sprung berechnen
 subq.l #2,d0                   * Vom Zeilenanfang an berechnen
 bsr rangeb1ck                  * Bereich -128 bis +128
 and #$ff,d0                    * Nur Byte-Größe (Auch negativ)
 bsr erreber                    * Der Sprung darf nicht den Abstand Null haben
 or d6,d0                       * Mit Befehlscode zusammensetzen
 bra putword                     * Und ausgeben

codbra1:
 move d6,d0                     * Befehlscode
 bsr putword                    * Ausgeben
 bsr expr1                      * Adressabstand holen
 sub.l pcstand(a5),d0           * Relativen Sprung berechnen
 bsr rangew1ck                  * Bereich prüfen
 bra putword                     * Und ausgeben

codchk:
 bsr checkw                     * Nur Wort
 bra.s codmuls0

codmuls:
 bsr checkno                    * Keine Größenangabe erlaubt
codmuls0:
 bsr immeck                     * '#' kann am Anfang stehen
 bcs.s codmuls1                 * Nein, dann weiter
 bsr expr1                      * Wert holen
 bsr rangewck                   * Muß im Wort-Bereich liegen
 bsr kommack                    * Komma muß folgen
 bsr checkdn                    * Dann muß Datenregister folgen
 bsr errcsyntax                 * Sonst Fehlerausgabe
 ror #7,d5                      * Nummer des Datenregisters an richtige Stelle
 or d6,d5                       * Mit Befehlscode verknüpfen
 or #%111100,d5
 exg d0,d5
 bsr putword                    * Befehlscode ausgeben
 move d5,d0
 bra putword                     * Wert ausgeben

codmuls1:
 bsr getea                      * Effektive Adresse holen
 and #areg,d4                   * Adressregister direkt nicht erlaubt
 bsr errnadress
 bsr kommack                    * Komma muß folgen
 bsr checkdn                    * Dann Datenregister
 bsr errcsyntax                 * Sonst Fehler
 ror #7,d5                      * Nummer an richtige Stelle
 or d5,d6
 bra codea                       * Ausgabe

codcmp:
 bsr checkbwl                   * Alle Größen erlaubt
 bsr igbn                       * Leerzeichen ignorieren
 cmp.b #'#',(a0)                * '#' kann folgen
 bne.s codcmp1
 addq.l #1,a0
 move attcode(a5),d6            * Alternativcode
 bsr sizeein                    * Größe an richtige Stelle
 bsr expr1                      * Arithmetischen Ausdruck auswerten
 bsr kommack                    * Komma muß folgen
 move.l d0,-(a7)
 bsr getea                      * Effektive Adresse holen
 and #areg,d4                   * Adressregister direkt ist nicht erlaubt
 bsr errnadress
 bsr putorea                    * Adressmode verknüpft mit Befehl ausgeben
 move.l d0,d6
 move.l (a7)+,d0
 cmp #1,wordbyte(a5)            * Wort ?
 beq codaddi1                   * Ja, weiter
 cmp #2,wordbyte(a5)            * Langwort ?
 beq codaddi2                   * Ja, weiter
 and #$ff,d0                    * Nur Byte-Größe
 bra codaddi1

codcmp1:
 bsr getea                      * Adressmode Quelle holen
 bsr kommack                    * Komma muß folgen
 bsr checkdn                    * Dann Datenregister
 bsr errcsyntax                 * Sonst Fehler
 bsr sizeudn                    * Size und Register einbauen
 bra codea                       * Ausgabe

codcmpm:
 bsr checkbwl                   * Alle Größen erlaubt
 bsr sizeein                    * Größe an richtige Stelle
 bsr getea                      * Adressmode holen
 cmp #incre,d4                  * Nur -(an) ist erlaubt
 bsr errnsyntax                 * Sonst Fehler
 and #7,d2                      * Nur Nummer des Register übriglassen
 or d2,d6                       * Einbauen
 bsr kommack                    * Komma muß folgen
 bsr getea                      * Zieladressmode holen
 cmp #incre,d4                  * Muß auch -(am) sein
 bsr errnsyntax                 * Sonst Fehler
 and #7,d2                      * Nur Nummer Register lassen
 ror #7,d2                      * Einbauen
 or d6,d2                       * Zusammensetzen
 move d2,d0                     * Nach d0
 bra putword                     * Ausgeben

coddbcc:
 bsr checkw                     * Nur Wort als Größe
 bsr checkdn                    * Datenregister muß am Anfang sein
 bsr errcsyntax                 * Sonst Fehler
 bsr kommack                    * Komma muß folgen
 move d6,d0                     * Befehlscode
 or d5,d0                       * Verknüpft mit Nummer des Registers
 bsr putword                    * Ausgabe
 bsr expr1                      * Wert holen
 sub.l pcstand(a5),d0           * Relative Adresse berechnen
 bsr rangew1ck                  * Muß im Wort-Bereich sein
 bra putword                     * Ausgabe

codeor:
 bsr checkbwl                   * Alle Größen erlaubt
 bsr igbn                       * Leerzeichen ignorieren
 cmp.b #'#',(a0)                * Wenn '#' am Anfang, dann wie eori
 bne.s codeor1
 move attcode(a5),d6            * Alternativcode
 bra.s codeori0

codeor1:
 bsr checkdn                    * Nicht '#', dann muß Datenregister kommen
 bsr errcsyntax                 * Fehler
 bsr sizeudn                    * Size und Register einbauen
 bsr kommack                    * Komma muß folgen
 bra codtas1                     * Weiter wie TAS

codeori:
 bsr checkbwl                   * Alle Größen erlaubt
codeori0:
 movea.l a0,a4
 bsr immeck                     * '#' muß am Anfang stehen
 bsr errcsyntax                 * Sonst Fehlerausgabe
 bsr expr1                      * Wert holen
 bsr kommack                    * Komma muß folgen
 move.l d0,-(a7)
 move.l a0,-(a7)
 bsr setigname                  * Namen ermitteln
 bcs.s codeori2                 * Fehler, dann weiter
 cmp.l #'CCR ',d2
 beq.s codeori1                 * eori to CCR
 cmp.l #'SR  ',d2
 bne.s codeori2
 exg.l a0,a4
 cmp #1,wordbyte(a5)            * Als Größe nur Wort erlaubt
 bsr errnsize
 exg.l a0,a4
 move d6,d0                     * eori to SR
 or #%01111100,d0               * Befehlscode
 bsr putword                    * Ausgabe
 addq.l #4,a7                   * Stack reinigen
 move.l (a7)+,d0
 bsr rangewck                   * Bereichstest
 bra putword                     * Ausgabe

codeori1:
 move d6,d0                     * eori to CCR
 or #%00111100,d0
 bsr putword                    * Ausgabe
 addq.l #4,a7                   * Stack reinigen
 move.l (a7)+,d0
 bsr rangebck                   * Bereichstest
 bra putword                     * Ausgabe

codeori2:
 bsr sizeein                    * Größe holen
 movea.l (a7)+,a0
 bsr getea                      * Zieladressmode holen
 and #areg!pcadr,d4             * Adressregister direkt und PC sind
 bsr errnadress                 * nicht erlaubt
 bra codeoaddi                   * Wie addi behandeln

codexg:
 bsr checkl                     * Nur Langwort
 bsr checkdn                    * Adressregister am Anfang ?
 bcs.s codexg2                  * Nein, weiter
 move d5,d0
 bsr kommack                    * Komma muß folgen
 bsr checkdn                    * Dann Datenregister ?
 bcs.s codexg1                  * Nein, weiter
 moveq #%01000000,d7            * Austausch Dn, Dm
 bra.s codexg4

codexg1:
 bsr checkan                    * Adressregister muß folgen
 bsr errcsyntax                 * Sonst Fehlerausgabe
 move #%10001000,d7             * Austausch Dn, Am
 bra.s codexg4

codexg2:
 bsr checkan                    * Adressregister muß am Anfang stehen
 bsr errcsyntax                 * Sonst Fehlerausgabe
 move d5,d0                     * Nummer merken
 bsr kommack                    * Komma muß folgen
 bsr checkdn                    * Folgt Datenregister ?
 bcs.s codexg3                  * Nein, dann weiter
 ror #7,d5                      * An richtige Stelle
 move #%10001000,d7             * Austausch An, Dm
 bra.s codexg5

codexg3:
 bsr checkan                    * Adressregister muß folgen
 bsr errcsyntax                 * Fehler
 moveq #%01001000,d7            * Austausch An, Am
codexg4:
 ror #7,d0                      * An richtig Stelle
codexg5:
 or d5,d0                       * Zusammensetzen
 or d6,d0                       * Zusammensetzen
 or d7,d0                       * Austausch-Art
 bra putword                     * Ausgabe

codext:
 bsr checkwl                    * Nur Wort oder Langwort
 bsr checkdn                    * Datenregister muß am Anfang stehen
 bsr errcsyntax                 * Sonst Fehlerausgabe
 or d6,d5                       * Nummer Datenregister einbauen
 cmp #2,wordbyte(a5)
 beq.s codext1                  * Erweiterung auf Langwort
 cmp #1,wordbyte(a5)            * Erweiterung auf Wort ?
 bsr errnsize                   * Nein, dann Fehler
 or #%10000000,d5               * Größe
 move d5,d0                     * Nach d0
 bra putword                     * Ausgabe

codext1:
 or #%011000000,d5              * Größe
 move d5,d0                     * Nach d0
 bra putword                     * Ausgabe

codall:
 bsr checkno                    * Keine Größenangabe erlaubt
 move d6,d0                     * Code einfach nach d0
 bra putword                     * Ausgabe

codtas:
 bsr checkb                     * Nur Byte
codtas1:                        * Einsprung für andere Befehle
 bsr getea                      * Zieladressmode holen
 and #areg!pcadr,d4             * Adressregister direkt und PC sind als Ziel
 bsr errnadress                 * Nicht erlaubt
 bra codea                       * Ausgabe

codpea:
 bsr checkl                     * Nur Langwort erlaubt
 bra.s codjmp1

codjmp:
 bsr checkno                    * Keine Größenangabe erlaubt
codjmp1:
 bsr getea                      * Zieladressmode holen
 and #decre!incre!areg!dreg,d4  * (An)+ / -(An) / An und Dn-Adressierungen sind
 bsr errnadress                 * nicht erlaubt
 bra codea                       * Ausgabe

codlea:
 bsr checkl                     * Nur Langwort erlaubt
 bsr getea                      * Quelladressmode holen
 and #areg!dreg!incre!decre,d4  * Nicht erlaubte Adressierungsarten
 bsr errnadress                 * Fehler
 bsr kommack                    * Komma muß folgen
 bsr checkan                    * Adressregister muß folgen
 bsr errcsyntax                 * Fehler
 ror #7,d5                      * Nummer an richtige Stelle
 or d5,d6                       * Zusammensetzen
 bra codea                       * Ausgabe

codlink:
 bsr checkw                     * Nur Wort erlaubt
 bsr checkan                    * Adressregister muß am Anfang stehen
 bsr errcsyntax                 * Fehler
 or d6,d5                       * Nummer einbauen
 move d5,d0
 bsr putword                    * Ausgabe
 bsr kommack                    * Komma muß folgen
 bsr immeck                     * '#' muß folgen
 bsr errcsyntax                 * Fehler
 bsr expr1                      * Wert holen
 bsr rangewck                   * Muß Wort-Bereich sein
 bra putword                     * Ausgabe

codmovea:
 bsr checkwl                    * Nur Wort oder Langwort
 bsr immeck                     * '#' am Anfang ?
 bcc.s codma1                   * Ja, dann weiter
 bsr getea                      * Adressmode holen
 bsr kommack                    * Komma muß folgen
 bsr checkan                    * Dann muß Adressregister kommen
 bsr errcsyntax                 * Sonst Fehlerausgabe
 ror #3,d5
 or wordbyte(a5),d5             * Größe einbauen
 ror #4,d5                      * An richtige Stelle
 or d5,d6                       * Mit Befehl verknüpfen
 bra codea                       * Ausgabe

codma1:
 bsr expr1                      * Wert holen
 movea.l a0,a4
 bsr kommack                    * Komma muß folgen
 bsr checkan                    * Adressregister muß folgen
 bsr errcsyntax                 * Sonst Fehlerausgabe
 ror #3,d5
 move wordbyte(a5),d4           * Größe holen
 bsr erresize                   * Byte ist nicht erlaubt
 or d4,d5                       * Nummer des Adressregisters einbauen
 ror #4,d5                      * Schieben
 or #%111100,d5                 * Mode
 or d5,d6
 exg d0,d6
 bsr putword                    * Ausgabe Befehlscode
 exg d0,d6
 cmp #1,wordbyte(a5)
 bne putlong                    * Langwort-Konstante
 bsr rangewck                   * Bereichstest Wort
 bra putword                     * Ausgabe Wort

codmove:
 bsr checkbwl                   * Alle Größen erlaubt
 movea.l a0,a4
 bsr setigname                  * Namen holen
 bcs.s codmove1                 * Fehler, dann weiter
 cmp.l #'SR  ',d2               * move from SR ?
 beq codmosr                    * Ja
 cmp.l #'USP ',d2               * move from USP ?
 beq codmousp                   * Ja
 cmp.l #'CCR ',d2               * move from CCR ?
 beq codmoccr                   * Ja
codmove1:
 movea.l a4,a0                  * a0 zurück
 bsr immeck                     * '#' am Anfang ?
 bcc codmoda                    * Ja, dann weiter
 bsr getea                      * Quelladressmode holen
 bsr kommack                    * Komma muß folgen
 movem.l d0/d2/d3,-(a7)
 move.l a0,-(a7)
 bsr setigname                  * Namen holen
 bcs.s codmove2                 * Fehler, dann weiter
 cmp.l #'SR  ',d2               * move to SR ?
 beq.s codsrmo                  * Ja
 cmp.l #'CCR ',d2               * move to CCR ?
 beq.s codccrmo                 * Ja
 cmp.l #'USP ',d2               * move to USP ?
 beq coduspmo                   * Ja
codmove2:
 movea.l (a7)+,a0
 bsr getea                      * Zieladressmode holen
 and #areg!pcadr,d4             * Adressregister direkt und PC sind
 bsr errnadress                 * nicht erlaubt
 move wordbyte(a5),d6           * Größe holen
 addq #1,d6                     * 1 addieren
 cmp #1,d6                      * Wenn 1
 beq.s codmove3                 * dann OK
 eori #1,d6                     * Sonst Bit Null ändern
codmove3:
 rol #3,d6                      * An richtige Stelle
 move d2,d1
 and #7,d1                      * Quelladressmode
 or d1,d6                       * Einbauen
 rol #3,d6
 move d2,d1
 ror #3,d1
 and #7,d1
 or d1,d6                       * Zusammensetzen
 rol #6,d6                      * An richtige Stelle
 move.l d0,d1                   * Werte merken
 move d2,d4
 move d3,d7
 movem.l (a7)+,d0/d2/d3
 bsr putorea
 move d7,d6                     * d7 wird zerstört aber d6 ist jetzt frei
 bsr putea                      * Ausgabe Erweiterungen
 move.l d1,d0                   * Werte zurück
 move d4,d2
 move d6,d3
 bra putea                       * Ausgabe Zielcode

codsrmo:
 addq.l #4,a7                   * Stack reinigen
 move #$46c0,d6                 * Code
 movem.l (a7)+,d0/d2/d3
 and #areg,d4                   * Adressregister direkt nicht als Ziel erlaubt
 bsr errnsyntax                 * Fehler
 bra codea                       * Ausgabe

codccrmo:
 addq.l #4,a7                   * Stack reinigen
 move #$44c0,d6                 * Code
 movem.l (a7)+,d0/d2/d3
 and #areg,d4                   * Adressregister direkt nicht als Ziel erlaubt
 bsr errnsyntax                 * Fehler
 bra codea                       * Ausgabe

coduspmo:
 addq.l #4,a7                   * Stack reinigen
 movem.l (a7)+,d0/d2/d3
 cmp #areg,d4                   * Nur als Ziel erlaubt
 bsr errnsyntax                 * Fehler
 move d2,d0
 and #7,d0
 or #$4e60,d0
 bra putword                     * Ausgabe

codmosr:
 bsr kommack                    * Komma muß folgen
 move #$40c0,d6
 bra codtas1                     * Weiter wie TAS

codmousp:
 bsr kommack                    * Komma muß folgen
 bsr checkan                    * Nur Adressregister als Ziel erlaubt
 bsr errcsyntax                 * Fehler
 move #$4e68,d0                 * Code für move to usp
 or d5,d0                       * Verknüpfen
 bra putword                     * Ausgabe

codmoccr:
 bsr kommack                    * Komma muß folgen
 move #$42c0,d6
 bra codtas1                     * Weiter wie TAS

codmoda:
 bsr expr1                      * Wert holen
 movea.l a0,a1                  * Adresse merken für Fehleranzeige
 bsr kommack                    * Komma muß folgen
 move.l d0,-(a7)
 move.l a0,-(a7)
 bsr setigname                  * Namen holen
 bcs.s codmoda1                 * Fehler, dann weiter
 cmp.l #'CCR ',d2               * move to CCR ?
 beq codmdaccr                  * Ja
 cmp.l #'SR  ',d2               * move to SR ?
 beq codmdasr                   * Ja
codmoda1:
 movea.l (a7)+,a0
 bsr getea                      * Zieladressmode holen
 move.l (a7)+,d5
 and #areg!pcadr,d4             * Als Ziel nicht erlaubt
 bsr errnadress                 * Fehler
 move.l d0,-(a7)
 move wordbyte(a5),d0           * Größe wandeln
 addq #1,d0
 cmp #1,d0
 beq.s codmoda2
 eori #1,d0
codmoda2:
 rol #3,d0                      * Alles zusammensetzen
 move d2,d7
 and #7,d7
 or d7,d0
 rol #3,d0
 move d2,d7
 ror #3,d7
 and #7,d7
 or d7,d0
 rol #6,d0
 or #%111100,d0
 bsr putword                    * Ausgabe Befehlscode
 exg.l a0,a1                    * Adresse Datenwert mit Adresse Zeile tauschen
 move wordbyte(a5),d0
 beq.s codmoda4
 cmp #1,d0
 beq.s codmoda3
 move.l d5,d0                   * Konstante ist Langwort
 bsr putlong                    * Ausgabe
 bra.s codmoda5
codmoda3:
 move.l d5,d0                   * Konstante ist Wort
 bsr rangewck                   * Bereichstest
 bsr putword                    * Ausgabe
 bra.s codmoda5
codmoda4:
 move.l d5,d0                   * Konstante ist Byte
 bsr rangebck                   * Bereichstest
 and #$ff,d0                    * Nur Byte
 bsr putword                    * Ausgabe
codmoda5:
 exg.l a0,a1                    * Adressregister zurück tauschen
 move.l (a7)+,d0
 bra putea                       * Ausgabe Erweiterung

codmdaccr:
 addq.l #4,a7                   * Stack reinigen
 move #$44fc,d0                 * Code für move to ccr
 bsr putword                    * Ausgabe
 move.l (a7)+,d0
 bsr rangewck                   * Bereichtstest
 bra putword                     * Ausgabe

codmdasr:
 addq.l #4,a7                   * Stack reinigen
 move #$46fc,d0                 * Code für move to sr
 bsr putword                    * Ausgabe
 move.l (a7)+,d0
 bsr rangewck                   * Bereichstest
 bra putword                     * Ausgabe

codmovec:
 bsr checkl                     * Nur Langwort
 bsr igbn
 bsr.s getadda                  * Adressregister oder Datenregister ?
 bcc.s codmovc0
 move d6,d0
 bsr putword                    * Erstes Wort ausgeben
 bsr.s getrc                    * Controlregister holen
 bsr kommack                    * Komma muß folgen
 bsr.s getadda                  * Register holen
 bsr errcsyntax                 * Fehler, wenn nicht Register
 or d5,d6
 move d6,d0
 bra putword                     * Ausgabe zweites Wort

codmovc0:
 or #1,d6                       * Richtung
 move d6,d0
 bsr putword                    * Erstes Wort ausgeben
 bsr kommack                    * Komma muß folgen
 bsr.s getrc                    * Controlregister holen
 or d5,d6
 move d6,d0
 bra putword                     * Ausgabe zweites Wort

getrc:                          * Ergebnis in d6
 bsr setigname                  * Namen holen
 lea getrctab(pc),a3            * Tabelle der Register
 moveq #4-1,d7
getrclp:
 cmp.l (a3)+,d2                 * Vergleich
 beq.s getrc1                   * OK, Register gefunden
 addq.l #2,a3                   * Nicht gefunden
 dbra d7,getrclp                 * Weiter suchen
 bra errs1                       * Fehler, da nicht gefunden
getrc1:
 move (a3),d6                   * Code für Register
 rts

getrctab:
 DC.b 'SFC ',$00,$00
 DC.b 'DFC ',$00,$01
 DC.b 'USP ',$08,$00
 DC.b 'VBR ',$08,$01

getadda:                        * Liefert in d5 Code für Register
 bsr igbn                       * Carry, wenn kein Register
 bsr checkdn
 bcc.s getadda1                 * OK, Datenregister
 bsr checkan
 bcc.s getadda0                 * OK, Adressregister
 clr d5
 bra carset                      * Fehler
getadda0:
 or #8,d5                       * Bit für Adressregister
getadda1:
 ror #4,d5                      * An richtige Stelle
 bra carres                      * OK

codmovem:
 bsr checkwl                    * Als Größe nur Wort oder Langwort
 bsr igbn                       * Leerzeichen ignorieren
 movea.l a0,a4                  * Adresse merken
 bsr checkdn                    * Dn am Anfang ?
 bcc.s codmom1                  * Ja, dann OK
 bsr checkan                    * An am Anfang ?
 bcs.s codmom4                  * Nein, dann weiter
codmom1:                        * movem dn-an,<ea>
 movea.l a4,a0                  * Adresse zurück
 bsr.s getregli                 * Liste der Register holen
 bsr kommack                    * Komma muß folgen
 move d4,-(a7)
 bsr getea                      * Adressmode holen
 move (a7)+,d5
 cmp #decre,d4                  * Wenn Decrement, dann
 bne.s codmom2
 bsr revlist                    * Liste umdrehen
codmom2:
 and #dreg!areg!incre!pcadr,d4  * Nicht erlaubte Adressmodi
 bsr errnadress                 * Fehler
 cmp #1,wordbyte(a5)            * Wort ?
 beq.s codmom3                  * Ja, dann OK
 or #%1000000,d6                * Größe Langwort einstellen
codmom3:
 bsr putorea                    * Ausgabe Befehlscode
 exg d0,d5
 bsr putword                    * Ausgabe Bits für Registerfolge
 exg d0,d5
 bra putea                       * Ausgabe Erweiterung, wenn vorhanden

codmom4:                        * movem <ea>,Reglist
 movea.l a4,a0                  * Adresse zurück
 bsr getea                      * Adressmode holen
 and #dreg!areg!decre,d4        * Nicht erlaubte Adressierungsarten
 bsr errnadress                 * Fehler
 bsr kommack                    * Komma muß folgen
 bsr.s getregli                 * Registerliste holen
 or #$400,d6                    * Richtung
 tst wordbyte(a5)               * Byte ist als Größe
 bsr erresize                   * nicht erlaubt
 cmp #1,wordbyte(a5)            * Wort-Größe ?
 beq.s codmom5                  * Ja, dann OK
 or #%1000000,d6                * Sonst Langwort-Bit setzen
codmom5:
 bsr putorea                    * Ausgabe Befehlscode
 exg d4,d0
 bsr putword                    * Ausgabe Registerliste
 exg d4,d0
 bra putea                       * Eventuell Ausgabe Erweiterung

getregli:
 moveq #0,d4                    * Registerliste holen
 movem.l d0/d5,-(a7)
 bsr.s getregl2                 * Liste holen
 movem.l (a7)+,d0/d5
 bcs errs1                      * Wenn Carry gesetzt, dann Syntax-Fehler
 rts

getregl1:
 addq.l #1,a0                   * a0 erhöhen
getregl2:
 bsr checkdn                    * Anfang mit dn ?
 bcs.s getregl5                 * Nein, dann weiter
 bset d5,d4                     * Bit für das spezielle Register setzen
 bsr igbn                       * Leerzeichen ignorieren
getregl3:
 cmp.b #'/',(a0)                * Folgt '/' ?
 beq.s getregl1                 * Ja, dann nur ein Register
 cmp.b #'-',(a0)                * folgt '-' ?
 bne carres                     * Nein, dann OK
 addq.l #1,a0                   * a0 erhöhen
 move d5,d0                     * d5 merken
 bsr checkdn                    * Nummer holen
 bcs carset                     * Fehler, da kein Datenregister folgt
getregl4:
 cmp d0,d5                      * d0 gleich d5
 beq.s getregl3                 * Dann alle Register gesetzt
 addq #1,d0                     * Sonst erhöhen
 bset d0,d4                     * Und setzen
 bra.s getregl4

getregl5:
 bsr checkan                    * Folgt an ?
 bcs carset                     * nein, dann Fehler
 addq #8,d5                     * d5+8, damit richtige Bits gesetzt werden
 bset d5,d4                     * Setzen
 bsr igbn                       * Leerzeichen ignorieren
 cmp.b #'/',(a0)                * Folgt '/' ?
 beq.s getregl1                 * Nein, dann normal weiter
 cmp.b #'-',(a0)                * Folgt '-' ?
 bne carres                     * Nein, dann Ende
 addq.l #1,a0                   * a0 erhöhen
 move d5,d0                     * d5 merken
 bsr checkan                    * Adressregister muß folgen
 bcs carset                     * Sonst Fehlerausgabe
 addq #8,d5                     * d5 erhöhen, damit richtige Bits gesetzt werden
getregl6:
 cmp d0,d5                      * d0 gleich d5
 beq.s getregl3                 * Ja, dann OK
 addq #1,d0                     * Sonst erhöhen
 bset d0,d4                     * Und Bit setzen
 bra.s getregl6

revlist:                        * Liste umdrehen
 movem.l d1/d2,-(a7)            * Nötig bei spezieller Adressierungsart
 moveq #16-1,d2                 * 16 Bits
revlist1:
 roxl #1,d5                     * Von links holen
 roxr #1,d1                     * Nach rechts schieben
 dbra d2,revlist1
 move d1,d5
 movem.l (a7)+,d1/d2            * Bit 15 ist Bit 0 usw.
 rts

codmovep:
 bsr checkwl                    * Als Größe nur Wort oder Langwort
 bsr checkdn                    * Kommt Datenregister am Anfang ?
 bcs.s cod1movep                * Nein, dann weiter
 ror #7,d5                      * An richtige Stelle
 or d5,d6                       * Verknüpfen
 cmp #1,wordbyte(a5)            * Wort-Größe ?
 beq.s cod12mp                  * Ja, dann weiter
 or #%111000000,d6              * Größe einbauen
 bra.s cod13mp
cod12mp:
 or #%110000000,d6              * Größe für Wort
cod13mp:
 bsr kommack                    * Komma muß folgen
 bsr getea                      * Adressmode holen
 move d2,d1
 and #%111000,d2                * Adressierungsart testen
 cmp #%101000,d2                * Ist es d(an)
 bsr errnadress                 * Nein, dann Fehler
 and #7,d1                      * Nur Registernummer behalten
 exg d0,d1
 or d6,d0                       * Verknüpfen mit Befehlscode
 bsr putword                    * Ausgabe Befehlscode
 exg d0,d1
 bsr rangewck                   * Muß Wort-Bereich sein
 bra putword                     * Ausgabe

cod1movep:
 bsr getea                      * Adressmode holen
 move d2,d1
 and #%111000,d2
 cmp #%101000,d2                * Muß d(an) sein
 bsr errnadress                 * Sonst Fehler
 bsr kommack                    * Komma muß folgen
 bsr checkdn                    * Dann muß Datenregister kommen
 bsr errcsyntax                 * Fehlertest
 ror #7,d5                      * Nummer an richtige Stelle
 or d6,d5                       * Verknüpfen
 and #7,d1
 or d5,d1
 cmp #1,wordbyte(a5)            * Wort als Größe, dann weiter
 beq.s cod2mp
 or #%101000000,d1              * Bits für Langwort
 bra.s cod3mp
cod2mp:
 or #%100000000,d1              * Bits für Wort
cod3mp:
 exg d0,d1
 bsr putword                    * Ausgabe Befehlscode
 exg d0,d1
 bsr rangewck                   * Bereichstest
 bra putword                     * Ausgabe

codmoveq:
 bsr checkl                     * Als Größe nur Langwort
 bsr immeck                     * '#' muß am Anfang stehen
 bsr errcsyntax                 * Sonst Fehlerausgabe
 bsr expr1                      * Wert holen
 bsr kommack                    * Komma muß folgen
 bsr checkdn                    * Dann Datenregister
 bsr errcsyntax                 * Fehlerabfrage
 ror #7,d5                      * Nummer an richtige Stelle
 or d6,d5                       * Verknüpfen
 bsr rangebck                   * Bereichtstest
 and #$ff,d0                    * Nur Byte
 or d5,d0                       * Verknüpfen
 bra putword                     * Ausgabe

codmoves:
 bsr checkbwl                   * Alle Größen erlaubt
 bsr sizeein                    * Größe an richtige Stelle
 bsr getadda                    * Register am Anfang ?
 bcs.s codmovs0                 * Nein, dann weiter
 or #$0800,d5                   * Richtung
 move d5,-(a7)                  * Merken
 bsr kommack                    * Komma muß folgen
 bsr getea
 and #dreg!areg!pcadr,d4        * Falsche Adressierungsarten
 bsr errnadress
 bsr putorea                    * Ausgabe Befehl
 move.l d0,d7                   * d0 merken
 move (a7)+,d0
 bsr putword                    * Ausgabe Quellregister
 move.l d7,d0
 bra putea                       * Ausgabe Erweiterung

codmovs0:
 bsr getea                      * Adressierungsart holen
 and #dreg!areg!pcadr,d4        * Falsche Adreesierungsarten
 bsr errnadress                 * Fehler
 bsr putorea                    * Ausgabe
 move.l d0,d7
 bsr kommack                    * Komma muß folgen
 bsr getadda                    * Register holen
 bsr errcsyntax                 * Fehler
 move d5,d0
 bsr putword                    * Ausgabe Register
 move.l d7,d0
 bra putea                       * Ausgabe Erweiterung

codneg:
 bsr checkbwl                   * Alle Größen erlaubt
 bsr sizeein                    * Größe an richtige Stelle
 bra codtas1                     * Weiter wie TAS

codstop:
 bsr checkno                    * Keine Größenangabe erlaubt
 bsr.s immeck                   * '#' muß am Anfang vorhanden sein
 bsr errcsyntax                 * Sonst Fehlerausgabe
 move d6,d0
 bsr putword                    * Ausgabe Befehlscode
 bsr expr1                      * Wert ermitteln
 bsr rangewck                   * Muß Wort-Bereich sein
 bra putword                     * Ausgabe

codswap:
 bsr checkw                     * Nur Wort als Größe
 bsr checkdn                    * Datenregister am Anfang ?
 bra.s codunlk0                  * Ausgabe

codtrap:
 bsr checkno                    * Ohne Größe
 bsr.s immeck                   * '#' muß folgen
 bsr errcsyntax                 * Sonst Fehlerausgabe
 bsr expr1                      * Wert holen
 cmp #$10,d0                    * Bereich 0..$f erlaubt
 bls.s codtrap1                 * OK
 bsr errb1                      * Wertebereich falsch
 and #$f,d0                     * Bereich einschränken
codtrap1:
 or d6,d0                       * Verknüpfen
 bra putword                     * Ausgabe

codunlk:
 bsr checkno                    * Ohne Größe
 bsr checkan                    * Adressregister muß folgen
codunlk0:
 bsr errcsyntax                 * Sonst Fehlerausgabe
 or d6,d5                       * Verknüpfen
 move d5,d0                     * Und nach d0
 bra putword                     * Für Ausgabe

immeck:
 bsr igbn                       * Leerzeichen ignorieren
 cmp.b #'#',(a0)                * Folgt '#' ?
 bne carset                     * Nein, dann Carry setzen
 addq.l #1,a0                   * Sonst a0 erhöhen
 bra carres                      * Und Carry rücksetzen

symclr:
 cmp #1,passflag(a5)            * Nur im ersten Durchlauf erlaubt
 bne.s symclrfi
 move.l a0,d0                   * a0 darf nicht zerstört werden
 bsr symloesche                 * Symboltabelle löschen
 movea.l d0,a0
symclrfi:
 rts

coddc:
 bsr checkbwl                   * Alle Größen erlaubt
 tst wordbyte(a5)               * Byte ?
 bne.s coddcw                   * Nein, dann weiter
coddcb:
 bsr igbn                       * Leerzeichen ignorieren
 cmp.b #$27,(a0)+               * ' = Anfang Text
 beq.s coddcbtxt
 subq.l #1,a0                   * Sonst a0 zurück
 bsr expr1                      * Wert holen
 bsr rangebck                   * Muß Byte-Bereich sein
 bsr putbyte                    * Ausgeben
coddcb1:
 bsr igbn
 cmp.b #',',(a0)+               * Komma kann folgen
 beq.s coddcb                   * OK, wiederholen
 subq.l #1,a0                   * Ende
 rts

coddcbtxt:
 cmp.b #$27,(a0)+               * ' = Ende Text
 beq.s coddcb1
 cmp.b #' ',-(a0)               * Muß ASCII-Zeichen sein
 bsr errcsyntax
 move.b (a0)+,d0                * Holen
 bsr putobyte                   * Und ausgeben
 bra.s coddcbtxt                 * Wiederholen

coddcw:
 cmp #1,wordbyte(a5)            * Wort-Größe
 bne.s coddcl                   * Nein, dann weiter
coddcw1:
 bsr expr1                      * Wert holen
 bsr rangewck                   * Muß Wort-Bereich sein
 bsr putword                    * Ausgabe
 bsr igbn
 cmp.b #',',(a0)+               * Komma kann folgen
 beq.s coddcw1                  * OK, wiederholen
 subq.l #1,a0                   * Ende
 rts

coddcl:
 bsr expr1                      * Wert holen
 bsr putlong                    * Ausgabe
 bsr igbn
 cmp.b #',',(a0)+               * Komma kann folgen
 beq.s coddcl                   * OK, wiederholen
 subq.l #1,a0                   * Ende
 rts

coddf:
 bsr checkbwl                   * Größe holen
 bsr expr1                      * Anzahl der Werte
 tst d1                         * Fehler ?
 beq.s *+8                      * Dann vorsichtshalber nicht weitermachen
 cmp #5,d1
 bne.s *+10                     * OK, auch nicht undefinert
 lea txtdf(pc),a0
 bra errabbr                     * Abbruch des Assembliervorgangs
 tst.l d0
 beq errb1                      * Bereichsfehler
 move.l d0,d6
 bsr kommack                    * Komma muß folgen
 bsr expr1                      * Wert holen
 move.l d0,d1
 tst wordbyte(a5)
 bne.s coddf1
coddf0:
 bsr co2test                    * Extraabfrage, da eventuell längere Schleife
 bcs abbruch                    * Abbruch mit Ctrl-C
 move.l d1,d0
 bsr rangebck                   * Byte, deshalb Bereich testen
 bsr putbyte                    * Byte ausgeben
 subq.l #1,d6
 bne.s coddf0                    * Schleife
 rts
coddf1:
 cmp #1,wordbyte(a5)
 bne.s coddf3
coddf2:
 bsr co2test                    * Extraabfrage, da eventuell längere Schleife
 bcs abbruch                    * Abbruch mit Ctrl-C
 move.l d1,d0
 bsr rangewck                   * Wort, deshalb Bereich testen
 bsr putword                    * Wert ausgeben
 subq.l #1,d6                   * Schleife
 bne.s coddf2
 rts
coddf3:
 bsr co2test                    * Extraabfrage, da eventuell längere Schleife
 bcs abbruch                    * Abbruch mit Ctrl-C
 move.l d1,d0
 bsr putlong
 subq.l #1,d6
 bne.s coddf3
 rts

codoff:
 bsr checkno                    * Keine Größenangabe
 bsr expr1                      * Wert holen
 bclr.l #0,d0                   * Muß gerader Wert sein
 bsr errnsyntax                 * Sonst Fehler
 move.l d0,offset(a5)           * Und merken
 rts

codds:
 bsr checkbwl                   * Alle Größen erlaubt
 bsr expr1                      * Wert holen
 tst.l d0                       * Wenn Wert Null
 beq.s codadjust                * Dann zu ds 0
 move wordbyte(a5),d1           * Größe holen
 beq.s codds1                   * Byte-Größe ? Dann OK
 add.l d0,d0                    * Wert mal 2
 cmp #1,d1                      * Wort-Größe ?
 beq.s codds1                   * Ja, dann OK
 add.l d0,d0                    * Sonst Wert insgesamt mal 4
codds1:
 add.l d0,pcstand(a5)           * Wert zum PC-Stand addieren
 rts

codadjust:
 addq.l #1,pcstand(a5)
 and.b #$fe,pcstand+3(a5)       * Jetzt ist PC immer auf gerader Adresse
 rts

codrs:
 move.l rscount(a5),d0          * Zähler
 moveq #3,d1                    * Langwort
 bsr newval                     * Neues Symbol
 bcc.s codrs1                   * OK
 cmp.l datenwert(a3),d0
 bsr errnmult                   * Eventuell mehrfach definiert
 move.l d0,datenwert(a3)        * Auf neuen Wert
 move d1,attribut(a3)           * einstellen
codrs1:
 bsr igbn                       * Leerzeichen ignorieren
 addq.l #2,a0                   * 'RS' überspringen
 movea.l a0,a4                  * Adresse merken
 lea ausbuf(a5),a0
 move #'= ',(a0)+
 bsr print8x                    * Wert des Symbols ausgeben
 move.b #' ',(a0)               * Null überschreiben
 movea.l a4,a0                  * Adresse zurück
 bsr checkbwl                   * Größe holen
 bsr expr1                      * Wert holen
 tst.l d0
 beq.s codrs4
 move wordbyte(a5),d1           * Größe holen
 beq.s codrs3                   * Byte-Größe ? Dann OK
 btst.b #0,rscount+3(a5)
 beq.s codrs2
 addq.l #1,datenwert(a3)        * Auf Wortgrenze bringen
 moveq #5,d7
 bsr errende                    * Nicht auf Wortgrenze
codrs2:
 add.l d0,d0                    * Wert mal 2
 cmp #1,d1                      * Wort-Größe ?
 beq.s codrs3                   * Ja, dann weiter
 add.l d0,d0                    * Sonst Wert insgesamt mal 4
codrs3:
 add.l d0,rscount(a5)           * Wert zum RS-Zähler addieren
 bra assline7                    * Restd er Zeile testen

codrsin:                        * Einsprung, wenn RS alleine steht
 addq.l #4,a7                   * Stack reinigen
 bsr checkbwl
 bsr expr1
 tst.l d0
 beq.s codrs4                   * Auf Wortgrenze bringen
 move wordbyte(a5),d1
 beq.s codrs3
 bra.s codrs2

codrs4:
 addq.l #1,rscount(a5)
 and.b #$fe,rscount+3(a5)       * RS-Zähler auf gerader Adresse
 bra assline7                    * Rest der Zeile testen

codrsreset:
 bsr checkno                    * Keine Größenangabe
 clr.l rscount(a5)              * RS-Zähler zurücksetzen
 rts

codrsset:
 bsr checkno                    * Keine Größenangabe
 bsr expr1                      * Wert holen
 tst errflag(a5)
 bne carset                     * Fehler
 move.l d0,rscount(a5)          * Wert merken
 rts

codend:
 move #2,errflag(a5)            * Merker für Ende
 rts

codorg:                         * Übersetzungsadresse einstellen
 bsr checkno                    * Ohne Größenangabe
 bsr expr1                      * Wert holen
 move.l d0,pcstand(a5)          * Wert einstellen
 movea.l a0,a1                  * a0 merken
 lea ausbuf(a5),a0              * Ziel
 bsr print6x                    * Adresse neu in Zeile setzen
 move.b #' ',(a0)               * Null am Ende überschreiben
 movea.l a1,a0                  * a0 zurück
 rts

debugon:
 cmp #2,passflag(a5)            * Nur beim zweiten Durchgang
 bne.s debugfi
 cmp.b #1,debug(a5)             * Debug schon an ?
 beq.s debugfi                  * Ja, dann OK
 st debug(a5)                   * Debug anschalten ( Für nächste Zeile )
 rts

debugoff:                       * Debug ausschalten
 cmp #2,passflag(a5)            * Nur beim zweiten Durchgang
 bne.s debugfi
 clr.b debug(a5)                * Debug aus
debugfi:
 rts

ausmode:
 cmp #2,passflag(a5)
 bne carres
 move.b d6,iostat(a5)
 rts

***** Fehlerbehandlung *****

range07:                        * Bereichstest 0..7
 cmp #2,passflag(a5)            * Nur beim zweiten Durchgang
 bne.s rangefi
 move.l d0,d7                   * Retten
 and.l #$fffffff8,d7            * Test
 bne.s errb1                    * Nicht im Bereich 0..7
 rts

rangeb1ck:                      * Bereich in Byte-Grenze mit Vorzeichen
 cmp #2,passflag(a5)
 bne.s rangefi
 move.l d0,d7
 and.l #$ffffff80,d7
 beq.s rangefi                  * OK
 cmp.l #$ffffff80,d7
 bne.s errb1                    * Fehler
 rts

rangebck:                       * Bereich in Byte-Grenze ohne Vorzeichen
 cmp #2,passflag(a5)
 bne.s rangefi
 move.l d0,d7
 and.l #$ffffff00,d7
 beq.s rangefi                  * OK
 cmp.l #$ffffff00,d7
 bne.s errb1                    * Fehler
 rts

rangew1ck:                      * Bereich in Wort-Grenze mit Vorzeichen
 cmp #2,passflag(a5)
 bne.s rangefi
 move.l d0,d7
 and.l #$ffff8000,d7
 beq.s rangefi                  * OK
 cmp.l #$ffff8000,d7
 bne.s errb1                    * Fehler
 rts

rangewck:                       * Bereich in Wort-Grenze ohne Vorzeichen
 cmp #2,passflag(a5)
 bne.s rangefi
 move.l d0,d7
 and.l #$ffff0000,d7
 beq.s rangefi                  * OK
 cmp.l #$ffff0000,d7
 bne.s errb1                    * Fehler
rangefi:
 rts

errb1:                          * Bereichsfehler
 moveq #0,d7
 bra.s errende

erreber:
 beq.s errb1                    * Bereichsfehler, wenn gleich
 rts

errcber:
 bcs.s errb1                    * Bereichsfehler, wenn Carry gesetzt
 rts

errnber:
 bne.s errb1                    * Bereichsfehler, wenn ungleich
 rts

errcsyntax:
 bcs.s errs1                    * Syntaxfehler, wenn Carry gesetzt
 rts

erresyntax:
 beq.s errs1                    * Syntaxfehler, wenn gleich
 rts

errnsyntax:
 bne.s errs1                    * Syntaxfehler, wenn ungleich
 rts

errs1:
 moveq #1,d7
 bra.s errende                   * Fehlerauswertung

errcadress:
 bcs.s erradr1                  * Adressfehler, wenn Carry gesetzt
 rts

erreadress:
 beq.s erradr1                  * Adressfehler, wenn gleich
 rts

errnadress:
 bne.s erradr1                  * Adressfehler, wenn ungleich
 rts

erradr1:
 moveq #2,d7
 bra.s errende                   * Fehlerauswertung

erru1:
 moveq #3,d7
 bra.s errende                   * Fehlerauswertung

errnmult:
 beq.s errfi                    * Mehrfach definiert, wenn ungleich
 moveq #4,d7
 bra.s errende

erresize:
 beq.s errsize                  * Falsche Größe, wenn gleich
 rts

errnsize:
 bne.s errsize                  * Falsche Größe, wenn ungleich
 rts

errsize:
 moveq #6,d7

errende:
 tst errflag(a5)                * Schon Fehler vorhanden ?
 bne.s errfi                    * Ja, Ende
 move d7,errart(a5)             * Fehlerart merken
 move #1,errflag(a5)            * Anzeige, daß Fehler vorhanden
 move.l a0,errpoi(a5)           * Zeiger auf Fehler
 addq #1,errcnt(a5)             * Ein Fehler mehr vorhanden
errfi:
 rts

errtab:
 DC.w txtber-errtab             * Bereichsfehler
 DC.w txtsyn-errtab             * Syntaxfehler
 DC.w txtadr-errtab             * Adressfehler
 DC.w txtundef-errtab           * Undefiniert
 DC.w txtmult-errtab            * Mehrfach definiert
 DC.w txtadj-errtab             * Nicht auf Wortgrenze
 DC.w txtsize-errtab            * Falsche Größenangabe

erranalyse:                     * Fehlerausgabe
 bsr newput                     * Ausgabe letzte Zeile
 move errart(a5),d0             * Art des Fehlers
 add d0,d0                      * Mal zwei
 move errtab(pc,d0),d0          * Adresse Fehlertext
 lea errtab(pc,d0),a0           * Berechnen
 move.l errpoi(a5),d1           * Zeiger auf Fehlerstelle
 lea einbuf-insst(a5),a1        * Anzahl der '-' berechnen
 sub.l a1,d1
 and #$ff,d1                    * Maximal 255
erran1:
 moveq #'-',d0                  * '-' ausgeben
 bsr co2ausa
 dbra d1,erran1
 moveq #'^',d0                  * Dann '^' als Zeiger
 bsr co2ausa
 bsr crlfe                      * CR LF
 bsr prtco2                     * Ausgabe des Fehlertextes
 bra crlfe                       * CR LF

errabbr:                        * Abbruch mit Fehlerausgabe
 move #2,passflag(a5)           * Ausgabe anschalten
 bsr prtco2                     * Text ausgeben
 bsr crlfe                      * Zeilenvorschub

abbruch:
 movea.l a6,a7                  * Stack zurück
 move #2,passflag(a5)           * Zweiter Durchgang, damit CO2 an
 move #2,errflag(a5)            * CO2 wirklich Ausgabe an
 lea txtend(pc),a0
 bsr prtco2                     * Ende-Text
 moveq #'0',d0
 bsr esc7                       * Immer Software-Scroll an
 addq #1,errcnt(a5)             * Ein Fehler mehr, als Merker für Abbruch
 move.b (a7)+,cotempo(a5)       * Für spätere Ausgaben wieder alte Scrollart
 bra carset                      * Assembliervorgang abgebrochen

txtber:
 DC.b 'Wertebereich falsch',0

txtsyn:
 DC.b 'Syntax Fehler',0

txtadr:
 DC.b 'Adressmode nicht erlaubt',0

txtundef:
 DC.b 'Undefiniertes Symbol',0

txtmult:
 DC.b 'Mehrfach Definiert',0

txtadj:
 DC.b 'Nicht auf Wortgrenze',0

txtsize:
 DC.b 'Größenangabe nicht erlaubt',0

txtmacro:
 DC.b 'MACRO nicht beendet !!!',0

txtdf:
 DC.b 'Fehler in DF-Anweisung !!!',0

txtend:
 DC.b $d,$a,'Abbruch des Assembliervorgangs !!!',$d,$a,0

 DC.W 0
*******************************************************************************
*                          680xx Grundprogramm graf                           *
*                         (C) 1990 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*        Grafik-Paket für GDP und GDP-FPGA-Farbe ( allgemeine-Routinen )      *
*******************************************************************************


grafik:                         * Grafik-Paket für GDP S/W und Farbe
 cmp.b #33, d0                  * Befehlsnummer zu groß
 bgt carset
 move sr, -(a7)                 * Status sichern
 ori #$0700, sr                 * Interrupts aus
 move d0,d7                     * d7 wird immer zerstört/a6 kann zerstört werden
 and #$ff,d7                    * Überall aktueller Penmodus wirksam
 add d7,d7                      * Gleiche Aufrufe für S/W- und Farb-Variante
 add.b gdpcol(a5),d7            * Auswahl GDP S/W oder Farbe
 add d7,d7                      * GDP(512*512) 2 Farben / 16 Farben
 move grtab(pc,d7),d7
 jsr grtab(pc,d7)               * Programm aufrufen
 move (a7)+, sr                 * Staus zurück
  rts

grtab:
 DC.w gr1p0-grtab,gr1p0-grtab   * d0=0 Punkt setzen
 DC.w gr1p1-grtab,gr1p1-grtab   * d0=1 Linie zeichnen
 DC.w gr1p2-grtab,gr1p2-grtab   * d0=2 Linienfolge zeichnen
 DC.w gr1p3-grtab,gr1p3-grtab   * d0=3 Quadrat leer
 DC.w gr1p4-grtab,gr1p4-grtab   * d0=4 Quadrat voll
 DC.w gr1p5-grtab,gr1p5-grtab   * d0=5 Rechteck leer
 DC.w gr1p6-grtab,gr1p6-grtab   * d0=6 Rechteck voll
 DC.w gr1p7-grtab,gr1p7-grtab   * d0=7 Kreis leer
 DC.w gr1p8-grtab,gr1p8-grtab   * d0=8 Kreis voll
 DC.w gr1p9-grtab,gr1p9-grtab   * d0=9 Elipse leer
 DC.w gr1p10-grtab,gr1p10-grtab * d0=10 Elipse voll
 DC.w gr1p11-grtab,gr3p11-grtab * d0=11 Fläche füllen (Nur neue GDP)
 DC.w gr1p12-grtab,gr1p12-grtab * d0=12 Seite in Farbe ohne XOR löschen
 DC.w gr1p13-grtab,gr1p13-grtab * d0=13 Seite anwählen
 DC.w gr1p14-grtab,gr1p14-grtab * d0=14 Seite abfragen
 DC.w gr1p15-grtab,gr3p15-grtab * d0=15 Farbe / Verknüpfungsmode setzen
 DC.w gr1p16-grtab,gr3p16-grtab * d0=16 Farbe / Verknüpfungsmode lesen
 DC.w gr1p17-grtab,gr1p17-grtab * d0=17 Scrollen (Nur neue GDP)
 DC.w gr1p18-grtab,gr1p18-grtab * d0=18 Scrollwert holen (Nur neue GDP)
 DC.w gr1p19-grtab,gr3p19-grtab * d0=19 Einen Punkt holen (Nur neue GDP)
 DC.w gr1p20-grtab,gr3p20-grtab * d0=20 Hardcopy erstellen (Neue GDP)
 DC.w gr1p21-grtab,gr3p21-grtab * d0=21 Bild laden
 DC.w carset-grtab,carset-grtab * d0=22 frei
 DC.w gr1p23-grtab,gr1p23-grtab * d0=23 Text ausgeben
 DC.w gr1p24-grtab,gr1p24-grtab * d0=24 Progzge mit Voreinstellungen
 DC.w carset-grtab,carset-grtab * d0=25 frei
 DC.w gr1p26-grtab,gr3p26-grtab * d0=26 Sprite schreiben
 DC.w gr1p27-grtab,gr3p27-grtab * d0=27 Sprite löschen
 DC.w carset-grtab,carset-grtab * d0=28 frei
 DC.w carset-grtab,carset-grtab * d0=29 frei
 DC.w carset-grtab,carset-grtab * d0=30 frei
 DC.w grp31-grtab,grp31-grtab   * d0=31 Grafik-Karte lesen
 DC.w gr1p32-grtab,gr3p32-grtab * d0=32 Bereich speichern
 DC.w gr1p33-grtab,gr3p33-grtab * d0=33 Bereich schreiben


*******************************************************************************
*                      68000/68010 Grundprogramm grafgdp                      *
*                         (C) 1990 Ralph Dombrowski                           *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                           Grafik-Paket für GDP                              *
*******************************************************************************


gr1p0:                          * Punkt setzen
 move d2,d7                     * d1.w = X / d2.w = Y
 bsr grmoveto                   * Positionieren
 move.b #$80,gdp.w              * Befehl für Punkt zeichnen
 move d7,d2
  rts

gr1p1:                          * Linie zeichnen
 movem.l d0-d4,-(a7)            * d1.w/d2.w = Anfang
 bsr grmoveto                   * d3.w/d4.w = Ende
 asr #1,d4
 bsr drawt0                     * Endposition
 movem.l (a7)+,d0-d4
  rts

gr1p2:                          * Linienfolge zeichnen
 movem.l d0-d4,-(a7)            * a0 zerstört, dadurch mehrere Tabellen
 move (a0)+,d7                  * hintereinander möglich
 subq #2,d7                     * a0 auf Tabelle
 movem.w (a0)+,d1/d2            * Anfang der Tabelle = Anzahl der Punkte
 bsr grmoveto                   * Dann Anfangspunkt, dann weitere Punkte
gr1p2a:
 movem.w (a0),d3/d4             * Nächste Koordinate
 asr #1,d4                      * Y/2
 bsr drawt0                     * Drawto ohne getxy
 movem.w (a0)+,d1/d2            * Endpunkt alter Linie ist Anfangspunkt
 asr #1,d2                      * neuer Linie; Y/2
 dbra d7,gr1p2a
 movem.l (a7)+,d0-d4
  rts

gr1p3:                          * Quardrat leer
 movem.l d3/d4/a0,-(a7)         * d1/d2 linke untere Ecke / d3 = Kantenlänge
 move d3,d4                     * Kantenlängen müssen positiv sein
 bsr gr1u1                      * Wie Rechteck leer mit gleichen Seitenlängen
 movem.l (a7)+,d3/d4/a0
  rts

gr1p4:                          * Quadrat voll
 movem.l d0-d4,-(a7)            * d1/d2 linke untere Ecke / d3 = Kantenlänge
 move d3,d4                     * d3 muß positiv sein
 bra.s gr1p60                   * Wie Rechteck voll mit gleichen Seitenlängen

gr1p5:                          * Rechteck leer
 movem.l d3/d4/a0,-(a7)         * d1/d2 linke untere Ecke d3/d4 = Kantenlängen
 bsr gr1u1                      * Kantenlängen müssen positiv sein
 movem.l (a7)+,d3/d4/a0
  rts

gr1p6:                          * Rechteck voll
 movem.l d0-d4,-(a7)            * d1/d2 linke untere Ecke d3/d4 = Kantenlängen
gr1p60:                         * Kantenlängen müssen positiv sein
 subq #1, d3
 move d2, d0
 add d4, d0
 asr #1, d0
 asr #1, d2
 sub d2, d0
 move d0, d4
 lea gdp.w,a6                   * GDP-Basis-Register
 add d1,d3                      * Breite
 beq.s gr1p6a
 subq #1,d4                     * Sonst minus 1 wegen DBRA
gr1p6a:                         * Höhe 0 und Höhe 1 sind jeweils eine Linie
 bsr gr1xline                   * Linie ziehen
 addq #1,d2                     * Y-Position erhöhen
 dbra d4,gr1p6a
 movem.l (a7)+,d0-d4
  rts

gr1p7:                          * Kreis leer
 movem.l d0-d6/a0-a4,-(a7)      * d1/d2 Mittelpunkt / d3 = Radius
 move d3,d4                     * d3 muß positiv sein
 bsr gr1u2                      * Elipse leer aufrufen mit gleichen Radien
 movem.l (a7)+,d0-d6/a0-a4
  rts

gr1p8:                          * Kreis voll
 movem.l d0-d6/a0-a3,-(a7)      * d1/d2 Mittelpunkt / d3 = Radius
 move d3,d4                     * d3 muß positiv sein
 bsr gr1u3                      * Elipse voll aufrufen mit gleichen Radien
 movem.l (a7)+,d0-d6/a0-a3
  rts

gr1p9:                          * Elipse leer
 movem.l d0-d6/a0-a4,-(a7)      * d1/d2 Mittelpunkt / d3/d4 = Radien
 bsr gr1u2                      * Radien müssen positiv sein
 movem.l (a7)+,d0-d6/a0-a4
  rts

gr1p10:                         * Elipse voll
 movem.l d0-d6/a0-a3,-(a7)      * d1/d2 = Mittelpunkt / d3/d4 = Radien
 bsr gr1u3                      * Radien müssen positiv sein
 movem.l (a7)+,d0-d6/a0-a3
  rts

                                * ACHTUNG nicht mit Schwarz und XOR füllen
gr1p11:                         * Fläche füllen ( Nur bei neuer GDP )
 btst.b #0,ioflag(a5)           * d1/d2 ist Punkt innerhalb der Fläche
 beq carset                     * Fehler, da alte GDP
 cmp #511,d2
 bhi carset                     * Außerhalb des Bereichs
 cmp #511,d1
 bhi carset                     * Außerhalb des Bereichs
 movem.l d0-d6/a0,-(a7)
 lea page.w,a0                  * Auslese-Adresse
 lea gdp.w,a6                   * GDP-Basis-Register
 bsr grmoveto                   * Positionieren
 move.b gdp+1*cpu.w,d6          * Aktuelle Farbe holen
 ror.b #2,d6                    * Farbe in Bit 7
 and #$80,d6                    * Nur Bit 7 lassen
 bsr gr1p11h0                   * Punkt aus Bildschirmspeicher holen
 bne.s gr1p11fi                 * Wenn Farben gleich, dann Ende
 move #512,d5                   * Rechte Grenze
 move #-1,-(a7)                 * Endekennung Eckpunkte
 move d1,d3                     * X-Koordiante auch
 bsr.s gr1p11e                  * Linke Grenze holen
 movem.w d1/d2,-(a7)            * Merken (Auch Y-Koordinate)
 move d3,d1                     * X zurück
 bsr gr1p11f                    * Rechte Grenze holen
 move d1,-(a7)                  * Merken
gr1p11a:                        * Schleife
 move (a7)+,d3                  * Rechte Grenze vom Stack holen
 bmi.s gr1p11fi                 * Negativ, dann Stack leer und Ende
 movem.w (a7)+,d1/d2            * Linke Grenze und Y-Koordinate vom Stack holen
 bsr moveto
 bsr gr1p11h0                   * Punkt an aktueller Stelle holen
 bne.s gr1p11a                  * Schon gefüllt, dann weiter
 bsr gr1xline                   * Linie ziehen
 move d1,d4                     * d1 merken
 addq.b #1,d2                   * Eine Reihe hoch
 bsr wait                       * Warten bis GDP fertig
 addq.b #1,gdp+$b*cpu.w         * GDP Y-Register auch erhöhen
 beq.s gr1p11c                  * Obere Grenze erreicht
 bsr.s gr1p11e                  * Nach links, bis Farben ungleich
gr1p11b:
 bsr gr1p11g                    * Jetzt linke Grenze holen
 bcs.s gr1p11c                  * Fehler, keine linke Grenze gefunden
 movem.w d1/d2,-(a7)            * Werte merken
 bsr.s gr1p11f                  * Rechte Grenze holen
 move d1,-(a7)                  * Merken
 addq #1,d1                     * X-Koordinate erhöhen
 cmp d1,d3                      * Nicht über rechte Grenze hinaus
 bhi.s gr1p11b
gr1p11c:
 subq.b #2,d2                   * Eine Reihe tiefer (addq #1,d2 ausgleichen)
 cmp.b #255,d2                  * Überlauf ?
 beq.s gr1p11a                  * Ja, dann nächste Linie
 subq.b #2,gdp+$b*cpu.w         * Y-Koordinate erniedrigen
 move d4,d1                     * d1 zurück
 bsr.s gr1p11e                  * Und wie oben
gr1p11d:
 bsr.s gr1p11g
 bcs.s gr1p11a
 movem.w d1/d2,-(a7)
 bsr.s gr1p11f
 move d1,-(a7)
 addq #1,d1
 cmp d1,d3
 bhi.s gr1p11d
 bra.s gr1p11a
gr1p11fi:
 movem.l (a7)+,d0-d6/a0         * Register zurück
 bra carres                     * OK, alles klar

gr1p11e:                        * Nach links suchen, bis Schreibfarbe<>Bildfarbe
 bsr.s gr1p11h                  * Punkt holen
 bne.s gr1p11e3                 * Ungleich, dann OK
 move.b (a0),d7                 * Punktreihe holen
 beq.s gr1p11e1                 * Wenn 0 oder $ff
 cmp.b #$ff,d7                  * dann auf 8-ter Grenze bringen
 bne.s gr1p11e2
gr1p11e1:
 and #$1f8,d1                   * Auf 8-ter Grenze
gr1p11e2:
 subq #1,d1                     * 1 zurück
 bpl.s gr1p11e                  * Positiv, dann wiederholen
 addq #1,d1                     * Sonst auf 0 und Ende
  rts
gr1p11e3:
 cmp #511,d1                    * Ganz rechts ?
 beq.s gr1p11e4                 * Ja, dann Ende
 addq #1,d1                     * Sonst 1 nach rechts
gr1p11e4:
  rts

gr1p11f:                        * Rechte Grenze suchen
 bsr.s gr1p11h                  * Punkt holen
 bne.s gr1p11f3                 * OK, Ende
 move.b (a0),d7                 * Punktreihe holen
 beq.s gr1p11f1
 cmp.b #$ff,d7
 bne.s gr1p11f2
gr1p11f1:
 and #$1f8,d1                   * Auf 8-ter Grenze bringen
 addq #7,d1                     * 7 dazu
gr1p11f2:
 addq #1,d1                     * 1 dazu
 cmp d5,d1                      * Rechte Grenze erreicht ?
 bne.s gr1p11f                  * Nein, dann weiter
gr1p11f3:
 subq #1,d1                     * 1 zurück
  rts

gr1p11g:
 move d1,-(a7)
gr1p11g0:
 bsr.s gr1p11h                  * Linke Grenze suchen
 beq.s gr1p11g3                 * OK, gefunden
 move.b (a0),d7                 * Punktreihe holen
 beq.s gr1p11g1
 cmp.b #$ff,d7
 bne.s gr1p11g2
gr1p11g1:
 and #$1f8,d1                   * Auf 8-ter Grenze bringen
 addq #7,d1                     * 7 dazu
gr1p11g2:
 addq #1,d1                     * 1 dazu
 cmp d5,d1                      * Rechte Grenze erreicht ?
 bne.s gr1p11g0                 * Nein, dann weitersuchen
 addq.l #2,a7                   * Stack abbauen
 bra carset                     * Fehler, keine linke Grenze gefunden
gr1p11g3:
 move (a7)+,d0                  * Anfangsprüfpunkt nach d0
 cmp d3,d1                      * Über rechte Grenze hinaus ?
 bhi carset                     * Ja, Fehler
 cmp d0,d1
 bpl carres
 move d0,d1
 bra carres                     * OK, Linke Grenze korrekt gefunden

gr1p11h:                        * Einen Punkt prüfen
 movep.w d1,8*cpu(a6)           * X-Koordinate setzen  ==> Nur für 68000/68010
gr1p11h0:                       * Extra-Einsprung
 move.b #$f,(a6)                * Befehl für Speicher auslesen
 move d1,d0                     * X-Koordinate holen
 and #7,d0                      * Nur 0 bis 7
gr1p11h1:
 btst.b #2,(a6)                 * Warten, bis GDP fertig
 beq.s gr1p11h1
 move.b (a0),d7                 * Wert holen
 lsl d0,d7                      * Bit für Punkt an die richtige Stelle bringen
 and #$80,d7                    * Nur diesen Punkt lassen
 cmp.b d6,d7                    * Vergleich
  rts                            * Ende

gr1p12:                         * Schreibseite in aktueller Farbe löschen
                                * XORMODE wird dazu ausgeschaltet
 move.b gdpwpage(a5),d7         * Schreibseite
 lsl.b #2,d7
 or.b gdpwpage(a5),d7           * Wird gleich Leseseite gesetzt, damit alle
 lsl.b #4,d7                    * Seiten gelöscht werden können
 bsr wait                       * Warten, bis GDP fertig
 move.b d7,page.w               * Daten übertragen
 or.b #4,gdp+1*cpu.w            * Screen kurz ausschalten
 move.b #$c,gdp.w               * Screen löschen
 bsr gr1page                    * Alte Seite setzen
 and.b #$fb,gdp+1*cpu.w         * Screen wieder anschalten
  rts

gr1p13:                         * Seite GDP setzen
 move.b d1,d7
 and.b #3,d7
 move.b d7,gdpvpage(a5)         * d1 = Leseseite
 move.b d2,d7
 and.b #3,d7
 move.b d7,gdpwpage(a5)         * d2 = Schreibseite
 bra gr1page

gr1p14:                         * Seite abfragen
 moveq #0,d1
 move.b gdpvpage(a5),d1         * Leseseite
 moveq #0,d2
 move.b gdpwpage(a5),d2         * Schreibseite
  rts

gr1p15:                         * Schreibfarbe + Verknüpfungsmode
 and #1, d1                     * d1 ist Ergebnis Port 1 GDP
 move.b d1, gdpcolor(a5)        * Nur 0 oder 1
 move.b d2, d7
 and.b #1, d7
 move.b d7, gdpxor(a5)          * Nur an oder aus
 bsr gr1init                    * Alles setzen
 move.b gdp+1*cpu.w, d1         * Ergebnis Port 1 GDP
  rts

gr1p16:                         * Farbe und Verknüpfungsmode abfragen
                                * Ergebnis d1 = Farbe / d2 = Verknüpfungsmode
 moveq #0,d2                    * Langwort gültig
 move.b gdpxor(a5),d2           * d2.b ist Verknüpfungsmode (0/1)
 moveq #0,d1                    * Langwort gültig
 move.b gdpcolor(a5),d1         * In d1.b ist Farbe
  rts

gr1p17:                         * Scrollwert setzen
 btst.b #0,ioflag(a5)           * d1 = Anzahl Punkte (In Zweierschritten)
 beq carset                     * Nur bei neuer GDP gültig
 move.b d1,d7
 and.b #$fe,d7                  * Nur in Zweier-Schritten
 move.b d7,gdpscroll(a5)        * Neuer Scroll
 not.b d7                       * Durch NOT gleiche Scrollrichtung wie bei COL
 addq #1, d7                    * Wert korregieren
 move.b d7,page1.w              * Neuer Wert
 bra carres                     * Es wird immer um minimal zwei Punkte gedreht

gr1p18:                         * Scroll abfragen, Scrollwert in d1
 moveq #0,d1                    * Langwort ist gültig
 move.b gdpscroll(a5),d1        * Y-Scroll-Wert aber nur als Byte
  rts

gr1p19:                         * Einen Punkt abfragen
 btst.b #0,ioflag(a5)           * Neue GDP ?
 beq carset                     * Nein, dann ist kein Auslesen möglich
 cmp #511,d2
 bhi carset                     * Außerhalb des Screens
 cmp #511,d1
 bhi carset                     * Außerhalb des Screens
 moveq #0,d3                    * Bit innerhalb Langwort gültig
 move d2,d7
 bsr grmoveto                   * d3 ist Ergebnis Punkt
 move.b #$f,gdp.w               * Befehl für Speicher auslesen
 move d7,d2                     * d2 zurück
 move.b d1,d7                   * X-Koordinate nach d7
 and #7,d7                      * Auf 8-ter Grenze bringen
 addq #1,d7                     * 1 dazu wegen Schiebeoperation
gr1p19a:
 btst.b #2,gdp.w                * WAIT
 beq.s gr1p19a
 move.b page.w,d3               * Ein Byte aus Speicher holen
 rol.b d7,d3                    * Punkt an die richtige Stelle schieben
 not.b d3                       * Umdrehen, da invers im Speicher
 and.b #1,d3                    * Bit Null ist Punkt
 bra carres

gr1p20:                         * Hardcopy erstellen
 btst.b #0,ioflag(a5)           * In a0 steht Ziel
 beq carset                     * Nicht bei alter GDP
 movem.l d0-d3/a0,-(a7)
 moveq #2,d3                    * WAIT-Bit der GDP-Karte
 moveq #$f,d7                   * Befehl für Speicher auslesen
 lea gdp.w,a6                   * GDP-Basis-Register
 bsr wait                       * Warten bis GDP fertig
 move.b #$e,(a6)                * Y-Pos auf Null
 move.b #1,gdp+$8*cpu.w         * X-High auf 1, da Hälfte gleich getauscht wird
 clr.b gdp+$9*cpu.w             * X-Low auf Null
 move #256-1,d2                 * 256 Zeilen
gr1p20a:
 subq.b #1,gdp+$b*cpu.w         * Y-Koordinate erniedrigen
 moveq #2-1,d1                  * X-Bereich in zwei Teile geteilt
gr1p20b:
 eori.b #1,gdp+$8*cpu.w         * X-Bereich wechseln
 moveq #32-1,d0                 * 32 Bytes holen
gr1p20c:
 move.b d7,(a6)                 * Speicher auslesen
gr1p20d:
 btst.b d3,(a6)                 * WAIT
 beq.s gr1p20d
 move.b page.w,(a0)             * Wert holen
 not.b (a0)+                    * Steht invers im Screen der GDP, deshalb NOT
 addq.b #8,gdp+$9*cpu.w         * 8 Punkte weiter
 dbra d0,gr1p20c
 dbra d1,gr1p20b
 dbra d2,gr1p20a
 movem.l (a7)+,d0-d3/a0
 bra carres                     * OK, alles klar

gr1p21:                         * Bild laden
 movem.l d0-d6/a0-a1,-(a7)      * In a0 steht Quelle (Muß gerade Adresse sein)
 moveq #2,d6                    * WAIT-Bit der GDP-Karte
 moveq #$80,d7                  * Befehl für Punkt setzen
 lea gdp.w,a6                   * GDP-Basis für WAIT
 lea gdp+9*cpu.w,a1
 clr d1                         * X-Koordinate
 bsr wait
 move.b #1,gdp+8*cpu.w          * X-High auf 1, da Hälfte gleich getauscht wird
 move.b #$e,(a6)                * Y auf Null
 move #256-1,d2                 * 256 Reihen
gr1p21a:
 btst.b d6,(a6)                 * Warten
 beq.s gr1p21a
 subq.b #1,gdp+$b*cpu.w
 moveq #2-1,d3                  * X geteilt in zwei Hälften wegen 256-Grenze
gr1p21b:
 btst.b d6,(a6)                 * Warten
 beq.s gr1p21b
 eori.b #1,gdp+$8*cpu.w         * Hälfte ändern
 moveq #8-1,d4                  * 8*32*2 = 512
gr1p21c:
 move.l (a0)+,d0                * 32 Pixel
 moveq #32-1,d5                 * 32 Bit
gr1p21d:
 btst d5,d0                     * Test, ob Punkt gesetzt
 beq.s gr1p21f                  * Nicht gesetzt
 move.b d1,(a1)                 * Neue X-Koordinate
gr1p21e:
 btst.b d6,(a6)                 * Warten
 beq.s gr1p21e
 move.b d7,(a6)                 * Punkt setzen
gr1p21f:
 addq.b #1,d1
 dbra d5,gr1p21d
 dbra d4,gr1p21c
 dbra d3,gr1p21b
 dbra d2,gr1p21a
 movem.l (a7)+,d0-d6/a0-a1      * Register zurück
  rts

gr1p23:                         * Textausgabe
 movem.l d0/d2,-(a7)
 asr #1,d2                      * Bildschirmaufbau beachten
 move.b d3,d0                   * Wie textprint, allerdings ist d3 die Größe
 bsr textprint
 movem.l (a7)+,d0/d2
  rts

gr1p24:                         * Zeichengenerator mit Voreinstellung
 move d2,d7                     * Y-Position merken
 bsr grmoveto                   * Ergebnis ist neue Position in d1/d2
 move.b d3,gdp+3*cpu.w          * Größe einstellen
 bsr progzge                    * Zeichen ausgeben
 move.b d3,d2                   * Größe nach d2
 lsr #4,d2
 and #$f,d2                     * Nur X-Vergrößerung lassen
 beq.s gr1p24a
 moveq #16,d2                   * Null ist Vergrößerung 16
gr1p24a:
 add d2,d2
 add d2,d1
 add d2,d2                      * Mal Zeichenbreite (6)
 add d2,d1                      * Neue Position
 move d7,d2                     * d2 auf alten Wert
  rts

gr1init:                        * Farbe, XOR-Mode und Seiten setzen
 move.b gdp+1*cpu.w,d7
 and #$fc,d7                    * Penmodus löschen
 ror.b #1,d7
 or.b gdpcolor(a5),d7           * Farbe dazu
 rol.b #1,d7
 addq.b #1,d7                   * Stift senken
 bsr wait                       * Warten bis GDP fertig
 move.b d7,gdp+1*cpu.w          * Farbe eingestellt

gr1page:
 move.b gdpwpage(a5),d7         * Schreibseite
 lsl.b #2,d7
 or.b gdpvpage(a5),d7           * Leseseite
 lsl.b #4,d7
 or.b gdpxor(a5),d7             * XOR-Mode
 bsr wait                       * Warten, bis GDP fertig
 move.b d7,page.w               * Alles setzen
  rts

grp31:                          * Grafik-Karte lesen
 moveq #0,d1                    * Langwort ist gültig
 move.b gdpcol(a5),d1
  rts

gr1u1:                          * Rechteck leer
 subq #2,d4                     * Damit Höhe stimmt
 subq #1,d3                     * Damit Breite stimmt
 lea -150(a7),a0                * Stackbereich anlegen
 move #5,(a0)+                  * d1/d2 = linke untere Ecke
 move d1,(a0)+                  * d3/d4 = Seitenlängen (immer positiv)
 move d2,(a0)+                  * Erster Eckpunkt
 add d3,d1
 move d1,(a0)+
 move d2,(a0)+                  * Zweiter Eckpunkt
 add d4,d2
 move d1,(a0)+
 move d2,(a0)+                  * Dritter Eckpunkt
 sub d3,d1
 move d1,(a0)+
 move d2,(a0)+                  * Vierter Eckpunkt
 sub d4,d2
 move d1,(a0)+
 move d2,(a0)+                  * Zurück zum ersten Eckpunkt -> Viereck fertig
 lea -150(a7),a0
 bra gr1p2                      * Befehl Linienfolge

gr1u2:                          * Elipse leer
 lea gdp.w,a6                   * GDP-Basis-Register
 lea -300(a7),a0                * Hier werden Kreisdaten abgelegt
 movea.l a0,a4
 asr #1,d2                      * Bildschirmformat
 move d3,(a0)
 add d1,(a0)+
 move d2,(a0)+                  * Punkt ganz rechts (Alpha = 0)
 move d1,(a0)
 sub d3,(a0)+
 move d2,(a0)+                  * Punkt ganz links (Alpha = 180)
 add d3,d1
 bsr moveto                     * Punkt ganz rechts
 movea.l a0,a1                  * Adresse merken
 move #-1,(a1)+                 * Bis jetzt keine Linie
 move d3,d1                     * X-Koordinate
 clr d2                         * Y-Koordinate
 lea sintab+2(pc),a2            * Tabelle für Sinus
 lea sintab+180(pc),a3          * Tabelle für Cosinus
 moveq #90-1,d7                 * Nur ein Viertel berechnen/Rest durch Spiegeln
gr1u2a:
 move -(a3),d5                  * Cossinus holen (Tabelle)
 muls d3,d5                     * Mal X-Radius
 asr.l #8,d5                    * Durch 256
 move (a2)+,d6                  * Sinus aus Tabelle
 muls d4,d6                     * Mal Y-Radius
 asr.l #8,d6                    * Durch 256
 asr.l #1,d6                    * Bildschirmaufbau beachten
 move d6,d0
 add d1,d0                      * d1/d2 alte Koordinaten
 sub d5,d0                      * d5/d6 neue Koordinaten
 sub d2,d0
 beq.s gr1u2c                   * Alte Koordinate = Neue Koordinate, dann weiter
 sub d5,d1                      * Sonst Linie zeichnen
 move.b d1,(a1)+                * Abstand X  Alter Punkt - Neuer Punkt
gr1u2b:
 btst.b #2,(a6)
 beq.s gr1u2b                   * Warten bis GDP fertig
 move.b d1,gdp+5*cpu.w          * Ins GDP DX-Register
 move d5,d1                     * X-Koordinate merken
 move d6,d0
 sub d2,d0                      * Abstand Y  Alter Punkt - Neuer Punkt
 move.b d0,(a1)+                * Merken
 move.b d0,gdp+7*cpu.w          * Und ins GDP DY-Register
 move.b #$13,(a6)               * Befehl Linie nach Links Oben
 move d6,d2                     * Y-Koordinate merken
 addq #1,(a0)                   * Ein Punkt mehr vorhanden
gr1u2c:
 dbra d7,gr1u2a
 tst (a0)
 bpl.s gr1u2d                   * Wenn positiv, dann mindestens ein Punkt
 moveq #$80,d0
 bra cmd                        * Sonst nur Punkt setzen
gr1u2d:
 lea 4(a4),a0                   * Adresse Anfangskoordinate
 moveq #$11,d0                  * Richtung
 bsr.s gr1u2e                   * 2. Kreisbogen malen
 moveq #$15,d0                  * Richtung
 bsr.s gr1u2e                   * 3. Kreisbogen malen
 movea.l a4,a0                  * Adresse Anfangskoordinaten
 moveq #$17,d0                  * Richtung
gr1u2e:                         * Letzter Kreisbogen
 movem (a0),d1/d2
 bsr moveto                     * Anfangskoordinate
 lea 8(a4),a1                   * Adresse Linien
 move (a1)+,d1                  * Anzahl Linien-1
gr1u2f:
 btst.b #2,(a6)
 beq.s gr1u2f                   * Warten bis GDP fertig
 move.b (a1)+,gdp+5*cpu.w       * Delta-X
 move.b (a1)+,gdp+7*cpu.w       * Delta-Y
 move.b d0,(a6)                 * Befehl Linie ausgeben
 dbra d1,gr1u2f                 * Nächste Linie
  rts

gr1u3:                          * Elipse ausgefüllt
 lea gdp.w,a6                   * GDP-Basis-Register
 lea -100(a7),a0                * Merker Palt
 lea -104(a7),a1                * Merker Pneu
 asr #1,d2
 move d1,d5                     * Merker X
 move d2,d6                     * Merker Y
 add d3,d1
 movem d1/d2,(a0)               * Erste Koordinate für Vergleich merken
 move d3,d7
 neg d3
 add d5,d3
 bsr.s gr1xline                 * Linie durch Mittelpunkt, da Spezialfall
 move d7,d3                     * denn diese Linie wird nicht berechnet
 lea sintab+2(pc),a2            * Tabelle für Sinus
 lea sintab+180(pc),a3          * Tabelle für Cosinus
 moveq #90-1,d7                 * 90 Grad
gr1u3a:
 move -(a3),d1                  * Sinus
 muls d3,d1                     * Mal X-Radius
 asr.l #8,d1                    * Durch 256
 add d5,d1                      * X-Koordinate berechnet
 move (a2)+,d2                  * Cosinus
 muls d4,d2                     * Mal Y-Radius
 asr.l #8,d2                    * Durch 256
 asr.l #1,d2                    * Bildschirmformat
 add d6,d2                      * Y-Koordinate berechnet
 movem d1/d2,(a1)               * X,Y merken
gr1u3b:
 move d2,d0
 sub 2(a0),d0
 beq.s gr1u3d                   * Wenn Delta-Y = 0 , dann Linie nicht zeichnen
 cmp #1,d0
 beq.s gr1u3c                   * Wenn 1, dann zeichnen
 add (a0),d1                    * Sonst arithmetisches Mittel von letzter und
 asr #1,d1                      * dieser Koordinate bis Abstand nur noch 1,
 add 2(a0),d2                   * dadurch werden einige MULS und LSR eingespart
 asr #1,d2
 bra.s gr1u3b                   * Wiederholen bis Abstand zu Yalt = 1
gr1u3c:
 move d3,-(a7)                  * Abstand ist 1, jetzt Linie zeichnen
 movem d1/d2,(a0)               * Koordinaten merken
 move d5,d3
 add d5,d3
 sub d1,d3                      * Spiegelung an X-Achse
 bsr.s gr1xline                 * Linie parallel zur X-Achse
 neg d2
 add d6,d2
 add d6,d2                      * d2 an Mittelpunkt gespiegelt
 bsr.s gr1xline                 * Linie parallel zur X-Achse
 move (a7)+,d3
 move 2(a1),d2
 cmp 2(a0),d2                   * Wenn erste Y-Position und entgültig Berechnet
 beq.s gr1u3d                   * übereinstimmen, dann nächsten Punkt berechnen
 move (a1),d1                   * Sonst nächsten Punkt mit alten Winkel
 bra.s gr1u3b
gr1u3d:
 dbra d7,gr1u3a                 * Neuer Winkel
  rts

gr1xline:                       * d1/d2/d3   d0 darf zerstört werden
 move d3,d0                     * Delta-X
 sub d1,d0                      * berechnen
 bpl.s gr1xla                   * Wenn positiv, dann weiter
 exg d1,d3                      * d1 und d3 tauschen
 neg d0                         * Delta-X muß positiv sein
gr1xla:
 bsr moveto                     * Positionieren
gr1xlb:
 cmp #255,d0                    * Zu groß für eine Linie ?
 bhi.s gr1xld                   * Ja, dann teilen
gr1xlc:
 btst.b #2,(a6)                 * WAIT
 beq.s gr1xlc
 move.b d0,gdp+5*cpu.w          * Länge
 move.b #$10,(a6)               * Linie zeichnen
  rts

gr1xld:
 move d0,-(a7)                  * d0 merken
gr1xle:
 asr #1,d0
 cmp #255,d0                    * Immer noch zur groß ?
 bhi.s gr1xle                   * Ja, dann weiter teilen
gr1xlf:
 btst.b #2,(a6)                 * WAIT
 beq.s gr1xlf
 move.b d0,gdp+5*cpu.w          * Länge
 move.b #$10,(a6)               * Linie zeichnen
 neg d0
 add (a7)+,d0                   * Rest der Linie
 bra.s gr1xlb                   * Wiederholen

gr1ap16:
 moveq #16-1, d3                * 16 Pixel
gr1ap16a:
 tst d1                         * X-Koordinate
 bpl.s gr1ap16b                 * in Darstellungsbereich
 lsl #1, d0
 addq #1, d1                    * sonst nächstes Pixel
 dbra d3, gr1ap16a
 bra.s gr1ap16f                 * hier Ende
gr1ap16b:
 cmp #512, d1                   * rechter Rand überschritten?
 bge.s gr1ap16f                 * dann Ende
 movep.w d1, 0(a1)              * Neue X-Koordinate -- Nur für 68000/68010
 lsl #1, d0                     * ein Pixel in Carry
 bcc.s gr1ap16d                 * Schwarz
gr1ap16c:
 btst.b d6, (a6)                * Warten
 beq.s gr1ap16c
 bset.b #1, (a3)                * Schreibstift
 bra.s gr1ap16e
gr1ap16d:
 btst.b d6, (a6)                * Warten
 beq.s gr1ap16d
 bclr.b #1, (a3)                * Löschstift
gr1ap16e:
 move.b d7, (a6)                * Punkt setzen
 addq #1, d1
 dbra d3, gr1ap16b              * nächster Punkt
gr1ap16f:
  rts

gr1p26:                         * Sprite schreiben
 btst.b #0,ioflag(a5)           * In a0 steht Ziel
 beq carset                     * Nicht bei alter GDP
 movem.l d0-d6/a0-a6, -(a7)
 move.b gdpxor(a5), d0          * XOR-Mode
 move d0, -(a7)                 * auf Stack retten
 lea gdp.w, a6                  * GDP-Basis für WAIT
 lea gdp+8*cpu.w, a4            * X-Register GDP
 lea gdp+1*cpu.w, a3            * GDP-CTRL1
 move d3, d7                    * Optionen retten
 move.b (a1)+, d6               * Maske
 move.b (a1)+, d5               * Spriteart
 sub (a1)+, d1                  * X-Koordinate - X-Offset
 sub (a1)+, d2                  * Y-Koordinate - Y-Offset
 asr #1, d2                     * auf 0..255
 move.b (a1)+, d3               * X-Scalierung
 move.b (a1)+, d4               * Y-Scalierung
gr1p26a:
 addq #8, a1                    * +8 um auf Maske bzw. Bild zu kommen
 btst #0, d7                  * Hintergrund speichern?
 bne.s gr1p26b                  * nein!
 bsr gr1sb                      * Speicherroutine
gr1p26b:
 tst.b d6                       * Maske?
 bne gr1p26o                    * nein
 movea.l a1, a0                 * für Maske
 moveq #8, d0                   * 8 Zeilen
 asl d4, d0                     * *Y-Scalierung
 moveq #2, d7                   * 2 Byte
 asl d3, d7                     * *X-Scalierung
 mulu d7, d0                    * Größe der Maske
 adda d0, a1                    * hier Bildpointer
gr1p26m:                        * mit Maske 2 Farben
 move.b gdpwpage(a5),d6         * Schreibseite
 lsl.b #2,d6
 or.b gdpvpage(a5),d6           * Leseseite
 lsl.b #4,d6
 or.b gdpxor(a5),d6             * XOR-Mode
 moveq #8, d0                   * 8 Zeilen
 lsl d4, d0                     * *Y-Scalierung
 subq #1, d0                    * -1 als Zähler
 move d0, d4                    * nach d4
 btst #0, d5                  * 2 oder 16 Farben
 bne gr1p26n                    * 16 Farben dort
gr1p26m1:
 tst d2                         * Y >=0 ?
 bpl.s gr1p26m2                 * ja, dann Ausgabe
 moveq #2, d0                   * 2 Byte/Zeile
 lsl d3, d0                     * *X-Scalierung
 adda.l d0, a1                  * Bild auf nächste Zeile
 adda.l d0, a0                  * Maske auch auf
 addq #1, d2                    * nächste Zeile
 dbra d4, gr1p26m1
 bra gr1p26x                    * Ende
gr1p26m2:
 cmp #256, d2                   * oberer Rand überschritten?
 bge gr1p26x                    * Ende
 move.b d2, gdp+$b*cpu.w        * Y-Koordinate setzen
 move d1, -(a7)                 * X-Koordinate retten
 moveq #2, d5                   * 2 Byte
 lsl d3, d5                     * *X-Scalierung
 subq #1, d5                    * -1 als Zähler
gr1p26m3:
 move (a0)+, d0                 * 16 Masken-Pixel
 swap d0
 move (a1)+, d0                 * 16 Bild-Pixel laden
 moveq #16-1, d7                * 16 Bits
gr1p26m4:
 tst d1                         * X-Koordinate
 bpl.s gr1p26m5                 * in Darstellungsbereich
 lsl.l #1, d0
 addq #1, d1                    * sonst nächstes Pixel
 dbra d7, gr1p26m4
 bra.s gr1p26m9                 * hier Ende
gr1p26m5:
 cmp #512, d1                   * rechter Rand überschritten?
 bge.s gr1p26m9                 * dann Ende
gr1p26m6:
 btst.b #2, (a6)                * Warten
 beq.s gr1p26m6
 movep.w d1, 0(a4)              * Neue X-Koordinate -- Nur für 68000/68010
 lsl #1, d0                     * Pixel-Bit
 bcs.s gr1p26mb                 * gesetzt
 swap d0
 lsl #1, d0                     * Masken-Bit
 bcc.s gr1p26ma                 * wenn 0, dann Pixel belassen
 bra.s gr1p26m7                 * sonst Hintergrundfarbe
gr1p26mb:
 swap d0
 lsl #1, d0                     * Masken-Bit
 bcs.s gr1p26mc                 * Vordergrundfarbe setzen
 btst #0, d6                  * XOR-Mode
 bne.s gr1p26md                 * ist gesetzt, dann Pixel ausgeben
 bset #0, d6                  * XOR setzen
 move.b d6, page.w              * und ausgeben
 bra.s gr1p26md
gr1p26mc:
 btst #0, d6                  * XOR-Mode
 beq.s gr1p26md                 * ist gelöscht, dann weiter
 bclr #0, d6                  * XOR-Mode löschen
 move.b d6, page.w              * und ausgeben
gr1p26md:
 bset.b #1, (a3)                * Schreibstift
 bra.s gr1p26m8
gr1p26m7:
 bclr.b #1, (a3)                * Löschstift
gr1p26m8:
 move.b #$80, (a6)              * Punkt setzen
gr1p26ma:
 swap d0                        *
 addq #1, d1
 dbra d7, gr1p26m5              * nächster Punkt
gr1p26m9:
 dbra d5, gr1p26m3              * nächsten 2 Byte
 addq #1, d2                    * nächste Zeile
 move (a7)+, d1                 * X-Koordinate zurück
 dbra d4, gr1p26m2
 bra gr1p26x                    * hier Ende
gr1p26n:                        * mit Maske 16 Farben
gr1p26n1:
 tst d2                         * Y >=0 ?
 bpl.s gr1p26n2                 * ja, dann Ausgabe
 moveq #8, d0                   * 8 Byte/Zeile
 lsl d3, d0                     * *X-Scalierung
 adda.l d0, a1                  * Bild auf nächste Zeile
 moveq #2, d0                   * 2 Byte/Zeile
 lsl d3, d0                     * *X-Scalierung
 adda.l d0, a0                  * Maske auf nächste Zeile
 addq #1, d2                    * Y auch auf nächste Zeile
 dbra d4, gr1p26n1
 bra gr1p26x                    * Ende
gr1p26n2:
 cmp #256, d2                   * oberer Rand überschritten?
 bge gr1p26x                    * Ende
 move.b d2, gdp+$b*cpu.w        * Y-Koordinate setzen
 move d1, -(a7)                 * X-Koordinate retten
 moveq #8, d5                   * 8 Byte
 lsl d3, d5                     * *X-Scalierung
 subq #1, d5                    * -1 als Zähler
 swap d2                        *
gr1p26n3:
 move.b (a0)+, d2               * 8 Masken-Pixel
 move.l (a1)+, d0               * 8 Bild-Pixel laden
 moveq #8-1, d7                 * 8 Nibble
gr1p26n4:
 tst d1                         * X-Koordinate
 bpl.s gr1p26n5                 * in Darstellungsbereich
 lsl.b #1, d2                   * Maske
 lsl.l #4, d0                   * Pixel
 addq #1, d1                    * sonst nächstes Pixel
 dbra d7, gr1p26n4
 bra.s gr1p26n9                 * hier Ende
gr1p26n5:
 cmp #512, d1                   * rechter Rand überschritten?
 bge.s gr1p26n9                 * dann Ende
gr1p26n6:
 btst.b #2, (a6)                * Warten
 beq.s gr1p26n6
 movep.w d1, 0(a4)              * Neue X-Koordinate -- Nur für 68000/68010
 swap d1
 rol.l #4, d0                   * Pixel-Bit
 move.b d0, d1
 and.b #$01, d1                 * nur Bit #0 lassen
 bne.s gr1p26nb                 * gesetzt
 lsl.b #1, d2                   * Masken-Bit
 bcc.s gr1p26na                 * wenn 0, dann Pixel belassen
 bra.s gr1p26n7                 * sonst Hintergrundfarbe
gr1p26nb:
 lsl.b #1, d2                   * Masken-Bit
 bcs.s gr1p26nc                 * Vordergrundfarbe setzen
 btst #0, d6                  * XOR-Mode
 bne.s gr1p26nd                 * ist gesetzt, dann Pixel ausgeben
 bset #0, d6                  * XOR setzen
 move.b d6, page.w              * und ausgeben
 bra.s gr1p26nd
gr1p26nc:
 btst #0, d6                  * XOR-Mode
 beq.s gr1p26nd                 * ist gelöscht, dann weiter
 bclr #0, d6                  * XOR-Mode löschen
 move.b d6, page.w              * und ausgeben
gr1p26nd:
 bset.b #1, (a3)                * Schreibstift
 bra.s gr1p26n8
gr1p26n7:
 bclr.b #1, (a3)                * Löschstift
gr1p26n8:
 move.b #$80, (a6)              * Punkt setzen
gr1p26na:
 swap d1                        *
 addq #1, d1
 dbra d7, gr1p26n5              * nächster Punkt
gr1p26n9:
 dbra d5, gr1p26n3              * nächsten 8 Pixel
 swap d2
 addq #1, d2                    * nächste Zeile
 move (a7)+, d1                 * X-Koordinate zurück
 dbra d4, gr1p26n2
 bra gr1p26x                    * hier Ende
gr1p26o:                        * ohne Maske, 2 Farben
 clr.b gdpxor(a5)               * kein XOR
 bsr gr1page                    * Seite und XOR-Modus setzen
 moveq #8, d0                   * 8 Zeilen
 lsl d4, d0                     * *Y-Scalierung
 subq #1, d0                    * -1 als Zähler
 move d0, d4                    * nach d4
 btst #0, d5                  * 2 oder 16 Farben
 bne.s gr1p26p                  * 16 Farben dort
gr1p26o1:
 tst d2                         * Y >=0 ?
 bpl.s gr1p26o2                 * ja, dann Ausgabe
 moveq #2, d0                   * 2 Byte/Zeile
 lsl d3, d0                     * *X-Scalierung
 adda.l d0, a1
 addq #1, d2                    * nächste Zeile
 dbra d4, gr1p26o1
 bra gr1p26x                    * Ende
gr1p26o2:
 cmp #256, d2                   * rechter Rand überschritten?
 bge gr1p26x                    * Ende
 move.b d2, gdp+$b*cpu.w        * Y-Koordinate setzen
 move d1, -(a7)                 * X-Koordinate retten
 moveq #2, d5                   * 2 Byte
 lsl d3, d5                     * *X-Scalierung
 subq #1, d5                    * -1 als Zähler
gr1p26o3:
 move (a1)+, d0                 * 16 Pixel laden
 moveq #16-1, d7                * 16 Bits
gr1p26o4:
 tst d1                         * X-Koordinate
 bpl.s gr1p26o5                 * in Darstellungsbereich
 lsl #1, d0
 addq #1, d1                    * sonst nächstes Pixel
 dbra d7, gr1p26o4
 bra.s gr1p26o9                 * hier Ende
gr1p26o5:
 cmp #512, d1                   * rechter Rand überschritten?
 bge.s gr1p26o9                 * dann Ende
gr1p26o6:
 btst.b #2, (a6)                * Warten
 beq.s gr1p26o6
 movep.w d1, 0(a4)              * Neue X-Koordinate -- Nur für 68000/68010
 lsl #1, d0                     * ein Pixel in Carry
 bcc.s gr1p26o7                 * Schwarz
 bset.b #1, (a3)                * Schreibstift
 bra.s gr1p26o8
gr1p26o7:
 bclr.b #1, (a3)                * Löschstift
gr1p26o8:
 move.b #$80, (a6)              * Punkt setzen
 addq #1, d1
 dbra d7, gr1p26o5              * nächster Punkt
gr1p26o9:
 dbra d5, gr1p26o3              * nächsten 2 Byte
 addq #1, d2                    * nächste Zeile
 move (a7)+, d1                 * X-Koordinate zurück
 dbra d4, gr1p26o2
 bra.s gr1p26x                  * hier Ende
gr1p26p:                        * ohne Maske 16 Farben
gr1p26p1:
 tst d2                         * Y >=0 ?
 bpl.s gr1p26p2                 * ja, dann Ausgabe
 moveq #8, d0                   * 8 Byte/Zeile
 lsl d3, d0                     * *X-Scalierung
 adda.l d0, a1
 addq #1, d2                    * nächste Zeile
 dbra d4, gr1p26p1
 bra.s gr1p26x                  * Ende
gr1p26p2:
 cmp #256, d2                   * rechter Rand überschritten?
 bge.s gr1p26x                  * Ende
 move.b d2, gdp+$b*cpu.w        * Y-Koordinate setzen
 move d1, -(a7)                 * X-Koordinate retten
 moveq #8, d5                   * 8 Byte
 lsl d3, d5                     * *X-Scalierung
 subq #1, d5                    * -1 als Zähler
gr1p26p3:
 move.b (a1)+, d0               * 2 Pixel laden
 moveq #2-1, d7                 * a 4 Bits
gr1p26p4:
 tst d1                         * X-Koordinate
 bpl.s gr1p26p5                 * in Darstellungsbereich
 rol.b #4, d0
 addq #1, d1                    * sonst nächstes Pixel
 dbra d7, gr1p26p4
 bra.s gr1p26p9                 * hier Ende
gr1p26p5:
 cmp #512, d1                   * rechter Rand überschritten?
 bge.s gr1p26p9                 * dann Ende
 movep.w d1, 0(a4)              * Neue X-Koordinate -- Nur für 68000/68010
 rol.b #4, d0                   * Pixel ind Bit #3-0
 move.b d0, d6                  * nach d6
 and.b #$01, d6                 * nur akt. Pixel lassen Bit #0
 beq.s gr1p26p7                 * Schwarz
 bset.b #1, (a3)                * Schreibstift
 bra.s gr1p26p8
gr1p26p7:
 bclr.b #1, (a3)                * Löschstift
gr1p26p8:
 btst.b #2, (a6)                * Warten
 beq.s gr1p26p8
 move.b #$80, (a6)              * Punkt setzen
 addq #1, d1
 dbra d7, gr1p26p5              * nächster Punkt
gr1p26p9:
 dbra d5, gr1p26p3              * nächstes Byte
 addq #1, d2                    * nächste Zeile
 move (a7)+, d1                 * X-Koordinate zurück
 dbra d4, gr1p26p2
gr1p26x:
 move (a7)+, d0
 move.b d0, gdpxor(a5)
 bsr gr1page                    * Seite und XOR-Modus setzen
 movem.l (a7)+, d0-d6/a0-a6
 bra carres                     * OK, alles klar

gr1sb:                          * Hintergrund speichern
 movem.l d0-d6/a0/a3, -(a7)
 lea page.w, a3                 * Seiten Register
 move.b #0, (a0)+               * Spriteart = GDP-COL
 move.b gdpwpage(a5), (a0)+     * Schreibseite
 move d1, (a0)+                 * X-Koordinate
 move d2, (a0)+                 * Y-Koordinate
 move.b d3, (a0)+               * X-Scalierung
 move.b d4, (a0)+               * Y-Scalierung
 addq #8, a0                    * Offset für Bilddaten
 moveq #8, d5                   * 8 Zeilen
 lsl d4, d5                     * * Y-Scalierung
 subq #1, d5                    * -1 als Zähler
gr1sba:
 tst d2                         * Y >=0 ?
 bpl.s gr1sbb                   * ja, dann Ausgabe
 moveq #3, d0                   * 3 Byte/Zeile
 lsl d3, d0                     * *X-Scalierung
 adda.l d0, a0
 addq #1, d2                    * nächste Zeile
 dbra d5, gr1sba
 bra.s gr1sbx                   * Ende
gr1sbb:
 cmp #256, d2                   * oberer Rand überschritten?
 bge gr1sbx                     * dann Ende
 move.b d2, gdp+$b*cpu.w        * Y-Koordinate setzen
 or #$fff1, d1                  * X auf 8er Adresse bringen
 move d1, -(a7)                 * X-Koordinate sichern
 moveq #1, d6
 asl d3, d6                     * 1*X-Scalierung
 subq #1, d6                    * -1 als Zähler
gr1sbc:
 moveq #3-1, d4                 * max. 2*9 Punkte
gr1sbd:
 movep.w d1, 0(a4)              * X-Koordinate setzen --- Nur für 68000/68010
 move.b #$f, (a6)               * Befehl für Speicher auslesen
gr1sbe:
 btst.b #2, (a6)                * WAIT
 beq.s gr1sbe
 move.b (a3), d0                * 8 Pixel holen
 not.b d0                       * inventiert im Grafikspeicher
 move.b d0, (a0)+               * und speichern
 addq #8, d1                    * nächsten Pixel
 dbra d4, gr1sbd
 dbra d6, gr1sbc                * bei Scalierung
 move (a7)+, d1                 * X-Koordinate zurück
 addq #1, d2                    * nächste Zeile
 dbra d5, gr1sbb
gr1sbx:
 movem.l (a7)+, d0-d6/a0/a3
  rts

gr1p27:                         * Sprite löschen
 movem.l d0-d6/a0-a4, -(a7)     * a0 zeigt auf Speicher
 move.b (a0)+, d0               * Spriteart
 cmp.b #0, d0                   * GDP-SW-Sprite 32 bis 1544 Byte groß
 bne gr1p27d                    * sonst Fehler
 move.b gdpwpage(a5), d0        * Schreibseite
 lsl #8, d0                     * ins obere Byte
 move.b gdpxor(a5), d0          * XOR-Mode
 move d0, -(a7)                 * auf Stack retten
 move.b (a0)+, gdpwpage(a5)     * alte Schreibseite
 clr.b gdpxor(a5)               * XOR-Modus löschen
 bsr gr1page                    * Seite und XOR-Modus setzen
 move (a0)+, d1                 * X-Koordinate
 move (a0)+, d2                 * Y-Koordinate
 move.b (a0)+, d3               * X-Scalierung
 move.b (a0)+, d4               * Y-Scalierung
 addq #8, a0                    * +8 um auf Bilddaten zu kommen
 moveq #8, d5                   * 8 Zeilen
 lsl d4, d5                     * * Y-Scalierung
 subq #1, d5                    * -1 als Zähler
 move d1, d0                    * für Shiftfaktor
 and #$7, d0                    * nur 0-7
 moveq #8, d4
 sub d0, d4                     * 8-Shift
 moveq #2, d6                   * WAIT-Bit der GDP-Karte
 moveq #$80, d7                 * Befehl für Punkt setzen
 lea gdp.w, a6                  * GDP-Basis für WAIT
 lea gdp+1*cpu.w, a3            * GDP-CTRL1
 lea gdp+8*cpu.w, a1            * X-Register GDP
 lea gdp+$b*cpu.w, a4           * Y-Register LSB
gr1p27a:
 tst d2                         * Y >=0 ?
 bpl.s gr1p27b                  * ja, dann Ausgabe
 addq #1, d2                    * sonst nächste Zeile
 moveq #3, d0                   * 3 Byte/Zeile
 lsl d3, d0                     * *X-Scalierung
 adda.l d0, a0
 dbra d5, gr1p27a
 bra.s gr1p27d                  * hier Ende
gr1p27b:
 cmp #256, d2                   * oberer Rand überschritten?
 bge.s gr1p27d                  * ja, dann Ende
 move d3, -(a7)                 * X-Scale retten
 move d1, -(a7)                 * X retten
 moveq #1, d0                   * 1 * 3 Byte
 lsl d3, d0                     * * X-Scale
 subq #1, d0                    * -1 als X_Scale Zähler
 move d0, d3                    * in d3
 move.b d2, (a4)                * Y-Koordinaten setzen
gr1p27b1:
 move.b (a0)+, d0               * 1. Byte
 swap d0                        * in Bits #23-16
 move.b (a0)+, d0               * 2. Byte
 lsl #8, d0                     * in Bits #15-8
 move.b (a0)+, d0               * 3. Byte in Bits #7-0
 lsr.l d4, d0                   * Pixel in Position schieben
 move d3, -(a7)                 * X-Scale Zähler retten
 bsr gr1ap16                    * und ausgeben
 move (a7)+, d3                 * X-Scale Zähler zurück
 dbra d3, gr1p27b1
 addq #1, d2                    * Y+1
 move (a7)+, d1                 * X zurück
 move (a7)+, d3                 * X-Scale zurück
 dbra d5, gr1p27b               * nächste Zeile
gr1p27c:
 move (a7)+, d0
 move.b d0, gdpxor(a5)
 lsr #8, d0
 move.b d0, gdpwpage(a5)
 bsr gr1page                    * Seite und XOR-Modus setzen
 bset.b #1, (a3)                * Schreibstift muss gesetzt werden
 movem.l (a7)+, d0-d6/a0-a4
 bra carres
gr1p27d:                        * Fehler
 movem.l (a7)+, d0-d6/a0-a4
 bra carset

gr1p32:                         * Bereich speichern
 movem.l d0-d6/a0/a2-a4/a6, -(a7)
 lea page.w, a3                 * Seiten Register
 lea gdp.w, a6                  * GDP-Basis für WAIT
 lea gdp+8*cpu.w, a2            * X-Register GDP
 lea gdp+$b*cpu.w, a4           * Y-Register LSB
 move.l #$1FF, d0               * max. 511
 and.l d0, d1
 and.l d0, d2
 asr #1, d2                     * Y auf 0..255
 asr #1, d4                     * Höhe auf 0..255
 subq #1, d4                    * als Zähler
 move.b #-1, d5                 * Maske1
 move.b d5, d6                  * Maske2
 not.b d6
 move d1, d7                    * X-Koordinate
 or #$fff1, d1                  * Auf 8-Grenze bringen
 and #7, d7                     * Rest?
 beq.s gr1p32a                  * kein Rest vorhanden
 lsl.b d7, d5                   * Maske1
 move.b d5, d6
 not.b d6                       * Maske2
gr1p32a:
 move.b d2, (a4)                * Y-Koordinate setzen
 swap d2                        * Y retten
 clr d2                         * Vorsichtshalber löschen
 swap d4                        * Höhe retten
 clr d4                         * Vorsichtshalber löschen
 move d1, -(a7)                 * X-Koordinate sichern
 move d3, -(a7)                 * Breitenzähler sichern
 tst.b d7                       * Auf 8er Grenze?
 beq.s gr1p32c                  * Ja
                                * 1. Durchlauf wenn nicht auf 8er Adresse
 movep.w d1, 0(a2)              * X-Koordinate setzen --- Nur für 68000/68010
 move.b #$f, (a6)               * Befehl für Speicher auslesen
gr1p32b:
 btst.b #2, (a6)                * WAIT
 beq.s gr1p32b
 move.b (a3), d2                * erster Zugriff 8 Pixel holen
 not.b d2                       * invertieren
 lsl.b d7, d2                   * in Position schieben
 addq #8, d1                    *
gr1p32c:                        * Hier 1. Durchlauf 8er Adresse
 and.b d5, d2
 movep.w d1, 0(a2)              * X-Koordinate setzen --- Nur für 68000/68010
 move.b #$f, (a6)               * Befehl für Speicher auslesen
gr1p32d:
 btst.b #2, (a6)                * WAIT
 beq.s gr1p32d
 move.b (a3), d0                * 8 Pixel holen
 not.b d0                       * invertieren
 rol.b d7, d0                   * in Position schieben
 move.b d0, d4
 and.b d6, d0
 or.b d2, d0
 move.b d0, (a0)+               * und speichern
 move.b d4, d2
 addq #8, d1
 subq #8, d3
 bpl.s gr1p32c                  * nächste 8er Gruppe
 move (a7)+, d3                 * Breitenzähler zurück
 move (a7)+, d1                 * X-Koordinate zurück
 swap d2                        * Y-Koordinate zurück
 swap d4                        * Höhe zurück
 addq #1, d2                    * nächste Zeile
 dbra d4, gr1p32a
gr1p32x:
 movem.l (a7)+, d0-d6/a0/a2-a4/a6
  rts

gr1p33:                         * Bereich schreiben
 movem.l d0-d7/a0/a2-a4/a6, -(a7)
 lea gdp.w, a6                  * GDP-Basis für WAIT
 lea gdp+8*cpu.w, a2            * X-Register GDP
 lea gdp+1*cpu.w, a3            * GDP-CTRL1
 lea gdp+$b*cpu.w, a4           * Y-Register LSB
 move.l #$1FF, d0               * max. 511
 and.l d0, d1
 and.l d0, d2
 asr #1, d2                     * Y auf 0..255
 asr #1, d4                     * Höhe auf 0..255
 subq #1, d4                    * Höhenzähler
 subq #1, d3                    * Breitenzähler
 moveq #2, d6                   * Bit fürs Warten
 move.b #$80, d7                * Punkt setzen
gr1p33a:
 move.b d2, (a4)                * Y-Koordinate ausgeben
 movem d1/d3, -(a7)             * X-Koordinate u. Breitenzähler retten
gr1p33b:
 moveq #8-1, d5                 * Pixel in Byte
 move.b (a0)+, d0               * 8 Pixel
gr1p33c:
 movep.w d1, 0(a2)              * Neue X-Koordinate -- Nur für 68000/68010
 lsl.b #1, d0                   * ein Pixel in Carry
 bcc.s gr1p33e                  * Schwarz
gr1p33d:
 btst.b d6, (a6)                * Warten
 beq.s gr1p33d
 bset.b #1, (a3)                * Schreibstift
 bra.s gr1p33f
gr1p33e:
 btst.b d6, (a6)                * Warten
 beq.s gr1p33e
 bclr.b #1, (a3)                * Löschstift
gr1p33f:
 move.b d7, (a6)                * Punkt setzen
 addq #1, d1
 subq #1, d3
 bmi.s gr1p33g                  * Zeile fertig
 dbra d5, gr1p33c               * nächster Punkt
 bra.s gr1p33b
gr1p33g:
 movem (a7)+, d1/d3             * X-Koordinate u. Breitenzähler zurück
 addq #1, d2                    * nächstes Y
 dbra d4, gr1p33a
 bset.b #1, (a3)                * wieder auf Schreibstift!!!
 movem.l (a7)+, d0-d7/a0/a2-a4/a6
  rts
*******************************************************************************
*                     68000/68010 Grundprogramm grafgdpc                      *
*                             2009 Jens Mewes                                 *
*                               V 7.10 Rev 5                                  *
*                                06.05.2009                                   *
*                         Farbgrafik-Paket für GDP                            *
*******************************************************************************

                                * ACHTUNG nicht mit Schwarz und XOR füllen
gr3p11:                         * Fläche füllen ( Nur bei neuer GDP )
 cmp #511,d2
 bhi carset                     * Außerhalb des Bereichs
 cmp #511,d1
 bhi carset                     * Außerhalb des Bereichs
 movem.l d0-d6/a0,-(a7)
 lea page.w,a0                  * Auslese-Adresse
 lea gdp.w,a6                   * GDP-Basis-Register
 bsr g3moveto                   * Positionieren
 btst.b #1, gdp+1*cpu.w
 bne.s gr3p11aa
 move.b fgcolor(a5), d6
 bra.s gr3p11ab
gr3p11aa:
 move.b bgcolor(a5), d6
gr3p11ab:
 and #$f, d6
 bsr gr3p11h0                   * Punkt aus Bildschirmspeicher holen
 bne.s gr3p11fi                 * Wenn Farben gleich, dann Ende
 move #512,d5                   * Rechte Grenze
 move #-1,-(a7)                 * Endekennung Eckpunkte
 move d1,d3                     * X-Koordiante auch
 bsr.s gr3p11e                  * Linke Grenze holen
 movem.w d1/d2,-(a7)            * Merken (Auch Y-Koordinate)
 move d3,d1                     * X zurück
 bsr gr3p11f                    * Rechte Grenze holen
 move d1,-(a7)                  * Merken
gr3p11a:                        * Schleife
 move (a7)+,d3                  * Rechte Grenze vom Stack holen
 bmi.s gr3p11fi                 * Negativ, dann Stack leer und Ende
 movem.w (a7)+,d1/d2            * Linke Grenze und Y-Koordinate vom Stack holen
 bsr move3to
 bsr gr3p11h0                   * Punkt an aktueller Stelle holen
 bne.s gr3p11a                  * Schon gefüllt, dann weiter
 bsr gr1xline                   * Linie ziehen
 move d1,d4                     * d1 merken
 addq.b #1,d2                   * Eine Reihe hoch
 bsr wait3                      * Warten bis GDP fertig
 addq.b #1,gdp+$b*cpu.w         * GDP Y-Register auch erhöhen
 beq.s gr3p11c                  * Obere Grenze erreicht
 bsr.s gr3p11e                  * Nach links, bis Farben ungleich
gr3p11b:
 bsr gr3p11g                    * Jetzt linke Grenze holen
 bcs.s gr3p11c                  * Fehler, keine linke Grenze gefunden
 movem.w d1/d2,-(a7)            * Werte merken
 bsr.s gr3p11f                  * Rechte Grenze holen
 move d1,-(a7)                  * Merken
 addq #1,d1                     * X-Koordinate erhöhen
 cmp d1,d3                      * Nicht über rechte Grenze hinaus
 bhi.s gr3p11b
gr3p11c:
 subq.b #2,d2                   * Eine Reihe tiefer (addq #1,d2 ausgleichen)
 cmp.b #255,d2                  * Überlauf ?
 beq.s gr3p11a                  * Ja, dann nächste Linie
 subq.b #2,gdp+$b*cpu.w         * Y-Koordinate erniedrigen
 move d4,d1                     * d1 zurück
 bsr.s gr3p11e                  * Und wie oben
gr3p11d:
 bsr.s gr3p11g
 bcs.s gr3p11a
 movem.w d1/d2,-(a7)
 bsr.s gr3p11f
 move d1,-(a7)
 addq #1,d1
 cmp d1,d3
 bhi.s gr3p11d
 bra.s gr3p11a
gr3p11fi:
 movem.l (a7)+,d0-d6/a0         * Register zurück
 bra carres                     * OK, alles klar

gr3p11e:                        * Nach links suchen, bis Schreibfarbe<>Bildfarbe
 bsr.s gr3p11h                  * Punkt holen
 bne.s gr3p11e3                 * Ungleich, dann OK
gr3p11e2:
 subq #1,d1                     * 1 zurück
 bpl.s gr3p11e                  * Positiv, dann wiederholen
 addq #1,d1                     * Sonst auf 0 und Ende
  rts

gr3p11e3:
 cmp #511,d1                    * Ganz rechts ?
 beq.s gr3p11e4                 * Ja, dann Ende
 addq #1,d1                     * Sonst 1 nach rechts
gr3p11e4:
  rts

gr3p11f:                        * Rechte Grenze suchen
 bsr.s gr3p11h                  * Punkt holen
 bne.s gr3p11f3                 * OK, Ende
 addq #1,d1                     * 1 dazu
 cmp d5,d1                      * Rechte Grenze erreicht ?
 bne.s gr3p11f                  * Nein, dann weiter
gr3p11f3:
 subq #1,d1                     * 1 zurück
  rts

gr3p11g:
 move d1,-(a7)
gr3p11g0:
 bsr.s gr3p11h                  * Linke Grenze suchen
 beq.s gr3p11g3                 * OK, gefunden
 addq #1,d1                     * 1 dazu
 cmp d5,d1                      * Rechte Grenze erreicht ?
 bne.s gr3p11g0                 * Nein, dann weitersuchen
 addq.l #2,a7                   * Stack abbauen
 bra carset                     * Fehler, keine linke Grenze gefunden
gr3p11g3:
 move (a7)+,d0                  * Anfangsprüfpunkt nach d0
 cmp d3,d1                      * Über rechte Grenze hinaus ?
 bhi carset                     * Ja, Fehler
 cmp d0,d1
 bpl carres
 move d0,d1
 bra carres                     * OK, Linke Grenze korrekt gefunden

gr3p11h:                        * Einen Punkt prüfen
 movep.w d1,8*cpu(a6)           * X-Koordinate einstellen ==> Nur für 68000
gr3p11h0:                       * Extra-Einsprung
 move.b #$f,(a6)                * Befehl für Speicher auslesen
 move d1,d0                     * X-Koordinate holen
 not d0
 and #1, d0
 asl #2, d0
gr3p11h1:
 btst.b #2,(a6)                 * Warten, bis GDP fertig
 beq.s gr3p11h1
 move.b (a0),d7                 * Wert holen
 lsr d0,d7                      * Bit für Punkt an die richtige Stelle bringen
 not d7
 and #$f,d7                     * Nur diesen Punkt lassen
 cmp.b d6,d7                    * Vergleich
  rts                            * Ende

gr3p15:                         * Schreibfarbe + Verknüpfungsmode
 tst d1                         * schwarz?
 beq.s gr3p15a                  * ja!
 clr.b bgcolor(a5)              * Hintergrund schwarz
 move.b d1, fgcolor(a5)
 move.b #1, gdpcolor(a5)        * Nur 0 oder 1
 move.b gdp+1*cpu.w, d7
 or.b #$03, d7                  * Screibstift und setzen
 bsr wait3
 move.b d7, gdp+1*cpu.w
 bra.s gr3p15b
gr3p15a:
 move.b #1, bgcolor(a5)         * weißer Hintergrund
 move.b d1, fgcolor(a5)
 clr.b gdpcolor(a5)
 move.b gdp+1*cpu.w, d7
 bclr #1, d7                  * Löschstift
 bset #0, d7                  * Setzen
 bsr wait3
 move.b d7, gdp+1*cpu.w
gr3p15b:
 move.b fgcolor(a5), colport.w
 move.b bgcolor(a5), colport1.w
 move.b d2, d7
 and.b #1, d7
 move.b d7, gdpxor(a5)          * Nur an oder aus
 bra gr1page

gr3p16:                         * Farbe und Verknüpfungsmode abfragen
                                * Ergebnis d1 = Farbe / d2 = Verknüpfungsmode
 moveq #0, d2                   * Langwort gültig
 move.b gdpxor(a5), d2          * d2.b ist Verknüpfungsmode (0/1)
 moveq #0, d1                   * Langwort gültig
 move.b fgcolor(a5), d1         * In d1.b ist die Farbe
  rts

gr3p19:                         * Einen Punkt abfragen
 cmp #511,d2
 bhi carset                     * Außerhalb des Screens
 cmp #511,d1
 bhi carset                     * Außerhalb des Screens
 moveq #0,d3                    * Bit innerhalb Langwort gültig
 move d2,d7
 bsr g3moveto                   * d3 ist Ergebnis Punkt
 move.b #$f,gdp.w               * Befehl für Speicher auslesen
 move d7,d2                     * d2 zurück
 move d1,d7                     * X-Koordinate nach d7
 not d7
 and #1, d7
 asl #2, d7
gr3p19a:
 btst.b #2,gdp.w                * WAIT
 beq.s gr3p19a
 move.b page.w,d3               * Ein Byte aus Speicher holen
 lsr.b d7,d3                    * Punkt an die richtige Stelle schieben
 not.b d3                       * Umdrehen, da invers im Speicher
 and.b #$f,d3                   * Bit 0-3 ist Punkt
 bra carres

gr3p20:                         * Hardcopy erstellen
 movem.l d0-d3/a0,-(a7)
 moveq #2,d3                    * WAIT-Bit der GDP-Karte
 moveq #$f,d7                   * Befehl für Speicher auslesen
 lea gdp.w,a6                   * GDP-Basis-Register
 bsr wait3                      * Warten bis GDP fertig
 move.b #$e,gdp.w               * Y-Pos auf Null
 move.b #1,gdp+$8*cpu.w         * X-High auf 1, da Hälfte gleich getauscht wird
 clr.b gdp+$9*cpu.w             * X-Low auf Null
 move #256-1,d2                 * 256 Zeilen
gr3p20a:
 subq.b #1,gdp+$b*cpu.w         * Y-Koordinate erniedrigen
 moveq #2-1,d1                  * X-Bereich in zwei Teile geteilt
gr3p20b:
 eori.b #1,gdp+$8*cpu.w         * X-Bereich wechseln
 moveq #128-1,d0                * 128 Bytes holen
gr3p20c:
 move.b d7,(a6)                 * Speicher auslesen
gr3p20d:
 btst.b d3,(a6)                 * WAIT
 beq.s gr3p20d
 move.b page.w,(a0)             * Wert holen
 not.b (a0)+                    * Steht invers im Screen der GDP, deshalb NOT
 addq.b #2,gdp+$9*cpu.w         * 2 Punkte weiter
 dbra d0,gr3p20c
 dbra d1,gr3p20b
 dbra d2,gr3p20a
 movem.l (a7)+,d0-d3/a0
 bra carres                     * OK, alles klar


gr3p21:                         * Bild laden
 movem.l d0-d6/a0-a2,-(a7)      * In a0 steht Quelle (Muß gerade Adresse sein)
 moveq #2,d6                    * WAIT-Bit der GDP-Karte
 moveq #$80,d7                  * Befehl für Punkt setzen
 lea gdp.w,a6                   * GDP-Basis für WAIT
 lea gdp+9*cpu.w,a1
 lea colport.w, a2
 clr d1                         * X-Koordinate
 bsr wait3
 move.b #1,gdp+8*cpu.w          * X-High auf 1, da Hälfte gleich getauscht wird
 move.b #$e,gdp.w               * Y auf Null
 move #256-1,d2                 * 256 Reihen
gr3p21a:
 btst.b d6,(a6)                 * Warten
 beq.s gr3p21a
 subq.b #1,gdp+$b*cpu.w
 moveq #2-1,d3                  * X geteilt in zwei Hälften wegen 256-Grenze
gr3p21b:
 btst.b d6,(a6)                 * Warten
 beq.s gr3p21b
 eori.b #1,gdp+$8*cpu.w         * Hälfte ändern
 moveq #64-1,d4                 * 64*4*2 = 512
gr3p21c:
 move (a0)+,d0                  * 4 Pixel
 moveq #4-1,d5                  *
gr3p21d:
 rol.l #4, d0                   * Pixel in Bit #16-19
 swap d0                        * jetzt in Bit #0-3
 and.b #$f, d0                  * nur unterstes Nibble
 beq.s gr3p21f                  * Nicht gesetzt
 move.b d1,(a1)                 * Neue X-Koordinate
gr3p21e:
 btst.b d6,(a6)                 * Warten
 beq.s gr3p21e
 move.b d0, (a2)                * Farbe setzen
 move.b d7,(a6)                 * Punkt setzen
gr3p21f:
 swap d0
 addq.b #1,d1
 dbra d5,gr3p21d
 dbra d4,gr3p21c
 dbra d3,gr3p21b
 dbra d2,gr3p21a
 movem.l (a7)+,d0-d6/a0-a2      * Register zurück
  rts

gr3p26:                         * Sprite/Bild schreiben
 movem.l d0-d6/a0-a6, -(a7)
 move.b gdpxor(a5), d0          * XOR-Mode
 move d0, -(a7)                 * auf Stack retten
 lea gdp.w, a6                  * GDP-Basis für WAIT
 lea gdp+8*cpu.w, a4            * X-Register GDP
 lea gdp+1*cpu.w, a3            * GDP-CTRL1
 lea colport.w, a2              * Farbregister
 move d3, d7                    * Optionen retten
 move.b (a1)+, d6               * Maske
 move.b (a1)+, d5               * Spriteart
 sub (a1)+, d1                  * X-Koordinate - X-Offset
 asr #1, d2                     * auf 0..255
 sub (a1)+, d2                  * Y-Koordinate - Y-Offset
 move.b (a1)+, d3               * X-Scalierung
 move.b (a1)+, d4               * Y-Scalierung
 clr.b colport1.w               * Hintergrundfabe auf 0
 btst #0, d5                  * Sprite mit 2 oder 16 Farben?
 bne.s gr3p26a                  * 16!
 move.b 0(a1), (a2)             * Vordergrundfarbe
 move.b 1(a1), colport1.w       * Hintergrundfarbe
gr3p26a:
 addq #8, a1                    * +8 um auf Maske bzw. Bild zu kommen
 btst #0, d7                  * Hintergrund speichern?
 bne.s gr3p26b                  * nein!
 bsr gr3sb                      * Speicherroutine
gr3p26b:
 tst.b d6                       * Maske?
 bne gr3p26o                    * nein
 movea.l a1, a0                 * für Maske
 moveq #8, d0                   * 8 Zeilen
 asl d4, d0                     * *Y-Scalierung
 moveq #2, d7                   * 2 Byte
 asl d3, d7                     * *X-Scalierung
 mulu d7, d0                    * Größe der Maske
 adda d0, a1                    * hier Bildpointer

gr3p26m:                        * mit Maske
 move.b gdpwpage(a5),d6         * Schreibseite
 lsl.b #2,d6
 or.b gdpvpage(a5),d6           * Leseseite
 lsl.b #4,d6
 or.b gdpxor(a5),d6             * XOR-Mode
 moveq #8, d0                   * 8 Zeilen
 lsl d4, d0                     * *Y-Scalierung
 subq #1, d0                    * -1 als Zähler
 move d0, d4                    * nach d4
 btst #0, d5                  * 2 oder 16 Farben
 bne gr3p26n                    * 16 Farben dort

gr3p26m1:                       * mit Maske 2 Farben
 tst d2                         * Y >=0 ?
 bpl.s gr3p26m2                 * ja, dann Ausgabe
 moveq #2, d0                   * 2 Byte/Zeile
 lsl d3, d0                     * *X-Scalierung
 adda.l d0, a1                  * Bild auf nächste Zeile
 adda.l d0, a0                  * Maske auch auf
 addq #1, d2                    * nächste Zeile
 dbra d4, gr3p26m1
 bra gr3p26x                    * Ende
gr3p26m2:
 cmp #256, d2                   * oberer Rand überschritten?
 bge gr3p26x                    * Ende
 move.b d2, gdp+$b*cpu.w        * Y-Koordinate setzen
 move d1, -(a7)                 * X-Koordinate retten
 moveq #2, d5                   * 2 Byte
 lsl d3, d5                     * *X-Scalierung
 subq #1, d5                    * -1 als Zähler
gr3p26m3:
 move (a0)+, d0                 * 16 Masken-Pixel
 swap d0
 move (a1)+, d0                 * 16 Bild-Pixel laden
 moveq #16-1, d7                * 16 Bits
gr3p26m4:
 tst d1                         * X-Koordinate
 bpl.s gr3p26m5                 * in Darstellungsbereich
 lsl.l #1, d0
 addq #1, d1                    * sonst nächstes Pixel
 dbra d7, gr3p26m4
 bra.s gr3p26m9                 * hier Ende
gr3p26m5:
 cmp #512, d1                   * rechter Rand überschritten?
 bge.s gr3p26m9                 * dann Ende
gr3p26m6:
 btst.b #2, (a6)                * Warten
 beq.s gr3p26m6
 movep.w d1, 0(a4)              * Neue X-Koordinate -- Nur für 68000
 lsl #1, d0                     * Pixel-Bit
 bcs.s gr3p26mb                 * gesetzt
 swap d0
 lsl #1, d0                     * Masken-Bit
 bcc.s gr3p26ma                 * wenn 0, dann Pixel belassen
 bra.s gr3p26m7                 * sonst Hintergrundfarbe
gr3p26mb:
 swap d0
 lsl #1, d0                     * Masken-Bit
 bcs.s gr3p26mc                 * Vordergrundfarbe setzen
 btst #0, d6                  * XOR-Mode
 bne.s gr3p26md                 * ist gesetzt, dann Pixel ausgeben
 bset #0, d6                  * XOR setzen
 move.b d6, page.w              * und ausgeben
 bra.s gr3p26md
gr3p26mc:
 btst #0, d6                  * XOR-Mode
 beq.s gr3p26md                 * ist gelöscht, dann weiter
 bclr #0, d6                  * XOR-Mode löschen
 move.b d6, page.w              * und ausgeben
gr3p26md:
 bset.b #1, (a3)                * Schreibstift
 bra.s gr3p26m8
gr3p26m7:
 bclr.b #1, (a3)                * Löschstift
gr3p26m8:
 move.b #$80, (a6)              * Punkt setzen
gr3p26ma:
 swap d0                        *
 addq #1, d1
 dbra d7, gr3p26m5              * nächster Punkt
gr3p26m9:
 dbra d5, gr3p26m3              * nächsten 2 Byte
 addq #1, d2                    * nächste Zeile
 move (a7)+, d1                 * X-Koordinate zurück
 dbra d4, gr3p26m2
 bra gr3p26x                    * hier Ende

gr3p26n:                        * mit Maske 16 Farben
gr3p26n1:
 tst d2                         * Y >=0 ?
 bpl.s gr3p26n2                 * ja, dann Ausgabe
 moveq #8, d0                   * 8 Byte/Zeile
 lsl d3, d0                     * *X-Scalierung
 adda.l d0, a1                  * Bild auf nächste Zeile
 moveq #2, d0                   * 2 Byte/Zeile
 lsl d3, d0                     * *X-Scalierung
 adda.l d0, a0                  * Maske auf nächste Zeile
 addq #1, d2                    * Y auch auf nächste Zeile
 dbra d4, gr3p26n1
 bra gr3p26x                    * Ende
gr3p26n2:
 cmp #256, d2                   * oberer Rand überschritten?
 bge gr3p26x                    * Ende
 move.b d2, gdp+$b*cpu.w        * Y-Koordinate setzen
 move d1, -(a7)                 * X-Koordinate retten
 moveq #2, d5                   * 8 Byte
 lsl d3, d5                     * *X-Scalierung
 subq #1, d5                    * -1 als Zähler
 swap d2                        *
gr3p26n3:
 move.b (a0)+, d2               * 8 Masken-Pixel
 move.l (a1)+, d0               * 8 Bild-Pixel laden
 moveq #8-1, d7                 * 8 Nibble
gr3p26n4:
 tst d1                         * X-Koordinate
 bpl.s gr3p26n5                 * in Darstellungsbereich
 lsl.b #1, d2                   * Maske
 lsl.l #4, d0                   * Pixel
 addq #1, d1                    * sonst nächstes Pixel
 dbra d7, gr3p26n4
 bra.s gr3p26n9                 * hier Ende
gr3p26n5:
 cmp #512, d1                   * rechter Rand überschritten?
 bge.s gr3p26n9                 * dann Ende
gr3p26n6:
 btst.b #2, (a6)                * Warten
 beq.s gr3p26n6
 movep.w d1, 0(a4)              * Neue X-Koordinate -- Nur für 68000
 swap d1
 rol.l #4, d0                   * Pixel-Bit
 move.b d0, d1
 and.b #$0f, d1
 bne.s gr3p26nb                 * gesetzt
 lsl.b #1, d2                   * Masken-Bit
 bcc.s gr3p26na                 * wenn 0, dann Pixel belassen
 bra.s gr3p26n7                 * sonst Hintergrundfarbe
gr3p26nb:
 lsl.b #1, d2                   * Masken-Bit
 bcs.s gr3p26nc                 * Vordergrundfarbe setzen
 btst #0, d6                  * XOR-Mode
 bne.s gr3p26nd                 * ist gesetzt, dann Pixel ausgeben
 bset #0, d6                  * XOR setzen
 move.b d6, page.w              * und ausgeben
 bra.s gr3p26nd
gr3p26nc:
 btst #0, d6                  * XOR-Mode
 beq.s gr3p26nd                 * ist gelöscht, dann weiter
 bclr #0, d6                  * XOR-Mode löschen
 move.b d6, page.w              * und ausgeben
gr3p26nd:
 move.b d1, (a2)                * Farbe
 bset.b #1, (a3)                * Schreibstift
 bra.s gr3p26n8
gr3p26n7:
 bclr.b #1, (a3)                * Löschstift
gr3p26n8:
 move.b #$80, (a6)              * Punkt setzen
gr3p26na:
 swap d1                        *
 addq #1, d1
 dbra d7, gr3p26n5              * nächster Punkt
gr3p26n9:
 dbra d5, gr3p26n3              * nächsten 8 Pixel
 swap d2
 addq #1, d2                    * nächste Zeile
 move (a7)+, d1                 * X-Koordinate zurück
 dbra d4, gr3p26n2
 bra gr3p26x                    * hier Ende

gr3p26o:                        * ohne Maske
 clr.b gdpxor(a5)               * kein XOR
 bsr gr1page                    * Seite und XOR-Modus setzen
 moveq #8, d0                   * 8 Zeilen
 lsl d4, d0                     * *Y-Scalierung
 subq #1, d0                    * -1 als Zähler
 move d0, d4                    * nach d4
 btst #0, d5                  * 2 oder 16 Farben
 bne.s gr3p26p                  * 16 Farben dort

gr3p26o1:                       * ohne Maske 2 Farben
 tst d2                         * Y >=0 ?
 bpl.s gr3p26o2                 * ja, dann Ausgabe
 moveq #2, d0                   * 2 Byte/Zeile
 lsl d3, d0                     * *X-Scalierung
 adda.l d0, a1
 addq #1, d2                    * nächste Zeile
 dbra d4, gr3p26o1
 bra gr3p26x                    * Ende
gr3p26o2:
 cmp #256, d2                   * rechter Rand überschritten?
 bge gr3p26x                    * Ende
 move.b d2, gdp+$b*cpu.w        * Y-Koordinate setzen
 move d1, -(a7)                 * X-Koordinate retten
 moveq #2, d5                   * 2 Byte
 lsl d3, d5                     * *X-Scalierung
 subq #1, d5                    * -1 als Zähler
gr3p26o3:
 move (a1)+, d0                 * 16 Pixel laden
 moveq #16-1, d7                * 16 Bits
gr3p26o4:
 tst d1                         * X-Koordinate
 bpl.s gr3p26o5                 * in Darstellungsbereich
 lsl #1, d0
 addq #1, d1                    * sonst nächstes Pixel
 dbra d7, gr3p26o4
 bra.s gr3p26o9                 * hier Ende
gr3p26o5:
 cmp #512, d1                   * rechter Rand überschritten?
 bge.s gr3p26o9                 * dann Ende
gr3p26o6:
 btst.b #2, (a6)                * Warten
 beq.s gr3p26o6
 movep.w d1, 0(a4)              * Neue X-Koordinate -- Nur für 68000
 lsl #1, d0                     * ein Pixel in Carry
 bcc.s gr3p26o7                 * Schwarz
 bset.b #1, (a3)                * Schreibstift
 bra.s gr3p26o8
gr3p26o7:
 bclr.b #1, (a3)                * Löschstift
gr3p26o8:
 move.b #$80, (a6)              * Punkt setzen
 addq #1, d1
 dbra d7, gr3p26o5              * nächster Punkt
gr3p26o9:
 dbra d5, gr3p26o3              * nächsten 2 Byte
 addq #1, d2                    * nächste Zeile
 move (a7)+, d1                 * X-Koordinate zurück
 dbra d4, gr3p26o2
 bra.s gr3p26x                  * hier Ende

gr3p26p:                        * ohne Maske 16 Farben
gr3p26p1:
 tst d2                         * Y >=0 ?
 bpl.s gr3p26p2                 * ja, dann Ausgabe
 moveq #8, d0                   * 8 Byte/Zeile
 lsl d3, d0                     * *X-Scalierung
 adda.l d0, a1
 addq #1, d2                    * nächste Zeile
 dbra d4, gr3p26p1
 bra.s gr3p26x                  * Ende
gr3p26p2:
 cmp #256, d2                   * oberer Rand überschritten?
 bge.s gr3p26x                  * Ende
 move.b d2, gdp+$b*cpu.w        * Y-Koordinate setzen
 move d1, -(a7)                 * X-Koordinate retten
 moveq #8, d5                   * 8 Byte
 lsl d3, d5                     * *X-Scalierung
 subq #1, d5                    * -1 als Zähler
gr3p26p3:
 move.b (a1)+, d0               * 2 Pixel laden
 moveq #2-1, d7                 * a 4 Bits
gr3p26p4:
 tst d1                         * X-Koordinate
 bpl.s gr3p26p5                 * in Darstellungsbereich
 rol.b #4, d0
 addq #1, d1                    * sonst nächstes Pixel
 dbra d7, gr3p26p4
 bra.s gr3p26p9                 * hier Ende
gr3p26p5:
 cmp #512, d1                   * rechter Rand überschritten?
 bge.s gr3p26p9                 * dann Ende
gr3p26p6:
 btst.b #2, (a6)                * Warten
 beq.s gr3p26p6
 movep.w d1, 0(a4)              * Neue X-Koordinate -- Nur für 68000
 rol.b #4, d0                   * Pixel ind Bit #3-0
 move.b d0, d6                  * nach d6
 and.b #$0f, d6                 * nur akt. Pixel lassen
 beq.s gr3p26p7                 * Schwarz
 move.b d6, (a2)                * Farbe in colport
 bset.b #1, (a3)                * Schreibstift
 bra.s gr3p26p8
gr3p26p7:
 bclr.b #1, (a3)                * Löschstift
gr3p26p8:
 move.b #$80, (a6)              * Punkt setzen
 addq #1, d1
 dbra d7, gr3p26p5              * nächster Punkt
gr3p26p9:
 dbra d5, gr3p26p3              * nächstes Byte
 addq #1, d2                    * nächste Zeile
 move (a7)+, d1                 * X-Koordinate zurück
 dbra d4, gr3p26p2
gr3p26x:
 move (a7)+, d0
 move.b d0, gdpxor(a5)
 bsr gr1page                    * Seite und XOR-Modus setzen
 movem.l (a7)+, d0-d6/a0-a6
 bra carres                     * OK, alles klar

gr3sb:                          * Hintergrund speichern
 movem.l d0-d6/a0/a3, -(a7)
 lea page.w, a3                 * Seiten Register
 move.b #2, (a0)+               * Spriteart = GDP-COL
 move.b gdpwpage(a5), (a0)+     * Schreibseite
 move d1, (a0)+                 * X-Koordinate
 move d2, (a0)+                 * Y-Koordinate
 move.b d3, (a0)+               * X-Scalierung
 move.b d4, (a0)+               * Y-Scalierung
 addq #8, a0                    * Offset für Bilddaten
 moveq #8, d5                   * 8 Zeilen
 lsl d4, d5                     * * Y-Scalierung
 subq #1, d5                    * -1 als Zähler
gr3sba:
 tst d2                         * Y >=0 ?
 bpl.s gr3sbb                   * ja, dann Ausgabe
 moveq #10, d0                  * 10 Byte/Zeile
 lsl d3, d0                     * *X-Scalierung
 adda.l d0, a0
 addq #1, d2                    * nächste Zeile
 dbra d5, gr3sba
 bra.s gr3sbx                   * Ende
gr3sbb:
 cmp #256, d2                   * oberer Rand überschritten?
 bge gr3sbx                     * dann Ende
 move.b d2, gdp+$b*cpu.w        * Y-Koordinate setzen
 and #$fffe, d1                 * X auf gerade Adresse bringen
 move d1, -(a7)                 * X-Koordinate sichern
 moveq #1, d6
 asl d3, d6                     * 1*X-Scalierung
 subq #1, d6                    * -1 als Zähler
gr3sbc:
 moveq #9-1, d4                 * max. 2*9 Punkte
gr3sbd:
 movep.w d1, 0(a4)              * X-Koordinate setzen --- Nur für 68000
 move.b #$f, (a6)               * Befehl für Speicher auslesen
gr3sbe:
 btst.b #2, (a6)                * WAIT
 beq.s gr3sbe
 move.b (a3), d0                * 2 Pixel holen
 not.b d0                       * inventiert im Grafikspeicher
 move.b d0, (a0)+               * und speichern
 addq #2, d1                    * nächsten Pixel
 dbra d4, gr3sbd
 addq #1, a0                    * auf 10 Byte
 dbra d6, gr3sbc                * bei Scalierung
 move (a7)+, d1                 * X-Koordinate zurück
 addq #1, d2                    * nächste Zeile
 dbra d5, gr3sbb
gr3sbx:
 movem.l (a7)+, d0-d6/a0/a3
  rts


gr3p27:                         * Sprite löschen GDP-COL
 movem.l d0-d6/a0-a4, -(a7)     * a0 zeigt auf Speicher
 move.b (a0)+, d0               * Spriteart
 cmp.b #2, d0                   * GDP-COL-Sprite 88 bis 5128 Byte groß
 bne gr3p27f                    * sonst Fehler
 move.b gdpwpage(a5), d0        * Schreibseite
 lsl #8, d0
 move.b gdpxor(a5), d0          * XOR-Mode
 move d0, -(a7)                 * auf Stack retten
 move.b (a0)+, gdpwpage(a5)     * alte Schreibseite
 clr.b gdpxor(a5)               * kein XOR
 bsr gr1page                    * Seite und XOR-Modus setzen
 moveq #2, d6                   * WAIT-Bit der GDP-Karte
 moveq #$80, d7                 * Befehl für Punkt setzen
 lea gdp.w, a6                  * GDP-Basis für WAIT
 lea gdp+1*cpu.w, a3            * GDP-CTRL1
 lea gdp+8*cpu.w, a1            * X-Register GDP
 lea gdp+$b*cpu.w, a4           * Y-Register LSB
 lea colport.w, a2              * Vordergrundfarbe
 clr.b colport1.w               * Hintergrundfarbe auf 0
 move (a0)+, d1                 * X-Koordinate
 move (a0)+, d2                 * Y-Koordinate
 move.b (a0)+, d3               * X-Scalierung
 move.b (a0)+, d4               * Y-Scalierung
 addq #8, a0                    * +8 um auf Bilddaten zu kommen
 moveq #8, d5                   * 8 Zeilen
 lsl d4, d5                     * Zeilen*Y-Scalierung
 subq #1, d5                    * -1 als Zähler
 btst #0, d1                    * X gerade oder ungerade
 bne.s gr3p27c                  * ungerade
gr3p27a:                        * Gerade Adresse
 moveq #1, d4                   * Zähler für X-Scalierung
 lsl d3, d4                     * *X-Scalierung
 subq #1 ,d4                    * -1 als Zähler
gr3p27a1:
 tst d2                         * Y >=0 ?
 bpl.s gr3p27b                  * ja, dann Ausgabe
 moveq #10, d0                  * 10 Byte/Zeile
 lsl d3, d0                     * *X-Scalierung
 adda.l d0, a0
 addq #1, d2                    * nächste Zeile
 dbra d5, gr3p27a1
 bra gr3p27e                    * hier Ende
gr3p27b:
 cmp #256, d2                   * oberer Rand überschritten?
 bge gr3p27e                    * dann Ende
 move.b d2, (a4)                * Y-Koordinaten setzen
 move d4, -(a7)                 * X-Scale-Zähler retten
 move d1, -(a7)                 * X-Koordinate retten
gr3p27b1:
 move d4, -(a7)                 * X-Scal-Zähler retten
 move.l (a0)+, d0
 bsr gr3ap8                     * 8 Pixel schreiben
 move.l (a0)+, d0
 bsr gr3ap8                     * 8 Pixel schreiben
 move (a7)+, d4                 * X-Scale-Zähler zurück
 addq #2, a0                    * auf 10 Byte bringen
 dbra d4, gr3p27b1              * X-Scale-Loop
 move (a7)+, d1                 * X-Koordinate zurück
 move (a7)+, d4                 * X-Scale-Zähler zurück
 addq #1, d2                    * Y-Koordinate erhöhen
 dbra d5, gr3p27b
 bra.s gr3p27e
gr3p27c:                        * Ungerade Adresse
 moveq #1, d4                   * Zähler für X-Scalierung
 lsl d3, d4                     * *X-Scalierung
 subq #1 ,d4                    * -1 als Zähler
gr3p27c1:
 tst d2                         * Y >=0 ?
 bpl.s gr3p27d                  * ja, dann Ausgabe
 moveq #10, d0                  * 10 Byte/Zeile
 lsl d3, d0                     * *X-Scalierung
 adda.l d0, a0
 addq #1, d2                    * nächste Zeile
 dbra d5, gr3p27c1
 bra.s gr3p27e                  * hier Ende
gr3p27d:
 cmp #256, d2                   * oberer Rand überschritten?
 bge.s gr3p27e                  * dann Ende
 move.b d2, (a4)                * Y-Koordinaten setzen
 move d4, -(a7)                 * X-Scal-Zähler retten
 move d1, -(a7)                 * X-Koordinate retten
gr3p27d1:
 move d4, -(a7)                 * X-Scal-Zähler retten
 move.l (a0)+, d0               * 8 Pixel holen
 lsl.l #4, d0                   * ein Pixel raus
 move.b (a0), d4                * noch 2 Pixel
 lsr.b #4, d4                   * nur das Oberste
 and.b #$0f, d4
 or.b d4, d0                    * dazu
 bsr gr3ap8                     * 8 Pixel schreiben
 move.l (a0)+, d0               * 8 Pixel holen
 lsl.l #4, d0                   * ein Pixel raus
 move.b (a0), d4                * noch 2 Pixel
 lsr.b #4, d4                   * nur das Oberste
 and.b #$0f, d4
 or.b d4, d0                    * dazu
 bsr gr3ap8                     * 8 Pixel schreiben
 move (a7)+, d4                 * X-Scal-Zähler zurück
 addq #2, a0                    * auf 10 Byte bringen
 dbra d4, gr3p27d1              * X-Scal-Loop
 move (a7)+, d1                 * X-Koordinate zurück
 move (a7)+, d4                 * X-Scal-Zähler zurück
 addq #1, d2                    * Y-Koordinate erhöhen
 dbra d5, gr3p27d
gr3p27e:
 move (a7)+, d0
 move.b d0, gdpxor(a5)
 lsr #8, d0
 move.b d0, gdpwpage(a5)
 bsr gr1page                    * Seite und XOR-Modus setzen
 bset.b #1, (a3)                * Schreibstift muss gesetzt werden!
 movem.l (a7)+, d0-d6/a0-a4
 bra carres
gr3p27f:
 movem.l (a7)+, d0-d6/a0-a4
 bra carset

gr3ap8:
 moveq #8-1, d3                 * 8 Pixel
gr3ap8a:
 move d1, d4                    * X-Koordinate
 bpl.s gr3ap8b                  *
 rol.l #4, d0
 addq #1, d1
 dbra d3, gr3ap8a               * bis X-Koordinate >=0
 bra.s gr3ap8f                  * sonst Ende
gr3ap8b:
 cmp #512, d1                   * über rechten Rand?
 bge.s gr3ap8f                  * ja, dann Ende
 movep.w d1, 0(a1)              * Neue X-Koordinate -- Nur für 68000
 rol.l #4, d0                   * ein Pixel in Bit #3-0
 move.b d0, d4
 and.b #$0f, d4                 * Pixel in Bit #3-0
 beq.s gr3ap8d                  * Schwarz
gr3ap8c:
 btst.b d6, (a6)                * Warten
 beq.s gr3ap8c
 bset.b #1, (a3)                * Schreibstift
 move.b d4, (a2)                * Farbe setzen
 bra.s gr3ap8e
gr3ap8d:
 btst.b d6, (a6)                * Warten
 beq.s gr3ap8d
 bclr.b #1, (a3)                * Löschstift
gr3ap8e:
 move.b d7, (a6)                * Punkt setzen
 addq #1, d1
 dbra d3, gr3ap8b               * nächster Punkt
gr3ap8f:
  rts

gr3p32:                         * Bereich speichern
 movem.l d0-d6/a0/a2-a4/a6, -(a7)
 lea page.w, a3                 * Seiten Register
 lea gdp.w, a6                  * GDP-Basis für WAIT
 lea gdp+8*cpu.w, a2            * X-Register GDP
 lea gdp+$b*cpu.w, a4           * Y-Register LSB
 move.l #$1FF, d0               * max. 511
 and.l d0, d1                   * X=0..511
 and.l d0, d2                   * Y=0..511
 subq #1, d3                    * auf 1..511 als Breitenzähler
 and.l d0, d3
 subq.l #1, d4                  * auf 1..511
 and.l d0, d4
 asr #1, d2                     * Y auf 0..255
 asr #1, d4                     * Höhe auf 0..255
 btst #0, d1                    * gerade Adresse?
 bne.s gr3p32d                  * nein!
gr3p32a:                        * gerade Adresse
 move.b d2, (a4)                * Y-Koordinate setzen
 movem d1/d3, -(a7)             * X-Koordinate u. Breitenzähler sichern
gr3p32b:
 movep.w d1, 0(a2)              * X-Koordinate setzen --- Nur für 68000
 move.b #$f, (a6)               * Befehl für Speicher auslesen
gr3p32c:
 btst.b #2, (a6)                * WAIT
 beq.s gr3p32c
 move.b (a3), d0                * 2 Pixel holen
 not.b d0                       * invertieren
 move.b d0, (a0)+               * speichern
 addq #2, d1                    * nächsten Pixel
 subq #2, d3
 bpl.s gr3p32b
 movem (a7)+, d1/d3             * X-Koordinate u.Breitenzähler zurück
 addq #1, d2                    * nächste Zeile
 dbra d4, gr3p32a
 bra.b gr3p32x
gr3p32d:                        * ungerade Adresse
 and #$fffe, d1                 * auf gerade Adresse
gr3p32e:
 move.b d2, (a4)                * Y-Koordinate setzen
 movem d1/d3, -(a7)             * X-Koordinate u. Breitenzähler sichern
 movep.w d1, 0(a2)              * X-Koordinate setzen --- Nur für 68000
 move.b #$f, (a6)               * Befehl für Speicher auslesen
gr3p32f:
 btst.b #2, (a6)                * WAIT
 beq.s gr3p32f
 move.b (a3), d0                * 1. Pixel holen
 not.b d0                       * invertieren
 rol.b #4, d0                   * Reihenfolge vertauschen
 move.b d0, d6
 and.b #$f0, d6                 * nur oberes Nibble lassen
 addq #2, d1
gr3p32g:
 movep.w d1, 0(a2)              * X-Koordinate setzen --- Nur für 68000
 move.b #$f, (a6)               * Befehl für Speicher auslesen
gr3p32h:
 btst.b #2, (a6)                * WAIT
 beq.s gr3p32h
 move.b (a3), d0                * Pixel holen
 not.b d0                       * invertieren
 rol.b #4, d0                   * Reihenfolge vertauschen
 move.b d0, d5
 and.b #$f, d5                  * nur unteres Nibble lassen
 or.b d5, d6                    * Pixel vereinigt ;-)
 move.b d6, (a0)+               * speichern
 and.b #$f0, d0                 * oberes Nibble behalten
 move.b d0, d6
 addq #2, d1                    * nächsten Pixel
 subq #2, d3
 bpl.s gr3p32g
 movem (a7)+, d1/d3             * X-Koordinate u.Breitenzähler zurück
 addq #1, d2                    * nächste Zeile
 dbra d4, gr3p32e
gr3p32x:
 movem.l (a7)+, d0-d6/a0/a2-a4/a6
  rts

gr3p33:                         * Bereich schreiben
 cmp.b #-1, d5                  * Transparenz-Farbe gesetzt?
 bne gr3up33                  * ja
 movem.l d0-d7/a0-a4/a6, -(a7)
 lea gdp.w, a6                  * GDP-Basis für WAIT
 lea colport.w, a1              * Vordergrund-Farbe
 lea gdp+8*cpu.w, a2            * X-Register GDP
 lea gdp+1*cpu.w, a3            * GDP-CTRL1
 lea gdp+$b*cpu.w, a4           * Y-Register LSB
 clr.b colport1.w               * Hintergrund-Farbe auf 0
 move.l #$1FF, d0               * max. 511
 and.l d0, d1
 and.l d0, d2
 subq.l #1, d3                  * auf 1..511
 and.l d0, d3
 subq.l #1, d4                  * auf 1..511
 and.l d0, d4
 asr #1, d2                     * Y auf 0..255
 asr #1, d4                     * Höhe auf 0..255
 moveq #2, d6                   * Bit fürs Warten
gr3p33a:
 move.b d2, (a4)                * Y-Koordinate ausgeben
 movem d1/d3, -(a7)             * X-Koordinate u. Breitenzähler retten
gr3p33b:
 moveq #2-1, d5                 * Pixel in Byte
 move.b (a0)+, d0               * 2 Pixel
gr3p33c:
 movep.w d1, 0(a2)              * Neue X-Koordinate -- Nur für 68000
 rol.b #4, d0                   * Pixel in Bit #0-3
 move.b d0, d7
 and.b #$f, d7                  * nur ein Pixel lassen
 beq.s gr3p33e                  * Schwarz
gr3p33d:
 btst.b d6, (a6)                * Warten
 beq.s gr3p33d
 move.b d7, (a1)                * Pixel an Colport
 bset.b #1, (a3)                * Schreibstift
 bra.s gr3p33f
gr3p33e:
 btst.b d6, (a6)                * Warten
 beq.s gr3p33e
 bclr.b #1, (a3)                * Löschstift
gr3p33f:
 move.b #$80, (a6)              * Punkt setzen
 addq #1, d1
 subq #1, d3
 bmi.s gr3p33g                  * Zeile fertig
 dbra d5, gr3p33c               * nächster Punkt
 bra.s gr3p33b
gr3p33g:
 movem (a7)+, d1/d3             * X-Koordinate u. Breitenzähler zurück
 addq #1, d2                    * nächstes Y
 dbra d4, gr3p33a
 bset.b #1, (a3)                * wieder auf Schreibstift!!!
 movem.l (a7)+, d0-d7/a0-a4/a6
  rts

gr3up33:                        * Bereich schreiben mit Transparenz
 movem.l d0-d7/a0-a4/a6, -(a7)
 lea gdp.w, a6                  * GDP-Basis für WAIT
 lea colport.w, a1              * Vordergrund-Farbe
 lea gdp+8*cpu.w, a2            * X-Register GDP
 lea gdp+1*cpu.w, a3            * GDP-CTRL1
 lea gdp+$b*cpu.w, a4           * Y-Register LSB
 clr.b colport1.w               * Hintergrund-Farbe auf 0
 move.l #$1FF, d0               * max. 511
 and.l d0, d1
 and.l d0, d2
 subq.l #1, d3                  * auf 1..511
 and.l d0, d3
 subq.l #1, d4                  * auf 1..511
 and.l d0, d4
 asr #1, d2                     * Y auf 0..255
 asr #1, d4                     * Höhe auf 0..255
 and.b #$f, d5                  * Transparentfarbe auf Pixelgröße
 moveq #2, d6                   * Bit fürs Warten
gr3up33a:
 move.b d2, (a4)                * Y-Koordinate ausgeben
 movem d1/d3/d4, -(a7)          * X-Koor., Breiten- u. Höhenzähler retten
gr3up33b:
 moveq #2-1, d4                 * Pixel in Byte
 move.b (a0)+, d0               * 2 Pixel
gr3up33c:
 movep.w d1, 0(a2)              * Neue X-Koordinate -- Nur für 68000
 rol.b #4, d0                   * Pixel in Bit #0-3
 move.b d0, d7
 and.b #$f, d7                  * nur ein Pixel lassen
 cmp.b d5, d7                   * Transparentfarbe?
 beq.s gr3up33g                 * ja, Pixel überspringen 
 tst.b d7                       * Hintergrundfarbe
 beq.s gr3up33e                 * ja
gr3up33d:
 btst.b d6, (a6)                * Warten
 beq.s gr3up33d
 move.b d7, (a1)                * Pixel an Colport
 bset.b #1, (a3)                * Schreibstift
 bra.s gr3up33f
gr3up33e:
 btst.b d6, (a6)                * Warten
 beq.s gr3up33e
 bclr.b #1, (a3)                * Löschstift
gr3up33f:
 move.b #$80, (a6)              * Punkt setzen
gr3up33g:
 addq #1, d1
 subq #1, d3
 bmi.s gr3up33h                 * Zeile fertig
 dbra d4, gr3up33c              * nächster Punkt
 bra.s gr3up33b
gr3up33h:
 movem (a7)+, d1/d3/d4          * X-Koor., Breiten- u. Höhenzähler zurück
 addq #1, d2                    * nächstes Y
 dbra d4, gr3up33a
 bset.b #1, (a3)                * wieder auf Schreibstift!!!
 movem.l (a7)+, d0-d7/a0-a4/a6
  rts

g3moveto:                       * MOVETO für GDP-COL-Paket
 asr #1,d2
move3to:                        * Schreibstift der GDP positionieren
 btst.b #2,gdp.w                * d1 = X  d2 = Y
 beq.s move3to                  * Ohne Sprung zu wait schneller
 move.l a0,-(a7)                * ==> Nur für 68000/68010
 lea gdp.w,a0
 movep.w d1,8*cpu(a0)           * X Register gesetzt
 movep.w d2,$a*cpu(a0)          * Y Register gesetzt
 movea.l (a7)+,a0
  rts

wait3:                          * Warten bis GDP fertig
 btst.b #2,gdp.w                * Bit 2 prüfen
 beq.s wait3                    * Warten bis auf 1
  rts

ende:                           * Endemarkierung für Längenberechnung

; DCB.b 1024*64-*,$ff              * Rest der 64 Kbyte mit $FF füllen

 END














*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
