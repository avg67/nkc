-- -----------------------------------------------
-- Title:    ControlDataPathBroad
-- file:     ControlDataPath.vhd
-- language: VHDL 93
-- author:       HSSE / Andreas Voggeneder
-- comments: Steuerwerk f. DataPath TX
-- history: 
--   01.2002 creation
-- -----------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.DffGlobal.all;

entity ControlDataPathBroad is
  port(clk       : in  std_ulogic;
       clr_n     : in  std_ulogic;
       Baud      : in  std_ulogic;
       DataValid : in  std_ulogic;
       Busy      : out std_ulogic;                     --0
       SelSp0    : out std_ulogic;                     --1
       SelPty    : out std_ulogic;                     --2
       SelD7     : out std_ulogic_vector(1 downto 0);  --3,4
       SelD6_0   : out std_ulogic_vector(1 downto 0);  --5,6
       SelSta    : out std_ulogic;                     --7
       SelOddPty : out std_ulogic;                     --8
       EnStp     : out std_ulogic;                     --9
       EnPty     : out std_ulogic;                     --10
       EnD7      : out std_ulogic;                     --11
       EnD6_0    : out std_ulogic;                     --12
       EnSta     : out std_ulogic);                    --13
end ControlDataPathBroad;

architecture MealyFsm of ControlDataPathBroad is
  type    state_t is (S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11);
  subtype output_t is std_ulogic_vector(13 downto 0);
  signal  state, next_state : state_t;
  signal  output            : output_t;
begin

  -- Mealy- FSM Zustandsregister
  fsm_reg : process(clr_n, Clk, Baud)
  begin
    if clr_n = activated_cn then
      state <= S11;                     -- Bei reset in den Idle State gehen
    elsif clk'event and clk = '1' then
      if Baud = '1' then
        state <= next_state;
      end if;
    end if;
  end process;

  -- NextState und Ausgang berechnen
  fsm_comp : process(DataValid, state )
  begin
    next_state <= state;
    output     <= (others => '0');
    case state is
      when S0 => if DataValid = '1' then
                   output     <= "11101-10010-10";
                   next_state <= S1;
                 else
                   output     <= "00000--------0";
                   next_state <= S0;
                 end if;
      when S1 => next_state <= S2;
                 output <= "11000-001----1";
      when S2 => next_state <= S3;
                 output <= "11010-011----1";
      when S3 => next_state <= S4;
                 output <= "11010-011----1";
      when S4 => next_state <= S5;
                 output <= "11010-011----1";
      when S5 => next_state <= S6;
                 output <= "11010-011----1";
      when S6 => next_state <= S7;
                 output <= "11010-011----1";
      when S7 => next_state <= S8;
                 output <= "11010-011----1";
      when S8 => next_state <= S9;
                 output <= "11010-011----1";
      when S9 => next_state <= S10;
                 output <= "11010-011----1";
      when S10 => next_state <= S0;
                 output <= "11010-011----1";
      when S11 => next_state <= S0;
                  output <= "00000--------1";
      when others => null;
    end case;
  end process;

  -- Die wirklichen Ausgänge mappen
  Busy      <= output(0);
  SelSp0    <= output(1);
  SelPty    <= output(2);
  SelD7     <= output(4)& output(3);
  SelD6_0   <= output(6)& output(5);
  SelSta    <= output(7);
  SelOddPty <= output(8);
  EnStp     <= output(9) and Baud;
  EnPty     <= output(10) and Baud;
  EnD7      <= output(11) and Baud;
  EnD6_0    <= output(12) and Baud;
  EnSta     <= output(13) and Baud;


end MealyFsm;



