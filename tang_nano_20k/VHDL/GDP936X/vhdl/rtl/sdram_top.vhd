-------------------------------------------------------------------------------
-- Title      : Testbench for design "MIST_Toplevel"
-- Project    :
-------------------------------------------------------------------------------
-- File       : Toplevel_tb.vhd
-- Author     : andreas.voggeneder  <voggened@lzsxc006.lz.intel.com>
-- Company    :
-- Created    : 2015-05-06
-- Last update: 2015-05-06
-- Platform   :
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Copyright (c) 2015
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2015-05-06  1.0      voggened	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.ALL;
-------------------------------------------------------------------------------

entity sdram_top is
  port(
    reset_n_i    : in  std_logic;
    clk_i        : in  std_logic;
    -- SDRAM
    sdram_clk    : out std_logic;
    sdram_cke    : out std_logic;
    sdram_cs_n   : out std_logic;  -- chip select
    sdram_cas_n  : out std_logic;  -- columns address select
    sdram_ras_n  : out std_logic;  -- row address select
    sdram_wen_n  : out std_logic;  -- write enable
    sdram_dq     : inout std_logic_vector(31 downto 0);  -- up to 32 bit bidirectional data bus
    sdram_addr   : out std_logic_vector(10 downto 0);  -- up to 13 bit multiplexed address bus
    sdram_ba     : out std_logic_vector(1 downto 0);  -- two banks
    sdram_dqm    : out std_logic_vector(3 downto 0);  -- 32/4
    --
    kernel_req_i      : in  std_ulogic;
    kernel_wr_i       : in  std_ulogic;
    kernel_addr_i     : in  std_ulogic_vector(17 downto 0);
    kernel_data_i     : in  std_ulogic_vector(7 downto 0);
    kernel_data_o     : out std_ulogic_vector(7 downto 0);
    kernel_busy_o     : out std_ulogic;
    --kernel_ack_i      : in  std_ulogic;
    -----------------------------
    -- interface to Video-VRAM
    -----------------------------
    rd_req_i   : in  std_ulogic;
    rd_addr_i  : in  std_ulogic_vector(15 downto 0);
    rd_data_o  : out std_ulogic_vector(31 downto 0);
    rd_ack_o   : out std_ulogic;
    rd_busy_o  : out std_ulogic;
    --
    debug_o      : out std_logic_vector(1 downto 0)
  );
end sdram_top;

-------------------------------------------------------------------------------

architecture rtl of sdram_top is
  type sdr_state_t is (INIT_e, IDLE_e, KERNEL_RD_e, KERNEL_WR_e, VID_RD_e);
  signal state, next_state : sdr_state_t;

  --signal reset_sync,reset_n_sync            : std_logic;
  signal power_down, selfrefresh            : std_logic;
  signal next_sdrc_wr_n,sdrc_wr_n           : std_logic;
  signal next_sdrc_rd_n,sdrc_rd_n           : std_logic;
  signal next_sdrc_addr,sdrc_addr           : std_logic_vector(20 downto 0);
  signal next_kernel_addr,kernel_addr       : std_logic_vector(20 downto 0);
  signal next_vid_addr,vid_addr             : std_logic_vector(20 downto 0);
  signal next_sdrc_data_len,sdrc_data_len   : std_logic_vector(7 downto 0);
  signal next_vid_data_count,vid_data_count : natural;
  signal next_sdrc_dqm,sdrc_dqm             : std_logic_vector(3 downto 0);
  signal sdrc_o_data                        : std_logic_vector(31 downto 0);
  signal next_sdrc_i_data,sdrc_i_data       : std_logic_vector(31 downto 0);
  signal sdrc_init_done                     : std_logic;
  signal sdrc_busy_n                        : std_logic;
  signal sdrc_rd_valid                      : std_logic;
  signal sdrc_wrd_ack                       : std_logic;
  signal cmd_busy                           : std_logic;
  signal kernel_req_pend,next_gdp_kernel_ack: std_logic;
  
  signal debug   : std_logic;
  signal debug1  : std_logic;
begin  -- behav


	SDRAM_inst : entity work.SDRAM_controller_top_SIP
  port map (
    O_sdram_clk              => sdram_clk,
    O_sdram_cke              => sdram_cke,
    O_sdram_cs_n             => sdram_cs_n,
    O_sdram_cas_n            => sdram_cas_n,
    O_sdram_ras_n            => sdram_ras_n,
    O_sdram_wen_n            => sdram_wen_n,
    O_sdram_dqm              => sdram_dqm,
    O_sdram_addr             => sdram_addr,
    O_sdram_ba               => sdram_ba,
    IO_sdram_dq              => sdram_dq,
    --
    I_sdrc_rst_n             => reset_n_i,
    I_sdrc_clk               => clk_i,
    I_sdram_clk              => clk_i,
    I_sdrc_selfrefresh       => selfrefresh,
    I_sdrc_power_down        => power_down,
    I_sdrc_wr_n              => sdrc_wr_n,
    I_sdrc_rd_n              => sdrc_rd_n,
    I_sdrc_addr              => sdrc_addr,
    I_sdrc_data_len          => sdrc_data_len,
    I_sdrc_dqm               => sdrc_dqm,
    I_sdrc_data              => std_logic_vector(sdrc_i_data),
    O_sdrc_data              => sdrc_o_data,
    O_sdrc_init_done         => sdrc_init_done,
    O_sdrc_busy_n            => sdrc_busy_n,
    O_sdrc_rd_valid          => sdrc_rd_valid,
    O_sdrc_wrd_ack           => sdrc_wrd_ack
	);
    selfrefresh <= '0';
    power_down  <= '0';
    

   
   process(reset_n_i, clk_i) is
   begin
      if (reset_n_i = '0') then
        state         <= INIT_e;
        sdrc_addr     <= (others => '0');
        sdrc_wr_n     <= '1';
        sdrc_rd_n     <= '1';
        sdrc_data_len <= (others =>'0');
        sdrc_i_data   <= (others =>'0');
        kernel_addr   <= (others =>'0');
        vid_addr      <= (others =>'0');
        vid_data_count<= 0;
        cmd_busy      <= '0';
        sdrc_dqm      <= (others => '0');
        kernel_req_pend <= '0';
      elsif rising_edge(clk_i) then
        state         <= next_state;
        sdrc_addr     <= next_sdrc_addr;
        sdrc_wr_n     <= next_sdrc_wr_n;
        sdrc_rd_n     <= next_sdrc_rd_n;
        sdrc_data_len <= next_sdrc_data_len;
        sdrc_i_data   <= next_sdrc_i_data;
        sdrc_dqm      <= next_sdrc_dqm;
        kernel_addr   <= next_kernel_addr;
        vid_addr      <= next_vid_addr;
        vid_data_count<= next_vid_data_count;
        if (next_sdrc_wr_n and next_sdrc_rd_n)='0' then
          cmd_busy      <= '1';
        end if;
        if sdrc_wrd_ack='1' then
          cmd_busy      <= '0';
        end if;
        if kernel_req_i='1' then
          kernel_req_pend <= '1';
        end if;
        if next_gdp_kernel_ack = '1' then
          kernel_req_pend <= '0';
        end if;
        
      end if;
   end process;
   
    fsm_comb: process(state, sdrc_o_data, sdrc_init_done, sdrc_busy_n, sdrc_rd_valid, sdrc_wrd_ack,
                      sdrc_addr,sdrc_wr_n, sdrc_rd_n, sdrc_data_len, sdrc_i_data,sdrc_dqm, kernel_addr, vid_addr, vid_data_count,
                      cmd_busy, kernel_req_pend, kernel_req_i, kernel_wr_i, kernel_addr_i, kernel_data_i)
    begin
      next_state         <= state;
      next_sdrc_addr     <= sdrc_addr;
      next_sdrc_wr_n     <= '1';
      next_sdrc_rd_n     <= '1';
      next_sdrc_data_len <= sdrc_data_len;
      next_sdrc_i_data   <= sdrc_i_data;
      next_sdrc_dqm      <= sdrc_dqm;
      next_kernel_addr   <= kernel_addr;
      next_vid_addr      <= vid_addr;
      next_vid_data_count<= vid_data_count;
      case state is
        when INIT_e => 
          if (sdrc_init_done='1') then
            next_state        <= IDLE_e;
          end if;
        when IDLE_e =>
          if (kernel_req_pend or kernel_req_i)='1' then
            next_sdrc_wr_n              <= not kernel_wr_i;
            next_sdrc_addr(15 downto 0) <= std_logic_vector(kernel_addr_i(17 downto 2));
            next_sdrc_data_len          <= (others => '0');
            if kernel_wr_i='1' then
               next_sdrc_i_data <= std_logic_vector(kernel_data_i & kernel_data_i & kernel_data_i & kernel_data_i);
               next_sdrc_dqm    <= (others => '0');
               case kernel_addr_i(1 downto 0) is
                  when "00" =>
                     next_sdrc_dqm(0) <= '1';
                  when "01" =>
                     next_sdrc_dqm(1) <= '1';
                  when "10" =>
                     next_sdrc_dqm(2) <= '1';
                  when others =>
                     next_sdrc_dqm(3) <= '1';
               end case;

            end if;
          end if;
        

        when others => 
          next_state <= IDLE_e;
      end case;
    end process;
   
   debug_o(0) <= debug;
   debug_o(1) <= debug1;
end rtl;

-------------------------------------------------------------------------------


