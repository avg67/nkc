-- -----------------------------------------------
-- Title:    Uebung 4
-- file:     DataPath.vhd
-- language: VHDL 93
-- author:       HSSE / Andreas Voggeneder
-- comments: 
-- history: 
--   03.2002 creation
-- -----------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity DataPathBroad is
  port(clk       : in  std_ulogic;
       clr_n     : in  std_ulogic;
       DinPar    : in  std_ulogic_vector(7 downto 0);
--       Baud      : in  std_ulogic;
       SelSp0    : in  std_ulogic;
       SelPty    : in  std_ulogic;
       SelD7     : in  std_ulogic_vector(1 downto 0);
       SelD6_0   : in  std_ulogic_vector(1 downto 0);
       SelSta    : in  std_ulogic;
       SelOddPty : in  std_ulogic;
       EnStp     : in  std_ulogic;
       EnPty     : in  std_ulogic;
       EnD7      : in  std_ulogic;
       EnD6_0    : in  std_ulogic;
       EnSta     : in  std_ulogic;
       TxD       : out std_ulogic);
end entity DataPathBroad;

architecture Rtl of DataPathBroad is
  signal Stp      : std_ulogic_vector(1 downto 0);  -- Stop bit Register
  signal Pty      : std_ulogic;                     -- Parity bit register
  signal D7       : std_ulogic;                     -- D7 bit Register
  signal Sta      : std_ulogic;                     -- Start bit Register
  signal D6_0     : std_ulogic_vector(6 downto 0);  -- D6-D0 bits Register
  signal Parity   : std_ulogic;
  signal MUX_Stp  : std_ulogic;
  signal MUX_Pty  : std_ulogic;
  signal MUX_D7   : std_ulogic;
  signal MUX_D6_0 : std_ulogic_vector(6 downto 0);
  signal MUX_Sta  : std_ulogic;
  
begin
  -- MUX Stopbit
  MUX_stp <= Stp(1) when SelSp0 = '0' else '1';
  -- MUX Parity
  MUX_Pty <= Stp(0) when SelPty = '0' else Parity;
  -- MUX D7
  MUX_D7  <= Pty    when SelD7 = "00" else
             '0' when SelD7 = "01" else DinPar(7) when SelD7="10" else '0';
  -- MUX D6 - D0
  MUX_D6_0 <= DinPar(6 downto 0) when SelD6_0 = "00" else
              D7 & D6_0(6 downto 1)     when SelD6_0 = "01" else
              Pty & D6_0(6 downto 1)    when SelD6_0 = "10" else
              Stp(0) & D6_0(6 downto 1) when SelD6_0 = "11";
  -- MUX Startbit
  MUX_Sta <= D6_0(0) when SelSta = '0' else '0';

  -- Process fuer die (12) FF 
  process(clk, clr_n)
  begin
    if clr_n = '0' then
      Stp  <= (others => '0');
      Pty  <= '0';
      D7   <= '0';
      Sta  <= '1';
      D6_0 <= (others => '0');
    elsif clk'event and clk = '1' then
--      if Baud = '1' then
        if EnStp = '1' then             -- Stopbit- FFs
          Stp <= '1' & MUX_Stp;
        end if;
        if EnPty = '1' then             -- Parity- FF
          Pty <= MUX_Pty;
        end if;
        if EnD7 = '1' then              -- D7 - FF
          D7 <= MUX_D7;
        end if;
        if EnD6_0 = '1' then            -- D6...D0 - FFs
          D6_0 <= MUX_D6_0;
        end if;
        if EnSta = '1' then             -- Startbit FF
          Sta <= MUX_Sta;
        end if;
--      end if;
    end if;
  end process;

  -- Parity Generator
  Parity <= D7 xor D6_0(6) xor D6_0(5) xor D6_0(4) xor D6_0(3) xor D6_0(2) xor D6_0(1) xor D6_0(0) xor SelOddPty;
  
  TxD <= Sta;  -- Den Ausgang (TxD) mit dem Ausgang des Startbit- FF verbinden
  
end Rtl;




