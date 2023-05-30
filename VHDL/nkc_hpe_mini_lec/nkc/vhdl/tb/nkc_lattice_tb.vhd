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

entity nkc_lattice_tb is

end nkc_lattice_tb;

-------------------------------------------------------------------------------

architecture beh of nkc_lattice_tb is

  -- clock
  signal Clk     : std_logic := '1';
  -- component ports
  signal reset_n        : std_ulogic;
  signal reset          : std_ulogic;
  signal SRAM_Addr      : std_logic_vector(22 downto 0);
  signal FLASH_Addr     : std_logic_vector(21 downto 0);
  signal SRAM_DB        : std_logic_vector(31 downto 0);
  signal SRAM_nCE       : std_logic;
  signal SRAM_nCE1      : std_logic :='0';
  signal SRAM_nWR       : std_logic;
  signal SRAM_nOE       : std_logic;
  signal SRAM_nBHE0     : std_logic;
  signal SRAM_nBLE0     : std_logic;
  signal SRAM_nBHE1     : std_logic;
  signal SRAM_nBLE1     : std_logic;
  signal FLASH_nCE      : std_logic;
  signal FLASH_nWP      : std_logic;
  signal FLASH_RESET    : std_logic;
  signal FLASH_nBYTE    : std_logic;
  signal FLASH_nWr      : std_logic;
--  signal FLASH_nRYBY    : std_logic;
  signal FLASH_nReset   : std_logic;
  signal TXD,RXD        : std_logic;

begin  -- beh
  SRAM_DB <= (others => 'H');
  
  DUT: entity work.soc_top
    generic map(sim_g => true)
    port map (
      --reset_n_i     => reset_n,
      reset_i       => reset,
      clk_i         => clk,
      SRAM_nCS_o    => SRAM_nCE,
      SRAM_ADR_o    => SRAM_Addr,
      SRAM_DB_io    => SRAM_DB,
      SRAM_nWR_o    => SRAM_nWR,
      SRAM_nOE_o    => SRAM_nOE,
      SRAM_nBE_o(0) => SRAM_nBHE0,
      SRAM_nBE_o(1) => SRAM_nBLE0,
      SRAM_nBE_o(2) => SRAM_nBHE1,
      SRAM_nBE_o(3) => SRAM_nBLE1,
      FLASH_nCE_o   => FLASH_nCE,
      FLASH_nWP_o   => FLASH_nWP,
      FLASH_RESET_o => FLASH_RESET,
      FLASH_nBYTE_o => FLASH_nBYTE,
      FLASH_nRYBY_i => "11",
      RxD_i         => RXD,
      TxD_o         => TXD,
      CTS_i         => '1'
      );

RAM0 : entity work.mobl_256Kx16
   generic map (
      dump_offset => 0,
      ADDR_BITS  => 18,
      DATA_BITS   => 16,
      depth       => 2**18,
      
      TimingInfo   => FALSE,
      TimingChecks =>'1'
   )
   port map(
       dump  => false,
       CE1_b => SRAM_nCE,
       CE2   => '1',
       WE_b  => SRAM_nWR,
       OE_b  => SRAM_nOE,
       BHE_b => SRAM_nBHE0,
       BLE_b => SRAM_nBLE0,
       A     => SRAM_Addr(17 downto 0),
       DQ    => SRAM_DB(15 downto 0)
   ); 
   
RAM1 : entity work.mobl_256Kx16
   generic map (
      dump_offset => 0,
      ADDR_BITS  => 18,
      DATA_BITS   => 16,
      depth       => 2**18,
      
      TimingInfo   => FALSE,
      TimingChecks =>'1'
   )
   port map(
       dump  => false,
       CE1_b => SRAM_nCE,
       CE2   => '1',
       WE_b  => SRAM_nWR,
       OE_b  => SRAM_nOE,
       BHE_b => SRAM_nBHE1,
       BLE_b => SRAM_nBLE1,
       A     => SRAM_Addr(17 downto 0),
       DQ    => SRAM_DB(31 downto 16)
   ); 
   
FLASH_nWr <= SRAM_nWR or FLASH_nCE;
FLASH_Addr <= SRAM_Addr(21 downto 0) when FLASH_nCE='0' else
              (others => '1');
Flash0 : entity work.flash_64m
   port map(
      CE_B    => FLASH_nCE,
      WE_B    => FLASH_nWr,
      BYTE_B  => FLASH_nBYTE,
      RESET_B => FLASH_nReset,
      OE_B    => SRAM_nOE,
      A       => FLASH_Addr(21 downto 0),
      Q       => SRAM_DB(15 downto 0)
   );
   
Flash1 : entity work.flash_64m
   port map(
      CE_B    => FLASH_nCE,        
      WE_B    => FLASH_nWr,    
      BYTE_B  => FLASH_nBYTE,    
      RESET_B => FLASH_nReset,
      OE_B    => SRAM_nOE,
      A       => FLASH_Addr(21 downto 0),
      Q       => SRAM_DB(31 downto 16)
   );

  FLASH_nReset <= '0', '1' after 1 us;
  -- clock generation
  Clk     <= not Clk after 20 ns;  -- 25 MHz
  reset_n <= '0', '1' after 100 ns;
  reset <= not reset_n;
   
   al : Entity work.AsyncLog
      generic map(FileName => "RX_Log.txt", Baud => 57600, Bits => 8)
      port map(TXD);
      
    as : Entity work.AsyncStim
      generic map(FileName => "Monitor.txt", InterCharDelay => 1000 us, Baud => 57600, Bits => 8)
      port map(RXD);


end beh;

