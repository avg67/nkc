------------------------------------------------------------------------------
------------------------------------------------------------------------------
--                                                                          --
-- Copyright (c) 2009-2011 Tobias Gubener                                   --
-- Subdesign fAMpIGA by TobiFlex                                            --
--                                                                          --
-- This source file is free software: you can redistribute it and/or modify --
-- it under the terms of the GNU General Public License as published        --
-- by the Free Software Foundation, either version 3 of the License, or     --
-- (at your option) any later version.                                      --
--                                                                          --
-- This source file is distributed in the hope that it will be useful,      --
-- but WITHOUT ANY WARRANTY; without even the implied warranty of           --
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            --
-- GNU General Public License for more details.                             --
--                                                                          --
-- You should have received a copy of the GNU General Public License        --
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.    --
--                                                                          --
------------------------------------------------------------------------------
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use IEEE.numeric_std.all;
use work.TG68K_Pack.all;

entity TG68K_ALU is
  generic(
    MUL_Mode : integer := 0;  --0=>16Bit,  1=>32Bit,  2=>switchable with CPU(1),  3=>no MUL,
    DIV_Mode : integer := 0  --0=>16Bit,  1=>32Bit,  2=>switchable with CPU(1),  3=>no DIV,
    );
  port(clk            : in  std_logic;
       Reset          : in  std_logic;
       clkena_lw      : in  std_logic := '1';
       execOPC        : in  bit;
       exe_condition  : in  std_logic;
       exec_tas       : in  std_logic;
       long_start     : in  bit;
       movem_presub   : in  bit;
       set_stop       : in  bit;
       Z_error        : in  bit;
       rot_bits       : in  std_logic_vector(1 downto 0);
       exec           : in  bit_vector(lastOpcBit downto 0);
       OP1out         : in  std_logic_vector(31 downto 0);
       OP2out         : in  std_logic_vector(31 downto 0);
       reg_QA         : in  std_logic_vector(31 downto 0);
       reg_QB         : in  std_logic_vector(31 downto 0);
       opcode         : in  std_logic_vector(15 downto 0);
       datatype       : in  std_logic_vector(1 downto 0);
       exe_opcode     : in  std_logic_vector(15 downto 0);
       exe_datatype   : in  std_logic_vector(1 downto 0);
       sndOPC         : in  std_logic_vector(15 downto 0);
       last_data_read : in  std_logic_vector(15 downto 0);
       data_read      : in  std_logic_vector(15 downto 0);
       FlagsSR        : in  std_logic_vector(7 downto 0);
       micro_state    : in  micro_states;
       bf_ext_in      : in  std_logic_vector(7 downto 0);
       bf_ext_out     : out std_logic_vector(7 downto 0);
       bf_shift       : in  std_logic_vector(5 downto 0);
       bf_width       : in  std_logic_vector(5 downto 0);
       bf_loffset     : in  std_logic_vector(4 downto 0);

       set_V_Flag : buffer bit;
       Flags      : buffer std_logic_vector(7 downto 0);
       c_out      : buffer std_logic_vector(2 downto 0);
       addsub_q   : buffer std_logic_vector(31 downto 0);
       ALUout     : out    std_logic_vector(31 downto 0)
       );
end TG68K_ALU;

architecture logic of TG68K_ALU is
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-- ALU and more
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
  signal OP1in       : std_logic_vector(31 downto 0);
  signal addsub_a    : std_logic_vector(31 downto 0);
  signal addsub_b    : std_logic_vector(31 downto 0);
  signal notaddsub_b : std_logic_vector(33 downto 0);
  signal add_result  : std_logic_vector(33 downto 0);
  signal addsub_ofl  : std_logic_vector(2 downto 0);
  signal opaddsub    : bit;
  signal c_in        : std_logic_vector(3 downto 0);
  signal flag_z      : std_logic_vector(2 downto 0);
  signal set_Flags   : std_logic_vector(3 downto 0);  --NZVC
  signal CCRin       : std_logic_vector(7 downto 0);

  signal niba_l  : std_logic_vector(5 downto 0);
  signal niba_h  : std_logic_vector(5 downto 0);
  signal niba_lc : std_logic;
  signal niba_hc : std_logic;
  signal bcda_lc : std_logic;
  signal bcda_hc : std_logic;
  signal nibs_l  : std_logic_vector(5 downto 0);
  signal nibs_h  : std_logic_vector(5 downto 0);
  signal nibs_lc : std_logic;
  signal nibs_hc : std_logic;

  signal bcd_a       : std_logic_vector(8 downto 0);
  signal bcd_s       : std_logic_vector(8 downto 0);
  signal result_mulu : std_logic_vector(63 downto 0);
  signal result_div  : std_logic_vector(63 downto 0);
  signal set_mV_Flag : std_logic;
  signal V_Flag      : bit;

  signal rot_rot    : std_logic;
  signal rot_lsb    : std_logic;
  signal rot_msb    : std_logic;
  signal rot_X      : std_logic;
  signal rot_C      : std_logic;
  signal rot_out    : std_logic_vector(31 downto 0);
  signal asl_VFlag  : std_logic;
  signal bit_bits   : std_logic_vector(1 downto 0);
  signal bit_number : std_logic_vector(4 downto 0);
  signal bits_out   : std_logic_vector(31 downto 0);
  signal one_bit_in : std_logic;
  signal bchg       : std_logic;
  signal bset       : std_logic;

  signal mulu_sign    : std_logic;
  signal mulu_signext : std_logic_vector(16 downto 0);
  signal muls_msb     : std_logic;
  signal mulu_reg     : std_logic_vector(63 downto 0);
  signal FAsign       : std_logic;
  signal faktorA      : std_logic_vector(31 downto 0);
  signal faktorB      : std_logic_vector(31 downto 0);

  signal div_reg   : std_logic_vector(63 downto 0);
  signal div_quot  : std_logic_vector(63 downto 0);
  signal div_ovl   : std_logic;
  signal div_neg   : std_logic;
  signal div_bit   : std_logic;
  signal div_sub   : std_logic_vector(32 downto 0);
  signal div_over  : std_logic_vector(32 downto 0);
  signal nozero    : std_logic;
  signal div_qsign : std_logic;
  signal divisor   : std_logic_vector(63 downto 0);
  signal divs      : std_logic;
  signal signedOP  : std_logic;
  signal OP1_sign  : std_logic;
  signal OP2_sign  : std_logic;
  signal OP2outext : std_logic_vector(15 downto 0);

  signal in_offset   : std_logic_vector(5 downto 0);
--    signal in_width         : std_logic_vector(5 downto 0);
  signal datareg     : std_logic_vector(31 downto 0);
  signal insert      : std_logic_vector(31 downto 0);
--    signal bf_result        : std_logic_vector(31 downto 0);
--    signal bf_offset        : std_logic_vector(5 downto 0);
--    signal bf_width         : std_logic_vector(5 downto 0);
--    signal bf_firstbit      : std_logic_vector(5 downto 0);
  signal bf_datareg  : std_logic_vector(31 downto 0);
--    signal bf_out       : std_logic_vector(31 downto 0);
  signal result      : std_logic_vector(39 downto 0);
  signal result_tmp  : std_logic_vector(39 downto 0);
  signal sign        : std_logic_vector(31 downto 0);
  signal bf_set1     : std_logic_vector(39 downto 0);
  signal inmux0      : std_logic_vector(39 downto 0);
  signal inmux1      : std_logic_vector(39 downto 0);
  signal inmux2      : std_logic_vector(39 downto 0);
  signal inmux3      : std_logic_vector(31 downto 0);
  signal copymux0    : std_logic_vector(39 downto 0);
  signal copymux1    : std_logic_vector(39 downto 0);
  signal copymux2    : std_logic_vector(39 downto 0);
  signal copymux3    : std_logic_vector(31 downto 0);
  signal bf_set2     : std_logic_vector(31 downto 0);
--    signal bf_set3          : std_logic_vector(31 downto 0);
  signal shift       : std_logic_vector(39 downto 0);
  signal copy        : std_logic_vector(39 downto 0);
--    signal offset         : std_logic_vector(5 downto 0);
--    signal width            : std_logic_vector(5 downto 0);
  signal bf_firstbit : std_logic_vector(5 downto 0);
  signal mux         : std_logic_vector(3 downto 0);
  signal bitnr       : std_logic_vector(4 downto 0);
  signal mask        : std_logic_vector(31 downto 0);
  signal bf_bset     : std_logic;
  signal bf_NFlag    : std_logic;
  signal bf_bchg     : std_logic;
  signal bf_ins      : std_logic;
  signal bf_exts     : std_logic;
  signal bf_fffo     : std_logic;
  signal bf_d32      : std_logic;
  signal bf_s32      : std_logic;
  signal index       : std_logic_vector(4 downto 0);
--    signal i  : integer range 0 to 31;
--    signal i  : integer range 0 to 31;
--    signal i  : std_logic_vector(5 downto 0);
begin
-----------------------------------------------------------------------------
-- set OP1in
-----------------------------------------------------------------------------
  process (OP2out, OP1out, OP1in, exe_datatype, addsub_q, exec,
           bcd_a, bcd_s, result_mulu, result_div, exe_condition, bf_shift,
           Flags, FlagsSR, bits_out, exec_tas, rot_out, exe_opcode, result, bf_fffo, bf_firstbit, bf_datareg)
  begin
    ALUout    <= OP1in;
    ALUout(7) <= OP1in(7) or exec_tas;
    if exec(opcBFwb) = '1' then
      ALUout <= result(31 downto 0);
      if bf_fffo = '1' then
        ALUout             <= (others => '0');
        ALUout(5 downto 0) <= bf_firstbit + bf_shift;
      end if;
    end if;

    OP1in <= addsub_q;
    if exec(opcABCD) = '1' then
      OP1in(7 downto 0) <= bcd_a(7 downto 0);
    elsif exec(opcSBCD) = '1' then
      OP1in(7 downto 0) <= bcd_s(7 downto 0);
    elsif exec(opcMULU) = '1' and MUL_Mode /= 3 then
      if exec(write_lowlong) = '1' and (MUL_Mode = 1 or MUL_Mode = 2) then
        OP1in <= result_mulu(31 downto 0);
      else
        OP1in <= result_mulu(63 downto 32);
      end if;
    elsif exec(opcDIVU) = '1' and DIV_Mode /= 3 then
      if exe_opcode(15) = '1' or DIV_Mode = 0 then
--          IF exe_opcode(15)='1' THEN
        OP1in <= result_div(47 downto 32)&result_div(15 downto 0);
      else                              --64bit
        if exec(write_reminder) = '1' then
          OP1in <= result_div(63 downto 32);
        else
          OP1in <= result_div(31 downto 0);
        end if;
      end if;
    elsif exec(opcOR) = '1' then
      OP1in <= OP2out or OP1out;
    elsif exec(opcAND) = '1' then
      OP1in <= OP2out and OP1out;
    elsif exec(opcScc) = '1' then
      OP1in(7 downto 0) <= (others => exe_condition);
    elsif exec(opcEOR) = '1' then
      OP1in <= OP2out xor OP1out;
    elsif exec(opcMOVE) = '1' or exec(exg) = '1' then
--          OP1in <= OP2out(31 downto 8)&(OP2out(7)OR exec_tas)&OP2out(6 downto 0);
      OP1in <= OP2out;
    elsif exec(opcROT) = '1' then
      OP1in <= rot_out;
    elsif exec(opcSWAP) = '1' then
      OP1in <= OP1out(15 downto 0)& OP1out(31 downto 16);
    elsif exec(opcBITS) = '1' then
      OP1in <= bits_out;
    elsif exec(opcBF) = '1' then
      OP1in <= bf_datareg;
    elsif exec(opcMOVESR) = '1' then
      OP1in(7 downto 0) <= Flags;
      if exe_datatype = "00" then
        OP1in(15 downto 8) <= "00000000";
      else
        OP1in(15 downto 8) <= FlagsSR;
      end if;
    end if;
  end process;

-----------------------------------------------------------------------------
-- addsub
-----------------------------------------------------------------------------
  process (OP1out, OP2out, execOPC, datatype, Flags, long_start, movem_presub, exe_datatype, exec, addsub_a, addsub_b, opaddsub,
           notaddsub_b, add_result, c_in, sndOPC)
  begin
    addsub_a <= OP1out;
    if exec(get_bfoffset) = '1' then
      if sndOPC(11) = '1' then
        addsub_a <= OP1out(31)&OP1out(31)&OP1out(31)&OP1out(31 downto 3);
      else
        addsub_a <= "000000000000000000000000000000"&sndOPC(10 downto 9);
      end if;
    end if;

    if exec(subidx) = '1' then
      opaddsub <= '1';
    else
      opaddsub <= '0';
    end if;

    c_in(0)  <= '0';
    addsub_b <= OP2out;
    if execOPC = '0' and exec(OP2out_one) = '0' and exec(get_bfoffset) = '0'then
      if long_start = '0' and datatype = "00" and exec(use_SP) = '0' then
        addsub_b <= "00000000000000000000000000000001";
      elsif long_start = '0' and exe_datatype = "10" and (exec(presub) or exec(postadd) or movem_presub) = '1' then
        if exec(movem_action) = '1' then
          addsub_b <= "00000000000000000000000000000110";
        else
          addsub_b <= "00000000000000000000000000000100";
        end if;
      else
        addsub_b <= "00000000000000000000000000000010";
      end if;
    else
      if (exec(use_XZFlag) = '1' and Flags(4) = '1') or exec(opcCHK) = '1' then
        c_in(0) <= '1';
      end if;
      opaddsub <= exec(addsub);
    end if;

    if opaddsub = '0' or long_start = '1' then  --ADD
      notaddsub_b <= '0'&addsub_b&c_in(0);
    else                                --SUB
      notaddsub_b <= not ('0'&addsub_b&c_in(0));
    end if;
    add_result    <= (('0'&addsub_a&notaddsub_b(0))+notaddsub_b);
    c_in(1)       <= add_result(9) xor addsub_a(8) xor addsub_b(8);
    c_in(2)       <= add_result(17) xor addsub_a(16) xor addsub_b(16);
    c_in(3)       <= add_result(33);
    addsub_q      <= add_result(32 downto 1);
    addsub_ofl(0) <= (c_in(1) xor add_result(8) xor addsub_a(7) xor addsub_b(7));  --V Byte
    addsub_ofl(1) <= (c_in(2) xor add_result(16) xor addsub_a(15) xor addsub_b(15));  --V Word
    addsub_ofl(2) <= (c_in(3) xor add_result(32) xor addsub_a(31) xor addsub_b(31));  --V Long
    c_out         <= c_in(3 downto 1);
  end process;

------------------------------------------------------------------------------
--ALU
------------------------------------------------------------------------------
  process (OP1out, OP2out, niba_hc, niba_h, niba_l, niba_lc, nibs_hc, nibs_h, nibs_l, nibs_lc, Flags)
  begin
--BCD_ARITH-------------------------------------------------------------------
    --ADC
    bcd_a   <= niba_hc&(niba_h(4 downto 1)+('0', niba_hc, niba_hc, '0'))&(niba_l(4 downto 1)+('0', niba_lc, niba_lc, '0'));
    niba_l  <= ('0'&OP1out(3 downto 0)&'1') + ('0'&OP2out(3 downto 0)&Flags(4));
    niba_lc <= niba_l(5) or (niba_l(4) and niba_l(3)) or (niba_l(4) and niba_l(2));

    niba_h  <= ('0'&OP1out(7 downto 4)&'1') + ('0'&OP2out(7 downto 4)&niba_lc);
    niba_hc <= niba_h(5) or (niba_h(4) and niba_h(3)) or (niba_h(4) and niba_h(2));
    --SBC
    bcd_s   <= nibs_hc&(nibs_h(4 downto 1)-('0', nibs_hc, nibs_hc, '0'))&(nibs_l(4 downto 1)-('0', nibs_lc, nibs_lc, '0'));
    nibs_l  <= ('0'&OP1out(3 downto 0)&'0') - ('0'&OP2out(3 downto 0)&Flags(4));
    nibs_lc <= nibs_l(5);

    nibs_h  <= ('0'&OP1out(7 downto 4)&'0') - ('0'&OP2out(7 downto 4)&nibs_lc);
    nibs_hc <= nibs_h(5);
  end process;

-----------------------------------------------------------------------------
-- Bits
-----------------------------------------------------------------------------
  process (clk)
  begin
    if rising_edge(clk) then
      if clkena_lw = '1' then
        bchg <= '0';
        bset <= '0';
        case opcode(7 downto 6) is
          when "01" =>                  --bchg
            bchg <= '1';
          when "11" =>                  --bset
            bset <= '1';
          when others => null;
        end case;
      end if;
    end if;
  end process;

  process (exe_opcode, OP1out, one_bit_in, bchg, bset, bit_Number, sndOPC, reg_QB)
  begin
    if exe_opcode(8) = '0' then
      if exe_opcode(5 downto 4) = "00" then
        bit_number <= sndOPC(4 downto 0);
      else
        bit_number <= "00"&sndOPC(2 downto 0);
      end if;
    else
      if exe_opcode(5 downto 4) = "00" then
        bit_number <= reg_QB(4 downto 0);
      else
        bit_number <= "00"&reg_QB(2 downto 0);
      end if;
    end if;

    one_bit_in                                 <= OP1out(to_integer(unsigned(bit_Number)));
    bits_out                                   <= OP1out;
    bits_out(to_integer(unsigned(bit_Number))) <= (bchg and not one_bit_in) or bset;
  end process;

-----------------------------------------------------------------------------
-- Bit Field
-----------------------------------------------------------------------------
  process (clk)
  begin
    if rising_edge(clk) then
      if clkena_lw = '1' then
        bf_bset <= '0';
        bf_bchg <= '0';
        bf_ins  <= '0';
        bf_exts <= '0';
        bf_fffo <= '0';
        bf_d32  <= '0';
        bf_s32  <= '0';
        case opcode(10 downto 8) is
          when "010" => bf_bchg <= '1';  --BFCHG
          when "011" => bf_exts <= '1';  --BFEXTS
--                  WHEN "100" => insert <= (OTHERS =>'0');     --BFCLR
          when "101" => bf_fffo <= '1';  --BFFFO
          when "110" => bf_bset <= '1';  --BFSET
          when "111" => bf_ins  <= '1';  --BFINS
                        bf_s32 <= '1';
          when others => null;
        end case;
        if opcode(4 downto 3) = "00" then
          bf_d32 <= '1';
        end if;
        bf_ext_out <= result(39 downto 32);
      end if;
    end if;
  end process;

  process (mux, mask, bitnr, bf_ins, bf_bchg, bf_bset, bf_exts, bf_shift, inmux0, inmux1, inmux2, inmux3, bf_set2, OP1out, OP2out, result_tmp, bf_ext_in,
            shift, datareg, bf_NFlag, reg_QB, sign, bf_d32, bf_s32, copy, bf_loffset, copymux0, copymux1, copymux2, copymux3, bf_width)
  begin
    shift <= bf_ext_in&OP2out;
    if bf_s32 = '1' then
      shift(39 downto 32) <= OP2out(7 downto 0);
    end if;

    if bf_shift(0) = '1' then
      inmux0 <= shift(0)&shift(39 downto 1);
    else
      inmux0 <= shift;
    end if;
    if bf_shift(1) = '1' then
      inmux1 <= inmux0(1 downto 0)&inmux0(39 downto 2);
    else
      inmux1 <= inmux0;
    end if;
    if bf_shift(2) = '1' then
      inmux2 <= inmux1(3 downto 0)&inmux1(39 downto 4);
    else
      inmux2 <= inmux1;
    end if;
    if bf_shift(3) = '1' then
      inmux3 <= inmux2(7 downto 0)&inmux2(31 downto 8);
    else
      inmux3 <= inmux2(31 downto 0);
    end if;
    if bf_shift(4) = '1' then
      bf_set2(31 downto 0) <= inmux3(15 downto 0)&inmux3(31 downto 16);
    else
      bf_set2(31 downto 0) <= inmux3;
    end if;

    if bf_loffset(4) = '1' then
      copymux3 <= sign(15 downto 0)&sign(31 downto 16);
    else
      copymux3 <= sign;
    end if;
    if bf_loffset(3) = '1' then
      copymux2(31 downto 0) <= copymux3(23 downto 0)&copymux3(31 downto 24);
    else
      copymux2(31 downto 0) <= copymux3;
    end if;
    if bf_d32 = '1' then
      copymux2(39 downto 32) <= copymux3(7 downto 0);
    else
      copymux2(39 downto 32) <= "11111111";
    end if;
    if bf_loffset(2) = '1' then
      copymux1 <= copymux2(35 downto 0)&copymux2(39 downto 36);
    else
      copymux1 <= copymux2;
    end if;
    if bf_loffset(1) = '1' then
      copymux0 <= copymux1(37 downto 0)&copymux1(39 downto 38);
    else
      copymux0 <= copymux1;
    end if;
    if bf_loffset(0) = '1' then
      copy <= copymux0(38 downto 0)&copymux0(39);
    else
      copy <= copymux0;
    end if;

    result_tmp <= bf_ext_in&OP1out;
    if bf_ins = '1' then
      datareg <= reg_QB;
    else
      datareg <= bf_set2;
    end if;
    if bf_ins = '1' then
      result(31 downto 0)  <= bf_set2;
      result(39 downto 32) <= bf_set2(7 downto 0);
    elsif bf_bchg = '1' then
      result(31 downto 0)  <= not OP1out;
      result(39 downto 32) <= not bf_ext_in;
    else
      result <= (others => '0');
    end if;
    if bf_bset = '1' then
      result <= (others => '1');
    end if;

    sign     <= (others => '0');
    bf_NFlag <= datareg(to_integer(unsigned(bf_width)));
    for i in 0 to 31 loop
      if i > bf_width(4 downto 0) then
        datareg(i) <= '0';
        sign(i)    <= '1';
      end if;
    end loop;

    for i in 0 to 39 loop
      if copy(i) = '1' then
        result(i) <= result_tmp(i);
      end if;
    end loop;

    if bf_exts = '1' and bf_NFlag = '1' then
      bf_datareg <= datareg or sign;
    else
      bf_datareg <= datareg;
    end if;
--  bf_datareg <= copy(31 downto 0);
--  result(31 downto 0)<=datareg;
--BFFFO
    mask        <= datareg;
    bf_firstbit <= '0'&bitnr;
    bitnr       <= "11111";
    if mask(31 downto 28) = "0000" then
      if mask(27 downto 24) = "0000" then
        if mask(23 downto 20) = "0000" then
          if mask(19 downto 16) = "0000" then
            bitnr(4) <= '0';
            if mask(15 downto 12) = "0000" then
              if mask(11 downto 8) = "0000" then
                bitnr(3) <= '0';
                if mask(7 downto 4) = "0000" then
                  bitnr(2) <= '0';
                  mux      <= mask(3 downto 0);
                else
                  mux <= mask(7 downto 4);
                end if;
              else
                mux      <= mask(11 downto 8);
                bitnr(2) <= '0';
              end if;
            else
              mux <= mask(15 downto 12);
            end if;
          else
            mux      <= mask(19 downto 16);
            bitnr(3) <= '0';
            bitnr(2) <= '0';
          end if;
        else
          mux      <= mask(23 downto 20);
          bitnr(3) <= '0';
        end if;
      else
        mux      <= mask(27 downto 24);
        bitnr(2) <= '0';
      end if;
    else
      mux <= mask(31 downto 28);
    end if;

    if mux(3 downto 2) = "00" then
      bitnr(1) <= '0';
      if mux(1) = '0' then
        bitnr(0) <= '0';
      end if;
    else
      if mux(3) = '0' then
        bitnr(0) <= '0';
      end if;
    end if;
  end process;

-----------------------------------------------------------------------------
-- Rotation
-----------------------------------------------------------------------------
  process (exe_opcode, OP1out, Flags, rot_bits, rot_msb, rot_lsb, rot_rot, exec)
  begin
    case exe_opcode(7 downto 6) is
      when "00" =>                      --Byte
        rot_rot <= OP1out(7);
      when "01"|"11" =>                 --Word
        rot_rot <= OP1out(15);
      when "10" =>                      --Long
        rot_rot <= OP1out(31);
      when others => null;
    end case;

    case rot_bits is
      when "00" =>                      --ASL, ASR
        rot_lsb <= '0';
        rot_msb <= rot_rot;
      when "01" =>                      --LSL, LSR
        rot_lsb <= '0';
        rot_msb <= '0';
      when "10" =>                      --ROXL, ROXR
        rot_lsb <= Flags(4);
        rot_msb <= Flags(4);
      when "11" =>                      --ROL, ROR
        rot_lsb <= rot_rot;
        rot_msb <= OP1out(0);
      when others => null;
    end case;

    if exec(rot_nop) = '1' then
      rot_out <= OP1out;
      rot_X   <= Flags(4);
      if rot_bits = "10" then           --ROXL, ROXR
        rot_C <= Flags(4);
      else
        rot_C <= '0';
      end if;
    else
      if exe_opcode(8) = '1' then       --left
        rot_out <= OP1out(30 downto 0)&rot_lsb;
        rot_X   <= rot_rot;
        rot_C   <= rot_rot;
      else                              --right
        rot_X   <= OP1out(0);
        rot_C   <= OP1out(0);
        rot_out <= rot_msb&OP1out(31 downto 1);
        case exe_opcode(7 downto 6) is
          when "00" =>                  --Byte
            rot_out(7) <= rot_msb;
          when "01"|"11" =>             --Word
            rot_out(15) <= rot_msb;
          when others => null;
        end case;
      end if;
    end if;
  end process;

------------------------------------------------------------------------------
--CCR op
------------------------------------------------------------------------------
  process (exe_datatype, Flags, last_data_read, OP2out, flag_z, OP1IN, c_out, addsub_ofl,
           bcd_s, bcd_a, exec)
  begin
    if exec(andiSR) = '1' then
      CCRin <= Flags and last_data_read(7 downto 0);
    elsif exec(eoriSR) = '1' then
      CCRin <= Flags xor last_data_read(7 downto 0);
    elsif exec(oriSR) = '1' then
      CCRin <= Flags or last_data_read(7 downto 0);
    else
      CCRin <= OP2out(7 downto 0);
    end if;

------------------------------------------------------------------------------
--Flags
------------------------------------------------------------------------------
    flag_z <= "000";
    if exec(use_XZFlag) = '1' and flags(2) = '0' then
      flag_z <= "000";
    elsif OP1in(7 downto 0) = "00000000" then
      flag_z(0) <= '1';
      if OP1in(15 downto 8) = "00000000" then
        flag_z(1) <= '1';
        if OP1in(31 downto 16) = "0000000000000000" then
          flag_z(2) <= '1';
        end if;
      end if;
    end if;

--                  --Flags NZVC
    if exe_datatype = "00" then                             --Byte
      set_flags <= OP1IN(7)&flag_z(0)&addsub_ofl(0)&c_out(0);
      if exec(opcABCD) = '1' then
        set_flags(0) <= bcd_a(8);
      elsif exec(opcSBCD) = '1' then
        set_flags(0) <= bcd_s(8);
      end if;
    elsif exe_datatype = "10" or exec(opcCPMAW) = '1' then  --Long
      set_flags <= OP1IN(31)&flag_z(2)&addsub_ofl(2)&c_out(2);
    else                                                    --Word
      set_flags <= OP1IN(15)&flag_z(1)&addsub_ofl(1)&c_out(1);
    end if;
  end process;

  process (clk)
  begin
    if rising_edge(clk) then
      if clkena_lw = '1' then
        if exec(directSR) = '1' or set_stop = '1' then
          Flags(7 downto 0) <= data_read(7 downto 0);
        end if;
        if exec(directCCR) = '1' then
          Flags(7 downto 0) <= data_read(7 downto 0);
        end if;

        if exec(opcROT) = '1' then
          asl_VFlag <= ((set_flags(3) xor rot_rot) or asl_VFlag);
        else
          asl_VFlag <= '0';
        end if;
        if exec(to_CCR) = '1' then
          Flags(7 downto 0) <= CCRin(7 downto 0);  --CCR
        elsif Z_error = '1' then
          if exe_opcode(8) = '0' then
            Flags(3 downto 0) <= reg_QA(31)&"000";
          else
            Flags(3 downto 0) <= "0100";
          end if;
        elsif exec(no_Flags) = '0' then
          if exec(opcADD) = '1' then
            Flags(4) <= set_flags(0);
          elsif exec(opcROT) = '1' and rot_bits /= "11" and exec(rot_nop) = '0' then
            Flags(4) <= rot_X;
          end if;

          if (exec(opcADD) or exec(opcCMP)) = '1' then
            Flags(3 downto 0) <= set_flags;
          elsif exec(opcDIVU) = '1' and DIV_Mode /= 3 then
            if V_Flag = '1' then
              Flags(3 downto 0) <= "1010";
            else
              Flags(3 downto 0) <= OP1IN(15)&flag_z(1)&"00";
            end if;
          elsif exec(write_reminder) = '1' and MUL_Mode /= 3 then  -- z-flag MULU.l
            Flags(3) <= set_flags(3);
            Flags(2) <= set_flags(2) and Flags(2);
            Flags(1) <= '0';
            Flags(0) <= '0';
          elsif exec(write_lowlong) = '1' and (MUL_Mode = 1 or MUL_Mode = 2) then  -- flag MULU.l
            Flags(3) <= set_flags(3);
            Flags(2) <= set_flags(2);
            Flags(1) <= set_mV_Flag;    --V
            Flags(0) <= '0';
          elsif exec(opcOR) = '1' or exec(opcAND) = '1' or exec(opcEOR) = '1' or exec(opcMOVE) = '1' or exec(opcMOVEQ) = '1' or exec(opcSWAP) = '1' or exec(opcBF) = '1' or (exec(opcMULU) = '1' and MUL_Mode /= 3) then
            Flags(1 downto 0) <= "00";
            Flags(3 downto 2) <= set_flags(3 downto 2);
            if exec(opcBF) = '1' then
              Flags(3) <= bf_NFlag;
            end if;
          elsif exec(opcROT) = '1' then
            Flags(3 downto 2) <= set_flags(3 downto 2);
            Flags(0)          <= rot_C;
            if rot_bits = "00" and ((set_flags(3) xor rot_rot) or asl_VFlag) = '1' then  --ASL/ASR
              Flags(1) <= '1';
            else
              Flags(1) <= '0';
            end if;
          elsif exec(opcBITS) = '1' then
            Flags(2) <= not one_bit_in;
          elsif exec(opcCHK) = '1' then
            if exe_datatype = "01" then                            --Word
              Flags(3) <= OP1out(15);
            else
              Flags(3) <= OP1out(31);
            end if;
            if OP1out(15 downto 0) = X"0000" and (exe_datatype = "01" or OP1out(31 downto 16) = X"0000") then
              Flags(2) <= '1';
            else
              Flags(2) <= '0';
            end if;
            Flags(1 downto 0) <= "00";
          end if;
        end if;
      end if;
      Flags(7 downto 5) <= "000";
    end if;
  end process;

-------------------------------------------------------------------------------
---- MULU/MULS
-------------------------------------------------------------------------------
  process (exe_opcode, OP2out, muls_msb, mulu_reg, FAsign, mulu_sign, faktorB, result_mulu, signedOP)
  begin
    if (signedOP = '1' and faktorB(31) = '1') or FAsign = '1' then
      muls_msb <= mulu_reg(63);
    else
      muls_msb <= '0';
    end if;

    if signedOP = '1' and faktorB(31) = '1' then
      mulu_sign <= '1';
    else
      mulu_sign <= '0';
    end if;

    if MUL_Mode = 0 then                -- 16 Bit
      result_mulu(63 downto 32) <= muls_msb&mulu_reg(63 downto 33);
      result_mulu(15 downto 0)  <= 'X'&mulu_reg(15 downto 1);
      if mulu_reg(0) = '1' then
        if FAsign = '1' then
          result_mulu(63 downto 47) <= (muls_msb&mulu_reg(63 downto 48)-(mulu_sign&faktorB(31 downto 16)));
        else
          result_mulu(63 downto 47) <= (muls_msb&mulu_reg(63 downto 48)+(mulu_sign&faktorB(31 downto 16)));
        end if;
      end if;
    else                                -- 32 Bit
      result_mulu <= muls_msb&mulu_reg(63 downto 1);
      if mulu_reg(0) = '1' then
        if FAsign = '1' then
          result_mulu(63 downto 31) <= (muls_msb&mulu_reg(63 downto 32)-(mulu_sign&faktorB));
        else
          result_mulu(63 downto 31) <= (muls_msb&mulu_reg(63 downto 32)+(mulu_sign&faktorB));
        end if;
      end if;
    end if;
    if exe_opcode(15) = '1' or MUL_Mode = 0 then
      faktorB(31 downto 16) <= OP2out(15 downto 0);
      faktorB(15 downto 0)  <= (others => '0');
    else
      faktorB <= OP2out;
    end if;
    if (result_mulu(63 downto 32) = X"00000000" and (signedOP = '0' or result_mulu(31) = '0')) or
      (result_mulu(63 downto 32) = X"FFFFFFFF" and signedOP = '1' and result_mulu(31) = '1') then
      set_mV_Flag <= '0';
    else
      set_mV_Flag <= '1';
    end if;
  end process;

  process (clk)
  begin
    if rising_edge(clk) then
      if clkena_lw = '1' then
        if micro_state = mul1 then
          mulu_reg(63 downto 32) <= (others => '0');
          if divs = '1' and ((exe_opcode(15) = '1' and reg_QA(15) = '1') or (exe_opcode(15) = '0' and reg_QA(31) = '1')) then  --MULS Neg faktor
            FAsign                <= '1';
            mulu_reg(31 downto 0) <= 0-reg_QA;
          else
            FAsign                <= '0';
            mulu_reg(31 downto 0) <= reg_QA;
          end if;
        elsif exec(opcMULU) = '0' then
          mulu_reg <= result_mulu;
        end if;
      end if;
    end if;
  end process;

-------------------------------------------------------------------------------
---- DIVU/DIVS
-------------------------------------------------------------------------------

  process (OP2out, div_reg, div_neg, div_bit, div_sub, OP1_sign, div_over, reg_QA, opcode, sndOPC, divs, exe_opcode, reg_QB,
           signedOP, nozero, div_qsign, OP2outext)
  begin
    divs                  <= (opcode(15) and opcode(8)) or (not opcode(15) and sndOPC(11));
    divisor(15 downto 0)  <= (others => '0');
    divisor(63 downto 32) <= (others => divs and reg_QA(31));
    if exe_opcode(15) = '1' or DIV_Mode = 0 then
      divisor(47 downto 16) <= reg_QA;
    else
      divisor(31 downto 0) <= reg_QA;
      if exe_opcode(14) = '1' and sndOPC(10) = '1' then
        divisor(63 downto 32) <= reg_QB;
      end if;
    end if;
    if signedOP = '1' or opcode(15) = '0' then
      OP2outext <= OP2out(31 downto 16);
    else
      OP2outext <= (others => '0');
    end if;
    if signedOP = '1' and OP2out(31) = '1' then
      div_sub <= (div_reg(63 downto 31))+('1'&OP2out(31 downto 0));
    else
      div_sub <= (div_reg(63 downto 31))-('0'&OP2outext(15 downto 0)&OP2out(15 downto 0));
    end if;
    if DIV_Mode = 0 then
      div_bit <= div_sub(16);
    else
      div_bit <= div_sub(32);
    end if;
    if div_bit = '1' then
      div_quot(63 downto 32) <= div_reg(62 downto 31);
    else
      div_quot(63 downto 32) <= div_sub(31 downto 0);
    end if;
    div_quot(31 downto 0) <= div_reg(30 downto 0)&not div_bit;


    if ((nozero = '1' and signedOP = '1' and (OP2out(31) xor OP1_sign xor div_neg xor div_qsign) = '1')  --Overflow DIVS
        or (signedOP = '0' and div_over(32) = '0')) and DIV_Mode/=3 then  --Overflow DIVU
      set_V_Flag <= '1';
    else
      set_V_Flag <= '0';
    end if;
  end process;

  process (clk)
  begin
    if rising_edge(clk) then
      if clkena_lw = '1' then
        V_Flag   <= set_V_Flag;
        signedOP <= divs;
        if micro_state = div1 then
          nozero <= '0';
          if divs = '1' and divisor(63) = '1' then  -- Neg divisor
            OP1_sign <= '1';
            div_reg  <= 0-divisor;
          else
            OP1_sign <= '0';
            div_reg  <= divisor;
          end if;
        else
          div_reg <= div_quot;
          nozero  <= not div_bit or nozero;
        end if;
        if micro_state = div2 then
          div_qsign <= not div_bit;
          div_neg   <= signedOP and (OP2out(31) xor OP1_sign);
          if DIV_Mode = 0 then
            div_over(32 downto 16) <= ('0'&div_reg(47 downto 32))-('0'&OP2out(15 downto 0));
          else
            div_over <= ('0'&div_reg(63 downto 32))-('0'&OP2out);
          end if;
        end if;
        if exec(write_reminder) = '0' then
--              IF exec_DIVU='0' THEN
          if div_neg = '1' then
            result_div(31 downto 0) <= 0-div_quot(31 downto 0);
          else
            result_div(31 downto 0) <= div_quot(31 downto 0);
          end if;

          if OP1_sign = '1' then
            result_div(63 downto 32) <= 0-div_quot(63 downto 32);
          else
            result_div(63 downto 32) <= div_quot(63 downto 32);
          end if;
        end if;
      end if;
    end if;
  end process;
end;
