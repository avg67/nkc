--------------------------------------------------------------------------------
-- Project     : Single Chip NDR Computer
-- Module      : GDP 936X Display processor - Toplevel for Lattice FPGA
-- File        : GDP_kernel.vhd
-- Description :
--------------------------------------------------------------------------------
-- Author       : Andreas Voggeneder
-- Organisation : FH-Hagenberg
-- Department   : Hardware/Software Systems Engineering
-- Language     : VHDL'87
--------------------------------------------------------------------------------
-- Copyright (c) 2007 by Andreas Voggeneder
--------------------------------------------------------------------------------
library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.DffGlobal.all;
use work.gdp_global.all;

entity gdp_lattice_top is
  generic(sim_g      : boolean := false);
  port(reset_n_i     : in  std_ulogic;
       clk_i         : in  std_ulogic;
--       addr_sel_i    : in  std_ulogic;
       --------------------------
       -- NKC Bus
       --------------------------
       nkc_DB        : inout std_logic_vector(7 downto 0);
       nkc_ADDR_i    : in std_ulogic_vector(7 downto 0);
       nkc_nRD_i     : in std_ulogic;
       nkc_nWR_i     : in std_ulogic;
       nkc_nIORQ_i   : in std_ulogic;
       driver_nEN_o  : out std_ulogic;
       driver_DIR_o  : out std_ulogic;
       nIRQ_o        : out std_ulogic;
       --------------------------
       -- UART Receiver
       --------------------------
       RxD_i    : in  std_ulogic;
       TxD_o    : out std_ulogic;
       RTS_o    : out std_ulogic;
       CTS_i    : in  std_ulogic;
       --------------------------
       -- PS/2 Keyboard signals
       --------------------------
       -- PS/2 clock line. Bidirectional (resolved!) for Inhibit bus state on
       -- PS/2 bus. In all other cases an input would be sufficient.
       Ps2Clk_io    : inout std_logic;
       -- PS/2 data line. Bidirectional for reading and writing data.
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
       --------------------------
       -- Video out
       --------------------------
       Red_o      : out std_ulogic_vector(2 downto 0);
       Green_o    : out std_ulogic_vector(2 downto 0);
       Blue_o     : out std_ulogic_vector(2 downto 0);
       Hsync_o    : out std_ulogic;
       Vsync_o    : out std_ulogic;
       --------------------------
       -- SPI-Signals
       --------------------------
       SD_SCK_o  : out std_ulogic;
       SD_nCS_o  : out std_ulogic_vector(1 downto 0);
       SD_MOSI_o : out std_ulogic;
       SD_MISO_i : in  std_ulogic;
       --
       ETH_SCK_o  : out std_ulogic;
       ETH_nCS_o  : out std_ulogic;
       ETH_MOSI_o : out std_ulogic;
       ETH_MISO_i : in  std_ulogic;
       --------------------------
       -- VDIP-SPI-Signals
       --------------------------
--       VDIP_SCK_o  : out std_ulogic;
--       VDIP_CS_o   : out std_ulogic;
--       VDIP_MOSI_o : out std_ulogic;
--       VDIP_MISO_i : in  std_ulogic;      
       --------------------------
       -- GPIO-Signals
       --------------------------
       GPIO_io   : inout std_logic_vector(7 downto 0);
       --------------------------
       -- Video-Memory data bus
       --------------------------
       SRAM1_nCS    : out std_ulogic;
       SRAM1_nCS1   : out std_ulogic;
       SRAM1_ADR    : out std_ulogic_vector(16 downto 0);
       SRAM1_DB     : inout std_logic_vector(7 downto 0);
       SRAM1_nWR    : out std_ulogic;
       SRAM1_nOE    : out std_ulogic;
       --------------------------
       -- Debug Signals - GDP
       --------------------------
       glob_gdp_en_i : in std_ulogic
--       debug_o      : out std_ulogic_vector(nr_mon_sigs_c-1 downto 0);
--       sample_clk_o : out std_ulogic
       );
end gdp_lattice_top;

architecture rtl of gdp_lattice_top is
  component gdp_bi is
    port(reset_n_i     : in  std_ulogic;
         clk_i         : in  std_ulogic;
         fpga_en_i     : in  std_ulogic;
         addr_o        : out std_ulogic_vector(7 downto 0);
         data_in_o     : out std_ulogic_vector(7 downto 0);
         IORQ_o        : out std_ulogic;
         Rd_o          : out std_ulogic;
         Wr_o          : out std_ulogic;
         nRd_sync_o    : out std_ulogic;
         nWr_sync_o    : out std_ulogic;
         nkc_nIORQ_i   : in  std_ulogic;
         nkc_nRD_i     : in  std_ulogic;
         nkc_nWR_i     : in  std_ulogic;
         nkc_ADDR_i    : in  std_ulogic_vector(7 downto 0);
         nkc_DB        : in  std_logic_vector(7 downto 0)
    );
  end component;

  component gdp_top is
    generic(INT_CHR_ROM_g : boolean := true); 
    port(reset_n_i     : in  std_ulogic;
         clk_i         : in  std_ulogic;
         clk_en_i      : in  std_ulogic;
         --------------------------
         -- internal data bus (Register)
         --------------------------
         Adr_i     : in  std_ulogic_vector(3 downto 0);
         gdp_en_i  : in  std_ulogic;
         sfr_en_i  : in  std_ulogic;
         col_en_i  : in  std_ulogic;
         clut_en_i : in  std_ulogic;
         DataIn_i  : in  std_ulogic_vector(7 downto 0);
         Rd_i      : in  std_ulogic;
         Wr_i      : in  std_ulogic;
         DataOut_o : out std_ulogic_vector(7 downto 0);
         --------------------------
         -- Video out
         --------------------------
--         pixel_o    : out std_ulogic;
         pixel_red_o   : out std_ulogic_vector(2 downto 0);
         pixel_green_o : out std_ulogic_vector(2 downto 0);
         pixel_blue_o  : out std_ulogic_vector(2 downto 0);
         Hsync_o       : out std_ulogic;
         Vsync_o       : out std_ulogic;
         --------------------------
         -- Video-Memory data bus
         --------------------------
         sram_addr_o : out std_ulogic_vector(16 downto 0);
         sram_data_o : out std_ulogic_vector(7 downto 0);
         sram_data_i : in  std_ulogic_vector(7 downto 0);
         sram_ena_o  : out std_ulogic_vector(1 downto 0);
         sram_we_o   : out std_ulogic;
         rom_ena_o   : out std_ulogic;
         --------------------------
         -- Monitoring (Debug) signals
         --------------------------
         monitoring_o : out std_ulogic_vector(nr_mon_sigs_c-1 downto 0)
         );
  end component;

  component InputSync
    generic(levels_g     : natural :=2;
            ResetValue_g : std_ulogic := '0');
    port (
      Input : in  std_ulogic;
      clk   : in  std_ulogic;
      clr_n : in  std_ulogic;
      q     : out std_ulogic);
  end component;
  
  component Receiver
    port (
      clk        : in  std_ulogic;
      clr_n      : in  std_ulogic;
      RxD        : in  std_ulogic;
      Busy       : in  std_ulogic;
      DoutPar    : out std_ulogic_vector(7 downto 0);
      DataValid  : out std_ulogic;
      ErrorFlags : out std_ulogic_vector(1 downto 0));
  end component;
  
  component PS2Keyboard
    port (
      reset_n_i : in    std_logic;
      clk_i     : in    std_logic;
      Ps2Clk_io : inout std_logic;
      Ps2Dat_io : inout std_logic;
      KeyCS_i   : in  std_ulogic;
      DipCS_i   : in  std_ulogic;
      Rd_i      : in  std_ulogic;
      DataOut_o : out std_ulogic_vector(7 downto 0);
      monitoring_o : out std_ulogic_vector(nr_mon_sigs_c-1 downto 0)
    );
  end component;
  
  component PS2Mouse is
  port(
    reset_n_i    : in  std_logic;
    clk_i        : in  std_logic;
    Ps2Clk_io    : inout std_logic;
    Ps2Dat_io    : inout std_logic;
    Adr_i        : in  std_ulogic_vector(2 downto 0);
    en_i         : in  std_ulogic;
    DataIn_i     : in  std_ulogic_vector(7 downto 0);
    Rd_i         : in  std_ulogic;
    Wr_i         : in  std_ulogic;
    DataOut_o    : out std_ulogic_vector(7 downto 0);
    monitoring_o : out std_ulogic_vector(nr_mon_sigs_c-1 downto 0)
  );
  end component;
  
  component Ser1
    port(
      reset_n_i    : in  std_logic;
      clk_i        : in  std_logic;
      RxD_i        : in  std_ulogic;
      TxD_o        : out std_ulogic;
      RTS_o        : out std_ulogic;
      CTS_i        : in  std_ulogic;
      DTR_o        : out std_ulogic;
      Adr_i        : in  std_ulogic_vector(1 downto 0);
      en_i         : in  std_ulogic;
      DataIn_i     : in  std_ulogic_vector(7 downto 0);
      Rd_i         : in  std_ulogic;
      Wr_i         : in  std_ulogic;
      DataOut_o    : out std_ulogic_vector(7 downto 0);
      Intr_o       : out std_ulogic;
      monitoring_o : out std_ulogic_vector(nr_mon_sigs_c-1 downto 0)
    );
  end component;
  
  component WF2149IP_TOP_SOC is
    port(
      SYS_CLK     : in std_ulogic; -- Read the inforation in the header!
      RESETn      : in std_ulogic;
      WAV_CLK     : in std_ulogic; -- Read the inforation in the header!
      SELn        : in std_ulogic;

      BDIR        : in std_ulogic;
      BC2, BC1    : in std_ulogic;

      A9n, A8     : in std_ulogic;
      DA_IN       : in std_ulogic_vector(7 downto 0);
      DA_OUT      : out std_ulogic_vector(7 downto 0);
      DA_EN       : out std_ulogic;
      
      IO_A_IN     : in std_ulogic_vector(7 downto 0);
      IO_A_OUT    : out std_ulogic_vector(7 downto 0);
      IO_A_EN     : out std_ulogic;
      IO_B_IN     : in std_ulogic_vector(7 downto 0);
      IO_B_OUT    : out std_ulogic_vector(7 downto 0);
      IO_B_EN     : out std_ulogic;

--      OUT_A       : out std_ulogic; -- Analog (PWM) outputs.
--      OUT_B       : out std_ulogic;
--      OUT_C       : out std_ulogic
      PWM_OUT     : out std_ulogic
    );
  end component;
  
  component SPI_Interface is
    port(
      reset_n_i    : in  std_logic;
      clk_i        : in  std_logic;
      SD_SCK_o  : out std_ulogic;
      SD_nCS_o  : out std_ulogic_vector(2 downto 0);
      SD_MOSI_o : out std_ulogic;
      SD_MISO_i : in  std_ulogic;
      Adr_i     : in  std_ulogic_vector(0 downto 0);
      en_i      : in  std_ulogic;
      DataIn_i  : in  std_ulogic_vector(7 downto 0);
      Rd_i      : in  std_ulogic;
      Wr_i      : in  std_ulogic;
      DataOut_o : out std_ulogic_vector(7 downto 0)
  --    monitoring_o : out std_ulogic_vector(nr_mon_sigs_c-1 downto 0)
    );
  end component;
  
  component Timer is
  port(
    reset_n_i    : in  std_logic;
    clk_i        : in  std_logic;
    Irq_o     : out std_ulogic;
    Adr_i     : in  std_ulogic_vector(1 downto 0);
    en_i      : in  std_ulogic;
    DataIn_i  : in  std_ulogic_vector(7 downto 0);
    Rd_i      : in  std_ulogic;
    Wr_i      : in  std_ulogic;
    DataOut_o : out std_ulogic_vector(7 downto 0)
  );
  end component;
  
  component SPI_VDIP is
    port(
      reset_n_i    : in  std_logic;
      clk_i        : in  std_logic;
      VDIP_SCK_o  : out std_ulogic;
      VDIP_CS_o   : out std_ulogic;
      VDIP_MOSI_o : out std_ulogic;
      VDIP_MISO_i : in  std_ulogic;
      Adr_i     : in  std_ulogic_vector(1 downto 0);
      en_i      : in  std_ulogic;
      DataIn_i  : in  std_ulogic_vector(7 downto 0);
      Rd_i      : in  std_ulogic;
      Wr_i      : in  std_ulogic;
      DataOut_o : out std_ulogic_vector(7 downto 0)
--      monitoring_o : out std_ulogic_vector(nr_mon_sigs_c-1 downto 0)
    );
  end component;
  
  component GPIO_Interface is
  port(
    reset_n_i : in  std_logic;
    clk_i     : in  std_logic;
    GPIO_io   : inout std_logic_vector(7 downto 0);
    Adr_i     : in  std_ulogic_vector(0 downto 0);
    en_i      : in  std_ulogic;
    DataIn_i  : in  std_ulogic_vector(7 downto 0);
    Rd_i      : in  std_ulogic;
    Wr_i      : in  std_ulogic;
    DataOut_o : out std_ulogic_vector(7 downto 0)
  );
  end component;
  
  constant use_ser_key_c   : boolean := false;
  constant use_ps2_key_c   : boolean := true;
  constant use_ps2_mouse_c : boolean := true;
  constant use_ser1_c      : boolean := true;
  constant use_sound_c     : boolean := true;
  constant use_spi_c       : boolean := true;
  constant use_timer_c     : boolean := true;
  constant use_vdip_c      : boolean := false;
  constant use_gpio_c      : boolean := true;
  constant dipswitches_c   : std_logic_vector(7 downto 0) := X"49";
--  constant dipswitches1_c : std_logic_vector(7 downto 0) := X"01";
  
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
  constant T1_BASE_ADDR_c     : std_ulogic_vector(7 downto 0) := X"F4"; -- r/w 
  constant VDIP_BASE_ADDR_c   : std_ulogic_vector(7 downto 0) := X"20"; -- r/w 
  constant GPIO_BASE_ADDR_c   : std_ulogic_vector(7 downto 0) := X"04"; -- r/w 
--  constant GDP_BASE_ADDR1_c  : std_ulogic_vector(7 downto 0) := X"50"; -- r/w
--  constant SFR_BASE_ADDR1_c  : std_ulogic_vector(7 downto 0) := X"40"; -- w
--  constant KEY_BASE_ADDR1_c  : std_ulogic_vector(7 downto 0) := X"48"; -- r
--  constant DIP_BASE_ADDR1_c  : std_ulogic_vector(7 downto 0) := X"49"; -- r
  
  signal reset_n           : std_ulogic;
  signal GDP_SRAM_ADDR     : std_ulogic_vector(16 downto 0);
  signal GDP_SRAM_datao    : std_ulogic_vector(7 downto 0);
  signal GDP_DataOut       : std_ulogic_vector(7 downto 0);
  signal GDP_SRAM_datai    : std_ulogic_vector(7 downto 0);
  signal GDP_SRAM_ena      : std_ulogic_vector(1 downto 0);
  signal GDP_SRAM_we       : std_ulogic;
--  signal VGA_pixel         : std_ulogic;
  signal gdp_Rd,gdp_Wr     : std_ulogic;
  signal gdp_cs            : std_ulogic;
  signal gdp_en,sfr_en     : std_ulogic;
  signal col_en,clut_en    : std_ulogic;

--  signal nIORQ,nIORQ_d     : std_ulogic;
--  signal nRD_d             : std_ulogic;
--  signal nWR_d             : std_ulogic;
  signal nWr,nRd           : std_ulogic;
  signal IORQ              : std_ulogic;
  signal glob_gdp_en       : std_ulogic;
  signal Addr              : std_ulogic_vector(7 downto 0);
  signal data_in           : std_ulogic_vector(7 downto 0);
  signal output_en,fpga_en : std_ulogic;
  signal key_cs,dip_cs     : std_ulogic;
  signal mouse_cs          : std_ulogic;
  
  signal BusyRX              : std_ulogic;
  signal DoutParRX,key_data  : std_ulogic_vector(7 downto 0);
  signal DataValidRX         : std_ulogic;
  signal OldDataValidRX      : std_ulogic;
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

  sync_reset: if not sim_g generate
    reset_sync: process(clk_i)
      variable tmp_v : std_ulogic_vector(1 downto 0):= "00";
    begin
      if rising_edge(clk_i) then
        reset_n  <= tmp_v(1);
        tmp_v(1) := tmp_v(0);
        tmp_v(0) := reset_n_i;
      end if;
    end process reset_sync;
  end generate;
  
  nosync_reset: if sim_g generate
    reset_n  <= reset_n_i;
  end generate;
  
--  GDP_EN_SYNC : InputSync
--     generic map (
--       ResetValue_g => '1'
--     )
 --    port map (
 --        Input => glob_gdp_en_i,
 --        clk   => clk_i,
 --        clr_n => reset_n,
 --        q     => glob_gdp_en
 --    );
 
 glob_gdp_en <= '1';
	 
--  ISIORQ : InputSync
--  generic map (
--    ResetValue_g => '1'
--  )
--  port map (
--      Input => nkc_nIORQ_i,
--      clk   => Clk_i,
--      clr_n => Reset_n,
--      q     => nIORQ);
--      
--  ISRD : InputSync
--  generic map (
--    ResetValue_g => '1'
--  )
--  port map (
--      Input => nkc_nRD_i,
--      clk   => Clk_i,
--      clr_n => Reset_n,
--      q     => nRD);
--      
--  ISWR : InputSync
--  generic map (
--    ResetValue_g => '1'
--  )
--  port map (
--      Input => nkc_nWR_i,
--      clk   => Clk_i,
--      clr_n => Reset_n,
--      q     => nWR);
--  
--  process(clk_i,reset_n)
----    variable oe_v : std_ulogic;
--  begin
--    if reset_n = '0' then
--      nIORQ_d      <= '1';
--      nRD_d        <= '1';
--      nWR_d        <= '1';
--      gdp_Rd       <= '0';
--      gdp_Wr       <= '0';
--      Addr         <= (others => '0');
--      data_in      <= (others => '0');
----      output_en    <= '0';
--    elsif rising_edge(clk_i) then
--      nIORQ_d      <= nIORQ; -- for edge detection
----      nWR_d        <= '1';
----      nRD_d        <= '1';
--      nWR_d  <= nWR;
--      nRD_d  <= nRD;
----      oe_v         := gdp_cs or key_cs or dip_cs or mouse_cs or ser_cs or snd_cs or spi_cs or t1_cs;
----      output_en    <= oe_v;
--      gdp_Rd  <= '0';
--      gdp_Wr  <= '0';
--      if nIORQ = '0' then
--        if nIORQ_d = '1' then
--          -- IORQ  had an falling edge.
--          -- Store Address
--          Addr <= nkc_ADDR_i;
--        end if;
--        if fpga_en = '1' or nRD = '0' then
----          nWR_d  <= nWR;
----          nRD_d  <= nRD;
--          gdp_Rd <= not nRD and nRD_d;
--          if (not nWR and nWR_d)='1' then
--            data_in <= std_ulogic_vector(nkc_DB);
--            gdp_Wr  <= '1';
--          end if;
--        end if;
--      else
--        nWR_d <= '1';
--        nRD_d <= '1';
--      end if;
--    end if;
--  end process;

  bi_inst:gdp_bi
    port map(
      reset_n_i   => reset_n,
      clk_i       => clk_i,
      fpga_en_i   => fpga_en,
      addr_o      => Addr,
      data_in_o   => data_in,
      IORQ_o      => IORQ,
      Rd_o        => gdp_Rd,
      Wr_o        => gdp_Wr,
      nRd_sync_o  => nRd,
      nWr_sync_o  => nWr,
      nkc_nIORQ_i => nkc_nIORQ_i,
      nkc_nRD_i   => nkc_nRD_i,
      nkc_nWR_i   => nkc_nWR_i,
      nkc_ADDR_i  => nkc_ADDR_i,
      nkc_DB      => nkc_DB
    );


  fpga_en      <= gdp_cs or key_cs or dip_cs or mouse_cs or ser_cs or 
                  snd_cs or spi_cs or t1_cs or vdip_cs or gpio_cs;
  driver_nEN_o <= not reset_n; --not(output_en and (not nkc_nWR_i or not nkc_nRD_i)); 
  driver_DIR_o <= '0' when (fpga_en and not nkc_nRD_i)='1' else
                  '1';
  process(clk_i,reset_n)   
  begin
    if reset_n = '0' then
      output_en <= '0';
    elsif rising_edge(clk_i) then
      output_en <= fpga_en;
    end if;
  end process;
  
--  process(clk_i,reset_n)
--  begin
--    if reset_n = '0' then
--      nIORQ_d      <= '1';
--      nRD_d        <= '1';
--      nWR_d        <= '1';
--      gdp_Rd       <= '0';
--      gdp_Wr       <= '0';
--      Addr         <= (others => '0');
--      data_in      <= (others => '0');
--      output_en    <= '0';
--    elsif rising_edge(clk_i) then
--      nIORQ_d      <= nIORQ; -- for edge detection
--      nWR_d        <= '1';
--      nRD_d        <= '1';
--      output_en    <= gdp_cs or key_cs or dip_cs or mouse_cs or ser_cs or snd_cs or spi_cs or t1_cs;
--      
--      gdp_Rd  <= '0';
--      gdp_Wr  <= '0';
--      if nIORQ = '0' then
--        if nIORQ_d = '1' then
--          -- IORQ  had an falling edge.
--          -- Store Address
--          Addr <= nkc_ADDR_i;
--        elsif output_en = '1' or nRD = '0' then
--          nWR_d  <= nWR;
--          nRD_d  <= nRD;
--          gdp_Rd <= not nRD and nRD_d;
--          if (not nWR and nWR_d)='1' then
--            data_in <= std_ulogic_vector(nkc_DB);
--            gdp_Wr  <= '1';
--          end if;
--        end if;
--      end if;
--    end if;
--  end process;
--
--  driver_nEN_o <= not(output_en and (not nkc_nWR_i or not nkc_nRD_i)); 
--  driver_DIR_o <= nRD;
                   
  nkc_DB       <= std_logic_vector(GDP_DataOut) when (output_en and gdp_cs   and not nkc_nRD_i)='1' else
                  std_logic_vector(key_data)    when (output_en and key_cs   and not nkc_nRD_i)='1' else
	                dipsw                         when (output_en and dip_cs   and not nkc_nRD_i)='1' else
	                std_logic_vector(mouse_data)  when (output_en and mouse_cs and not nkc_nRD_i)='1' else
	                std_logic_vector(ser_data)    when (output_en and ser_cs   and not nkc_nRD_i)='1' else
	                std_logic_vector(snd_data)    when (output_en and snd_cs   and not nkc_nRD_i)='1' else
	                std_logic_vector(spi_data)    when (output_en and spi_cs   and not nkc_nRD_i)='1' else
	                std_logic_vector(t1_data)     when (output_en and t1_cs    and not nkc_nRD_i)='1' else
	                std_logic_vector(vdip_data)   when (output_en and vdip_cs  and not nkc_nRD_i)='1' else
	                std_logic_vector(gpio_data)   when (output_en and gpio_cs  and not nkc_nRD_i)='1' else
                  (others => 'Z') after 1 ns;
  
      
  GDP: gdp_top
    port map (
      reset_n_i   => reset_n,
      clk_i       => clk_i,
      clk_en_i    => '1',
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
--      pixel_o     => VGA_pixel,
      pixel_red_o   => red_o,
      pixel_green_o => green_o,
      pixel_blue_o  => blue_o,
      Hsync_o     => Hsync_o,
      Vsync_o     => Vsync_o,
      sram_addr_o => GDP_SRAM_ADDR,
      sram_data_o => GDP_SRAM_datao,
      sram_data_i => GDP_SRAM_datai,
      sram_ena_o  => GDP_SRAM_ena,
      sram_we_o   => GDP_SRAM_we,
      monitoring_o=> open --debug_o
      );
  
----  gdp_cs <= (not nIORQ and not nIORQ_d) when  Addr(7 downto 4) = "0111" or  -- GDP
----                                             (Addr(7 downto 4) = "0110" and nWR='0')  else -- SFRs
----            '0';
--  gdp_cs <= (not nIORQ and not nIORQ_d) when  Addr(7 downto 4) = GDP_BASE_ADDR_c(7 downto 4) or  -- GDP
--                                             (Addr(7 downto 4) = SFR_BASE_ADDR_c(7 downto 4) and nWR='0')  else -- SFRs
--            '0';
--  gdp_en <= gdp_cs when Addr(7 downto 4) = GDP_BASE_ADDR_c(7 downto 4) else
--            '0';
--  sfr_en <= gdp_cs when Addr(7 downto 4) = SFR_BASE_ADDR_c(7 downto 4) else
--            '0';
--  key_cs <= (not nIORQ and not nIORQ_d) when Addr = KEY_BASE_ADDR_c and nRD='0' else
--            '0';
--  dip_cs <= (not nIORQ and not nIORQ_d) when Addr = DIP_BASE_ADDR_c and nRD='0' else
--            '0';

--  gdp_cs <= (not nIORQ and not nIORQ_d) when  Addr(7 downto 4) = gdp_base(7 downto 4)  or  -- GDP
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
--  key_cs <= (not nIORQ and not nIORQ_d and addr_sel_i) when Addr = key_base and nRD='0' else
--  key_cs <= (not nIORQ and not nIORQ_d) when Addr = key_base and nRD='0' else
  key_cs <= IORQ when Addr = key_base and nRD='0' else
            '0';
--  dip_cs <= (not nIORQ and not nIORQ_d and addr_sel_i) when Addr = dip_base and nRD='0' else
--  dip_cs <= (not nIORQ and not nIORQ_d) when Addr = dip_base and nRD='0' else
  dip_cs <= IORQ when Addr = dip_base and nRD='0' else
            '0';

--  impl_key1: if use_ser_key_c generate
--              
--    Rx: Receiver
--      port map (
--        clk        => clk_i,
--        clr_n      => reset_n,
--        RxD        => RxD_i,
--        Busy       => BusyRX,
--        DoutPar    => DoutParRX,
--        DataValid  => DataValidRX,
--        ErrorFlags => open);
--    
--    process(clk_i,reset_n)
--  --    variable access_v : std_ulogic;
--    begin
--      if reset_n = '0' then
--        BusyRX <= '1';
--        OldDataValidRX <= '0';
--  --      access_v       := '0';
--      elsif rising_edge(clk_i) then
--        OldDataValidRX <= DataValidRX;
--        if (not OldDataValidRX and DataValidRX)= '1' then
--          BusyRX <= '1';
--        end if;
--  --      if (access_v and nRD and not nRD_d)='1' then
--  --        BusyRX   <= '0';
--  --        access_v := '0';
--  --      end if;
--        if (dip_cs and gdp_Rd)='1' then
--  --        access_v := '1';
--          BusyRX <= '0';
--        end if;  
--      end if;
--    end process; 
--    key_data  <= not BusyRX & DoutParRX(6 downto 0);
--  end generate;
  
  no_key1: if not use_ser_key_c and not use_ps2_key_c generate
    DoutParRX <= (others =>'0');
    BusyRX    <= '1';
    key_data  <= not BusyRX & DoutParRX(6 downto 0);
  end generate;
  
  impl_key2: if use_ps2_key_c generate
    kbd: PS2Keyboard
      port map (
        reset_n_i => reset_n,
        clk_i     => clk_i,
        Ps2Clk_io => Ps2Clk_io,
        Ps2Dat_io => Ps2Dat_io,
        KeyCS_i   => key_cs,
        DipCS_i   => dip_cs,
        Rd_i      => gdp_Rd,
        DataOut_o => key_data,
        monitoring_o=> open --debug_o
     );
   end generate;

  impl_mouse: if use_ps2_mouse_c generate 
--    mouse_cs <= (not nIORQ and not nIORQ_d and addr_sel_i) when Addr(7 downto 3)=MOUSE_BASE_ADDR_c(7 downto 3) else
--    mouse_cs <= (not nIORQ and not nIORQ_d) when Addr(7 downto 3)=MOUSE_BASE_ADDR_c(7 downto 3) else
    mouse_cs <= IORQ when Addr(7 downto 3)=MOUSE_BASE_ADDR_c(7 downto 3) else
                '0';
    mouse : PS2Mouse
      port map (
        reset_n_i    => reset_n,
        clk_i        => clk_i,
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
  
  impl_ser1: if use_ser1_c generate 
--    ser_cs <= (not nIORQ and not nIORQ_d) when Addr(7 downto 2)=SER_BASE_ADDR_c(7 downto 2) else -- 0xF0 - 0xF3
    ser_cs <= IORQ when Addr(7 downto 2)=SER_BASE_ADDR_c(7 downto 2) else -- 0xF0 - 0xF3
              '0';
    
    ser : Ser1
      port map (
        reset_n_i   => reset_n,
        clk_i       => clk_i,
        RxD_i       => RxD_i,
        TxD_o       => TxD_o,
        RTS_o       => RTS_o,
        CTS_i       => CTS_i,
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
  no_ser1: if not use_ser1_c generate
    ser_data       <= (others =>'0');
    ser_cs         <= '0';
    RTS_o          <= CTS_i;
    TxD_o          <= RxD_i;
    ser_int        <= '0';
  end generate;      
     
  impl_sound : if use_sound_c generate
--    snd_cs <= (not nIORQ and not nIORQ_d) when Addr(7 downto 1)=SOUND_BASE_ADDR_c(7 downto 1) else -- 0x50 - 0x51
    snd_cs <= IORQ when Addr(7 downto 1)=SOUND_BASE_ADDR_c(7 downto 1) else -- 0x50 - 0x51
              '0';
    snd_bdir <= snd_cs and gdp_Wr;
    snd_bc1  <= snd_cs and (gdp_Rd or (gdp_Wr and not Addr(0))); --(not snd_cs) nor Addr(0);    

    process(clk_i,reset_n)
    begin
      if reset_n = '0' then
        wav_cnt <= 0;
        wav_en  <= '0';
      elsif rising_edge(clk_i) then
        wav_en  <= '0';
        if wav_cnt < 19 then
          wav_cnt <= wav_cnt +1;
        else
          wav_cnt <= 0;
          wav_en  <= '1';
        end if;
      end if;
    end process;
    
    Sound_inst : WF2149IP_TOP_SOC
      port map (
        SYS_CLK   => clk_i,
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
        PWM_OUT    => PWM_OUT_o
      );
  end generate;
  no_sound: if not use_sound_c generate
    snd_data       <= (others =>'0');
    snd_cs         <= '0';
    snd_bdir       <= '0';
    snd_bc1        <= '0';
    PWM_OUT_o      <= '0';
    wav_cnt        <= 0;
    wav_en         <= '0';
  end generate;

  impl_SPI: if use_spi_c generate 
--    spi_cs <= (not nIORQ and not nIORQ_d) when Addr(7 downto 1)=SPI_BASE_ADDR_c(7 downto 1) else -- 0x00 - 0x01
    spi_cs <= IORQ when Addr(7 downto 1)=SPI_BASE_ADDR_c(7 downto 1) else -- 0x00 - 0x01
              '0';
    
    SPI : SPI_Interface
      port map (
        reset_n_i   => reset_n,
        clk_i       => clk_i,
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
      SD_SCK_o <= SD_SCK_s;
      SD_nCS_o <= SD_nCS_s(1 downto 0);
      SD_MOSI_o <= SD_MOSI_s;
      SD_MISO_s <= ETH_MISO_i when SD_nCS_s(2)='0' else
                   SD_MISO_i;
      --SD_MISO_s <= SD_MISO_i;
      -- duplicate SPI pins to decouple SD-cards and Ethernet controller electrically
      ETH_SCK_o  <= SD_SCK_s;
      ETH_nCS_o  <= SD_nCS_s(2);
      ETH_MOSI_o <= SD_MOSI_s;
  end generate;
  no_spi: if not use_spi_c generate
    spi_data       <= (others =>'0');
    spi_cs         <= '0';
    SD_SCK_o       <= '0';
    SD_nCS_o       <= (others => '1');
    SD_MOSI_o      <= SD_MISO_i;
    ETH_SCK_o      <= SD_SCK_s;
    ETH_nCS_o      <= '1';
    ETH_MOSI_o     <= ETH_MISO_i;
  end generate;
  
  impl_T1: if use_timer_c generate 
--    t1_cs <= (not nIORQ and not nIORQ_d) when Addr(7 downto 2)=T1_BASE_ADDR_c(7 downto 2) else -- 0x00 - 0x01
    t1_cs <= IORQ when Addr(7 downto 2)=T1_BASE_ADDR_c(7 downto 2) else -- 0x00 - 0x01
              '0';
    
    T1 : Timer
      port map (
        reset_n_i   => reset_n,
        clk_i       => clk_i,
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
--        clk_i       => clk_i,
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
  
  impl_GPIO: if use_gpio_c generate 
--    vdip_cs <= (not nIORQ and not nIORQ_d) when Addr(7 downto 2)=VDIP_BASE_ADDR_c(7 downto 2) else -- 0x20 - 0x23
    gpio_cs <= IORQ when Addr(7 downto 1)=GPIO_BASE_ADDR_c(7 downto 1) else -- 0x04 - 0x05
                '0';
    
  GPIO : GPIO_Interface
      port map (
        reset_n_i   => reset_n,
        clk_i       => clk_i,
        GPIO_io     => GPIO_io,
        Adr_i       => Addr(0 downto 0),
        en_i        => gpio_cs,
        DataIn_i    => data_in,
        Rd_i        => gdp_Rd,
        Wr_i        => gdp_Wr,
        DataOut_o   => gpio_data
      );
  end generate;
  no_gpio: if not use_gpio_c generate
    gpio_data       <= (others =>'0');
    gpio_cs         <= '0';
    GPIO_io         <= (others =>'Z');
  end generate;
  
--  gdp_cs <= '1' when (CPUEN and not IORq_n)='1' and Cpu_A(7 downto 5) = "011" else
--            '0';
  SRAM1_ADR <= GDP_SRAM_ADDR after 1 ns;
  SRAM1_DB  <= std_logic_vector(GDP_SRAM_datao) after 1 ns when ((GDP_SRAM_ena(0) or GDP_SRAM_ena(1)) and GDP_SRAM_we)='1' else
               (others => 'Z') after 1 ns;
  GDP_SRAM_datai <= std_ulogic_vector(SRAM1_DB);
  SRAM1_nCS      <= not GDP_SRAM_ena(0); -- and not clk);
  SRAM1_nCS1     <= not GDP_SRAM_ena(1);

--  sim_ram : if sim_g generate
--    SRAM1_nOE      <= not (GDP_SRAM_ena and not GDP_SRAM_we and not clk);
--    SRAM1_nWR      <= not (GDP_SRAM_we and not clk);
    SRAM1_nWR      <= not (GDP_SRAM_we and not clk_i);
--  end generate;
--  rtl_ram : if not sim_g generate
    SRAM1_nOE      <= not ((GDP_SRAM_ena(0) or GDP_SRAM_ena(1)) and not GDP_SRAM_we);
--    SRAM1_nWR      <= not (GDP_SRAM_we);
--  end generate;
  
--  Red_o   <= (others => VGA_pixel);
--  Green_o <= (others => VGA_pixel);
--  Blue_o  <= (others => VGA_pixel);

  nIRQ_o <= '0' when (t1_irq or ser_int)='1' else
            'Z';
--  sample_clk_o  <= clk_i;
end rtl;
