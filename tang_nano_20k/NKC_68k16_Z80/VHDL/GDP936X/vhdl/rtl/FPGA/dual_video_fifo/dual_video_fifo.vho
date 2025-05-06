--
--Written by GowinSynthesis
--Tool Version "V1.9.10.03 (64-bit)"
--Mon Apr  7 19:25:26 2025

--Source file index table:
--file0 "\C:/Gowin/Gowin_V1.9.10.03_x64/IDE/ipcore/FIFO_HS/data/fifo_hs.v"
--file1 "\C:/Gowin/Gowin_V1.9.10.03_x64/IDE/ipcore/FIFO_HS/data/fifo_hs_top.v"
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library gw2a;
use gw2a.components.all;

entity dual_video_fifo is
port(
  Data :  in std_logic_vector(31 downto 0);
  WrReset :  in std_logic;
  RdReset :  in std_logic;
  WrClk :  in std_logic;
  RdClk :  in std_logic;
  WrEn :  in std_logic;
  RdEn :  in std_logic;
  AlmostEmptyTh :  in std_logic_vector(4 downto 0);
  Almost_Empty :  out std_logic;
  Q :  out std_logic_vector(31 downto 0);
  Empty :  out std_logic;
  Full :  out std_logic);
end dual_video_fifo;
architecture beh of dual_video_fifo is
  signal fifo_inst_wfull_val1 : std_logic ;
  signal fifo_inst_wfull_val1_3 : std_logic ;
  signal fifo_inst_Full : std_logic ;
  signal fifo_inst_Full_2 : std_logic ;
  signal fifo_inst_n328 : std_logic ;
  signal fifo_inst_n328_16 : std_logic ;
  signal fifo_inst_n328_17 : std_logic ;
  signal fifo_inst_n328_18 : std_logic ;
  signal fifo_inst_n328_19 : std_logic ;
  signal fifo_inst_n328_20 : std_logic ;
  signal fifo_inst_n328_21 : std_logic ;
  signal fifo_inst_n328_22 : std_logic ;
  signal fifo_inst_rcnt_sub_0 : std_logic ;
  signal fifo_inst_rcnt_sub_1 : std_logic ;
  signal fifo_inst_rcnt_sub_2 : std_logic ;
  signal fifo_inst_rcnt_sub_3 : std_logic ;
  signal fifo_inst_rcnt_sub_4 : std_logic ;
  signal fifo_inst_rcnt_sub_5 : std_logic ;
  signal fifo_inst_n156 : std_logic ;
  signal fifo_inst_n156_3 : std_logic ;
  signal fifo_inst_n157 : std_logic ;
  signal fifo_inst_n157_3 : std_logic ;
  signal fifo_inst_n158 : std_logic ;
  signal fifo_inst_n158_3 : std_logic ;
  signal fifo_inst_n159 : std_logic ;
  signal fifo_inst_n159_3 : std_logic ;
  signal fifo_inst_n160 : std_logic ;
  signal fifo_inst_n160_3 : std_logic ;
  signal fifo_inst_n16 : std_logic ;
  signal fifo_inst_n22 : std_logic ;
  signal fifo_inst_n184 : std_logic ;
  signal fifo_inst_wfull_val : std_logic ;
  signal fifo_inst_arempty_val : std_logic ;
  signal fifo_inst_wfull_val1_13 : std_logic ;
  signal fifo_inst_wfull_val1_16 : std_logic ;
  signal fifo_inst_Full_11 : std_logic ;
  signal \fifo_inst_Equal.wbinnext_0\ : std_logic ;
  signal \fifo_inst_Equal.rgraynext_3\ : std_logic ;
  signal \fifo_inst_Equal.rgraynext_4\ : std_logic ;
  signal fifo_inst_wfull_val_4 : std_logic ;
  signal fifo_inst_wfull_val_5 : std_logic ;
  signal fifo_inst_wfull_val_6 : std_logic ;
  signal fifo_inst_arempty_val_4 : std_logic ;
  signal fifo_inst_arempty_val_5 : std_logic ;
  signal fifo_inst_arempty_val_6 : std_logic ;
  signal fifo_inst_arempty_val_8 : std_logic ;
  signal fifo_inst_arempty_val_9 : std_logic ;
  signal fifo_inst_arempty_val_10 : std_logic ;
  signal fifo_inst_arempty_val_11 : std_logic ;
  signal fifo_inst_arempty_val_12 : std_logic ;
  signal \fifo_inst_Equal.wgraynext_2\ : std_logic ;
  signal fifo_inst_n455 : std_logic ;
  signal fifo_inst_arempty_val_15 : std_logic ;
  signal fifo_inst_rempty_val : std_logic ;
  signal GND_0 : std_logic ;
  signal VCC_0 : std_logic ;
  signal \fifo_inst/rbin_num\ : std_logic_vector(4 downto 0);
  signal \fifo_inst/Equal.rq1_wptr\ : std_logic_vector(5 downto 0);
  signal \fifo_inst/Equal.rq2_wptr\ : std_logic_vector(5 downto 0);
  signal \fifo_inst/rptr\ : std_logic_vector(5 downto 0);
  signal \fifo_inst/wptr\ : std_logic_vector(5 downto 0);
  signal \fifo_inst/Equal.wbin\ : std_logic_vector(4 downto 0);
  signal \fifo_inst/Equal.wcount_r_d\ : std_logic_vector(5 downto 0);
  signal \fifo_inst/rcnt_sub_d\ : std_logic_vector(5 downto 0);
  signal \fifo_inst/rcnt_sub\ : std_logic_vector(5 downto 0);
  signal \fifo_inst/Equal.rgraynext\ : std_logic_vector(4 downto 0);
  signal \fifo_inst/Equal.wcount_r\ : std_logic_vector(4 downto 0);
  signal \fifo_inst/Equal.wgraynext\ : std_logic_vector(4 downto 0);
  signal \fifo_inst/rbin_num_next\ : std_logic_vector(5 downto 0);
  signal \fifo_inst/Equal.wbinnext\ : std_logic_vector(5 downto 1);
  signal NN : std_logic;
begin
\fifo_inst/rbin_num_4_s0\: DFFC
port map (
  Q => \fifo_inst/rbin_num\(4),
  D => \fifo_inst/rbin_num_next\(4),
  CLK => RdClk,
  CLEAR => RdReset);
\fifo_inst/rbin_num_3_s0\: DFFC
port map (
  Q => \fifo_inst/rbin_num\(3),
  D => \fifo_inst/rbin_num_next\(3),
  CLK => RdClk,
  CLEAR => RdReset);
\fifo_inst/rbin_num_2_s0\: DFFC
port map (
  Q => \fifo_inst/rbin_num\(2),
  D => \fifo_inst/rbin_num_next\(2),
  CLK => RdClk,
  CLEAR => RdReset);
\fifo_inst/rbin_num_1_s0\: DFFC
port map (
  Q => \fifo_inst/rbin_num\(1),
  D => \fifo_inst/rbin_num_next\(1),
  CLK => RdClk,
  CLEAR => RdReset);
\fifo_inst/rbin_num_0_s0\: DFFC
port map (
  Q => \fifo_inst/rbin_num\(0),
  D => \fifo_inst/rbin_num_next\(0),
  CLK => RdClk,
  CLEAR => RdReset);
\fifo_inst/Equal.rq1_wptr_5_s0\: DFFC
port map (
  Q => \fifo_inst/Equal.rq1_wptr\(5),
  D => \fifo_inst/wptr\(5),
  CLK => RdClk,
  CLEAR => RdReset);
\fifo_inst/Equal.rq1_wptr_4_s0\: DFFC
port map (
  Q => \fifo_inst/Equal.rq1_wptr\(4),
  D => \fifo_inst/wptr\(4),
  CLK => RdClk,
  CLEAR => RdReset);
\fifo_inst/Equal.rq1_wptr_3_s0\: DFFC
port map (
  Q => \fifo_inst/Equal.rq1_wptr\(3),
  D => \fifo_inst/wptr\(3),
  CLK => RdClk,
  CLEAR => RdReset);
\fifo_inst/Equal.rq1_wptr_2_s0\: DFFC
port map (
  Q => \fifo_inst/Equal.rq1_wptr\(2),
  D => \fifo_inst/wptr\(2),
  CLK => RdClk,
  CLEAR => RdReset);
\fifo_inst/Equal.rq1_wptr_1_s0\: DFFC
port map (
  Q => \fifo_inst/Equal.rq1_wptr\(1),
  D => \fifo_inst/wptr\(1),
  CLK => RdClk,
  CLEAR => RdReset);
\fifo_inst/Equal.rq1_wptr_0_s0\: DFFC
port map (
  Q => \fifo_inst/Equal.rq1_wptr\(0),
  D => \fifo_inst/wptr\(0),
  CLK => RdClk,
  CLEAR => RdReset);
\fifo_inst/Equal.rq2_wptr_5_s0\: DFFC
port map (
  Q => \fifo_inst/Equal.rq2_wptr\(5),
  D => \fifo_inst/Equal.rq1_wptr\(5),
  CLK => RdClk,
  CLEAR => RdReset);
\fifo_inst/Equal.rq2_wptr_4_s0\: DFFC
port map (
  Q => \fifo_inst/Equal.rq2_wptr\(4),
  D => \fifo_inst/Equal.rq1_wptr\(4),
  CLK => RdClk,
  CLEAR => RdReset);
\fifo_inst/Equal.rq2_wptr_3_s0\: DFFC
port map (
  Q => \fifo_inst/Equal.rq2_wptr\(3),
  D => \fifo_inst/Equal.rq1_wptr\(3),
  CLK => RdClk,
  CLEAR => RdReset);
\fifo_inst/Equal.rq2_wptr_2_s0\: DFFC
port map (
  Q => \fifo_inst/Equal.rq2_wptr\(2),
  D => \fifo_inst/Equal.rq1_wptr\(2),
  CLK => RdClk,
  CLEAR => RdReset);
\fifo_inst/Equal.rq2_wptr_1_s0\: DFFC
port map (
  Q => \fifo_inst/Equal.rq2_wptr\(1),
  D => \fifo_inst/Equal.rq1_wptr\(1),
  CLK => RdClk,
  CLEAR => RdReset);
\fifo_inst/Equal.rq2_wptr_0_s0\: DFFC
port map (
  Q => \fifo_inst/Equal.rq2_wptr\(0),
  D => \fifo_inst/Equal.rq1_wptr\(0),
  CLK => RdClk,
  CLEAR => RdReset);
\fifo_inst/rptr_5_s0\: DFFC
port map (
  Q => \fifo_inst/rptr\(5),
  D => \fifo_inst/rbin_num_next\(5),
  CLK => RdClk,
  CLEAR => RdReset);
\fifo_inst/rptr_4_s0\: DFFC
port map (
  Q => \fifo_inst/rptr\(4),
  D => \fifo_inst/Equal.rgraynext\(4),
  CLK => RdClk,
  CLEAR => RdReset);
\fifo_inst/rptr_3_s0\: DFFC
port map (
  Q => \fifo_inst/rptr\(3),
  D => \fifo_inst/Equal.rgraynext\(3),
  CLK => RdClk,
  CLEAR => RdReset);
\fifo_inst/rptr_2_s0\: DFFC
port map (
  Q => \fifo_inst/rptr\(2),
  D => \fifo_inst/Equal.rgraynext\(2),
  CLK => RdClk,
  CLEAR => RdReset);
\fifo_inst/rptr_1_s0\: DFFC
port map (
  Q => \fifo_inst/rptr\(1),
  D => \fifo_inst/Equal.rgraynext\(1),
  CLK => RdClk,
  CLEAR => RdReset);
\fifo_inst/rptr_0_s0\: DFFC
port map (
  Q => \fifo_inst/rptr\(0),
  D => \fifo_inst/Equal.rgraynext\(0),
  CLK => RdClk,
  CLEAR => RdReset);
\fifo_inst/wptr_5_s0\: DFFC
port map (
  Q => \fifo_inst/wptr\(5),
  D => \fifo_inst/Equal.wbinnext\(5),
  CLK => WrClk,
  CLEAR => WrReset);
\fifo_inst/wptr_4_s0\: DFFC
port map (
  Q => \fifo_inst/wptr\(4),
  D => \fifo_inst/Equal.wgraynext\(4),
  CLK => WrClk,
  CLEAR => WrReset);
\fifo_inst/wptr_3_s0\: DFFC
port map (
  Q => \fifo_inst/wptr\(3),
  D => \fifo_inst/Equal.wgraynext\(3),
  CLK => WrClk,
  CLEAR => WrReset);
\fifo_inst/wptr_2_s0\: DFFC
port map (
  Q => \fifo_inst/wptr\(2),
  D => \fifo_inst/Equal.wgraynext\(2),
  CLK => WrClk,
  CLEAR => WrReset);
\fifo_inst/wptr_1_s0\: DFFC
port map (
  Q => \fifo_inst/wptr\(1),
  D => \fifo_inst/Equal.wgraynext\(1),
  CLK => WrClk,
  CLEAR => WrReset);
\fifo_inst/wptr_0_s0\: DFFC
port map (
  Q => \fifo_inst/wptr\(0),
  D => \fifo_inst/Equal.wgraynext\(0),
  CLK => WrClk,
  CLEAR => WrReset);
\fifo_inst/Equal.wbin_4_s0\: DFFC
port map (
  Q => \fifo_inst/Equal.wbin\(4),
  D => \fifo_inst/Equal.wbinnext\(4),
  CLK => WrClk,
  CLEAR => WrReset);
\fifo_inst/Equal.wbin_3_s0\: DFFC
port map (
  Q => \fifo_inst/Equal.wbin\(3),
  D => \fifo_inst/Equal.wbinnext\(3),
  CLK => WrClk,
  CLEAR => WrReset);
\fifo_inst/Equal.wbin_2_s0\: DFFC
port map (
  Q => \fifo_inst/Equal.wbin\(2),
  D => \fifo_inst/Equal.wbinnext\(2),
  CLK => WrClk,
  CLEAR => WrReset);
\fifo_inst/Equal.wbin_1_s0\: DFFC
port map (
  Q => \fifo_inst/Equal.wbin\(1),
  D => \fifo_inst/Equal.wbinnext\(1),
  CLK => WrClk,
  CLEAR => WrReset);
\fifo_inst/Equal.wbin_0_s0\: DFFC
port map (
  Q => \fifo_inst/Equal.wbin\(0),
  D => \fifo_inst_Equal.wbinnext_0\,
  CLK => WrClk,
  CLEAR => WrReset);
\fifo_inst/Equal.wcount_r_d_5_s0\: DFFC
port map (
  Q => \fifo_inst/Equal.wcount_r_d\(5),
  D => \fifo_inst/Equal.rq2_wptr\(5),
  CLK => RdClk,
  CLEAR => RdReset);
\fifo_inst/Equal.wcount_r_d_4_s0\: DFFC
port map (
  Q => \fifo_inst/Equal.wcount_r_d\(4),
  D => \fifo_inst/Equal.wcount_r\(4),
  CLK => RdClk,
  CLEAR => RdReset);
\fifo_inst/Equal.wcount_r_d_3_s0\: DFFC
port map (
  Q => \fifo_inst/Equal.wcount_r_d\(3),
  D => \fifo_inst/Equal.wcount_r\(3),
  CLK => RdClk,
  CLEAR => RdReset);
\fifo_inst/Equal.wcount_r_d_2_s0\: DFFC
port map (
  Q => \fifo_inst/Equal.wcount_r_d\(2),
  D => \fifo_inst/Equal.wcount_r\(2),
  CLK => RdClk,
  CLEAR => RdReset);
\fifo_inst/Equal.wcount_r_d_1_s0\: DFFC
port map (
  Q => \fifo_inst/Equal.wcount_r_d\(1),
  D => \fifo_inst/Equal.wcount_r\(1),
  CLK => RdClk,
  CLEAR => RdReset);
\fifo_inst/Equal.wcount_r_d_0_s0\: DFFC
port map (
  Q => \fifo_inst/Equal.wcount_r_d\(0),
  D => \fifo_inst/Equal.wcount_r\(0),
  CLK => RdClk,
  CLEAR => RdReset);
\fifo_inst/rcnt_sub_d_5_s0\: DFFC
port map (
  Q => \fifo_inst/rcnt_sub_d\(5),
  D => \fifo_inst/rcnt_sub\(5),
  CLK => RdClk,
  CLEAR => RdReset);
\fifo_inst/rcnt_sub_d_4_s0\: DFFC
port map (
  Q => \fifo_inst/rcnt_sub_d\(4),
  D => \fifo_inst/rcnt_sub\(4),
  CLK => RdClk,
  CLEAR => RdReset);
\fifo_inst/rcnt_sub_d_3_s0\: DFFC
port map (
  Q => \fifo_inst/rcnt_sub_d\(3),
  D => \fifo_inst/rcnt_sub\(3),
  CLK => RdClk,
  CLEAR => RdReset);
\fifo_inst/rcnt_sub_d_2_s0\: DFFC
port map (
  Q => \fifo_inst/rcnt_sub_d\(2),
  D => \fifo_inst/rcnt_sub\(2),
  CLK => RdClk,
  CLEAR => RdReset);
\fifo_inst/rcnt_sub_d_1_s0\: DFFC
port map (
  Q => \fifo_inst/rcnt_sub_d\(1),
  D => \fifo_inst/rcnt_sub\(1),
  CLK => RdClk,
  CLEAR => RdReset);
\fifo_inst/rcnt_sub_d_0_s0\: DFFC
port map (
  Q => \fifo_inst/rcnt_sub_d\(0),
  D => \fifo_inst/rcnt_sub\(0),
  CLK => RdClk,
  CLEAR => RdReset);
\fifo_inst/Empty_s0\: DFFP
port map (
  Q => NN,
  D => fifo_inst_rempty_val,
  CLK => RdClk,
  PRESET => RdReset);
\fifo_inst/Almost_Empty_s0\: DFFP
port map (
  Q => Almost_Empty,
  D => fifo_inst_arempty_val,
  CLK => RdClk,
  PRESET => RdReset);
\fifo_inst/wfull_val1_s0\: DFFC
port map (
  Q => fifo_inst_wfull_val1,
  D => fifo_inst_wfull_val,
  CLK => WrClk,
  CLEAR => WrReset);
\fifo_inst/wfull_val1_s1\: DFFP
port map (
  Q => fifo_inst_wfull_val1_3,
  D => fifo_inst_wfull_val,
  CLK => WrClk,
  PRESET => fifo_inst_n455);
\fifo_inst/Full_s0\: DFFC
port map (
  Q => fifo_inst_Full,
  D => fifo_inst_wfull_val1_13,
  CLK => WrClk,
  CLEAR => WrReset);
\fifo_inst/Full_s1\: DFFP
port map (
  Q => fifo_inst_Full_2,
  D => fifo_inst_wfull_val1_13,
  CLK => WrClk,
  PRESET => fifo_inst_n455);
\fifo_inst/n328_s12\: ALU
generic map (
  ALU_MODE => 1
)
port map (
  SUM => fifo_inst_n328,
  COUT => fifo_inst_n328_16,
  I0 => VCC_0,
  I1 => \fifo_inst/rcnt_sub_d\(0),
  I3 => GND_0,
  CIN => AlmostEmptyTh(0));
\fifo_inst/n328_s13\: ALU
generic map (
  ALU_MODE => 1
)
port map (
  SUM => fifo_inst_n328_17,
  COUT => fifo_inst_n328_18,
  I0 => AlmostEmptyTh(1),
  I1 => \fifo_inst/rcnt_sub_d\(1),
  I3 => GND_0,
  CIN => fifo_inst_n328_16);
\fifo_inst/n328_s14\: ALU
generic map (
  ALU_MODE => 1
)
port map (
  SUM => fifo_inst_n328_19,
  COUT => fifo_inst_n328_20,
  I0 => AlmostEmptyTh(2),
  I1 => \fifo_inst/rcnt_sub_d\(2),
  I3 => GND_0,
  CIN => fifo_inst_n328_18);
\fifo_inst/n328_s15\: ALU
generic map (
  ALU_MODE => 1
)
port map (
  SUM => fifo_inst_n328_21,
  COUT => fifo_inst_n328_22,
  I0 => AlmostEmptyTh(3),
  I1 => \fifo_inst/rcnt_sub_d\(3),
  I3 => GND_0,
  CIN => fifo_inst_n328_20);
\fifo_inst/Equal.mem_Equal.mem_0_0_s\: SDPB
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
  ADA(9 downto 5) => \fifo_inst/Equal.wbin\(4 downto 0),
  ADA(4) => GND_0,
  ADA(3) => VCC_0,
  ADA(2) => VCC_0,
  ADA(1) => VCC_0,
  ADA(0) => VCC_0,
  ADB(13) => GND_0,
  ADB(12) => GND_0,
  ADB(11) => GND_0,
  ADB(10) => GND_0,
  ADB(9 downto 5) => \fifo_inst/rbin_num_next\(4 downto 0),
  ADB(4) => GND_0,
  ADB(3) => GND_0,
  ADB(2) => GND_0,
  ADB(1) => GND_0,
  ADB(0) => GND_0,
  CLKA => WrClk,
  CLKB => RdClk,
  CEA => fifo_inst_n16,
  CEB => fifo_inst_n22,
  OCE => GND_0,
  RESETA => GND_0,
  RESETB => RdReset);
\fifo_inst/rcnt_sub_0_s\: ALU
generic map (
  ALU_MODE => 1
)
port map (
  SUM => \fifo_inst/rcnt_sub\(0),
  COUT => fifo_inst_rcnt_sub_0,
  I0 => \fifo_inst/Equal.wcount_r_d\(0),
  I1 => \fifo_inst/rbin_num\(0),
  I3 => GND_0,
  CIN => VCC_0);
\fifo_inst/rcnt_sub_1_s\: ALU
generic map (
  ALU_MODE => 1
)
port map (
  SUM => \fifo_inst/rcnt_sub\(1),
  COUT => fifo_inst_rcnt_sub_1,
  I0 => \fifo_inst/Equal.wcount_r_d\(1),
  I1 => \fifo_inst/rbin_num\(1),
  I3 => GND_0,
  CIN => fifo_inst_rcnt_sub_0);
\fifo_inst/rcnt_sub_2_s\: ALU
generic map (
  ALU_MODE => 1
)
port map (
  SUM => \fifo_inst/rcnt_sub\(2),
  COUT => fifo_inst_rcnt_sub_2,
  I0 => \fifo_inst/Equal.wcount_r_d\(2),
  I1 => \fifo_inst/rbin_num\(2),
  I3 => GND_0,
  CIN => fifo_inst_rcnt_sub_1);
\fifo_inst/rcnt_sub_3_s\: ALU
generic map (
  ALU_MODE => 1
)
port map (
  SUM => \fifo_inst/rcnt_sub\(3),
  COUT => fifo_inst_rcnt_sub_3,
  I0 => \fifo_inst/Equal.wcount_r_d\(3),
  I1 => \fifo_inst/rbin_num\(3),
  I3 => GND_0,
  CIN => fifo_inst_rcnt_sub_2);
\fifo_inst/rcnt_sub_4_s\: ALU
generic map (
  ALU_MODE => 1
)
port map (
  SUM => \fifo_inst/rcnt_sub\(4),
  COUT => fifo_inst_rcnt_sub_4,
  I0 => \fifo_inst/Equal.wcount_r_d\(4),
  I1 => \fifo_inst/rbin_num\(4),
  I3 => GND_0,
  CIN => fifo_inst_rcnt_sub_3);
\fifo_inst/rcnt_sub_5_s\: ALU
generic map (
  ALU_MODE => 1
)
port map (
  SUM => \fifo_inst/rcnt_sub\(5),
  COUT => fifo_inst_rcnt_sub_5,
  I0 => fifo_inst_n184,
  I1 => GND_0,
  I3 => GND_0,
  CIN => fifo_inst_rcnt_sub_4);
\fifo_inst/n156_s0\: ALU
generic map (
  ALU_MODE => 3
)
port map (
  SUM => fifo_inst_n156,
  COUT => fifo_inst_n156_3,
  I0 => \fifo_inst/Equal.rgraynext\(0),
  I1 => \fifo_inst/Equal.rq2_wptr\(0),
  I3 => GND_0,
  CIN => GND_0);
\fifo_inst/n157_s0\: ALU
generic map (
  ALU_MODE => 3
)
port map (
  SUM => fifo_inst_n157,
  COUT => fifo_inst_n157_3,
  I0 => \fifo_inst/Equal.rgraynext\(1),
  I1 => \fifo_inst/Equal.rq2_wptr\(1),
  I3 => GND_0,
  CIN => fifo_inst_n156_3);
\fifo_inst/n158_s0\: ALU
generic map (
  ALU_MODE => 3
)
port map (
  SUM => fifo_inst_n158,
  COUT => fifo_inst_n158_3,
  I0 => \fifo_inst/Equal.rgraynext\(2),
  I1 => \fifo_inst/Equal.rq2_wptr\(2),
  I3 => GND_0,
  CIN => fifo_inst_n157_3);
\fifo_inst/n159_s0\: ALU
generic map (
  ALU_MODE => 3
)
port map (
  SUM => fifo_inst_n159,
  COUT => fifo_inst_n159_3,
  I0 => \fifo_inst/Equal.rgraynext\(3),
  I1 => \fifo_inst/Equal.rq2_wptr\(3),
  I3 => GND_0,
  CIN => fifo_inst_n158_3);
\fifo_inst/n160_s0\: ALU
generic map (
  ALU_MODE => 3
)
port map (
  SUM => fifo_inst_n160,
  COUT => fifo_inst_n160_3,
  I0 => \fifo_inst/Equal.rgraynext\(4),
  I1 => \fifo_inst/Equal.rq2_wptr\(4),
  I3 => GND_0,
  CIN => fifo_inst_n159_3);
\fifo_inst/n16_s1\: LUT4
generic map (
  INIT => X"5300"
)
port map (
  F => fifo_inst_n16,
  I0 => fifo_inst_Full_2,
  I1 => fifo_inst_Full,
  I2 => fifo_inst_Full_11,
  I3 => WrEn);
\fifo_inst/n22_s1\: LUT3
generic map (
  INIT => X"0E"
)
port map (
  F => fifo_inst_n22,
  I0 => RdEn,
  I1 => NN,
  I2 => fifo_inst_rempty_val);
\fifo_inst/Equal.rgraynext_3_s0\: LUT4
generic map (
  INIT => X"07F8"
)
port map (
  F => \fifo_inst/Equal.rgraynext\(3),
  I0 => \fifo_inst/rbin_num\(2),
  I1 => \fifo_inst_Equal.rgraynext_3\,
  I2 => \fifo_inst/rbin_num\(3),
  I3 => \fifo_inst/rbin_num\(4));
\fifo_inst/Equal.rgraynext_4_s0\: LUT4
generic map (
  INIT => X"07F8"
)
port map (
  F => \fifo_inst/Equal.rgraynext\(4),
  I0 => \fifo_inst_Equal.rgraynext_3\,
  I1 => \fifo_inst_Equal.rgraynext_4\,
  I2 => \fifo_inst/rbin_num\(4),
  I3 => \fifo_inst/rptr\(5));
\fifo_inst/Equal.wcount_r_4_s0\: LUT2
generic map (
  INIT => X"6"
)
port map (
  F => \fifo_inst/Equal.wcount_r\(4),
  I0 => \fifo_inst/Equal.rq2_wptr\(5),
  I1 => \fifo_inst/Equal.rq2_wptr\(4));
\fifo_inst/Equal.wcount_r_1_s0\: LUT2
generic map (
  INIT => X"6"
)
port map (
  F => \fifo_inst/Equal.wcount_r\(1),
  I0 => \fifo_inst/Equal.rq2_wptr\(1),
  I1 => \fifo_inst/Equal.wcount_r\(2));
\fifo_inst/Equal.wcount_r_0_s0\: LUT3
generic map (
  INIT => X"96"
)
port map (
  F => \fifo_inst/Equal.wcount_r\(0),
  I0 => \fifo_inst/Equal.rq2_wptr\(1),
  I1 => \fifo_inst/Equal.rq2_wptr\(0),
  I2 => \fifo_inst/Equal.wcount_r\(2));
\fifo_inst/n184_s0\: LUT2
generic map (
  INIT => X"6"
)
port map (
  F => fifo_inst_n184,
  I0 => \fifo_inst/Equal.wcount_r_d\(5),
  I1 => \fifo_inst/rptr\(5));
\fifo_inst/Equal.wgraynext_2_s0\: LUT3
generic map (
  INIT => X"96"
)
port map (
  F => \fifo_inst/Equal.wgraynext\(2),
  I0 => \fifo_inst/Equal.wbin\(3),
  I1 => \fifo_inst_Equal.wgraynext_2\,
  I2 => \fifo_inst/Equal.wbinnext\(2));
\fifo_inst/Equal.wgraynext_3_s0\: LUT3
generic map (
  INIT => X"1E"
)
port map (
  F => \fifo_inst/Equal.wgraynext\(3),
  I0 => \fifo_inst/Equal.wbin\(3),
  I1 => \fifo_inst_Equal.wgraynext_2\,
  I2 => \fifo_inst/Equal.wbin\(4));
\fifo_inst/Equal.wgraynext_4_s0\: LUT4
generic map (
  INIT => X"07F8"
)
port map (
  F => \fifo_inst/Equal.wgraynext\(4),
  I0 => \fifo_inst/Equal.wbin\(3),
  I1 => \fifo_inst_Equal.wgraynext_2\,
  I2 => \fifo_inst/Equal.wbin\(4),
  I3 => \fifo_inst/wptr\(5));
\fifo_inst/wfull_val_s0\: LUT3
generic map (
  INIT => X"80"
)
port map (
  F => fifo_inst_wfull_val,
  I0 => fifo_inst_wfull_val_4,
  I1 => fifo_inst_wfull_val_5,
  I2 => fifo_inst_wfull_val_6);
\fifo_inst/arempty_val_s0\: LUT4
generic map (
  INIT => X"FF10"
)
port map (
  F => fifo_inst_arempty_val,
  I0 => fifo_inst_arempty_val_4,
  I1 => fifo_inst_arempty_val_5,
  I2 => fifo_inst_arempty_val_6,
  I3 => fifo_inst_arempty_val_15);
\fifo_inst/wfull_val1_s9\: LUT3
generic map (
  INIT => X"AC"
)
port map (
  F => fifo_inst_wfull_val1_13,
  I0 => fifo_inst_wfull_val1_3,
  I1 => fifo_inst_wfull_val1,
  I2 => fifo_inst_wfull_val1_16);
\fifo_inst/wfull_val1_s10\: LUT3
generic map (
  INIT => X"0E"
)
port map (
  F => fifo_inst_wfull_val1_16,
  I0 => fifo_inst_wfull_val,
  I1 => fifo_inst_wfull_val1_16,
  I2 => WrReset);
\fifo_inst/Full_d_s\: LUT3
generic map (
  INIT => X"AC"
)
port map (
  F => Full,
  I0 => fifo_inst_Full_2,
  I1 => fifo_inst_Full,
  I2 => fifo_inst_Full_11);
\fifo_inst/Full_s8\: LUT3
generic map (
  INIT => X"0E"
)
port map (
  F => fifo_inst_Full_11,
  I0 => fifo_inst_wfull_val,
  I1 => fifo_inst_Full_11,
  I2 => WrReset);
\fifo_inst/rbin_num_next_0_s5\: LUT3
generic map (
  INIT => X"B4"
)
port map (
  F => \fifo_inst/rbin_num_next\(0),
  I0 => NN,
  I1 => RdEn,
  I2 => \fifo_inst/rbin_num\(0));
\fifo_inst/rbin_num_next_1_s5\: LUT3
generic map (
  INIT => X"B4"
)
port map (
  F => \fifo_inst/rbin_num_next\(1),
  I0 => \fifo_inst/rbin_num_next\(0),
  I1 => \fifo_inst/rbin_num\(0),
  I2 => \fifo_inst/rbin_num\(1));
\fifo_inst/rbin_num_next_2_s5\: LUT2
generic map (
  INIT => X"6"
)
port map (
  F => \fifo_inst/rbin_num_next\(2),
  I0 => \fifo_inst/rbin_num\(2),
  I1 => \fifo_inst_Equal.rgraynext_3\);
\fifo_inst/rbin_num_next_3_s5\: LUT3
generic map (
  INIT => X"78"
)
port map (
  F => \fifo_inst/rbin_num_next\(3),
  I0 => \fifo_inst/rbin_num\(2),
  I1 => \fifo_inst_Equal.rgraynext_3\,
  I2 => \fifo_inst/rbin_num\(3));
\fifo_inst/rbin_num_next_5_s2\: LUT4
generic map (
  INIT => X"7F80"
)
port map (
  F => \fifo_inst/rbin_num_next\(5),
  I0 => \fifo_inst/rbin_num\(4),
  I1 => \fifo_inst_Equal.rgraynext_3\,
  I2 => \fifo_inst_Equal.rgraynext_4\,
  I3 => \fifo_inst/rptr\(5));
\fifo_inst/Equal.wbinnext_0_s3\: LUT2
generic map (
  INIT => X"6"
)
port map (
  F => \fifo_inst_Equal.wbinnext_0\,
  I0 => \fifo_inst/Equal.wbin\(0),
  I1 => fifo_inst_n16);
\fifo_inst/Equal.wbinnext_1_s3\: LUT3
generic map (
  INIT => X"78"
)
port map (
  F => \fifo_inst/Equal.wbinnext\(1),
  I0 => \fifo_inst/Equal.wbin\(0),
  I1 => fifo_inst_n16,
  I2 => \fifo_inst/Equal.wbin\(1));
\fifo_inst/Equal.wbinnext_3_s3\: LUT2
generic map (
  INIT => X"6"
)
port map (
  F => \fifo_inst/Equal.wbinnext\(3),
  I0 => \fifo_inst/Equal.wbin\(3),
  I1 => \fifo_inst_Equal.wgraynext_2\);
\fifo_inst/Equal.wbinnext_4_s3\: LUT3
generic map (
  INIT => X"78"
)
port map (
  F => \fifo_inst/Equal.wbinnext\(4),
  I0 => \fifo_inst/Equal.wbin\(3),
  I1 => \fifo_inst_Equal.wgraynext_2\,
  I2 => \fifo_inst/Equal.wbin\(4));
\fifo_inst/Equal.wbinnext_5_s2\: LUT4
generic map (
  INIT => X"7F80"
)
port map (
  F => \fifo_inst/Equal.wbinnext\(5),
  I0 => \fifo_inst/Equal.wbin\(3),
  I1 => \fifo_inst/Equal.wbin\(4),
  I2 => \fifo_inst_Equal.wgraynext_2\,
  I3 => \fifo_inst/wptr\(5));
\fifo_inst/Equal.rgraynext_3_s1\: LUT4
generic map (
  INIT => X"4000"
)
port map (
  F => \fifo_inst_Equal.rgraynext_3\,
  I0 => NN,
  I1 => RdEn,
  I2 => \fifo_inst/rbin_num\(0),
  I3 => \fifo_inst/rbin_num\(1));
\fifo_inst/Equal.rgraynext_4_s1\: LUT2
generic map (
  INIT => X"8"
)
port map (
  F => \fifo_inst_Equal.rgraynext_4\,
  I0 => \fifo_inst/rbin_num\(2),
  I1 => \fifo_inst/rbin_num\(3));
\fifo_inst/wfull_val_s1\: LUT4
generic map (
  INIT => X"0990"
)
port map (
  F => fifo_inst_wfull_val_4,
  I0 => \fifo_inst/wptr\(0),
  I1 => \fifo_inst/rptr\(0),
  I2 => \fifo_inst/wptr\(4),
  I3 => \fifo_inst/rptr\(4));
\fifo_inst/wfull_val_s2\: LUT4
generic map (
  INIT => X"4182"
)
port map (
  F => fifo_inst_wfull_val_5,
  I0 => \fifo_inst/rptr\(5),
  I1 => \fifo_inst/wptr\(3),
  I2 => \fifo_inst/rptr\(3),
  I3 => \fifo_inst/wptr\(5));
\fifo_inst/wfull_val_s3\: LUT4
generic map (
  INIT => X"9009"
)
port map (
  F => fifo_inst_wfull_val_6,
  I0 => \fifo_inst/wptr\(1),
  I1 => \fifo_inst/rptr\(1),
  I2 => \fifo_inst/wptr\(2),
  I3 => \fifo_inst/rptr\(2));
\fifo_inst/arempty_val_s1\: LUT4
generic map (
  INIT => X"BFD6"
)
port map (
  F => fifo_inst_arempty_val_4,
  I0 => \fifo_inst/rcnt_sub_d\(2),
  I1 => AlmostEmptyTh(2),
  I2 => fifo_inst_arempty_val_8,
  I3 => fifo_inst_arempty_val_9);
\fifo_inst/arempty_val_s2\: LUT3
generic map (
  INIT => X"78"
)
port map (
  F => fifo_inst_arempty_val_5,
  I0 => AlmostEmptyTh(4),
  I1 => fifo_inst_arempty_val_10,
  I2 => \fifo_inst/rcnt_sub_d\(5));
\fifo_inst/arempty_val_s3\: LUT4
generic map (
  INIT => X"4100"
)
port map (
  F => fifo_inst_arempty_val_6,
  I0 => fifo_inst_arempty_val_11,
  I1 => fifo_inst_arempty_val_10,
  I2 => fifo_inst_arempty_val_12,
  I3 => RdEn);
\fifo_inst/arempty_val_s5\: LUT2
generic map (
  INIT => X"8"
)
port map (
  F => fifo_inst_arempty_val_8,
  I0 => AlmostEmptyTh(1),
  I1 => AlmostEmptyTh(0));
\fifo_inst/arempty_val_s6\: LUT2
generic map (
  INIT => X"6"
)
port map (
  F => fifo_inst_arempty_val_9,
  I0 => \fifo_inst/rcnt_sub_d\(3),
  I1 => AlmostEmptyTh(3));
\fifo_inst/arempty_val_s7\: LUT4
generic map (
  INIT => X"8000"
)
port map (
  F => fifo_inst_arempty_val_10,
  I0 => AlmostEmptyTh(1),
  I1 => AlmostEmptyTh(0),
  I2 => AlmostEmptyTh(2),
  I3 => AlmostEmptyTh(3));
\fifo_inst/arempty_val_s8\: LUT4
generic map (
  INIT => X"F69F"
)
port map (
  F => fifo_inst_arempty_val_11,
  I0 => \fifo_inst/rcnt_sub_d\(1),
  I1 => AlmostEmptyTh(1),
  I2 => AlmostEmptyTh(0),
  I3 => \fifo_inst/rcnt_sub_d\(0));
\fifo_inst/arempty_val_s9\: LUT2
generic map (
  INIT => X"6"
)
port map (
  F => fifo_inst_arempty_val_12,
  I0 => \fifo_inst/rcnt_sub_d\(4),
  I1 => AlmostEmptyTh(4));
\fifo_inst/Equal.wgraynext_0_s1\: LUT3
generic map (
  INIT => X"96"
)
port map (
  F => \fifo_inst/Equal.wgraynext\(0),
  I0 => \fifo_inst/Equal.wbin\(0),
  I1 => fifo_inst_n16,
  I2 => \fifo_inst/Equal.wbinnext\(1));
\fifo_inst/Equal.wgraynext_2_s2\: LUT4
generic map (
  INIT => X"8000"
)
port map (
  F => \fifo_inst_Equal.wgraynext_2\,
  I0 => \fifo_inst/Equal.wbin\(2),
  I1 => fifo_inst_n16,
  I2 => \fifo_inst/Equal.wbin\(0),
  I3 => \fifo_inst/Equal.wbin\(1));
\fifo_inst/Equal.wbinnext_2_s5\: LUT4
generic map (
  INIT => X"7F80"
)
port map (
  F => \fifo_inst/Equal.wbinnext\(2),
  I0 => fifo_inst_n16,
  I1 => \fifo_inst/Equal.wbin\(0),
  I2 => \fifo_inst/Equal.wbin\(1),
  I3 => \fifo_inst/Equal.wbin\(2));
\fifo_inst/rbin_num_next_4_s6\: LUT4
generic map (
  INIT => X"7F80"
)
port map (
  F => \fifo_inst/rbin_num_next\(4),
  I0 => \fifo_inst_Equal.rgraynext_3\,
  I1 => \fifo_inst/rbin_num\(2),
  I2 => \fifo_inst/rbin_num\(3),
  I3 => \fifo_inst/rbin_num\(4));
\fifo_inst/Equal.wgraynext_1_s1\: LUT4
generic map (
  INIT => X"8778"
)
port map (
  F => \fifo_inst/Equal.wgraynext\(1),
  I0 => \fifo_inst/Equal.wbin\(0),
  I1 => fifo_inst_n16,
  I2 => \fifo_inst/Equal.wbin\(1),
  I3 => \fifo_inst/Equal.wbinnext\(2));
\fifo_inst/Equal.wcount_r_2_s1\: LUT4
generic map (
  INIT => X"6996"
)
port map (
  F => \fifo_inst/Equal.wcount_r\(2),
  I0 => \fifo_inst/Equal.rq2_wptr\(3),
  I1 => \fifo_inst/Equal.rq2_wptr\(2),
  I2 => \fifo_inst/Equal.rq2_wptr\(5),
  I3 => \fifo_inst/Equal.rq2_wptr\(4));
\fifo_inst/Equal.wcount_r_3_s1\: LUT3
generic map (
  INIT => X"96"
)
port map (
  F => \fifo_inst/Equal.wcount_r\(3),
  I0 => \fifo_inst/Equal.rq2_wptr\(3),
  I1 => \fifo_inst/Equal.rq2_wptr\(5),
  I2 => \fifo_inst/Equal.rq2_wptr\(4));
\fifo_inst/Equal.rgraynext_2_s1\: LUT4
generic map (
  INIT => X"956A"
)
port map (
  F => \fifo_inst/Equal.rgraynext\(2),
  I0 => \fifo_inst/rbin_num_next\(2),
  I1 => \fifo_inst/rbin_num\(2),
  I2 => \fifo_inst_Equal.rgraynext_3\,
  I3 => \fifo_inst/rbin_num\(3));
\fifo_inst/Equal.rgraynext_0_s1\: LUT4
generic map (
  INIT => X"4BB4"
)
port map (
  F => \fifo_inst/Equal.rgraynext\(0),
  I0 => NN,
  I1 => RdEn,
  I2 => \fifo_inst/rbin_num\(0),
  I3 => \fifo_inst/rbin_num_next\(1));
\fifo_inst/Equal.rgraynext_1_s1\: LUT4
generic map (
  INIT => X"4BB4"
)
port map (
  F => \fifo_inst/Equal.rgraynext\(1),
  I0 => \fifo_inst/rbin_num_next\(0),
  I1 => \fifo_inst/rbin_num\(0),
  I2 => \fifo_inst/rbin_num\(1),
  I3 => \fifo_inst/rbin_num_next\(2));
\fifo_inst/n455_s2\: LUT4
generic map (
  INIT => X"4000"
)
port map (
  F => fifo_inst_n455,
  I0 => WrReset,
  I1 => fifo_inst_wfull_val_4,
  I2 => fifo_inst_wfull_val_5,
  I3 => fifo_inst_wfull_val_6);
\fifo_inst/arempty_val_s10\: LUT4
generic map (
  INIT => X"00B2"
)
port map (
  F => fifo_inst_arempty_val_15,
  I0 => AlmostEmptyTh(4),
  I1 => \fifo_inst/rcnt_sub_d\(4),
  I2 => fifo_inst_n328_22,
  I3 => \fifo_inst/rcnt_sub_d\(5));
\fifo_inst/rempty_val_s2\: LUT3
generic map (
  INIT => X"09"
)
port map (
  F => fifo_inst_rempty_val,
  I0 => \fifo_inst/rbin_num_next\(5),
  I1 => \fifo_inst/Equal.rq2_wptr\(5),
  I2 => fifo_inst_n160_3);
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
