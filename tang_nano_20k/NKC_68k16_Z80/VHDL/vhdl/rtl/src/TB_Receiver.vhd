-- -----------------------------------------------
-- Title:    Uebung 3
-- file:     TB_Receiver.vhd
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
use IEEE.math_real.all;
use work.UARTGlobal.all;

entity RS_232_RX is
  port(RX : in std_ulogic);
end RS_232_RX;


--------------------- Architecture --------------------------------------

architecture behav of RS_232_RX is
  
  file cmd_file           : text;
  file logfile            : text;
  signal Settings         : UART_Settings_t;
  signal bitclk           : std_ulogic := '0';
  signal RXByte           : DataByte_t;
  signal RealBaudRate     : natural;
  signal StartBitDetected : std_ulogic := '0';

  procedure WriteFile(file logfile : text; msg : string) is
    variable l : line;
  begin
    write(l, string'(msg));
    writeline(logfile, l);
  end;

  -- Ein Datenbyte von RX mit der eingestellten Baudrate einlesen
  procedure ReadDataByte(signal RX : in std_ulogic; signal SB : out std_ulogic;
                         file logfile : text; DataByte : out DataByte_t; good : out boolean) is
    variable b      : unsigned(Settings.Databits-1 downto 0);
    variable ti     : time       := 1000000 us /(Settings.Baudrate);
    variable bitstr : string (3 downto 1);
    variable len    : integer    := time'image(now/1000)'length;
    variable Parity : std_ulogic := '0';
    variable l      : line;
  begin
    good  := true;
    write(l, now/(1000 ns), right, 8);	-- akt. Simulationszeit in uS protokollieren
    write(l, string'(" | "));
    wait for ti/2;
    SB <= '0';                          -- signalisieren dass das Startbit nun
                                        -- erkannt wurde => Steigende Flanke
                                        -- dieses Signals wertet der Baudrate
                                        -- Process aus (Beginn der Messung)
    if RX = '1' then                    -- Startbit muss low sein
      write(l, string'("Wrong Startbit detected"));
      good := false;
      writeline(logfile, l);
      return;
    end if;

    -- Alle Datenbits einlesen
    for i in 0 to Settings.DataBits-1 loop
      wait for ti;
      b                      := b srl 1;
      b(Settings.DataBits-1) := RX;
      Parity                 := Parity xor RX;  -- Parity Bit berechnen
    end loop;

    -- ev. Paritybit einlesen (Even oder ODD)
    if Settings.Parity /= 'n' and Settings.Parity /= 'N' then
      if Settings.Parity = 'o' or Settings.Parity = 'O' then
        Parity := not Parity;
      end if;
      wait for ti;
      if Parity /= RX then
        write(l, string'("Wrong Paritytbit detected"));
        good := false;
        writeline(logfile, l);
        return;
      end if;
      bitstr := string'(std_ulogic'image(Parity));
    else
      bitstr := " - ";
    end if;

    -- Alle eingestellten Stopbits einlesen
    for i in 1 to Settings.StopBits loop
      wait for ti;
      if RX = '0' then
        write(l, string'("Wrong Stopbit detected"));
        good := false;
        writeline(logfile, l);
        exit;
      end if;
    end loop;

-- Baudrate darf max. um +- 10% von der eingestellten abweichen    
    if real(RealBaudRate)>(real(Settings.Baudrate)*1.1) or 
       real(RealBaudRate)<(real(Settings.Baudrate)*0.9) then
    	    write(l,string'("Wrong Baudrate detected - simulation stopped"));
        good := false;
        writeline(logfile, l);
        return;
    end if;

    -- Alles nun Loggen 
    DataByte := to_integer(b);
    write(l, string'(integer'image(to_integer(b))), right, 9);
    write(l, string'("| "),right,8);
    write(l, bitstr(2), right, 3);
    write(l, string'("| "),right,6);
    write(l, string'(natural'image(RealBaudRate)), right, 9);
    writeline(logfile, l);
  end;
  
begin

  -- Erzeugen eines Bittaktes zur Kontrolle
  process(bitclk, Settings) is
  begin
    if Settings.Baudrate /= 0 then
      bitclk <= not bitclk after 1000000000 ns/(2*Settings.Baudrate);
    end if;
  end process;

  -- Prozess zum berechnen der Baudrate
  process is
    variable startbit           : time;
    variable NrOfBits           : real;
    variable PulseTime, BitTime : time;
    variable RealBitTime        : integer;
  begin
    wait until StartBitDetected = '1';  -- auf das Startbit warten
    startbit     := now;
    wait until RX'event and RX = '1';   -- auf die nächste steigende
                                        -- Flanke warten
    PulseTime    := now - startbit;
    BitTime      := 1000000000 ns/(Settings.Baudrate);
    NrOfBits     := real(PulseTime / 1 ns)/real(BitTime /1 ns);
    RealBitTime  := (PulseTime / 1 ns)/integer(round(NrOfBits));
    RealBaudRate <= 1000000000 /RealBitTime;  -- Die wirkliche Baudrate berechnen
  end process;

  -- Receiver- Hauptprozess 
  process
    variable inline   : line;
    variable good     : boolean;
    variable DataByte : DataByte_t;

  begin
    file_open(cmd_file, INIFILENAME, read_mode);
    ReadNextLine(cmd_file, inline);      -- Die erste datenzeile einlesen
    ProcessFirstLine(inline, Settings);  -- und daraus Baudrate,
                                         -- Datenbits,Parity etc. extrahieren

    file_open(logfile, "out.log",write_mode);

    WriteFile(logfile, "Time[us] | Data (decimal) | Parity | Baudrate (avg.)");
    WriteFile(logfile, "---------+----------------+--------+----------------");

    good := true;
    while(good) loop
      wait until RX'event and RX = '0';  -- auf das Startbit warten
      StartBitDetected <= '1';
      ReadDataByte(RX, StartBitDetected, logfile, DataByte, good);  -- So lange Datenzeilen einlesen und verarbeiten bis
      assert good report "Read of DataByte failed" severity failure;
      RXByte           <= DataByte;
    end loop;

    file_close(cmd_file);
    report "End of Program reached" severity failure;
    wait;
  end process;

end;




















