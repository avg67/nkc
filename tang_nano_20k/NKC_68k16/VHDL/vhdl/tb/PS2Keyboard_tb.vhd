-------------------------------------------------------------------------------
-- Title      : Testbench for design "PS2Keyboard"
-- Project    : 
-------------------------------------------------------------------------------
-- File       : PS2Keyboard_tb.vhd
-- Author     :   <Andreas Voggeneder@LAPI>
-- Company    : 
-- Created    : 2007-06-15
-- Last update: 2007-06-15
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2007 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2007-06-15  1.0      Andreas Voggeneder	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity PS2Keyboard_tb is

end PS2Keyboard_tb;

-------------------------------------------------------------------------------

architecture behav of PS2Keyboard_tb is

  component PS2Keyboard
    port (
      reset_n_i : in    std_logic;
      clk_i     : in    std_logic;
      Ps2Clk_io : inout std_logic;
      Ps2Dat_io : inout std_logic;
      KeyCS_i   : in  std_ulogic;
      DipCS_i   : in  std_ulogic;
      Rd_i      : in  std_ulogic;
      DataOut_o : out std_ulogic_vector(7 downto 0)
    );
  end component;

  -- component ports
  signal reset_n_i : std_logic;
  signal clk_i     : std_logic;
  signal Ps2Clk : std_logic;
  signal Ps2Dat : std_logic;

  -- clock
  signal Clk : std_logic := '1';

begin  -- behav

  -- component instantiation
  DUT: PS2Keyboard
    port map (
      reset_n_i => reset_n_i,
      clk_i     => Clk,
      Ps2Clk_io => Ps2Clk,
      Ps2Dat_io => Ps2Dat,
      KeyCS_i   => '0',
      DipCS_i   => '0',
      Rd_i      => '0',
      DataOut_o => open
   );

  -- clock generation
  Clk     <= not Clk after 12.5 ns;  -- 40 MHz
  Ps2Clk <= 'H';
  Ps2Dat <= 'H';
  -- waveform generation
  WaveGen_Proc: process
    procedure sendbit(b : in std_logic) is
    begin
      Ps2Dat <= b;
      Ps2Clk <= '0';
      wait for 25 us;
      Ps2Clk <= '1';
      wait for 25 us;
    end sendbit;
    procedure sendkbd(data : in std_logic_vector(7 downto 0)) is
      variable parity : std_logic :='1';
    begin
      sendbit('0');
      for i in 0 to 7 loop
        sendbit(data(i));
        parity := parity xor data(i);
      end loop;
      sendbit(parity);
      sendbit('1');
      Ps2Clk <= 'Z';
      Ps2Dat <= 'Z';
    end sendkbd;
  begin
    -- insert signal assignments here
    reset_n_i <= '0', '1' after 20 ns;
    Ps2Clk <= 'Z';
    Ps2Dat <= 'Z';
    wait for 100 us;
    sendkbd(X"BA"); -- Self Test ok
    wait for 10 ms;
    sendkbd(X"1c"); -- a
    wait for 1 ms;
    sendkbd(X"F0");
    sendkbd(X"1c");
    sendkbd(X"12"); -- shift
    sendkbd(X"1c"); -- A
    wait for 1 ms;
    sendkbd(X"F0");
    sendkbd(X"1c");
    sendkbd(X"F0");
    sendkbd(X"12"); -- shift relese
    sendkbd(X"06"); -- F1
    wait for 1 ms;
    sendkbd(X"F0");  
    sendkbd(X"06"); -- F1  
    sendkbd(X"E0");
    sendkbd(X"7d"); -- PGUP
    wait for 1 ms;
    sendkbd(X"E0");
    sendkbd(X"F0");  
    sendkbd(X"7D");
    wait for 1 ms;
    wait;
  end process WaveGen_Proc;

  

end behav;

-------------------------------------------------------------------------------


