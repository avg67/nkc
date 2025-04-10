--
--Written by GowinSynthesis
--Tool Version "V1.9.10 (64-bit)"
--Wed Sep  4 18:15:42 2024

--Source file index table:
--file0 "\C:/working/_Tang_nano/gdp_fpga/VHDL/GDP936X/vhdl/rtl/FPGA/fifo_sc_hs/temp/FIFO_SC/fifo_sc_hs_define.v"
--file1 "\C:/working/_Tang_nano/gdp_fpga/VHDL/GDP936X/vhdl/rtl/FPGA/fifo_sc_hs/temp/FIFO_SC/fifo_sc_hs_parameter.v"
--file2 "\C:/Gowin/Gowin_V1.9.10_x64/IDE/ipcore/FIFO_SC_HS/data/fifo_sc_hs.v"
--file3 "\C:/Gowin/Gowin_V1.9.10_x64/IDE/ipcore/FIFO_SC_HS/data/fifo_sc_hs_top.v"
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
  AlmostEmptyTh :  in std_logic_vector(4 downto 0);
  Almost_Empty :  out std_logic;
  Q :  out std_logic_vector(31 downto 0);
  Empty :  out std_logic;
  Full :  out std_logic);
end video_fifo;
architecture beh of video_fifo is
  signal fifo_sc_hs_inst_arempty_val : std_logic ;
  signal fifo_sc_hs_inst_arempty_val_15 : std_logic ;
  signal fifo_sc_hs_inst_arempty_val_16 : std_logic ;
  signal fifo_sc_hs_inst_arempty_val_17 : std_logic ;
  signal fifo_sc_hs_inst_arempty_val_18 : std_logic ;
  signal fifo_sc_hs_inst_arempty_val_19 : std_logic ;
  signal fifo_sc_hs_inst_arempty_val_20 : std_logic ;
  signal fifo_sc_hs_inst_arempty_val_21 : std_logic ;
  signal fifo_sc_hs_inst_n242 : std_logic ;
  signal fifo_sc_hs_inst_n242_1 : std_logic ;
  signal fifo_sc_hs_inst_n241 : std_logic ;
  signal fifo_sc_hs_inst_n241_1 : std_logic ;
  signal fifo_sc_hs_inst_n240 : std_logic ;
  signal fifo_sc_hs_inst_n240_1 : std_logic ;
  signal fifo_sc_hs_inst_n239 : std_logic ;
  signal fifo_sc_hs_inst_n239_1 : std_logic ;
  signal fifo_sc_hs_inst_n238 : std_logic ;
  signal fifo_sc_hs_inst_n238_1 : std_logic ;
  signal fifo_sc_hs_inst_n237 : std_logic ;
  signal fifo_sc_hs_inst_n237_1 : std_logic ;
  signal fifo_sc_hs_inst_wbin_next_0 : std_logic ;
  signal fifo_sc_hs_inst_wbin_next_1 : std_logic ;
  signal fifo_sc_hs_inst_wbin_next_2 : std_logic ;
  signal fifo_sc_hs_inst_wbin_next_3 : std_logic ;
  signal fifo_sc_hs_inst_wbin_next_4 : std_logic ;
  signal fifo_sc_hs_inst_wbin_next_5 : std_logic ;
  signal fifo_sc_hs_inst_n257 : std_logic ;
  signal fifo_sc_hs_inst_n257_3 : std_logic ;
  signal fifo_sc_hs_inst_n258 : std_logic ;
  signal fifo_sc_hs_inst_n258_3 : std_logic ;
  signal fifo_sc_hs_inst_n259 : std_logic ;
  signal fifo_sc_hs_inst_n259_3 : std_logic ;
  signal fifo_sc_hs_inst_n260 : std_logic ;
  signal fifo_sc_hs_inst_n260_3 : std_logic ;
  signal fifo_sc_hs_inst_n261 : std_logic ;
  signal fifo_sc_hs_inst_n261_3 : std_logic ;
  signal fifo_sc_hs_inst_n262 : std_logic ;
  signal fifo_sc_hs_inst_n262_3 : std_logic ;
  signal fifo_sc_hs_inst_n13 : std_logic ;
  signal fifo_sc_hs_inst_n190 : std_logic ;
  signal fifo_sc_hs_inst_Wnum_5 : std_logic ;
  signal fifo_sc_hs_inst_n7 : std_logic ;
  signal fifo_sc_hs_inst_n7_7 : std_logic ;
  signal fifo_sc_hs_inst_n190_4 : std_logic ;
  signal fifo_sc_hs_inst_rbin_next_2 : std_logic ;
  signal fifo_sc_hs_inst_rbin_next_4 : std_logic ;
  signal fifo_sc_hs_inst_n7_9 : std_logic ;
  signal fifo_sc_hs_inst_n190_1 : std_logic ;
  signal fifo_sc_hs_inst_rempty_val : std_logic ;
  signal GND_0 : std_logic ;
  signal VCC_0 : std_logic ;
  signal \fifo_sc_hs_inst/rbin\ : std_logic_vector(5 downto 0);
  signal \fifo_sc_hs_inst/wbin\ : std_logic_vector(5 downto 0);
  signal \fifo_sc_hs_inst/Wnum\ : std_logic_vector(5 downto 0);
  signal \fifo_sc_hs_inst/wbin_next\ : std_logic_vector(5 downto 0);
  signal \fifo_sc_hs_inst/rbin_next\ : std_logic_vector(5 downto 0);
  signal NN : std_logic;
begin
\fifo_sc_hs_inst/rbin_5_s0\: DFFC
port map (
  Q => \fifo_sc_hs_inst/rbin\(5),
  D => \fifo_sc_hs_inst/rbin_next\(5),
  CLK => Clk,
  CLEAR => Reset);
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
\fifo_sc_hs_inst/wbin_5_s0\: DFFC
port map (
  Q => \fifo_sc_hs_inst/wbin\(5),
  D => \fifo_sc_hs_inst/wbin_next\(5),
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
\fifo_sc_hs_inst/Wnum_5_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \fifo_sc_hs_inst/Wnum\(5),
  D => fifo_sc_hs_inst_n237,
  CLK => Clk,
  CE => fifo_sc_hs_inst_Wnum_5,
  CLEAR => Reset);
\fifo_sc_hs_inst/Wnum_4_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \fifo_sc_hs_inst/Wnum\(4),
  D => fifo_sc_hs_inst_n238,
  CLK => Clk,
  CE => fifo_sc_hs_inst_Wnum_5,
  CLEAR => Reset);
\fifo_sc_hs_inst/Wnum_3_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \fifo_sc_hs_inst/Wnum\(3),
  D => fifo_sc_hs_inst_n239,
  CLK => Clk,
  CE => fifo_sc_hs_inst_Wnum_5,
  CLEAR => Reset);
\fifo_sc_hs_inst/Wnum_2_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \fifo_sc_hs_inst/Wnum\(2),
  D => fifo_sc_hs_inst_n240,
  CLK => Clk,
  CE => fifo_sc_hs_inst_Wnum_5,
  CLEAR => Reset);
\fifo_sc_hs_inst/Wnum_1_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \fifo_sc_hs_inst/Wnum\(1),
  D => fifo_sc_hs_inst_n241,
  CLK => Clk,
  CE => fifo_sc_hs_inst_Wnum_5,
  CLEAR => Reset);
\fifo_sc_hs_inst/Wnum_0_s1\: DFFCE
generic map (
  INIT => '0'
)
port map (
  Q => \fifo_sc_hs_inst/Wnum\(0),
  D => fifo_sc_hs_inst_n242,
  CLK => Clk,
  CE => fifo_sc_hs_inst_Wnum_5,
  CLEAR => Reset);
\fifo_sc_hs_inst/arempty_val_s12\: ALU
generic map (
  ALU_MODE => 1
)
port map (
  SUM => fifo_sc_hs_inst_arempty_val,
  COUT => fifo_sc_hs_inst_arempty_val_15,
  I0 => VCC_0,
  I1 => \fifo_sc_hs_inst/Wnum\(0),
  I3 => GND_0,
  CIN => AlmostEmptyTh(0));
\fifo_sc_hs_inst/arempty_val_s13\: ALU
generic map (
  ALU_MODE => 1
)
port map (
  SUM => fifo_sc_hs_inst_arempty_val_16,
  COUT => fifo_sc_hs_inst_arempty_val_17,
  I0 => AlmostEmptyTh(1),
  I1 => \fifo_sc_hs_inst/Wnum\(1),
  I3 => GND_0,
  CIN => fifo_sc_hs_inst_arempty_val_15);
\fifo_sc_hs_inst/arempty_val_s14\: ALU
generic map (
  ALU_MODE => 1
)
port map (
  SUM => fifo_sc_hs_inst_arempty_val_18,
  COUT => fifo_sc_hs_inst_arempty_val_19,
  I0 => AlmostEmptyTh(2),
  I1 => \fifo_sc_hs_inst/Wnum\(2),
  I3 => GND_0,
  CIN => fifo_sc_hs_inst_arempty_val_17);
\fifo_sc_hs_inst/arempty_val_s15\: ALU
generic map (
  ALU_MODE => 1
)
port map (
  SUM => fifo_sc_hs_inst_arempty_val_20,
  COUT => fifo_sc_hs_inst_arempty_val_21,
  I0 => AlmostEmptyTh(3),
  I1 => \fifo_sc_hs_inst/Wnum\(3),
  I3 => GND_0,
  CIN => fifo_sc_hs_inst_arempty_val_19);
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
  ADA(9 downto 5) => \fifo_sc_hs_inst/wbin\(4 downto 0),
  ADA(4) => GND_0,
  ADA(3) => VCC_0,
  ADA(2) => VCC_0,
  ADA(1) => VCC_0,
  ADA(0) => VCC_0,
  ADB(13) => GND_0,
  ADB(12) => GND_0,
  ADB(11) => GND_0,
  ADB(10) => GND_0,
  ADB(9 downto 5) => \fifo_sc_hs_inst/rbin_next\(4 downto 0),
  ADB(4) => GND_0,
  ADB(3) => GND_0,
  ADB(2) => GND_0,
  ADB(1) => GND_0,
  ADB(0) => GND_0,
  CLKA => Clk,
  CLKB => Clk,
  CEA => fifo_sc_hs_inst_n7_9,
  CEB => fifo_sc_hs_inst_n13,
  OCE => GND_0,
  RESETA => GND_0,
  RESETB => Reset);
\fifo_sc_hs_inst/n242_1_s\: ALU
generic map (
  ALU_MODE => 2
)
port map (
  SUM => fifo_sc_hs_inst_n242,
  COUT => fifo_sc_hs_inst_n242_1,
  I0 => \fifo_sc_hs_inst/Wnum\(0),
  I1 => VCC_0,
  I3 => fifo_sc_hs_inst_n190,
  CIN => fifo_sc_hs_inst_n190_1);
\fifo_sc_hs_inst/n241_1_s\: ALU
generic map (
  ALU_MODE => 2
)
port map (
  SUM => fifo_sc_hs_inst_n241,
  COUT => fifo_sc_hs_inst_n241_1,
  I0 => \fifo_sc_hs_inst/Wnum\(1),
  I1 => GND_0,
  I3 => fifo_sc_hs_inst_n190,
  CIN => fifo_sc_hs_inst_n242_1);
\fifo_sc_hs_inst/n240_1_s\: ALU
generic map (
  ALU_MODE => 2
)
port map (
  SUM => fifo_sc_hs_inst_n240,
  COUT => fifo_sc_hs_inst_n240_1,
  I0 => \fifo_sc_hs_inst/Wnum\(2),
  I1 => GND_0,
  I3 => fifo_sc_hs_inst_n190,
  CIN => fifo_sc_hs_inst_n241_1);
\fifo_sc_hs_inst/n239_1_s\: ALU
generic map (
  ALU_MODE => 2
)
port map (
  SUM => fifo_sc_hs_inst_n239,
  COUT => fifo_sc_hs_inst_n239_1,
  I0 => \fifo_sc_hs_inst/Wnum\(3),
  I1 => GND_0,
  I3 => fifo_sc_hs_inst_n190,
  CIN => fifo_sc_hs_inst_n240_1);
\fifo_sc_hs_inst/n238_1_s\: ALU
generic map (
  ALU_MODE => 2
)
port map (
  SUM => fifo_sc_hs_inst_n238,
  COUT => fifo_sc_hs_inst_n238_1,
  I0 => \fifo_sc_hs_inst/Wnum\(4),
  I1 => GND_0,
  I3 => fifo_sc_hs_inst_n190,
  CIN => fifo_sc_hs_inst_n239_1);
\fifo_sc_hs_inst/n237_1_s\: ALU
generic map (
  ALU_MODE => 2
)
port map (
  SUM => fifo_sc_hs_inst_n237,
  COUT => fifo_sc_hs_inst_n237_1,
  I0 => \fifo_sc_hs_inst/Wnum\(5),
  I1 => GND_0,
  I3 => fifo_sc_hs_inst_n190,
  CIN => fifo_sc_hs_inst_n238_1);
\fifo_sc_hs_inst/wbin_next_0_s\: ALU
generic map (
  ALU_MODE => 0
)
port map (
  SUM => \fifo_sc_hs_inst/wbin_next\(0),
  COUT => fifo_sc_hs_inst_wbin_next_0,
  I0 => \fifo_sc_hs_inst/wbin\(0),
  I1 => fifo_sc_hs_inst_n7_9,
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
\fifo_sc_hs_inst/wbin_next_5_s\: ALU
generic map (
  ALU_MODE => 0
)
port map (
  SUM => \fifo_sc_hs_inst/wbin_next\(5),
  COUT => fifo_sc_hs_inst_wbin_next_5,
  I0 => \fifo_sc_hs_inst/wbin\(5),
  I1 => GND_0,
  I3 => GND_0,
  CIN => fifo_sc_hs_inst_wbin_next_4);
\fifo_sc_hs_inst/n257_s0\: ALU
generic map (
  ALU_MODE => 3
)
port map (
  SUM => fifo_sc_hs_inst_n257,
  COUT => fifo_sc_hs_inst_n257_3,
  I0 => \fifo_sc_hs_inst/rbin_next\(0),
  I1 => \fifo_sc_hs_inst/wbin\(0),
  I3 => GND_0,
  CIN => GND_0);
\fifo_sc_hs_inst/n258_s0\: ALU
generic map (
  ALU_MODE => 3
)
port map (
  SUM => fifo_sc_hs_inst_n258,
  COUT => fifo_sc_hs_inst_n258_3,
  I0 => \fifo_sc_hs_inst/rbin_next\(1),
  I1 => \fifo_sc_hs_inst/wbin\(1),
  I3 => GND_0,
  CIN => fifo_sc_hs_inst_n257_3);
\fifo_sc_hs_inst/n259_s0\: ALU
generic map (
  ALU_MODE => 3
)
port map (
  SUM => fifo_sc_hs_inst_n259,
  COUT => fifo_sc_hs_inst_n259_3,
  I0 => \fifo_sc_hs_inst/rbin_next\(2),
  I1 => \fifo_sc_hs_inst/wbin\(2),
  I3 => GND_0,
  CIN => fifo_sc_hs_inst_n258_3);
\fifo_sc_hs_inst/n260_s0\: ALU
generic map (
  ALU_MODE => 3
)
port map (
  SUM => fifo_sc_hs_inst_n260,
  COUT => fifo_sc_hs_inst_n260_3,
  I0 => \fifo_sc_hs_inst/rbin_next\(3),
  I1 => \fifo_sc_hs_inst/wbin\(3),
  I3 => GND_0,
  CIN => fifo_sc_hs_inst_n259_3);
\fifo_sc_hs_inst/n261_s0\: ALU
generic map (
  ALU_MODE => 3
)
port map (
  SUM => fifo_sc_hs_inst_n261,
  COUT => fifo_sc_hs_inst_n261_3,
  I0 => \fifo_sc_hs_inst/rbin_next\(4),
  I1 => \fifo_sc_hs_inst/wbin\(4),
  I3 => GND_0,
  CIN => fifo_sc_hs_inst_n260_3);
\fifo_sc_hs_inst/n262_s0\: ALU
generic map (
  ALU_MODE => 3
)
port map (
  SUM => fifo_sc_hs_inst_n262,
  COUT => fifo_sc_hs_inst_n262_3,
  I0 => \fifo_sc_hs_inst/rbin_next\(5),
  I1 => \fifo_sc_hs_inst/wbin\(5),
  I3 => GND_0,
  CIN => fifo_sc_hs_inst_n261_3);
\fifo_sc_hs_inst/n13_s1\: LUT3
generic map (
  INIT => X"E0"
)
port map (
  F => fifo_sc_hs_inst_n13,
  I0 => RdEn,
  I1 => NN,
  I2 => fifo_sc_hs_inst_n262_3);
\fifo_sc_hs_inst/n190_s0\: LUT4
generic map (
  INIT => X"0700"
)
port map (
  F => fifo_sc_hs_inst_n190,
  I0 => fifo_sc_hs_inst_n7,
  I1 => fifo_sc_hs_inst_n7_7,
  I2 => fifo_sc_hs_inst_n190_4,
  I3 => WrEn);
\fifo_sc_hs_inst/Wnum_5_s3\: LUT4
generic map (
  INIT => X"8F70"
)
port map (
  F => fifo_sc_hs_inst_Wnum_5,
  I0 => fifo_sc_hs_inst_n7_7,
  I1 => fifo_sc_hs_inst_n7,
  I2 => WrEn,
  I3 => fifo_sc_hs_inst_n190_4);
\fifo_sc_hs_inst/rbin_next_2_s5\: LUT2
generic map (
  INIT => X"6"
)
port map (
  F => \fifo_sc_hs_inst/rbin_next\(2),
  I0 => \fifo_sc_hs_inst/rbin\(2),
  I1 => fifo_sc_hs_inst_rbin_next_2);
\fifo_sc_hs_inst/rbin_next_3_s5\: LUT3
generic map (
  INIT => X"78"
)
port map (
  F => \fifo_sc_hs_inst/rbin_next\(3),
  I0 => \fifo_sc_hs_inst/rbin\(2),
  I1 => fifo_sc_hs_inst_rbin_next_2,
  I2 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/rbin_next_5_s2\: LUT4
generic map (
  INIT => X"7F80"
)
port map (
  F => \fifo_sc_hs_inst/rbin_next\(5),
  I0 => \fifo_sc_hs_inst/rbin\(4),
  I1 => fifo_sc_hs_inst_rbin_next_2,
  I2 => fifo_sc_hs_inst_rbin_next_4,
  I3 => \fifo_sc_hs_inst/rbin\(5));
\fifo_sc_hs_inst/n7_s2\: LUT4
generic map (
  INIT => X"0100"
)
port map (
  F => fifo_sc_hs_inst_n7,
  I0 => \fifo_sc_hs_inst/Wnum\(2),
  I1 => \fifo_sc_hs_inst/Wnum\(3),
  I2 => \fifo_sc_hs_inst/Wnum\(4),
  I3 => \fifo_sc_hs_inst/Wnum\(5));
\fifo_sc_hs_inst/n7_s3\: LUT2
generic map (
  INIT => X"1"
)
port map (
  F => fifo_sc_hs_inst_n7_7,
  I0 => \fifo_sc_hs_inst/Wnum\(0),
  I1 => \fifo_sc_hs_inst/Wnum\(1));
\fifo_sc_hs_inst/n190_s1\: LUT2
generic map (
  INIT => X"4"
)
port map (
  F => fifo_sc_hs_inst_n190_4,
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
\fifo_sc_hs_inst/rbin_next_4_s6\: LUT2
generic map (
  INIT => X"8"
)
port map (
  F => fifo_sc_hs_inst_rbin_next_4,
  I0 => \fifo_sc_hs_inst/rbin\(2),
  I1 => \fifo_sc_hs_inst/rbin\(3));
\fifo_sc_hs_inst/rbin_next_4_s7\: LUT4
generic map (
  INIT => X"7F80"
)
port map (
  F => \fifo_sc_hs_inst/rbin_next\(4),
  I0 => fifo_sc_hs_inst_rbin_next_2,
  I1 => \fifo_sc_hs_inst/rbin\(2),
  I2 => \fifo_sc_hs_inst/rbin\(3),
  I3 => \fifo_sc_hs_inst/rbin\(4));
\fifo_sc_hs_inst/rbin_next_1_s6\: LUT4
generic map (
  INIT => X"DF20"
)
port map (
  F => \fifo_sc_hs_inst/rbin_next\(1),
  I0 => \fifo_sc_hs_inst/rbin\(0),
  I1 => NN,
  I2 => RdEn,
  I3 => \fifo_sc_hs_inst/rbin\(1));
\fifo_sc_hs_inst/rbin_next_0_s6\: LUT3
generic map (
  INIT => X"9A"
)
port map (
  F => \fifo_sc_hs_inst/rbin_next\(0),
  I0 => \fifo_sc_hs_inst/rbin\(0),
  I1 => NN,
  I2 => RdEn);
\fifo_sc_hs_inst/Full_d_s0\: LUT3
generic map (
  INIT => X"10"
)
port map (
  F => Full,
  I0 => \fifo_sc_hs_inst/Wnum\(0),
  I1 => \fifo_sc_hs_inst/Wnum\(1),
  I2 => fifo_sc_hs_inst_n7);
\fifo_sc_hs_inst/n7_s4\: LUT4
generic map (
  INIT => X"FD00"
)
port map (
  F => fifo_sc_hs_inst_n7_9,
  I0 => fifo_sc_hs_inst_n7,
  I1 => \fifo_sc_hs_inst/Wnum\(0),
  I2 => \fifo_sc_hs_inst/Wnum\(1),
  I3 => WrEn);
\fifo_sc_hs_inst/n190_1_s1\: LUT4
generic map (
  INIT => X"F8FF"
)
port map (
  F => fifo_sc_hs_inst_n190_1,
  I0 => fifo_sc_hs_inst_n7,
  I1 => fifo_sc_hs_inst_n7_7,
  I2 => fifo_sc_hs_inst_n190_4,
  I3 => WrEn);
\fifo_sc_hs_inst/Almost_Empty_d_s0\: LUT4
generic map (
  INIT => X"00B2"
)
port map (
  F => Almost_Empty,
  I0 => AlmostEmptyTh(4),
  I1 => \fifo_sc_hs_inst/Wnum\(4),
  I2 => fifo_sc_hs_inst_arempty_val_21,
  I3 => \fifo_sc_hs_inst/Wnum\(5));
\fifo_sc_hs_inst/rempty_val_s1\: INV
port map (
  O => fifo_sc_hs_inst_rempty_val,
  I => fifo_sc_hs_inst_n262_3);
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
