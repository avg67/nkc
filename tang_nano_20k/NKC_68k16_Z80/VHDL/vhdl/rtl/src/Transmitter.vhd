-- -----------------------------------------------
-- Title:    Uebung 7
-- file:     UART.vhd
-- language: VHDL 93
-- author:       HSSE / Andreas Voggeneder
-- comments: Unit Transmitter
-- history: 
--   04.2002 creation
-- -----------------------------------------------


library IEEE;
library Work;
--library BaudRateGen9600;
--library DataPathBroad;
--library Receiver;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Transmitter is
  port(clk         : in  std_ulogic;
       clr_n       : in  std_ulogic;
       TxD         : out std_ulogic;
       Busy        : out std_ulogic;
       DinPar      : in  std_ulogic_vector(7 downto 0);
       DataValid   : in  std_ulogic);
end entity Transmitter;

architecture Rtl of Transmitter is
  signal Baud                                : std_ulogic;
--  signal DataBus                                              : std_ulogic_vector(7 downto 0);
  signal SelSp0, SelPty                                       : std_ulogic;
  signal SelD7, SelD6_0                                       : std_ulogic_vector(1 downto 0);
  signal SelSta, SelOddPty, EnStp, EnPty, EnD7, EnD6_0, EnSta : std_ulogic;
--  signal ErrorFlags                                           : std_ulogic_vector(1 downto 0);
begin

  BaudGen : entity work.BaudRateGen9600(Rtl)  -- Baudrate Generator
    port map (clk   => clk,
              clr_n => clr_n,
              Baud  => Baud);

--  Rec : entity Receiver.Receiver(Rtl)   --  Datenquelle
--    port map (clk        => clk,
--              clr_n      => clr_n,
--              RxD        => RxD,
--              Busy       => Busy,
--              DOutPar    => DataBus,
--              DataValid  => DataValid,
--              ErrorFlags => ErrorFlags);

  DataPath : entity work.DataPathBroad(Rtl)        -- Datenpfad
    port map (clk       => clk,
              clr_n     => clr_n,
              DinPar    => DinPar,
              SelSp0    => SelSp0,
              SelPty    => SelPty,
              SelD7     => SelD7,
              SelD6_0   => SelD6_0,
              SelSta    => SelSta,
              SelOddPty => SelOddPty,
              EnStp     => EnStp,
              EnPty     => EnPty,
              EnD7      => EnD7,
              EnD6_0    => EnD6_0,
              EnSta     => EnSta,
              TxD       => TxD);     
  ControlPath : entity Work.ControlDataPathBroad(MealyFsm)  -- Controlpfad
--  ControlPath : entity Work.ControlDataPathBroad(MooreFsm)  -- Controlpfad
--  ControlPath : entity Work.ControlDataPathBroad(MedwedevFsm)  -- Controlpfad
    port map (clk       => clk,
              clr_n     => clr_n,
              Baud      => Baud,
              DataValid => DataValid,
              Busy      => Busy,
              SelSp0    => SelSp0,
              SelPty    => SelPty,
              SelD7     => SelD7,
              SelD6_0   => SelD6_0,
              SelSta    => SelSta,
              SelOddPty => SelOddPty,
              EnStp     => EnStp,
              EnPty     => EnPty,
              EnD7      => EnD7,
              EnD6_0    => EnD6_0,
              EnSta     => EnSta);   

--  FrameError  <= ErrorFlags(1);
--  ParityError <= ErrorFlags(0);
end Rtl;
