--------------------------------------------------------------------------------
-- Project     : Single Chip NDR Computer
-- Module      : SPI Interface
-- File        : SPI_Interface.vhd
-- Description : SPI Interface for attaqching an SD/MMC-Card to NKC.
--------------------------------------------------------------------------------
-- Author       : Andreas Voggeneder
-- Organisation : FH-Hagenberg
-- Department   : Hardware/Software Systems Engineering
-- Language     : VHDL'87
--------------------------------------------------------------------------------
-- Copyright (c) 2008 by Andreas Voggeneder
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.DffGlobal.all;
use work.gdp_global.all;

entity GPIO_Interface is
  port(
    reset_n_i    : in  std_logic;
    clk_i        : in  std_logic;
    --------------------------
    -- SPI-Signals
    --------------------------
    GPIO_io   : inout std_logic_vector(7 downto 0);
    
    ----------------------------------
    -- Data Bus
    ----------------------------------
    Adr_i     : in  std_ulogic_vector(0 downto 0);
    en_i      : in  std_ulogic;
    DataIn_i  : in  std_ulogic_vector(7 downto 0);
    Rd_i      : in  std_ulogic;
    Wr_i      : in  std_ulogic;
    DataOut_o : out std_ulogic_vector(7 downto 0)
    --------------------------
    -- Monitoring (Debug) signals
    --------------------------
--    monitoring_o : out std_ulogic_vector(nr_mon_sigs_c-1 downto 0)
  );
end GPIO_Interface;

architecture rtl of GPIO_Interface is
 
  component InputSync
    generic(levels_g     : natural :=2;
            ResetValue_g : std_ulogic := '0');
    port (
      Input : in  std_ulogic;
      clk   : in  std_ulogic;
      clr_n : in  std_ulogic;
      q     : out std_ulogic);
  end component;
--  -- load shift reg from data reg
--  signal load_en          : std_ulogic;
  
  signal data_out_reg : std_ulogic_vector(7 downto 0);
  signal data_in_reg  : std_ulogic_vector(7 downto 0);
  signal ddr_reg      : std_ulogic_vector(7 downto 0);
  
  signal DataOut,DataOut_reg     : std_ulogic_vector(7 downto 0);

  
begin
    
    with Adr_i(0) select
      DataOut   <=  data_in_reg     when '0',
                    ddr_reg         when others;

       
    process (Clk_i, reset_n_i) is
    begin  -- process
      if reset_n_i = ResetActive_c then
        ddr_reg       <= (others => '0');
        data_out_reg  <= (others => '0');
        DataOut_reg   <= (others => '0');
      elsif rising_edge(Clk_i) then
        
        if (en_i and Wr_i)='1' then
          if Adr_i(0)='0' then
            data_out_reg <= DataIn_i;
          else
            ddr_reg <= DataIn_i;
          end if;
        end if;
        if (en_i and Rd_i)='1' then
          DataOut_reg <= DataOut;
        end if;
      end if;
    end process;    
    
    DataOut_o <= DataOut_reg;
    
  is_inst: for i in GPIO_io'range generate
    IS1 : InputSync
     generic map (
       levels_g => 2,
       ResetValue_g => '0')
     port map (
       Input => GPIO_io(i),
       clk   => Clk_i,
       clr_n => reset_n_i,
       q     => data_in_reg(i));
       
    GPIO_io(i) <= data_out_reg(i) when ddr_reg(i)='1' else
                  'Z';
  end generate;
end rtl;
