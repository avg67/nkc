-- -----------------------------------------------
-- Title:    Uebung 2
-- file:     TestEnv.vhd
-- language: VHDL 93
-- author:       HSSE / Andreas Voggeneder
-- comments: 
-- history: 
--   03.2002 creation
-- -----------------------------------------------

library IEEE;
use std.textio.all;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.UARTGlobal.all;

entity RS_232_TX is
  port(TX : out std_ulogic);
end RS_232_TX;


--------------------- Architecture --------------------------------------

architecture behav of RS_232_TX is

  file cmd_file    : text;
  signal  Settings : UART_Settings_t;
  signal  bitclk   : std_ulogic := '0';
  signal  TXBit    : std_logic:='1';
  signal  TXByte   : DataByte_t;



  -- gibt das Byte nr mit der Baudrate Settings.Baudrate seriell auf Txd aus
  procedure Serialize(nr : in DataByte_t; signal Txd : out std_ulogic) is
    variable outval : std_ulogic_vector(Settings.DataBits-1 downto 0);
    variable ti     : time       := 1000000 us /(Settings.Baudrate);
    variable Parity : std_ulogic := '0';
  begin
    outval := std_ulogic_vector(to_unsigned(nr, Settings.DataBits));
    Txd    <= '0';                      -- Startbit ausgeben
    wait for ti;
    for i in 0 to Settings.DataBits-1 loop
      Txd    <= outval(i);              -- Datenbit ausgeben
      Parity := Parity xor outval(i);   -- Parity Bit berechnen
      wait for ti;
    end loop;
    if Settings.Parity /= 'n' and Settings.Parity /= 'N' then
      if Settings.Parity = 'o' or Settings.Parity = 'O' then
        Parity := not Parity;
      end if;
      Txd <= Parity;                    -- Parity Bit ausgeben
      wait for ti;
    end if;
    Txd <= '1';                         -- Stopbit
    wait for ti*Settings.StopBits;
  end;

  -- Verarbeiten der Kommandos in Line
  procedure ProcessDataLine(l : inout line; signal Txd : out std_ulogic; signal TxByte : out DataByte_t) is
    variable s    : symbol_t;
    variable good : boolean;
    variable nr   : natural;
    variable byte : DataByte_t;
  begin
    while(l'length > 0) loop
      ReadSym(l, s);
      if IsTBDataByte(s) then           -- Beginn eines Datenbytes ?
        read(l, byte, good);
        assert good report "Read of DataByte failed" severity failure;
        assert byte >= DataByte_t'low and byte <= 2**(Settings.DataBits)-1 report "Invalid Databyte" severity failure;
        report "Output: " & natural'image(byte) severity note;
        TxByte                                 <= byte;  -- zur Kontrolle auch das Datenbyte auf
                                        -- ein Signal ausgeben (bessere
                                        -- Kontrollmoeglichkeit bei der Wave)
        Serialize(byte, Txd);
      elsif IsTBZycles(s) then          -- Beginn einer Wartezeit ?
        read(l, nr, good);
        assert good report "Read of Zycles failed" severity failure;
        report "Waiting for "& natural'image(nr) &" Cycles" severity note;
        wait for nr*1000000000 ns/(Settings.Baudrate);
      elsif IsTBComment(s) then         -- Kommentar am Ende der Zeile ?
        exit;
      else
        report "Syntax Error in Commandfile" severity failure;
      end if;
    end loop;
  end;



begin

  -- Erzeugen eines Bittaktes zur Kontrolle
  process(bitclk, Settings) is
  begin
    if Settings.Baudrate /= 0 then
      bitclk <= not bitclk after 1000000000 ns/(2*Settings.Baudrate);
    end if;
  end process;


  process
    variable inline : line;
  begin
    file_open(cmd_file, INIFILENAME, read_mode);
    ReadNextLine(cmd_file,inline);                -- Die erste datenzeile einlesen
    ProcessFirstLine(inline, Settings);  -- und daraus Baudrate,
                                         -- Datenbits,Parity etc. extrahieren

    wait on Settings;                   -- warten bis die Settings uebernommen sind
    while(not(endfile(cmd_file))) loop  -- So lange Datenzeilen einlesen und verarbeiten bis
      ReadNextLine(cmd_file,inline);             -- das Dateiende erreicht wurde
      ProcessDataLine(inline, TXbit, TxByte);
    end loop;
    file_close(cmd_file);
    report "End of command file reached" severity failure;
    wait;
  end process;


  TX <= TXbit;
end;
