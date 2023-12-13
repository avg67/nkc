# Makefile -- DHRYSTONE program
# Copyright 2000, 2002, 2003 Free Software Foundation, Inc.
# Written by Stephane Carrez (stcarrez@nerim.fr)
#
# This file is part of GEL.
#
# GEL is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# GEL is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with GEL; see the file COPYING.  If not, write to
# the Free Software Foundation, 59 Temple Place - Suite 330,
# Boston, MA 02111-1307, USA.
#
# Host generic commands
RM=rm -f
MV=mv -f
INSTALL=cp

# 68k compiler and tools
DEVC_PREFIX=m68k-elf-
CC=$(DEVC_PREFIX)gcc.exe
CPP=$(DEVC_PREFIX)g++.exe
AS=$(DEVC_PREFIX)as.exe
SIZE=$(DEVC_PREFIX)size.exe
OBJCOPY=$(DEVC_PREFIX)objcopy.exe
OBJDUMP=$(DEVC_PREFIX)objdump.exe

TARGET := mine
#countbsp
gccdir = /c/SysGCC/m68k-elf
ISEARCH = #-I.

#LIBDIRS =  -L $(gccdir)/m68k-elf/lib/m68000
COMMON_DIR = $(gccdir)/nkc_common/
LIBS =

# Compile with debugging info (-g), with size optimization (-Os)
# and 16-bit integers (-mshort)
COMMON_FLAGS=-g -Os -m68000 -Wall -fomit-frame-pointer  -fno-stack-protector -Dndrcomp  -DUSE_JADOS -DUSE_SURROUND $(ISEARCH) #-ffunction-sections -fdata-sections # -nostartfiles
CFLAGS=$(COMMON_FLAGS) -std=gnu99
CPPFLAGS=$(COMMON_FLAGS) -std=gnu++11 -fno-exceptions #-fexceptions
ASFLAGS= #-DM68000

# Linker Flags
LDFLAGS= -T $(COMMON_DIR)rm_ram1.ld -Wl,-Map,$(OUTDIR)$(TARGET).map,--gc-sections,-flto -lm $(LIBDIRS) $(LIBS) -lgcc -lstdc++ -fno-exceptions



# Flags for objcopy tool
OBJCOPY_FLAGS=--only-section=.text \
              --only-section=.rodata \
              --only-section=.vectors \
              --only-section=.data

# List of C sources
CSRCS=  gp_helper.c
# List of CPP sources
CPPSRCS= mine.cpp \
		field.cpp \
		board.cpp \
		highscore.cpp

ASM_SRCS=
# Directory where the files are generated to (objects, list files, ...)
OUTDIR=./_out/
OBJPATH = ./obj

# List of objects
OBJS           = $(addprefix $(OBJPATH)/, $(addsuffix .o, $(notdir $(basename $(CSRCS)))))
OBJS          += $(addprefix $(OBJPATH)/, $(addsuffix .o, $(notdir $(basename $(CPPSRCS)))))
OBJS          += $(addprefix $(OBJPATH)/, $(addsuffix .o, $(notdir $(basename $(ASM_SRCS)))))

PROGS=$(OUTDIR)$(TARGET).elf
LIST=$(PROGS:.elf=.lst)

all:: createdirs $(PROGS) create_bin print_codesize

clean_all: clean all

createdirs:
	-@mkdir $(OUTDIR) 2>/dev/null || echo "" >/dev/null
	-@mkdir $(OBJPATH) 2>/dev/null || echo "" >/dev/null
$(PROGS):	$(OBJS)
	$(CC) $(CFLAGS) -c -o $(OBJPATH)/crt0.o $(COMMON_DIR)crt0.c
# Link
	$(CPP) $(CPPFLAGS) $(LDFLAGS) -o $@ $(OBJS)
#	$(MV) *.o $(OUTDIR)
#	$(RM) $(LIST)
	$(OBJDUMP) -S $(PROGS) > $(LIST)

$(TARGET).s19:    $(PROGS)
	$(OBJCOPY) $(OBJCOPY_FLAGS) --output-target=srec $< $(OUTDIR)$@

create_bin:   $(TARGET).s19
	$(OBJCOPY) --output-target=binary $(OUTDIR)$(TARGET).elf $(OUTDIR)$(TARGET).68k

# print codesize
print_codesize: $(PROGS)
	$(SIZE) $(OUTDIR)*.elf

define COMPILE_C_TEMPLATE
$(OBJPATH)/$(notdir $(basename $(1))).o : $(1)
	$(CC) -c $$(CFLAGS) $$< -o $$@
endef
$(foreach src, $(filter %.c, $(CSRCS)), $(eval $(call COMPILE_C_TEMPLATE, $(src))))
define COMPILE_CC_TEMPLATE
$(OBJPATH)/$(notdir $(basename $(1))).o : $(1)
	$(CPP) -c $$(CPPFLAGS) $$< -o $$@
endef
$(foreach src, $(filter %.cpp, $(CPPSRCS)), $(eval $(call COMPILE_CC_TEMPLATE, $(src))))

define COMPILE_ASM_TEMPLATE
$(OBJPATH)/$(notdir $(basename $(1))).o : $(1)
	$(AS) $$(ASFLAGS) $$< -o $$@
endef
$(foreach src, $(filter %.s, $(ASM_SRCS)), $(eval $(call COMPILE_ASM_TEMPLATE, $(src))))
clean:
	echo $(OBJS)
	$(RM) $(OBJS) $(OUTDIR)*.68k $(OUTDIR)*.lst $(OUTDIR)*.elf $(OUTDIR)*.s19
#	$(RM) $(OBJS) $(AOBJ) *.hex *.srec *.bin *.elf *.map *~ *.lst
	$(RM) $(OBJS) $(OBJPATH)/*.o $(OUTDIR)/*.map



