-- Display Test
-- Version : 0100
--
-- Copyright (c) 2006 MikeJ
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- Redistributions in synthesized form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- Neither the name of the author nor the names of other contributors may
-- be used to endorse or promote products derived from this software without
-- specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- Please report bugs to the author, but before you do so, please
-- make sure that this is not a derivative work and that
-- you have the latest version of this file.
--
-- The latest version of this file can be found at:
--      http://www.fpgaarcade.com

-- The latest version of this file can be found at: www.fpgaarcade.com
--
-- Email support@fpgaarcade.com
--
-- Revision list
--
-- version 0100 June 2006 release - initial release

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

--library UNISIM;
--  use UNISIM.Vcomponents.all;

entity VTG_TEST is
  port (
    I_RESET           : in    std_logic;
    I_PIXEL_CLOCK     : in    std_logic;
    --
    O_VIDEO_R         : out   std_logic_vector(3 downto 0);
    O_VIDEO_G         : out   std_logic_vector(3 downto 0);
    O_VIDEO_B         : out   std_logic_vector(3 downto 0);
    O_Reset           : out   std_logic;
    O_HSYNC           : out   std_logic;
    O_VSYNC           : out   std_logic
    );
end;

architecture RTL of VTG_TEST is
  --
  --types & constants
  --
  subtype  Bus12         is std_logic_vector (11 downto 0);

  -- 800 x 600
  -- Clock freq 50MHz. Horiz 48.8 KHz, Vert 72.19 Hz, Horiz Sync 2.4uS, Vert Sync 124.8 mS

  constant V_FRONT_PORCH_START : Bus12 := x"258"; -- line 600
  constant V_SYNC_START        : Bus12 := x"27D"; -- line 637
  constant V_BACK_PORCH_START  : Bus12 := x"283"; -- line 643
  constant LINE_PER_FRAME      : Bus12 := x"29A"; -- 666 lines

  constant H_FRONT_PORCH_START : Bus12 := x"320"; -- pixel 800
  constant H_SYNC_START        : Bus12 := x"358"; -- pixel 856
  constant H_BACK_PORCH_START  : Bus12 := x"3D0"; -- pixel 976
  constant PIXEL_PER_LINE      : Bus12 := x"410"; -- 1040 pixels


  --Signals
  signal line_count             : std_logic_vector(9 downto 0);
  signal pixel_count            : std_logic_vector(10 downto 0);
  signal hterm                  : boolean;
  signal vterm                  : boolean;
  signal v_sync                 : std_logic;
  signal h_sync                 : std_logic;

  signal vertical_blanking      : std_logic;
  signal horizontal_blanking    : std_logic;
  signal active_video           : std_logic;
  signal test_gen               : std_logic;

  signal ext_reset              : std_logic;
  signal ext_rst_cnt            : std_logic_vector(2 downto 0);
  signal hold_pixel_address     : std_logic;
  signal reset_pixel_address    : std_logic;
  signal next_row               : std_logic;

  signal addr_row               : std_logic_vector(9 downto 0);
  signal addr_col               : std_logic_vector(9 downto 0);

  signal tpg                    : std_logic_vector(11 downto 0);
  signal video_r                : std_logic_vector(3 downto 0);
  signal video_g                : std_logic_vector(3 downto 0);
  signal video_b                : std_logic_vector(3 downto 0);

begin

  p_extreset           : process(I_PIXEL_CLOCK, I_RESET)
  begin
    if (I_RESET = '1') then
      ext_rst_cnt <= "000";
      ext_reset <= '1';
    elsif rising_edge(I_PIXEL_CLOCK) then
      if (ext_rst_cnt = "111") then
        ext_rst_cnt <= "111";
        ext_reset <= '0';
      else
        ext_rst_cnt <= ext_rst_cnt + "1";
        ext_reset <= '1';
      end if;
    end if;
  end process;

  p_cnt_compare_comb   : process(pixel_count, line_count)
  begin
    hterm <= (pixel_count = (PIXEL_PER_LINE(10 downto 0) - "1"));
    vterm <= (line_count = (LINE_PER_FRAME(9 downto 0) - "1"));
  end process;

  p_h_cnt              : process(I_PIXEL_CLOCK, ext_reset)
  begin
    if (ext_reset = '1') then
      pixel_count <= (others => '0');
    elsif rising_edge(I_PIXEL_CLOCK) then
      if hterm then
        pixel_count <= (others => '0');
      else
        pixel_count <= pixel_count + "1";
      end if;
    end if;
  end process;

  p_v_cnt              : process(I_PIXEL_CLOCK, ext_reset)
  begin
    if (ext_reset = '1') then
      line_count <= (others => '0');
    elsif rising_edge(I_PIXEL_CLOCK) then
      if hterm then
        if vterm then
          line_count <= (others => '0');
        else
          line_count <= line_count + "1";
        end if;
      end if;
    end if;
  end process;

  p_vertical_sync      : process(I_PIXEL_CLOCK, ext_reset)
    variable vcnt_eq_front_porch_start : boolean;
    variable vcnt_eq_sync_start        : boolean;
    variable vcnt_eq_back_porch_start  : boolean;
    variable hterm_m8 : boolean;
  begin
    if (ext_reset = '1') then
      v_sync <= '1';
      vertical_blanking <= '0';
      reset_pixel_address <= '0';
    elsif rising_edge(I_PIXEL_CLOCK) then
      vcnt_eq_front_porch_start := (line_count = (V_FRONT_PORCH_START(9 downto 0) - "1"));
      vcnt_eq_sync_start        := (line_count = (       V_SYNC_START(9 downto 0) - "1"));
      vcnt_eq_back_porch_start  := (line_count = ( V_BACK_PORCH_START(9 downto 0) - "1"));

      hterm_m8 := (pixel_count = (PIXEL_PER_LINE(10 downto 0) - "1001"));

      if vcnt_eq_sync_start and hterm then
        v_sync <= '0';
      elsif vcnt_eq_back_porch_start and hterm then
        v_sync <= '1';
      end if;

      if vcnt_eq_front_porch_start and hterm then
        vertical_blanking <= '1';
      elsif vterm and hterm then
        vertical_blanking <= '0';
      end if;

      if vcnt_eq_front_porch_start and hterm_m8 then
        reset_pixel_address <= '1';
      elsif vterm and hterm_m8 then
        reset_pixel_address <= '0';
      end if;

    end if;
  end process;

  p_horizontal_sync    : process(I_PIXEL_CLOCK, ext_reset)
    variable hcnt_eq_front_porch_start_m2  : boolean;
    variable hcnt_eq_front_porch_start     : boolean;
    variable hcnt_eq_sync_start           : boolean;
    variable hcnt_eq_back_porch_start      : boolean;
    variable hterm_m2 : boolean;
  begin
    if (ext_reset = '1') then
      h_sync <= '1';
      horizontal_blanking <= '0';
      hold_pixel_address <= '0';
      next_row <= '0';
    elsif rising_edge(I_PIXEL_CLOCK) then
      hcnt_eq_front_porch_start_m2  := (pixel_count = ( H_FRONT_PORCH_START(10 downto 0) - "0011"));
      hcnt_eq_front_porch_start     := (pixel_count = ( H_FRONT_PORCH_START(10 downto 0) - "1"));
      hcnt_eq_sync_start            := (pixel_count = (        H_SYNC_START(10 downto 0) - "1"));
      hcnt_eq_back_porch_start      := (pixel_count = (  H_BACK_PORCH_START(10 downto 0) - "1"));

      hterm_m2 := (pixel_count = (PIXEL_PER_LINE(10 downto 0) - "0011"));

      if hcnt_eq_sync_start then
        h_sync <= '0';
      elsif hcnt_eq_back_porch_start then
        h_sync <= '1';
      end if;

      if hcnt_eq_front_porch_start then
        horizontal_blanking <= '1';
      elsif hterm then
        horizontal_blanking <= '0';
      end if;

      next_row <= '0';
      if hcnt_eq_front_porch_start_m2 then
        hold_pixel_address <= '1';
        next_row <= '1';
      elsif hterm_m2 then
        hold_pixel_address <= '0';
      end if;

    end if;
  end process;

  p_active_video_comb  : process(horizontal_blanking, vertical_blanking)
  begin
    active_video <= not(horizontal_blanking or vertical_blanking);
  end process;

  p_test_video_comb    : process(line_count, pixel_count)
  begin
    if (line_count = "0000000000") or (line_count = (('0' & V_FRONT_PORCH_START(9 downto 1)) - "1")) or
       (line_count = (V_FRONT_PORCH_START(9 downto 0) - "1")) then
        test_gen <= '1';
    elsif (pixel_count = "00000000000") or (pixel_count = (('0' & H_FRONT_PORCH_START(10 downto 1)) - "1")) or
        (pixel_count = (H_FRONT_PORCH_START(10 downto 0) - "1")) then
        test_gen <= '1';
    elsif (line_count = "0000001001") or (line_count = (V_FRONT_PORCH_START(9 downto 0) - "1010")) then
        test_gen <= '1';
    elsif (pixel_count = "00000001001") or (pixel_count = (H_FRONT_PORCH_START(10 downto 0) - "1010")) then
        test_gen <= '1';
    else
        test_gen <= '0';
    end if;
  end process;

  p_pixel_addr         : process(I_PIXEL_CLOCK, I_RESET)
  begin
    if (I_RESET = '1') then
      addr_col <= (others => '0');
      addr_row <= (others => '0');
    elsif rising_edge(I_PIXEL_CLOCK) then
      if (reset_pixel_address = '1') then
        addr_row <= (others => '0');
      elsif (next_row = '1') then
        addr_row <= addr_row + "1";
      end if;

      if (reset_pixel_address = '1') or (next_row = '1') then
        addr_col <= (others => '0');
      elsif (hold_pixel_address = '0') then
        addr_col <= addr_col + "1";
      end if;

    end if;
  end process;

  p_tpg                : process
    variable c : std_logic_vector(3 downto 0);
  begin
    wait until rising_edge(I_PIXEL_CLOCK);
    c := addr_col(6 downto 3);
    tpg <= (others => '0');
    if (addr_row(9 downto 8) = "00") then
      case addr_col(9 downto 6) is
        when x"0" | x"1" | x"2" | x"3" =>
          tpg(11 downto 8) <= x"0"; tpg(7 downto 4) <= x"0"; tpg(3 downto 0) <= c;
        -- green
        when x"4" | x"5" | x"6" | x"7" =>
          tpg(11 downto 8) <= x"0"; tpg(7 downto 4) <= c   ; tpg(3 downto 0) <= x"0";
        -- blue
        when x"8" | x"9" | x"a" | x"b" =>
          tpg(11 downto 8) <= c   ; tpg(7 downto 4) <= x"0"; tpg(3 downto 0) <= x"0";
        -- gray
        when x"c" | x"d" | x"e" | x"f" =>
          tpg(11 downto 8) <= c   ; tpg(7 downto 4) <= c;    tpg(3 downto 0) <= c;
        when others => null;
      end case;
    else
      case addr_col(9 downto 6) is
        -- red
        when x"0" => tpg <= x"001";
        when x"1" => tpg <= x"002";
        when x"2" => tpg <= x"004";
        when x"3" => tpg <= x"008";
        -- green
        when x"4" => tpg <= x"010";
        when x"5" => tpg <= x"020";
        when x"6" => tpg <= x"040";
        when x"7" => tpg <= x"080";
        -- blue
        when x"8" => tpg <= x"100";
        when x"9" => tpg <= x"200";
        when x"a" => tpg <= x"400";
        when x"b" => tpg <= x"800";
        -- gray
        when x"c" => tpg <= x"777";
        when x"d" => tpg <= x"777";
        when x"e" => tpg <= x"777";
        when x"f" => tpg <= x"777";
        when others => null;
      end case;
    end if;
  end process;

  p_shifter            : process
  begin
    wait until rising_edge(I_PIXEL_CLOCK);
    -- character generator removed
    video_r <= tpg( 3 downto 0);
    video_g <= tpg( 7 downto 4);
    video_b <= tpg(11 downto 8);
  end process;

  p_video_mux          : process(I_PIXEL_CLOCK, I_RESET)
  begin
    if (I_RESET = '1') then
      O_VIDEO_R <= x"0";
      O_VIDEO_G <= x"0";
      O_VIDEO_B <= x"0";

      O_VSYNC <= '1';
      O_HSYNC <= '1';

    elsif rising_edge(I_PIXEL_CLOCK) then
      if (active_video = '1') then
        if (test_gen = '1') then
          O_VIDEO_R <= x"F";
          O_VIDEO_G <= x"F";
          O_VIDEO_B <= x"F";
        else
          O_VIDEO_R <= video_r;
          O_VIDEO_G <= video_g;
          O_VIDEO_B <= video_b;
        end if;
      else
        O_VIDEO_R <= x"0";
        O_VIDEO_G <= x"0";
        O_VIDEO_B <= x"0";
      end if;

      O_VSYNC <= v_sync;
      O_HSYNC <= h_sync;
    end if;
  end process;

end architecture RTL;

