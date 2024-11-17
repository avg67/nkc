--
--Written by GowinSynthesis
--Tool Version "V1.9.10 (64-bit)"
--Thu Oct  3 21:53:41 2024

--Source file index table:
--file0 "\C:/working/_Tang_nano/_cores/ps2_fifo/fifo_sc_hs.vhdl/temp/FIFO_SC/fifo_sc_hs_define.v"
--file1 "\C:/working/_Tang_nano/_cores/ps2_fifo/fifo_sc_hs.vhdl/temp/FIFO_SC/fifo_sc_hs_parameter.v"
--file2 "\C:/Gowin/Gowin_V1.9.10_x64/IDE/ipcore/FIFO_SC_HS/data/fifo_sc_hs.v"
--file3 "\C:/Gowin/Gowin_V1.9.10_x64/IDE/ipcore/FIFO_SC_HS/data/fifo_sc_hs_top.v"
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library gw2a;
use gw2a.components.all;

entity ps2_fifo is
port(
  Data :  in std_logic_vector(6 downto 0);
  Clk :  in std_logic;
  WrEn :  in std_logic;
  RdEn :  in std_logic;
  Reset :  in std_logic;
  Q :  out std_logic_vector(6 downto 0);
  Empty :  out std_logic;
  Full :  out std_logic);
end ps2_fifo;
architecture beh of ps2_fifo is
  signal fifo_sc_hs_inst_n132 : std_logic ;
  signal fifo_sc_hs_inst_n132_1 : std_logic ;
  signal fifo_sc_hs_inst_n131 : std_logic ;
  signal fifo_sc_hs_inst_n131_1 : std_logic ;
  signal fifo_sc_hs_inst_n130 : std_logic ;
  signal fifo_sc_hs_inst_n130_1 : std_logic ;
  signal fifo_sc_hs_inst_n129 : std_logic ;
  signal fifo_sc_hs_inst_n129_1 : std_logic ;
  signal fifo_sc_hs_inst_n128 : std_logic ;
  signal fifo_sc_hs_inst_n128_1 : std_logic ;
  signal fifo_sc_hs_inst_rbin_next_0 : std_logic ;
  signal fifo_sc_hs_inst_rbin_next_1 : std_logic ;
  signal fifo_sc_hs_inst_rbin_next_2 : std_logic ;
  signal fifo_sc_hs_inst_rbin_next_3 : std_logic ;
  signal fifo_sc_hs_inst_wbin_next_0 : std_logic ;
  signal fifo_sc_hs_inst_wbin_next_1 : std_logic ;
  signal fifo_sc_hs_inst_wbin_next_2 : std_logic ;
  signal fifo_sc_hs_inst_wbin_next_3 : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_0_G[0]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_0_G[1]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_0_G[2]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_0_G[3]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_0_G[4]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_0_G[5]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_0_G[6]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_1_G[0]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_1_G[1]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_1_G[2]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_1_G[3]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_1_G[4]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_1_G[5]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_1_G[6]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_2_G[0]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_2_G[1]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_2_G[2]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_2_G[3]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_2_G[4]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_2_G[5]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_2_G[6]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_3_G[0]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_3_G[1]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_3_G[2]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_3_G[3]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_3_G[4]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_3_G[5]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_3_G[6]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_4_G[0]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_4_G[1]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_4_G[2]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_4_G[3]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_4_G[4]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_4_G[5]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_4_G[6]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_5_G[0]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_5_G[1]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_5_G[2]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_5_G[3]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_5_G[4]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_5_G[5]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_5_G[6]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_6_G[0]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_6_G[1]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_6_G[2]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_6_G[3]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_6_G[4]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_6_G[5]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_6_G[6]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_7_G[0]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_7_G[1]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_7_G[2]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_7_G[3]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_7_G[4]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_7_G[5]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_7_G[6]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_8_G[0]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_8_G[1]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_8_G[2]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_8_G[3]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_8_G[4]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_8_G[5]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_8_G[6]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_9_G[0]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_9_G[1]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_9_G[2]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_9_G[3]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_9_G[4]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_9_G[5]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_9_G[6]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_10_G[0]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_10_G[1]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_10_G[2]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_10_G[3]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_10_G[4]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_10_G[5]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_10_G[6]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_11_G[0]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_11_G[1]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_11_G[2]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_11_G[3]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_11_G[4]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_11_G[5]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_11_G[6]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_12_G[0]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_12_G[1]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_12_G[2]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_12_G[3]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_12_G[4]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_12_G[5]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_12_G[6]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_13_G[0]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_13_G[1]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_13_G[2]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_13_G[3]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_13_G[4]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_13_G[5]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_13_G[6]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_14_G[0]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_14_G[1]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_14_G[2]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_14_G[3]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_14_G[4]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_14_G[5]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_14_G[6]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_15_G[0]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_15_G[1]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_15_G[2]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_15_G[3]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_15_G[4]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_15_G[5]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_mem_RAMREG_15_G[6]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_7_G[3]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_7_G[3]_18\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_7_G[3]_19\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_7_G[3]_20\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_7_G[3]_21\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_7_G[3]_22\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_7_G[3]_23\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_7_G[3]_24\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_22_G[3]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_22_G[3]_18\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_22_G[3]_19\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_22_G[3]_20\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_22_G[3]_21\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_22_G[3]_22\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_22_G[3]_23\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_22_G[3]_24\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_37_G[3]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_37_G[3]_18\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_37_G[3]_19\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_37_G[3]_20\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_37_G[3]_21\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_37_G[3]_22\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_37_G[3]_23\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_37_G[3]_24\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_52_G[3]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_52_G[3]_18\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_52_G[3]_19\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_52_G[3]_20\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_52_G[3]_21\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_52_G[3]_22\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_52_G[3]_23\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_52_G[3]_24\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_67_G[3]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_67_G[3]_18\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_67_G[3]_19\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_67_G[3]_20\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_67_G[3]_21\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_67_G[3]_22\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_67_G[3]_23\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_67_G[3]_24\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_82_G[3]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_82_G[3]_18\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_82_G[3]_19\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_82_G[3]_20\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_82_G[3]_21\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_82_G[3]_22\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_82_G[3]_23\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_82_G[3]_24\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_97_G[3]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_97_G[3]_18\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_97_G[3]_19\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_97_G[3]_20\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_97_G[3]_21\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_97_G[3]_22\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_97_G[3]_23\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_97_G[3]_24\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_7_G[3]_26\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_7_G[3]_28\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_7_G[3]_30\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_7_G[3]_32\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_22_G[3]_26\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_22_G[3]_28\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_22_G[3]_30\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_22_G[3]_32\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_37_G[3]_26\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_37_G[3]_28\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_37_G[3]_30\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_37_G[3]_32\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_52_G[3]_26\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_52_G[3]_28\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_52_G[3]_30\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_52_G[3]_32\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_67_G[3]_26\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_67_G[3]_28\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_67_G[3]_30\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_67_G[3]_32\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_82_G[3]_26\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_82_G[3]_28\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_82_G[3]_30\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_82_G[3]_32\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_97_G[3]_26\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_97_G[3]_28\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_97_G[3]_30\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_97_G[3]_32\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_7_G[3]_34\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_7_G[3]_36\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_22_G[3]_34\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_22_G[3]_36\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_37_G[3]_34\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_37_G[3]_36\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_52_G[3]_34\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_52_G[3]_36\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_67_G[3]_34\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_67_G[3]_36\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_82_G[3]_34\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_82_G[3]_36\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_97_G[3]_34\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_97_G[3]_36\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_0_G[0]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_15_G[0]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_30_G[0]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_45_G[0]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_60_G[0]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_75_G[0]\ : std_logic ;
  signal \fifo_sc_hs_inst_mem_RAMOUT_90_G[0]\ : std_logic ;
  signal fifo_sc_hs_inst_n7 : std_logic ;
  signal fifo_sc_hs_inst_n11 : std_logic ;
  signal fifo_sc_hs_inst_n82 : std_logic ;
  signal fifo_sc_hs_inst_Wnum_4 : std_logic ;
  signal fifo_sc_hs_inst_mem : std_logic ;
  signal fifo_sc_hs_inst_mem_239 : std_logic ;
  signal fifo_sc_hs_inst_mem_241 : std_logic ;
  signal fifo_sc_hs_inst_mem_243 : std_logic ;
  signal fifo_sc_hs_inst_mem_245 : std_logic ;
  signal fifo_sc_hs_inst_mem_247 : std_logic ;
  signal fifo_sc_hs_inst_mem_249 : std_logic ;
  signal fifo_sc_hs_inst_mem_251 : std_logic ;
  signal fifo_sc_hs_inst_mem_253 : std_logic ;
  signal fifo_sc_hs_inst_mem_255 : std_logic ;
  signal fifo_sc_hs_inst_mem_257 : std_logic ;
  signal fifo_sc_hs_inst_mem_259 : std_logic ;
  signal fifo_sc_hs_inst_mem_261 : std_logic ;
  signal fifo_sc_hs_inst_mem_263 : std_logic ;
  signal fifo_sc_hs_inst_mem_265 : std_logic ;
  signal fifo_sc_hs_inst_mem_267 : std_logic ;
  signal fifo_sc_hs_inst_n7_5 : std_logic ;
  signal fifo_sc_hs_inst_mem_268 : std_logic ;
  signal fifo_sc_hs_inst_mem_269 : std_logic ;
  signal fifo_sc_hs_inst_mem_270 : std_logic ;
  signal fifo_sc_hs_inst_mem_271 : std_logic ;
  signal fifo_sc_hs_inst_mem_272 : std_logic ;
  signal fifo_sc_hs_inst_mem_273 : std_logic ;
  signal fifo_sc_hs_inst_mem_274 : std_logic ;
  signal fifo_sc_hs_inst_mem_275 : std_logic ;
  signal fifo_sc_hs_inst_mem_276 : std_logic ;
  signal fifo_sc_hs_inst_mem_277 : std_logic ;
  signal fifo_sc_hs_inst_n82_1 : std_logic ;
  signal GND_0 : std_logic ;
  signal VCC_0 : std_logic ;
  signal \fifo_sc_hs_inst/rbin\ : std_logic_vector(3 downto 0);
  signal \fifo_sc_hs_inst/wbin\ : std_logic_vector(3 downto 0);
  signal \fifo_sc_hs_inst/Wnum\ : std_logic_vector(4 downto 0);
  signal \fifo_sc_hs_inst/rbin_next\ : std_logic_vector(3 downto 0);
  signal \fifo_sc_hs_inst/wbin_next\ : std_logic_vector(3 downto 0);
begin
\fifo_sc_hs_inst/Q_r2_5_s0\: DFFCE
port map (
  Q => Q(5),
  D => \fifo_sc_hs_inst_mem_RAMOUT_75_G[0]\,
  CLK => Clk,
  CE => fifo_sc_hs_inst_n11,
  CLEAR => Reset);
\fifo_sc_hs_inst/Q_r2_4_s0\: DFFCE
port map (
  Q => Q(4),
  D => \fifo_sc_hs_inst_mem_RAMOUT_60_G[0]\,
  CLK => Clk,
  CE => fifo_sc_hs_inst_n11,
  CLEAR => Reset);
\fifo_sc_hs_inst/Q_r2_3_s0\: DFFCE
port map (
  Q => Q(3),
  D => \fifo_sc_hs_inst_mem_RAMOUT_45_G[0]\,
  CLK => Clk,
  CE => fifo_sc_hs_inst_n11,
  CLEAR => Reset);
\fifo_sc_hs_inst/Q_r2_2_s0\: DFFCE
port map (
  Q => Q(2),
  D => \fifo_sc_hs_inst_mem_RAMOUT_30_G[0]\,
  CLK => Clk,
  CE => fifo_sc_hs_inst_n11,
  CLEAR => Reset);
\fifo_sc_hs_inst/Q_r2_1_s0\: DFFCE
port map (
  Q => Q(1),
  D => \fifo_sc_hs_inst_mem_RAMOUT_15_G[0]\,
  CLK => Clk,
  CE => fifo_sc_hs_inst_n11,
  CLEAR => Reset);
\fifo_sc_hs_inst/Q_r2_0_s0\: DFFCE
port map (
  Q => Q(0),
  D => \fifo_sc_hs_inst_mem_RAMOUT_0_G[0]\,
  CLK => Clk,
  CE => fifo_sc_hs_inst_n11,
  CLEAR => Reset);
\fifo_sc_hs_inst/rbin_3_s0\: DFFC
port map (
  Q => \fifo_sc_hs_inst/rbin\(3),
  D => \fifo_sc_hs_inst/rbin_next\(3),
  CLK => Clk,
  CLEAR => Reset);
\fifo_sc_hs_inst/rbin_2_s0\: DFFC
port map (
  Q => \fifo_sc_hs_inst/rbin\(2),
  D => \fifo_sc_hs_inst/rbin_next\(2),
  CLK => Clk,
  CLEAR => Reset);
\fifo_sc_hs_inst/rbin_1_s0\: DFFC
port map (
  Q => \fifo_sc_hs_inst/rbin\(1),
  D => \fifo_sc_hs_inst/rbin_next\(1),
  CLK => Clk,
  CLEAR => Reset);
\fifo_sc_hs_inst/rbin_0_s0\: DFFC
port map (
  Q => \fifo_sc_hs_inst/rbin\(0),
  D => \fifo_sc_hs_inst/rbin_next\(0),
  CLK => Clk,
  CLEAR => Reset);
\fifo_sc_hs_inst/wbin_3_s0\: DFFC
port map (
  Q => \fifo_sc_hs_inst/wbin\(3),
  D => \fifo_sc_hs_inst/wbin_next\(3),
  CLK => Clk,
  CLEAR => Reset);
\fifo_sc_hs_inst/wbin_2_s0\: DFFC
port map (
  Q => \fifo_sc_hs_inst/wbin\(2),
  D => \fifo_sc_hs_inst/wbin_next\(2),
  CLK => Clk,
  CLEAR => Reset);
\fifo_sc_hs_inst/wbin_1_s0\: DFFC
port map (
  Q => \fifo_sc_hs_inst/wbin\(1),
  D => \fifo_sc_hs_inst/wbin_next\(1),
  CLK => Clk,
  CLEAR => Reset);
\fifo_sc_hs_inst/wbin_0_s0\: DFFC
port map (
  Q => \fifo_sc_hs_inst/wbin\(0),
  D => \fifo_sc_hs_inst/wbin_next\(0),
  CLK => Clk,
  CLEAR => Reset);
\fifo_sc_hs_inst/Q_r2_6_s0\: DFFCE
port map (
  Q => Q(6),
  D => \fifo_sc_hs_inst_mem_RAMOUT_90_G[0]\,
  CLK => Clk,
  CE => fifo_sc_hs_inst_n11,
  CLEAR => Reset);
\fifo_sc_hs_inst/Wnum_4_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \fifo_sc_hs_inst/Wnum\(4),
  D => fifo_sc_hs_inst_n128,
  CLK => Clk,
  CE => fifo_sc_hs_inst_Wnum_4,
  CLEAR => Reset);
\fifo_sc_hs_inst/Wnum_3_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \fifo_sc_hs_inst/Wnum\(3),
  D => fifo_sc_hs_inst_n129,
  CLK => Clk,
  CE => fifo_sc_hs_inst_Wnum_4,
  CLEAR => Reset);
\fifo_sc_hs_inst/Wnum_2_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \fifo_sc_hs_inst/Wnum\(2),
  D => fifo_sc_hs_inst_n130,
  CLK => Clk,
  CE => fifo_sc_hs_inst_Wnum_4,
  CLEAR => Reset);
\fifo_sc_hs_inst/Wnum_1_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \fifo_sc_hs_inst/Wnum\(1),
  D => fifo_sc_hs_inst_n131,
  CLK => Clk,
  CE => fifo_sc_hs_inst_Wnum_4,
  CLEAR => Reset);
\fifo_sc_hs_inst/Wnum_0_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \fifo_sc_hs_inst/Wnum\(0),
  D => fifo_sc_hs_inst_n132,
  CLK => Clk,
  CE => fifo_sc_hs_inst_Wnum_4,
  CLEAR => Reset);
\fifo_sc_hs_inst/n132_1_s\: ALU
generic map (
  ALU_MODE => 2
)
port map (
  SUM => fifo_sc_hs_inst_n132,
  COUT => fifo_sc_hs_inst_n132_1,
  I0 => \fifo_sc_hs_inst/Wnum\(0),
  I1 => VCC_0,
  I3 => fifo_sc_hs_inst_n82,
  CIN => fifo_sc_hs_inst_n82_1);
\fifo_sc_hs_inst/n131_1_s\: ALU
generic map (
  ALU_MODE => 2
)
port map (
  SUM => fifo_sc_hs_inst_n131,
  COUT => fifo_sc_hs_inst_n131_1,
  I0 => \fifo_sc_hs_inst/Wnum\(1),
  I1 => GND_0,
  I3 => fifo_sc_hs_inst_n82,
  CIN => fifo_sc_hs_inst_n132_1);
\fifo_sc_hs_inst/n130_1_s\: ALU
generic map (
  ALU_MODE => 2
)
port map (
  SUM => fifo_sc_hs_inst_n130,
  COUT => fifo_sc_hs_inst_n130_1,
  I0 => \fifo_sc_hs_inst/Wnum\(2),
  I1 => GND_0,
  I3 => fifo_sc_hs_inst_n82,
  CIN => fifo_sc_hs_inst_n131_1);
\fifo_sc_hs_inst/n129_1_s\: ALU
generic map (
  ALU_MODE => 2
)
port map (
  SUM => fifo_sc_hs_inst_n129,
  COUT => fifo_sc_hs_inst_n129_1,
  I0 => \fifo_sc_hs_inst/Wnum\(3),
  I1 => GND_0,
  I3 => fifo_sc_hs_inst_n82,
  CIN => fifo_sc_hs_inst_n130_1);
\fifo_sc_hs_inst/n128_1_s\: ALU
generic map (
  ALU_MODE => 2
)
port map (
  SUM => fifo_sc_hs_inst_n128,
  COUT => fifo_sc_hs_inst_n128_1,
  I0 => \fifo_sc_hs_inst/Wnum\(4),
  I1 => GND_0,
  I3 => fifo_sc_hs_inst_n82,
  CIN => fifo_sc_hs_inst_n129_1);
\fifo_sc_hs_inst/rbin_next_0_s\: ALU
generic map (
  ALU_MODE => 0
)
port map (
  SUM => \fifo_sc_hs_inst/rbin_next\(0),
  COUT => fifo_sc_hs_inst_rbin_next_0,
  I0 => \fifo_sc_hs_inst/rbin\(0),
  I1 => fifo_sc_hs_inst_n11,
  I3 => GND_0,
  CIN => GND_0);
\fifo_sc_hs_inst/rbin_next_1_s\: ALU
generic map (
  ALU_MODE => 0
)
port map (
  SUM => \fifo_sc_hs_inst/rbin_next\(1),
  COUT => fifo_sc_hs_inst_rbin_next_1,
  I0 => \fifo_sc_hs_inst/rbin\(1),
  I1 => GND_0,
  I3 => GND_0,
  CIN => fifo_sc_hs_inst_rbin_next_0);
\fifo_sc_hs_inst/rbin_next_2_s\: ALU
generic map (
  ALU_MODE => 0
)
port map (
  SUM => \fifo_sc_hs_inst/rbin_next\(2),
  COUT => fifo_sc_hs_inst_rbin_next_2,
  I0 => \fifo_sc_hs_inst/rbin\(2),
  I1 => GND_0,
  I3 => GND_0,
  CIN => fifo_sc_hs_inst_rbin_next_1);
\fifo_sc_hs_inst/rbin_next_3_s\: ALU
generic map (
  ALU_MODE => 0
)
port map (
  SUM => \fifo_sc_hs_inst/rbin_next\(3),
  COUT => fifo_sc_hs_inst_rbin_next_3,
  I0 => \fifo_sc_hs_inst/rbin\(3),
  I1 => GND_0,
  I3 => GND_0,
  CIN => fifo_sc_hs_inst_rbin_next_2);
\fifo_sc_hs_inst/wbin_next_0_s\: ALU
generic map (
  ALU_MODE => 0
)
port map (
  SUM => \fifo_sc_hs_inst/wbin_next\(0),
  COUT => fifo_sc_hs_inst_wbin_next_0,
  I0 => \fifo_sc_hs_inst/wbin\(0),
  I1 => fifo_sc_hs_inst_n7,
  I3 => GND_0,
  CIN => GND_0);
\fifo_sc_hs_inst/wbin_next_1_s\: ALU
generic map (
  ALU_MODE => 0
)
port map (
  SUM => \fifo_sc_hs_inst/wbin_next\(1),
  COUT => fifo_sc_hs_inst_wbin_next_1,
  I0 => \fifo_sc_hs_inst/wbin\(1),
  I1 => GND_0,
  I3 => GND_0,
  CIN => fifo_sc_hs_inst_wbin_next_0);
\fifo_sc_hs_inst/wbin_next_2_s\: ALU
generic map (
  ALU_MODE => 0
)
port map (
  SUM => \fifo_sc_hs_inst/wbin_next\(2),
  COUT => fifo_sc_hs_inst_wbin_next_2,
  I0 => \fifo_sc_hs_inst/wbin\(2),
  I1 => GND_0,
  I3 => GND_0,
  CIN => fifo_sc_hs_inst_wbin_next_1);
\fifo_sc_hs_inst/wbin_next_3_s\: ALU
generic map (
  ALU_MODE => 0
)
port map (
  SUM => \fifo_sc_hs_inst/wbin_next\(3),
  COUT => fifo_sc_hs_inst_wbin_next_3,
  I0 => \fifo_sc_hs_inst/wbin\(3),
  I1 => GND_0,
  I3 => GND_0,
  CIN => fifo_sc_hs_inst_wbin_next_2);
\fifo_sc_hs_inst/mem_mem_RAMREG_0_G[0]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_0_G[0]\,
  D => Data(0),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem);
\fifo_sc_hs_inst/mem_mem_RAMREG_0_G[1]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_0_G[1]\,
  D => Data(1),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem);
\fifo_sc_hs_inst/mem_mem_RAMREG_0_G[2]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_0_G[2]\,
  D => Data(2),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem);
\fifo_sc_hs_inst/mem_mem_RAMREG_0_G[3]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_0_G[3]\,
  D => Data(3),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem);
\fifo_sc_hs_inst/mem_mem_RAMREG_0_G[4]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_0_G[4]\,
  D => Data(4),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem);
\fifo_sc_hs_inst/mem_mem_RAMREG_0_G[5]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_0_G[5]\,
  D => Data(5),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem);
\fifo_sc_hs_inst/mem_mem_RAMREG_0_G[6]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_0_G[6]\,
  D => Data(6),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem);
\fifo_sc_hs_inst/mem_mem_RAMREG_1_G[0]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_1_G[0]\,
  D => Data(0),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_239);
\fifo_sc_hs_inst/mem_mem_RAMREG_1_G[1]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_1_G[1]\,
  D => Data(1),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_239);
\fifo_sc_hs_inst/mem_mem_RAMREG_1_G[2]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_1_G[2]\,
  D => Data(2),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_239);
\fifo_sc_hs_inst/mem_mem_RAMREG_1_G[3]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_1_G[3]\,
  D => Data(3),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_239);
\fifo_sc_hs_inst/mem_mem_RAMREG_1_G[4]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_1_G[4]\,
  D => Data(4),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_239);
\fifo_sc_hs_inst/mem_mem_RAMREG_1_G[5]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_1_G[5]\,
  D => Data(5),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_239);
\fifo_sc_hs_inst/mem_mem_RAMREG_1_G[6]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_1_G[6]\,
  D => Data(6),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_239);
\fifo_sc_hs_inst/mem_mem_RAMREG_2_G[0]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_2_G[0]\,
  D => Data(0),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_241);
\fifo_sc_hs_inst/mem_mem_RAMREG_2_G[1]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_2_G[1]\,
  D => Data(1),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_241);
\fifo_sc_hs_inst/mem_mem_RAMREG_2_G[2]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_2_G[2]\,
  D => Data(2),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_241);
\fifo_sc_hs_inst/mem_mem_RAMREG_2_G[3]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_2_G[3]\,
  D => Data(3),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_241);
\fifo_sc_hs_inst/mem_mem_RAMREG_2_G[4]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_2_G[4]\,
  D => Data(4),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_241);
\fifo_sc_hs_inst/mem_mem_RAMREG_2_G[5]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_2_G[5]\,
  D => Data(5),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_241);
\fifo_sc_hs_inst/mem_mem_RAMREG_2_G[6]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_2_G[6]\,
  D => Data(6),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_241);
\fifo_sc_hs_inst/mem_mem_RAMREG_3_G[0]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_3_G[0]\,
  D => Data(0),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_243);
\fifo_sc_hs_inst/mem_mem_RAMREG_3_G[1]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_3_G[1]\,
  D => Data(1),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_243);
\fifo_sc_hs_inst/mem_mem_RAMREG_3_G[2]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_3_G[2]\,
  D => Data(2),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_243);
\fifo_sc_hs_inst/mem_mem_RAMREG_3_G[3]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_3_G[3]\,
  D => Data(3),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_243);
\fifo_sc_hs_inst/mem_mem_RAMREG_3_G[4]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_3_G[4]\,
  D => Data(4),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_243);
\fifo_sc_hs_inst/mem_mem_RAMREG_3_G[5]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_3_G[5]\,
  D => Data(5),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_243);
\fifo_sc_hs_inst/mem_mem_RAMREG_3_G[6]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_3_G[6]\,
  D => Data(6),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_243);
\fifo_sc_hs_inst/mem_mem_RAMREG_4_G[0]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_4_G[0]\,
  D => Data(0),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_245);
\fifo_sc_hs_inst/mem_mem_RAMREG_4_G[1]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_4_G[1]\,
  D => Data(1),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_245);
\fifo_sc_hs_inst/mem_mem_RAMREG_4_G[2]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_4_G[2]\,
  D => Data(2),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_245);
\fifo_sc_hs_inst/mem_mem_RAMREG_4_G[3]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_4_G[3]\,
  D => Data(3),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_245);
\fifo_sc_hs_inst/mem_mem_RAMREG_4_G[4]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_4_G[4]\,
  D => Data(4),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_245);
\fifo_sc_hs_inst/mem_mem_RAMREG_4_G[5]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_4_G[5]\,
  D => Data(5),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_245);
\fifo_sc_hs_inst/mem_mem_RAMREG_4_G[6]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_4_G[6]\,
  D => Data(6),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_245);
\fifo_sc_hs_inst/mem_mem_RAMREG_5_G[0]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_5_G[0]\,
  D => Data(0),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_247);
\fifo_sc_hs_inst/mem_mem_RAMREG_5_G[1]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_5_G[1]\,
  D => Data(1),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_247);
\fifo_sc_hs_inst/mem_mem_RAMREG_5_G[2]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_5_G[2]\,
  D => Data(2),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_247);
\fifo_sc_hs_inst/mem_mem_RAMREG_5_G[3]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_5_G[3]\,
  D => Data(3),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_247);
\fifo_sc_hs_inst/mem_mem_RAMREG_5_G[4]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_5_G[4]\,
  D => Data(4),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_247);
\fifo_sc_hs_inst/mem_mem_RAMREG_5_G[5]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_5_G[5]\,
  D => Data(5),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_247);
\fifo_sc_hs_inst/mem_mem_RAMREG_5_G[6]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_5_G[6]\,
  D => Data(6),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_247);
\fifo_sc_hs_inst/mem_mem_RAMREG_6_G[0]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_6_G[0]\,
  D => Data(0),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_249);
\fifo_sc_hs_inst/mem_mem_RAMREG_6_G[1]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_6_G[1]\,
  D => Data(1),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_249);
\fifo_sc_hs_inst/mem_mem_RAMREG_6_G[2]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_6_G[2]\,
  D => Data(2),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_249);
\fifo_sc_hs_inst/mem_mem_RAMREG_6_G[3]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_6_G[3]\,
  D => Data(3),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_249);
\fifo_sc_hs_inst/mem_mem_RAMREG_6_G[4]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_6_G[4]\,
  D => Data(4),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_249);
\fifo_sc_hs_inst/mem_mem_RAMREG_6_G[5]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_6_G[5]\,
  D => Data(5),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_249);
\fifo_sc_hs_inst/mem_mem_RAMREG_6_G[6]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_6_G[6]\,
  D => Data(6),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_249);
\fifo_sc_hs_inst/mem_mem_RAMREG_7_G[0]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_7_G[0]\,
  D => Data(0),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_251);
\fifo_sc_hs_inst/mem_mem_RAMREG_7_G[1]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_7_G[1]\,
  D => Data(1),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_251);
\fifo_sc_hs_inst/mem_mem_RAMREG_7_G[2]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_7_G[2]\,
  D => Data(2),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_251);
\fifo_sc_hs_inst/mem_mem_RAMREG_7_G[3]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_7_G[3]\,
  D => Data(3),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_251);
\fifo_sc_hs_inst/mem_mem_RAMREG_7_G[4]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_7_G[4]\,
  D => Data(4),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_251);
\fifo_sc_hs_inst/mem_mem_RAMREG_7_G[5]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_7_G[5]\,
  D => Data(5),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_251);
\fifo_sc_hs_inst/mem_mem_RAMREG_7_G[6]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_7_G[6]\,
  D => Data(6),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_251);
\fifo_sc_hs_inst/mem_mem_RAMREG_8_G[0]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_8_G[0]\,
  D => Data(0),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_253);
\fifo_sc_hs_inst/mem_mem_RAMREG_8_G[1]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_8_G[1]\,
  D => Data(1),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_253);
\fifo_sc_hs_inst/mem_mem_RAMREG_8_G[2]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_8_G[2]\,
  D => Data(2),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_253);
\fifo_sc_hs_inst/mem_mem_RAMREG_8_G[3]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_8_G[3]\,
  D => Data(3),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_253);
\fifo_sc_hs_inst/mem_mem_RAMREG_8_G[4]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_8_G[4]\,
  D => Data(4),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_253);
\fifo_sc_hs_inst/mem_mem_RAMREG_8_G[5]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_8_G[5]\,
  D => Data(5),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_253);
\fifo_sc_hs_inst/mem_mem_RAMREG_8_G[6]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_8_G[6]\,
  D => Data(6),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_253);
\fifo_sc_hs_inst/mem_mem_RAMREG_9_G[0]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_9_G[0]\,
  D => Data(0),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_255);
\fifo_sc_hs_inst/mem_mem_RAMREG_9_G[1]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_9_G[1]\,
  D => Data(1),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_255);
\fifo_sc_hs_inst/mem_mem_RAMREG_9_G[2]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_9_G[2]\,
  D => Data(2),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_255);
\fifo_sc_hs_inst/mem_mem_RAMREG_9_G[3]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_9_G[3]\,
  D => Data(3),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_255);
\fifo_sc_hs_inst/mem_mem_RAMREG_9_G[4]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_9_G[4]\,
  D => Data(4),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_255);
\fifo_sc_hs_inst/mem_mem_RAMREG_9_G[5]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_9_G[5]\,
  D => Data(5),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_255);
\fifo_sc_hs_inst/mem_mem_RAMREG_9_G[6]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_9_G[6]\,
  D => Data(6),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_255);
\fifo_sc_hs_inst/mem_mem_RAMREG_10_G[0]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_10_G[0]\,
  D => Data(0),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_257);
\fifo_sc_hs_inst/mem_mem_RAMREG_10_G[1]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_10_G[1]\,
  D => Data(1),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_257);
\fifo_sc_hs_inst/mem_mem_RAMREG_10_G[2]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_10_G[2]\,
  D => Data(2),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_257);
\fifo_sc_hs_inst/mem_mem_RAMREG_10_G[3]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_10_G[3]\,
  D => Data(3),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_257);
\fifo_sc_hs_inst/mem_mem_RAMREG_10_G[4]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_10_G[4]\,
  D => Data(4),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_257);
\fifo_sc_hs_inst/mem_mem_RAMREG_10_G[5]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_10_G[5]\,
  D => Data(5),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_257);
\fifo_sc_hs_inst/mem_mem_RAMREG_10_G[6]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_10_G[6]\,
  D => Data(6),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_257);
\fifo_sc_hs_inst/mem_mem_RAMREG_11_G[0]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_11_G[0]\,
  D => Data(0),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_259);
\fifo_sc_hs_inst/mem_mem_RAMREG_11_G[1]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_11_G[1]\,
  D => Data(1),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_259);
\fifo_sc_hs_inst/mem_mem_RAMREG_11_G[2]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_11_G[2]\,
  D => Data(2),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_259);
\fifo_sc_hs_inst/mem_mem_RAMREG_11_G[3]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_11_G[3]\,
  D => Data(3),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_259);
\fifo_sc_hs_inst/mem_mem_RAMREG_11_G[4]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_11_G[4]\,
  D => Data(4),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_259);
\fifo_sc_hs_inst/mem_mem_RAMREG_11_G[5]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_11_G[5]\,
  D => Data(5),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_259);
\fifo_sc_hs_inst/mem_mem_RAMREG_11_G[6]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_11_G[6]\,
  D => Data(6),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_259);
\fifo_sc_hs_inst/mem_mem_RAMREG_12_G[0]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_12_G[0]\,
  D => Data(0),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_261);
\fifo_sc_hs_inst/mem_mem_RAMREG_12_G[1]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_12_G[1]\,
  D => Data(1),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_261);
\fifo_sc_hs_inst/mem_mem_RAMREG_12_G[2]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_12_G[2]\,
  D => Data(2),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_261);
\fifo_sc_hs_inst/mem_mem_RAMREG_12_G[3]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_12_G[3]\,
  D => Data(3),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_261);
\fifo_sc_hs_inst/mem_mem_RAMREG_12_G[4]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_12_G[4]\,
  D => Data(4),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_261);
\fifo_sc_hs_inst/mem_mem_RAMREG_12_G[5]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_12_G[5]\,
  D => Data(5),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_261);
\fifo_sc_hs_inst/mem_mem_RAMREG_12_G[6]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_12_G[6]\,
  D => Data(6),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_261);
\fifo_sc_hs_inst/mem_mem_RAMREG_13_G[0]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_13_G[0]\,
  D => Data(0),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_263);
\fifo_sc_hs_inst/mem_mem_RAMREG_13_G[1]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_13_G[1]\,
  D => Data(1),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_263);
\fifo_sc_hs_inst/mem_mem_RAMREG_13_G[2]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_13_G[2]\,
  D => Data(2),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_263);
\fifo_sc_hs_inst/mem_mem_RAMREG_13_G[3]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_13_G[3]\,
  D => Data(3),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_263);
\fifo_sc_hs_inst/mem_mem_RAMREG_13_G[4]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_13_G[4]\,
  D => Data(4),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_263);
\fifo_sc_hs_inst/mem_mem_RAMREG_13_G[5]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_13_G[5]\,
  D => Data(5),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_263);
\fifo_sc_hs_inst/mem_mem_RAMREG_13_G[6]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_13_G[6]\,
  D => Data(6),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_263);
\fifo_sc_hs_inst/mem_mem_RAMREG_14_G[0]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_14_G[0]\,
  D => Data(0),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_265);
\fifo_sc_hs_inst/mem_mem_RAMREG_14_G[1]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_14_G[1]\,
  D => Data(1),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_265);
\fifo_sc_hs_inst/mem_mem_RAMREG_14_G[2]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_14_G[2]\,
  D => Data(2),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_265);
\fifo_sc_hs_inst/mem_mem_RAMREG_14_G[3]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_14_G[3]\,
  D => Data(3),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_265);
\fifo_sc_hs_inst/mem_mem_RAMREG_14_G[4]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_14_G[4]\,
  D => Data(4),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_265);
\fifo_sc_hs_inst/mem_mem_RAMREG_14_G[5]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_14_G[5]\,
  D => Data(5),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_265);
\fifo_sc_hs_inst/mem_mem_RAMREG_14_G[6]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_14_G[6]\,
  D => Data(6),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_265);
\fifo_sc_hs_inst/mem_mem_RAMREG_15_G[0]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_15_G[0]\,
  D => Data(0),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_267);
\fifo_sc_hs_inst/mem_mem_RAMREG_15_G[1]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_15_G[1]\,
  D => Data(1),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_267);
\fifo_sc_hs_inst/mem_mem_RAMREG_15_G[2]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_15_G[2]\,
  D => Data(2),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_267);
\fifo_sc_hs_inst/mem_mem_RAMREG_15_G[3]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_15_G[3]\,
  D => Data(3),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_267);
\fifo_sc_hs_inst/mem_mem_RAMREG_15_G[4]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_15_G[4]\,
  D => Data(4),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_267);
\fifo_sc_hs_inst/mem_mem_RAMREG_15_G[5]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_15_G[5]\,
  D => Data(5),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_267);
\fifo_sc_hs_inst/mem_mem_RAMREG_15_G[6]_s0\: DFFE
port map (
  Q => \fifo_sc_hs_inst_mem_mem_RAMREG_15_G[6]\,
  D => Data(6),
  CLK => Clk,
  CE => fifo_sc_hs_inst_mem_267);
\fifo_sc_hs_inst/mem_RAMOUT_0_G[0]_s7\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_7_G[3]\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_0_G[0]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_8_G[0]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_0_G[0]_s8\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_7_G[3]_18\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_4_G[0]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_12_G[0]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_0_G[0]_s9\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_7_G[3]_19\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_2_G[0]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_10_G[0]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_0_G[0]_s10\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_7_G[3]_20\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_6_G[0]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_14_G[0]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_0_G[0]_s11\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_7_G[3]_21\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_1_G[0]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_9_G[0]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_0_G[0]_s12\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_7_G[3]_22\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_5_G[0]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_13_G[0]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_0_G[0]_s13\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_7_G[3]_23\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_3_G[0]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_11_G[0]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_0_G[0]_s14\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_7_G[3]_24\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_7_G[0]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_15_G[0]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_15_G[0]_s7\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_22_G[3]\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_0_G[1]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_8_G[1]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_15_G[0]_s8\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_22_G[3]_18\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_4_G[1]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_12_G[1]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_15_G[0]_s9\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_22_G[3]_19\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_2_G[1]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_10_G[1]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_15_G[0]_s10\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_22_G[3]_20\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_6_G[1]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_14_G[1]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_15_G[0]_s11\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_22_G[3]_21\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_1_G[1]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_9_G[1]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_15_G[0]_s12\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_22_G[3]_22\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_5_G[1]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_13_G[1]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_15_G[0]_s13\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_22_G[3]_23\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_3_G[1]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_11_G[1]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_15_G[0]_s14\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_22_G[3]_24\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_7_G[1]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_15_G[1]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_30_G[0]_s7\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_37_G[3]\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_0_G[2]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_8_G[2]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_30_G[0]_s8\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_37_G[3]_18\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_4_G[2]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_12_G[2]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_30_G[0]_s9\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_37_G[3]_19\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_2_G[2]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_10_G[2]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_30_G[0]_s10\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_37_G[3]_20\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_6_G[2]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_14_G[2]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_30_G[0]_s11\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_37_G[3]_21\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_1_G[2]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_9_G[2]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_30_G[0]_s12\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_37_G[3]_22\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_5_G[2]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_13_G[2]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_30_G[0]_s13\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_37_G[3]_23\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_3_G[2]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_11_G[2]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_30_G[0]_s14\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_37_G[3]_24\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_7_G[2]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_15_G[2]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_45_G[0]_s7\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_52_G[3]\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_0_G[3]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_8_G[3]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_45_G[0]_s8\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_52_G[3]_18\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_4_G[3]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_12_G[3]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_45_G[0]_s9\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_52_G[3]_19\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_2_G[3]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_10_G[3]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_45_G[0]_s10\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_52_G[3]_20\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_6_G[3]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_14_G[3]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_45_G[0]_s11\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_52_G[3]_21\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_1_G[3]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_9_G[3]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_45_G[0]_s12\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_52_G[3]_22\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_5_G[3]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_13_G[3]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_45_G[0]_s13\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_52_G[3]_23\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_3_G[3]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_11_G[3]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_45_G[0]_s14\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_52_G[3]_24\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_7_G[3]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_15_G[3]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_60_G[0]_s7\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_67_G[3]\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_0_G[4]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_8_G[4]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_60_G[0]_s8\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_67_G[3]_18\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_4_G[4]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_12_G[4]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_60_G[0]_s9\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_67_G[3]_19\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_2_G[4]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_10_G[4]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_60_G[0]_s10\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_67_G[3]_20\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_6_G[4]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_14_G[4]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_60_G[0]_s11\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_67_G[3]_21\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_1_G[4]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_9_G[4]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_60_G[0]_s12\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_67_G[3]_22\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_5_G[4]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_13_G[4]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_60_G[0]_s13\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_67_G[3]_23\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_3_G[4]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_11_G[4]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_60_G[0]_s14\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_67_G[3]_24\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_7_G[4]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_15_G[4]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_75_G[0]_s7\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_82_G[3]\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_0_G[5]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_8_G[5]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_75_G[0]_s8\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_82_G[3]_18\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_4_G[5]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_12_G[5]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_75_G[0]_s9\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_82_G[3]_19\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_2_G[5]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_10_G[5]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_75_G[0]_s10\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_82_G[3]_20\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_6_G[5]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_14_G[5]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_75_G[0]_s11\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_82_G[3]_21\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_1_G[5]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_9_G[5]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_75_G[0]_s12\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_82_G[3]_22\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_5_G[5]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_13_G[5]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_75_G[0]_s13\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_82_G[3]_23\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_3_G[5]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_11_G[5]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_75_G[0]_s14\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_82_G[3]_24\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_7_G[5]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_15_G[5]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_90_G[0]_s7\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_97_G[3]\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_0_G[6]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_8_G[6]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_90_G[0]_s8\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_97_G[3]_18\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_4_G[6]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_12_G[6]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_90_G[0]_s9\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_97_G[3]_19\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_2_G[6]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_10_G[6]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_90_G[0]_s10\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_97_G[3]_20\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_6_G[6]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_14_G[6]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_90_G[0]_s11\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_97_G[3]_21\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_1_G[6]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_9_G[6]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_90_G[0]_s12\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_97_G[3]_22\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_5_G[6]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_13_G[6]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_90_G[0]_s13\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_97_G[3]_23\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_3_G[6]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_11_G[6]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_90_G[0]_s14\: LUT3
generic map (
  INIT => X"CA"
)
port map (
  F => \fifo_sc_hs_inst_mem_RAMOUT_97_G[3]_24\,
  I0 => \fifo_sc_hs_inst_mem_mem_RAMREG_7_G[6]\,
  I1 => \fifo_sc_hs_inst_mem_mem_RAMREG_15_G[6]\,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/mem_RAMOUT_0_G[0]_s3\: MUX2_LUT5
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_7_G[3]_26\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_7_G[3]\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_7_G[3]_18\,
  S0 => \fifo_sc_hs_inst/rbin\(2));
\fifo_sc_hs_inst/mem_RAMOUT_0_G[0]_s4\: MUX2_LUT5
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_7_G[3]_28\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_7_G[3]_19\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_7_G[3]_20\,
  S0 => \fifo_sc_hs_inst/rbin\(2));
\fifo_sc_hs_inst/mem_RAMOUT_0_G[0]_s5\: MUX2_LUT5
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_7_G[3]_30\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_7_G[3]_21\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_7_G[3]_22\,
  S0 => \fifo_sc_hs_inst/rbin\(2));
\fifo_sc_hs_inst/mem_RAMOUT_0_G[0]_s6\: MUX2_LUT5
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_7_G[3]_32\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_7_G[3]_23\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_7_G[3]_24\,
  S0 => \fifo_sc_hs_inst/rbin\(2));
\fifo_sc_hs_inst/mem_RAMOUT_15_G[0]_s3\: MUX2_LUT5
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_22_G[3]_26\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_22_G[3]\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_22_G[3]_18\,
  S0 => \fifo_sc_hs_inst/rbin\(2));
\fifo_sc_hs_inst/mem_RAMOUT_15_G[0]_s4\: MUX2_LUT5
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_22_G[3]_28\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_22_G[3]_19\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_22_G[3]_20\,
  S0 => \fifo_sc_hs_inst/rbin\(2));
\fifo_sc_hs_inst/mem_RAMOUT_15_G[0]_s5\: MUX2_LUT5
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_22_G[3]_30\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_22_G[3]_21\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_22_G[3]_22\,
  S0 => \fifo_sc_hs_inst/rbin\(2));
\fifo_sc_hs_inst/mem_RAMOUT_15_G[0]_s6\: MUX2_LUT5
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_22_G[3]_32\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_22_G[3]_23\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_22_G[3]_24\,
  S0 => \fifo_sc_hs_inst/rbin\(2));
\fifo_sc_hs_inst/mem_RAMOUT_30_G[0]_s3\: MUX2_LUT5
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_37_G[3]_26\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_37_G[3]\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_37_G[3]_18\,
  S0 => \fifo_sc_hs_inst/rbin\(2));
\fifo_sc_hs_inst/mem_RAMOUT_30_G[0]_s4\: MUX2_LUT5
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_37_G[3]_28\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_37_G[3]_19\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_37_G[3]_20\,
  S0 => \fifo_sc_hs_inst/rbin\(2));
\fifo_sc_hs_inst/mem_RAMOUT_30_G[0]_s5\: MUX2_LUT5
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_37_G[3]_30\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_37_G[3]_21\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_37_G[3]_22\,
  S0 => \fifo_sc_hs_inst/rbin\(2));
\fifo_sc_hs_inst/mem_RAMOUT_30_G[0]_s6\: MUX2_LUT5
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_37_G[3]_32\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_37_G[3]_23\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_37_G[3]_24\,
  S0 => \fifo_sc_hs_inst/rbin\(2));
\fifo_sc_hs_inst/mem_RAMOUT_45_G[0]_s3\: MUX2_LUT5
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_52_G[3]_26\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_52_G[3]\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_52_G[3]_18\,
  S0 => \fifo_sc_hs_inst/rbin\(2));
\fifo_sc_hs_inst/mem_RAMOUT_45_G[0]_s4\: MUX2_LUT5
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_52_G[3]_28\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_52_G[3]_19\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_52_G[3]_20\,
  S0 => \fifo_sc_hs_inst/rbin\(2));
\fifo_sc_hs_inst/mem_RAMOUT_45_G[0]_s5\: MUX2_LUT5
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_52_G[3]_30\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_52_G[3]_21\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_52_G[3]_22\,
  S0 => \fifo_sc_hs_inst/rbin\(2));
\fifo_sc_hs_inst/mem_RAMOUT_45_G[0]_s6\: MUX2_LUT5
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_52_G[3]_32\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_52_G[3]_23\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_52_G[3]_24\,
  S0 => \fifo_sc_hs_inst/rbin\(2));
\fifo_sc_hs_inst/mem_RAMOUT_60_G[0]_s3\: MUX2_LUT5
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_67_G[3]_26\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_67_G[3]\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_67_G[3]_18\,
  S0 => \fifo_sc_hs_inst/rbin\(2));
\fifo_sc_hs_inst/mem_RAMOUT_60_G[0]_s4\: MUX2_LUT5
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_67_G[3]_28\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_67_G[3]_19\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_67_G[3]_20\,
  S0 => \fifo_sc_hs_inst/rbin\(2));
\fifo_sc_hs_inst/mem_RAMOUT_60_G[0]_s5\: MUX2_LUT5
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_67_G[3]_30\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_67_G[3]_21\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_67_G[3]_22\,
  S0 => \fifo_sc_hs_inst/rbin\(2));
\fifo_sc_hs_inst/mem_RAMOUT_60_G[0]_s6\: MUX2_LUT5
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_67_G[3]_32\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_67_G[3]_23\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_67_G[3]_24\,
  S0 => \fifo_sc_hs_inst/rbin\(2));
\fifo_sc_hs_inst/mem_RAMOUT_75_G[0]_s3\: MUX2_LUT5
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_82_G[3]_26\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_82_G[3]\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_82_G[3]_18\,
  S0 => \fifo_sc_hs_inst/rbin\(2));
\fifo_sc_hs_inst/mem_RAMOUT_75_G[0]_s4\: MUX2_LUT5
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_82_G[3]_28\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_82_G[3]_19\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_82_G[3]_20\,
  S0 => \fifo_sc_hs_inst/rbin\(2));
\fifo_sc_hs_inst/mem_RAMOUT_75_G[0]_s5\: MUX2_LUT5
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_82_G[3]_30\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_82_G[3]_21\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_82_G[3]_22\,
  S0 => \fifo_sc_hs_inst/rbin\(2));
\fifo_sc_hs_inst/mem_RAMOUT_75_G[0]_s6\: MUX2_LUT5
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_82_G[3]_32\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_82_G[3]_23\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_82_G[3]_24\,
  S0 => \fifo_sc_hs_inst/rbin\(2));
\fifo_sc_hs_inst/mem_RAMOUT_90_G[0]_s3\: MUX2_LUT5
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_97_G[3]_26\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_97_G[3]\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_97_G[3]_18\,
  S0 => \fifo_sc_hs_inst/rbin\(2));
\fifo_sc_hs_inst/mem_RAMOUT_90_G[0]_s4\: MUX2_LUT5
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_97_G[3]_28\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_97_G[3]_19\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_97_G[3]_20\,
  S0 => \fifo_sc_hs_inst/rbin\(2));
\fifo_sc_hs_inst/mem_RAMOUT_90_G[0]_s5\: MUX2_LUT5
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_97_G[3]_30\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_97_G[3]_21\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_97_G[3]_22\,
  S0 => \fifo_sc_hs_inst/rbin\(2));
\fifo_sc_hs_inst/mem_RAMOUT_90_G[0]_s6\: MUX2_LUT5
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_97_G[3]_32\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_97_G[3]_23\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_97_G[3]_24\,
  S0 => \fifo_sc_hs_inst/rbin\(2));
\fifo_sc_hs_inst/mem_RAMOUT_0_G[0]_s1\: MUX2_LUT6
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_7_G[3]_34\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_7_G[3]_26\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_7_G[3]_28\,
  S0 => \fifo_sc_hs_inst/rbin\(1));
\fifo_sc_hs_inst/mem_RAMOUT_0_G[0]_s2\: MUX2_LUT6
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_7_G[3]_36\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_7_G[3]_30\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_7_G[3]_32\,
  S0 => \fifo_sc_hs_inst/rbin\(1));
\fifo_sc_hs_inst/mem_RAMOUT_15_G[0]_s1\: MUX2_LUT6
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_22_G[3]_34\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_22_G[3]_26\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_22_G[3]_28\,
  S0 => \fifo_sc_hs_inst/rbin\(1));
\fifo_sc_hs_inst/mem_RAMOUT_15_G[0]_s2\: MUX2_LUT6
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_22_G[3]_36\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_22_G[3]_30\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_22_G[3]_32\,
  S0 => \fifo_sc_hs_inst/rbin\(1));
\fifo_sc_hs_inst/mem_RAMOUT_30_G[0]_s1\: MUX2_LUT6
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_37_G[3]_34\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_37_G[3]_26\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_37_G[3]_28\,
  S0 => \fifo_sc_hs_inst/rbin\(1));
\fifo_sc_hs_inst/mem_RAMOUT_30_G[0]_s2\: MUX2_LUT6
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_37_G[3]_36\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_37_G[3]_30\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_37_G[3]_32\,
  S0 => \fifo_sc_hs_inst/rbin\(1));
\fifo_sc_hs_inst/mem_RAMOUT_45_G[0]_s1\: MUX2_LUT6
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_52_G[3]_34\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_52_G[3]_26\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_52_G[3]_28\,
  S0 => \fifo_sc_hs_inst/rbin\(1));
\fifo_sc_hs_inst/mem_RAMOUT_45_G[0]_s2\: MUX2_LUT6
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_52_G[3]_36\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_52_G[3]_30\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_52_G[3]_32\,
  S0 => \fifo_sc_hs_inst/rbin\(1));
\fifo_sc_hs_inst/mem_RAMOUT_60_G[0]_s1\: MUX2_LUT6
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_67_G[3]_34\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_67_G[3]_26\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_67_G[3]_28\,
  S0 => \fifo_sc_hs_inst/rbin\(1));
\fifo_sc_hs_inst/mem_RAMOUT_60_G[0]_s2\: MUX2_LUT6
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_67_G[3]_36\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_67_G[3]_30\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_67_G[3]_32\,
  S0 => \fifo_sc_hs_inst/rbin\(1));
\fifo_sc_hs_inst/mem_RAMOUT_75_G[0]_s1\: MUX2_LUT6
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_82_G[3]_34\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_82_G[3]_26\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_82_G[3]_28\,
  S0 => \fifo_sc_hs_inst/rbin\(1));
\fifo_sc_hs_inst/mem_RAMOUT_75_G[0]_s2\: MUX2_LUT6
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_82_G[3]_36\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_82_G[3]_30\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_82_G[3]_32\,
  S0 => \fifo_sc_hs_inst/rbin\(1));
\fifo_sc_hs_inst/mem_RAMOUT_90_G[0]_s1\: MUX2_LUT6
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_97_G[3]_34\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_97_G[3]_26\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_97_G[3]_28\,
  S0 => \fifo_sc_hs_inst/rbin\(1));
\fifo_sc_hs_inst/mem_RAMOUT_90_G[0]_s2\: MUX2_LUT6
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_97_G[3]_36\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_97_G[3]_30\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_97_G[3]_32\,
  S0 => \fifo_sc_hs_inst/rbin\(1));
\fifo_sc_hs_inst/mem_RAMOUT_0_G[0]_s0\: MUX2_LUT7
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_0_G[0]\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_7_G[3]_34\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_7_G[3]_36\,
  S0 => \fifo_sc_hs_inst/rbin\(0));
\fifo_sc_hs_inst/mem_RAMOUT_15_G[0]_s0\: MUX2_LUT7
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_15_G[0]\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_22_G[3]_34\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_22_G[3]_36\,
  S0 => \fifo_sc_hs_inst/rbin\(0));
\fifo_sc_hs_inst/mem_RAMOUT_30_G[0]_s0\: MUX2_LUT7
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_30_G[0]\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_37_G[3]_34\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_37_G[3]_36\,
  S0 => \fifo_sc_hs_inst/rbin\(0));
\fifo_sc_hs_inst/mem_RAMOUT_45_G[0]_s0\: MUX2_LUT7
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_45_G[0]\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_52_G[3]_34\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_52_G[3]_36\,
  S0 => \fifo_sc_hs_inst/rbin\(0));
\fifo_sc_hs_inst/mem_RAMOUT_60_G[0]_s0\: MUX2_LUT7
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_60_G[0]\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_67_G[3]_34\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_67_G[3]_36\,
  S0 => \fifo_sc_hs_inst/rbin\(0));
\fifo_sc_hs_inst/mem_RAMOUT_75_G[0]_s0\: MUX2_LUT7
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_75_G[0]\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_82_G[3]_34\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_82_G[3]_36\,
  S0 => \fifo_sc_hs_inst/rbin\(0));
\fifo_sc_hs_inst/mem_RAMOUT_90_G[0]_s0\: MUX2_LUT7
port map (
  O => \fifo_sc_hs_inst_mem_RAMOUT_90_G[0]\,
  I0 => \fifo_sc_hs_inst_mem_RAMOUT_97_G[3]_34\,
  I1 => \fifo_sc_hs_inst_mem_RAMOUT_97_G[3]_36\,
  S0 => \fifo_sc_hs_inst/rbin\(0));
\fifo_sc_hs_inst/n7_s0\: LUT3
generic map (
  INIT => X"70"
)
port map (
  F => fifo_sc_hs_inst_n7,
  I0 => \fifo_sc_hs_inst/Wnum\(4),
  I1 => fifo_sc_hs_inst_n7_5,
  I2 => WrEn);
\fifo_sc_hs_inst/n11_s0\: LUT3
generic map (
  INIT => X"B0"
)
port map (
  F => fifo_sc_hs_inst_n11,
  I0 => \fifo_sc_hs_inst/Wnum\(4),
  I1 => fifo_sc_hs_inst_n7_5,
  I2 => RdEn);
\fifo_sc_hs_inst/n82_s0\: LUT4
generic map (
  INIT => X"3500"
)
port map (
  F => fifo_sc_hs_inst_n82,
  I0 => RdEn,
  I1 => \fifo_sc_hs_inst/Wnum\(4),
  I2 => fifo_sc_hs_inst_n7_5,
  I3 => WrEn);
\fifo_sc_hs_inst/Full_d_s\: LUT2
generic map (
  INIT => X"8"
)
port map (
  F => Full,
  I0 => fifo_sc_hs_inst_n7_5,
  I1 => \fifo_sc_hs_inst/Wnum\(4));
\fifo_sc_hs_inst/Empty_d_s\: LUT2
generic map (
  INIT => X"4"
)
port map (
  F => Empty,
  I0 => \fifo_sc_hs_inst/Wnum\(4),
  I1 => fifo_sc_hs_inst_n7_5);
\fifo_sc_hs_inst/Wnum_4_s3\: LUT4
generic map (
  INIT => X"E43C"
)
port map (
  F => fifo_sc_hs_inst_Wnum_4,
  I0 => \fifo_sc_hs_inst/Wnum\(4),
  I1 => WrEn,
  I2 => RdEn,
  I3 => fifo_sc_hs_inst_n7_5);
\fifo_sc_hs_inst/mem_s235\: LUT4
generic map (
  INIT => X"7000"
)
port map (
  F => fifo_sc_hs_inst_mem,
  I0 => \fifo_sc_hs_inst/Wnum\(4),
  I1 => fifo_sc_hs_inst_n7_5,
  I2 => fifo_sc_hs_inst_mem_268,
  I3 => fifo_sc_hs_inst_mem_269);
\fifo_sc_hs_inst/mem_s236\: LUT4
generic map (
  INIT => X"7000"
)
port map (
  F => fifo_sc_hs_inst_mem_239,
  I0 => \fifo_sc_hs_inst/Wnum\(4),
  I1 => fifo_sc_hs_inst_n7_5,
  I2 => fifo_sc_hs_inst_mem_270,
  I3 => fifo_sc_hs_inst_mem_269);
\fifo_sc_hs_inst/mem_s237\: LUT4
generic map (
  INIT => X"7000"
)
port map (
  F => fifo_sc_hs_inst_mem_241,
  I0 => \fifo_sc_hs_inst/Wnum\(4),
  I1 => fifo_sc_hs_inst_n7_5,
  I2 => fifo_sc_hs_inst_mem_271,
  I3 => fifo_sc_hs_inst_mem_269);
\fifo_sc_hs_inst/mem_s238\: LUT4
generic map (
  INIT => X"7000"
)
port map (
  F => fifo_sc_hs_inst_mem_243,
  I0 => \fifo_sc_hs_inst/Wnum\(4),
  I1 => fifo_sc_hs_inst_n7_5,
  I2 => fifo_sc_hs_inst_mem_272,
  I3 => fifo_sc_hs_inst_mem_269);
\fifo_sc_hs_inst/mem_s239\: LUT4
generic map (
  INIT => X"0700"
)
port map (
  F => fifo_sc_hs_inst_mem_245,
  I0 => \fifo_sc_hs_inst/Wnum\(4),
  I1 => fifo_sc_hs_inst_n7_5,
  I2 => \fifo_sc_hs_inst/wbin\(0),
  I3 => fifo_sc_hs_inst_mem_273);
\fifo_sc_hs_inst/mem_s240\: LUT4
generic map (
  INIT => X"7000"
)
port map (
  F => fifo_sc_hs_inst_mem_247,
  I0 => \fifo_sc_hs_inst/Wnum\(4),
  I1 => fifo_sc_hs_inst_n7_5,
  I2 => fifo_sc_hs_inst_mem_273,
  I3 => \fifo_sc_hs_inst/wbin\(0));
\fifo_sc_hs_inst/mem_s241\: LUT4
generic map (
  INIT => X"7000"
)
port map (
  F => fifo_sc_hs_inst_mem_249,
  I0 => \fifo_sc_hs_inst/Wnum\(4),
  I1 => fifo_sc_hs_inst_n7_5,
  I2 => fifo_sc_hs_inst_mem_274,
  I3 => fifo_sc_hs_inst_mem_271);
\fifo_sc_hs_inst/mem_s242\: LUT4
generic map (
  INIT => X"7000"
)
port map (
  F => fifo_sc_hs_inst_mem_251,
  I0 => \fifo_sc_hs_inst/Wnum\(4),
  I1 => fifo_sc_hs_inst_n7_5,
  I2 => fifo_sc_hs_inst_mem_274,
  I3 => fifo_sc_hs_inst_mem_272);
\fifo_sc_hs_inst/mem_s243\: LUT4
generic map (
  INIT => X"7000"
)
port map (
  F => fifo_sc_hs_inst_mem_253,
  I0 => \fifo_sc_hs_inst/Wnum\(4),
  I1 => fifo_sc_hs_inst_n7_5,
  I2 => fifo_sc_hs_inst_mem_275,
  I3 => fifo_sc_hs_inst_mem_268);
\fifo_sc_hs_inst/mem_s244\: LUT4
generic map (
  INIT => X"7000"
)
port map (
  F => fifo_sc_hs_inst_mem_255,
  I0 => \fifo_sc_hs_inst/Wnum\(4),
  I1 => fifo_sc_hs_inst_n7_5,
  I2 => fifo_sc_hs_inst_mem_275,
  I3 => fifo_sc_hs_inst_mem_270);
\fifo_sc_hs_inst/mem_s245\: LUT4
generic map (
  INIT => X"7000"
)
port map (
  F => fifo_sc_hs_inst_mem_257,
  I0 => \fifo_sc_hs_inst/Wnum\(4),
  I1 => fifo_sc_hs_inst_n7_5,
  I2 => fifo_sc_hs_inst_mem_275,
  I3 => fifo_sc_hs_inst_mem_271);
\fifo_sc_hs_inst/mem_s246\: LUT4
generic map (
  INIT => X"7000"
)
port map (
  F => fifo_sc_hs_inst_mem_259,
  I0 => \fifo_sc_hs_inst/Wnum\(4),
  I1 => fifo_sc_hs_inst_n7_5,
  I2 => fifo_sc_hs_inst_mem_275,
  I3 => fifo_sc_hs_inst_mem_272);
\fifo_sc_hs_inst/mem_s247\: LUT4
generic map (
  INIT => X"0700"
)
port map (
  F => fifo_sc_hs_inst_mem_261,
  I0 => \fifo_sc_hs_inst/Wnum\(4),
  I1 => fifo_sc_hs_inst_n7_5,
  I2 => \fifo_sc_hs_inst/wbin\(0),
  I3 => fifo_sc_hs_inst_mem_276);
\fifo_sc_hs_inst/mem_s248\: LUT4
generic map (
  INIT => X"7000"
)
port map (
  F => fifo_sc_hs_inst_mem_263,
  I0 => \fifo_sc_hs_inst/Wnum\(4),
  I1 => fifo_sc_hs_inst_n7_5,
  I2 => fifo_sc_hs_inst_mem_276,
  I3 => \fifo_sc_hs_inst/wbin\(0));
\fifo_sc_hs_inst/mem_s249\: LUT4
generic map (
  INIT => X"0700"
)
port map (
  F => fifo_sc_hs_inst_mem_265,
  I0 => \fifo_sc_hs_inst/Wnum\(4),
  I1 => fifo_sc_hs_inst_n7_5,
  I2 => \fifo_sc_hs_inst/wbin\(0),
  I3 => fifo_sc_hs_inst_mem_277);
\fifo_sc_hs_inst/mem_s250\: LUT4
generic map (
  INIT => X"7000"
)
port map (
  F => fifo_sc_hs_inst_mem_267,
  I0 => \fifo_sc_hs_inst/Wnum\(4),
  I1 => fifo_sc_hs_inst_n7_5,
  I2 => fifo_sc_hs_inst_mem_277,
  I3 => \fifo_sc_hs_inst/wbin\(0));
\fifo_sc_hs_inst/n7_s1\: LUT4
generic map (
  INIT => X"0001"
)
port map (
  F => fifo_sc_hs_inst_n7_5,
  I0 => \fifo_sc_hs_inst/Wnum\(0),
  I1 => \fifo_sc_hs_inst/Wnum\(1),
  I2 => \fifo_sc_hs_inst/Wnum\(2),
  I3 => \fifo_sc_hs_inst/Wnum\(3));
\fifo_sc_hs_inst/mem_s251\: LUT3
generic map (
  INIT => X"10"
)
port map (
  F => fifo_sc_hs_inst_mem_268,
  I0 => \fifo_sc_hs_inst/wbin\(1),
  I1 => \fifo_sc_hs_inst/wbin\(0),
  I2 => WrEn);
\fifo_sc_hs_inst/mem_s252\: LUT2
generic map (
  INIT => X"1"
)
port map (
  F => fifo_sc_hs_inst_mem_269,
  I0 => \fifo_sc_hs_inst/wbin\(2),
  I1 => \fifo_sc_hs_inst/wbin\(3));
\fifo_sc_hs_inst/mem_s253\: LUT3
generic map (
  INIT => X"40"
)
port map (
  F => fifo_sc_hs_inst_mem_270,
  I0 => \fifo_sc_hs_inst/wbin\(1),
  I1 => WrEn,
  I2 => \fifo_sc_hs_inst/wbin\(0));
\fifo_sc_hs_inst/mem_s254\: LUT3
generic map (
  INIT => X"40"
)
port map (
  F => fifo_sc_hs_inst_mem_271,
  I0 => \fifo_sc_hs_inst/wbin\(0),
  I1 => \fifo_sc_hs_inst/wbin\(1),
  I2 => WrEn);
\fifo_sc_hs_inst/mem_s255\: LUT3
generic map (
  INIT => X"80"
)
port map (
  F => fifo_sc_hs_inst_mem_272,
  I0 => WrEn,
  I1 => \fifo_sc_hs_inst/wbin\(1),
  I2 => \fifo_sc_hs_inst/wbin\(0));
\fifo_sc_hs_inst/mem_s256\: LUT4
generic map (
  INIT => X"1000"
)
port map (
  F => fifo_sc_hs_inst_mem_273,
  I0 => \fifo_sc_hs_inst/wbin\(1),
  I1 => \fifo_sc_hs_inst/wbin\(3),
  I2 => \fifo_sc_hs_inst/wbin\(2),
  I3 => WrEn);
\fifo_sc_hs_inst/mem_s257\: LUT2
generic map (
  INIT => X"4"
)
port map (
  F => fifo_sc_hs_inst_mem_274,
  I0 => \fifo_sc_hs_inst/wbin\(3),
  I1 => \fifo_sc_hs_inst/wbin\(2));
\fifo_sc_hs_inst/mem_s258\: LUT2
generic map (
  INIT => X"4"
)
port map (
  F => fifo_sc_hs_inst_mem_275,
  I0 => \fifo_sc_hs_inst/wbin\(2),
  I1 => \fifo_sc_hs_inst/wbin\(3));
\fifo_sc_hs_inst/mem_s259\: LUT4
generic map (
  INIT => X"4000"
)
port map (
  F => fifo_sc_hs_inst_mem_276,
  I0 => \fifo_sc_hs_inst/wbin\(1),
  I1 => WrEn,
  I2 => \fifo_sc_hs_inst/wbin\(2),
  I3 => \fifo_sc_hs_inst/wbin\(3));
\fifo_sc_hs_inst/mem_s260\: LUT4
generic map (
  INIT => X"8000"
)
port map (
  F => fifo_sc_hs_inst_mem_277,
  I0 => WrEn,
  I1 => \fifo_sc_hs_inst/wbin\(1),
  I2 => \fifo_sc_hs_inst/wbin\(2),
  I3 => \fifo_sc_hs_inst/wbin\(3));
\fifo_sc_hs_inst/n82_1_s1\: LUT4
generic map (
  INIT => X"CAFF"
)
port map (
  F => fifo_sc_hs_inst_n82_1,
  I0 => RdEn,
  I1 => \fifo_sc_hs_inst/Wnum\(4),
  I2 => fifo_sc_hs_inst_n7_5,
  I3 => WrEn);
GND_s0: GND
port map (
  G => GND_0);
VCC_s0: VCC
port map (
  V => VCC_0);
GSR_0: GSR
port map (
  GSRI => VCC_0);
end beh;
