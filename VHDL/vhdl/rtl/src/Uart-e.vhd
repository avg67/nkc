--------------------------------------------------------------------------------
-- Project     : Sandbox AVR Library
-- Module      : Uart
-- File        : Uart-e.vhd
-- Description : Entity RS232 Interface 9600,n,8,1.
--------------------------------------------------------------------------------
-- Author       : Andreas Voggeneder
-- Organisation : FH-Hagenberg
-- Department   : Hardware/Software Systems Engineering
-- Language     : VHDL'87
--------------------------------------------------------------------------------
-- Copyright (c) 2003 by Andreas Voggeneder
--------------------------------------------------------------------------------

library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.DffGlobal.all;
use work.global.all;


entity Uart is
  port(clr_n_i      : in  std_ulogic;
       clk_i        : in  std_ulogic;
       RxD          : in  std_ulogic;
       TxD          : out std_ulogic;
       --------------------------
       -- Synchronized Data Bus (AVR)
       --------------------------
       AVRAdr_i     : in  std_ulogic_vector(dUart_Size_c-1 downto 0);
       AVRCS_i      : in  std_ulogic;
       AVRDataIn_i  : in  std_ulogic_vector(7 downto 0);
       AVRRd_i      : in  std_ulogic;
       AVRWr_i      : in  std_ulogic;
       AVRDataOut_o : out std_ulogic_vector(7 downto 0);
       AVRIrq_o     : out std_ulogic_vector(1 downto 0)
       );
end Uart;





