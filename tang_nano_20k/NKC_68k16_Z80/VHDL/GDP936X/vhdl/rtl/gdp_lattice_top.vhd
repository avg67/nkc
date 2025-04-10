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
       --------------------------
       -- UART
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
       -- Video out
       --------------------------
       Red_o      : out std_logic_vector(2 downto 0);
       Green_o    : out std_logic_vector(2 downto 0);
       Blue_o     : out std_logic_vector(2 downto 0);
       Hsync_o    : out std_ulogic;
       Vsync_o    : out std_ulogic;
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
       -- Floppy Interface
       --------------------------
       FDD_RDn      : in  std_ulogic; -- (30)
       FDD_TR00n    : in  std_ulogic; -- (26) nTK0
       FDD_IPn      : in  std_ulogic; -- (8) nIndex
       FDD_WPRTn    : in  std_ulogic; -- (28) nWriteProtect

       FDD_MOn      : out std_ulogic; -- (16) Motor on      Open drain
       FDD_WGn      : out std_ulogic; -- (24) Write Gate    Open drain.
       FDD_WDn      : out std_ulogic; -- (22) Write Data    Open drain
       FDD_STEPn    : out std_ulogic; -- (20) Open drain
       FDD_DIRCn    : out std_ulogic; -- (18) Open drain
       FDD_DSELn    : out std_ulogic_vector(1 downto 0); -- (6,14,12,10)
       FDD_SDSEL    : out std_ulogic; -- (2) Dense (DD / HD)
       FDD_SIDE     : out std_ulogic; -- (32) Side          Open drain
       --------------------------
       -- Debug Signals - Flo
       --------------------------
--       debug_clk  : out std_ulogic;
--       debug_lock : out std_ulogic
--       debug_o  : out std_ulogic_vector(nr_mon_sigs_c-1 downto 0)
       debug_o  : out std_ulogic_vector(8 downto 0)
     );
end gdp_lattice_top;

architecture rtl of gdp_lattice_top is
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
         DataIn_i  : in  std_ulogic_vector(7 downto 0);
         Rd_i      : in  std_ulogic;
         Wr_i      : in  std_ulogic;
         DataOut_o : out std_ulogic_vector(7 downto 0);
         --------------------------
         -- Video out
         --------------------------
         pixel_o    : out std_ulogic;
         Hsync_o    : out std_ulogic;
         Vsync_o    : out std_ulogic;
         --------------------------
         -- Video-Memory data bus
         --------------------------
         sram_addr_o : out std_ulogic_vector(15 downto 0);
         sram_data_o : out std_ulogic_vector(7 downto 0);
         sram_data_i : in  std_ulogic_vector(7 downto 0);
         sram_ena_o  : out std_ulogic;
         sram_we_o   : out std_ulogic;
         rom_ena_o   : out std_ulogic;
         --------------------------
         -- Monitoring (Debug) signals
         --------------------------
         monitoring_o : out std_ulogic_vector(nr_mon_sigs_c-1 downto 0)
         );
  end component;
  
  component flo2_top
    generic(emu_g : boolean := false);
    port(reset_n_i     : in  std_ulogic;
         clk_i         : in  std_ulogic;
         Adr_i     : in  std_ulogic_vector(7 downto 0);
         CS_i      : in  std_ulogic;
         DataIn_i  : in  std_ulogic_vector(7 downto 0);
         Rd_i      : in  std_ulogic;
         Wr_i      : in  std_ulogic;
         DataOut_o : out std_ulogic_vector(7 downto 0);
         Int_n_o   : out std_ulogic;
         FDD_RDn      : in  std_ulogic; -- (30)
         FDD_TR00n    : in  std_ulogic; -- (26) nTK0
         FDD_IPn      : in  std_ulogic; -- (8) nIndex
         FDD_WPRTn    : in  std_ulogic; -- (28) nWriteProtect
  
         FDD_MOn      : out std_ulogic; -- (16) Motor on      Open drain
         FDD_WGn      : out std_ulogic; -- (24) Write Gate    Open drain.
         FDD_WDn      : out std_ulogic; -- (22) Write Data    Open drain
         FDD_STEPn    : out std_ulogic; -- (20) Open drain
         FDD_DIRCn    : out std_ulogic; -- (18) Open drain
         FDD_DSELn    : out std_ulogic_vector(3 downto 0); -- (6,14,12,10)
         FDD_SDSEL    : out std_ulogic; -- (2) Dense (DD / HD)
         FDD_SIDE     : out std_ulogic;  -- (32) Side          Open drain
         monitoring_o : out std_ulogic_vector(7 downto 0)
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
  
--  component Receiver
--    port (
--      clk        : in  std_ulogic;
--      clr_n      : in  std_ulogic;
--      RxD        : in  std_ulogic;
--      Busy       : in  std_ulogic;
--      DoutPar    : out std_ulogic_vector(7 downto 0);
--      DataValid  : out std_ulogic;
--      ErrorFlags : out std_ulogic_vector(1 downto 0));
--  end component;
  
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
  component pll
    port (CLK: in std_logic; RESET: in std_logic; CLKOP: out std_logic; 
        CLKOK: out std_logic; LOCK: out std_logic);
  end component;
  
  component clk_gate
    port(
      clk_i    : in  std_ulogic; -- clock input
      en_i     : in  std_ulogic; -- clock enable signal
      clk_o    : out std_ulogic  -- gated clock
    );
  end component;
  
  constant use_ser_key_c : boolean := false;
  constant use_ps2_key_c : boolean := true;
  constant use_ps2_mouse_c : boolean := true;
  constant use_ser1_c      : boolean := true;
  constant dipswitches_c : std_logic_vector(7 downto 0) := X"09"; -- GDP64HS
--  constant dipswitches1_c : std_logic_vector(7 downto 0) := X"01"; -- GDP64
  
  constant GDP_BASE_ADDR_c  : std_ulogic_vector(7 downto 0) := X"70"; -- r/w
  constant SFR_BASE_ADDR_c  : std_ulogic_vector(7 downto 0) := X"60"; -- w  
  constant KEY_BASE_ADDR_c  : std_ulogic_vector(7 downto 0) := X"68"; -- r  
  constant DIP_BASE_ADDR_c  : std_ulogic_vector(7 downto 0) := X"69"; -- r  
  constant MOUSE_BASE_ADDR_c  : std_ulogic_vector(7 downto 0) := X"88"; -- r/w  
  constant SER_BASE_ADDR_c    : std_ulogic_vector(7 downto 0) := X"F0"; -- r/w  
  constant SOUND_BASE_ADDR_c  : std_ulogic_vector(7 downto 0) := X"50"; -- r/w  
  
--  constant GDP_BASE_ADDR1_c  : std_ulogic_vector(7 downto 0) := X"50"; -- r/w
--  constant SFR_BASE_ADDR1_c  : std_ulogic_vector(7 downto 0) := X"40"; -- w
--  constant KEY_BASE_ADDR1_c  : std_ulogic_vector(7 downto 0) := X"48"; -- r
--  constant DIP_BASE_ADDR1_c  : std_ulogic_vector(7 downto 0) := X"49"; -- r
  
  signal reset_n           : std_ulogic;
  signal GDP_SRAM_ADDR     : std_ulogic_vector(15 downto 0);
  signal GDP_SRAM_datao    : std_ulogic_vector(7 downto 0);
  signal GDP_DataOut       : std_ulogic_vector(7 downto 0);
  signal GDP_SRAM_datai    : std_ulogic_vector(7 downto 0);
  signal GDP_SRAM_ena      : std_ulogic;
  signal GDP_SRAM_we       : std_ulogic;
  signal VGA_pixel         : std_ulogic;
  signal gdp_Rd,gdp_Wr     : std_ulogic;
  signal gdp_cs            : std_ulogic;
  signal gdp_en,sfr_en     : std_ulogic;

  signal nIORQ,nIORQ_d     : std_ulogic;
  signal nRD,nRD_d         : std_ulogic;
  signal nWR,nWR_d         : std_ulogic;
  signal Addr              : std_ulogic_vector(7 downto 0);
  signal data_in           : std_ulogic_vector(7 downto 0);
  signal output_en         : std_ulogic;
  signal key_cs,dip_cs     : std_ulogic;
  signal mouse_cs          : std_ulogic;
  signal ser_cs            : std_ulogic;
  
  
  signal BusyRX              : std_ulogic;
  signal DoutParRX,key_data  : std_ulogic_vector(7 downto 0);
  signal DataValidRX         : std_ulogic;
  signal OldDataValidRX      : std_ulogic;
  signal gdp_base,sfr_base,key_base,dip_base : std_ulogic_vector(7 downto 0);        
  signal dipsw             : std_logic_vector(7 downto 0);
  signal mouse_data        : std_ulogic_vector(7 downto 0); 
  signal ser_data          : std_ulogic_vector(7 downto 0);
  signal pll_locked        : std_ulogic;
  signal reset_n_async     : std_ulogic;
  signal clk_80MHz,gdp_clk : std_ulogic;
  
  signal cycle_cnt_16        : natural range 0 to 4;
  signal clk_16              : std_ulogic;
  signal clk_en_16,clk_en_40 : std_ulogic;
  signal flo_addr            : std_ulogic;
  signal output_en_flo       : std_ulogic;
  signal flo_DataOut         : std_ulogic_vector(7 downto 0); 

  signal flo_Int_n           : std_ulogic;
  signal clk_debug           : std_ulogic;
  signal FDD_DSELni          : std_ulogic_vector(3 downto 0); 
  
begin

  pll_inst : pll
    port map (
      CLK   => clk_i, 
      RESET => '0', 
      CLKOP => clk_80MHz, 
      CLKOK => open, --gdp_clk,  -- 40 MHz
      LOCK  => pll_locked
    );
  reset_n_async <= reset_n_i and pll_locked;

--  debug_clk  <= clk_16;
--  debug_lock <= pll_locked;

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

  reset_sync: process(clk_80MHz)
    variable tmp_v : std_ulogic_vector(1 downto 0);
  begin
    if rising_edge(clk_80MHz) then
      reset_n  <= tmp_v(1);
      tmp_v(1) := tmp_v(0);
      tmp_v(0) := reset_n_async;
    end if;
  end process reset_sync;

  process(clk_80MHz,reset_n)
  begin
    if reset_n = '0' then
      clk_en_40 <= '0';
      clk_en_16 <= '0';
      cycle_cnt_16 <= 0;
    elsif rising_edge(clk_80MHz) then
      clk_en_40 <= not clk_en_40;
      clk_en_16 <= '0';
      if cycle_cnt_16 /= 4 then
        cycle_cnt_16 <= cycle_cnt_16 +1;
      else
        cycle_cnt_16 <= 0;
        clk_en_16    <= '1';
      end if;
    end if;
  end process;

  clkgate1: clk_gate
    port map(
      clk_i  => clk_80MHz,
      en_i   => clk_en_40,
      clk_o  => gdp_clk
    );

  clkgate2: clk_gate
    port map(
      clk_i  => clk_80MHz,
      en_i   => clk_en_16,
      clk_o  => clk_16
    );
  
  ISIORQ : InputSync
  generic map (
    ResetValue_g => '1'
  )
  port map (
      Input => nkc_nIORQ_i,
      clk   => gdp_clk,
      clr_n => Reset_n,
      q     => nIORQ);
      
  ISRD : InputSync
  generic map (
    ResetValue_g => '1'
  )
  port map (
      Input => nkc_nRD_i,
      clk   => gdp_clk,
      clr_n => Reset_n,
      q     => nRD);
      
  ISWR : InputSync
  generic map (
    ResetValue_g => '1'
  )
  port map (
      Input => nkc_nWR_i,
      clk   => gdp_clk,
      clr_n => Reset_n,
      q     => nWR);
  
  process(gdp_clk,reset_n)
  begin
    if reset_n = '0' then
      nIORQ_d      <= '1';
      nRD_d        <= '1';
      nWR_d        <= '1';
      gdp_Rd       <= '0';
      gdp_Wr       <= '0';
      Addr         <= (others => '0');
      data_in      <= (others => '0');
      output_en    <= '0';
    elsif rising_edge(gdp_clk) then
      nIORQ_d      <= nIORQ; -- for edge detection
      nWR_d        <= '1';
      nRD_d        <= '1';
      output_en    <= gdp_cs or key_cs or dip_cs or mouse_cs or ser_cs; -- or flo_addr;
      
      gdp_Rd  <= '0';
      gdp_Wr  <= '0';
      if nIORQ = '0' then
        if nIORQ_d = '1' then
          -- IORQ  had an falling edge.
          -- Store Address
          Addr <= nkc_ADDR_i;
        elsif output_en = '1' or nRD = '0' then
          nWR_d  <= nWR;
          nRD_d  <= nRD;
          gdp_Rd <= not nRD and nRD_d;
          if (not nWR and nWR_d)='1' then
            data_in <= std_ulogic_vector(nkc_DB);
            gdp_Wr  <= '1';
          end if;
        end if;
      end if;
    end if;
  end process;

  driver_nEN_o <= not((output_en or output_en_flo) and (not nkc_nWR_i or not nkc_nRD_i)); 
  driver_DIR_o <= nRD;
  nkc_DB       <= std_logic_vector(GDP_DataOut) when (output_en     and gdp_cs   and not nkc_nRD_i)='1' else
                  std_logic_vector(key_data)    when (output_en     and key_cs   and not nkc_nRD_i)='1' else
	                dipsw                         when (output_en     and dip_cs   and not nkc_nRD_i)='1' else
	                std_logic_vector(mouse_data)  when (output_en     and mouse_cs and not nkc_nRD_i)='1' else
	                std_logic_vector(ser_data)    when (output_en     and ser_cs   and not nkc_nRD_i)='1' else
	                std_logic_vector(flo_DataOut) when (output_en_flo and flo_addr and not nkc_nRD_i)='1' else
                  (others => 'Z') after 1 ns;
  
      
  GDP: gdp_top
    port map (
      reset_n_i   => reset_n,
      clk_i       => gdp_clk,
      clk_en_i    => '1',
      Adr_i       => Addr(3 downto 0),
--      CS_i        => gdp_cs,
      gdp_en_i    => gdp_en,
      sfr_en_i    => sfr_en,
      DataIn_i    => data_in,
      Rd_i        => gdp_Rd,
      Wr_i        => gdp_Wr,
      DataOut_o   => GDP_DataOut,
      pixel_o     => VGA_pixel,
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

  gdp_cs <= (not nIORQ and not nIORQ_d) when  Addr(7 downto 4) = gdp_base(7 downto 4)  or  -- GDP
                                             (Addr(7 downto 1) = sfr_base(7 downto 1)) else -- SFRs
            '0';
  
  gdp_en <= gdp_cs when Addr(7 downto 4) = gdp_base(7 downto 4) else
            '0';
  sfr_en <= gdp_cs when Addr(7 downto 4) = sfr_base(7 downto 4) else
            '0';
  key_cs <= (not nIORQ and not nIORQ_d) when Addr = key_base and nRD='0' else
            '0';
  dip_cs <= (not nIORQ and not nIORQ_d) when Addr = dip_base and nRD='0' else
            '0';

--  impl_key1: if use_ser_key_c generate
--              
--    Rx: Receiver
--      port map (
--        clk        => gdp_clk,
--        clr_n      => reset_n,
--        RxD        => RxD_i,
--        Busy       => BusyRX,
--        DoutPar    => DoutParRX,
--        DataValid  => DataValidRX,
--        ErrorFlags => open);
--    
--    process(gdp_clk,reset_n)
--  --    variable access_v : std_ulogic;
--    begin
--      if reset_n = '0' then
--        BusyRX <= '1';
--        OldDataValidRX <= '0';
--  --      access_v       := '0';
--      elsif rising_edge(gdp_clk) then
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
        clk_i     => gdp_clk,
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
    mouse_cs <= (not nIORQ and not nIORQ_d) when Addr(7 downto 3)=MOUSE_BASE_ADDR_c(7 downto 3) else
                 '0';
    mouse : PS2Mouse
      port map (
        reset_n_i    => reset_n,
        clk_i        => gdp_clk,
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
    ser_cs <= (not nIORQ and not nIORQ_d) when Addr(7 downto 2)=SER_BASE_ADDR_c(7 downto 2) else -- 0xF0 - 0xF3
              '0';
    
    ser : Ser1
      port map (
        reset_n_i   => reset_n,
        clk_i       => gdp_clk,
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
        Intr_o      => open
      );
  end generate;
  no_ser1: if not use_ser1_c generate
    ser_data       <= (others =>'0');
    ser_cs         <= '0';
    RTS_o          <= CTS_i;
    TxD_o          <= RxD_i;
  end generate;      
  
  
--  debug_o <= key_data;  
  
--  gdp_cs <= '1' when (CPUEN and not IORq_n)='1' and Cpu_A(7 downto 5) = "011" else
--            '0';
  SRAM1_ADR <= "0" & GDP_SRAM_ADDR after 1 ns;
  SRAM1_DB  <= std_logic_vector(GDP_SRAM_datao) after 1 ns when (GDP_SRAM_ena and GDP_SRAM_we)='1' else
               (others => 'Z') after 1 ns;
  GDP_SRAM_datai <= std_ulogic_vector(SRAM1_DB);

  SRAM1_nCS      <= not GDP_SRAM_ena; -- and not clk);
  SRAM1_nCS1     <= '1';

--  sim_ram : if sim_g generate
--    SRAM1_nOE      <= not (GDP_SRAM_ena and not GDP_SRAM_we and not clk);
--    SRAM1_nWR      <= not (GDP_SRAM_we and not gdp_clk);
    SRAM1_nWR      <= not (GDP_SRAM_we and clk_en_40);
    
--  end generate;
--  rtl_ram : if not sim_g generate
    SRAM1_nOE      <= not (GDP_SRAM_ena and not GDP_SRAM_we);
--    SRAM1_nWR      <= not (GDP_SRAM_we);
--  end generate;
  
  Red_o   <= (others => VGA_pixel);
  Green_o <= (others => VGA_pixel);
  Blue_o  <= (others => VGA_pixel);


  floppy: block
    signal addr_flo              : std_ulogic_vector(7 downto 0);  
    signal data_in_flo           : std_ulogic_vector(7 downto 0);
    signal flo_cs,flo_rd,flo_wr  : std_ulogic;
    signal nRD_flo_d, nWR_flo_d  : std_ulogic;
    signal nRD_flo,nWR_flo       : std_ulogic;
    signal nIORQ_flo,nIORQ_flo_d : std_ulogic;
  begin
    ISIORQ_f : InputSync
    generic map (
      ResetValue_g => '1'
    )
    port map (
        Input => nkc_nIORQ_i,
        clk   => clk_16,
        clr_n => Reset_n,
        q     => nIORQ_flo);
        
    ISRD_f : InputSync
    generic map (
      ResetValue_g => '1'
    )
    port map (
        Input => nkc_nRD_i,
        clk   => clk_16,
        clr_n => Reset_n,
        q     => nRD_flo);
        
    ISWR_f : InputSync
    generic map (
      ResetValue_g => '1'
    )
    port map (
        Input => nkc_nWR_i,
        clk   => clk_16,
        clr_n => Reset_n,
        q     => nWR_flo);
    
    process(clk_16,reset_n)
    begin
      if reset_n = '0' then
        nIORQ_flo_d   <= '1';
        nRD_flo_d     <= '1';
        nWR_flo_d     <= '1';
        flo_Rd        <= '0';
        flo_Wr        <= '0';
        Addr_flo      <= (others => '0');
        data_in_flo   <= (others => '0');
        output_en_flo <= '0';
      elsif rising_edge(clk_16) then
        nIORQ_flo_d      <= nIORQ_flo; -- for edge detection
        nWR_flo_d        <= '1';
        nRD_flo_d        <= '1';
        output_en_flo    <= flo_addr;
        
        flo_Rd  <= '0';
        flo_Wr  <= '0';
        if nIORQ_flo = '0' then
          if nIORQ_flo_d = '1' then
            -- IORQ  had an falling edge.
            -- Store Address
            Addr_flo <= nkc_ADDR_i;
          elsif output_en_flo = '1' or nRD_flo = '0' then
            nWR_flo_d  <= nWR_flo;
            nRD_flo_d  <= nRD_flo;
            flo_Rd <= not nRD_flo and nRD_flo_d;
            if (not nWR_flo and nWR_flo_d)='1' then
              data_in_flo <= std_ulogic_vector(nkc_DB);
              flo_Wr      <= '1';
            end if;
          end if;
        end if;
      end if;
    end process;

  flo2: flo2_top
  generic map (emu_g => false)
  port map (
       reset_n_i => reset_n,
       clk_i     => clk_16,

       Adr_i     => addr_flo(7 downto 0),
       CS_i      => flo_cs,
       DataIn_i  => data_in_flo,
       Rd_i      => flo_rd,
       Wr_i      => flo_wr,
       DataOut_o => flo_DataOut,
       Int_n_o   => flo_Int_n,

       FDD_RDn   => FDD_RDn,
       FDD_TR00n => FDD_TR00n,
       FDD_IPn   => FDD_IPn,
       FDD_WPRTn => FDD_WPRTn,
                             
       FDD_MOn   => FDD_MOn,
       FDD_WGn   => FDD_WGn,
       FDD_WDn   => FDD_WDn,
       FDD_STEPn => FDD_STEPn,
       FDD_DIRCn => FDD_DIRCn,
       FDD_DSELn => FDD_DSELni,
--       FDD_DSELn(3 downto 2) => open,
       FDD_SDSEL => FDD_SDSEL,
       FDD_SIDE  => FDD_SIDE,
       monitoring_o => debug_o(7 downto 0)
     );

    FDD_DSELn <= FDD_DSELni(FDD_DSELn'range);
--    FDD_DSELn <= FDD_DSELni(0) & FDD_DSELni(1); -- swap drive 0 and 1

    flo_addr <= (not nIORQ_flo and not nIORQ_flo_d) when addr_flo(7 downto 4)="1100" else
                 '0';

    flo_cs <= not nIORQ_flo when addr_flo(7 downto 4) = "1100" else 
              '0';
  
--    flo_Rd <= not nRD and not nRD_d and not flo_rd_d;
--    flo_Wr <= not nWR and not nWR_d and not flo_wr_d;
--      flo_Rd      <= not nRD_flo and nRD_flo_d;
--      flo_Wr      <= not nWR_flo and nWR_flo_d;


--    flo_cs <= flo_addr and (flo_Rd or flo_Wr);

--    process(clk_16,reset_n)
--    begin
--      if reset_n = '0' then
--        clk_debug <= '0';
--        nRD_flo_d <= '1';
--        nWR_flo_d <= '1';
--        nRD_flo   <= '1';
--        nWR_flo   <= '1';
--        nIORQ_flo <= '1';
--        data_in_flo <= (others => '0');
--        addr_flo    <= (others => '0');
--  --      flo_Rd      <= '0';
--  --      flo_Wr      <= '0';
--  
--      elsif rising_edge(clk_16) then
--        clk_debug  <= not clk_debug;
--        addr_flo    <= Addr(7 downto 0);
--        data_in_flo <= data_in;
--        nIORQ_flo   <= nIORQ;
--        nRD_flo     <= nRD;
--        nWR_flo     <= nWR or nWR_d;
--        nRD_flo_d   <= nRD_flo;
--        nWR_flo_d   <= nWR_flo;
--  
--  
--  --      flo_rd_d <= not nRD and not nRD_d;
--  --      flo_wr_d <= not nWR and not nWR_d;
--      end if;
--    end process;
    debug_o(8) <= flo_Rd;
  end block;

--  debug_o(8) <= clk_debug;
  
end rtl;
