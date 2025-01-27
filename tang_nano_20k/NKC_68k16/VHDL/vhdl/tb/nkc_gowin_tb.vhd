-------------------------------------------------------------------------------
-- Title      : Testbench for design "FX68"
-- Project    :
-------------------------------------------------------------------------------
-- File       : nkc_gowin_tb.vhd
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
use ieee.std_logic_unsigned.all;

-------------------------------------------------------------------------------

entity nkc_gowin_tb is

end nkc_gowin_tb;

-------------------------------------------------------------------------------

architecture beh of nkc_gowin_tb is
  -- clock
  signal Clk     : std_logic := '1';
  -- component ports
  signal reset_i   : std_ulogic;
  signal SDRAM_DQ   : std_logic_vector(31 downto 0);
  signal SDRAM_A    : std_logic_vector(10 downto 0);
  signal SDRAM_DQM  : std_logic_vector(3 downto 0);
  signal SDRAM_nWE  : STD_LOGIC;
  signal SDRAM_nCAS : STD_LOGIC;
  signal SDRAM_nRAS : STD_LOGIC;
  signal SDRAM_nCS  : STD_LOGIC;
  signal SDRAM_BA   : std_logic_vector(1 downto 0);
  signal SDRAM_CLK  : STD_LOGIC;
  --signal SDRAM_CLK_neg : std_logic;
  signal SDRAM_CKE  : STD_LOGIC;

  signal SDRAM_DQ1   : std_logic_vector(31 downto 0);
  signal SDRAM_A1    : std_logic_vector(10 downto 0);
  signal SDRAM_DQM1  : std_logic_vector(3 downto 0);
  signal SDRAM_nWE1  : STD_LOGIC;
  signal SDRAM_nCAS1 : STD_LOGIC;
  signal SDRAM_nRAS1 : STD_LOGIC;
  signal SDRAM_nCS1  : STD_LOGIC;
  signal SDRAM_BA1   : std_logic_vector(1 downto 0);

  signal SD_nCS         : std_ulogic_vector(1 downto 0);
  signal SD_MOSI        : std_ulogic;
  signal Ps2Clk         : std_logic;
  signal Ps2Dat         : std_logic;
  signal Ps2MouseClk    : std_logic;
  signal Ps2MouseDat    : std_logic;
  signal TxD            : std_ulogic:='1';
  
  signal nkc_DB      : std_logic_vector(7 downto 0):=(others =>'H');
  signal nkc_ADDR    : std_ulogic_vector(7 downto 0);
  signal nkc_nRD     : std_ulogic;
  signal nkc_nWR     : std_ulogic;
  signal nkc_nIORQ   : std_ulogic;
  signal driver_nEN  : std_ulogic;
  signal driver_DIR  : std_ulogic;
  signal gpio_reg    : std_logic_vector(7 downto 0):=(others =>'0');
begin  -- beh

  -- clock generation
  Clk     <= not Clk after 18.51851859 ns; -- 27 MHz

  DUT: entity work.nkc_gowin_top
    generic map(sim_g => false)
    port map (
      reset_i      => reset_i,
      refclk_i     => clk,
      nkc_DB       => nkc_DB,
      nkc_ADDR_o   => nkc_ADDR,
      nkc_nRD_o    => nkc_nRD,
      nkc_nWR_o    => nkc_nWR,
      nkc_nIORQ_o  => nkc_nIORQ,
      driver_nEN_o => driver_nEN,
      driver_DIR_o => driver_DIR,
      RxD_i       => TxD,
      TxD_o       => open,
--      CTS_i       => '1',
      Ps2Clk_io   => Ps2Clk,
      Ps2Dat_io   => Ps2Dat,
--      Ps2MouseClk_io => Ps2MouseClk,
--      Ps2MouseDat_io => Ps2MouseDat,
      SD_SCK_o    => open,
      SD_nCS_o    => SD_nCS,
      SD_MOSI_o   => SD_MOSI,
      SD_MISO_i   => '1',
      O_sdram_clk   => SDRAM_CLK, --SDRAM_CLK_neg,
      O_sdram_cke   => SDRAM_CKE,
      O_sdram_cs_n  => SDRAM_nCS,
      O_sdram_cas_n => SDRAM_nCAS,
      O_sdram_ras_n => SDRAM_nRAS,
      O_sdram_wen_n => SDRAM_nWE,
      IO_sdram_dq   => SDRAM_DQ,
      O_sdram_addr  => SDRAM_A,
      O_sdram_ba    => SDRAM_BA,
      O_sdram_dqm   => SDRAM_DQM
      --glob_gdp_en_i => '1'
    );

--  TX : entity work.RS_232_TX
--    port map(TX => TxD);

  DRAM_1: entity work.sdram_sim_model
    port map (
      Dq     => SDRAM_DQ,
      Addr   => SDRAM_A1,
      Ba     => SDRAM_BA1,
      Clk    => SDRAM_CLK,
      Cke    => SDRAM_CKE,
      Cs_n   => SDRAM_nCS1,
      Ras_n  => SDRAM_nRAS1,
      Cas_n  => SDRAM_nCAS1,
      We_n   => SDRAM_nWE1,
      Dqm    => SDRAM_DQM1
    );
    
    SDRAM_A1    <= SDRAM_A    after 1 ns;
    SDRAM_DQM1  <= SDRAM_DQM  after 1 ns;
    SDRAM_nWE1  <= SDRAM_nWE  after 1 ns;
    SDRAM_nCAS1 <= SDRAM_nCAS after 1 ns;
    SDRAM_nRAS1 <= SDRAM_nRAS after 1 ns;
    SDRAM_nCS1  <= SDRAM_nCS  after 1 ns;
    SDRAM_BA1   <= SDRAM_BA   after 1 ns;

   reset_i <= '1', '0' after 1 us;
   
   nkc_DB <= gpio_reg when nkc_nIORQ='0' and nkc_nRD='0' and nkc_ADDR=X"30" else
             (others => 'Z') after 150 ns;
   
   process(nkc_DB,nkc_ADDR,   nkc_nRD, nkc_nWR, nkc_nIORQ)
   begin
      if nkc_nWR='0' and nkc_nIORQ='0' and  nkc_ADDR=X"30" then
         gpio_reg <= nkc_DB;
      end if;
   end process;   
end beh;