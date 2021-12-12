--------------------------------------------------------------------------------
-- Project     : Single Chip NDR Computer
-- Module      : Clock-gating cell for FPGA
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


entity clk_gate is
  port(
    clk_i    : in  std_ulogic; -- clock input
    en_i     : in  std_ulogic; -- clock enable signal
    clk_o    : out std_ulogic  -- gated clock
    );
end clk_gate;

architecture fpga of clk_gate is

  constant latch_enable_with_test_enable_c : boolean := TRUE;
  
  signal clk_latched_s   : std_ulogic;
  
  -- enable signal for latch of clock gating cell
  signal latch_enable_s  : std_ulogic;
  
  -- synchronized enable signal for clock (second input of AND gate)
  signal clk_enable_s    : std_ulogic;


begin

  -- define for clock gating cell if the test enable is inserted before the
  -- clock gating latch (latch_enable_with_test_enable_c = TRUE)
  -- or after the latch (latch_enable_with_test_enable_c = FALSE)
  
  -----------------------------------------------------------------------------
  latch_enable_p : process (en_i)
    variable latch_enable_v  : std_ulogic;
  begin
    -- default
    -- for enable active clock will run
    latch_enable_v := en_i;  
    latch_enable_s <= latch_enable_v;
  end process latch_enable_p;
  
  
  -----------------------------------------------------------------------------
  latches_on_enable_lines_p : process (clk_i, latch_enable_s)
  begin
    if (clk_i = '0') then
      clk_latched_s  <= latch_enable_s;
    end if;
  end process latches_on_enable_lines_p;
  
  
  -----------------------------------------------------------------------------
  clk_enable_p : process (clk_latched_s)
    variable clk_enable_v  : std_ulogic;
  begin
    -- default
    -- for enable active clock will run
    clk_enable_v := clk_latched_s;  
    clk_enable_s <= clk_enable_v;
  end process clk_enable_p;
  
  
  -----------------------------------------------------------------------------
  -- AND gate
  -----------------------------------------------------------------------------
  clk_o <= clk_i and clk_enable_s;

end fpga;
