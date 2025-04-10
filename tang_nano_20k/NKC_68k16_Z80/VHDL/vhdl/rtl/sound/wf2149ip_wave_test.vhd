----------------------------------------------------------------------
----                                                              ----
---- YM2149 compatible sound generator.                           ----
----                                                              ----
---- This file is part of the SUSKA ATARI clone project.          ----
---- http://www.experiment-s.de                                   ----
----                                                              ----
---- Description:                                                 ----
---- Model of the ST or STE's YM2149 sound generator.             ----
----                                                              ----
---- Waveform generator.                                          ----
----                                                              ----
----                                                              ----
---- To Do:                                                       ----
---- -                                                            ----
----                                                              ----
---- Author(s):                                                   ----
---- - Wolfgang Foerster, wf@experiment-s.de; wf@inventronik.de   ----
----                                                              ----
----------------------------------------------------------------------
----                                                              ----
---- Copyright (C) 2006 Wolfgang Foerster                         ----
----                                                              ----
---- This source file may be used and distributed without         ----
---- restriction provided that this copyright statement is not    ----
---- removed from the file and that any derivative work contains  ----
---- the original copyright notice and the associated disclaimer. ----
----                                                              ----
---- This source file is free software; you can redistribute it   ----
---- and/or modify it under the terms of the GNU Lesser General   ----
---- Public License as published by the Free Software Foundation; ----
---- either version 2.1 of the License, or (at your option) any   ----
---- later version.                                               ----
----                                                              ----
---- This source is distributed in the hope that it will be       ----
---- useful, but WITHOUT ANY WARRANTY; without even the implied   ----
---- warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ----
---- PURPOSE. See the GNU Lesser General Public License for more  ----
---- details.                                                     ----
----                                                              ----
---- You should have received a copy of the GNU Lesser General    ----
---- Public License along with this source; if not, download it   ----
---- from http://www.gnu.org/licenses/lgpl.html                   ----
----                                                              ----
----------------------------------------------------------------------
-- 
-- Revision History
-- 
-- Revision 2K6A  2006/06/03 WF
--   Initial Release.
-- Revision 2K6B    2006/11/07 WF
--   Modified Source to compile with the Xilinx ISE.
--

library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.wf2149ip_pkg.all;

entity WF2149IP_WAVE is
    port(
        RESETn      : in std_ulogic;
        SYS_CLK     : in std_ulogic;

        WAV_STRB    : in std_ulogic;

        ADR         : in std_ulogic_vector(3 downto 0);
        DATA_IN     : in std_ulogic_vector(7 downto 0);
        DATA_OUT    : out std_ulogic_vector(7 downto 0);
        DATA_EN     : out std_ulogic;
        
        BUSCYCLE    : in BUSCYCLES_t;
        CTRL_REG    : in std_ulogic_vector(5 downto 0);

--        OUT_A       : out std_ulogic;
--        OUT_B       : out std_ulogic;
--        OUT_C       : out std_ulogic;
        OUT_SUM     : out std_ulogic
    );
end entity WF2149IP_WAVE;

architecture BEHAVIOR of WF2149IP_WAVE is
signal FREQUENCY_A  : unsigned(11 downto 0);
signal FREQUENCY_B  : unsigned(11 downto 0);
signal FREQUENCY_C  : unsigned(11 downto 0);
signal NOISE_FREQ   : unsigned(4 downto 0);
signal LEVEL_A      : std_ulogic_vector(4 downto 0);
signal LEVEL_B      : std_ulogic_vector(4 downto 0);
signal LEVEL_C      : std_ulogic_vector(4 downto 0);
signal ENV_FREQ     : std_ulogic_vector(15 downto 0);
signal ENV_SHAPE    : std_ulogic_vector(3 downto 0);
signal ENV_RESET    : boolean;
signal ENV_STRB     : std_ulogic;
signal OSC_A_OUT    : std_ulogic;
signal OSC_B_OUT    : std_ulogic;
signal OSC_C_OUT    : std_ulogic;
signal NOISE_OUT    : std_ulogic;
signal AUDIO_A      : std_ulogic;
signal AUDIO_B      : std_ulogic;
signal AUDIO_C      : std_ulogic;
signal VOL_ENV      : unsigned(4 downto 0);
signal AMPLITUDE_A  : std_ulogic_vector(4 downto 0);
signal AMPLITUDE_B  : std_ulogic_vector(4 downto 0);
signal AMPLITUDE_C  : std_ulogic_vector(4 downto 0);
signal VOLUME_A     : std_ulogic_vector(7 downto 0);
signal VOLUME_B     : std_ulogic_vector(7 downto 0);
signal VOLUME_C     : std_ulogic_vector(7 downto 0);
--signal PWM_RAMP     : unsigned(7 downto 0);
signal SUM_VOL      : std_ulogic_vector(7 downto 0);
signal cnt          : natural range 0 to 2;
signal VOLUME_ABC   : std_ulogic_vector(7 downto 0);
signal AMPLITUDE_ABC: std_ulogic_vector(4 downto 0);
begin
    REGISTERS: process(RESETn, SYS_CLK)
    -- This process is responsible for initialisation
    -- and write access to the configuration registers.
    begin
        if RESETn = '0' then
            FREQUENCY_A <= x"000";
            FREQUENCY_B <= x"000";
            FREQUENCY_C <= x"000";
            NOISE_FREQ <= "00000";
            LEVEL_A <= "00000";
            LEVEL_B <= "00000";
            LEVEL_C <= "00000";
            ENV_FREQ <= (others => '0');
            ENV_SHAPE <= "0000";
        elsif SYS_CLK = '1' and SYS_CLK' event then
            ENV_RESET <= false; -- Initialize signal.
            if BUSCYCLE = WRITE then
                case ADR is
                    when x"0" => FREQUENCY_A(7 downto 0)  <= unsigned(DATA_IN);
                    when x"1" => FREQUENCY_A(11 downto 8) <= unsigned(DATA_IN(3 downto 0));
                    when x"2" => FREQUENCY_B(7 downto 0)  <= unsigned(DATA_IN);
                    when x"3" => FREQUENCY_B(11 downto 8) <= unsigned(DATA_IN(3 downto 0));
                    when x"4" => FREQUENCY_C(7 downto 0)  <= unsigned(DATA_IN);
                    when x"5" => FREQUENCY_C(11 downto 8) <= unsigned(DATA_IN(3 downto 0));
                    when x"6" => NOISE_FREQ <= unsigned(DATA_IN(4 downto 0));
                    when x"8" => LEVEL_A <= DATA_IN(4 downto 0);
                    when x"9" => LEVEL_B <= DATA_IN(4 downto 0);
                    when x"A" => LEVEL_C <= DATA_IN(4 downto 0);
                    when x"B" => ENV_FREQ(7 downto 0)  <= DATA_IN;
                    when x"C" => ENV_FREQ(15 downto 8) <= DATA_IN;  
                                 ENV_RESET <= true; -- Initialize the envelope generator.
                    when x"D" => ENV_SHAPE <= DATA_IN(3 downto 0);
                    when others => null;
                end case;
            end if;
        end if;
    end process REGISTERS;

    -- Read back the configuration registers:
    DATA_OUT <= std_ulogic_vector(FREQUENCY_A(7 downto 0))           when BUSCYCLE = READ and ADR = x"0" else
                "0000" & std_ulogic_vector(FREQUENCY_A(11 downto 8)) when BUSCYCLE = READ and ADR = x"1" else
                std_ulogic_vector(FREQUENCY_B(7 downto 0))           when BUSCYCLE = READ and ADR = x"2" else
                "0000" & std_ulogic_vector(FREQUENCY_B(11 downto 8)) when BUSCYCLE = READ and ADR = x"3" else
                std_ulogic_vector(FREQUENCY_C(7 downto 0))           when BUSCYCLE = READ and ADR = x"4" else
                "0000" & std_ulogic_vector(FREQUENCY_C(11 downto 8)) when BUSCYCLE = READ and ADR = x"5" else
                "000" & std_ulogic_vector(NOISE_FREQ)                when BUSCYCLE = READ and ADR = x"6" else
                "000" & LEVEL_A                                      when BUSCYCLE = READ and ADR = x"8" else
                "000" & LEVEL_B                                      when BUSCYCLE = READ and ADR = x"9" else
                "000" & LEVEL_C                                      when BUSCYCLE = READ and ADR = x"A" else
                ENV_FREQ(7 downto 0)                                 when BUSCYCLE = READ and ADR = x"B" else
                ENV_FREQ(15 downto 8)                                when BUSCYCLE = READ and ADR = x"C" else
                x"0" & ENV_SHAPE                                     when BUSCYCLE = READ and ADR = x"D" else (others => '0');

    DATA_EN <=  '1' when BUSCYCLE = READ and ADR >= x"0" and ADR <= x"6" else
                '1' when BUSCYCLE = READ and ADR >= x"8" and ADR <= x"D" else 
                '0';

    MUSICGENERATOR: process(RESETn, SYS_CLK)
    variable CLK_DIV    : unsigned(2 downto 0);
    variable CNT_CH_A   : unsigned(11 downto 0);
    variable CNT_CH_B   : unsigned(11 downto 0);
    variable CNT_CH_C   : unsigned(11 downto 0);
    begin
        if RESETn = '0' then
            CLK_DIV := "000";
            CNT_CH_A := (others => '0');
            CNT_CH_B := (others => '0');
            CNT_CH_C := (others => '0');
            OSC_A_OUT <= '0';
            OSC_B_OUT <= '0';
            OSC_C_OUT <= '0';
        elsif SYS_CLK = '1' and SYS_CLK' event then
            if WAV_STRB = '1' then
                -- Divider by 8 for the oscillators brings in connection 
                -- with the toggle flip flops CH_x_OUT the required divider
                -- ratio of 16.
                CLK_DIV := CLK_DIV + 1;

                if CLK_DIV = "000" then
                    if FREQUENCY_A = x"000" then
                        CNT_CH_A := (others => '0');
                        OSC_A_OUT <= '0';
                    elsif CNT_CH_A = x"000" then
                        CNT_CH_A := FREQUENCY_A - 1 ;
                        OSC_A_OUT <= not OSC_A_OUT;
                    else
                        CNT_CH_A := CNT_CH_A - 1;
                    end if;

                    if FREQUENCY_B = x"000" then
                        CNT_CH_B := (others => '0');
                        OSC_B_OUT <= '0';
                    elsif CNT_CH_B = x"000" then
                        CNT_CH_B := FREQUENCY_B - 1 ;
                        OSC_B_OUT <= not OSC_B_OUT;
                    else
                        CNT_CH_B := CNT_CH_B - 1;
                    end if;

                    if FREQUENCY_C = x"000" then
                        CNT_CH_C := (others => '0');
                        OSC_C_OUT <= '0';
                    elsif CNT_CH_C = x"000" then
                        CNT_CH_C := FREQUENCY_C - 1 ;
                        OSC_C_OUT <= not OSC_C_OUT;
                    else
                        CNT_CH_C := CNT_CH_C - 1;
                    end if;
                end if;
            end if;
        end if;
    end process MUSICGENERATOR;

    NOISEGENERATOR: process(RESETn, SYS_CLK)
    -- The noise shift polynomial is taken from a template of Kazuhiro TSUJIKAWA's 
    -- (ESE Artists' factory) approach for a 2149 equivalent. But the implementation
    -- is done in another way.
    -- LFSR (linear feedback shift register polynomial: f(x) = x^17 + x^14 + 1.
    variable CLK_DIV    : unsigned(3 downto 0);
    variable CNT_NOISE  : unsigned(4 downto 0);
    variable N_SHFT     : std_ulogic_vector(16 downto 0);
    begin
        if RESETn = '0' then
            CLK_DIV := x"0";
            CNT_NOISE := (others => '1'); -- Preset the polynomial shift register.
            NOISE_OUT <= '1';
            N_SHFT    := (others => '0');
        elsif SYS_CLK = '1' and SYS_CLK' event then
            if WAV_STRB = '1' then
                -- Divider by 16 for the noise generator.
                CLK_DIV := CLK_DIV + 1;
                if CLK_DIV = x"0" then
                    -- Noise frequency counter.
                    if NOISE_FREQ = "00000" then
                        CNT_NOISE := (others => '0');
                    elsif CNT_NOISE = "00000" then
                        CNT_NOISE := NOISE_FREQ - 1 ;
                        N_SHFT := N_SHFT(15 downto 14) & not(N_SHFT(16) xor N_SHFT(13)) & 
                                                        N_SHFT(12 downto 0) & not N_SHFT(16);
                    else
                        CNT_NOISE := CNT_NOISE - 1;
                    end if;
                end if;
            end if;
            NOISE_OUT <= N_SHFT(16);
        end if;
    end process NOISEGENERATOR;

    ENVELOPE_PERIOD: process(RESETn, SYS_CLK)
    -- The envelope period is controlled by the Envelope Frequency and the divider ratio which is
    -- 256/32 = 8. For further information see the original data sheet.
      variable ENV_CLK : unsigned(18 downto 0);
      variable LOCK : boolean;
    begin
        if RESETn = '0' then
            ENV_STRB <= '0';
            ENV_CLK := (others => '0');
            LOCK := false;
        elsif SYS_CLK = '1' and SYS_CLK' event then
            if WAV_STRB = '1' and LOCK = false then
                LOCK := true;
                if ENV_FREQ = x"0000" then
                    ENV_STRB <= '0';
                elsif ENV_CLK = x"0000" & "000" then
                    ENV_CLK := unsigned(ENV_FREQ & "111") - 1 ;
                    ENV_STRB <= '1';
                else
                    ENV_CLK := ENV_CLK - 1;
                    ENV_STRB <= '0';
                end if;
            elsif WAV_STRB = '0' then
                LOCK := false;
                ENV_STRB <= '0';
            else
                ENV_STRB <= '0';
            end if;
        end if;
    end process ENVELOPE_PERIOD;
    
    ENVELOPE: process(RESETn, SYS_CLK)
    -- Envelope shapes:
    -- case ENV_SHAPE:
    --
    -- 0 0 x x  \___
    --
    -- 0 1 x x  /|___
    --
    -- 1 0 0 0  _|\|\|\|\|
    --
    -- 1 0 0 1  \___
    --
    -- 1 0 1 0  \/\/
    --            ___
    -- 1 0 1 1  \|
    --
    -- 1 1 0 0  /|/|/|/|
    --           ___
    -- 1 1 0 1  /
    --
    -- 1 1 1 0  /\/\
    --
    -- 1 1 1 1  /|___
    --
    variable ENV_STOP   : boolean;
    variable ENV_UP_DNn : std_ulogic;
    begin
        if RESETn = '0' then
            VOL_ENV <= (others => '0');
            ENV_UP_DNn := '0';
            ENV_STOP := false;
        elsif SYS_CLK = '1' and SYS_CLK' event then
            if ENV_RESET = true then
                ENV_STOP := false;
                case ENV_SHAPE is
                    when "1011" | "1010" | "1001" | "1000" | "0011" | "0010" | "0001" | "0000" =>
                        VOL_ENV <= "11111"; -- Start on top.
                        ENV_UP_DNn := '0';
                    when others =>
                        VOL_ENV <= "00000"; -- Start at bottom.
                        ENV_UP_DNn := '1';
                end case;
            elsif ENV_STRB = '1' then
                case ENV_SHAPE is
                    when "1001" | "0011" | "0010" | "0001" | "0000"  =>
                        if VOL_ENV > "00000" then
                            VOL_ENV <= VOL_ENV - 1;
                        end if;
                    when "1111" | "0111" | "0110" | "0101" | "0100"  =>
                        if VOL_ENV < "11111" and ENV_STOP = false then
                            VOL_ENV <= VOL_ENV + 1;
                        else
                            VOL_ENV <= "00000";
                            ENV_STOP := true;
                        end if;
                    when "1000" =>
                        VOL_ENV <= VOL_ENV - 1;
                    when "1110" | "1010" =>
                        if ENV_UP_DNn = '0' then
                            VOL_ENV <= VOL_ENV - 1;
                        else
                            VOL_ENV <= VOL_ENV + 1;
                        end if;
                        if VOL_ENV = "00000" then
                            ENV_UP_DNn := '1';
                        elsif VOL_ENV = "11111" then
                            ENV_UP_DNn := '0';
                        end if;
                    when "1011" =>
                        if VOL_ENV > "00000" and ENV_STOP = false then
                            VOL_ENV <= VOL_ENV - 1;
                        else
                            VOL_ENV <= "11111";
                            ENV_STOP := true;
                        end if;
                    when "1100" =>
                        VOL_ENV <= VOL_ENV + 1;
                    when "1101" =>
                        if VOL_ENV < "11111" then
                            VOL_ENV <= VOL_ENV + 1;
                        end if;
                    when others => null; -- Covers U, X, Z, W, H, L, -.
                end case;
            end if;
        end if;
    end process ENVELOPE;

    --MIXER:
    -- The mixer controls, dependant on the mixer settings, the output of the
    -- audio data for all three channels. The noise generator and the square wave
    --  generators A, B and C are mixed together by a simple boolean OR.
    AUDIO_A <= (OSC_A_OUT and not CTRL_REG(0)) or (NOISE_OUT and not CTRL_REG(3));
    AUDIO_B <= (OSC_B_OUT and not CTRL_REG(1)) or (NOISE_OUT and not CTRL_REG(4));
    AUDIO_C <= (OSC_C_OUT and not CTRL_REG(2)) or (NOISE_OUT and not CTRL_REG(5));

    --LEVEL (e.g. volume control):
    -- The linear amplitude for the DA converters of channel A, B or C are fixed
    -- (LEVEL(3 downto 0)) or delivered by the envelope generator.
    -- The following behavior is taken from the 2149 IP core of Mike J (www.fpgaarcade.com):
    -- "make sure level 31 (env) = level 15 (tone)"
    -- Thus there is a resulting & '1' modeling if LEVEL amplitudes are selected.
    AMPLITUDE_A <=  LEVEL_A(3 downto 0) & '1'   when LEVEL_A(4) = '0' and AUDIO_A = '1' else
                    std_ulogic_vector(VOL_ENV)  when LEVEL_A(4) = '1' and AUDIO_A = '1' else "00000";
    AMPLITUDE_B <=  LEVEL_B(3 downto 0) & '1'   when LEVEL_B(4) = '0' and AUDIO_B = '1' else
                    std_ulogic_vector(VOL_ENV)  when LEVEL_B(4) = '1' and AUDIO_B = '1' else "00000";
    AMPLITUDE_C <=  LEVEL_C(3 downto 0) & '1'   when LEVEL_C(4) = '0' and AUDIO_C = '1' else
                    std_ulogic_vector(VOL_ENV)  when LEVEL_C(4) = '1' and AUDIO_C = '1' else "00000";

    -- The values for the logarithmic DA converter volume controls are taken from the linear 
    -- mixer of Mike J's 2149 IP core (www.fpgaarcade.com).
    process(RESETn, SYS_CLK)
    begin
      if RESETn='0' then
        cnt      <= 0;
        VOLUME_A <= (others => '0');
        VOLUME_B <= (others => '0');
        VOLUME_C <= (others => '0');
      elsif rising_edge(SYS_CLK) then
        case cnt is
          when 0 =>
            VOLUME_A <= VOLUME_ABC;
            cnt      <= cnt + 1;
          when 1 =>
            VOLUME_B <= VOLUME_ABC;
            cnt      <= cnt + 1;
          when 2 =>
            VOLUME_C <= VOLUME_ABC;
            cnt      <= 0;
          when others => null;
        end case;           
      end if;
    end process;

    -- re-use Lookup-Table for all three channels => to save resources
    with cnt select
      AMPLITUDE_ABC <= AMPLITUDE_A when 0,
                       AMPLITUDE_B when 1,
                       AMPLITUDE_C when others;

    with AMPLITUDE_ABC select
                      VOLUME_ABC <= x"FF" when "11111",
                                    x"D9" when "11110",
                                    x"BA" when "11101",
                                    x"9F" when "11100",
                                    x"88" when "11011",
                                    x"74" when "11010",
                                    x"63" when "11001",
                                    x"54" when "11000",
                                    x"48" when "10111",
                                    x"3D" when "10110",
                                    x"34" when "10101",
                                    x"2C" when "10100",
                                    x"25" when "10011",
                                    x"1F" when "10010",
                                    x"1A" when "10001",
                                    x"16" when "10000",
                                    x"13" when "01111",
                                    x"10" when "01110",
                                    x"0D" when "01101",
                                    x"0B" when "01100",
                                    x"09" when "01011",
                                    x"08" when "01010",
                                    x"07" when "01001",
                                    x"06" when "01000",
                                    x"05" when "00111",
                                    x"04" when "00110",
                                    x"03" when "00101",
                                    x"03" when "00100",
                                    x"02" when "00011",
                                    x"02" when "00010",
                                    x"01" when "00001",
                                    x"00" when others; -- Also covers U, X, Z, W, H, L, -.


    
--    with AMPLITUDE_A select
--                        VOLUME_A <= x"FF" when "11111",
--                                    x"D9" when "11110",
--                                    x"BA" when "11101",
--                                    x"9F" when "11100",
--                                    x"88" when "11011",
--                                    x"74" when "11010",
--                                    x"63" when "11001",
--                                    x"54" when "11000",
--                                    x"48" when "10111",
--                                    x"3D" when "10110",
--                                    x"34" when "10101",
--                                    x"2C" when "10100",
--                                    x"25" when "10011",
--                                    x"1F" when "10010",
--                                    x"1A" when "10001",
--                                    x"16" when "10000",
--                                    x"13" when "01111",
--                                    x"10" when "01110",
--                                    x"0D" when "01101",
--                                    x"0B" when "01100",
--                                    x"09" when "01011",
--                                    x"08" when "01010",
--                                    x"07" when "01001",
--                                    x"06" when "01000",
--                                    x"05" when "00111",
--                                    x"04" when "00110",
--                                    x"03" when "00101",
--                                    x"03" when "00100",
--                                    x"02" when "00011",
--                                    x"02" when "00010",
--                                    x"01" when "00001",
--                                    x"00" when others; -- Also covers U, X, Z, W, H, L, -.
--
--    with AMPLITUDE_B select 
--                        VOLUME_B <= x"FF" when "11111",
--                                    x"D9" when "11110",
--                                    x"BA" when "11101",
--                                    x"9F" when "11100",
--                                    x"88" when "11011",
--                                    x"74" when "11010",
--                                    x"63" when "11001",
--                                    x"54" when "11000",
--                                    x"48" when "10111",
--                                    x"3D" when "10110",
--                                    x"34" when "10101",
--                                    x"2C" when "10100",
--                                    x"25" when "10011",
--                                    x"1F" when "10010",
--                                    x"1A" when "10001",
--                                    x"16" when "10000",
--                                    x"13" when "01111",
--                                    x"10" when "01110",
--                                    x"0D" when "01101",
--                                    x"0B" when "01100",
--                                    x"09" when "01011",
--                                    x"08" when "01010",
--                                    x"07" when "01001",
--                                    x"06" when "01000",
--                                    x"05" when "00111",
--                                    x"04" when "00110",
--                                    x"03" when "00101",
--                                    x"03" when "00100",
--                                    x"02" when "00011",
--                                    x"02" when "00010",
--                                    x"01" when "00001",
--                                    x"00" when others; -- Also covers U, X, Z, W, H, L, -.
--
--    with AMPLITUDE_C select
--                        VOLUME_C <= x"FF" when "11111",
--                                    x"D9" when "11110",
--                                    x"BA" when "11101",
--                                    x"9F" when "11100",
--                                    x"88" when "11011",
--                                    x"74" when "11010",
--                                    x"63" when "11001",
--                                    x"54" when "11000",
--                                    x"48" when "10111",
--                                    x"3D" when "10110",
--                                    x"34" when "10101",
--                                    x"2C" when "10100",
--                                    x"25" when "10011",
--                                    x"1F" when "10010",
--                                    x"1A" when "10001",
--                                    x"16" when "10000",
--                                    x"13" when "01111",
--                                    x"10" when "01110",
--                                    x"0D" when "01101",
--                                    x"0B" when "01100",
--                                    x"09" when "01011",
--                                    x"08" when "01010",
--                                    x"07" when "01001",
--                                    x"06" when "01000",
--                                    x"05" when "00111",
--                                    x"04" when "00110",
--                                    x"03" when "00101",
--                                    x"03" when "00100",
--                                    x"02" when "00011",
--                                    x"02" when "00010",
--                                    x"01" when "00001",
--                                    x"00" when others; -- Also covers U, X, Z, W, H, L, -.

--    DA_CONVERSION: process(SYS_CLK,RESETn)
--    -- The DA conversion for the three analog outputs is originally performed by a built in DA converter.
--    -- For this is not possible in current FPGA designs, the converter is replaced by three PWM units
--    -- operating at a frequency which is 100 times higher than the highest noise or music frequency which
--    -- is 2MHz/16 = 125kHz. So the PWM frequency requires about 12.5MHz or more. The design is done for
--    -- a PWM frequency of 16MHz).
--    begin
--      if RESETn = '0' then
--        PWM_RAMP <= (others => '0');
--      elsif rising_edge(SYS_CLK) then
----        wait until SYS_CLK = '1' and SYS_CLK' event;
--        PWM_RAMP <= PWM_RAMP + 1;
--      end if;
--    end process DA_CONVERSION;
--    OUT_A <= '0' when VOLUME_A = x"00" else '1' when PWM_RAMP < unsigned(VOLUME_A) else '0';
--    OUT_B <= '0' when VOLUME_B = x"00" else '1' when PWM_RAMP < unsigned(VOLUME_B) else '0';
--    OUT_C <= '0' when VOLUME_C = x"00" else '1' when PWM_RAMP < unsigned(VOLUME_C) else '0';
    --
    -- To obtain proper analog output it is necessary to install analog RC filters to the pulse width
    -- outputs. An example is given for the direct wiring of the three analog outputs and for a system
    -- clock frequency of 16MHz. The output circuitry looks in this case as follows:
    --
    -- OUT_A ---------|1kOhm|-----------|                      |\ e.g. LM741
    --                                  |----------------------|+\       ||
    -- OUT_B ---------|1kOhm|-----------|                      | OP------||--- Analog Signal
    --                                  |----------------------|-/  |    ||
    -- OUT_C ---------|1kOhm|-----------|                |     |/   |   4u7
    --                                  |                |__________|
    --                                  |
    --                                 --- 10nF.
    --                                 ---
    --                                  |
    --                                  |
    --                                 ---
    --  WF.
    process(VOLUME_A,VOLUME_B,VOLUME_C)
      variable sum_v : unsigned(9 downto 0);
    begin
      sum_v := resize(unsigned(VOLUME_A),10) + unsigned(VOLUME_B) + unsigned(VOLUME_C);
      sum_v := sum_v + shift_right(sum_v,2);
      SUM_VOL <= std_ulogic_vector(sum_v(9 downto 2));
    end process;
    
    dac_inst : dac
      generic map(
        msbi_g => 7
      )
      port  map(
        clk_i   => SYS_CLK,
        res_n_i => RESETn,
        dac_i   => SUM_VOL,
        dac_o   => OUT_SUM
      );
    
end architecture BEHAVIOR;
