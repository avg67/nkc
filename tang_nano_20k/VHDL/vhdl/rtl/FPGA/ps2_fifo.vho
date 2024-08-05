--
--Written by GowinSynthesis
--Tool Version "V1.9.9.02"
--Fri May 31 15:50:54 2024

--Source file index table:
--file0 "\C:/working/_Tang_nano/_cores/ps2_fifo/fifo_sc_hs/temp/FIFO_SC/fifo_sc_hs_define.v"
--file1 "\C:/working/_Tang_nano/_cores/ps2_fifo/fifo_sc_hs/temp/FIFO_SC/fifo_sc_hs_parameter.v"
--file2 "\C:/Gowin/Gowin_V1.9.9.02_x64/IDE/ipcore/FIFO_SC_HS/data/fifo_sc_hs.v"
--file3 "\C:/Gowin/Gowin_V1.9.9.02_x64/IDE/ipcore/FIFO_SC_HS/data/fifo_sc_hs_top.v"
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
  signal fifo_sc_hs_inst_mem_mem_0_0_0_DO31 : std_logic ;
  signal fifo_sc_hs_inst_mem_mem_0_0_0_DO30 : std_logic ;
  signal fifo_sc_hs_inst_mem_mem_0_0_0_DO29 : std_logic ;
  signal fifo_sc_hs_inst_mem_mem_0_0_0_DO28 : std_logic ;
  signal fifo_sc_hs_inst_mem_mem_0_0_0_DO27 : std_logic ;
  signal fifo_sc_hs_inst_mem_mem_0_0_0_DO26 : std_logic ;
  signal fifo_sc_hs_inst_mem_mem_0_0_0_DO25 : std_logic ;
  signal fifo_sc_hs_inst_mem_mem_0_0_0_DO24 : std_logic ;
  signal fifo_sc_hs_inst_mem_mem_0_0_0_DO23 : std_logic ;
  signal fifo_sc_hs_inst_mem_mem_0_0_0_DO22 : std_logic ;
  signal fifo_sc_hs_inst_mem_mem_0_0_0_DO21 : std_logic ;
  signal fifo_sc_hs_inst_mem_mem_0_0_0_DO20 : std_logic ;
  signal fifo_sc_hs_inst_mem_mem_0_0_0_DO19 : std_logic ;
  signal fifo_sc_hs_inst_mem_mem_0_0_0_DO18 : std_logic ;
  signal fifo_sc_hs_inst_mem_mem_0_0_0_DO17 : std_logic ;
  signal fifo_sc_hs_inst_mem_mem_0_0_0_DO16 : std_logic ;
  signal fifo_sc_hs_inst_mem_mem_0_0_0_DO15 : std_logic ;
  signal fifo_sc_hs_inst_mem_mem_0_0_0_DO14 : std_logic ;
  signal fifo_sc_hs_inst_mem_mem_0_0_0_DO13 : std_logic ;
  signal fifo_sc_hs_inst_mem_mem_0_0_0_DO12 : std_logic ;
  signal fifo_sc_hs_inst_mem_mem_0_0_0_DO11 : std_logic ;
  signal fifo_sc_hs_inst_mem_mem_0_0_0_DO10 : std_logic ;
  signal fifo_sc_hs_inst_mem_mem_0_0_0_DO9 : std_logic ;
  signal fifo_sc_hs_inst_mem_mem_0_0_0_DO8 : std_logic ;
  signal fifo_sc_hs_inst_mem_mem_0_0_0_DO7 : std_logic ;
  signal fifo_sc_hs_inst_n134 : std_logic ;
  signal fifo_sc_hs_inst_n134_1 : std_logic ;
  signal fifo_sc_hs_inst_n133 : std_logic ;
  signal fifo_sc_hs_inst_n133_1 : std_logic ;
  signal fifo_sc_hs_inst_n132 : std_logic ;
  signal fifo_sc_hs_inst_n132_1 : std_logic ;
  signal fifo_sc_hs_inst_n131 : std_logic ;
  signal fifo_sc_hs_inst_n131_1 : std_logic ;
  signal fifo_sc_hs_inst_n130 : std_logic ;
  signal fifo_sc_hs_inst_n130_1 : std_logic ;
  signal fifo_sc_hs_inst_wbin_next_0 : std_logic ;
  signal fifo_sc_hs_inst_wbin_next_1 : std_logic ;
  signal fifo_sc_hs_inst_wbin_next_2 : std_logic ;
  signal fifo_sc_hs_inst_wbin_next_3 : std_logic ;
  signal fifo_sc_hs_inst_wbin_next_4 : std_logic ;
  signal fifo_sc_hs_inst_n147 : std_logic ;
  signal fifo_sc_hs_inst_n147_3 : std_logic ;
  signal fifo_sc_hs_inst_n148 : std_logic ;
  signal fifo_sc_hs_inst_n148_3 : std_logic ;
  signal fifo_sc_hs_inst_n149 : std_logic ;
  signal fifo_sc_hs_inst_n149_3 : std_logic ;
  signal fifo_sc_hs_inst_n150 : std_logic ;
  signal fifo_sc_hs_inst_n150_3 : std_logic ;
  signal fifo_sc_hs_inst_n151 : std_logic ;
  signal fifo_sc_hs_inst_n151_3 : std_logic ;
  signal fifo_sc_hs_inst_n7 : std_logic ;
  signal fifo_sc_hs_inst_n13 : std_logic ;
  signal fifo_sc_hs_inst_n84 : std_logic ;
  signal fifo_sc_hs_inst_Wnum_4 : std_logic ;
  signal fifo_sc_hs_inst_n7_6 : std_logic ;
  signal fifo_sc_hs_inst_n84_4 : std_logic ;
  signal fifo_sc_hs_inst_rbin_next_2 : std_logic ;
  signal fifo_sc_hs_inst_n84_1 : std_logic ;
  signal fifo_sc_hs_inst_rempty_val : std_logic ;
  signal GND_0 : std_logic ;
  signal VCC_0 : std_logic ;
  signal \fifo_sc_hs_inst/rbin\ : std_logic_vector(4 downto 0);
  signal \fifo_sc_hs_inst/wbin\ : std_logic_vector(4 downto 0);
  signal \fifo_sc_hs_inst/Wnum\ : std_logic_vector(4 downto 0);
  signal \fifo_sc_hs_inst/wbin_next\ : std_logic_vector(4 downto 0);
  signal \fifo_sc_hs_inst/rbin_next\ : std_logic_vector(4 downto 0);
  signal NN : std_logic;
begin
\fifo_sc_hs_inst/rbin_4_s0\: DFFC
port map (
  Q => \fifo_sc_hs_inst/rbin\(4),
  D => \fifo_sc_hs_inst/rbin_next\(4),
  CLK => Clk,
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
\fifo_sc_hs_inst/wbin_4_s0\: DFFC
port map (
  Q => \fifo_sc_hs_inst/wbin\(4),
  D => \fifo_sc_hs_inst/wbin_next\(4),
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
\fifo_sc_hs_inst/Empty_s0\: DFFP
port map (
  Q => NN,
  D => fifo_sc_hs_inst_rempty_val,
  CLK => Clk,
  PRESET => Reset);
\fifo_sc_hs_inst/Wnum_4_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \fifo_sc_hs_inst/Wnum\(4),
  D => fifo_sc_hs_inst_n130,
  CLK => Clk,
  CE => fifo_sc_hs_inst_Wnum_4,
  CLEAR => Reset);
\fifo_sc_hs_inst/Wnum_3_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \fifo_sc_hs_inst/Wnum\(3),
  D => fifo_sc_hs_inst_n131,
  CLK => Clk,
  CE => fifo_sc_hs_inst_Wnum_4,
  CLEAR => Reset);
\fifo_sc_hs_inst/Wnum_2_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \fifo_sc_hs_inst/Wnum\(2),
  D => fifo_sc_hs_inst_n132,
  CLK => Clk,
  CE => fifo_sc_hs_inst_Wnum_4,
  CLEAR => Reset);
\fifo_sc_hs_inst/Wnum_1_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \fifo_sc_hs_inst/Wnum\(1),
  D => fifo_sc_hs_inst_n133,
  CLK => Clk,
  CE => fifo_sc_hs_inst_Wnum_4,
  CLEAR => Reset);
\fifo_sc_hs_inst/Wnum_0_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \fifo_sc_hs_inst/Wnum\(0),
  D => fifo_sc_hs_inst_n134,
  CLK => Clk,
  CE => fifo_sc_hs_inst_Wnum_4,
  CLEAR => Reset);
\fifo_sc_hs_inst/mem_mem_0_0_s\: SDPB
generic map (
  BIT_WIDTH_0 => 8,
  BIT_WIDTH_1 => 8,
  READ_MODE => '0',
  RESET_MODE => "ASYNC",
  BLK_SEL_0 => "000",
  BLK_SEL_1 => "000"
)
port map (
  DO(31) => fifo_sc_hs_inst_mem_mem_0_0_0_DO31,
  DO(30) => fifo_sc_hs_inst_mem_mem_0_0_0_DO30,
  DO(29) => fifo_sc_hs_inst_mem_mem_0_0_0_DO29,
  DO(28) => fifo_sc_hs_inst_mem_mem_0_0_0_DO28,
  DO(27) => fifo_sc_hs_inst_mem_mem_0_0_0_DO27,
  DO(26) => fifo_sc_hs_inst_mem_mem_0_0_0_DO26,
  DO(25) => fifo_sc_hs_inst_mem_mem_0_0_0_DO25,
  DO(24) => fifo_sc_hs_inst_mem_mem_0_0_0_DO24,
  DO(23) => fifo_sc_hs_inst_mem_mem_0_0_0_DO23,
  DO(22) => fifo_sc_hs_inst_mem_mem_0_0_0_DO22,
  DO(21) => fifo_sc_hs_inst_mem_mem_0_0_0_DO21,
  DO(20) => fifo_sc_hs_inst_mem_mem_0_0_0_DO20,
  DO(19) => fifo_sc_hs_inst_mem_mem_0_0_0_DO19,
  DO(18) => fifo_sc_hs_inst_mem_mem_0_0_0_DO18,
  DO(17) => fifo_sc_hs_inst_mem_mem_0_0_0_DO17,
  DO(16) => fifo_sc_hs_inst_mem_mem_0_0_0_DO16,
  DO(15) => fifo_sc_hs_inst_mem_mem_0_0_0_DO15,
  DO(14) => fifo_sc_hs_inst_mem_mem_0_0_0_DO14,
  DO(13) => fifo_sc_hs_inst_mem_mem_0_0_0_DO13,
  DO(12) => fifo_sc_hs_inst_mem_mem_0_0_0_DO12,
  DO(11) => fifo_sc_hs_inst_mem_mem_0_0_0_DO11,
  DO(10) => fifo_sc_hs_inst_mem_mem_0_0_0_DO10,
  DO(9) => fifo_sc_hs_inst_mem_mem_0_0_0_DO9,
  DO(8) => fifo_sc_hs_inst_mem_mem_0_0_0_DO8,
  DO(7) => fifo_sc_hs_inst_mem_mem_0_0_0_DO7,
  DO(6 downto 0) => Q(6 downto 0),
  DI(31) => GND_0,
  DI(30) => GND_0,
  DI(29) => GND_0,
  DI(28) => GND_0,
  DI(27) => GND_0,
  DI(26) => GND_0,
  DI(25) => GND_0,
  DI(24) => GND_0,
  DI(23) => GND_0,
  DI(22) => GND_0,
  DI(21) => GND_0,
  DI(20) => GND_0,
  DI(19) => GND_0,
  DI(18) => GND_0,
  DI(17) => GND_0,
  DI(16) => GND_0,
  DI(15) => GND_0,
  DI(14) => GND_0,
  DI(13) => GND_0,
  DI(12) => GND_0,
  DI(11) => GND_0,
  DI(10) => GND_0,
  DI(9) => GND_0,
  DI(8) => GND_0,
  DI(7) => GND_0,
  DI(6 downto 0) => Data(6 downto 0),
  BLKSELA(2) => GND_0,
  BLKSELA(1) => GND_0,
  BLKSELA(0) => GND_0,
  BLKSELB(2) => GND_0,
  BLKSELB(1) => GND_0,
  BLKSELB(0) => GND_0,
  ADA(13) => GND_0,
  ADA(12) => GND_0,
  ADA(11) => GND_0,
  ADA(10) => GND_0,
  ADA(9) => GND_0,
  ADA(8) => GND_0,
  ADA(7) => GND_0,
  ADA(6 downto 3) => \fifo_sc_hs_inst/wbin\(3 downto 0),
  ADA(2) => GND_0,
  ADA(1) => GND_0,
  ADA(0) => GND_0,
  ADB(13) => GND_0,
  ADB(12) => GND_0,
  ADB(11) => GND_0,
  ADB(10) => GND_0,
  ADB(9) => GND_0,
  ADB(8) => GND_0,
  ADB(7) => GND_0,
  ADB(6 downto 3) => \fifo_sc_hs_inst/rbin_next\(3 downto 0),
  ADB(2) => GND_0,
  ADB(1) => GND_0,
  ADB(0) => GND_0,
  CLKA => Clk,
  CLKB => Clk,
  CEA => fifo_sc_hs_inst_n7,
  CEB => fifo_sc_hs_inst_n13,
  OCE => GND_0,
  RESETA => GND_0,
  RESETB => Reset);
\fifo_sc_hs_inst/n134_1_s\: ALU
generic map (
  ALU_MODE => 2
)
port map (
  SUM => fifo_sc_hs_inst_n134,
  COUT => fifo_sc_hs_inst_n134_1,
  I0 => \fifo_sc_hs_inst/Wnum\(0),
  I1 => VCC_0,
  I3 => fifo_sc_hs_inst_n84,
  CIN => fifo_sc_hs_inst_n84_1);
\fifo_sc_hs_inst/n133_1_s\: ALU
generic map (
  ALU_MODE => 2
)
port map (
  SUM => fifo_sc_hs_inst_n133,
  COUT => fifo_sc_hs_inst_n133_1,
  I0 => \fifo_sc_hs_inst/Wnum\(1),
  I1 => GND_0,
  I3 => fifo_sc_hs_inst_n84,
  CIN => fifo_sc_hs_inst_n134_1);
\fifo_sc_hs_inst/n132_1_s\: ALU
generic map (
  ALU_MODE => 2
)
port map (
  SUM => fifo_sc_hs_inst_n132,
  COUT => fifo_sc_hs_inst_n132_1,
  I0 => \fifo_sc_hs_inst/Wnum\(2),
  I1 => GND_0,
  I3 => fifo_sc_hs_inst_n84,
  CIN => fifo_sc_hs_inst_n133_1);
\fifo_sc_hs_inst/n131_1_s\: ALU
generic map (
  ALU_MODE => 2
)
port map (
  SUM => fifo_sc_hs_inst_n131,
  COUT => fifo_sc_hs_inst_n131_1,
  I0 => \fifo_sc_hs_inst/Wnum\(3),
  I1 => GND_0,
  I3 => fifo_sc_hs_inst_n84,
  CIN => fifo_sc_hs_inst_n132_1);
\fifo_sc_hs_inst/n130_1_s\: ALU
generic map (
  ALU_MODE => 2
)
port map (
  SUM => fifo_sc_hs_inst_n130,
  COUT => fifo_sc_hs_inst_n130_1,
  I0 => \fifo_sc_hs_inst/Wnum\(4),
  I1 => GND_0,
  I3 => fifo_sc_hs_inst_n84,
  CIN => fifo_sc_hs_inst_n131_1);
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
\fifo_sc_hs_inst/wbin_next_4_s\: ALU
generic map (
  ALU_MODE => 0
)
port map (
  SUM => \fifo_sc_hs_inst/wbin_next\(4),
  COUT => fifo_sc_hs_inst_wbin_next_4,
  I0 => \fifo_sc_hs_inst/wbin\(4),
  I1 => GND_0,
  I3 => GND_0,
  CIN => fifo_sc_hs_inst_wbin_next_3);
\fifo_sc_hs_inst/n147_s0\: ALU
generic map (
  ALU_MODE => 3
)
port map (
  SUM => fifo_sc_hs_inst_n147,
  COUT => fifo_sc_hs_inst_n147_3,
  I0 => \fifo_sc_hs_inst/rbin_next\(0),
  I1 => \fifo_sc_hs_inst/wbin\(0),
  I3 => GND_0,
  CIN => GND_0);
\fifo_sc_hs_inst/n148_s0\: ALU
generic map (
  ALU_MODE => 3
)
port map (
  SUM => fifo_sc_hs_inst_n148,
  COUT => fifo_sc_hs_inst_n148_3,
  I0 => \fifo_sc_hs_inst/rbin_next\(1),
  I1 => \fifo_sc_hs_inst/wbin\(1),
  I3 => GND_0,
  CIN => fifo_sc_hs_inst_n147_3);
\fifo_sc_hs_inst/n149_s0\: ALU
generic map (
  ALU_MODE => 3
)
port map (
  SUM => fifo_sc_hs_inst_n149,
  COUT => fifo_sc_hs_inst_n149_3,
  I0 => \fifo_sc_hs_inst/rbin_next\(2),
  I1 => \fifo_sc_hs_inst/wbin\(2),
  I3 => GND_0,
  CIN => fifo_sc_hs_inst_n148_3);
\fifo_sc_hs_inst/n150_s0\: ALU
generic map (
  ALU_MODE => 3
)
port map (
  SUM => fifo_sc_hs_inst_n150,
  COUT => fifo_sc_hs_inst_n150_3,
  I0 => \fifo_sc_hs_inst/rbin_next\(3),
  I1 => \fifo_sc_hs_inst/wbin\(3),
  I3 => GND_0,
  CIN => fifo_sc_hs_inst_n149_3);
\fifo_sc_hs_inst/n151_s0\: ALU
generic map (
  ALU_MODE => 3
)
port map (
  SUM => fifo_sc_hs_inst_n151,
  COUT => fifo_sc_hs_inst_n151_3,
  I0 => \fifo_sc_hs_inst/rbin_next\(4),
  I1 => \fifo_sc_hs_inst/wbin\(4),
  I3 => GND_0,
  CIN => fifo_sc_hs_inst_n150_3);
\fifo_sc_hs_inst/n7_s1\: LUT3
generic map (
  INIT => X"B0"
)
port map (
  F => fifo_sc_hs_inst_n7,
  I0 => \fifo_sc_hs_inst/Wnum\(0),
  I1 => fifo_sc_hs_inst_n7_6,
  I2 => WrEn);
\fifo_sc_hs_inst/n13_s1\: LUT3
generic map (
  INIT => X"E0"
)
port map (
  F => fifo_sc_hs_inst_n13,
  I0 => RdEn,
  I1 => NN,
  I2 => fifo_sc_hs_inst_n151_3);
\fifo_sc_hs_inst/n84_s0\: LUT4
generic map (
  INIT => X"0B00"
)
port map (
  F => fifo_sc_hs_inst_n84,
  I0 => \fifo_sc_hs_inst/Wnum\(0),
  I1 => fifo_sc_hs_inst_n7_6,
  I2 => fifo_sc_hs_inst_n84_4,
  I3 => WrEn);
\fifo_sc_hs_inst/Full_d_s\: LUT2
generic map (
  INIT => X"4"
)
port map (
  F => Full,
  I0 => \fifo_sc_hs_inst/Wnum\(0),
  I1 => fifo_sc_hs_inst_n7_6);
\fifo_sc_hs_inst/Wnum_4_s3\: LUT4
generic map (
  INIT => X"2FD0"
)
port map (
  F => fifo_sc_hs_inst_Wnum_4,
  I0 => fifo_sc_hs_inst_n7_6,
  I1 => \fifo_sc_hs_inst/Wnum\(0),
  I2 => WrEn,
  I3 => fifo_sc_hs_inst_n84_4);
\fifo_sc_hs_inst/rbin_next_2_s5\: LUT2
generic map (
  INIT => X"6"
)
port map (
  F => \fifo_sc_hs_inst/rbin_next\(2),
  I0 => fifo_sc_hs_inst_rbin_next_2,
  I1 => \fifo_sc_hs_inst/rbin\(2));
\fifo_sc_hs_inst/rbin_next_3_s5\: LUT3
generic map (
  INIT => X"78"
)
port map (
  F => \fifo_sc_hs_inst/rbin_next\(3),
  I0 => fifo_sc_hs_inst_rbin_next_2,
  I1 => \fifo_sc_hs_inst/rbin\(2),
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/rbin_next_4_s2\: LUT4
generic map (
  INIT => X"7F80"
)
port map (
  F => \fifo_sc_hs_inst/rbin_next\(4),
  I0 => fifo_sc_hs_inst_rbin_next_2,
  I1 => \fifo_sc_hs_inst/rbin\(2),
  I2 => \fifo_sc_hs_inst/rbin\(3),
  I3 => \fifo_sc_hs_inst/rbin\(4));
\fifo_sc_hs_inst/n7_s2\: LUT4
generic map (
  INIT => X"0100"
)
port map (
  F => fifo_sc_hs_inst_n7_6,
  I0 => \fifo_sc_hs_inst/Wnum\(1),
  I1 => \fifo_sc_hs_inst/Wnum\(2),
  I2 => \fifo_sc_hs_inst/Wnum\(3),
  I3 => \fifo_sc_hs_inst/Wnum\(4));
\fifo_sc_hs_inst/n84_s1\: LUT2
generic map (
  INIT => X"4"
)
port map (
  F => fifo_sc_hs_inst_n84_4,
  I0 => NN,
  I1 => RdEn);
\fifo_sc_hs_inst/rbin_next_2_s6\: LUT4
generic map (
  INIT => X"4000"
)
port map (
  F => fifo_sc_hs_inst_rbin_next_2,
  I0 => NN,
  I1 => RdEn,
  I2 => \fifo_sc_hs_inst/rbin\(0),
  I3 => \fifo_sc_hs_inst/rbin\(1));
\fifo_sc_hs_inst/rbin_next_1_s6\: LUT4
generic map (
  INIT => X"BF40"
)
port map (
  F => \fifo_sc_hs_inst/rbin_next\(1),
  I0 => NN,
  I1 => RdEn,
  I2 => \fifo_sc_hs_inst/rbin\(0),
  I3 => \fifo_sc_hs_inst/rbin\(1));
\fifo_sc_hs_inst/rbin_next_0_s6\: LUT3
generic map (
  INIT => X"B4"
)
port map (
  F => \fifo_sc_hs_inst/rbin_next\(0),
  I0 => NN,
  I1 => RdEn,
  I2 => \fifo_sc_hs_inst/rbin\(0));
\fifo_sc_hs_inst/n84_1_s1\: LUT4
generic map (
  INIT => X"F4FF"
)
port map (
  F => fifo_sc_hs_inst_n84_1,
  I0 => \fifo_sc_hs_inst/Wnum\(0),
  I1 => fifo_sc_hs_inst_n7_6,
  I2 => fifo_sc_hs_inst_n84_4,
  I3 => WrEn);
\fifo_sc_hs_inst/rempty_val_s1\: INV
port map (
  O => fifo_sc_hs_inst_rempty_val,
  I => fifo_sc_hs_inst_n151_3);
GND_s0: GND
port map (
  G => GND_0);
VCC_s0: VCC
port map (
  V => VCC_0);
GSR_0: GSR
port map (
  GSRI => VCC_0);
  Empty <= NN;
end beh;
