-- -----------------------------------------------
-- Title:    Uebung 7
-- file:     RecDataPath.vhd
-- language: VHDL 93
-- author:       HSSE / Andreas Voggeneder
-- comments: 
-- history: 
--   03.2002 creation
-- -----------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity DataPathBroadRX is
  port(clk       : in  std_ulogic;
       clr_n     : in  std_ulogic;
       RxD       : in  std_ulogic;
--       Baud      : in  std_ulogic;
       SelStp    : in  std_ulogic;
       SelPty    : in  std_ulogic;
       SelD7     : in  std_ulogic;
       EnPty     : in  std_ulogic;
       EnD7      : in  std_ulogic;
       EnD6_0    : in  std_ulogic;
       EnSta     : in  std_ulogic;
       EnStp     : in  std_ulogic;
       StpOut    : out std_ulogic_vector(1 downto 0);
       PtyOut    : out std_ulogic;
       StaOut    : out std_ulogic;
       DoutPar   : out std_ulogic_vector(7 downto 0);
       Parity    : out std_ulogic;
       BaudSync  : out std_ulogic);

end entity DataPathBroadRX;

architecture Rtl of DataPathBroadRX is
  signal Stp            : std_ulogic_vector(1 downto 0);  -- Stop bit Register
  signal Pty            : std_ulogic;   -- Parity bit register
  signal D7             : std_ulogic;   -- D7 bit Register
  signal Sta            : std_ulogic;   -- Start bit Register
  signal D6_0           : std_ulogic_vector(6 downto 0);  -- D6-D0 bits Register
  signal MUX_Stp        : std_ulogic;
  signal MUX_Pty        : std_ulogic;
  signal MUX_D7         : std_ulogic;
  signal RxTmp1, RxTmp2 : std_ulogic;   -- 2 Register zum synchronisieren des Eingangs
  signal RxDold         : std_ulogic;
begin

  -- RxD- Pin Synchronisieren
  InputSync : process (clk, clr_n)
  begin
    if clr_n = '0' then
      RxTmp1 <= '0';                    -- Reset Condition
      RxTmp2 <= '0';
    elsif clk'event and clk = '1' then
      RxTmp1 <= RxD;                    -- RxD Pegel 
      RxTmp2 <= RxTmp1;
    end if;
  end process InputSync;

  -- Generiert BaudSync - Signal für den Baudrategenerator
  SyncBaudGen : process(clk, clr_n)
  begin
    if clr_n = '0' then
      RxDold   <= '0';                  -- Reset Condition
      BaudSync <= '0';
    elsif clk'event and clk = '1' then
      if (RxTmp2 /= RxDold and RxTmp2='0') then
        BaudSync <= '1';
      else
        BaudSync <= '0';
      end if;
      RxDold <= RxTmp2;  -- Bei jeder Taktflanke Pegel an RxD speichern
    end if;
  end process SyncBaudGen;


  -- MUX Stopbit
  MUX_Stp <= Stp(1) when SelStp = '0' else Stp(0);
  -- MUX Parity
  MUX_Pty <= Pty    when SelPty = '0' else MUX_Stp;
  -- MUX D7
  MUX_D7  <= D7     when SelD7 = '0'  else MUX_Pty;

  -- Process fuer die (12) FF 
  process(clk, clr_n)
  begin
    if clr_n = '0' then
      Stp  <= (others => '0');
      Pty  <= '0';
      D7   <= '0';
      Sta  <= '0';
      D6_0 <= (others => '0');
    elsif clk'event and clk = '1' then
      if EnStp = '1' then               -- Stopbit- FFs
        Stp(0) <= RxTmp2;
        Stp(1) <= Stp(0);
      end if;
      if EnPty = '1' then               -- Parity- FF
        Pty <= MUX_Stp;
      end if;
      if EnD7 = '1' then                -- D7 - FF
        D7 <= MUX_Pty;
      end if;
      if EnD6_0 = '1' then              -- D6...D0 - FFs
        D6_0 <= MUX_D7 & D6_0(6 downto 1);
      end if;
      if EnSta = '1' then               -- Startbit FF
        Sta <= D6_0(0);
      end if;
    end if;
  end process;

  -- Parity Generator
  Parity  <= D7 xor D6_0(6) xor D6_0(5) xor D6_0(4) xor D6_0(3) xor D6_0(2) xor D6_0(1) xor D6_0(0);
  StpOut  <= Stp;
  PtyOut  <= Pty;
  StaOut  <= Sta;
  DoutPar <= D7 & D6_0;

  
end Rtl;




