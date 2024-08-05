-- -----------------------------------------------
-- Title:    ControlReceiver
-- file:     ControlReceiver.vhd
-- language: VHDL 93
-- author:       HSSE / Andreas Voggeneder
-- comments: Steuerwerk f. Empfänger als Mealy FSM
-- history: 
--   06.2002 creation
-- -----------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.DffGlobal.all;

entity ControlReceiver is
  port(clk        : in  std_ulogic;
       clr_n      : in  std_ulogic;
       Baud       : in  std_ulogic;
       BaudSync   : in  std_ulogic;
       Busy       : in  std_ulogic;
       Stp        : in  std_ulogic_vector(1 downto 0);
       Pty        : in  std_ulogic;
       Sta        : in  std_ulogic;
       Parity     : in  std_ulogic;
       DataValid  : out std_ulogic;     --0
       SelStp     : out std_ulogic;     --1
       SelPty     : out std_ulogic;     --2
       SelD7      : out std_ulogic;     --3
       EnPty      : out std_ulogic;     --4
       EnD7       : out std_ulogic;     --5
       EnD6_0     : out std_ulogic;     --6
       EnSta      : out std_ulogic;     --7
       EnStp      : out std_ulogic;     --8
       ErrorFlags : out std_ulogic_vector(1 downto 0));  
end ControlReceiver;

architecture MealyFsm of ControlReceiver is
  type    state_t is (S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S11, S12, S13);
  subtype output_t is std_ulogic_vector(9 downto 0);
  signal  state, next_state : state_t;
  signal  output            : output_t;
  signal  SelOddPty         : std_ulogic;
begin

  -- Mealy- FSM Zustandsregister
  fsm_reg : process(clr_n, Clk)
  begin
    if clr_n = activated_cn then
      state <= S0;                      -- Bei reset in den Idle State gehen
    elsif clk'event and clk = '1' then
      state <= next_state;
    end if;
  end process;

  -- NextState und Ausgang berechnen
  fsm_comp : process(BaudSync, state, Busy, Baud )
  begin
    next_state <= state;
    output     <= (others => '0');
    case state is
      when S0 => if BaudSync = '1' then  -- Auf Startbit warten
                   output     <= "-111100110";
                   next_state <= S1;
                 else
                   output     <= "-00000---0";
                   next_state <= S0;
                 end if;
      when S1 => if Baud = '1' then      -- Sta
                   next_state <= S2;
                 end if;
                 output <= "-111100110";
      when S2 => if Baud = '1' then      -- D0
                   next_state <= S3;
                 end if;
                 output <= "-111100110";
      when S3 => if Baud = '1' then      -- D1
                   next_state <= S4;
                 end if;
                 output <= "-111100110";
      when S4 => if Baud = '1' then      -- D2
                   next_state <= S5;
                 end if;
                 output <= "-111100110";
      when S5 => if Baud = '1' then      -- D3
                   next_state <= S6;
                 end if;
                 output <= "-111100110";
      when S6 => if Baud = '1' then      -- D4
                   next_state <= S7;
                 end if;
                 output <= "-111100110";
      when S7 => if Baud = '1' then      -- D5
                   next_state <= S8;
                 end if;
                 output <= "-111100110";
      when S8 => if Baud = '1' then      -- D6
                   next_state <= S9;
                 end if;
                 output <= "-111100110";
      when S9 => if Baud = '1' then      -- D7
                   next_state <= S11;
                 end if;
                 output <= "-111100110";
--      when S10 => if Baud = '1' then     -- Pty
--                    next_state <= S11;
--                  end if;
--                  output <= "-111100110";
      when S11 => if Baud = '1' then     -- Stp
                    next_state <= S12;
                  end if;
                  output <= "-111100110";
      when S12 => if Busy = '1' then
                    next_state <= S12;   -- Datenübergabe, warten auf not Busy
                    output     <= "-00000---0";
                  else
                    next_state <= S13;   -- Datenübergabe. DataValid='1'
                    output     <= "-00000---1";
                  end if;
      when S13 => if Busy = '1' then
                    next_state <= S0;    -- Datenübergabe, warten auf Busy
                    output     <= "-00000---0";
                  else
                    next_state <= S13;   -- Datenübergabe. DataValid='1'
                    output     <= "-00000---1";
                  end if;
      when others => null;
    end case;
  end process;

  -- Die wirklichen Ausgänge mappen  
  DataValid <= output(0);
  SelStp    <= output(1);
  SelPty    <= output(2);
  SelD7     <= output(3);
  EnPty     <= output(4) and Baud;
  EnD7      <= output(5) and Baud;
  EnD6_0    <= output(6) and Baud;
  EnSta     <= output(7) and Baud;
  EnStp     <= output(8) and Baud;
  SelOddPty <= output(9);

  -- Check ob Framing Fehler oder Parity Fehler
  Error_reg : process(clr_n, Clk)
  begin
    if clr_n = activated_cn then
      ErrorFlags <= (others => '0');
    elsif clk'event and clk = '1' then
      if state = S13 then               -- Erst checken wenn Empfang der Daten
                                        -- abgeschlossen
        ErrorFlags(0) <= Parity xor SelOddPty xor Pty;
        ErrorFlags(1) <= not Stp(0) or Sta;  -- Framing Fehler (Startbit oder Stopbit falsch)
      end if;
    end if;
  end process;


end MealyFsm;



