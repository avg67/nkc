# NKC System on Chip für Tang-Nano

## FPGA-Files:
- NKC_68k_PS2_KEYB_PCB.fs
   - NKC SOC mit 10MHz 68000 (16 bit) CPU, GDP64HS, Timer, PS/2-Keyboard und Maus, Sound, SPI (SD-Card), Ser, I2C, Reset-Info
     sowie externen I/O-BUS (3 WS) für PCB von UWE
- NKC_Z80_PS2_KEYB_PCB.fs
   - NKC SOC mit 8MHz Z80 CPU, GDP64HS, Timer, PS/2-Keyboard, I2C, Sound, SDIO SD-Card Interface, Ser
     FLOMON20170501, ZEAT Roms sowie externen I/O-BUS für PCB von UWE
- NKC_Z80_PS2_KEYB_ADD_ROMS_PCB.fs
   - NKC SOC mit 8MHz Z80 CPU, GDP64HS, Timer, PS/2-Keyboard und Maus, Sound, SDIO SD-Card Interface, Ser
     FLOMON20170501, ZEAT, GP, GOSI, BASIC, EZASS Roms sowie externen I/O-BUS für PCB von UWE
- GDP64HS_FPGA_PCB.fs
   - Bus-Slave mit GDP64HS, Timer, PS/2-Keyboard und Maus, Sound, SPI (SD-Card), Ser
     für PCB von UWE
- GDP64HS_FPGA_NUR_GDP_PCB.fs
   - Bus-Slave nur mit GDP64HS
     für PCB von UWE
-  NKC_68k_FAST_PS2_KEYB_PCB.fs
   - NKC SOC mit 40MHz 68000 (16 bit) CPU, GDP64HS, Timer, PS/2-Keyboard und Maus, Sound, SPI (SD-Card), Ser
     sowie externen I/O-BUS (3 WS) für PCB von UWE
- NKC_68020_PS2_KEYB_PCB.fs
   - NKC SOC mit 40MHz 68020 (32 bit) CPU, GDP64HS, Timer, PS/2-Keyboard und Maus, Sound, SPI (SD-Card), Ser
     sowie externen I/O-BUS (3 WS) für PCB von UWE
     Achtung: Vorab-Test-Version, Instruction-set des 68020 nicht zu 100% implementiert (CALLM, RETM fehlen)
- NKC_68020_I2C_PS2_KEYB_PCB.fs
   - NKC SOC mit 40MHz 68020 (32 bit) CPU, GDP64HS, Timer, PS/2-Keyboard und Maus, Sound, SPI (SD-Card), Ser, Reset-Info
     sowie externen I/O-BUS (3 WS) für PCB von UWE
     Weiters ist ein I2C-Master am PS2 Port der Maus angeschlossen. Diese wird ausgeschaltet wenn das I2C interface eingeschaltet wird.
     
     Dokumentation des I2C siehe https://github.com/avg67/nkc/blob/main/tang_nano_20k/doc/i2c.pdf
- NKC_68020_I2C_EDID_PS2_KEYB_PCB.fs
   - Wie NKC_68020_I2C_PS2_KEYB_PCB.fs aber mit dem Unterschied dass beim I2C-Interface (Mouse PS/2-Port) die SDA/SCL-Pins vertauscht sind.
     Dadurch kann das HDMI-EDID (Electronic Display Information Data) abgefragt werden (https://ez.analog.com/video/w/documents/18368/edid-extended-display-identification-data).
     Aus dem EDID-Interface (welches eigentlich ein I2C-Interface ist) kann man herauslesen welcher Bildschirm mit welchen Auflösungen und Wiederholfrequenzen etc. angeschlossen ist.
     Das ist eigentlich der Weg mit dem jeder PC den angeschlossenen Bildschirm identifiziert und sich darauf einstellt.
Auf I/O-Addresse 0xFF (0xFFFFFFFF*2 beim 68k) gibt es nun das Reset-Info Register.
- Bit 0=1: Letzter Reset war ein Power-On Reset. Dieses Bit kann durch schreiben von 0x01 auf dieses Register gelöscht werden.

*****************************
## CPU-Zugriff auf GDP-Video-RAM:

Beim NKC-SOC (mit integrierter CPU) ist der volle GDP-Videoram in den CPU-Adressraum gemappt.
1MB RAM, GP7.10R6 intern @ 0x1D0000, 64kB GP-Ram @ 0x1E0000, Video-RAM in CPU-Adressraum @ 0x800000 (256kB per page)

- PAGE0: 0x800000 -  0x83FFFF

- PAGE2: 0x840000 -  0x87FFFF

- PAGE3: 0x880000 -  0x8BFFFF

- PAGE4: 0x8C0000 -  0x8FFFFF

Jede Page 512x512 - 8bit/Pixel
