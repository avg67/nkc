-- -----------------------------------------------
-- Title:    Uebung 8
-- file:     Receiver.vhd
-- language: VHDL 93
-- author:       HSSE / Andreas Voggeneder
-- comments: RS232- Receiver 9600 Baud
-- history: 
--   04.2002 creation
-- -----------------------------------------------


library IEEE;
library Work;
--library DataPathRX;
--library BaudRateGenRX9600;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Receiver is
  port(clk        : in  std_ulogic;
       clr_n      : in  std_ulogic;
       RxD        : in  std_ulogic;
       Busy       : in  std_ulogic;
       DoutPar    : out std_ulogic_vector(7 downto 0);
       DataValid  : out std_ulogic;
       ErrorFlags : out std_ulogic_vector(1 downto 0));
end entity Receiver;

architecture Rtl of Receiver is
  signal Baud                               : std_ulogic;
  signal SelStp, SelPty, SelD7, EnPty       : std_ulogic;
  signal EnD7, EnD6_0, EnSta, EnStp, PtyOut : std_ulogic;
  signal StaOut, Parity, BaudSync           : std_ulogic;
  signal StpOut                             : std_ulogic_vector(1 downto 0);
begin
  RXDataPath : entity work.DataPathBroadRX(Rtl)
    port map ( clk      => clk,
               clr_n    => clr_n,
               RxD      => RxD,
               SelStp   => SelStp,
               SelPty   => SelPty,
               SelD7    => SelD7,
               EnPty    => EnPty,
               EnD7     => EnD7,
               EnD6_0   => EnD6_0,
               EnSta    => EnSta,
               EnStp    => EnStp,
               StpOut   => StpOut,
               PtyOut   => PtyOut,
               StaOut   => StaOut,
               DoutPar  => DoutPar,
               Parity   => Parity,
               BaudSync => BaudSync); 

  BaudRateGen : entity work.BaudRateGenRX9600(Rtl)
    port map (clk      => clk,
              clr_n    => clr_n,
              BaudSync => BaudSync,
              Baud     => Baud);

  ControlPath : entity Work.ControlReceiver(MealyFsm)
    port map (clk        => clk,
              clr_n      => clr_n,
              Baud       => Baud,
              SelStp     => SelStp,
              SelPty     => SelPty,
              SelD7      => SelD7,
              EnPty      => EnPty,
              EnD7       => EnD7,
              EnD6_0     => EnD6_0,
              EnSta      => EnSta,
              EnStp      => EnStp,
              Stp        => StpOut,
              Pty        => PtyOut,
              Sta        => StaOut,
              Parity     => Parity,
              BaudSync   => BaudSync,
              Busy       => Busy,
              DataValid  => DataValid,
              ErrorFlags => ErrorFlags);

end Rtl;














