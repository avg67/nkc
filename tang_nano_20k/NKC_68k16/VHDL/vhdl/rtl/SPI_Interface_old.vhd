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

entity SPI_Interface is
  port(
    reset_n_i    : in  std_logic;
    clk_i        : in  std_logic;
    --------------------------
    -- SPI-Signals
    --------------------------
    SD_SCK_o  : out std_ulogic;
    SD_nCS_o  : out std_ulogic_vector(1 downto 0);
    SD_MOSI_o : out std_ulogic;
    SD_MISO_i : in  std_ulogic;
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
end SPI_Interface;

architecture rtl of SPI_Interface is
 
  signal shift_in_reg        : std_ulogic_vector(6 downto 0);
  signal shift_out_reg       : std_ulogic_vector(7 downto 0);
  signal shift_en         : std_ulogic;
--  -- load shift reg from data reg
--  signal load_en          : std_ulogic;
  
  signal data_in_reg : std_ulogic_vector(7 downto 0);
  signal bit_cnt     : unsigned(2 downto 0);
  signal delay_cnt   : unsigned(2 downto 0);

  -- bit 0-2 SPR (SPI Clock Rate)
  -- bit 6-5 Slave Select
  -- bit 7   SPE (SPI Enable)
  signal ctrl_reg    : std_ulogic_vector(7 downto 0);
  -- bit 0 IDLE SPI IDLE. Write to data reg only allowed when IDLE=1
  -- bit 1 WCOL (Write collision, datareg written during a data transfer, cleared by reading datareg)
  signal status      : std_ulogic_vector(1 downto 0);
--  signal status_reg  : std_ulogic_vector(1 downto 0);
  signal wcol   : std_ulogic;
--  signal ss_reg      : std_ulogic_vector(1 downto 0);
  signal SD_nCS      : std_ulogic_vector(1 downto 0);
  
  signal sd_sck, sd_mosi : std_ulogic;
  signal DataOut,DataOut_reg     : std_ulogic_vector(7 downto 0);
  signal finish : std_ulogic;
  
begin
    
--    with to_integer(unsigned(Adr_i(1 downto 0))) select
--      DataOut   <=  "00000"  & ctrl_reg   when 0,
--                    "000000" & status     when 1,
--                    data_in_reg           when 2,
--                    "000000" & ss_reg     when others;
    with Adr_i(0) select
      DataOut   <=  "000000" & status     when '0',
                    data_in_reg           when others;

       
    process (Clk_i, reset_n_i) is
    begin  -- process
      if reset_n_i = ResetActive_c then
        sd_sck        <= '1';
        sd_mosi       <= '0';
        bit_cnt       <= (others => '1');
        delay_cnt     <= (others => '0');
        shift_in_reg  <= (others => '0');
        shift_out_reg <= (others => '0');
        data_in_reg   <= (others => '0');
        ctrl_reg      <= (others => '0');
--        status_reg    <= (others => '0');
        DataOut_reg   <= (others => '0');
--        ss_reg        <= (others => '0');
--        spif          <= '0';
        wcol          <= '0';
        shift_en      <= '0';
        SD_nCS        <= (others => '1');
        SD_MOSI_o     <= '1';
        finish        <= '0';
      elsif rising_edge(Clk_i) then
        if ctrl_reg(7)='1' then
          if shift_en='1' then
            if delay_cnt /= unsigned(ctrl_reg(2 downto 0)) then
              delay_cnt <= delay_cnt + 1;
            else
              delay_cnt <= (others => '0');
              
              sd_sck    <= not sd_sck;
              if sd_sck = '1' then
                -- falling edge on sd_clk 
                -- 
                shift_out_reg <= shift_out_reg(6 downto 0) & "0";
                SD_MOSI_o <= shift_out_reg(7);
                
              else
                -- rising edge on sd_clk
                -- sample data from SD-card
                shift_in_reg <= shift_in_reg(5 downto 0) & SD_MISO_i;
                bit_cnt   <= bit_cnt - 1;
                if bit_cnt=0 then
--                  spif        <= '1';
                  data_in_reg <= shift_in_reg(6 downto 0) & SD_MISO_i;
                  shift_en    <= '0';
                  finish      <= '1';
                end if;
              end if;
            end if;
          end if;
          if finish='1' then
            if delay_cnt /= unsigned(ctrl_reg(2 downto 0)) then
              delay_cnt <= delay_cnt + 1;
            else
              delay_cnt <= (others => '0');
              finish    <= '0';
              SD_MOSI_o <= '1';
            end if;
          end if;
        else
          bit_cnt   <= (others => '1');
          delay_cnt <= (others => '0');
--          spif      <= '0';
          wcol      <= '0';
          SD_MOSI_o <= '1';
          finish    <= '1';
        end if;
        
        if (en_i and Wr_i)='1' then
          if Adr_i(0)='0' then
            ctrl_reg <= DataIn_i;
          else
            shift_out_reg <= DataIn_i;
            bit_cnt       <= to_unsigned(7,bit_cnt'length);
            shift_en   <= '1';
            if shift_en='1' then
              wcol <= '1';
            end if;
          end if;
        end if;
        if (en_i and Rd_i)='1' then
          DataOut_reg <= DataOut;
          if Adr_i(0)='0' then
            wcol <= '0';
          end if;
        end if;
        SD_nCS <= (others => '1');
        case ctrl_reg(6 downto 5) is
          when "01" =>
            SD_nCS <= "10";
          when "10" =>
            SD_nCS <= "01";
          when others => null;
        end case;
      end if;
    end process;    
    
    status(0) <= not (shift_en or finish);
    status(1) <= wcol;
    DataOut_o <= DataOut_reg;
    SD_SCK_o  <= sd_sck;
    SD_nCS_o  <= SD_nCS;
    
    
end rtl;
