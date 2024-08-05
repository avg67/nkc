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

entity Toplevel_tb is

end Toplevel_tb;

-------------------------------------------------------------------------------

architecture behav of Toplevel_tb is


  -- component ports
  --signal CLOCK_27   : std_logic_vector(1 downto 0):="00";
  signal reset_i  : std_logic;

   type t_vector is array (1 downto 0) of std_logic_vector(15 downto 0);
  -- clock
  signal Clk : std_logic := '1';
--  signal pixel_clk : std_logic;
--  signal  r : std_logic_vector(5 downto 0):=(others => '0');
--  signal  g : std_logic_vector(5 downto 0):=(others => '0');
--  signal  b : std_logic_vector(5 downto 0):=(others => '0');
--  --signal audio : t_vector:=(others => (others =>'0'));
--  signal audio0 :  std_logic_vector(15 downto 0):=(others =>'0');
--  signal audio1 :  std_logic_vector(15 downto 0):=(others =>'0');
--  signal vreset : std_logic:='0';
--  signal vvmode  :  std_logic_vector(1 downto 0):=(others =>'0');
--  signal pixel_count : natural range 0 to 800*600 :=800*600-10;
begin  -- behav

    --CLOCK_27(0) <= Clk;

 
  -- component instantiation
--  DUT: entity work.video2hdmi
--    port map (
--      clk            => Clk,
--      clk_32         => pixel_clk,
--      pll_lock       => open,
--      vreset         => vreset,
--      vvmode         => vvmode,
--      vwide          => '0',
--       r             => r,
--       g             => g,
--       b             => b,
--      --audio          => audio,
--      audio0          => audio0,
--      audio1          => audio1,
--      --audio(1)       => audio1,
--      tmds_clk_n     => open,
--      tmds_clk_p     => open,
--      tmds_d_n       => open,
--      tmds_d_p       => open
--    );
    
    DUT: entity work.hdmi_top
      port map (
         reset_i   => reset_i,
         clk_i     => Clk
      );

  -- clock generation
  Clk <= not Clk after 18.51851859 ns; -- 27 MHz

  -- waveform generation
  WaveGen_Proc: process
  begin
    -- insert signal assignments here
    reset_i <= '1', '0' after 50 ns;
    wait until Clk = '1';
    wait;
  end process WaveGen_Proc;

   --vreset <= '0', '1' after 100 us, '0' after 101 us;

   
--   process(pixel_clk) is
--   begin
--      if rising_edge(pixel_clk) then
--         vreset <= '0';
--         if (pixel_count = ((800*600) -1)) then
--            vreset <= '1';
--            pixel_count <= 0;
--         else
--            pixel_count <= pixel_count +1;
--         end if;
--      end if;
--   end process;
end behav;

-------------------------------------------------------------------------------


