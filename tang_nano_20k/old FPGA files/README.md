# NKC System on Chip für Tang-Nano

## Archived (old) FPGA-Files:
- GDP64HS_FPGA.fs
   - Bus-Slave mit GDP64HS, Timer, PS/2-Keyboard und Maus, Sound, SPI (SD-Card), Ser
- GDP_and_TIMER.fs
   - Bus-Slave mit GDP64HS, Timer
- GDP_TIMER_SPI.fs
   - Bus-Slave mit GDP64HS, Timer, SPI (SD-Card)
- NKC_PS2_KEYB.fs
   - NKC SOC mit 10MHz 68000 (16 bit) CPU, GDP64HS, Timer, PS/2-Keyboard und Maus, Sound, SPI (SD-Card), Ser
     KEIN externer Bus!
- NKC_PS2_KEYB_Bus.fs
   - NKC SOC mit 10MHz 68000 (16 bit) CPU, GDP64HS, Timer, PS/2-Keyboard und Maus, Sound, SPI (SD-Card), Ser
     sowie externen I/O-BUS (3 WS)
- NKC_PS2_KEYB_Bus_2nd_SD_GP_Patched.fs
   - NKC SOC mit 10MHz 68000 (16 bit) CPU, GDP64HS, Timer, PS/2-Keyboard und Maus, Sound, SPI (SD-Card), Ser
     sowie externen I/O-BUS (3 WS) und gepatchtem GP710r6 für bessere SD-Karten Kompatibilität
- NKC_ser_key.fs
   - NKC SOC mit 10MHz 68000 (16 bit) CPU, GDP64HS, Timer, PS/2-Maus, Sound, SPI (SD-Card)
     Key via (virt.) RS232 über Tang-Nano mit 9600 Baud
     sowie externen I/O-BUS (3 WS) und gepatchtem GP710r6 für bessere SD-Karten Kompatibilität
- only_timer.fs
   - Nur Timer
- NKC_Z80.fs
   - Z80 System mit 8MHz Z80 CPU, 1MB RAM, GDP64HS, Timer, PS/2-Keyboard und PS/2-Maus, Sound, SDIO SD-Card Interface,
     sowie externen I/O-Bus
- NKC_Z80_ser_key_ext_bus.fs
   - Z80 System mit 8MHz Z80 CPU, 1MB RAM, GDP64HS, Timer, Sound, SDIO SD-Card Interface,
     Key via (virt.) RS232 über Tang-Nano mit 9600 Baud
     sowie externen I/O-Bus

