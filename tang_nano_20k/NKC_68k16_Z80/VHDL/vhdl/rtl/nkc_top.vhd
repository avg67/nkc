--------------------------------------------------------------------------------
-- Project     : Single Chip NDR Computer
-- Module      : GDP 936X Display processor - kernel
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

entity nkc_top is
  generic(sim_g      : boolean := false);
  port(reset_i       : in  std_ulogic;
       clk_i         : in  std_ulogic;
       --------------------------
       -- Video out
       --------------------------
       Red_o      : out std_logic_vector(1 downto 0);
       Green_o    : out std_logic_vector(1 downto 0);
       Blue_o     : out std_logic_vector(1 downto 0);
       Hsync_o    : out std_ulogic;
       Vsync_o    : out std_ulogic;
       --------------------------
       -- Video-Memory data bus
       --------------------------
       SRAM1_nCS    : out std_ulogic;
       SRAM1_ADR    : out std_ulogic_vector(17 downto 0);
       SRAM1_DB     : inout std_logic_vector(7 downto 0);
       SRAM1_nWR    : out std_ulogic;
       SRAM1_nOE    : out std_ulogic;
       SRAM1_nBE    : out std_ulogic_vector(1 downto 0);
       --
       RxD_i        : in std_ulogic;
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
       FDD_DSELn    : out std_ulogic_vector(3 downto 0); -- (6,14,12,10)
       FDD_SDSEL    : out std_ulogic; -- (2) Dense (DD / HD)
       FDD_SIDE     : out std_ulogic;  -- (32) Side          Open drain
       
       --------------------------
       -- Z80 data bus
       --------------------------
       SRAM2_nCS    : out std_ulogic;
       SRAM2_ADR    : out std_ulogic_vector(17 downto 0);
       SRAM2_DB     : inout std_logic_vector(7 downto 0);
       SRAM2_nWR    : out std_ulogic;
       SRAM2_nOE    : out std_ulogic;
       SRAM2_nBE    : out std_ulogic_vector(1 downto 0);
       FLASH_nCE    : out std_ulogic;
       FLASH_nWE    : out std_ulogic;
       FLASH_nOE    : out std_ulogic
       );
end nkc_top;


architecture rtl of nkc_top is
  component gru
    PORT
    (
      address   : IN STD_LOGIC_VECTOR (12 DOWNTO 0);
      clock   : IN STD_LOGIC ;
      clken   : IN STD_LOGIC ;
      q   : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
    );
  end component;
  component flomon
    PORT
    (
      address   : IN STD_LOGIC_VECTOR (12 DOWNTO 0);
      clock   : IN STD_LOGIC ;
      clken   : IN STD_LOGIC ;
      q   : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
    );
  end component;
  component RAM
    PORT
    (
      address   : IN STD_LOGIC_VECTOR (12 DOWNTO 0);
      clken   : IN STD_LOGIC ;
      clock   : IN STD_LOGIC ;
      data    : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
      wren    : IN STD_LOGIC ;
      q   : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
    );
  end component;
  component pll_80MHz
    PORT
    (
      areset    : IN STD_LOGIC  := '0';
      inclk0    : IN STD_LOGIC  := '0';
      c0    : OUT STD_LOGIC ;
      locked    : OUT STD_LOGIC 
    );
  end component;
  component clk_gate
    port(
      clk_i    : in  std_ulogic; -- clock input
      en_i     : in  std_ulogic; -- clock enable signal
      clk_o    : out std_ulogic  -- gated clock
    );
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
  
  constant GDP_BASE_ADDR_c  : std_logic_vector(7 downto 0) := X"70"; -- r/w
  constant SFR_BASE_ADDR_c  : std_logic_vector(7 downto 0) := X"60"; -- w  
  constant dipswitches_c : std_logic_vector(7 downto 0)     := X"09";
  
  signal GDP_SRAM_ADDR     : std_ulogic_vector(15 downto 0);
  signal GDP_SRAM_datao    : std_ulogic_vector(7 downto 0);
  signal GDP_DataOut       : std_ulogic_vector(7 downto 0);
  signal GDP_SRAM_datai    : std_ulogic_vector(7 downto 0);
  signal GDP_SRAM_ena      : std_ulogic;
  signal GDP_SRAM_we       : std_ulogic;
  signal VGA_pixel         : std_ulogic;
  signal gdp_Rd,gdp_Wr     : std_ulogic;
  signal gdp_addr          : std_ulogic;
  signal gdp_en,sfr_en     : std_ulogic;
  signal RAMCS_n,ROMCS_n   : std_ulogic;
  signal rom_data,ram_data : std_logic_vector(7 downto 0);
  signal DI_CPU,DO_CPU     : std_logic_vector(7 downto 0);
  signal Cpu_A             : std_logic_vector(15 downto 0);
  signal MReq_n            : std_logic;
  signal IORq_n            : std_logic;
  signal Rd_n,ram_wren     : std_logic;
  signal Wr_n,CPUEN        : std_logic;
  signal Rd_nd,Wr_nd       : std_logic;
  signal cycle_cnt         : natural range 0 to 4;
  signal cycle_cnt_16      : natural range 0 to 4;
  signal clk_en_40         : std_ulogic;
  signal pll_locked        : std_ulogic;
  signal clk,reset_n       : std_ulogic;
  signal reset_n_async     : std_ulogic;

  signal BusyRX              : std_ulogic;
  signal DoutParRX,key_data  : std_ulogic_vector(7 downto 0);
  signal DataValidRX         : std_ulogic;
  signal OldDataValidRX      : std_ulogic;
  signal clk_gated,clk_16    : std_ulogic;
  signal clk_en_16           : std_ulogic;
  
  signal flo_addr            : std_ulogic;
  signal flo_DataOut         : std_ulogic_vector(7 downto 0); 
  signal flo_cs,flo_rd,flo_wr: std_ulogic;
  signal flo_rd_d, flo_wr_d  : std_ulogic;
  signal flo_Int_n           : std_ulogic;
  
  -- bank/boot specific signals
  signal bank_reg     : std_ulogic_vector(7 downto 0);
  signal banken       : std_ulogic;
  signal Ext_RAMCS_n  : std_ulogic;
  
begin
 fpga : if not sim_g generate
   pll : pll_80MHz
      PORT map
      (
        areset => '0',  
        inclk0 => Clk_i,
        c0     => Clk,
        locked => pll_locked
      );
    
    reset_n_async <= not reset_i and pll_locked;
  end generate;
  sim : if sim_g generate
    Clk           <= Clk_i;
    reset_n_async <= not reset_i;
  end generate;

  process(Clk)
    variable tmp_v : std_ulogic_vector(1 downto 0);
  begin
    if rising_edge(Clk) then
      reset_n <= tmp_v(1);
      tmp_v(1) := tmp_v(0);
      tmp_v(0) := reset_n_async;
    end if;
  end process;


  process(Clk,reset_n)
  begin
    if reset_n = '0' then
      clk_en_40 <= '0';
      clk_en_16 <= '0';
      cycle_cnt_16 <= 0;
    elsif rising_edge(Clk) then
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

--  clk_gated <= Clk and clk_en_40;
  clkgate1: clk_gate
    port map(
      clk_i  => Clk,
      en_i   => clk_en_40,
      clk_o  => clk_gated
    );
  clkgate2: clk_gate
    port map(
      clk_i  => Clk,
      en_i   => clk_en_16,
      clk_o  => clk_16
    );
    

  process(clk_gated,reset_n)
  begin
    if reset_n = '0' then
      cycle_cnt <= 0;
      CPUEN     <= '0';
    elsif rising_edge(clk_gated) then
      CPUEN <= '0';
      if cycle_cnt /= 4 then
        cycle_cnt <= cycle_cnt +1;
      else
        cycle_cnt <= 0;
        CPUEN     <= '1';
      end if;
    end if;
  end process;

  rom_inst: flomon --gru
    PORT map
    (
      address   => Cpu_A(12 downto 0),
      clock     => clk_gated,
      clken     => CPUEN,
      q         => rom_data
    );

  ram_inst: ram
    PORT map
    (
      address   => Cpu_A(12 downto 0),
      clock     => clk_gated,
      clken     => CPUEN,
      data      => DO_CPU,
      wren      => ram_wren,
      q         => ram_data
    );

  -- bank/boot register
  process(clk_gated,reset_n)
  begin
    if reset_n = '0' then
      bank_reg <= (others => '0');
    elsif rising_edge(clk_gated) then
      if (CPUEN and not IORq_n and not Wr_n)='1' and 
        Cpu_A(7 downto 0) = X"C8" then
        bank_reg <= std_ulogic_vector(DO_CPU);
      end if;  
    end if;
  end process;
  
  banken <= bank_reg(7) or Cpu_A(15);


  Z80: entity work.T80se
    generic map (Mode => 0, T2Write => 1)
    port map (
      CLK_n   => clk_gated,
      CLKEN   => CPUEN,
      RESET_n => reset_n,
      M1_n    => open,
      MREQ_n  => MReq_n,
      IORQ_n  => IORq_n,
      RD_n    => Rd_n,
      WR_n    => Wr_n,
      RFSH_n  => open,
      HALT_n  => open,
      WAIT_n  => '1',
      INT_n   => flo_Int_n,
      NMI_n   => '1',
      BUSRQ_n => '1',
      BUSAK_n => open,
      A       => Cpu_A,
      DI      => DI_CPU,
      DO      => DO_CPU);
      
  DI_CPU <= std_logic_vector(GDP_DataOut) when gdp_addr='1' else
            rom_data                      when ROMCS_n='0' else
            ram_data                      when RAMCS_n='0' else
            std_logic_vector(key_data)    when IORq_n='0' and Cpu_A(7 downto 0) = X"68" else
            dipswitches_c                 when IORq_n='0' and Cpu_A(7 downto 0) = X"69" else
            std_logic_vector(flo_DataOut) when flo_addr='1' else
            SRAM2_DB                      when Ext_RAMCS_n='0' else
            (others => '1');
            

  gdp_addr <= not IORq_n when  Cpu_A(7 downto 4) = GDP_BASE_ADDR_c(7 downto 4) or  -- GDP
                              (Cpu_A(7 downto 4) = SFR_BASE_ADDR_c(7 downto 4) and Wr_n='0')  else -- SFRs
              '0';
    
  GDP: entity work.gdp_top
    port map (
      reset_n_i   => reset_n,
      clk_i       => clk_gated,
      clk_en_i    => '1',
      Adr_i       => std_ulogic_vector(Cpu_A(3 downto 0)),
--      CS_i        => gdp_cs,
      gdp_en_i    => gdp_en,
      sfr_en_i    => sfr_en,
      DataIn_i    => std_ulogic_vector(DO_CPU),
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
      sram_we_o   => GDP_SRAM_we);
  
  process(clk_gated,reset_n)
  begin
    if reset_n = '0' then
      Rd_nd <= '1';
      Wr_nd <= '1';
    elsif rising_edge(clk_gated) then
      if CPUEN  ='1' then
        Rd_nd <= Rd_n;
        Wr_nd <= Wr_n;
      end if;  
    end if;
  end process;
  
  
  
  gdp_Rd <= not Rd_n and Rd_nd and CPUEN;
  gdp_Wr <= not Wr_n and Wr_nd and CPUEN;
  
--  gdp_cs <= '1' when (CPUEN and not IORq_n)='1' and Cpu_A(7 downto 5) = "011" else
--            '0';
--  gdp_cs <= CPUEN and gdp_addr;
  gdp_en <= (CPUEN and not IORq_n) when Cpu_A(7 downto 4) = GDP_BASE_ADDR_c(7 downto 4) else
            '0';
  sfr_en <= (CPUEN and not IORq_n) when Cpu_A(7 downto 4) = SFR_BASE_ADDR_c(7 downto 4) and Wr_n='0' else
            '0';


  SRAM1_ADR <= "00" & GDP_SRAM_ADDR after 1 ns;
  SRAM1_DB  <= std_logic_vector(GDP_SRAM_datao) after 1 ns when (GDP_SRAM_ena and GDP_SRAM_we)='1' else
               (others => 'Z') after 1 ns;
  GDP_SRAM_datai <= std_ulogic_vector(SRAM1_DB);
  SRAM1_nCS      <= not GDP_SRAM_ena; -- and not clk);

--  sim_ram : if sim_g generate
--    SRAM1_nOE      <= not (GDP_SRAM_ena and not GDP_SRAM_we and not clk);
--    SRAM1_nWR      <= not (GDP_SRAM_we and not clk);
    SRAM1_nWR      <= not (GDP_SRAM_we and clk_en_40);
--  end generate;
--  rtl_ram : if not sim_g generate
    SRAM1_nOE      <= not (GDP_SRAM_ena and not GDP_SRAM_we);
--    SRAM1_nWR      <= not (GDP_SRAM_we);
--  end generate;
  SRAM1_nBE      <= "1" & not GDP_SRAM_ena;
  
  -- Bank/Boot-ROM 0x0000 - 0x1fff
  ROMCS_n   <= '0' when (Cpu_A(15 downto 13)="000") and MReq_n = '0' and banken='0' else '1';

--  RAMCS_n   <= '0' when (Cpu_A(15 downto 14)="10") and MReq_n = '0' else '1';
  -- Bank/Boot-Ram 0x6000 - 0x7fff
  RAMCS_n     <= '0' when (Cpu_A(15 downto 13)="011") and MReq_n = '0' and banken='0' else '1';
  Ext_RAMCS_n <= '0' when (banken and not MReq_n)='1' and bank_reg(3 downto 0)=X"0" else
                 '1';
  
  ram_wren  <= not Wr_n and not RAMCS_n;
  
  
  SRAM2_ADR <= "00" & std_ulogic_vector(Cpu_A) after 1 ns;
  SRAM2_DB  <= DO_CPU after 1 ns when (not Ext_RAMCS_n and not Wr_n)='1' else
               (others => 'Z') after 1 ns;
  SRAM2_nWR <= Wr_n;
  SRAM2_nCS <= Ext_RAMCS_n;
  SRAM2_nOE <= Rd_n;
  SRAM2_nBE <= "1" & Ext_RAMCS_n;
  FLASH_nCE <= '1';
  FLASH_nWE <= '1';
  FLASH_nOE <= '1';
  
  Red_o   <= (others => VGA_pixel);
  Green_o <= (others => VGA_pixel);
  Blue_o  <= (others => VGA_pixel);

    
  Rx: Receiver
    port map (
      clk        => clk_gated,
      clr_n      => reset_n,
      RxD        => RxD_i,
      Busy       => BusyRX,
      DoutPar    => DoutParRX,
      DataValid  => DataValidRX,
      ErrorFlags => open);
  
  key_data <= not BusyRX & DoutParRX(6 downto 0);
  
  process(clk_gated,reset_n)
  begin
    if reset_n = '0' then
      BusyRX <= '0';
      OldDataValidRX <= '0';
    elsif rising_edge(clk_gated) then
      OldDataValidRX <= DataValidRX;
      if (not OldDataValidRX and DataValidRX)= '1' then
        BusyRX <= '1';
      end if;
      if (CPUEN and not IORq_n and not Rd_n)='1' and 
         Cpu_A(7 downto 0) = X"69" then
        BusyRX <= '0';
      end if;  
    end if;
  end process;
  
  flo2: entity work.flo2_top
  port map (
       reset_n_i => reset_n,
       clk_i     => clk_16,

       Adr_i     => std_ulogic_vector(Cpu_A(7 downto 0)),
       CS_i      => flo_cs,
       DataIn_i  => std_ulogic_vector(DO_CPU),
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
       FDD_DSELn => FDD_DSELn,
       FDD_SDSEL => FDD_SDSEL,
       FDD_SIDE  => FDD_SIDE 
     );

    flo_addr <= not IORq_n when  Cpu_A(7 downto 4) = "1100" else 
                '0';
  
    flo_Rd <= not Rd_n and not Rd_nd and not flo_rd_d;
    flo_Wr <= not Wr_n and not Wr_nd and not flo_wr_d;

    flo_cs <= flo_addr and (flo_Rd or flo_Wr);

  process(clk_16,reset_n)
  begin
    if reset_n = '0' then
      flo_rd_d <= '0';
      flo_wr_d <= '0';
    elsif rising_edge(clk_16) then
      flo_rd_d <= not Rd_n and not Rd_nd;
      flo_wr_d <= not Wr_n and not Wr_nd;
    end if;
  end process;

  
end rtl;