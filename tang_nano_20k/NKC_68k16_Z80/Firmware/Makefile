ARCH=68000

#VASM=vasmm68k_mot
TOOLS=/c/working/_nkc_git_avg/nkc_hpe_mini_lec/nkc/tools
VASM=$(TOOLS)/vasmm68k

SRECCAT=$(TOOLS)/srec_cat
HEX2MIF=$(TOOLS)/hex2mif #.py


C_OBJ=$(patsubst %.c,%.o,$(SDBOOTSTRAP_CSRC))
A_OBJ=$(patsubst %.s,%.o,$(SDBOOTSTRAP_ASRC))
SDBOOTSTRAPOBJ=$(A_OBJ)
SDBOOTSTRAP=sdbootstrap.elf
SDBOOTSTRAPVHD=test_ROM.vhd

#ROMGENDIR = ../../romgen
#ROMGENDIR = ../romgen
ROMGENDIR = /c/working/_Tang_nano/gdp_fpga/romgen
ROMGEN = $(ROMGENDIR)/romgen

CFLAGS=-m$(ARCH) -O6

all:  $(SDBOOTSTRAPVHD) test.v
#all:  sdbootstrap.mif

clean:
	rm -f $(SDBOOTSTRAPVHD) *.bin

test_ROM.vhd: test.bin $(ROMGEN)
	sed 's/soc_firmware/test_ROM/' >test_ROM.vhd <$(ROMGENDIR)/rom_prologue.vhd
	$(ROMGEN) test.bin >>test_ROM.vhd
	cat >>test_ROM.vhd $(ROMGENDIR)/rom_epilogue.vhd

test.bin: test.S68
	#../tools/srec_cat test.S68 -Output test.bin -Binary
	$(SRECCAT) $< -Output $@ -Binary

test.v: test.bin
	python $(TOOLS)/hex2mem/hex2mem.py test.bin test.v
#test.mem: test.S68
#	$(SRECCAT) $< -Output $@ −Lattice_Memory_Initialization_Format 16

#test.S68: test.X68
#	$(VASM) -m68000 -Felf -o $@ $<

