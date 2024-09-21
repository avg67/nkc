--------------------------------------------------------------------------------
-- Project     : Single Chip NDR Computer
-- Module      : GDP 936X Display processor - VRAM-interface
-- File        : GDP_vram.vhd
-- Description :
--------------------------------------------------------------------------------
-- Author       : Andreas Voggeneder
-- Organisation : FH-Hagenberg
-- Department   : Hardware/Software Systems Engineering
-- Language     : VHDL'87
--------------------------------------------------------------------------------
-- Copyright (c) 2007 by Andreas Voggeneder
--------------------------------------------------------------------------------

--
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;
  use work.gdp_global.all;
  use work.DffGlobal.all;

entity gdp_vram is
  port (
    clk_i             : in  std_ulogic;
    clk_en_i          : in  std_ulogic;
    reset_n_i         : in  std_ulogic;
    -- kernel port (read & write)
    kernel_clk_en_i   : in  std_ulogic;
    kernel_req_i      : in  std_ulogic;
    kernel_wr_i       : in  std_ulogic;
    kernel_clrscr_i   : in  std_ulogic;
    kernel_addr_i     : in  std_ulogic_vector(19 downto 0);
    kernel_data_i     : in  std_ulogic_vector(7 downto 0);
    kernel_data_o     : out std_ulogic_vector(7 downto 0);
    kernel_busy_o     : out std_ulogic;
    kernel_ack_o      : out std_ulogic;

    -- video port (only read)
    rd_req_i          : in  std_ulogic;
    rd_addr_i         : in  std_ulogic_vector(17 downto 0);
    rd_data_o         : out std_ulogic_vector(31 downto 0);
    rd_data_valid_o   : out std_ulogic;
    rd_busy_o         : out std_ulogic;
    rd_ack_o          : out std_ulogic;
    -- SDRAM
    sdram_clk    : out std_logic;
    sdram_cke    : out std_logic;
    sdram_cs_n   : out std_logic;  -- chip select
    sdram_cas_n  : out std_logic;  -- columns address select
    sdram_ras_n  : out std_logic;  -- row address select
    sdram_wen_n  : out std_logic;  -- write enable
    sdram_dq     : inout std_logic_vector(31 downto 0);  -- up to 32 bit bidirectional data bus
    sdram_addr   : out std_logic_vector(12 downto 0);  -- up to 13 bit multiplexed address bus
    sdram_ba     : out std_logic_vector(1 downto 0);  -- two banks
    sdram_dqm    : out std_logic_vector(3 downto 0)  -- 32/4
  );
end;

architecture rtl of gdp_vram is

  constant Refresh_time_c                   : natural := 600; -- 4096 times every 64mS -> every 15 us
  type state_t is(init_e,idle_e,kernel_write_e,kernel_read_e,dram_busy_e,vid_read_e,vid_busy_e, refresh_e);
  signal wr_data                            : std_ulogic_vector(7 downto 0);
  --signal rd_data, next_rd_data              : std_ulogic_vector(31 downto 0);
  --signal set_rd_data                        : std_ulogic;
  signal kernel_data, next_kernel_data      : std_ulogic_vector(7 downto 0);
  signal set_kernel_data                    : std_ulogic;
  signal state,next_state                   : state_t;
  signal ram_address, next_ram_address      : std_ulogic_vector(20 downto 0);
  signal set_ram_address                    : std_ulogic;
  signal kernel_req_pend                    : std_ulogic;
  signal next_kernel_ack                    : std_ulogic;
  signal rd_pend                            : std_ulogic;
  signal next_rd_ack                        : std_ulogic;
  signal ram_wren, next_ram_wren            : std_ulogic;
  signal ram_en, next_ram_en                : std_ulogic;
  signal ram_refresh, next_ram_refresh      : std_logic;
  signal refresh_timer                      : natural range 0 to Refresh_time_c;
  signal do_refresh, refresh_done           : std_ulogic;
  --signal ram_bhe, next_ram_bhe              : std_ulogic;
  --signal ram_ble, next_ram_ble              : std_ulogic;
  signal next_sdrc_dqm,sdrc_dqm             : std_ulogic_vector(3 downto 0);
  signal power_down                         : std_logic;
  --signal sdrc_wr_n                          : std_logic;
  --signal sdrc_rd_n                          : std_logic;
  signal sdrc_addr                          : std_logic_vector(20 downto 0);
  --signal next_sdrc_data_len,sdrc_data_len   : std_logic_vector(7 downto 0);
  signal sdrc_i_data                        : std_ulogic_vector(31 downto 0);
  signal sdrc_o_data                        : std_logic_vector(31 downto 0);
  signal next_sdrc_read_burst, sdrc_read_burst   : std_logic;
  signal sdrc_init_done                     : std_logic;
  --signal sdrc_busy_n                        : std_logic;
  signal srdc_cmd_ready                     : std_logic;
  signal sdrc_rd_valid                      : std_logic;
  signal rd_data_valid                      : std_logic;
  --signal next_wr_data, wr_data              : std_logic_vector(31 downto 0);
  --signal sdrc_wrd_ack                       : std_logic;
  --signal cmd_busy                           : std_logic;
begin


--SDRAM_inst : entity work.SDRAM_controller_top_SIP
--  port map (
--    O_sdram_clk              => sdram_clk,
--    O_sdram_cke              => sdram_cke,
--    O_sdram_cs_n             => sdram_cs_n,
--    O_sdram_cas_n            => sdram_cas_n,
--    O_sdram_ras_n            => sdram_ras_n,
--    O_sdram_wen_n            => sdram_wen_n,
--    O_sdram_dqm              => sdram_dqm,
--    O_sdram_addr             => sdram_addr,
--    O_sdram_ba               => sdram_ba,
--    IO_sdram_dq              => sdram_dq,
--    --
--    I_sdrc_rst_n             => reset_n_i,
--    I_sdrc_clk               => clk_i,
--    I_sdram_clk              => clk_i,
--    I_sdrc_selfrefresh       => selfrefresh,
--    I_sdrc_power_down        => power_down,
--    I_sdrc_wr_n              => sdrc_wr_n,
--    I_sdrc_rd_n              => sdrc_rd_n,
--    I_sdrc_addr              => sdrc_addr,
--    I_sdrc_data_len          => sdrc_data_len,
--    I_sdrc_dqm               => sdrc_dqm,
--    I_sdrc_data              => std_logic_vector(sdrc_i_data),
--    O_sdrc_data              => sdrc_o_data,
--    O_sdrc_init_done         => sdrc_init_done,
--    O_sdrc_busy_n            => sdrc_busy_n,
--    O_sdrc_rd_valid          => sdrc_rd_valid,
--    O_sdrc_wrd_ack           => sdrc_wrd_ack
--   );
    SDRAM_inst: entity work.sdram
      port map (
         sd_clk     => sdram_clk,
         sd_cke     => sdram_cke,
         sd_data    => sdram_dq,
                    
         sd_addr    => sdram_addr,
         sd_dqm     => sdram_dqm,
         sd_ba      => sdram_ba,
         sd_cs      => sdram_cs_n,
         sd_we      => sdram_wen_n,
         sd_ras     => sdram_ras_n,
         sd_cas     => sdram_cas_n,
                    
         clk        => clk_i,
         reset_n    => reset_n_i,
                    
         ready      => sdrc_init_done,
         refresh    => ram_refresh,
         din        => sdrc_i_data,
         dout       => sdrc_o_data,
         dout_valid => sdrc_rd_valid,
         addr       => sdrc_addr,
         ds         => sdrc_dqm,
         cs         => ram_en,
         we         => ram_wren,
         cmd_ready  => srdc_cmd_ready,
         read_burst => sdrc_read_burst
      );



    power_down  <= '0';
    sdrc_addr   <=  std_logic_vector(ram_address);
    sdrc_i_data <= wr_data & wr_data & wr_data & wr_data;


  -- DP-RAM Controller FSM for ext. SRAM
  process(state,ram_address, kernel_addr_i,kernel_wr_i,rd_addr_i,wr_data,ram_wren, ram_en, ram_refresh,
          kernel_req_i,kernel_req_pend,rd_req_i,rd_pend,kernel_data,kernel_clk_en_i,do_refresh,
          sdrc_o_data,sdrc_dqm,srdc_cmd_ready,sdrc_init_done,sdrc_read_burst,sdrc_rd_valid)
    procedure do_kernel_acc_p is
    begin
      set_ram_address      <= '1';
      next_ram_address     <= "000" & kernel_addr_i(19 downto 2);
      next_ram_wren        <= kernel_wr_i;
      next_sdrc_read_burst <= '0';
      --if kernel_addr_i(19)='1' then
      --  next_ram_en <= "10";
      --else
      --  next_ram_en <= "01";
      --end if;
      next_ram_en <= '1';
      --if kernel_addr_i(0)='0' then
      --   next_ram_bhe <= '1';
      --else
      --   next_ram_ble <= '1';
      --end if;
      if kernel_wr_i='1' then
         if kernel_clrscr_i = '1' then
            next_sdrc_dqm    <= (others => '1');
         else
            next_sdrc_dqm    <= (others => '0');
            case kernel_addr_i(1 downto 0) is
              when "00" =>
                 next_sdrc_dqm(3) <= '1';
              when "01" =>
                 next_sdrc_dqm(2) <= '1';
              when "10" =>
                 next_sdrc_dqm(1) <= '1';
              when others =>
                 next_sdrc_dqm(0) <= '1';
            end case;
         end if;
         next_state     <= kernel_write_e;
      else
         next_sdrc_dqm  <= (others => '1');
         next_state     <= kernel_read_e;
      end if;
      --if kernel_wr_i='0' then
      --  next_state     <= kernel_read_e;
      --else
      --  next_kernel_ack  <= '1';
      --end if;
    end procedure;
    procedure do_vid_rd_p is
    begin
      set_ram_address  <= '1';
      next_ram_address <= "000" & rd_addr_i;
      --if rd_addr_i(18)='1' then
      --  next_ram_en <= "10";
      --else
      --  next_ram_en <= "01";
      --end if;
      next_ram_en      <= '1';
      next_ram_wren    <= '0';
      --next_ram_ble     <= '1';
      --next_ram_bhe     <= '1';
      next_sdrc_dqm    <= (others => '1');
      --next_sdrc_data_len <= std_logic_vector(to_unsigned(RD_BURST_SIZE_c - 1,next_sdrc_data_len'length)); -- INC8 Burst
      next_sdrc_read_burst <= '1';
      next_state       <= vid_read_e;
    end procedure;
    procedure do_refresh_p is
    begin
      next_ram_wren        <= '0';
      next_sdrc_read_burst <= '0';
      next_ram_en          <= '1';
      next_state           <= refresh_e;
      next_ram_refresh     <= '1';
    end procedure;
  begin
    next_state      <= state;
    next_kernel_ack <= '0';
    next_rd_ack     <= '0';
    next_ram_address <= (others => '-');
    set_ram_address  <= '0';
--    next_wr_data    <= wr_data;
    --next_rd_data     <= (others => '-');
    --set_rd_data      <= '0';
    next_kernel_data <= (others => '-');
    set_kernel_data  <= '0';
    next_ram_wren    <= ram_wren;
    next_ram_en      <= ram_en;
    next_ram_refresh <= '0';
    --next_ram_ble     <= '0';
    --next_ram_bhe     <= '0';
    next_sdrc_dqm    <= sdrc_dqm;
    next_sdrc_read_burst <= sdrc_read_burst;
    rd_data_valid   <= '0';
    refresh_done    <= '0';
    --next_sdrc_data_len <= sdrc_data_len;


    case state is
      when init_e => 
          next_ram_en <= '0';
          if (sdrc_init_done='1') then
            next_state        <= idle_e;
          end if;
      when idle_e =>
         if srdc_cmd_ready='1' then
            -- a video read has always a higher priority than a kernel access
            next_ram_en <= '0';
            if (rd_req_i or rd_pend)='1' then
               do_vid_rd_p;
            elsif do_refresh ='1' then
               do_refresh_p;
            elsif ((kernel_clk_en_i and kernel_req_i) or kernel_req_pend)='1' then
               do_kernel_acc_p;
            end if;
         end if;

      when vid_read_e =>
        if srdc_cmd_ready='0' then
          next_state   <= vid_busy_e;
          --set_rd_data  <= '1';
          --next_rd_data <= std_ulogic_vector(sdrc_o_data);
        end if;
        
      when vid_busy_e =>
        rd_data_valid <= sdrc_rd_valid;
        if srdc_cmd_ready='1' then
          next_state   <= idle_e;
          next_ram_en  <= '0';
          next_rd_ack  <= '1';
          --if (rd_req_i or rd_pend)='1' then
          --  do_vid_rd_p;
          --els
          --if ((kernel_clk_en_i and kernel_req_i) or kernel_req_pend)='1' then
          --  do_kernel_acc_p;
          --end if;
        end if;
      
      
      when dram_busy_e =>
         set_kernel_data  <= sdrc_rd_valid and not ram_wren;
         case kernel_addr_i(1 downto 0) is
         when "00" =>
            next_kernel_data <= std_ulogic_vector(sdrc_o_data(31 downto 24));
         when "01" =>
            next_kernel_data <= std_ulogic_vector(sdrc_o_data(23 downto 16));
         when "10" =>
            next_kernel_data <= std_ulogic_vector(sdrc_o_data(15 downto 8));
         when others =>
            next_kernel_data <= std_ulogic_vector(sdrc_o_data(7 downto 0));
         end case;
         -- wait until command is finished
         if srdc_cmd_ready='1' then
             next_state  <= idle_e;
             next_ram_en <= '0';
             next_kernel_ack  <= '1';
             
             --if (rd_req_i or rd_pend)='1' then
             --  do_vid_rd_p;
             ----elsif ((kernel_clk_en_i and kernel_req_i) or kernel_req_pend)='1' then
             ----  do_kernel_acc_p;
             --end if;
         end if;
      when kernel_read_e =>
        if srdc_cmd_ready='0' then
           next_state   <= dram_busy_e;

 --          set_kernel_data  <= '1';
 --         case kernel_addr_i(1 downto 0) is
 --           when "00" =>
 --              next_kernel_data <= std_ulogic_vector(sdrc_o_data(7 downto 0));
 --           when "01" =>
 --              next_kernel_data <= std_ulogic_vector(sdrc_o_data(15 downto 8));
 --           when "10" =>
 --              next_kernel_data <= std_ulogic_vector(sdrc_o_data(23 downto 16));
 --           when others =>
 --              next_kernel_data <= std_ulogic_vector(sdrc_o_data(31 downto 24));
 --         end case;
           
        end if;
      when kernel_write_e =>
         -- wait until command execution starts
         if srdc_cmd_ready='0' then
            next_state       <= dram_busy_e;
            --next_kernel_ack  <= '1';
         end if;
      when refresh_e =>
         refresh_done <= '1';
         next_ram_en  <= '0';
         next_state   <= idle_e;
      when others =>
        next_state  <= idle_e;
        next_ram_en <= '0';
    end case;
  end process;

  process(clk_i,reset_n_i)
  begin
    if reset_n_i = ResetActive_c then
      state       <= init_e;
      ram_address <= (others => '0');
      wr_data     <= (others => '0');
      --rd_data     <= (others => '0');
      kernel_data <= (others => '0');
      ram_wren    <= '0';
      ram_en      <= '0';
      ram_refresh <= '0';
      kernel_req_pend <= '0';
      rd_pend     <= '0';
      kernel_ack_o<= '0';
      rd_ack_o    <= '0';
      --ram_bhe     <= '0';
      --ram_ble     <= '0';
      sdrc_dqm      <= (others => '0');
      sdrc_read_burst <= '0';
      refresh_timer <= 0;
      do_refresh    <= '0';
      --cmd_busy      <= '0';
      --sdrc_data_len <= (others => '0');

    elsif rising_edge(clk_i) then
      if clk_en_i = '1' then
         state       <= next_state;
         if set_ram_address  = '1' then
          ram_address <= next_ram_address;
         end if;
         --if set_rd_data = '1' then
         --  rd_data     <= next_rd_data;
         --end if;
         if set_kernel_data = '1' then
          kernel_data <= next_kernel_data;
         end if;
         ram_wren    <= next_ram_wren;
         ram_en      <= next_ram_en;
         ram_refresh <= next_ram_refresh;
         --ram_bhe     <= next_ram_bhe;
         --ram_ble     <= next_ram_ble;
         sdrc_dqm    <= next_sdrc_dqm;
         --sdrc_data_len <= next_sdrc_data_len;
         sdrc_read_burst <= next_sdrc_read_burst;

         kernel_ack_o<= next_kernel_ack;
         rd_ack_o    <= next_rd_ack;

         if (kernel_clk_en_i and kernel_req_i)='1' then
          kernel_req_pend  <= '1';
          wr_data  <= kernel_data_i;
         end if;
         if next_kernel_ack ='1' then
          kernel_req_pend   <= '0';
         end if;
         if rd_req_i='1' then
          rd_pend   <= '1';
         end if;
         if next_rd_ack ='1' then
          rd_pend   <= '0';
         end if;
         if refresh_timer = (Refresh_time_c-1) then
            refresh_timer <= 0;
            do_refresh    <= '1';
         else
            refresh_timer <= refresh_timer + 1;
         end if;
         if refresh_done ='1' then
            do_refresh    <= '0';
         end if;
--        if (sdrc_wr_n and sdrc_rd_n)='0' then
--          cmd_busy      <= '1';
--        end if;
--        if sdrc_wrd_ack='1' then
--          cmd_busy      <= '0';
--        end if;

      end if;
    end if;
  end process;
  --sdrc_wr_n <= '0' when ram_en ='1' and ram_wren = '1' else
  --             '1';
  --sdrc_rd_n <= '0' when ram_en ='1' and ram_wren = '0' else
  --             '1';

  kernel_busy_o   <= kernel_req_pend;
  rd_busy_o       <= rd_pend;
  rd_data_o       <= std_ulogic_vector(sdrc_o_data);
  rd_data_valid_o <= rd_data_valid; 
  kernel_data_o   <= kernel_data;
  --

end architecture rtl;

