-- -----------------------------------------------
-- Title:    Uebung 02,03
-- file:     UARTGlobal.vhd
-- language: VHDL 93
-- author:       HSSE / Andreas Voggeneder
-- comments: Package declaration
-- history: 
--   03.2002 creation
-- -----------------------------------------------


library IEEE;
use std.textio.all;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package UARTGlobal is
--  constant INIFILENAME : string := "U:\RES1\ue3\CMD.DAT";
  constant INIFILENAME : string    := "UARTINIT.DAT";
  constant MINBAUD : natural := 1000;
  constant MAXBAUD : natural := 128000;
  
  type UART_Settings_t is
    record
      BaudRate : natural;
      DataBits : natural;
      StopBits : natural;
      Parity   : character;
    end record;
  type    Symbol_t is array (1 to 2) of character;
  subtype DataByte_t is natural range 0 to 255;

  procedure ltrim(l : inout line);
  procedure ReadNextLine(file cmd_file :text;NextLine : out line);
  procedure ProcessFirstLine (InLine : inout line; signal s : out UART_Settings_t);
  function IsTBDataByte(s : in symbol_t) return boolean;
  function IsTBZycles(s : in symbol_t) return boolean;
  function IsTBComment(s : in symbol_t) return boolean;  
  procedure ReadSym ( l : inout line; sym : out symbol_t);
  
end package UARTGlobal;  

package body UARTGlobal is
  -- Entfernt fuehrende white spaces
  procedure ltrim(l : inout line) is
    variable good : boolean;
    variable ch   : character;
  begin
    -- Alle Leerzeichen und Tabs überlesen
    while(l'length > 0 and (l(1) = ' ' or l(1) = ht)) loop
      read(l, ch, good);
    end loop;
  end;


  -- Liest die naechste Datenzeile ein (Kommentarzeilen und Leerzeilen werden ueberlesen)
  procedure ReadNextLine(file cmd_file :text;NextLine : out line)is
    variable inline : line;
  begin
    while(not(endfile(cmd_file))) loop
      readline(cmd_file, inline);
      ltrim(inline);                        -- fuehrende Leerzeichen entfernen
      if inline'length = 1 or (inline'length >= 2 and (inline(1) /= '-' or inline(2) /= '-')) then
        exit;
      end if;
    end loop;
    NextLine := inline;                     -- Zeile zurueckgeben
  end;

  -- Auswerten der ersten Datenzeile in der Steuerdatei (Baudrate, Datenbits,
  -- Parity, Stopbits)
  procedure ProcessFirstLine (InLine : inout line; signal s : out UART_Settings_t) is
    variable good    : boolean;
    variable nr      : natural;
    variable ch, spc : character;
  begin
    read(InLine, nr, good);
    assert good report "Read of Databits failed" severity failure;
    assert nr = 7 or nr = 8 report "Invalid number of Databits" severity failure;
    report "Databits: " & natural'image(nr) severity note;
    s.Databits                  <= nr;
    ltrim(inline);
    read(InLine, nr, good);
    assert good report "Read of Stopbits failed" severity failure;
    assert (nr = 1 or nr = 2) report "Invalid number of Stopbits" severity failure;
    report "Stopbits: " & natural'image(nr) severity note;
    s.Stopbits                  <= nr;
    ltrim(inline);
    read(InLine, ch, good);
    assert good report "Read of Parity failed" severity failure;
    report "Parity: " & ch severity note;
    s.Parity                    <= ch;
    ltrim(inline);
    read(InLine, nr, good);
    assert good report "Read of Baudrate failed" severity failure;
    assert nr >= MINBAUD and nr <= MAXBAUD report "Invalid Baudrate" severity failure;
    report "Baudrate: " & natural'image(nr) severity note;
    s.Baudrate                  <= nr;
  end;

   -- Gibt TRUE zurueck wenn es sich beim akt. Symbol um ein Datenbyte handelt
  function IsTBDataByte(s : in symbol_t) return boolean is
  begin
    if (s(1) = 'd' or s(1) = 'D') and s(2) = ' ' then
      return true;
    else
      return false;
    end if;
  end;

  -- Gibt TRUE zurueck wenn es sich beim akt. Symbol um eine Wartezeit handelt
  function IsTBZycles(s : in symbol_t) return boolean is
  begin
    if (s(1) = 'i' or s(1) = 'I') and s(2) = ' ' then
      return true;
    else
      return false;
    end if;
  end;

  -- Gibt TRUE zurueck wenn es sich beim akt. Symbol um einen Kommentar handelt
  function IsTBComment(s : in symbol_t) return boolean is
  begin
    if s(1) = '-' and s(2) = '-' then
      return true;
    else
      return false;
    end if;
  end;
  
    -- Einlesen des naechsten Symbols von line
  procedure ReadSym ( l : inout line; sym : out symbol_t) is
    variable s    : symbol_t;
    variable good : boolean;
  begin
    ltrim(l);
    for i in s'left to s'right loop
      read(l, s(i), good);              -- alle zum Symbol gehoerenden Zeichen einlesen
      assert good report "Read of Symbol Failed" severity failure;
    end loop;  -- i
    sym := s;
  end;


end package body UARTGlobal;  







