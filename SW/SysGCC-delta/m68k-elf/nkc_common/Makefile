# Host generic commands
RM=rm -f
MV=mv -f
INSTALL=cp

# source files.
#crt0.c
SRC =  	newlib_stubs.c \
        system/open.c \
        system/close.c \
        system/creat.c \
        system/dup.c \
        system/ioctl.c \
        system/isatty.c \
        system/lseek.c \
        system/read.c \
        system/stat.c \
        system/write.c

OBJ = $(SRC:.c=.o)

TARGET = libnkc.a

# include directories
INCLUDES = -I. -I../include/ #-I/usr/local/include

# C compiler flags
CFLAGS=-g -Os -m68000 -Wall -fomit-frame-pointer -nostartfiles -std=gnu99 -Dndrcomp -DUSE_JADOS #-ffunction-sections -fdata-sections

# 68k compiler and tools
DEVC_PREFIX=m68k-elf-
CC=$(DEVC_PREFIX)gcc.exe
CPP=$(DEVC_PREFIX)g++.exe
AS=$(DEVC_PREFIX)as.exe
AR=$(DEVC_PREFIX)ar.exe
RAN=$(DEVC_PREFIX)ranlib.exe
SIZE=$(DEVC_PREFIX)size.exe
OBJCOPY=$(DEVC_PREFIX)objcopy.exe
OBJDUMP=$(DEVC_PREFIX)objdump.exe
# library paths
#LIBS = -L../ -L/usr/local/lib -lm

# Linker Flags
LDFLAGS= -g

.SUFFIXES: .c

all: $(TARGET)

%.o : %.c
	$(CC) $(INCLUDES) $(CFLAGS) -c $< -o $@

$(TARGET): $(OBJ)
	$(AR) rv $@ $?
	$(RAN) $@

.PHONY : install 
install : $(TARGET)
	$(INSTALL) $(TARGET) ../m68k-elf/lib/m68000/
 
clean:
	$(RM) $(OBJ) $(OUT) *.bak