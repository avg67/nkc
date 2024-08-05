-------------------------------------------------------------------------------
-- Title      : Testbench for design "nkc_top"
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

-------------------------------------------------------------------------------

entity nkc_tb is

end nkc_tb;

-------------------------------------------------------------------------------

architecture beh of nkc_tb is

  -- clock
  signal Clk : std_logic := '1';
  -- component ports
  signal reset : std_ulogic;

--  signal SRAM_addr_o    : std_ulogic_vector(15 downto 0);
--  signal SRAM_data_o    : std_ulogic_vector(7 downto 0);
--  signal SRAM_data_i    : std_ulogic_vector(7 downto 0);
--  signal SRAM_ena_o     : std_ulogic;
--  signal SRAM_we_o      : std_ulogic;
  signal SRAM_Addr      : std_ulogic_vector(17 downto 0);
  signal SRAM_DB        : std_logic_vector(7 downto 0);
  signal SRAM_nCE       : std_logic;
  signal SRAM_nWR       : std_logic;
  signal SRAM_nOE       : std_logic;
  signal do_dump        : boolean := false;
  signal SRAM2_nCS      : std_ulogic;
  signal SRAM2_ADR      : std_ulogic_vector(17 downto 0);
  signal SRAM2_DB       : std_logic_vector(7 downto 0);
  signal SRAM2_nWR      : std_ulogic;
  signal SRAM2_nOE      : std_ulogic;

begin  -- beh

  -- component instantiation
  DUT: entity work.nkc_top
    generic map(sim_g => true)
    port map (
      reset_i     => reset,
      clk_i       => clk,
      Red_o       => open,
      Green_o     => open,
      Blue_o      => open,
      Hsync_o     => open,
      Vsync_o     => open,
      SRAM1_ADR   => SRAM_addr,
      SRAM1_nCS   => SRAM_nCE,
      SRAM1_DB    => SRAM_DB,
      SRAM1_nWR   => SRAM_nWR,
      SRAM1_nOE   => SRAM_nOE,
      RxD_i       => '1',
      FDD_RDn     => '0',
      FDD_TR00n   => '0',
      FDD_IPn     => '0',
      FDD_WPRTn   => '0',
               
      FDD_MOn     => open,
      FDD_WGn     => open,
      FDD_WDn     => open,
      FDD_STEPn   => open,
      FDD_DIRCn   => open,
      FDD_DSELn   => open,
      FDD_SDSEL   => open,
      FDD_SIDE    => open,

      SRAM2_nCS   => SRAM2_nCS,
      SRAM2_ADR   => SRAM2_ADR,
      SRAM2_DB    => SRAM2_DB, 
      SRAM2_nWR   => SRAM2_nWR,
      SRAM2_nOE   => SRAM2_nOE,
      SRAM2_nBE   => open,
      FLASH_nCE   => open,
      FLASH_nWE   => open,
      FLASH_nOE   => open
    );

  -- clock generation
  --Clk <= not Clk after 12.5 ns;
  Clk <= not Clk after 6.25 ns;

--  SRAM_DB <= std_logic_vector(SRAM_data_o) after 1 ns when (SRAM_ena_o and SRAM_we_o)='1' else
--             (others => 'Z') after 1 ns;

--  SRAM_data_i <= std_ulogic_vector(SRAM_DB);
--  SRAM_nCE    <= not (SRAM_ena_o and not Clk);
--  SRAM_nWR    <= not (SRAM_we_o and not Clk);
--  SRAM_nOE    <= (SRAM_we_o and not Clk);
--  SRAM_Addr   <= std_logic_vector(SRAM_addr_o) after 1 ns;

  VRAM : entity work.SRAM
     port map(
     dump => do_dump,
     nCE => SRAM_nCE,
     nWE => SRAM_nWR,
     nOE => SRAM_nOE,
     A   => std_logic_vector(SRAM_Addr(15 downto 0)),
     D   => SRAM_DB(7 downto 0)
   );

  CPU_RAM : entity work.SRAM
     port map(
     dump => false,
     nCE => SRAM2_nCS,
     nWE => SRAM2_nWR,
     nOE => SRAM2_nOE,
     A   => std_logic_vector(SRAM2_ADR(15 downto 0)),
     D   => SRAM2_DB(7 downto 0)
   );

  -- waveform generation
--  WaveGen_Proc: process
--    procedure write_bus(addr : in bit_vector(7 downto 0); data : in bit_vector(7 downto 0)) is
--    begin
--      CS_i <= '1' after 1 ns;
--      Wr_i <= '1' after 1 ns;
--      Adr_i <= to_stdulogicvector(addr) after 1 ns;
--      DataIn_i <= to_stdulogicvector(data) after 1 ns;
--      wait until Clk'event and Clk='1';
--      CS_i       <= '0' after 1 ns;
--      Wr_i       <= '0' after 1 ns;
--      wait until Clk'event and Clk='1';
--    end write_bus;
--
--    procedure read_bus(addr : in bit_vector(7 downto 0); data : out std_ulogic_vector(7 downto 0)) is
--    begin
--      CS_i <= '1' after 1 ns;
--      Rd_i <= '1' after 1 ns;
--      Adr_i <= to_stdulogicvector(addr) after 1 ns;
--      wait until Clk'event and Clk='1';
--      CS_i       <= '0' after 1 ns;
--      Rd_i       <= '0' after 1 ns;
--      wait until Clk'event and Clk='1';
--      data       := DataOut_o;
--     end read_bus;
--
--    procedure wait_ready is
--      variable tmp_v : std_ulogic_vector(7 downto 0);
--    begin
--      read_bus(X"70",tmp_v);
--      while tmp_v(2) = '0' loop
--        read_bus(X"70",tmp_v);
--      end loop;
--    end wait_ready;
--
--  begin
--    -- insert signal assignments here
--    do_dump    <= false;
--    Adr_i      <= (others => '0');
--    DataIn_i   <= (others => '0');
--    CS_i       <= '0';
--    Rd_i       <= '0';
--    Wr_i       <= '0';
--    reset_n_i  <= '0', '1' after 20 ns;
--    wait for 100 ns;
--    wait until Clk'event and Clk='1';
--    write_bus(X"70",X"07");  -- Clear Screen
--    wait_ready;
--    wait for 1500 us;
--    write_bus(X"75",X"04");  -- dx = 5
--    write_bus(X"71",X"03");  --  CTRL1 = 3
--    write_bus(X"72",X"01");  --  CTRL2 = 1
----    write_bus(X"70",X"00");
----    write_bus(X"70",X"02");
----    write_bus(X"70",X"11");
--    write_bus(X"70",X"10");  -- x+=5
--    wait_ready;
--    write_bus(X"70",X"E6");  -- x-=4
--    wait_ready;
--    write_bus(X"70",X"A6");  -- x-=2
--    wait_ready;
--    write_bus(X"70",X"80");  -- x+=1
--    wait_ready;
----    write_bus(X"70",X"F9");  -- x+=4, Y+=4
--    write_bus(X"75",X"ff");  -- dx = 255
----    write_bus(X"70",X"19");  -- x+=255
--    wait_ready;
--
--    write_bus(X"70",X"05");  -- x,y=0
--    write_bus(X"73",X"11");  -- CSIZE = 0x22
--    write_bus(X"70",X"21");  --
--    wait_ready;
--    write_bus(X"70",X"7f");  --
--    wait_ready;
--    write_bus(X"70",X"41");  --
--    wait_ready;
--    write_bus(X"70",X"0B");  -- 4x4
--    wait_ready;
--    write_bus(X"70",X"0A");  -- 5x8
--    wait_ready;
--    write_bus(X"72",X"00");  --
--    write_bus(X"79",X"64");  -- x=100
--    write_bus(X"7B",X"64");  -- y=100
--    write_bus(X"70",X"E0");  -- x+=4 draw marker
--    wait_ready;
--    write_bus(X"79",X"64");  -- x=100
--    write_bus(X"70",X"9C");  -- y-=4 draw marker
--    wait_ready;
--    write_bus(X"79",X"32");  -- x=50
--    write_bus(X"7B",X"32");  -- y=50
--    write_bus(X"72",X"04");  --
--    write_bus(X"70",X"41");  --
--    wait_ready;
--    write_bus(X"79",X"32");  -- x=50
--    wait_ready;
--    write_bus(X"72",X"0C");  --
--    write_bus(X"79",X"64");  -- x=100
--    write_bus(X"7B",X"64");  -- y=100
--    write_bus(X"70",X"41");  --
--    wait_ready;
--    
----    write_bus(X"71",X"0B");  --  CTRL1 = b, neverLeave=1
--    write_bus(X"79",X"A0");  -- 
--    write_bus(X"78",X"01");  -- x=0x1A0
--    write_bus(X"7B",X"64");  -- y=100
--    write_bus(X"77",X"10");  -- dy = 10
--    write_bus(X"70",X"11");  -- x+=255, y+=10
--    wait_ready;
--    write_bus(X"70",X"0E");  -- y = 0
--    write_bus(X"70",X"0D");  -- x = 0
--    wait_ready;
--    write_bus(X"72",X"00");  -- CTRL2 = 0
--    write_bus(X"79",X"16");  -- x=22
--    write_bus(X"70",X"01");  -- Löschstift
--    write_bus(X"70",X"0B");  -- 4x4
--    wait_ready;
--    write_bus(X"79",X"20");  -- x=32
--    write_bus(X"70",X"00");  -- Schreibstift
--    write_bus(X"70",X"0B");  -- 4x4
--    wait_ready;
--    write_bus(X"72",X"04");  -- CTRL2 = 4
--    write_bus(X"79",X"28");  -- x=40
--    write_bus(X"70",X"0B");  -- 4x4
--    wait_ready;
--    write_bus(X"60",X"01");  -- XOR Mode
--    write_bus(X"79",X"05");   -- x=5
--    write_bus(X"72",X"00");  -- CTRL2 = 0
--    write_bus(X"70",X"0B");  -- 4x4
--    wait_ready;
--    do_dump <= true;
--    wait for 1 us;
--    assert false report "End of simulation" severity failure;
--    wait;
--  end process WaveGen_Proc;

  reset      <= '1', '0' after 20 ns;
  do_dump    <= false, true after 150 ms;

end beh;

