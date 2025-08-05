--------------------------------------------------------------------------------
-- Project     : Single Chip NDR Computer
-- Module      : SDIO Interface
-- File        : SDIO_Interface.vhd
-- Description : SDIO Interface for attaching an SD/MMC-Card to NKC.
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
use work.DffGlobal.all;
use work.gdp_global.all;

entity SDIO_Interface is
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
end SDIO_Interface;

architecture rtl of SDIO_Interface is
 
  constant MOSI_IDLE_c       : std_ulogic := '1';
  constant SLOW_DIVIDER_c    : natural := 64;
  constant FAST_DIVIDER_c    : natural := 2;
  
  signal divider             : natural range 0 to SLOW_DIVIDER_c - 1;
 
  signal shift_in_reg        : std_ulogic_vector(6 downto 0);
  signal shift_out_reg       : std_ulogic_vector(7 downto 0);
  signal shift_en            : std_ulogic;
--  -- load shift reg from data reg
--  signal load_en          : std_ulogic;
  
  signal data_in_reg : std_ulogic_vector(7 downto 0);
  signal bit_cnt     : unsigned(2 downto 0);
  signal delay_cnt   :natural range 0 to SLOW_DIVIDER_c - 1;

  -- bit 0: CS0
  -- bit 1: CS1
  -- bit 3: Power
  -- bit 6: 0=Single / 1=Multi-Read. Ein Data-Read startet den nächsten transfer
  -- bit 7: 0=Slow / 1=Fast
  signal ctrl_reg    : std_ulogic_vector(7 downto 0);
  -- bit 0 IDLE SPI IDLE. Write to data reg only allowed when IDLE=1
  -- bit 1 WCOL (Write collision, datareg written during a data transfer, cleared by reading datareg)
  signal status      : std_ulogic;
  signal wcol        : std_ulogic;
--  signal SD_nCS      : std_ulogic_vector(1 downto 0);
  signal sd_sck      : std_ulogic;
  
  signal DataOut,DataOut_reg     : std_ulogic_vector(7 downto 0);
  signal finish                  : std_ulogic;
  signal initial                 : std_ulogic;
  
begin

-- Divider:
-- 0: /2
-- 1: /4
-- 2: /6
-- 3: /8
-- 4: /10
-- 5: /12
-- 6: /14
-- 7: /16
    
    divider <= SLOW_DIVIDER_c - 1  when ctrl_reg(7)='1' else
               FAST_DIVIDER_c - 1;
    
    with Adr_i(0) select
      DataOut   <=  data_in_reg           when '0',
                    "1111111" & status    when others;
       
    process (Clk_i, reset_n_i) is
    begin  -- process
      if reset_n_i = ResetActive_c then
        sd_sck        <= '0';
        bit_cnt       <= (others => '1');
        delay_cnt     <= 0;
        shift_in_reg  <= (others => '0');
        shift_out_reg <= (others => '0');
        data_in_reg   <= (others => '0');
        ctrl_reg      <= (others => '0');

        DataOut_reg   <= (others => '0');

        shift_en      <= '0';
--        SD_nCS        <= (others => '1');
        SD_MOSI_o     <= MOSI_IDLE_c;
        finish        <= '0';
        initial       <= '1';
      elsif rising_edge(Clk_i) then
         if shift_en='1' then
            if delay_cnt /= divider then --unsigned(ctrl_reg(2 downto 0)) then
               delay_cnt <= delay_cnt + 1;
            else
               delay_cnt <= 0;
               --if (ctrl_reg(3) or not initial)='1' then
               if (not initial)='1' then
                  -- toggle SCK when either SCK is IDLE HIGH or initial phase is over
                  sd_sck    <= not sd_sck;
               end if;
               --if ((not ctrl_reg(3) and initial) or sd_sck) = '1' then
               if (initial or sd_sck) = '1' then
                  -- falling edge on sd_clk 
                  -- or SCK IDLE LOW and first clock 
                  initial       <= '0';
                  shift_out_reg <= shift_out_reg(6 downto 0) & "0";
                  SD_MOSI_o     <= shift_out_reg(7);
                  
               else
                  -- rising edge on sd_clk
                  -- sample data from SD-card
                  shift_in_reg <= shift_in_reg(5 downto 0) & SD_MISO_i;
                  bit_cnt      <= bit_cnt - 1;
                  if bit_cnt=0 then
                     data_in_reg <= shift_in_reg(6 downto 0) & SD_MISO_i;
                     shift_en    <= '0';
                     finish      <= '1';
                  end if;
               end if;
            end if;
         end if;
         if finish='1' then
            if delay_cnt /= divider then --unsigned(ctrl_reg(2 downto 0)) then
               delay_cnt <= delay_cnt + 1;
            else
               delay_cnt <= 0;
               finish    <= '0';
               SD_MOSI_o <= MOSI_IDLE_c;
               --if (not ctrl_reg(3) and sd_sck)='1' then
               if sd_sck='1' then
                  -- do a final toggle of SCK when IDLE LOW
                  sd_sck <= not sd_sck;
               end if;
            end if;
         end if;
        
        if (en_i and Wr_i)='1' then
          if Adr_i(0)='1' then
            ctrl_reg <= DataIn_i;
          else
            shift_out_reg <= DataIn_i;
            bit_cnt       <= to_unsigned(7,bit_cnt'length);
            shift_en      <= '1';
            initial       <= '1';
          end if;
        end if;
        if (en_i and Rd_i)='1' then
          DataOut_reg <= DataOut;
          
          if (not Adr_i(0) and not ctrl_reg(6))='1' then
            -- Multiread enabled and read-access to data-reg -> trigger next read transfer
            shift_out_reg <= (others => '1');
            bit_cnt       <= to_unsigned(7,bit_cnt'length);
            shift_en      <= '1';
            initial       <= '1';
          end if;
        end if;
        --SD_nCS <= (others => '1');
        --case ctrl_reg(6 downto 4) is
        --  when "010" => --0
        --    SD_nCS <= "110";
        --  when "100" => --1
        --    SD_nCS <= "101";
        --  when "001" => -- 2
        --    SD_nCS <= "011";
        --  when others => null;
        --end case;
      end if;
    end process;    
    
    status    <= (shift_en or finish);
    DataOut_o <= DataOut_reg;
    SD_SCK_o  <= sd_sck;
    SD_nCS_o  <= ctrl_reg(1 downto 0);
    
    
end rtl;
