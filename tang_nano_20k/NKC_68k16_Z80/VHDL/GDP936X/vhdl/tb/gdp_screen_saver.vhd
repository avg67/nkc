--------------------------------------------------------------------------------
-- Project     : Single Chip NDR Computer
-- Module      : GDP 936X Display processor - Screenshot behavioural model
-- File        : gdp_screen_dumper.vhd
-- Description :
--------------------------------------------------------------------------------
-- Author       : Andreas Voggeneder
-- Organisation : FH-Hagenberg
-- Department   : Hardware/Software Systems Engineering
-- Language     : VHDL'87
--------------------------------------------------------------------------------
-- Copyright (c) 2007 by Andreas Voggeneder
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.gdp_global.all;
use work.gdp_bitmap.all;


entity gdp_screen_dumper is
  port(reset_n_i     : in  std_ulogic;
       clk_en_i      : in  std_ulogic;
       clk_i         : in  std_ulogic;
       pixel_red_i   : in std_ulogic_vector(2 downto 0);
       pixel_green_i : in std_ulogic_vector(2 downto 0);
       pixel_blue_i  : in std_ulogic_vector(2 downto 0);
       Hsync_i       : in std_ulogic;
       Vsync_i       : in std_ulogic;
       vid_en_i      : in std_ulogic;
       line_i        : in unsigned(10 downto 0);
       column_i      : in unsigned(10 downto 0)
     );
end gdp_screen_dumper;

architecture behav of gdp_screen_dumper is
   constant XRES_c: natural := 512;
   constant YRES_c: natural := 512;
   signal x_pos, y_pos : natural;
   signal vid_en_d     : std_ulogic;
   signal Vsync_d      : std_ulogic;
   signal column_d     : unsigned(10 downto 0);

begin
-- pragma translate_off

   process(clk_i, reset_n_i)
      CONSTANT low_address : natural := 0;
      CONSTANT high_address: natural := 512*512-1; 
      TYPE memory_array IS
         ARRAY (natural RANGE low_address TO high_address) OF std_logic_vector(8  DOWNTO 0);
      VARIABLE mem: memory_array;
      variable idx_v : natural;
      variable fnr : natural :=0;
      
      procedure Dump_Frame(frame_Nr : integer; page_Nr : integer) is
         variable xres,yres : integer;
         variable add,xbytes: integer;
         variable fn        : string(1 to output_file_c'length+2);
         file fh            : video_Ramfile_t;
         variable ch        : character;
      begin

      xres := XRES_c;
      yres := YRES_c; 

      fn(1 to output_file_c'length) := output_file_c;
      if fn(fn'length-5) = '.' and ((fn(fn'length-4) = 'B' and fn(fn'length-3) = 'M' and fn(fn'length-2) = 'P') or
                                    (fn(fn'length-4) = 'b' and fn(fn'length-3) = 'm' and fn(fn'length-2) = 'p')) then
        fn := fn(1 to fn'length-6)&'_'&character'val(48+frame_Nr)&fn(fn'length-5 to fn'length-2);
      else
        fn(fn'length-1) := '_';
        fn(fn'length)   := character'val(frame_Nr);
      end if;


      file_open(fh, fn, write_mode);
      write_hdr(fh,xres,yres,color_support_c);
      --      ytmp:=(others=>'0');

        add :=0;
        xbytes := xres;

      for y in yres-1 downto 0 loop
        for x in 0 to xbytes-1 loop
      --          ch  := character'val(conv_integer(mem(add)));
      --          write(fh, ch);
          --write_byte(fh,mem(add),color_support_c);
          write_byte(fh,mem(add),color_8bit);
          add := add +1;
        end loop;
        ch := 'A'; 
      end loop; 
      file_close(fh);       

      end; --procedure;
   
   begin
      if reset_n_i='0' then
         x_pos <= 0;
         y_pos <= 0;
         vid_en_d <= '0';
         Vsync_d  <= '0';
         column_d <= (others => '0');
      elsif rising_edge(clk_i) then
         vid_en_d <= vid_en_i;
         column_d <= column_i;
         Vsync_d  <= Vsync_i;
         if vid_en_d='1' then
            idx_v := to_integer(line_i*XRES_c + column_d);
            mem(idx_v) := std_logic_vector(pixel_red_i)&std_logic_vector(pixel_green_i)&std_logic_vector(pixel_blue_i);
         elsif (Vsync_d and not Vsync_i)='1' then
            Dump_Frame(fnr,0);
            fnr := fnr+1;
         end if;
      end if;
   end process;


-- pragma translate_on
end behav;




