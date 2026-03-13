--------------------------------------------------------------------------------
-- Project     : Single Chip NDR Computer
-- Module      : I2C Interface Toplevel
-- File        : i2c_master-rtl-ea.vhd
-- Description : I2C Interface for NKC.
--------------------------------------------------------------------------------
-- Author       : Andreas Voggeneder
-- Organisation : FH-Hagenberg
-- Department   : Hardware/Software Systems Engineering
-- Language     : VHDL'87
--------------------------------------------------------------------------------
-- Copyright (c) 2007,2025 by Andreas Voggeneder
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DffGlobal.all;
use work.gdp_global.all;

entity i2c_interface is
  port (
    reset_n_i    : in  std_logic;
    clk_i        : in  std_logic;
    ----------------------------------
    -- Data Bus
    ----------------------------------
    Adr_i     : in  std_ulogic_vector(2 downto 0);
    en_i      : in  std_ulogic;
    DataIn_i  : in  std_ulogic_vector(7 downto 0);
    Rd_i      : in  std_ulogic;
    Wr_i      : in  std_ulogic;
    DataOut_o : out std_ulogic_vector(7 downto 0);
    Intr_o    : out std_ulogic;
    --
    core_en_o : out std_ulogic;
    -- i2c interface
    scl_pad_i    : in  std_logic;       -- i2c clock line input
    scl_pad_o    : out std_logic;       -- i2c clock line output
    scl_padoen_o : out std_logic;  -- i2c clock line output enable, active low
    sda_pad_i    : in  std_logic;       -- i2c data line input
    sda_pad_o    : out std_logic;       -- i2c data line output
    sda_padoen_o : out std_logic   -- i2c data line output enable, active low

    );

end entity i2c_interface;


architecture rtl of i2c_interface is
  -----------------------------------------------------------------------------
  -- I2C master signals
  -----------------------------------------------------------------------------
  signal PRERlo_Wr  : std_logic;
  signal PRERlo_Sel : std_logic;
  signal PRERhi_Wr  : std_logic;
  signal PRERhi_Sel : std_logic;
  signal CTR_Wr     : std_logic;
  signal CTR_Sel    : std_logic;
  signal TXR_Wr     : std_logic;
  signal TXR_Sel    : std_logic;
  signal RXR_Wr     : std_logic;
  signal RXR_Sel    : std_logic;
  signal CR_Wr      : std_logic;
  signal CR_Sel     : std_logic;
  signal SR_Wr      : std_logic;
  signal SR_Sel     : std_logic;
  signal data_in    : std_logic_vector(7 downto 0);
  signal data_out   : std_logic_vector(7 downto 0);

  -----------------------------------------------------------------------------
  -- register addresses
  -----------------------------------------------------------------------------
  constant reg_addr_cr_c    : natural := 0;
  constant reg_addr_prerl_c : natural := 1;
  constant reg_addr_prerh_c : natural := 2;
  constant reg_addr_ctr_c   : natural := 3;
  constant reg_addr_txr_c   : natural := 4;
  constant reg_addr_rxr_c   : natural := 5;
  constant reg_addr_sr_c    : natural := 6;

begin  -- architecture rtl


  i2c_master_top : entity work.i2c_master_top
    generic map (
      ARST_LVL => '0')
    port map (
      wb_clk_i     => clk_i,
      wb_rst_i     => '1', -- no synchronous reset used
      arst_i       => reset_n_i,
      PRERlo_Wr    => PRERlo_Wr,
      PRERlo_Sel   => PRERlo_Sel,
      PRERhi_Wr    => PRERhi_Wr,
      PRERhi_Sel   => PRERhi_Sel,
      CTR_Wr       => CTR_Wr,
      CTR_Sel      => CTR_Sel,
      TXR_Wr       => TXR_Wr,
      TXR_Sel      => TXR_Sel,
      RXR_Wr       => RXR_Wr,
      RXR_Sel      => RXR_Sel,
      CR_Wr        => CR_Wr,
      CR_Sel       => CR_Sel,
      SR_Wr        => SR_Wr,
      SR_Sel       => SR_Sel,
      data_in      => data_in,
      data_out     => data_out,
      inter_req    => Intr_o,
      core_en_o    => core_en_o,
      scl_pad_i    => scl_pad_i,
      scl_pad_o    => scl_pad_o,
      scl_padoen_o => scl_padoen_o,
      sda_pad_i    => sda_pad_i,
      sda_pad_o    => sda_pad_o,
      sda_padoen_o => sda_padoen_o);

  -----------------------------------------------------------------------------
  -- read
  -----------------------------------------------------------------------------
  raddr_dec : process (Adr_i, Rd_i, en_i) is
  begin  -- process raddr_dec
    CR_Sel     <= '0';
    PRERlo_Sel <= '0';
    PRERhi_Sel <= '0';
    CTR_Sel    <= '0';
    TXR_Sel    <= '0';
    RXR_Sel    <= '0';
    SR_Sel     <= '0';

   if (en_i and Rd_i) = '1'  then
       case to_integer(unsigned(Adr_i(2 downto 0))) is
         when reg_addr_cr_c    => CR_Sel     <= '1';
         when reg_addr_prerl_c => PRERlo_Sel <= '1';
         when reg_addr_prerh_c => PRERhi_Sel <= '1';
         when reg_addr_ctr_c   => CTR_Sel    <= '1';
         when reg_addr_txr_c   => TXR_Sel    <= '1';
         when reg_addr_rxr_c   => RXR_Sel    <= '1';
         when reg_addr_sr_c    => SR_Sel     <= '1';
         when others           => null;
       end case;
    end if;
  end process raddr_dec;
  
  process(clk_i) is
  begin
    if rising_edge(clk_i) then
      DataOut_o <= std_ulogic_vector(data_out);
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- write
  -----------------------------------------------------------------------------
  waddr_dec : process (Adr_i, Wr_i, en_i) is
  begin  -- process waddr_dec
    CR_Wr     <= '0';
    PRERlo_Wr <= '0';
    PRERhi_Wr <= '0';
    CTR_Wr    <= '0';
    TXR_Wr    <= '0';
    RXR_Wr    <= '0';
    SR_Wr     <= '0';

    if (en_i and Wr_i) = '1'  then
      case to_integer(unsigned(Adr_i(2 downto 0))) is
        when reg_addr_cr_c    => CR_Wr     <= '1';
        when reg_addr_prerl_c => PRERlo_Wr <= '1';
        when reg_addr_prerh_c => PRERhi_Wr <= '1';
        when reg_addr_ctr_c   => CTR_Wr    <= '1';
        when reg_addr_txr_c   => TXR_Wr    <= '1';
        when reg_addr_rxr_c   => RXR_Wr    <= '1';
        when reg_addr_sr_c    => SR_Wr     <= '1';
        when others           => null;
      end case;
    end if;
  end process waddr_dec;

  data_in <= std_logic_vector(DataIn_i);

end architecture rtl;
