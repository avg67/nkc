-- -----------------------------------------------
-- Title:    Uebung 4
-- file:     BaudRateGen9600.vhd
-- language: VHDL 93
-- author:       HSSE / Andreas Voggeneder
-- comments: 
-- history: 
--   04.2002 creation
-- -----------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
--use work.DffGlobal.all;


entity BaudRateGen9600 is
  generic (Stages : integer := 13;      -- Anzahl der Zaehlerstufen. Default 13
--  generic (Stages : integer := 14;      -- Anzahl der Zaehlerstufen. Default 14
           Divider : integer :=5000 );  -- Clock Teiler f�r 9600 Baud
--           Divider : integer :=10000 );  -- Clock Teiler f�r 9600 Baud           
  port(clk  : in std_ulogic;
       clr_n  : in std_ulogic;
       Baud : out std_ulogic);
end entity BaudRateGen9600;

architecture Rtl of BaudRateGen9600 is
  signal q : unsigned(Stages-1 downto 0);
  
begin
  -- Baudrate Takt erzeugen (=>Impuls)
  process(clk, clr_n)
  begin
    if clr_n = '0' then
      q <= (others => '0');             -- Reset Condition
      Baud<='0';
    elsif clk'event and clk = '1' then
      if q /= to_unsigned(Divider-1,Stages) then
        q <= q+1;                       -- Zaehlen
        Baud<='0';                           
      else
        q <= (others => '0');
        Baud<='1';                      -- Einen Impuls der einen Taktzyklus
                                        -- lang ist erzeugen (Enable fuer FF) 
      end if;
    end if;
  end process;

 
end Rtl;






