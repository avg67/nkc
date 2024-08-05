--
--Written by GowinSynthesis
--Tool Version "V1.9.9.02"
--Fri Jun 14 16:07:29 2024

--Source file index table:
--file0 "\C:/working/_Tang_nano/gdp_fpga/VHDL/GDP936X/vhdl/rtl/FPGA/fifo_sc_hs/temp/FIFO_SC/fifo_sc_hs_define.v"
--file1 "\C:/working/_Tang_nano/gdp_fpga/VHDL/GDP936X/vhdl/rtl/FPGA/fifo_sc_hs/temp/FIFO_SC/fifo_sc_hs_parameter.v"
--file2 "\C:/Gowin/Gowin_V1.9.9.02_x64/IDE/ipcore/FIFO_SC_HS/data/fifo_sc_hs.v"
--file3 "\C:/Gowin/Gowin_V1.9.9.02_x64/IDE/ipcore/FIFO_SC_HS/data/fifo_sc_hs_top.v"
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library gw2a;
use gw2a.components.all;

entity video_fifo is
port(
  Data :  in std_logic_vector(31 downto 0);
  Clk :  in std_logic;
  WrEn :  in std_logic;
  RdEn :  in std_logic;
  Reset :  in std_logic;
  AlmostEmptyTh :  in std_logic_vector(3 downto 0);
  Almost_Empty :  out std_logic;
  Q :  out std_logic_vector(31 downto 0);
  Empty :  out std_logic;
  Full :  out std_logic);
end video_fifo;
architecture beh of video_fifo is
  signal fifo_sc_hs_inst_arempty_val : std_logic ;
  signal fifo_sc_hs_inst_arempty_val_13 : std_logic ;
  signal fifo_sc_hs_inst_arempty_val_14 : std_logic ;
  signal fifo_sc_hs_inst_arempty_val_15 : std_logic ;
  signal fifo_sc_hs_inst_arempty_val_16 : std_logic ;
  signal fifo_sc_hs_inst_arempty_val_17 : std_logic ;
  signal fifo_sc_hs_inst_n234 : std_logic ;
  signal fifo_sc_hs_inst_n234_1 : std_logic ;
  signal fifo_sc_hs_inst_n233 : std_logic ;
  signal fifo_sc_hs_inst_n233_1 : std_logic ;
  signal fifo_sc_hs_inst_n232 : std_logic ;
  signal fifo_sc_hs_inst_n232_1 : std_logic ;
  signal fifo_sc_hs_inst_n231 : std_logic ;
  signal fifo_sc_hs_inst_n231_1 : std_logic ;
  signal fifo_sc_hs_inst_n230 : std_logic ;
  signal fifo_sc_hs_inst_n230_1 : std_logic ;
  signal fifo_sc_hs_inst_wbin_next_0 : std_logic ;
  signal fifo_sc_hs_inst_wbin_next_1 : std_logic ;
  signal fifo_sc_hs_inst_wbin_next_2 : std_logic ;
  signal fifo_sc_hs_inst_wbin_next_3 : std_logic ;
  signal fifo_sc_hs_inst_wbin_next_4 : std_logic ;
  signal fifo_sc_hs_inst_n247 : std_logic ;
  signal fifo_sc_hs_inst_n247_3 : std_logic ;
  signal fifo_sc_hs_inst_n248 : std_logic ;
  signal fifo_sc_hs_inst_n248_3 : std_logic ;
  signal fifo_sc_hs_inst_n249 : std_logic ;
  signal fifo_sc_hs_inst_n249_3 : std_logic ;
  signal fifo_sc_hs_inst_n250 : std_logic ;
  signal fifo_sc_hs_inst_n250_3 : std_logic ;
  signal fifo_sc_hs_inst_n251 : std_logic ;
  signal fifo_sc_hs_inst_n251_3 : std_logic ;
  signal fifo_sc_hs_inst_n7 : std_logic ;
  signal fifo_sc_hs_inst_n13 : std_logic ;
  signal fifo_sc_hs_inst_n184 : std_logic ;
  signal fifo_sc_hs_inst_Wnum_4 : std_logic ;
  signal fifo_sc_hs_inst_n7_6 : std_logic ;
  signal fifo_sc_hs_inst_n184_4 : std_logic ;
  signal fifo_sc_hs_inst_rbin_next_2 : std_logic ;
  signal fifo_sc_hs_inst_n184_1 : std_logic ;
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
  D => fifo_sc_hs_inst_n230,
  CLK => Clk,
  CE => fifo_sc_hs_inst_Wnum_4,
  CLEAR => Reset);
\fifo_sc_hs_inst/Wnum_3_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \fifo_sc_hs_inst/Wnum\(3),
  D => fifo_sc_hs_inst_n231,
  CLK => Clk,
  CE => fifo_sc_hs_inst_Wnum_4,
  CLEAR => Reset);
\fifo_sc_hs_inst/Wnum_2_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \fifo_sc_hs_inst/Wnum\(2),
  D => fifo_sc_hs_inst_n232,
  CLK => Clk,
  CE => fifo_sc_hs_inst_Wnum_4,
  CLEAR => Reset);
\fifo_sc_hs_inst/Wnum_1_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \fifo_sc_hs_inst/Wnum\(1),
  D => fifo_sc_hs_inst_n233,
  CLK => Clk,
  CE => fifo_sc_hs_inst_Wnum_4,
  CLEAR => Reset);
\fifo_sc_hs_inst/Wnum_0_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \fifo_sc_hs_inst/Wnum\(0),
  D => fifo_sc_hs_inst_n234,
  CLK => Clk,
  CE => fifo_sc_hs_inst_Wnum_4,
  CLEAR => Reset);
\fifo_sc_hs_inst/arempty_val_s10\: ALU
generic map (
  ALU_MODE => 1
)
port map (
  SUM => fifo_sc_hs_inst_arempty_val,
  COUT => fifo_sc_hs_inst_arempty_val_13,
  I0 => VCC_0,
  I1 => \fifo_sc_hs_inst/Wnum\(0),
  I3 => GND_0,
  CIN => AlmostEmptyTh(0));
\fifo_sc_hs_inst/arempty_val_s11\: ALU
generic map (
  ALU_MODE => 1
)
port map (
  SUM => fifo_sc_hs_inst_arempty_val_14,
  COUT => fifo_sc_hs_inst_arempty_val_15,
  I0 => AlmostEmptyTh(1),
  I1 => \fifo_sc_hs_inst/Wnum\(1),
  I3 => GND_0,
  CIN => fifo_sc_hs_inst_arempty_val_13);
\fifo_sc_hs_inst/arempty_val_s12\: ALU
generic map (
  ALU_MODE => 1
)
port map (
  SUM => fifo_sc_hs_inst_arempty_val_16,
  COUT => fifo_sc_hs_inst_arempty_val_17,
  I0 => AlmostEmptyTh(2),
  I1 => \fifo_sc_hs_inst/Wnum\(2),
  I3 => GND_0,
  CIN => fifo_sc_hs_inst_arempty_val_15);
\fifo_sc_hs_inst/mem_mem_0_0_s\: SDPB
generic map (
  BIT_WIDTH_0 => 32,
  BIT_WIDTH_1 => 32,
  READ_MODE => '0',
  RESET_MODE => "ASYNC",
  BLK_SEL_0 => "000",
  BLK_SEL_1 => "000"
)
port map (
  DO(31 downto 0) => Q(31 downto 0),
  DI(31 downto 0) => Data(31 downto 0),
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
  ADA(8 downto 5) => \fifo_sc_hs_inst/wbin\(3 downto 0),
  ADA(4) => GND_0,
  ADA(3) => VCC_0,
  ADA(2) => VCC_0,
  ADA(1) => VCC_0,
  ADA(0) => VCC_0,
  ADB(13) => GND_0,
  ADB(12) => GND_0,
  ADB(11) => GND_0,
  ADB(10) => GND_0,
  ADB(9) => GND_0,
  ADB(8 downto 5) => \fifo_sc_hs_inst/rbin_next\(3 downto 0),
  ADB(4) => GND_0,
  ADB(3) => GND_0,
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
\fifo_sc_hs_inst/n234_1_s\: ALU
generic map (
  ALU_MODE => 2
)
port map (
  SUM => fifo_sc_hs_inst_n234,
  COUT => fifo_sc_hs_inst_n234_1,
  I0 => \fifo_sc_hs_inst/Wnum\(0),
  I1 => VCC_0,
  I3 => fifo_sc_hs_inst_n184,
  CIN => fifo_sc_hs_inst_n184_1);
\fifo_sc_hs_inst/n233_1_s\: ALU
generic map (
  ALU_MODE => 2
)
port map (
  SUM => fifo_sc_hs_inst_n233,
  COUT => fifo_sc_hs_inst_n233_1,
  I0 => \fifo_sc_hs_inst/Wnum\(1),
  I1 => GND_0,
  I3 => fifo_sc_hs_inst_n184,
  CIN => fifo_sc_hs_inst_n234_1);
\fifo_sc_hs_inst/n232_1_s\: ALU
generic map (
  ALU_MODE => 2
)
port map (
  SUM => fifo_sc_hs_inst_n232,
  COUT => fifo_sc_hs_inst_n232_1,
  I0 => \fifo_sc_hs_inst/Wnum\(2),
  I1 => GND_0,
  I3 => fifo_sc_hs_inst_n184,
  CIN => fifo_sc_hs_inst_n233_1);
\fifo_sc_hs_inst/n231_1_s\: ALU
generic map (
  ALU_MODE => 2
)
port map (
  SUM => fifo_sc_hs_inst_n231,
  COUT => fifo_sc_hs_inst_n231_1,
  I0 => \fifo_sc_hs_inst/Wnum\(3),
  I1 => GND_0,
  I3 => fifo_sc_hs_inst_n184,
  CIN => fifo_sc_hs_inst_n232_1);
\fifo_sc_hs_inst/n230_1_s\: ALU
generic map (
  ALU_MODE => 2
)
port map (
  SUM => fifo_sc_hs_inst_n230,
  COUT => fifo_sc_hs_inst_n230_1,
  I0 => \fifo_sc_hs_inst/Wnum\(4),
  I1 => GND_0,
  I3 => fifo_sc_hs_inst_n184,
  CIN => fifo_sc_hs_inst_n231_1);
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
\fifo_sc_hs_inst/n247_s0\: ALU
generic map (
  ALU_MODE => 3
)
port map (
  SUM => fifo_sc_hs_inst_n247,
  COUT => fifo_sc_hs_inst_n247_3,
  I0 => \fifo_sc_hs_inst/rbin_next\(0),
  I1 => \fifo_sc_hs_inst/wbin\(0),
  I3 => GND_0,
  CIN => GND_0);
\fifo_sc_hs_inst/n248_s0\: ALU
generic map (
  ALU_MODE => 3
)
port map (
  SUM => fifo_sc_hs_inst_n248,
  COUT => fifo_sc_hs_inst_n248_3,
  I0 => \fifo_sc_hs_inst/rbin_next\(1),
  I1 => \fifo_sc_hs_inst/wbin\(1),
  I3 => GND_0,
  CIN => fifo_sc_hs_inst_n247_3);
\fifo_sc_hs_inst/n249_s0\: ALU
generic map (
  ALU_MODE => 3
)
port map (
  SUM => fifo_sc_hs_inst_n249,
  COUT => fifo_sc_hs_inst_n249_3,
  I0 => \fifo_sc_hs_inst/rbin_next\(2),
  I1 => \fifo_sc_hs_inst/wbin\(2),
  I3 => GND_0,
  CIN => fifo_sc_hs_inst_n248_3);
\fifo_sc_hs_inst/n250_s0\: ALU
generic map (
  ALU_MODE => 3
)
port map (
  SUM => fifo_sc_hs_inst_n250,
  COUT => fifo_sc_hs_inst_n250_3,
  I0 => \fifo_sc_hs_inst/rbin_next\(3),
  I1 => \fifo_sc_hs_inst/wbin\(3),
  I3 => GND_0,
  CIN => fifo_sc_hs_inst_n249_3);
\fifo_sc_hs_inst/n251_s0\: ALU
generic map (
  ALU_MODE => 3
)
port map (
  SUM => fifo_sc_hs_inst_n251,
  COUT => fifo_sc_hs_inst_n251_3,
  I0 => \fifo_sc_hs_inst/rbin_next\(4),
  I1 => \fifo_sc_hs_inst/wbin\(4),
  I3 => GND_0,
  CIN => fifo_sc_hs_inst_n250_3);
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
  I2 => fifo_sc_hs_inst_n251_3);
\fifo_sc_hs_inst/n184_s0\: LUT4
generic map (
  INIT => X"0B00"
)
port map (
  F => fifo_sc_hs_inst_n184,
  I0 => \fifo_sc_hs_inst/Wnum\(0),
  I1 => fifo_sc_hs_inst_n7_6,
  I2 => fifo_sc_hs_inst_n184_4,
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
  I3 => fifo_sc_hs_inst_n184_4);
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
\fifo_sc_hs_inst/n184_s1\: LUT2
generic map (
  INIT => X"4"
)
port map (
  F => fifo_sc_hs_inst_n184_4,
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
\fifo_sc_hs_inst/n184_1_s1\: LUT4
generic map (
  INIT => X"F4FF"
)
port map (
  F => fifo_sc_hs_inst_n184_1,
  I0 => \fifo_sc_hs_inst/Wnum\(0),
  I1 => fifo_sc_hs_inst_n7_6,
  I2 => fifo_sc_hs_inst_n184_4,
  I3 => WrEn);
\fifo_sc_hs_inst/Almost_Empty_d_s0\: LUT4
generic map (
  INIT => X"00B2"
)
port map (
  F => Almost_Empty,
  I0 => AlmostEmptyTh(3),
  I1 => \fifo_sc_hs_inst/Wnum\(3),
  I2 => fifo_sc_hs_inst_arempty_val_17,
  I3 => \fifo_sc_hs_inst/Wnum\(4));
\fifo_sc_hs_inst/rempty_val_s1\: INV
port map (
  O => fifo_sc_hs_inst_rempty_val,
  I => fifo_sc_hs_inst_n251_3);
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
