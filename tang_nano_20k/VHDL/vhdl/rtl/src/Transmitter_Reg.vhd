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

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.DffGlobal.all;

entity Transmitter is
  port(clk         : in  std_ulogic;
       clr_n       : in  std_ulogic;
       TxD         : out std_ulogic;
       Busy        : out std_ulogic;
       DinPar      : in  std_ulogic_vector(7 downto 0);
       DataValid   : in  std_ulogic);
end entity Transmitter;

architecture Rtl of Transmitter is
  signal Baud                                                 : std_ulogic;
  signal SelSp0, SelPty                                       : std_ulogic;
  signal SelD7, SelD6_0                                       : std_ulogic_vector(1 downto 0);
  signal SelSta, SelOddPty, EnStp, EnPty, EnD7, EnD6_0, EnSta : std_ulogic;
  signal TXDataReg                                            : std_ulogic_vector(7 downto 0);
  signal TXDataRegValid                                       : std_ulogic;
  signal TXBusy,TXBusyOld                                     : std_ulogic;
  
begin

  BaudGen : entity work.BaudRateGen9600(Rtl)  -- Baudrate Generator
    port map (clk   => clk,
              clr_n => clr_n,
              Baud  => Baud);

  DataPath : entity work.DataPathBroad(Rtl)        -- Datenpfad
    port map (clk       => clk,
              clr_n     => clr_n,
              DinPar    => TXDataReg, --DinPar,
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
  ControlPath : entity Work.ControlDataPathBroad(MooreFsm)  -- Controlpfad
    port map (clk       => clk,
              clr_n     => clr_n,
              Baud      => Baud,
              DataValid => TXDataRegValid,
              Busy      => TXBusy,
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

  -- Input Register handling
  process(clr_n,clk)
  begin
    if clr_n = activated_cn then
      TXDataReg      <= (others =>'0');
      TXDataRegValid <= '0';
      TXBusyOld      <= '0';
    elsif clk'event and clk='1' then
      TXBusyOld <= TXBusy;
      if DataValid='1' and TXDataRegValid='0' then
        TXDataReg      <= DinPar;
        TXDataRegValid <= '1';
      elsif TXDataRegValid='1' and TXBusy='1' and TXBusyOld='0' then
        TXDataRegValid <= '0';
      end if;
    end if;
  end process;

  Busy <= TXDataRegValid;
  
end Rtl;
