-------------------------------------------------------------------------------
-- Title      : Testbench for design "FX68"
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
use ieee.std_logic_unsigned.all;

-------------------------------------------------------------------------------

entity fx68_tb is

end fx68_tb;

-------------------------------------------------------------------------------

architecture beh of fx68_tb is
  signal logic1         : std_ulogic;
  signal logic0         : std_ulogic;
  -- clock
  signal Clk : std_logic := '1';
  -- component ports
  signal reset,pwrUp    : std_ulogic;
  signal clkDivisor     : unsigned(1 downto 0) :="00";
  signal enPhi1,enPhi2  : std_ulogic;
  signal iEdb, oEdb     : std_ulogic_vector(15 downto 0);
  signal eab            : std_ulogic_vector(23 downto 0);
  signal RWn            : std_ulogic;
  signal ASn            : std_ulogic;
  signal LDSn           : std_ulogic;
  signal UDSn           : std_ulogic;
  signal fc             : std_ulogic_vector(2 downto 0);
  signal DTACKn         : std_ulogic;
  signal VPAn           : std_ulogic;

--  signal SRAM_addr_o    : std_ulogic_vector(15 downto 0);
--  signal SRAM_data_o    : std_ulogic_vector(7 downto 0);
--  signal SRAM_data_i    : std_ulogic_vector(7 downto 0);
--  signal SRAM_ena_o     : std_ulogic;
--  signal SRAM_we_o      : std_ulogic;


begin  -- beh

  -- clock generation
  --Clk <= not Clk after 12.5 ns;
  Clk <= not Clk after 20 ns;

logic1 <= '1';
logic0 <= '0';

fx68k: entity work.fx68k 
   port map (
   clk       => Clk,
   extReset  => reset,
   pwrUp     => pwrUp,
   enPhi1    => enPhi1,
   enPhi2    => enPhi2,

   eRWn      => RWn,
   ASn       => ASn,
   LDSn      => LDSn,
   UDSn      => UDSn,
   E         => open,
   VMAn      => open,
   FC0       => fc(0),
   FC1       => fc(1),
   FC2       => fc(2),
   BGn       => open,
   oRESETn   => open,
   oHALTEDn  => open,
   DTACKn    => DTACKn,
   VPAn      => VPAn,
   BERRn     => logic1,
   HALTn     => logic1 ,
   BRn       => logic1,
   BGACKn    => logic1,
   IPL0n     => logic1,
   IPL1n     => logic1,
   IPL2n     => logic1,
   iEdb      => iEdb,
   oEdb      => oEdb,
   eab       => eab(23 downto 1)
);
eab(0) <= '0';

test_rom: entity work.test
   port map (
      clock   => Clk,
      address => eab(6 downto 1),
      q       => iEdb
   );

   process(Clk)
   begin
      if rising_edge(Clk) then
         clkDivisor <= clkDivisor +1;
      end if;
   end process;
   
  enPhi1 <= '1' when clkDivisor = "11" else '0';
  enPhi2 <= '1' when clkDivisor = "01" else '0';
  VPAn   <= '0' when fc="111" and ASn='0' else
            '1';
  DTACKn <= '0';
  reset      <= '1', '0' after 1 us;
  pwrUp      <= '1', '0' after 2 us;

end beh;

