-------------------------------------------------------------------------------
-- Title      : Testbench for design "MIST_Toplevel"
-- Project    :
-------------------------------------------------------------------------------
-- File       : Toplevel_tb.vhd
-- Author     : andreas.voggeneder  <voggened@lzsxc006.lz.intel.com>
-- Company    :
-- Created    : 2015-05-06
-- Last update: 2015-05-06
-- Platform   :
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Copyright (c) 2015
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2015-05-06  1.0      voggened	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.ALL;
-------------------------------------------------------------------------------

entity hdmi_test is
  port(
    reset_n_i    : in  std_logic;
    pixel_clk_i  : in  std_logic;
    red_o        : out std_ulogic_vector(2 downto 0);
    green_o      : out std_ulogic_vector(2 downto 0);
    blue_o       : out std_ulogic_vector(2 downto 0);
    vreset_o     : out std_ulogic;
  );
end hdmi_test;

-------------------------------------------------------------------------------

architecture rtl of hdmi_top is
  --constant HMAX_c            : natural :=880 -1 ; --+8+32;
  constant HMAX_c            : natural :=1056 -1 ; --+40(HFP)+128(HSYNC);
  --constant VMAX_c            : natural :=618 -1 ; --+4+8;
  constant VMAX_c            : natural :=628 -1 ; --+1(VFP)+4(VSYNC);
  --constant HFRONT_PORCH_c    : natural := 8; --40;
  --constant VFRONT_PORCH_c    : natural := 37; --1;
  signal pixel_clk : std_logic;
  signal delay  : natural range 0 to 100;
  signal run    : std_logic;
  signal audio0 :  std_logic_vector(15 downto 0):=(others =>'0');
  signal audio1 :  std_logic_vector(15 downto 0):=(others =>'0');
  signal reset, pll_lock : std_logic;
  signal vreset_done     : std_logic;
 
  signal red             : std_logic_vector(5 downto 0);
  signal green           : std_logic_vector(5 downto 0);
  signal blue            : std_logic_vector(5 downto 0);
  signal vreset          : std_logic;
  signal vid_en          : std_logic;

  signal h_count : unsigned(10 downto 0);
  signal v_count : unsigned(9 downto 0);
  signal addr_col               : std_logic_vector(9 downto 0);
  signal addr_row               : std_logic_vector(9 downto 0);
  signal tpg                    : std_logic_vector(11 downto 0);
  
  signal debug   : std_logic;
  signal debug1  : std_logic;
begin  -- behav


    
    process(pixel_clk_i,reset_n_i) is
      variable sync_v : std_logic_vector(1 downto 0); --:=(others =>'1');
    begin
      if (reset_n_i='0') then
         sync_v     := (others =>'1');
         reset_sync <= '1';
      elsif rising_edge(pixel_clk_i) then
         reset_sync <= sync_v(1);
         sync_v(1) := sync_v(0);
         sync_v(0) := reset;
      end if;
    end process;

   
   vid_en <= '1' when h_count < 800 and v_count<600 else
             '0';
   
   process(reset_n_i, pixel_clk_i) is
   begin
      if (reset_n_i = '0') then
         h_count <= (others =>'0');
         v_count <= (others =>'0');
         vreset_done <= '0';
         vreset  <= '0';
         debug   <= '0';
         debug1  <= '0';
         run     <= '0';
         delay   <= 100;
      elsif rising_edge(pixel_clk_i) then
         debug   <= not debug;
         vreset  <= '0';
         if run='0' then
            if delay/=0 then
               delay <= delay - 1;
            else
               run    <= '1';
               vreset <= '1';
            end if;
         else
            if (h_count /= HMAX_c) then
               h_count <= h_count +1;
            else
               h_count <= (others =>'0');
               if (v_count /= VMAX_c) then
                  v_count <= v_count +1;
               else
                  v_count <= (others =>'0');
                  if (vreset_done='0') then
                     vreset  <= '1';
                     vreset_done <= '1';
                  end if;
                  debug1 <= not debug1;
               end if;
            end if;
         end if;
      end if;
   end process;
   
   addr_col <= std_logic_vector(h_count(addr_col'range));
   addr_row <= std_logic_vector(v_count(addr_row'range));
   
  p_tpg : process
    variable c : std_logic_vector(3 downto 0);
  begin
    wait until rising_edge(pixel_clk);
    c := addr_col(6 downto 3);
    tpg <= (others => '0');
    if (addr_row(9 downto 8) = "00") then
      case addr_col(9 downto 6) is
        when x"0" | x"1" | x"2" | x"3" => -- 0 - 255
          tpg(11 downto 8) <= x"0"; tpg(7 downto 4) <= x"0"; tpg(3 downto 0) <= c;
        -- green
        when x"4" | x"5" | x"6" | x"7" => -- 256 - 511
          tpg(11 downto 8) <= x"0"; tpg(7 downto 4) <= c   ; tpg(3 downto 0) <= x"0";
        -- blue
        when x"8" | x"9" | x"a" | x"b" => -- 512 - 767
          tpg(11 downto 8) <= c   ; tpg(7 downto 4) <= x"0"; tpg(3 downto 0) <= x"0";
        -- gray
        when x"c" | x"d" | x"e" | x"f" => -- 768 - 799
          tpg(11 downto 8) <= c   ; tpg(7 downto 4) <= c;    tpg(3 downto 0) <= c;
        when others => null;
      end case;
    else
      case addr_col(9 downto 6) is
        -- red
        when x"0" => tpg <= x"001";
        when x"1" => tpg <= x"002";
        when x"2" => tpg <= x"004";
        when x"3" => tpg <= x"008";
        -- green
        when x"4" => tpg <= x"010";
        when x"5" => tpg <= x"020";
        when x"6" => tpg <= x"040";
        when x"7" => tpg <= x"080";
        -- blue
        when x"8" => tpg <= x"100";
        when x"9" => tpg <= x"200";
        when x"a" => tpg <= x"400";
        when x"b" => tpg <= x"800";
        -- gray
        when x"c" => tpg <= x"777";
        when x"d" => tpg <= x"777";
        when x"e" => tpg <= x"777";
        when x"f" => tpg <= x"777";
        when others => null;
      end case;
    end if;
  end process;
   
  p_shifter            : process
  begin
    wait until rising_edge(pixel_clk_i);
    -- character generator removed
    if vid_en='1' then
       red   <= tpg( 3 downto 0)&"00";
       green <= tpg( 7 downto 4)&"00";
       blue  <= tpg(11 downto 8)&"00";
     else
       red   <= (others => '0');
       green <= (others => '0');
       blue  <= (others => '0');
     end if;
  end process;
   
   --debug_o(0) <= debug;
   --debug_o(1) <= debug1;
end rtl;

-------------------------------------------------------------------------------


