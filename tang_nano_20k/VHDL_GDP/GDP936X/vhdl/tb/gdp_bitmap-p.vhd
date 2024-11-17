--------------------------------------------------------------------------------
-- Project     : Single Chip NDR Computer
-- Module      : GDP 936X Display processor - Bitmap Package
-- File        : gdp_bitmap-p.vhd
-- Description :
--------------------------------------------------------------------------------
-- Author       : Andreas Voggeneder
-- Organisation : FH-Hagenberg
-- Department   : Hardware/Software Systems Engineering
-- Language     : VHDL'87
--------------------------------------------------------------------------------
-- Copyright (c) 2007 by Andreas Voggeneder
--------------------------------------------------------------------------------


--------BMP format spec.----------------------------------------------------
-- Windows format is used.
--
-- The image data is bit packed but every line must end on a dword boundary
-- if thats not the case, it must be padded with zeroes. BMP files are stored bottom-up,
-- that means that the first scan line is the bottom line. The BMP format has four
-- incarnations, two under Windows (new and old) and two under OS/2, all are
-- described here.

-- OFFSET              Count TYPE   Description
-- 0000h                   2 char   ID='BM' - BitMap
--                                  OS/2 also supports the following IDs :
--                                  ID='BA' - Bitmap Array
--                                  ID='CI' - Color Icon
--                                  ID='CP' - Color Pointer (mouse cursor)
--                                  ID='IC' - Icon
--                                  ID='PT' - Pointer (mouse cursor)
-- 0002h                   1 dword  Filesize of whole file
-- 0006h                   4 byte   reserved
-- 000Ah                   1 dword  Offset of bitmap in file
--                                  ="BOF"
-- 000Eh                   1 dword  Length of BitMapInfoHeader
--                                  The BitMapInfoHeader starts directly after
--                                  this header.
--                                  12 - OS/2 1.x format
--                                  40 - Windows 3.x format
--                                  64 - OS/2 2.x format
-- 0012h                   1 dword  Horizontal width of bitmap in pixels
-- 0016h                   1 dword  Vertical width of bitmap in pixels
-- 001Ah                   1 word   Number of planes
-- 001Ch                   1 word   Bits per pixel ( thus the number of colors )
--                                  ="BPP"
-- 001Eh                   1 dword  Compression type, see ALGRTHMS.txt for descrip-
--                                  tion of the dccferent types
--                                  0 - none
--                                  1 - RLE 8-bit/Pixel
--                                  2 - RLE 4-bit/Pixel
-- 0022h                   1 dword  Size of picture in bytes
-- 0026h                   1 dword  Horizontal resolution
-- 002Ah                   1 dword  Vertical resolution
-- 002Ah                   1 dword  Number of used colors
-- 002Ah                   1 dword  Number of important colors
-- 0036h                   ? rec    Definition of N colors
--                                  N=1 shl "BPP"
--                         1 byte   Blue component
--                         1 byte   Green component
--                         1 byte   Red component
--                         1 byte   Filler
-- "BOF"                   ? byte   Image data
-- ----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

package gdp_bitmap is

--Destination File for RGB-Display (Framenumber will be added to this Name)
  constant output_file_c : string := "Frame.bmp";
  type color_mode_t is (color_4bit, color_8bit);
  type     video_Ramfile_t is file of character;
--  subtype rgb_color_t is std_ulogic_vector(23 downto 0);
--  subtype blueRange_t is natural range 7 downto 0;
--  subtype greenRange_t is natural range 15 downto 8;
--  subtype redRange_t is natural range 23 downto 16;

--  function  write_hdr(xres : integer; yres : integer) return video_Ramfile_t;
  procedure write_hdr(file bmp_File : video_Ramfile_t; xres : integer; yres : integer; color : boolean);
--  procedure write_YCbCr444(file bmp_File : video_Ramfile_t; Pixel : std_ulogic_vector(31 downto 0));
--  procedure write_YCbCr422(file bmp_File : video_Ramfile_t; Pixel : std_ulogic_vector(31 downto 0));
--  procedure write_RGB555(file bmp_File : video_Ramfile_t; Pixel : std_ulogic_vector(31 downto 0));
--  procedure write_RGB888(file bmp_File : video_Ramfile_t; Pixel : std_ulogic_vector(31 downto 0));
--  procedure WriteEOL(file bmp_File : video_Ramfile_t;xres : integer);
  procedure write_byte(file bmp_File: video_Ramfile_t; byte : std_logic_vector; color : color_mode_t);  
end package gdp_bitmap;



package body gdp_bitmap is

--  function checkLimits (colval : integer) return std_ulogic_vector is
--    variable val : integer := colval;
--  begin
--    if colval < 0 then
--      val := 0;
--    elsif colval > 255 then
--      val := 255;
--    end if;
--    return std_ulogic_vector(conv_signed(val, 8));
--  end;
--
--  function YCbCr2RGB(Y: integer; Cb : integer; Cr : integer) return rgb_color_t is
--    variable rgb   : rgb_color_t;
--    variable r,b,g : integer;
--  begin
--
--    r   := integer(real(Y)*tmx1_c+real(Cr)*tm13_c);
--    g   := integer(real(Y)*tmx1_c+real(Cb)*tm22_c+ real(Cr)*tm23_c);
--    b   := integer(real(Y)*tmx1_c+real(Cb)*tm32_c);
--
--    rgb(redRange_t)   := checkLimits(r);
--    rgb(greenRange_t) := checkLimits(g);
--    rgb(blueRange_t)  := checkLimits(b);
--
--    
----    rgb(redRange_t)   := std_ulogic_vector(conv_signed(integer(real(Y)*tmx1_c+real(Cr)*tm13_c), 8));
----    rgb(greenRange_t) := std_ulogic_vector(conv_signed(integer(real(Y)*tmx1_c+real(Cb)*tm22_c+ real(Cr)*tm23_c), 8));
----    rgb(blueRange_t)  := std_ulogic_vector(conv_signed(integer(real(Y)*tmx1_c+real(Cb)*tm32_c), 8));
--
----    red   <= checkLimits(integer(yvalue*tmx1_c+(crvalue-128)*tm13_c)/128);
----    green <= checkLimits(integer(yvalue*tmx1_c-(cbvalue-128)*tm22_c- (crvalue-128)*tm23_c)/128);
----    blue  <= checkLimits(integer(yvalue*tmx1_c+(cbvalue-128)*tm32_c)/128);
--    return rgb;
--  end;
--
--  function MkFullColor(color : std_ulogic_vector; toBits : integer) return std_ulogic_vector is
--    variable c : std_ulogic_vector(toBits-1 downto 0) := (others => '0');
--    variable r : integer;
--  begin
--    r                              := color'high - color'low;
--    c(toBits-1 downto toBits-1 -r) := color;
--    for i in toBits-2-r downto 0 loop
--      c(i) := color(i+color'low);
--    end loop;
--    return c;
--  end;

  -- writes a DWORD (32 bit) using little endian- format to the File
  procedure writeDword(file bmp_File : video_Ramfile_t; val : integer) is
    variable x : integer;
  begin
    x := val mod 256;
    write(bmp_File, character'val(x));
    x := (val/256) mod 256;
    write(bmp_File, character'val(x));
    x := (val/65536) mod 256;
    write(bmp_File, character'val(x));
    x := (val/16777216) mod 256;
    write(bmp_File, character'val(x));
  end;

  -- writes a WORD (16 bit) using little endian- format to the File 
  procedure writeWord(file bmp_File : video_Ramfile_t; val : integer) is
    variable x : integer;
  begin
    x := val mod 256;
    write(bmp_File, character'val(x));
    x := (val/256) mod 256;
    write(bmp_File, character'val(x));
  end;

--  procedure writeRGB(file bmp_File : video_Ramfile_t; col : rgb_color_t) is
--    variable ch : character;
--  begin
--    ch := character'val(conv_integer(unsigned(col(blueRange_t))));
--    write(bmp_File, ch);
--    ch := character'val(conv_integer(unsigned(col(greenRange_t))));  -- green
--    write(bmp_File, ch);
--    ch := character'val(conv_integer(unsigned(col(redRange_t))));  -- red
--    write(bmp_File, ch);
--  
--  end;


  procedure write_hdr(file bmp_File : video_Ramfile_t; xres : integer; yres : integer; color : boolean) is
    variable val, tmp, padding      : integer;
    variable w,size, x              : integer;
    variable ch                     : character;
--    variable fn                     : string(1 to output_file_c'length+2);
--    variable col                    : rgb_color_t;
    variable yval,cbval,crval       : integer;
  begin
    
--    fn(1 to output_file_c'length) := output_file_c;
--    if fn(fn'length-5) = '.' and ((fn(fn'length-4) = 'B' and fn(fn'length-3) = 'M' and fn(fn'length-2) = 'P') or
--                                  (fn(fn'length-4) = 'b' and fn(fn'length-3) = 'm' and fn(fn'length-2) = 'p')) then
--      fn := fn(1 to fn'length-6)&'_'&character'val(48+frameNr)&fn(fn'length-5 to fn'length-2);
--    else
--      fn(fn'length-1) := '_';
--      fn(fn'length)   := character'val(frameNr);
--    end if;
    
--    file_open(bmp_File, output_file_c, write_mode);
    -- Kennung dass es sich um ein BMP handelt
    write(bmp_File, 'B');
    write(bmp_File, 'M');
    if color then
      w   := xres*3;                      -- 3 bytes per pixel
      tmp := w rem 4;                     -- calculate required padding- Bytes
      
      if tmp > 0 then
        padding := 4-tmp;                 -- a bmp- imageline must be mod 4
      else
        padding := 0;
      end if;
      size := yres*(w+padding) + 14 + 40;
    else
      size := yres*xres/8 + 14 + 40 + 8;  --128L*64/8+54+8
    end if;
    -- write Filesize (32 bit)
    writeDword(bmp_File, size);
    -- 4 Bytes reserved
    writeDword(bmp_File, 0);
    -- BOF (32 bit)
    if color then
      writeDword(bmp_File, 54);
    else
      writeDword(bmp_File, 54+8);
    end if;
    -- Length of BitMapInfoHeader (32 bit)
    writeDword(bmp_File, 40);
    -- Resolution
    writeDword(bmp_File, xres);
    writeDword(bmp_File, yres);
    -- Num Planes
    writeWord(bmp_File, 1);
    if color then
      -- Bits per Pixel
      writeWord(bmp_File, 24);
      -- No compression
      writeDword(bmp_File, 0);
      -- Imagesize
      writeDword(bmp_File, yres*(w+padding));
    else
      -- Bits per Pixel
      writeWord(bmp_File, 1);
      -- No compression
      writeDword(bmp_File, 0);
      -- Imagesize
      writeDword(bmp_File, yres*xres/8);
    end if;
    
    -- H und V- Resolution
    writeDword(bmp_File, 0);
    writeDword(bmp_File, 0);
    -- Color Used
    writeDword(bmp_File, 0);
    -- No of Important Colors
    writeDword(bmp_File, 0);
    if not color then
      writeDword(bmp_File, 17408);
      writeDword(bmp_File, 16777215);  
    end if;
  end;

    function lookup(color : in std_logic_vector(3 downto 0)) return std_logic_vector is
      variable tmp : std_logic_vector(8 downto 0);
    begin
      if color(3 downto 0) /= "1000" then
        tmp(8) := color(2);               -- red
        tmp(7) := color(2) and color(3);
        tmp(6) := tmp(7);
        tmp(5) := color(1);               -- green
        tmp(4) := color(1) and color(3);
        tmp(3) := tmp(4);
        tmp(2) := color(0);               -- blue
        tmp(1) := color(0) and color(3);
        tmp(0) := tmp(1);
      else
        tmp := "011011011";         -- light gray
      end if;  
      return tmp;
    end;
    
    function lookup8bit(color : in std_logic_vector(7 downto 0)) return std_logic_vector is
      variable tmp : std_logic_vector(8 downto 0);
    begin
        tmp(8 downto 6) := color(7 downto 5);               -- red
        tmp(5 downto 3) := color(4 downto 2);               -- green
        tmp(2 downto 0) := color(1 downto 0) & "0";         -- blue
        if color(1 downto 0)="11" then
            tmp(0) := '1';
        end if;
      return tmp;
    end;


  

  procedure write_byte(file bmp_File: video_Ramfile_t; byte : std_logic_vector; color : color_mode_t) is
--    variable tmp   : std_ulogic_vector(3 downto 0);
    variable r,g,b : std_logic_vector(7 downto 0);
    variable tmp1  : std_logic_vector(8 downto 0);
    variable ch    : character;
    variable by    : std_logic_vector(7 downto 0);
  begin
    if color=color_4bit then
      by:= byte;
      for i in 0 to 1 loop
        r := (others => '0');
        g := (others => '0');
        b := (others => '0');
        tmp1 := lookup(by(7 downto 4));
        r(7 downto 5) := tmp1(8 downto 6);
        g(7 downto 5) := tmp1(5 downto 3);
        b(7 downto 5) := tmp1(2 downto 0);
        ch  := character'val(to_integer(unsigned(b)));
        write(bmp_File, ch);
        ch  := character'val(to_integer(unsigned(g)));
        write(bmp_File, ch);
        ch  := character'val(to_integer(unsigned(r)));
        write(bmp_File, ch);
        
        by(7 downto 4) := by(3 downto 0);
      end loop;
    elsif color=color_8bit then
      by:= byte;
      r := (others => '0');
      g := (others => '0');
      b := (others => '0');
      tmp1 := lookup8bit(by(7 downto 0));
      r(7 downto 5) := tmp1(8 downto 6);
      g(7 downto 5) := tmp1(5 downto 3);
      b(7 downto 5) := tmp1(2 downto 0);
      ch  := character'val(to_integer(unsigned(b)));
      write(bmp_File, ch);
      ch  := character'val(to_integer(unsigned(g)));
      write(bmp_File, ch);
      ch  := character'val(to_integer(unsigned(r)));
      write(bmp_File, ch);

      by(7 downto 4) := by(3 downto 0);
    else
      ch  := character'val(to_integer(unsigned(byte)));
      write(bmp_File, ch);
    end if;
  end;

  -- Takes a YCbCr4:4:4 Pixel, convertes it into RGB Colorspace and writes it to BMP File
--  procedure write_YCbCr444(file bmp_File : video_Ramfile_t; Pixel : std_ulogic_vector(31 downto 0)) is
----    variable val, tmp, padding      : integer;
----    variable w, size, x             : integer;
----    variable ch                     : character;
--    variable col                    : rgb_color_t;
--    variable yval,cbval,crval       : integer;
--  begin
--
----        index := conv_integer(unsigned(videoRam(i*xres_c+j)));
----        col:=MkFullColor(videoRam(i*xres_c+j)(blueRange_t), 8);
--        yval:=  conv_integer(unsigned(Pixel(7 downto 0)))-16;
--        cbval:= conv_integer(unsigned(Pixel(15 downto 8)))-128;
--        crval:= conv_integer(unsigned(Pixel(23 downto 16)))-128;
--        
--        col:=   YCbCr2RGB(yval,cbval,crval);
--
----        ReadFromBus(rgbDataAdr_sel,tmp);
----        col:=std_ulogic_vector(conv_unsigned(tmp,32));      
--        writeRGB(bmp_File, col);
----        ch := character'val(conv_integer(unsigned(col(blueRange_t))));
----        write(bmp_File, ch);
----        ch := character'val(conv_integer(unsigned(col(greenRange_t))));  -- green
----        write(bmp_File, ch);
----        ch := character'val(conv_integer(unsigned(col(redRange_t))));  -- red
----        write(bmp_File, ch);
--
--  end;
  
    -- convertes the temp. file of a frame into a .BMP- file
--  procedure write_YCbCr422(file bmp_File : video_Ramfile_t; Pixel : std_ulogic_vector(31 downto 0)) is
--    variable col                           : rgb_color_t;
--    variable y0val,y1val,cbval,crval       : integer;
--  begin
--
--
--    y0val:=  conv_integer(unsigned(Pixel(7 downto 0)))-16;
--    y1val:=  conv_integer(unsigned(Pixel(23 downto 16)))-16;
--    cbval:= conv_integer(unsigned(Pixel(15 downto 8)))-128;
--    crval:= conv_integer(unsigned(Pixel(31 downto 24)))-128;
--
----    if ytmp>0 then
----      col:=YCbCr2RGB(ytmp,cbval,crtmp);
----      writeRGB(bmp_File,col);
----    end if;
--    
--    col:=   YCbCr2RGB(y0val,cbval,crval);
--    writeRGB(bmp_File,col);
--    col:=   YCbCr2RGB(y1val,cbval,crval);
--    writeRGB(bmp_File,col);
----    if last then
----      ytmp:=0;  -- mark it as empty
----      crtmp:=0;
----      col:=   YCbCr2RGB(y1val,cbval,crval);
----      writeRGB(bmp_File,col);
----    else
----      ytmp:=y1val;
----      crtmp:=crval;
----    end if;
--  end;
--
--  procedure write_RGB555(file bmp_File : video_Ramfile_t; Pixel : std_ulogic_vector(31 downto 0)) is
--    variable col : rgb_color_t;
--  begin
--    col(blueRange_t) := MkFullColor(Pixel(4 downto 0), 8);
--    col(greenRange_t):= MkFullColor(Pixel(9 downto 5), 8);
--    col(redRange_t)  := MkFullColor(Pixel(14 downto 10), 8);
--    writeRGB(bmp_File, col);
--    col(blueRange_t) := MkFullColor(Pixel(20 downto 16), 8);
--    col(greenRange_t):= MkFullColor(Pixel(25 downto 21), 8);
--    col(redRange_t)  := MkFullColor(Pixel(30 downto 26), 8);
--    writeRGB(bmp_File, col);
--  end;
--
--  procedure write_RGB888(file bmp_File : video_Ramfile_t; Pixel : std_ulogic_vector(31 downto 0)) is
--    variable col : rgb_color_t;
--  begin
--    col(blueRange_t) := Pixel(7 downto 0);
--    col(greenRange_t):= Pixel(15 downto 8);
--    col(redRange_t)  := Pixel(23 downto 16);
--    writeRGB(bmp_File, col);
--  end;

--  procedure WriteEOL(file bmp_File : video_Ramfile_t;xres : integer) is
--    variable tmp, padding      : integer;
--    variable w, size           : integer;
--  begin
--    w   := xres*3;                      -- 3 bytes per pixel
--    tmp := w rem 4;                     -- calculate required padding- Bytes
--
--    if tmp > 0 then
--      padding := 4-tmp;                 -- a bmp- imageline must be mod 4
--      for j in 1 to padding loop
--        write(bmp_File, character'val(0));  -- Padding to mod 4
--      end loop;  -- j
--    end if;
--  end;

end package body;
