# NKC System on Chip für Tang-Nano

## FPGA-Files:
- NKC_68k_PS2_KEYB_PCB.fs
   - NKC SOC mit 10MHz 68000 (16 bit) CPU, GDP64HS, Timer, PS/2-Keyboard und Maus, Sound, SPI (SD-Card), Ser
     sowie externen I/O-BUS (3 WS) für PCB von UWE
- NKC_Z80_PS2_KEYB_PCB.fs
   - NKC SOC mit 8MHz Z80 CPU, GDP64HS, Timer, PS/2-Keyboard und Maus, Sound, SDIO SD-Card Interface, Ser
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
   - NKC preliminary SOC mit 40MHz 68000 (16 bit) CPU, GDP64HS, Timer, PS/2-Keyboard und Maus, Sound, SPI (SD-Card), Ser
     sowie externen I/O-BUS (3 WS) für PCB von UWE
     Achtung: Ext. Bus noch nicht 100% stabil (FLO2 läuft bei mir damit nicht stabil, alles andere schon)!

*****************************
## CPU-Zugriff auf GDP-Video-RAM:

Beim NKC-SOC (mit integrierter CPU) ist der volle GDP-Videoram in den CPU-Adressraum gemappt.
1MB RAM, GP7.10R6 intern @ 0x1D0000, 64kB GP-Ram @ 0x1E0000, Video-RAM in CPU-Adressraum @ 0x800000 (256kB per page)

- PAGE0: 0x800000 -  0x83FFFF

- PAGE2: 0x840000 -  0x87FFFF

- PAGE3: 0x880000 -  0x8BFFFF

- PAGE4: 0x8C0000 -  0x8FFFFF

Jede Page 512x512 - 8bit/Pixel
