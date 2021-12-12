-------------------------------------------------------------------------------
-- Title      : Testbench for design "gdp_kernel"
-- Project    :
-------------------------------------------------------------------------------
-- File       : gdp_kernel_tb.vhd
-- Author     :   <Andreas Voggeneder@LAPI>
-- Company    :
-- Created    : 2007-04-08
-- Last update: 2007-04-08
-- Platform   :
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Copyright (c) 2007
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2007-04-08  1.0      Andreas Voggeneder	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

-------------------------------------------------------------------------------

entity gdp_standallone_tb is

end gdp_standallone_tb;

-------------------------------------------------------------------------------

architecture beh of gdp_standallone_tb is

  -- clock
  signal Clk     : std_logic := '1';
  -- component ports
  signal reset_n_i : std_ulogic;


  signal SRAM_addr_o    : std_ulogic_vector(17 downto 0);
--  signal SRAM_data_o    : std_ulogic_vector(7 downto 0);
--  signal SRAM_data_i    : std_ulogic_vector(7 downto 0);
--  signal SRAM_ena_o     : std_ulogic;
--  signal SRAM_we_o      : std_ulogic;
  signal SRAM_Addr      : std_logic_vector(15 downto 0);
  signal SRAM_DB        : std_logic_vector(7 downto 0);
  signal SRAM_nCE       : std_logic;
  signal SRAM_nWR       : std_logic;
  signal SRAM_nOE       : std_logic;
  signal do_dump        : boolean;
  signal endflag        : std_ulogic;

begin  -- beh

  -- component instantiation
  DUT: entity work.gdp_standalone_top
    port map (
      reset_n_i   => reset_n_i,
      clk_i       => clk,
      driver_nEN_o=> open,
      driver_DIR_o=> open,
      endflag_o   => endflag,
      SRAM1_ADR   => SRAM_addr_o,
      SRAM1_DB    => SRAM_DB,
      SRAM1_nCS   => SRAM_nCE,
      SRAM1_nWR   => SRAM_nWR,
      SRAM1_nOE   => SRAM_nOE);

  -- clock generation
  Clk     <= not Clk after 12.5 ns;  -- 40 MHz


--  SRAM_DB <= std_logic_vector(SRAM_data_o) after 1 ns when (SRAM_ena_o and SRAM_we_o)='1' else
--             (others => 'Z') after 1 ns;

--  SRAM_data_i <= std_ulogic_vector(SRAM_DB);
--  SRAM_nCE    <= not (SRAM_ena_o and not Clk);
--  SRAM_nWR    <= not (SRAM_we_o and not Clk);
--  SRAM_nOE    <= (SRAM_we_o and not Clk);
  SRAM_Addr   <= std_logic_vector(SRAM_addr_o(15 downto 0)) after 1 ns;
  RSRAM : entity work.SRAM
     port map(
     dump => do_dump,
     nCE => SRAM_nCE,
     nWE => SRAM_nWR,
     nOE => SRAM_nOE,
     A   => SRAM_Addr(15 downto 0),
     D   => SRAM_DB(7 downto 0)
   );


  -- waveform generation
  WaveGen_Proc: process

  begin
    -- insert signal assignments here
    do_dump    <= false;


    reset_n_i  <= '0', '1' after 50 ns;
    wait for 100 ns;
    wait until Clk'event and Clk='1';

    wait until endflag='1' ;
    
    do_dump <= true;
    wait for 1 us;
    assert false report "End of simulation" severity failure;
    wait;
  end process WaveGen_Proc;



end beh;

