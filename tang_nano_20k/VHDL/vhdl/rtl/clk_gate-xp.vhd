--------------------------------------------------------------------------------
-- Project     : Single Chip NDR Computer
-- Module      : Clock-gating cell for Lattice XP
-- File        : clk_gate-fpga.vhd
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

-- synopsys translate_off
library xp;
use xp.components.all;
-- synopsys translate_on

entity clk_gate is
  port(
    clk_i    : in  std_ulogic; -- clock input
    en_i     : in  std_ulogic; -- clock enable signal
    clk_o    : out std_ulogic  -- gated clock
    );
end clk_gate;

architecture rtl of clk_gate is
  COMPONENT DCS
    -- synthesis translate_off
    GENERIC (
      DCSMODE : string := "POS"
    );
    -- synthesis translate_on
    PORT (
      CLK0 :IN std_logic;
      CLK1 :IN std_logic;
      SEL :IN std_logic;
      DCSOUT :OUT std_logic
    );
  END COMPONENT;
  attribute DCSMODE : string;
  attribute DCSMODE of DCSinst0 : label is "HIGH_LOW";

begin
  DCSInst0: DCS
  -- synthesis translate_off
  GENERIC MAP(
    DCSMODE => "HIGH_LOW"
  )
  -- synthesis translate_on
  PORT MAP (
    SEL    => en_i,
    CLK0   => '0',
    CLK1   => clk_i,
    DCSOUT => clk_o
  );

end rtl;
