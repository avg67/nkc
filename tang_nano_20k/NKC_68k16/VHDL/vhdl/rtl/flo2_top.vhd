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
use ieee.std_logic_unsigned.all;
use work.DffGlobal.all;


entity flo2_top is
  generic(emu_g : boolean := false);
  port(reset_n_i     : in  std_ulogic;
       clk_i         : in  std_ulogic;
       --------------------------
       -- internal data bus (Register)
       --------------------------
       Adr_i     : in  std_ulogic_vector(7 downto 0);
       CS_i      : in  std_ulogic;
       DataIn_i  : in  std_ulogic_vector(7 downto 0);
       Rd_i      : in  std_ulogic;
       Wr_i      : in  std_ulogic;
       DataOut_o : out std_ulogic_vector(7 downto 0);
       Int_n_o   : out std_ulogic;
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
       FDD_SIDE     : out std_ulogic; -- (32) Side          Open drain
       --
       monitoring_o : out std_ulogic_vector(7 downto 0)
     );
end flo2_top;


architecture rtl of flo2_top is
  component WF1772IP_TOP_SOC is
    port (
      CLK       : in std_logic; -- 16MHz clock!
      RESETn    : in std_logic;
      CSn       : in std_logic;
      RWn       : in std_logic;
      A1, A0    : in std_logic;
      DATA_IN   : in std_logic_vector(7 downto 0);
      DATA_OUT  : out std_logic_vector(7 downto 0);
      DATA_EN   : out std_logic;

      RDn     : in std_logic;
      TR00n   : in std_logic;  -- nTK0
      IPn     : in std_logic;  -- nIndex
      WPRTn   : in std_logic;  -- nWriteProtect
      DDEn    : in std_logic;  -- Singe (FM) / Double (MFM) Density
      HDTYPE  : in std_logic; -- '0' = DD disks, '1' = HD disks.
      MO      : out std_logic;
      WG      : out std_logic;
      WD      : out std_logic;
      STEP    : out std_logic;
      DIRC    : out std_logic;

      DRQ     : out std_logic;
      INTRQ   : out std_logic;
      monitoring_o : out std_ulogic_vector(7 downto 0) 
    );
  end component;
  component InputSync
    generic(levels_g     : natural :=2;
            ResetValue_g : std_ulogic := '1');
    port (
      Input : in  std_ulogic;
      clk   : in  std_ulogic;
      clr_n : in  std_ulogic;
      q     : out std_ulogic);
  end component;
--  signal RDn                     : std_logic;
--  signal TR00n                   : std_logic;  -- nTK0
--  signal IPn                     : std_logic;  -- nIndex
--  signal WPRTn                   : std_logic;  -- nWriteProtect
  signal DDEn                    : std_logic;  -- Singe (FM) / Double (MFM) Density
  signal HDTYPE                  : std_logic;  -- '0' = DD disks, '1' = HD disks.
  signal MO                      : std_logic;  -- Motor on
  signal WG                      : std_logic;  -- Write Gate
  signal WD                      : std_logic;  -- Write Data
  signal STEP                    : std_logic;
  signal DIRC                    : std_logic;
  signal DRQ                     : std_logic;
  signal INTRQ                   : std_logic;
  signal fdc_DataOut             : std_logic_vector(7 downto 0);
  signal fdc_csn,fdc_rwn,fdc_data_en : std_logic;
  signal RDn_sync,TR00n_sync,IPn_sync,WPRTn_sync: std_logic;
  

  signal flo_en,sfr_en               : std_logic;
  signal flo_reg,sfr_stat            : std_ulogic_vector(7 downto 0);
--  signal test_reg                    : std_ulogic_vector(7 downto 0);
  signal debug_toggle                : std_ulogic;
  signal wdc_monitoring              : std_ulogic_vector(7 downto 0);
begin

  sfr_en  <= CS_i when Adr_i(3 downto 2)="01" else
             '0';
  flo_en  <= CS_i  when Adr_i(3 downto 2)="00" else
             '0';

  fdc_csn <= not(flo_en and (Wr_i or Rd_i));


  fdc_rwn <= not (Wr_i and CS_i);


  FDC : WF1772IP_TOP_SOC
    port map(
      CLK       => clk_i,
      RESETn    => reset_n_i,
      CSn       => fdc_csn,
      RWn       => fdc_rwn,
      A0        => Adr_i(0),
      A1        => Adr_i(1),
      DATA_IN   => std_logic_vector(DataIn_i),
      DATA_OUT  => fdc_DataOut,
      DATA_EN   => fdc_data_en,

      RDn       => RDn_sync,
      TR00n     => TR00n_sync,
      IPn       => IPn_sync,
      WPRTn     => WPRTn_sync,
      DDEn      => '0', --DDEn,
      HDTYPE    => HDTYPE,
      MO        => MO,
      WG        => WG,
      WD        => WD,
      STEP      => STEP,
      DIRC      => DIRC,

      DRQ       => DRQ,
      INTRQ     => INTRQ,
      monitoring_o => wdc_monitoring
    );

  soc: if emu_g generate
--  FDD_MOn   <= flo_reg(6); -- ST3 Jumper
    FDD_MOn   <= not MO;
    FDD_WGn   <= not WG;
    FDD_WDn   <= not WD;
    FDD_STEPn <= not STEP;
    FDD_DIRCn <= not DIRC;
    FDD_SIDE  <= not flo_reg(7);
    RDn_sync  <= FDD_RDn;
    TR00n_sync<= FDD_TR00n;
    IPn_sync  <= FDD_IPn;
    WPRTn_sync<= FDD_WPRTn;
    FDD_DSELn <= not flo_reg(3 downto 0) when MO = '1' else
                 (others => '1');
    FDD_SDSEL <= not flo_reg(5);

    monitoring_o <=   "00"       &
                      not MO     &
                      not STEP   &
                      RDn_sync   &
                      TR00n_sync &
                      IPn_sync   &
                      WPRTn_sync; 
                      
  end generate;
  no_soc: if not emu_g generate
    monitoring_o <= wdc_monitoring;
  
    ISRDn : InputSync
    generic map (
      ResetValue_g => '1'
    )
    port map (
        Input => FDD_RDn,
        clk   => clk_i,
        clr_n => reset_n_i,
        q     => RDn_sync);
        
    ISTR00n : InputSync
    generic map (
      ResetValue_g => '1'
    )
    port map (
        Input => FDD_TR00n,
        clk   => clk_i,
        clr_n => reset_n_i,
        q     => TR00n_sync);
  
    ISIPn : InputSync
    generic map (
      ResetValue_g => '1'
    )
    port map (
        Input => FDD_IPn,
        clk   => clk_i,
        clr_n => reset_n_i,
        q     => IPn_sync);
        
    ISWPRTn : InputSync
    generic map (
      ResetValue_g => '1'
    )
    port map (
        Input => FDD_WPRTn,
        clk   => clk_i,
        clr_n => reset_n_i,
        q     => WPRTn_sync);
  
--    FDD_MOn   <= '0' when MO    = '1' else 'Z';
--  --  FDD_MOn   <= flo_reg(6); -- ST3 Jumper
--  
--    FDD_WGn   <= '0' when WG    = '1' else 'Z';
--    FDD_WDn   <= '0' when WD    = '1' else 'Z';
--    FDD_STEPn <= '0' when STEP  = '1' else 'Z';
--    FDD_DIRCn <= '0' when DIRC  = '1' else 'Z';
--    FDD_SIDE  <= '0' when flo_reg(7)  = '1' else 'Z';
    
    FDD_MOn   <= MO;
--    FDD_MOn   <= not flo_reg(6); -- ST3 Jumper
  
    FDD_WGn     <= WG;
    FDD_WDn     <= WD;
    FDD_STEPn   <= STEP;
    FDD_DIRCn   <= DIRC;
    FDD_SIDE    <= flo_reg(7);
    FDD_DSELn <= flo_reg(3 downto 0) when MO = '1' else
                 (others => '0');
    FDD_SDSEL <= flo_reg(5);

  end generate;

--  FDD_DDEn  <= DDEn;


  HDTYPE               <= not flo_reg(5);
  DDEn                 <= flo_reg(4); -- FM / MFM
  sfr_stat(7)          <= DRQ;
  sfr_stat(6)          <= INTRQ;
  sfr_stat(5)          <= MO;
  sfr_stat(4 downto 0) <= (others => '0');

  Int_n_o              <= not INTRQ;

  -- Prozess zum schreiben der SFR's
  Regs : process(clk_i, reset_n_i)
  begin
    if reset_n_i = ResetActive_c then
      flo_reg      <= (others => '0');
--      test_reg     <= (others => '0');
      debug_toggle <=  '0';
    elsif rising_edge(clk_i) then
      if ((flo_en and Rd_i) or (sfr_en and Rd_i))= '1' then
        debug_toggle <= not debug_toggle;
      end if;
      if (sfr_en and Wr_i) = '1' then
        if Adr_i(0)='0' then
          flo_reg <= DataIn_i;
--        else
--          test_reg <= DataIn_i;
        end if;
      end if;
    end if;
  end process;

  process(clk_i)
  begin
    if rising_edge(clk_i) then
      if (flo_en and Rd_i) = '1' then
        DataOut_o <= std_ulogic_vector(fdc_DataOut);
      elsif (sfr_en and Rd_i) = '1' then
        if Adr_i(0)='0' then
          DataOut_o <= sfr_stat;
        else
--          DataOut_o <= test_reg;
          DataOut_o <= wdc_monitoring;
        end if;
      end if;
    end if;
  end process;

--  monitoring_o <= test_reg(6 downto 0) & wdc_monitoring(0); --debug_toggle;
--  monitoring_o <= wdc_monitoring;

end rtl;
