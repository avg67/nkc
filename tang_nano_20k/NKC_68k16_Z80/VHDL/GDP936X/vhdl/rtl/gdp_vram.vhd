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
  generic (
   cpu_early_ack_g : boolean :=true   -- 68k needs early ack, Z80 not, acknowledge read-access early (only for 68000 possible)
  );
  port (
    clk_i             : in  std_ulogic;
    clk_en_i          : in  std_ulogic;
    sdctrl_clk_i      : in  std_ulogic;   -- needs to be synch to clk_o
    --sdram_clk_i       : in  std_ulogic;   -- same fraquency as sdctrl_clk_i but maybe phase shifted
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
    
    cpu_req_i         : in  std_ulogic;
    cpu_wr_i          : in  std_ulogic;
    cpu_addr_i        : in  std_ulogic_vector(21 downto 0);
    cpu_data_i        : in  std_ulogic_vector(15 downto 0);
    cpu_data_bv_i     : in  std_ulogic_vector(1 downto 0);
    cpu_data_o        : out std_ulogic_vector(15 downto 0);
    cpu_busy_o        : out std_ulogic;
    cpu_ack_o         : out std_ulogic;

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
  constant early_request_c                  : boolean := true;
  constant Refresh_time_c                   : natural := 600; -- 4096 times every 64ms -> every 15 us
  type state_t is(init_e,idle_e,kernel_write_e,kernel_read_e,dram_busy_e,vid_read_e,vid_busy_e, refresh_e, cpu_write_e,cpu_read_e, dram_cpu_busy_e);
  signal wr_data                            : std_ulogic_vector(7 downto 0);
  signal kernel_data, next_kernel_data      : std_ulogic_vector(7 downto 0);
  signal set_kernel_data                    : std_ulogic;
  signal cpu_data, next_cpu_data            : std_ulogic_vector(31 downto 0);
  --signal stored_cpu_data                    : std_ulogic_vector(31 downto 0);
  --signal set_cpu_data,next_set_cpu_data     : std_ulogic;
  signal set_store_data, store_data         : std_ulogic;
  signal state,next_state                   : state_t;
  signal ram_address, next_ram_address      : std_ulogic_vector(20 downto 0);
  signal set_ram_address                    : std_ulogic;
  signal kernel_req_pend                    : std_ulogic;
  signal next_kernel_ack                    : std_ulogic;
  signal cpu_req_pend                       : std_ulogic;
  signal next_cpu_ack                       : std_ulogic;
  signal rd_pend                            : std_ulogic;
  signal next_rd_ack                        : std_ulogic;
  signal ram_wren, next_ram_wren            : std_ulogic;
  signal ram_en, next_ram_en                : std_ulogic;
  signal ram_refresh, next_ram_refresh      : std_logic;
  signal refresh_timer                      : natural range 0 to Refresh_time_c;
  signal do_refresh, refresh_done           : std_ulogic;
  signal next_sdrc_dqm,sdrc_dqm             : std_ulogic_vector(3 downto 0);
  signal power_down                         : std_logic;
  signal sdrc_addr                          : std_logic_vector(20 downto 0);
  signal sdrc_i_data                        : std_ulogic_vector(31 downto 0);
  signal sdrc_o_data                        : std_logic_vector(31 downto 0);
  signal next_sdrc_read_burst, sdrc_read_burst   : std_logic;
  signal sdrc_init_done                     : std_logic;
  signal srdc_cmd_ready                     : std_logic;
  signal sdrc_rd_valid                         : std_logic; -- fast clock
  signal sdrc_rd_valid_tgl,sdrc_rd_valid_tgl_d : std_logic; -- fast clock
  signal sdram_rd_data_valid                   : std_logic;
  signal rd_data_valid                      : std_logic;
  signal cpu_prio, next_cpu_prio            : std_ulogic;
  signal is_cpu_acc, next_is_cpu_acc        : std_ulogic;
  signal next_cpu_req                       : std_ulogic;
  signal next_cache_hit, cache_hit          : std_ulogic;
  signal cpu_req_almost_done                : std_ulogic;
begin


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
                    
         clk_i            => sdctrl_clk_i,
         reset_n_i        => reset_n_i,
                          
         ready_o          => sdrc_init_done,
         refresh_i        => ram_refresh,
         din              => sdrc_i_data,
         dout             => sdrc_o_data,
         dout_valid_o     => sdrc_rd_valid, -- 80 MHz 
         dout_valid_tgl_o => sdrc_rd_valid_tgl,
         addr_i           => sdrc_addr,
         ds_i             => sdrc_dqm,
         cs_i             => ram_en,
         we_i             => ram_wren,
         cmd_ready_o      => srdc_cmd_ready,
         read_burst_i     => sdrc_read_burst
      );

   sdram_rd_data_valid <= sdrc_rd_valid_tgl xor sdrc_rd_valid_tgl_d;

    power_down  <= '0';
    sdrc_addr   <=  std_logic_vector(ram_address);
    sdrc_i_data <= wr_data & wr_data & wr_data & wr_data when is_cpu_acc='0' else
                   cpu_data_i & cpu_data_i;


  -- RAM Arbiter FSM for ext. SDRAM
  process(state,ram_address, kernel_addr_i,kernel_wr_i,rd_addr_i,wr_data,ram_wren, ram_en, ram_refresh,
          kernel_req_i,kernel_req_pend,rd_req_i,rd_pend,kernel_data,kernel_clk_en_i,do_refresh,
          sdrc_o_data,sdrc_dqm,srdc_cmd_ready,sdrc_init_done,sdrc_read_burst,sdrc_rd_valid,sdram_rd_data_valid,
          next_cpu_req,cpu_req_pend,cpu_wr_i,cpu_addr_i,cpu_data_bv_i,cpu_prio,is_cpu_acc
         )
    variable cpu_req_v, kernel_req_v : std_ulogic;
    procedure do_kernel_acc_p is
    begin
      set_ram_address      <= '1';
      next_ram_address     <= "111" & kernel_addr_i(19 downto 2); -- 1MB (20 bit) VRAM (0x70_0000)
      next_ram_wren        <= kernel_wr_i;
      next_sdrc_read_burst <= '0';
      next_is_cpu_acc      <= '0';
      next_ram_en <= '1';
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
    end procedure;
    
    procedure do_cpu_acc_p is
    begin
      set_ram_address      <= '1';
      next_ram_address     <= cpu_addr_i(21 downto 1);
      next_ram_wren        <= cpu_wr_i;
      next_ram_en          <= '1';
      next_sdrc_read_burst <= '0';
      next_is_cpu_acc      <= '1';

      if cpu_wr_i='1' then
         next_sdrc_dqm    <= (others => '0');
         case cpu_addr_i(0) is
           when '0' =>
              next_sdrc_dqm(3 downto 2) <= cpu_data_bv_i;
           when others =>
              next_sdrc_dqm(1 downto 0) <= cpu_data_bv_i;
         end case;
        
         next_state     <= cpu_write_e;
      else
         next_sdrc_dqm  <= (others => '1');
         next_state     <= cpu_read_e;
      end if;

    end procedure;
    procedure do_vid_rd_p is
    begin
      set_ram_address  <= '1';
      next_ram_address <= "111" & rd_addr_i;
      next_ram_en      <= '1';
      next_ram_wren    <= '0';
      next_sdrc_dqm    <= (others => '1');
      next_sdrc_read_burst <= '1';
      next_state       <= vid_read_e;
      next_is_cpu_acc  <= '0';
    end procedure;
    procedure do_refresh_p is
    begin
      next_ram_wren        <= '0';
      next_sdrc_read_burst <= '0';
      next_ram_en          <= '1';
      next_state           <= refresh_e;
      next_ram_refresh     <= '1';
      next_is_cpu_acc      <= '0';
    end procedure;
  begin
    next_state      <= state;
    next_kernel_ack <= '0';
    next_cpu_ack    <= '0';
    next_rd_ack     <= '0';
    next_ram_address <= (others => '-');
    set_ram_address  <= '0';
    next_cpu_prio    <= cpu_prio;
    next_kernel_data <= (others => '-');
    set_kernel_data  <= '0';
    set_store_data   <= '0';
    --next_cpu_data    <= (others => '-');
    next_ram_wren    <= ram_wren;
    next_ram_en      <= ram_en;
    next_ram_refresh <= '0';
    next_sdrc_dqm    <= sdrc_dqm;
    next_sdrc_read_burst <= sdrc_read_burst;
    rd_data_valid        <= '0';
    refresh_done         <= '0';
    next_is_cpu_acc      <= is_cpu_acc;
    cpu_req_almost_done  <= '0';
    cpu_req_v    := next_cpu_req or cpu_req_pend;
    kernel_req_v := (kernel_clk_en_i and kernel_req_i) or kernel_req_pend;

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
            elsif cpu_req_v='1' then
              do_cpu_acc_p;
            elsif kernel_req_v='1' then
              do_kernel_acc_p;
            end if;
         end if;

      when vid_read_e =>
        if srdc_cmd_ready='0' then
          next_state   <= vid_busy_e;
            next_ram_en  <= '0'; -- !!! Terminate CS early
        end if;
        
      when vid_busy_e =>
        rd_data_valid <= sdrc_rd_valid;
        if srdc_cmd_ready='1' then
          next_state   <= idle_e;
          next_ram_en  <= '0';
          next_rd_ack  <= '1';
            if early_request_c then
               if do_refresh ='1' then
                  do_refresh_p;
               elsif ((kernel_clk_en_i and kernel_req_i) or kernel_req_pend)='1' then
                  do_kernel_acc_p;
               elsif cpu_req_v='1' then
                  do_cpu_acc_p;
               end if;
            end if;
              
        end if;
      
      
      when dram_busy_e =>
         set_kernel_data  <= sdram_rd_data_valid and not ram_wren;
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
             
            if early_request_c then
               if (rd_req_i or rd_pend)='1' then
                 do_vid_rd_p;
               elsif do_refresh ='1' then
                 do_refresh_p;
                --elsif ((kernel_clk_en_i and kernel_req_i) or kernel_req_pend)='1' then
                --  do_kernel_acc_p;
               elsif cpu_req_v='1' then
                  do_cpu_acc_p;
               end if;
            end if;
         end if;
      when kernel_read_e =>
        if srdc_cmd_ready='0' then
           next_state   <= dram_busy_e;
           next_ram_en  <= '0'; -- !!! Terminate CS early
        end if;
      when kernel_write_e =>
         -- wait until command execution starts
         if srdc_cmd_ready='0' then
            --next_state       <= dram_busy_e;
	    next_state       <= idle_e;
            next_ram_en      <= '0'; -- !!! Terminate CS early
            next_kernel_ack  <= '1';   -- !!! early kernel ack
         end if;
      when cpu_read_e =>
        if srdc_cmd_ready='0' then
           next_state   <= dram_cpu_busy_e;
           next_ram_en  <= '0'; -- !!! Terminate CS early
           if cpu_early_ack_g then  
               next_cpu_ack <= '1';
           end if;
        end if;
      when cpu_write_e =>
         -- wait until command execution starts
         if srdc_cmd_ready='0' then
            --next_state       <= dram_cpu_busy_e;
            --if cpu_early_ack_g then
               next_cpu_ack     <= '1';
            --end if;
            next_state       <= idle_e;
            next_ram_en      <= '0'; -- !!! Terminate CS early
         end if;
      when dram_cpu_busy_e =>
         cpu_req_almost_done <= '1';
         --set_cpu_data  <= sdrc_rd_valid and not ram_wren;
         set_store_data <=  not ram_wren;
         --next_cpu_data      <= std_ulogic_vector(sdrc_o_data);
         -- wait until command is finished
         if srdc_cmd_ready='1' then
            next_state   <= idle_e;
            next_ram_en  <= '0';
            if not cpu_early_ack_g then
               next_cpu_ack <= '1';
            end if;
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

  next_cpu_data      <= std_ulogic_vector(sdrc_o_data);

  process(clk_i,reset_n_i)
  begin
    if reset_n_i = ResetActive_c then
      state       <= init_e;
      ram_address <= (others => '0');
      wr_data     <= (others => '0');
      --rd_data     <= (others => '0');
      kernel_data <= (others => '0');
      cpu_data    <= (others => '0');
      ram_wren    <= '0';
      ram_en      <= '0';
      ram_refresh <= '0';
      kernel_req_pend <= '0';
      cpu_req_pend    <= '0';
      rd_pend     <= '0';
      kernel_ack_o<= '0';
      cpu_ack_o   <= '0';
      rd_ack_o    <= '0';
      sdrc_dqm      <= (others => '0');
      sdrc_read_burst <= '0';
      refresh_timer <= 0;
      do_refresh    <= '0';
      cpu_prio      <= '0';
      is_cpu_acc    <= '0';
      store_data    <= '0';
      sdrc_rd_valid_tgl_d <= '0';
    elsif rising_edge(clk_i) then
      if clk_en_i = '1' then
         state       <= next_state;
         if set_ram_address  = '1' then
          ram_address <= next_ram_address;
         end if;
         if set_kernel_data = '1' then
          kernel_data <= next_kernel_data;
         end if;
         if set_store_data='1' then
            store_data <= '1';
         end if;
         if ((set_store_data or store_data) and sdram_rd_data_valid)='1' then
            store_data <= '0';
            cpu_data   <= next_cpu_data;
         --elsif next_cache_hit='1' then
         --   cpu_data <= stored_cpu_data;
         end if;
         
         --if set_cpu_data = '1' then
         --  cpu_data <= next_cpu_data;
         --elsif next_cache_hit='1' then
         --  cpu_data <= stored_cpu_data;
         --end if;
         ram_wren    <= next_ram_wren;
         ram_en      <= next_ram_en;
         ram_refresh <= next_ram_refresh;
         sdrc_dqm    <= next_sdrc_dqm;
         sdrc_read_burst <= next_sdrc_read_burst;
         sdrc_rd_valid_tgl_d <= sdrc_rd_valid_tgl;

         kernel_ack_o<= next_kernel_ack;
         cpu_ack_o   <= next_cpu_ack;
         rd_ack_o    <= next_rd_ack;

         if (kernel_clk_en_i and kernel_req_i)='1' then
            kernel_req_pend  <= '1';
            wr_data          <= kernel_data_i;
         end if;
         if next_kernel_ack ='1' then
            kernel_req_pend   <= '0';
         end if;
         if (next_cpu_req)='1' then
            cpu_req_pend  <= '1';
         end if;
         if next_cpu_ack ='1' then
            cpu_req_pend   <= '0';
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
         cpu_prio   <= next_cpu_prio;
         is_cpu_acc <= next_is_cpu_acc;
      end if;
    end if;
  end process;

  kernel_busy_o   <= kernel_req_pend;
  cpu_busy_o      <= cpu_req_pend;
  rd_busy_o       <= rd_pend;
  rd_data_o       <= std_ulogic_vector(sdrc_o_data);
  rd_data_valid_o <= rd_data_valid; 
  kernel_data_o   <= kernel_data;
  
  
  CPU_RD: block
    type cpu_rd_state_t is (IDLE_e, RD_REQ_e);
    signal next_cpu_rd_state, cpu_rd_state             : cpu_rd_state_t;
    signal next_stored_cpu_address, stored_cpu_address : std_ulogic_vector(cpu_addr_i'high downto 1);
    --signal next_stored_cpu_data                        : std_ulogic_vector(31 downto 0);
    signal next_cache_valid, cache_valid               : std_ulogic;
    signal cpu_data1                                   : std_ulogic_vector(cpu_data'range);
    
    pure function check_x(v : in std_ulogic_vector) return std_ulogic_vector is
      variable tmp_v : std_ulogic_vector(v'range);
    begin
      tmp_v := v;
      -- pragma translate_off
      for i in tmp_v'range loop
        if is_x(tmp_v(i)) then
          tmp_v(i) := '0';
        end if;
      end loop;
      -- pragma translate_on
      return tmp_v;
    end check_x;
  begin
    
    process(cpu_addr_i,cpu_data1) is
      variable tmp_v : std_ulogic_vector(cpu_data'range);
    begin
      case cpu_addr_i(0) is
        when '0' =>
            cpu_data_o <= cpu_data1(31 downto 16);
        when others =>
            cpu_data_o <= cpu_data1(15 downto 0);
      end case;
    end process;
    
--
  --cpu_data1  <= check_x(std_ulogic_vector(sdrc_o_data)) when ((set_store_data or store_data) and sdrc_rd_valid)='1' else
  cpu_data1  <= check_x(std_ulogic_vector(sdrc_o_data)) when ((set_store_data or store_data) and sdram_rd_data_valid)='1' else
                check_x(cpu_data); 
--  cpu_data_o <= cpu_data1; --cpu_data1;
  
    process(cpu_rd_state, cpu_req_i, cpu_wr_i, cpu_addr_i, cpu_data1, cache_valid,
            stored_cpu_address, sdrc_o_data, set_store_data, store_data, sdram_rd_data_valid)
    begin
      next_cpu_rd_state       <= cpu_rd_state;
      next_cpu_req            <= cpu_req_i;
      next_stored_cpu_address <= stored_cpu_address;
      --next_stored_cpu_data    <= stored_cpu_data;
      next_cache_valid        <= cache_valid;
      next_cache_hit          <= '0';

      case cpu_rd_state is
        when IDLE_e =>
          if (cache_valid and cpu_req_i and not cpu_wr_i)='1' and stored_cpu_address = cpu_addr_i(cpu_addr_i'high downto 1) then
            -- it's a cache hit
            next_cpu_req   <= '0';
            next_cache_hit <= '1';
--            case cpu_addr_i(0) is
--              when '0' =>
--                 next_cpu_rd_data <= std_ulogic_vector(stored_cpu_data(31 downto 16));
--              when others =>
--                 next_cpu_rd_data <= std_ulogic_vector(stored_cpu_data(15 downto 0));
--            end case;

          elsif (cpu_req_i and not cpu_wr_i)='1' then
            next_cpu_rd_state <= RD_REQ_e;
            next_cache_valid  <= '0';
          elsif (cpu_req_i and cpu_wr_i)='1'  and stored_cpu_address = cpu_addr_i(cpu_addr_i'high downto 1) then
            next_cache_valid  <= '0';
          end if;
        when RD_REQ_e =>
          --if set_cpu_data='1' then
          --if ((set_store_data or store_data) and sdrc_rd_valid) = '1' then
          if ((set_store_data or store_data) and sdram_rd_data_valid) = '1' then
            next_stored_cpu_address <= cpu_addr_i(cpu_addr_i'high downto 1);
            --next_stored_cpu_data    <= check_x(std_ulogic_vector(sdrc_o_data));
            next_cpu_rd_state       <= idle_e;
            next_cache_valid        <= '1';
          end if;
        when others => 
          next_cpu_rd_state <= idle_e;
      end case;
    end process;
    
    process(clk_i,reset_n_i)
    begin
      if reset_n_i = ResetActive_c then
        cpu_rd_state       <= IDLE_e;
        stored_cpu_address <= (others => '0');
        --stored_cpu_data    <= (others => '0');
        cache_valid        <= '0';
      elsif rising_edge(clk_i) then
        cpu_rd_state       <= next_cpu_rd_state;
        stored_cpu_address <= next_stored_cpu_address;
        --stored_cpu_data    <= next_stored_cpu_data;
        cache_valid        <= next_cache_valid;
      end if;
    end process;
  end block;

end architecture rtl;

