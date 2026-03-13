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
  signal gpio_reg1   : std_logic_vector(7 downto 0):=(others =>'0');
begin  -- beh

  -- clock generation
  Clk     <= not Clk after 18.51851859 ns; -- 27 MHz

  DUT: entity work.nkc_gowin_top
    generic map(sim_g          => true,
                use_test_rom_g => true)
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
      Ps2MouseClk_io => Ps2MouseClk,
      Ps2MouseDat_io => Ps2MouseDat,
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

i2c_slave : entity work.i2c_slave_model
   port map (
      scl => Ps2MouseClk,
      sda => Ps2MouseDat
   );

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
   
   nkc_DB <= gpio_reg after 150 ns when nkc_nIORQ='0' and nkc_nRD='0' and nkc_ADDR=X"30" else
             gpio_reg1 after 150 ns when nkc_nIORQ='0' and nkc_nRD='0' and nkc_ADDR=X"31" else
             (others => 'Z') after 20 ns;
   
   process(nkc_DB,nkc_ADDR,   nkc_nRD, nkc_nWR, nkc_nIORQ)
   begin
      if nkc_nWR='0' and nkc_nIORQ='0' and  nkc_ADDR=X"30" then
         gpio_reg <= nkc_DB;
      elsif nkc_nWR='0' and nkc_nIORQ='0' and  nkc_ADDR=X"31" then
         gpio_reg1 <= nkc_DB;
      end if;
   end process;   
  Ps2Clk <= 'H';
  Ps2Dat <= 'H';
  Ps2MouseClk <= 'H';
  Ps2MouseDat <= 'H';
   PS2_Proc: process
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
    Ps2Clk <= 'Z';
    Ps2Dat <= 'Z';
    wait for 100 us;
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
  end process PS2_Proc;
--   PS2_Mouse: process
--    procedure sendbit(b : in std_logic) is
--    begin
--      Ps2MouseDat <= b;
--      Ps2MouseClk <= '0';
--      wait for 25 us;
--      Ps2MouseClk <= '1';
--      wait for 25 us;
--    end sendbit;
--    procedure sendmouse(data : in std_logic_vector(7 downto 0)) is
--      variable parity : std_logic :='1';
--    begin
--      sendbit('0');
--      for i in 0 to 7 loop
--        sendbit(data(i));
--        parity := parity xor data(i);
--      end loop;
--      sendbit(parity);
--      sendbit('1');
--      Ps2MouseClk <= 'Z';
--      Ps2MouseDat <= 'Z';
--    end sendmouse;
--  begin
--
--    Ps2MouseClk <= 'Z';
--    Ps2MouseDat <= 'Z';
--    wait for 100 us;
--    sendmouse(X"08"); 
--    sendmouse(X"05");
--    sendmouse(X"05");
--    wait for 1 ms;
--    sendmouse(X"38"); 
--    sendmouse(X"FB");
--    sendmouse(X"FB");
--    wait;
--  end process PS2_Mouse;
end beh;