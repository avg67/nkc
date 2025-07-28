--------------------------------------------------------------------------------
-- Project     : Single Chip NDR Computer
-- Module      : NKC - Toplevel for Gowin FPGA
-- File        : nkc_gowin_top.vhd
-- Description :
--------------------------------------------------------------------------------
-- Author       : Andreas Voggeneder
-- Organisation : FH-Hagenberg
-- Department   : Hardware/Software Systems Engineering
-- Language     : VHDL'87
--------------------------------------------------------------------------------
-- Copyright (c) 2024 by Andreas Voggeneder
--------------------------------------------------------------------------------
library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_misc.all;
use work.DffGlobal.all;
use work.gdp_global.all;

entity nkc_gowin_top is
  generic(sim_g      : boolean := false;
          is_pcb     : boolean := true); -- set to true for "official" PCB, false for prototype
  port(reset_i       : in  std_ulogic:='0';
       refclk_i      : in  std_ulogic;
       --------------------------
       -- NKC Bus
       --------------------------
       nkc_nreset_o  : out std_ulogic;
       nkc_DB        : inout std_logic_vector(7 downto 0);
       nkc_ADDR_o    : out std_ulogic_vector(7 downto 0);
       nkc_nRD_o     : out std_ulogic;
       nkc_nWR_o     : out std_ulogic;
       nkc_nIORQ_o   : out std_ulogic;
       driver_nEN_o  : out std_ulogic;
       driver_DIR_o  : out std_ulogic;
       driver_DIR1_o : out std_ulogic;
       nIRQ_i        : in  std_logic :='1';
--	   
--       --------------------------
--       -- UART Receiver
--       --------------------------
       RxD_i    : in  std_ulogic;
       TxD_o    : out std_ulogic;
       --txd_debug_o : out std_ulogic;
       --rxd_debug_o : out std_ulogic;
--       RTS_o    : out std_ulogic;
--       CTS_i    : in  std_ulogic;
       --------------------------
       -- PS/2 Keyboard signals
       --------------------------
       -- PS/2 clock line. Bidirectional (resolved!) for Inhibit bus state on
       -- PS/2 bus. In all other cases an input would be sufficient.
       Ps2Clk_io    : inout std_logic;
--       -- PS/2 data line. Bidirectional for reading and writing data.
       Ps2Dat_io    : inout std_logic;
       --------------------------
       -- PS/2 Mouse signals
       --------------------------
       -- PS/2 clock line. Bidirectional (resolved!) for Inhibit bus state on
       -- PS/2 bus. In all other cases an input would be sufficient.
       Ps2MouseClk_io    : inout std_logic;
       -- PS/2 data line. Bidirectional for reading and writing data.
       Ps2MouseDat_io    : inout std_logic;
       --------------------------
       -- Audio DAC-PWM out
       -- This DAC requires an external RC low-pass filter:
       --
       --   pwm_out 0---XXXXX---+---0 analog audio
       --                3k3    |
       --                      === 4n7
       --                       |
       --                      GND
       --------------------------
       PWM_OUT_o   : out std_ulogic;
--       PWM_OUT_L_o   : out std_ulogic;
       --------------------------
       -- Video out
       --------------------------
       --Pixel_o      : out std_ulogic;
       --Hsync_o      : out std_ulogic;
       --Vsync_o      : out std_ulogic;
       tmds_clk_n   : out std_logic;
       tmds_clk_p   : out std_logic;
       tmds_d_n     : out std_logic_vector(2 downto 0);
       tmds_d_p     : out std_logic_vector(2 downto 0);
--       --------------------------
--       -- SPI-Signals
--       --------------------------
       SD_SCK_o  : out std_ulogic;
       SD_nCS_o  : out std_ulogic_vector(1 downto 0);
       SD_MOSI_o : out std_ulogic;
       SD_MISO_i : in  std_ulogic;
       --
       SD1_SCK_o  : out std_ulogic;
       SD1_MOSI_o : out std_ulogic;
       SD1_MISO_i : in  std_ulogic := '1';
--       --------------------------
--       -- GPIO-Signals
--       --------------------------
--       gpio_io       : inout std_logic_vector(7 downto 0);
--       --------------------------
--       -- Video-Memory data bus
--       --------------------------
       -- SDRAM "Magic" port names that the gowin compiler connects to the on-chip SDRAM
       O_sdram_clk    : out std_logic;
       O_sdram_cke    : out std_logic;
       O_sdram_cs_n   : out std_logic;  -- chip select
       O_sdram_cas_n  : out std_logic;  -- columns address select
       O_sdram_ras_n  : out std_logic;  -- row address select
       O_sdram_wen_n  : out std_logic;  -- write enable
       IO_sdram_dq    : inout std_logic_vector(31 downto 0);  -- up to 32 bit bidirectional data bus
       O_sdram_addr   : out std_logic_vector(10 downto 0);  -- up to 11 bit multiplexed address bus
       O_sdram_ba     : out std_logic_vector(1 downto 0);  -- four banks
       O_sdram_dqm    : out std_logic_vector(3 downto 0)  -- 32/8
       --------------------------
       -- Debug Signals - GDP
       --------------------------
       );
end nkc_gowin_top;

architecture rtl of nkc_gowin_top is

  constant use_ser_key_c   : boolean := false;
  constant use_ps2_key_c   : boolean := true;
  constant use_ps2_mouse_c : boolean := false;
  constant use_ser1_c      : boolean := true;
  constant use_sound_c     : boolean := true;
  constant use_spi_c       : boolean := false;
  constant use_sdio_c      : boolean := true;
  constant use_timer_c     : boolean := true;
  constant use_vdip_c      : boolean := false;
  constant use_gpio_c      : boolean := false;
  --constant dipswitches_c   : std_logic_vector(7 downto 0) := X"49";
  constant dipswitches_c : std_logic_vector(7 downto 0) := X"01";
  
  constant GDP_BASE_ADDR_c    : std_ulogic_vector(7 downto 0) := X"70"; -- r/w
  constant SFR_BASE_ADDR_c    : std_ulogic_vector(7 downto 0) := X"60"; -- w  
  constant COL_BASE_c         : std_ulogic_vector(7 downto 0) := X"A0"; -- r/w  
  constant CLUT_BASE_c        : std_ulogic_vector(7 downto 0) := X"A4"; -- r/w 
  constant KEY_BASE_ADDR_c    : std_ulogic_vector(7 downto 0) := X"68"; -- r  
  constant DIP_BASE_ADDR_c    : std_ulogic_vector(7 downto 0) := X"69"; -- r  
  constant MOUSE_BASE_ADDR_c  : std_ulogic_vector(7 downto 0) := X"88"; -- r/w  
  constant SER_BASE_ADDR_c    : std_ulogic_vector(7 downto 0) := X"F0"; -- r/w  
  constant SOUND_BASE_ADDR_c  : std_ulogic_vector(7 downto 0) := X"50"; -- r/w  
  constant SPI_BASE_ADDR_c    : std_ulogic_vector(7 downto 0) := X"00"; -- r/w 
  constant SDIO_BASE_ADDR_c   : std_ulogic_vector(7 downto 0) := X"20"; -- r/w 
  constant T1_BASE_ADDR_c     : std_ulogic_vector(7 downto 0) := X"F4"; -- r/w 
  constant VDIP_BASE_ADDR_c   : std_ulogic_vector(7 downto 0) := X"20"; -- r/w 
  constant GPIO_BASE_ADDR_c   : std_ulogic_vector(7 downto 0) := X"04"; -- r/w 
--  constant GDP_BASE_ADDR1_c  : std_ulogic_vector(7 downto 0) := X"50"; -- r/w
--  constant SFR_BASE_ADDR1_c  : std_ulogic_vector(7 downto 0) := X"40"; -- w
--  constant KEY_BASE_ADDR1_c  : std_ulogic_vector(7 downto 0) := X"48"; -- r
--  constant DIP_BASE_ADDR1_c  : std_ulogic_vector(7 downto 0) := X"49"; -- r
  
  signal clk_40            : std_ulogic;
   signal pixel_clk,clk_80 : std_ulogic;
  signal reset_n           : std_ulogic:='0';
  signal pll_80m_reset     : std_ulogic;
  signal GDP_DataOut       : std_ulogic_vector(7 downto 0);
  signal gdp_Rd,gdp_Wr     : std_ulogic;
  signal gdp_cs            : std_ulogic;
  signal gdp_en,sfr_en     : std_ulogic;
  signal col_en,clut_en    : std_ulogic;

  signal nWr,nRd           : std_ulogic;
  signal IORQ              : std_ulogic;
  signal MREQ              : std_ulogic;
  signal glob_gdp_en       : std_ulogic;
  signal Addr              : std_ulogic_vector(7 downto 0);
  signal data_in           : std_ulogic_vector(7 downto 0);
  signal output_en,fpga_en : std_ulogic;
  signal key_cs,dip_cs     : std_ulogic;
  signal mouse_cs          : std_ulogic;
  
  signal BusyRX              : std_ulogic;
  signal DoutParRX,key_data  : std_ulogic_vector(7 downto 0);
  signal OldDataValidRX    : std_ulogic;
  signal DataValidRX       : std_ulogic;
  
  signal gdp_base,sfr_base,key_base,dip_base : std_ulogic_vector(7 downto 0);        
  signal dipsw             : std_logic_vector(7 downto 0);
  signal mouse_data        : std_ulogic_vector(7 downto 0);
  
  signal ser_cs            : std_ulogic;
  signal ser_data          : std_ulogic_vector(7 downto 0);
  signal ser_int           : std_ulogic;
  
  signal snd_cs            : std_ulogic;
  signal snd_data          : std_ulogic_vector(7 downto 0); 
  signal snd_bdir,snd_bc1  : std_ulogic;
  signal wav_en            : std_ulogic;
  signal wav_cnt           : natural range 0 to 19; -- 2 MHz
  
  signal spi_cs            : std_ulogic;
  signal spi_data          : std_ulogic_vector(7 downto 0);
  signal vdip_cs           : std_ulogic;
  signal vdip_data         : std_ulogic_vector(7 downto 0);
  signal gpio_cs           : std_ulogic;
  signal gpio_data         : std_ulogic_vector(7 downto 0);
  
  signal t1_cs,t1_irq      : std_ulogic;
  signal t1_data           : std_ulogic_vector(7 downto 0);
  SIGNAL SD_SCK_s          : std_ulogic; 
  SIGNAL SD_nCS_s          : std_ulogic_vector(2 downto 0);
  SIGNAL SD_MOSI_s         : std_ulogic;
  SIGNAL SD_MISO_s         : std_ulogic;
  
  signal PWM_OUT_s         : std_ulogic;
  signal SND_s             : std_ulogic_vector(9 downto 0);
  signal TxD_s             : std_ulogic;
 
  signal pll_lock          : std_ulogic;
  signal pll_80m_lock      : std_ulogic;
--  signal vpll_lock         : std_ulogic;
  signal red               : std_ulogic_vector(2 downto 0);
  signal green             : std_ulogic_vector(2 downto 0);
  signal blue              : std_ulogic_vector(2 downto 0);
  signal vreset            : std_ulogic;
  signal sdram_addr        : std_logic_vector(12 downto 0);
  signal vvmode            : std_logic_vector(1 downto 0);
  signal vwide             : std_logic;
  signal audio0            : std_logic_vector(15 downto 0);
  signal audio1            : std_logic_vector(15 downto 0);
  signal nkc_DB_in         : std_logic_vector(7 downto 0);
  --
  signal cpu_req           : std_ulogic;
  signal cpu_wr            : std_ulogic;
  signal cpu_addr          : std_ulogic_vector(21 downto 0);
  signal cpu_datai         : std_ulogic_vector(15 downto 0);
  signal cpu_data_bv       : std_ulogic_vector(1 downto 0);
  signal cpu_datao         : std_ulogic_vector(15 downto 0);
  signal cpu_busy          : std_ulogic;
  signal cpu_ack           : std_ulogic;
  signal nIRQ              : std_ulogic;
begin

  dipsw <= dipswitches_c;-- when addr_sel_i = '1' else
--           dipswitches1_c;

  gdp_base <= GDP_BASE_ADDR_c; -- when addr_sel_i = '0' else
--              GDP_BASE_ADDR1_c;
  sfr_base <= SFR_BASE_ADDR_c; -- when addr_sel_i = '0' else
--              SFR_BASE_ADDR1_c;
--  key_base <= KEY_BASE_ADDR_c when addr_sel_i = '1' else
--              KEY_BASE_ADDR1_c;
--  dip_base <= DIP_BASE_ADDR_c when addr_sel_i = '1' else
--              DIP_BASE_ADDR1_c;

  key_base <= KEY_BASE_ADDR_c;
  dip_base <= DIP_BASE_ADDR_c;

--  sync_reset: if not sim_g generate
    reset_sync: process(pixel_clk)
      variable tmp_v : std_ulogic_vector(1 downto 0):= "00";
    begin
      if rising_edge(pixel_clk) then
        reset_n  <= tmp_v(1);
        tmp_v(1) := tmp_v(0);
        tmp_v(0) := (not reset_i) and pll_80m_lock;
      end if;
    end process reset_sync;
  --end generate;
  
--  nosync_reset: if sim_g generate
--    reset_n  <= not reset_i;
--  end generate;

   pll_80 : entity work.pll_80m
      port map (
         reset    => pll_80m_reset,
         clkin    => clk_40,
         clkout   => clk_80,
         lock     => pll_80m_lock,
         clkoutd  => pixel_clk
      );
   pll_80m_reset <= not pll_lock;


  video2hdmi: entity work.video2hdmi
    port map (
      clk            => refclk_i,
      clk_40         => clk_40, --pixel_clk,
      pll_lock       => pll_lock, --vpll_lock,
      vreset         => vreset,
      vvmode         => vvmode,
      vwide          => vwide,
      r              => red,
      g              => green,
      b              => blue,
      --audio          => audio,
      audio0         => audio0,
      audio1         => audio1,
      --audio(1)       => audio1,
      tmds_clk_n     => tmds_clk_n,
      tmds_clk_p     => tmds_clk_p,
      tmds_d_n       => tmds_d_n,
      tmds_d_p       => tmds_d_p
    );

   vvmode <= "00";
   vwide  <= '0';
   audio0 <= std_logic_vector(SND_s) & "000000";
   audio1 <= std_logic_vector(SND_s) & "000000";

--   rpll2_reset <= not vpll_lock;
--
--  Gowin_rPLL_40_inst : entity work.Gowin_rPLL_40
--    port map (
--        reset   => rpll2_reset,
--        clkin   => pixel_clk,
--        lock    => pll_lock,
--        clkout  => sdctrl_clk,   -- clock for SDRAM-controller
--        clkoutp => sdram_clk     -- clock for SDRAM 
--    );
  
--  GDP_EN_SYNC : entity work.InputSync
--     generic map (
--       ResetValue_g => '1'
--     )
--     port map (
--         Input => glob_gdp_en_i,
--         clk   => pixel_clk,
--         clr_n => reset_n,
--         q     => glob_gdp_en
--     );

   glob_gdp_en <= '1';
   
--  bi_inst:entity work.gdp_bi
--    port map(
--      reset_n_i   => reset_n,
--      clk_i       => pixel_clk,
--      fpga_en_i   => fpga_en,
--      addr_o      => Addr,
--      data_in_o   => data_in,
--      IORQ_o      => IORQ,
--      Rd_o        => gdp_Rd,
--      Wr_o        => gdp_Wr,
--      nRd_sync_o  => nRd,
--      nWr_sync_o  => nWr,
--      nkc_nIORQ_i => nkc_nIORQ_i,
--      nkc_nRD_i   => nkc_nRD_s,
--      nkc_nWR_i   => nkc_nWR_s,
--      nkc_ADDR_i  => nkc_ADDR_i,
--      nkc_DB      => nkc_DB(7 downto 0)
--    );

--	nkc_nRD_s <= '0' when nkc_nRD_i='0' else --and UDS_SIZ0_i ='0' else
--	             '1';
--   nkc_nWR_s <= '0' when nkc_nWR_i='0' else --and UDS_SIZ0_i ='0' else
--                '1';

  fpga_en      <= gdp_cs or key_cs or dip_cs or mouse_cs or ser_cs or 
                  snd_cs or spi_cs or t1_cs or vdip_cs or gpio_cs;
--  driver_nEN_o <= not reset_n; --not(output_en and (not nkc_nWR_i or not nkc_nRD_i)); 
--
--  driver_DIR_o <= '0' when (fpga_en and not nkc_nRD_i)='1' else
--                  '1';
  
  process(pixel_clk,reset_n)   
  begin
    if reset_n = '0' then
      output_en <= '0';
    elsif rising_edge(pixel_clk) then
      output_en <= fpga_en;
    end if;
  end process;
  
                   
  nkc_DB_in <=     std_logic_vector(GDP_DataOut) when (output_en and gdp_cs   and not nRD)='1' else
                   std_logic_vector(key_data)    when (output_en and key_cs   and not nRD)='1' else
	                dipsw                         when (output_en and dip_cs   and not nRD)='1' else
	                std_logic_vector(mouse_data)  when (output_en and mouse_cs and not nRD)='1' else
	                std_logic_vector(ser_data)    when (output_en and ser_cs   and not nRD)='1' else
	                std_logic_vector(snd_data)    when (output_en and snd_cs   and not nRD)='1' else
	                std_logic_vector(spi_data)    when (output_en and spi_cs   and not nRD)='1' else
	                std_logic_vector(t1_data)     when (output_en and t1_cs    and not nRD)='1' else
	                std_logic_vector(vdip_data)   when (output_en and vdip_cs  and not nRD)='1' else
	                std_logic_vector(gpio_data)   when (output_en and gpio_cs  and not nRD)='1' else
                  (others => '1'); -- after 1 ns;
  
  GDP: entity work.gdp_top
    generic map (
      cpu_vram_early_ack_g => false
    )
    port map (
      reset_n_i   => reset_n,
      clk_i       => pixel_clk,
      clk_en_i    => '1',
      sdctrl_clk_i=> clk_80, --pixel_clk, --sdctrl_clk,
      --sdram_clk_i => pixel_clk, --sdram_clk,
      Adr_i       => Addr(3 downto 0),
--      CS_i        => gdp_cs,
      gdp_en_i    => gdp_en,
      sfr_en_i    => sfr_en,
      col_en_i    => col_en,
      clut_en_i   => clut_en,
      DataIn_i    => data_in,
      Rd_i        => gdp_Rd,
      Wr_i        => gdp_Wr,
      DataOut_o   => GDP_DataOut,
      --
      cpu_req_i     => cpu_req,
      cpu_wr_i      => cpu_wr,
      cpu_addr_i    => cpu_addr,
      cpu_data_i    => cpu_datai,
      cpu_data_bv_i => cpu_data_bv,
      cpu_data_o    => cpu_datao,
      cpu_busy_o    => cpu_busy,
      cpu_ack_o     => cpu_ack,
      --
--      pixel_o     => VGA_pixel,
      pixel_red_o   => red,
      pixel_green_o => green,
      pixel_blue_o  => blue,
      --Hsync_o     => Hsync_o,
      --Vsync_o     => Vsync_o,
      vreset_o    => vreset,

--      kernel_req_o  => kernel_req,
--      kernel_wr_o   => kernel_wr,
--      kernel_addr_o => kernel_addr,
--      kernel_data_i => kernel_data_is,
--      kernel_data_o => kernel_data_os,
--      kernel_busy_i => kernel_busy,
--      --kernel_ack_i  => kernel_ack_i,
--      --
--      rd_req_o      => rd_req,
--      rd_addr_o     => rd_addr,
--      rd_data_i     => rd_data_is,
--      rd_busy_i     => rd_busy,
--      rd_ack_i      => rd_ack, 
      sdram_clk       => O_sdram_clk,
      sdram_cke       => O_sdram_cke,
      sdram_cs_n      => O_sdram_cs_n,
      sdram_cas_n     => O_sdram_cas_n,
      sdram_ras_n     => O_sdram_ras_n,
      sdram_wen_n     => O_sdram_wen_n,
      sdram_dq        => IO_sdram_dq,
      sdram_addr      => sdram_addr,
      sdram_ba        => O_sdram_ba,
      sdram_dqm       => O_sdram_dqm,
      monitoring_o    => open --debug_o
    );
    
  --Pixel_o <= or_reduce(red&green&blue);
  O_sdram_addr <= sdram_addr(O_sdram_addr'range);

  gdp_cs <= (IORQ and glob_gdp_en) when  Addr(7 downto 4) = gdp_base(7 downto 4)  or  -- GDP
                       (Addr(7 downto 1) = sfr_base(7 downto 1)) or
                       (Addr(7 downto 1) = COL_BASE_c(7 downto 1) and color_support_c) or -- SFRs
                       (Addr(7 downto 2) = CLUT_BASE_c(7 downto 2) and color_support_c) else
            '0';
  
  gdp_en <= gdp_cs when Addr(7 downto 4) = gdp_base(7 downto 4) else
            '0';
  sfr_en <= gdp_cs when Addr(7 downto 4) = sfr_base(7 downto 4) else
            '0';
  col_en <= gdp_cs when Addr(7 downto 1) = COL_BASE_c(7 downto 1) and color_support_c else
            '0';
  clut_en<= gdp_cs when Addr(7 downto 2) = CLUT_BASE_c(7 downto 2) and color_support_c else
            '0';
  key_cs <= IORQ when Addr = key_base and nRD='0' and (use_ps2_key_c or use_ser_key_c) else
            '0';
  dip_cs <= IORQ when Addr = dip_base and nRD='0' and (use_ps2_key_c or use_ser_key_c) else
            '0';

--  impl_key1: if use_ser_key_c generate
--    Rx: entity work.Receiver
--      port map (
--        clk        => pixel_clk,
--        clr_n      => reset_n,
--        RxD        => RxD_i,
--        Busy       => BusyRX,
--        DoutPar    => DoutParRX,
--        DataValid  => DataValidRX,
--        ErrorFlags => open);
--    
--    process(pixel_clk,reset_n)
--    begin
--      if reset_n = '0' then
--        BusyRX         <= '0';
--        OldDataValidRX <= '0';
--  --      access_v       := '0';
--      elsif rising_edge(pixel_clk) then
--        OldDataValidRX <= DataValidRX;
--        if (not OldDataValidRX and DataValidRX)= '1' then
--          BusyRX <= '1';
--        end if;
--        if (dip_cs and gdp_Rd)='1' then
--          BusyRX <= '0';
--        end if;  
--      end if;
--    end process; 
--    key_data  <= not BusyRX & DoutParRX(6 downto 0);
--  end generate;

  impl_key1: if use_ser_key_c generate
    Ser_key: entity work.Ser_key
      port map (
        clk_i      => pixel_clk,
        reset_n_i  => reset_n,
        RxD_i      => RxD_i,
        KeyCS_i    => key_cs,
        DipCS_i    => dip_cs,
        Rd_i       => gdp_Rd,
        DataOut_o  => key_data);
  end generate;
  
  no_key_at_all: if not use_ser_key_c and not use_ps2_key_c generate
    DoutParRX      <= (others =>'0');
    BusyRX         <= '1';
    OldDataValidRX <= '0';
    DataValidRX    <= '0';
    key_data       <= not BusyRX & DoutParRX(6 downto 0);
  end generate;
  
  impl_key2: if  not use_ser_key_c and use_ps2_key_c generate
    kbd: entity work.PS2Keyboard
      port map (
        reset_n_i => reset_n,
        clk_i     => pixel_clk,
        Ps2Clk_io => Ps2Clk_io,
        Ps2Dat_io => Ps2Dat_io,
        KeyCS_i   => key_cs,
        DipCS_i   => dip_cs,
        Rd_i      => gdp_Rd,
        DataOut_o => key_data,
        monitoring_o=> open --debug_o
     );
   end generate;
  no_key1: if not use_ps2_key_c generate
    Ps2Clk_io <= 'Z';
    Ps2Dat_io <= 'Z';
  end generate;

  impl_mouse: if use_ps2_mouse_c generate 
    mouse_cs <= IORQ when Addr(7 downto 3)=MOUSE_BASE_ADDR_c(7 downto 3) else
                '0';
    mouse : entity work.PS2Mouse
      port map (
        reset_n_i    => reset_n,
        clk_i        => pixel_clk,
        Ps2Clk_io    => Ps2MouseClk_io,
        Ps2Dat_io    => Ps2MouseDat_io,
        Adr_i        => Addr(2 downto 0),
        en_i         => mouse_cs,
        DataIn_i     => data_in,
        Rd_i         => gdp_Rd,
        Wr_i         => gdp_Wr,
        DataOut_o    => mouse_data,
        monitoring_o => open  --debug_o
      );
  end generate;
  
  no_mouse: if not use_ps2_mouse_c generate
    mouse_data     <= (others =>'0');
    mouse_cs       <= '0';
    Ps2MouseClk_io <= 'Z';
    Ps2MouseDat_io <= 'Z';
  end generate;
  
  impl_ser1: if not use_ser_key_c and use_ser1_c generate 
--    ser_cs <= (not nIORQ and not nIORQ_d) when Addr(7 downto 2)=SER_BASE_ADDR_c(7 downto 2) else -- 0xF0 - 0xF3
    ser_cs <= IORQ when Addr(7 downto 2)=SER_BASE_ADDR_c(7 downto 2) else -- 0xF0 - 0xF3
              '0';
    
    ser : entity work.Ser1
      port map (
        reset_n_i   => reset_n,
        clk_i       => pixel_clk,
        RxD_i       => RxD_i,
        TxD_o       => TxD_s,
        RTS_o       => open, --RTS_o,
        CTS_i       => '1', --CTS_i,
        DTR_o       => open,
        Adr_i       => Addr(1 downto 0),
        en_i        => ser_cs,
        DataIn_i    => data_in,
        Rd_i        => gdp_Rd,
        Wr_i        => gdp_Wr,
        DataOut_o   => ser_data,
        Intr_o      => ser_int
      );
  end generate;
  no_ser1: if not use_ser1_c or use_ser_key_c generate
    ser_data       <= (others =>'0');
    ser_cs         <= '0';
--    RTS_o          <= CTS_i;
    TxD_s          <= RxD_i;
    ser_int        <= '0';
  end generate;
  --txd_debug_o <= TxD_s;
  --rxd_debug_o <= RxD_i;
  TXD_o       <= TxD_s;
     
  impl_sound : if use_sound_c generate
--    snd_cs <= (not nIORQ and not nIORQ_d) when Addr(7 downto 1)=SOUND_BASE_ADDR_c(7 downto 1) else -- 0x50 - 0x51
    snd_cs <= IORQ when Addr(7 downto 1)=SOUND_BASE_ADDR_c(7 downto 1) else -- 0x50 - 0x51
              '0';
    snd_bdir <= snd_cs and gdp_Wr;
    snd_bc1  <= snd_cs and (gdp_Rd or (gdp_Wr and not Addr(0))); --(not snd_cs) nor Addr(0);    

    process(pixel_clk,reset_n)
    begin
      if reset_n = '0' then
        wav_cnt <= 0;
        wav_en  <= '0';
      elsif rising_edge(pixel_clk) then
        wav_en  <= '0';
        if wav_cnt < 19 then
          wav_cnt <= wav_cnt +1;
        else
          wav_cnt <= 0;
          wav_en  <= '1';
        end if;
      end if;
    end process;
    
    Sound_inst : entity work.WF2149IP_TOP_SOC
      port map (
        SYS_CLK   => pixel_clk,
        RESETn    => reset_n,
        WAV_CLK   => wav_en,
        SELn      => '1',
        BDIR      => snd_bdir,
        BC2       => '1',
        BC1       => snd_bc1,
        A9n       => '0',
        A8        => '1',
        DA_IN     => data_in,
        DA_OUT    => snd_data,
        DA_EN     => open,
        IO_A_IN   => X"00",
        IO_A_OUT  => open,
        IO_A_EN   => open,
        IO_B_IN   => X"00",
        IO_B_OUT  => open,
        IO_B_EN   => open,
  --      OUT_A     => open,
  --      OUT_B     => open,
  --      OUT_C     => open
        SND_OUT    => SND_s,
        PWM_OUT    => PWM_OUT_s
      );
  end generate;
  no_sound: if not use_sound_c generate
    snd_data       <= (others =>'0');
    snd_cs         <= '0';
    snd_bdir       <= '0';
    snd_bc1        <= '0';
    PWM_OUT_s      <= 'Z';
    wav_cnt        <= 0;
    wav_en         <= '0';
    SND_s          <= (others =>'0');
  end generate;
  
  PWM_OUT_o <= PWM_OUT_s;
--  PWM_OUT_R_o <= PWM_OUT_s;

  impl_SPI: if use_spi_c generate 
--    spi_cs <= (not nIORQ and not nIORQ_d) when Addr(7 downto 1)=SPI_BASE_ADDR_c(7 downto 1) else -- 0x00 - 0x01
    spi_cs <= IORQ when Addr(7 downto 1)=SPI_BASE_ADDR_c(7 downto 1) else -- 0x00 - 0x01
              '0';
    
    SPI : entity work.SPI_Interface
      port map (
        reset_n_i   => reset_n,
        clk_i       => pixel_clk,
        SD_SCK_o    => SD_SCK_s,
        SD_nCS_o    => SD_nCS_s,
        SD_MOSI_o   => SD_MOSI_s,
        SD_MISO_i   => SD_MISO_s,
        Adr_i       => Addr(0 downto 0),
        en_i        => spi_cs,
        DataIn_i    => data_in,
        Rd_i        => gdp_Rd,
        Wr_i        => gdp_Wr,
        DataOut_o   => spi_data
      );
      SD_SCK_o   <= SD_SCK_s;
      SD1_SCK_o  <= SD_SCK_s;
      SD_nCS_o   <= SD_nCS_s(1 downto 0);
      SD_MOSI_o  <= SD_MOSI_s;
      SD1_MOSI_o <= SD_MOSI_s;
      --SD_MISO_s <= ETH_MISO_i when SD_nCS_s(2)='0' else
      --             SD_MISO_i;
      SD_MISO_s <= SD1_MISO_i when SD_nCS_s(1)='0' else
                   SD_MISO_i;
      -- duplicate SPI pins to decouple SD-cards and Ethernet controller electrically
      --ETH_SCK_o  <= SD_SCK_s;
      --ETH_nCS_o  <= SD_nCS_s(2);
      --ETH_MOSI_o <= SD_MOSI_s;
  end generate;
--  no_spi: if not use_spi_c generate
--    spi_data       <= (others =>'0');
--    spi_cs         <= '0';
--    SD_SCK_o       <= '0';
--    SD_nCS_o       <= (others => '1'); --(others => '1');
--    SD_MOSI_o      <= SD_MISO_i;
--    --ETH_SCK_o      <= SD_SCK_s;
--    --ETH_nCS_o      <= '1';
--    --ETH_MOSI_o     <= ETH_MISO_i;
--  end generate;
  
  impl_SDIO: if use_sdio_c generate 
    spi_cs <= IORQ when Addr(7 downto 1)=SDIO_BASE_ADDR_c(7 downto 1) else -- 0x20 - 0x21
              '0';
    
    SDIO : entity work.SDIO_Interface
      port map (
        reset_n_i   => reset_n,
        clk_i       => pixel_clk,
        SD_SCK_o    => SD_SCK_s,
        SD_nCS_o(1 downto 0)   => SD_nCS_s(1 downto 0),
        SD_MOSI_o   => SD_MOSI_s,
        SD_MISO_i   => SD_MISO_s,
        Adr_i       => Addr(0 downto 0),
        en_i        => spi_cs,
        DataIn_i    => data_in,
        Rd_i        => gdp_Rd,
        Wr_i        => gdp_Wr,
        DataOut_o   => spi_data
      );
      SD_SCK_o   <= SD_SCK_s;
      SD1_SCK_o  <= SD_SCK_s;
      SD_nCS_o   <= SD_nCS_s(1 downto 0);
      SD_MOSI_o  <= SD_MOSI_s;
      SD1_MOSI_o <= SD_MOSI_s;
      SD_MISO_s  <= SD1_MISO_i when SD_nCS_s(1)='0' else
                    SD_MISO_i;

  end generate;
  no_spi_no_sdio: if not use_spi_c and not use_sdio_c generate
    spi_data       <= (others =>'0');
    spi_cs         <= '0';
    SD_SCK_o       <= '0';
    SD_nCS_o       <= (others => '1'); --(others => '1');
    SD_MOSI_o      <= SD_MISO_i;
    --ETH_SCK_o      <= SD_SCK_s;
    --ETH_nCS_o      <= '1';
    --ETH_MOSI_o     <= ETH_MISO_i;
  end generate;
  
  impl_T1: if use_timer_c generate 
--    t1_cs <= (not nIORQ and not nIORQ_d) when Addr(7 downto 2)=T1_BASE_ADDR_c(7 downto 2) else -- 0x00 - 0x01
    t1_cs <= IORQ when Addr(7 downto 2)=T1_BASE_ADDR_c(7 downto 2) else -- 0x00 - 0x01
              '0';
    
    T1 : entity work.Timer
      port map (
        reset_n_i   => reset_n,
        clk_i       => pixel_clk,
        irq_o       => t1_irq,
        Adr_i       => Addr(1 downto 0),
        en_i        => t1_cs,
        DataIn_i    => data_in,
        Rd_i        => gdp_Rd,
        Wr_i        => gdp_Wr,
        DataOut_o   => t1_data
      );
  end generate;
  no_T1: if not use_timer_c generate
    t1_data      <= (others =>'0');
    t1_cs        <= '0';
    t1_irq       <= '0';
  end generate;
  
--  impl_VDIP: if use_vdip_c generate 
----    vdip_cs <= (not nIORQ and not nIORQ_d) when Addr(7 downto 2)=VDIP_BASE_ADDR_c(7 downto 2) else -- 0x20 - 0x23
--    vdip_cs <= IORQ when Addr(7 downto 2)=VDIP_BASE_ADDR_c(7 downto 2) else -- 0x20 - 0x23
--                '0';
--    
--  VDIP : SPI_VDIP
--      port map (
--        reset_n_i   => reset_n,
--        clk_i       => pixel_clk,
--        VDIP_SCK_o  => VDIP_SCK_o,
--        VDIP_CS_o   => VDIP_CS_o,
--        VDIP_MOSI_o => VDIP_MOSI_o,
--        VDIP_MISO_i => VDIP_MISO_i,
--        Adr_i       => Addr(1 downto 0),
--        en_i        => vdip_cs,
--        DataIn_i    => data_in,
--        Rd_i        => gdp_Rd,
--        Wr_i        => gdp_Wr,
--        DataOut_o   => vdip_data
--      );
--  end generate;
  no_vdip: if not use_vdip_c generate
    vdip_data       <= (others =>'0');
    vdip_cs         <= '0';
--    VDIP_SCK_o      <= '0';
--    VDIP_CS_o       <= '0';
--    VDIP_MOSI_o     <= VDIP_MISO_i;
  end generate;
  
--  impl_GPIO: if use_gpio_c generate 
--  
--    gpio_cs <= IORQ when Addr(7 downto 1)=GPIO_BASE_ADDR_c(7 downto 1) else -- 0x04 - 0x05
--                '0';
--    
--  GPIO : entity work.GPIO_Interface
--      port map (
--        reset_n_i   => reset_n,
--        clk_i       => pixel_clk,
--        GPIO_io     => open, --GPIO_io,
--        Adr_i       => Addr(0 downto 0),
--        en_i        => gpio_cs,
--        DataIn_i    => data_in,
--        Rd_i        => gdp_Rd,
--        Wr_i        => gdp_Wr,
--        DataOut_o   => gpio_data
--      );
--  end generate;
  no_gpio: if not use_gpio_c generate
    gpio_data       <= (others =>'0');
    gpio_cs         <= '0';
--    GPIO_io         <= (others =>'Z');
  end generate;
  
  nIRQ   <= '0' when (t1_irq or ser_int)='1' else
            '1';
            
            
   CPU: block  
      constant USE_FLOMON_c : boolean :=true;
      constant USE_ZEAT_c   : boolean :=true; 
      constant USE_BASIC_c  : boolean :=false; -- Test feature: ROM's in Bank 14 - use with care!
      constant USE_EZASS_c  : boolean :=false; -- Test feature: ROM's in Bank 14 - use with care!
      constant USE_GOSI_c   : boolean :=false; -- Test feature: ROM's in Bank 14 - use with care!
      constant USE_GRUND_c  : boolean :=false; -- Test feature: ROM's in Bank 14 - use with care!
      constant IO_WAITSTATES_c : natural := 4;
      signal logic1         : std_ulogic;
      signal logic0         : std_ulogic;
      signal reset          : std_ulogic;
      signal cycle_cnt      : natural range 0 to 4;
      signal CPUEN          : std_ulogic;
      signal DI_CPU,DO_CPU  : std_logic_vector(7 downto 0);
      signal Cpu_A          : std_logic_vector(15 downto 0);
      signal MReq_n         : std_logic;
      signal IORq_n         : std_logic;
      signal Rd_n,Wr_n      : std_logic;
      signal wait_n         : std_logic;
      signal rom_dout       : std_logic_vector(7 downto 0);
      signal rom_b14_dout   : std_logic_vector(7 downto 0);
      signal rom0_dout      : std_logic_vector(7 downto 0);
      signal rom1_dout      : std_logic_vector(7 downto 0);
      signal rom2_dout      : std_logic_vector(7 downto 0);
      signal rom_basic_dout : std_logic_vector(7 downto 0);
      signal rom_ezass_dout : std_logic_vector(7 downto 0);
      signal rom_gosi_dout  : std_logic_vector(7 downto 0);
      signal rom_gp_dout    : std_logic_vector(7 downto 0);
      --signal rom2_dout      : std_logic_vector(7 downto 0);

      signal nRD_d          : std_ulogic;
      signal nWR_d          : std_ulogic;
      signal rom_en         : std_ulogic;
      signal rom_b14_en     : std_ulogic;
      signal gp_ram_en      : std_ulogic;
      -- bank/boot specific signals
      signal bank_reg     : std_ulogic_vector(7 downto 0);
      signal bank_reg_en  : std_ulogic;
      signal banken       : std_ulogic;

      signal cpu_req1       : std_ulogic;
      signal cpu_req_d      : std_ulogic;
      signal INT_IORQ       : std_ulogic;
      signal EXT_IORQ       : std_ulogic;
      signal EXT_IORQ_d     : std_ulogic;
      signal ext_io_dly     : natural range 0 to IO_WAITSTATES_c;
      signal ext_io_wait    : std_ulogic;
      signal ext_data_reg   : std_ulogic_vector(7 downto 0);
      signal ext_driver_en  : std_ulogic;
      signal driver_DIR     : std_ulogic;
      signal int_n          : std_ulogic;
      --signal bus_watch      : natural range 0 to 500;
   begin
      logic1 <= '1';
      logic0 <= '0';
      process(pixel_clk,reset_n)
      begin
         if reset_n = '0' then

            nRD_d        <= '1';
            nWR_d        <= '1';
            gdp_Rd       <= '0';
            gdp_Wr       <= '0';
            cpu_req_d    <= '0';
            --bus_watch    <= 0;
            EXT_IORQ_d   <= '0';
            ext_data_reg <= (others => '0');
            ext_io_dly   <= 0;
            ext_io_wait  <= '1';
         elsif rising_edge(pixel_clk) then

            nWR_d      <= nWR;
            nRD_d      <= nRD;
            gdp_Rd     <= not nRD and nRD_d;
            gdp_Wr     <= not nWR and nWR_d;
            cpu_req_d  <= cpu_req1;
            EXT_IORQ_d <= EXT_IORQ;
            if (not EXT_IORQ_d and  EXT_IORQ)='1' then
               ext_io_wait <= '0';
               ext_io_dly  <= IO_WAITSTATES_c;
            elsif EXT_IORQ='1' then
               if ext_io_dly/=0 then
                  if CPUEN='1' then
                     ext_io_dly <= ext_io_dly - 1;
                  end if;
               else
                  ext_io_wait <= '1';
                  if nRD='0' then
                     ext_data_reg <= std_ulogic_vector(nkc_DB);
                  end if;
               end if;
            end if;
            --if cpu_req1='1' and cpu_busy/='0' then
            --   if enPhi2='1' and bus_watch/=7 then
            --      bus_watch <= bus_watch+1;
            --   end if;
            --else
            --   bus_watch <= 0;
            --end if;
         end if;
      end process;
   
     ISRD : entity work.InputSync
     generic map (
       ResetValue_g => '1'
     )
     port map (
         Input => nIRQ_i,
         clk   => pixel_clk,
         clr_n => reset_n,
         q     => int_n);
   
   
      reset <= not reset_n;

      Z80: entity work.T80se
         generic map (Mode => 0, T2Write => 1)
       port map (
         CLK_n   => pixel_clk,
         CLKEN   => CPUEN,
         RESET_n => reset_n,
         M1_n    => open,
         MREQ_n  => MReq_n,
         IORQ_n  => IORq_n,
         RD_n    => Rd_n,
         WR_n    => Wr_n,
         RFSH_n  => open,
         HALT_n  => open,
         WAIT_n  => wait_n,
         INT_n   => int_n,
         NMI_n   => '1',
         BUSRQ_n => '1',
         BUSAK_n => open,
         A       => Cpu_A,
         DI      => DI_CPU,
         DO      => DO_CPU);

  process(pixel_clk,reset_n)
  begin
    if reset_n = '0' then
      cycle_cnt <= 0;
      CPUEN     <= '0';
    elsif rising_edge(pixel_clk) then
      CPUEN <= '0';
      if cycle_cnt /= 4 then
        cycle_cnt <= cycle_cnt +1;
      else
        cycle_cnt <= 0;
        CPUEN     <= '1';
      end if;
    end if;
  end process;

   bank_reg_en <= '1' when IORq_n='0' and Cpu_A(7 downto 0) = X"C8" else
                  '0';

   -- bank/boot register
   process(pixel_clk,reset_n)
   begin
    if reset_n = '0' then
      bank_reg <= (others => '0');
    elsif rising_edge(pixel_clk) then
      --if (CPUEN and bank_reg_en and not Wr_n)='1' then
      if (bank_reg_en and gdp_Wr)='1' then
        bank_reg <= std_ulogic_vector(DO_CPU);
      end if;  
    end if;
   end process;
   
   banken <= bank_reg(7) or Cpu_A(15);

      gp_rom_inst: if not USE_FLOMON_c generate 
          -- GP2019 ROM A+B
          rom0: entity work.gp_rom0
            port map (
               Clk => pixel_clk,
               A   => Cpu_A(12 downto 0),
               D   => rom0_dout
            );
          rom1: entity work.gp_rom1
            port map (
               Clk => pixel_clk,
               A   => Cpu_A(12 downto 0),
               D   => rom1_dout
            );
--          rom2: entity work.rom2
--            port map (
--               Clk => pixel_clk,
--               A   => Cpu_A(12 downto 0),
--               D   => rom1_dout
--            );
            
         with to_integer(unsigned(Cpu_A(14 downto 13))) select
            rom_dout <= rom0_dout when 0, -- 0x0000 - 0x1FFF
                        rom1_dout when 1, -- 0x2000 - 0x3FFF
                        rom2_dout when 2, -- 0x4000 - 0x5FFF
                        (others => '1') when others;
         rom_b14_en <= '0';
      end generate;
      
      flomon_rom_inst: if USE_FLOMON_c generate
         test_rom_inst: if sim_g generate
            test_rom: entity work.test_rom
               port map (
                  CLK  => pixel_clk,
                  ADDR => Cpu_A(9 downto 0),
                  DATA => rom0_dout
               );
         end generate;
         flomon_rom_inst: if not sim_g generate
            rom0: entity work.flomon_rom
               port map (
                  Clk => pixel_clk,
                  A   => Cpu_A(12 downto 0),
                  D   => rom0_dout
               );
         end generate;

         with to_integer(unsigned(Cpu_A(14 downto 13))) select
            -- ROMs in all banks with Banken ='0'
            rom_dout <= rom0_dout when 0, -- 0x0000 - 0x1FFF Flomon
                        rom1_dout when 1, -- 0x2000 - 0x3FFF Zeat_A
                        rom2_dout when 2, -- 0x4000 - 0x5FFF Zeat_B
                        (others => '1') when others;
                        
         zeat_rom_inst: if USE_ZEAT_c generate
            rom1: entity work.zeat_a_rom
               port map (
                  Clk => pixel_clk,
                  A   => Cpu_A(12 downto 0),
                  D   => rom1_dout
               );
            rom2: entity work.zeat_b_rom
               port map (
                  Clk => pixel_clk,
                  A   => Cpu_A(12 downto 0),
                  D   => rom2_dout
               );
         end generate;
         no_zeat_rom: if not USE_ZEAT_c generate
            rom1_dout <= (others =>'1');
            rom2_dout <= (others =>'1');
         end generate;
         
         with to_integer(unsigned(Cpu_A(14 downto 13))) select
            -- ROMs on Bank 14 with Banken ='1'
            rom_b14_dout <= rom_gp_dout    when 0, -- 0xe0000 - 0xe1FFF GP
                            rom_gosi_dout  when 1, -- 0xe2000 - 0xe3FFF GOSI
                            rom_basic_dout when 2, -- 0xe4000 - 0xe5FFF Basic
                            rom_ezass_dout when 3, -- 0xe6000 - 0xe7FFF EZASS
                            (others => '1') when others;
         
         grund_rom_inst: if USE_GRUND_c generate
            rom1: entity work.grund_rom
               port map (
                  Clk => pixel_clk,
                  A   => Cpu_A(12 downto 0),
                  D   => rom_gp_dout
               );
         end generate;
         no_grund_rom: if not USE_GRUND_c generate
            rom_gp_dout <= (others =>'1');
         end generate;
         basic_rom_inst: if USE_BASIC_c generate
            rom1: entity work.basic_rom
               port map (
                  Clk => pixel_clk,
                  A   => Cpu_A(12 downto 0),
                  D   => rom_basic_dout
               );
         end generate;
         no_basic_rom: if not USE_BASIC_c generate
            rom_basic_dout <= (others =>'1');
         end generate;
         ezass_rom_inst: if USE_EZASS_c generate
            rom1: entity work.ezass_rom
               port map (
                  Clk => pixel_clk,
                  A   => Cpu_A(12 downto 0),
                  D   => rom_ezass_dout
               );
         end generate;
         no_ezass_rom: if not USE_EZASS_c generate
            rom_ezass_dout <= (others =>'1');
         end generate;
         gosi_rom_inst: if USE_GOSI_c generate
            rom1: entity work.gosi_rom
               port map (
                  Clk => pixel_clk,
                  A   => Cpu_A(12 downto 0),
                  D   => rom_gosi_dout
               );
         end generate;
         no_gosi_rom: if not USE_GOSI_c generate
            rom_gosi_dout <= (others =>'1');
         end generate;
         use_roms_in_b14: if USE_GRUND_c or USE_BASIC_c or USE_EZASS_c or USE_GOSI_c generate
            rom_b14_en <= MREQ when Cpu_A(15) ='0' and bank_reg(3 downto 0)=X"E" and banken='1' else
                          '0';
         end generate;
         no_roms_in_b14: if not USE_GRUND_c and not USE_BASIC_c and not USE_EZASS_c and not USE_GOSI_c generate
            rom_b14_en <= '0';
         end generate;
      end generate;
      
   process(Cpu_A,gp_ram_en,bank_reg)
   begin
      cpu_addr               <= (others => '0');
      cpu_addr(14 downto 0)  <= std_ulogic_vector(Cpu_A(15 downto 1));   -- 16bit data
      if gp_ram_en='1' then
         cpu_addr(20)<='1';
      else
         cpu_addr(18 downto 15) <= bank_reg(3 downto 0);
      end if;
   end process;
      --A15 14 13
      -- 0 0 0  -> 0x0000 - 0x1FFF
      -- 0 0 1  -> 0x2000 - 0x3FFF
      -- 0 1 0  -> 0x4000 - 0x5FFF
      -- 0 1 1  -> 0x6000 - 0x7FFF
      -- 1 0 0
      -- 1 0 1
      -- 1 1 0
      -- 1 1 1
      
      
      DI_CPU <= rom_dout                                 when rom_en='1' else
                rom_b14_dout                             when rom_b14_en='1' else
                std_logic_vector(cpu_datao(7 downto 0))  when cpu_req1='1' and Cpu_A(0) ='0' else
                std_logic_vector(cpu_datao(15 downto 8)) when cpu_req1='1' and Cpu_A(0) ='1' else
                std_logic_vector(bank_reg)               when bank_reg_en='1' else
                nkc_DB_in                                when INT_IORQ='1' else
                std_logic_vector(ext_data_reg)           when EXT_IORQ='1' else
                (others => '1');
      
      
      nRD  <= Rd_n;
      nWR  <= Wr_n;
      IORQ <= not IORq_n;
      MREQ <= not MReq_n and (not RD_n or not WR_n);
      
      -- ROM: 0 - 5fff
      rom_en <= MREQ when unsigned(Cpu_A(15 downto 13)) < 3 and banken='0' else
                '0';
      -- Bank/Boot-Ram 0x6000 - 0x7fff
      gp_ram_en <= MREQ when (Cpu_A(15 downto 13)="011") and banken='0' else
                   '0';
      -- 1MB of SDRAM (0 - 0xf_ffff) (BANKEN=1) and 8kB at 0x6000 - 0x7FFF (BANKEN=0)
      cpu_req1 <= MREQ when rom_b14_en='0' and (banken='1' or gp_ram_en='1') else   -- 64kB
                  '0';
      cpu_req     <= cpu_req1 and not cpu_req_d;
      cpu_wr      <= MREQ and not nWR;
      
      wait_n      <= '0'         when cpu_req1='1' and cpu_busy/='0' else
                     ext_io_wait when EXT_IORQ='1' else
                     '1';

      cpu_datai   <= std_ulogic_vector(DO_CPU) & std_ulogic_vector(DO_CPU);
      cpu_data_bv <= "01" when Cpu_A(0)='0' else
                     "10";
      Addr        <= std_ulogic_vector(Cpu_A(7 downto 0));
      data_in     <= std_ulogic_vector(DO_CPU);
      
      -- indicates and FPGA internal IORQ when '1'
      INT_IORQ     <= IORQ and fpga_en;
      
      
      nkc_nreset_o <= reset_n;

      nkc_DB       <= DO_CPU when not is_pcb and driver_DIR='0' else
                      DO_CPU when     is_pcb and driver_DIR='1' else
                      (others => 'Z');

      process(pixel_clk)
      begin
         if rising_edge(pixel_clk) then
            EXT_IORQ      <= IORQ and not fpga_en;
            ext_driver_en <= IORQ and not fpga_en and not nWR;
            nkc_nRD_o     <= '1';
            if (not nRD and EXT_IORQ)='1' then
               nkc_nRD_o     <= '0';
            end if;
            nkc_nWR_o     <= '1';
            if is_pcb then
               driver_DIR    <= ext_driver_en; -- 245 DIR = 1 (A->B) for an ext write
            else
               driver_DIR    <= not ext_driver_en; -- 245 DIR = 0 (B->A) for an ext write for Prototype
            end if;
            if (not nWR and EXT_IORQ)='1' then
               nkc_nWR_o     <= '0';
               -- set 245 to output (B->A) for an external IO-Write
               --driver_DIR_o  <= '0';
            end if;
         end if;
      end process;
      
      nkc_ADDR_o   <= std_ulogic_vector(Cpu_A(7 downto 0));

      nkc_nIORQ_o  <= not EXT_IORQ;
      driver_nEN_o <= not reset_n; 
      -- set 245 to output (B->A) for an external IO-Write
      driver_DIR_o <= driver_DIR;
      driver_DIR1_o<= '1' when is_pcb else -- set driver to drive towards bus for "official" PCB
                      '0'; 
   end block;

end rtl;
