--------------------------------------------------------------------------------
-- Project     : Single Chip NDR Computer
-- Module      : 68k System on chip - Toplevel for HPE_MINI_LEC
-- File        : soc_top.vhd
-- Description :
--------------------------------------------------------------------------------
-- Author       : Andreas Voggeneder
-- Organisation : FH-Hagenberg
-- Department   : Hardware/Software Systems Engineering
-- Language     : VHDL'87
--------------------------------------------------------------------------------
-- Copyright (c) 2023 by Andreas Voggeneder
--------------------------------------------------------------------------------
library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.DffGlobal.all;
--use work.gdp_global.all;

entity soc_top is
  generic(sim_g      : boolean := false);
  port(--reset_n_i     : in  std_ulogic;
       reset_i     : in  std_ulogic;
       clk_i         : in  std_ulogic;
       --------------------------
       -- SRAM/Flash Databus
       --------------------------
       SRAM_nCS_o    : out std_logic;
       SRAM_ADR_o    : out std_logic_vector(22 downto 0);
       SRAM_DB_io    : inout std_logic_vector(31 downto 0);
       SRAM_nWR_o    : out std_logic;
       SRAM_nOE_o    : out std_logic;
       SRAM_nBE_o    : out std_logic_vector(3 downto 0);
       FLASH_nCE_o   : out std_logic;
       FLASH_nWP_o   : out std_logic;
       FLASH_RESET_o : out std_logic;
       FLASH_nBYTE_o : out std_logic;
       FLASH_nRYBY_i : in  std_logic_vector(1 downto 0):="11";
       --------------------------
       -- UART Receiver
       --------------------------
       RxD_i    : in  std_ulogic;
       TxD_o    : out std_ulogic;
       RTS_o    : out std_ulogic;
       CTS_i    : in  std_ulogic;
       
       gpio_io       : inout std_logic_vector(7 downto 0)

       );
end soc_top;
-- 0 - 007fffff ... external Memory
architecture rtl of soc_top is
   constant boot_rom_addr_bits_c : natural := 10;
   constant boot_rom_addr_c : std_logic_vector(31 downto 0) := X"00800000";
   constant flash_addr_c    : std_logic_vector(31 downto 0) := X"00100000";
   constant use_gen_rom_c   : boolean := sim_g;
   constant use_ser1_c      : boolean := true;
   constant SER_BASE_ADDR_c    : std_logic_vector(7 downto 0) := X"F0"; -- r/w  
   
   type state_t is (IDLE_e, REQ_e);
   signal reset_n           : std_ulogic;
   signal state, next_state : state_t;
   signal cpu_run     : std_logic := '1';
   signal cpu_run1    : std_logic;
   signal cpu_datain  : std_logic_vector(15 downto 0);
   signal cpu_addr    : std_logic_vector(31 downto 0);
   signal cpu_dataout : std_logic_vector(15 downto 0);
   signal cpu_r_w     : std_logic;
   signal cpu_uds     : std_logic;
   signal cpu_lds     : std_logic;
   --signal cpu_addr_r    : std_logic_vector(31 downto 0);
   --signal cpu_dataout_r : std_logic_vector(15 downto 0);
   --signal cpu_r_w_r     : std_logic;
   --signal cpu_uds_r     : std_logic;
   --signal cpu_lds_r     : std_logic;
   signal busstate    : std_logic_vector(1 downto 0);
   signal busstate_r  : std_logic_vector(1 downto 0);
   signal tg68_ready  : std_logic;
   signal rom_q       : std_logic_vector(15 downto 0);
   signal cpu_req     : std_logic;
   signal cpu_req_r   : std_logic;
   signal cpu_ack     : std_logic;
   signal iorq        : std_logic;
   signal gpio_ddr    : std_logic_vector(7 downto 0);
   signal gpio_data   : std_logic_vector(7 downto 0);
   signal gpio_read_data : std_logic_vector(7 downto 0);
   signal io_data_r   : std_logic_vector(7 downto 0);
   signal gpio_sync   : std_logic_vector(7 downto 0);
   signal gpio_en     : std_logic;
   signal io_en_r     : std_logic;
   signal io_rd, io_wr: std_logic;
   
   signal ser_cs            : std_ulogic;
   signal ser_data          : std_ulogic_vector(7 downto 0);
   signal ser_int           : std_ulogic;
   
   signal boot_rom_always_en : std_logic;
   signal boot_active        : std_logic;
   signal boot_active_r      : std_logic;
   --signal rom_en      : std_logic;
   signal acc_en             : std_logic;
   signal ExSel              : std_logic;
   signal ExSel_wr           : std_logic;
   signal ExSel_rd           : std_logic;
   signal ExSel_r            : std_logic;
   signal ExSel_rd_r         : std_logic;
   signal ExWr               : std_logic;
   signal ExDI               : std_logic_vector(31 downto 0);
   signal ExDI_r             : std_logic_vector(15 downto 0);
   signal flash_latch_r      : std_logic_vector(15 downto 0);
--   signal rom_q_r     : std_logic_vector(15 downto 0);

   signal Flash_en,Flash_en1      : std_logic;
   signal Flash_latch_en          : std_logic;
   signal flash_ack               : std_logic;
   signal EthWait,FlashWait,Ready : std_logic;
   signal FlashWait_r             : std_logic;
   signal ws_cnt                  : natural range 0 to 2;
   
   signal SRAM_nCS_s    : std_logic;
   signal SRAM_ADR_s    : std_logic_vector(22 downto 0);
   signal SRAM_nWR_s    : std_logic;
   signal SRAM_nOE_s    : std_logic;
   signal SRAM_nBE_s    : std_logic_vector(3 downto 0);
   signal FLASH_nCE_s   : std_logic;
   signal FLASH_we_n    : std_logic;
   
   signal SRAM_nCS_r    : std_logic;
   signal SRAM_ADR_r    : std_logic_vector(22 downto 0);
   signal SRAM_nWR_r    : std_logic;
   signal SRAM_nOE_r    : std_logic;
   signal SRAM_nBE_r    : std_logic_vector(3 downto 0);
   signal FLASH_nCE_r   : std_logic;
   signal EXT_Dout_r    : std_logic_vector(31 downto 0);
   
   signal FLASH_nRYBY_sync : std_logic_vector(1 downto 0);

   component test_rom is
      port (
        clock   : in  std_logic;
        address : in  std_logic_vector(5 downto 0);
        q       : out std_logic_vector(15 downto 0)
      );
   end component;
   component Monitor_rom is
      port (
        clock   : in  std_logic;
        address : in  std_logic_vector(10 downto 0);
        q       : out std_logic_vector(15 downto 0)
      );
   end component;
   
begin

   EthWait <= '0';

  sync_reset: if not sim_g generate
    reset_sync: process(clk_i)
      variable tmp_v : std_ulogic_vector(1 downto 0):= "00";
    begin
      if rising_edge(clk_i) then
        reset_n  <= tmp_v(1);
        tmp_v(1) := tmp_v(0);
        tmp_v(0) := not reset_i;
      end if;
    end process reset_sync;
  end generate;
  
  nosync_reset: if sim_g generate
    reset_n  <= not reset_i;
  end generate;

--   ROM_inst : entity work.test_ROM
--   generic map
--   (
--      maxAddrBitBRAM => 10 -- Specify your actual ROM size to save LEs and unnecessary block RAM usage.
--   )
--   port map (
--      clk     => clk_i,
--      reset_n => reset_n_i,
--      addr    => cpu_addr(10 downto 0),
--      q       => rom_q
--      -- Allow writes - defaults supplied to simplify projects that don't need to write.
--      --d       => zeros(15 downto 0),
--      --we_n    => '0'
--      --uds_n   =>
--      --lds_n 
--   );
   gen_rom: if use_gen_rom_c generate 
     ROM_inst : Monitor_rom
        port map (
           address           => cpu_addr(11 downto 1), 
           clock             => clk_i, 
           Q                 => rom_q
        );
   end generate;
   brom: if not use_gen_rom_c generate 
      ROM_inst : entity work.boot_rom
         port map (
            Address(10 downto 0) => cpu_addr(11 downto 1), 
            OutClock             => clk_i, 
            OutClockEn           => '1', 
            Reset                => '0', 
            Q(15 downto 0)       => rom_q
         );
   end generate;
   
--   cpu_ack <= cpu_run and ready;

   --cpu_req <= '1' when busstate/="01" and cpu_run='1' else '0';
   cpu_req <= '1' when busstate/="01" and cpu_ack='0' else '0';
   
   boot_active <= '1' when busstate/="01" and cpu_addr(31 downto boot_rom_addr_bits_c) = boot_rom_addr_c(31 downto boot_rom_addr_bits_c) else
                  '0';
   
   process(clk_i,reset_n)
   begin
      if reset_n = '0' then
--         cpu_run       <= '1';
         cpu_req_r     <= '0';
         boot_active_r <= '0';
         FlashWait_r   <= '0';
         state         <= IDLE_e;
      elsif rising_edge(clk_i) then
         state <= next_state;
         boot_active_r <= boot_active;
         cpu_req_r <= cpu_req;
--         cpu_run   <= '1';
         
         --if (cpu_req and not cpu_req_r)='1' then
         --   cpu_run   <='0';
         --end if;
--         if cpu_req = '1' then
--            cpu_run   <='0';
--         end if;
--         if cpu_ack = '1' then
--            cpu_run   <='1';
--         end if;
         FlashWait_r <= FlashWait;
         --rom_q_r <= rom_q;
      end if;
   end process;
   
   
   process(state, cpu_req, ready, ws_cnt, SRAM_nWR_s, Flash_en)
   begin
      next_state <= state;
      cpu_ack    <= '0';
      acc_en     <= '0';
      FLASH_we_n <= SRAM_nWR_s;
      case state is
         when IDLE_e =>
            if cpu_req='1' then
               next_state <= REQ_e;
               acc_en     <= '1';
            end if;
         when REQ_e =>
            acc_en     <= '1';
            if ready = '1' then
               cpu_ack    <= '1';
               next_state <= IDLE_e;
               acc_en     <= '0';
            end if;
            if (Flash_en and not SRAM_nWR_s) = '1' and ws_cnt>=2 then
               FLASH_we_n <= '1';
            end if;
         when others => 
            next_state <= IDLE_e;
      end case;
   
   end process;
   
   
   
--   cpu_run1 <= '0' when FlashWait ='1' or (busstate_r ="01" and busstate /="01") else 
----               '1' when (FlashWait_r and not FlashWait)='1' else
--               cpu_run;
   cpu_run1 <= '0' when (cpu_req and not cpu_ack)='1' or (busstate_r ="01" and busstate /="01") else 
               '1';
               

   process(clk_i)
   begin
    if rising_edge(clk_i) then
      --cpu_dataout_r <= cpu_dataout;
      --cpu_addr_r    <= cpu_addr;
      --cpu_uds_r     <= cpu_uds;
      --cpu_lds_r     <= cpu_lds;
      --cpu_r_w_r     <= cpu_r_w;
      busstate_r    <= busstate;
    end if;
   end process;

   myTG68 : entity work.TG68KdotC_Kernel
   generic map(
      MUL_Mode => 1
   )
   port map(
      clk            => clk_i,
      nReset         => reset_n,
      clkena_in      => cpu_run1,
      data_in        => cpu_datain,
      IPL            => "111",
      IPL_autovector => '1',
      CPU            => "00",
      addr           => cpu_addr,
      data_write     => cpu_dataout,
      nWr            => cpu_r_w,
      nUDS           => cpu_uds,
      nLDS           => cpu_lds,
      busstate       => busstate,
      nResetOut      => tg68_ready
   );
      
   cpu_datain <= ExDI_r when ExSel_rd_r = '1' else
                 io_data_r & "--------" when io_en_r='1' else
                 rom_q;


   iorq <= '1' when cpu_addr(31 downto 16) = X"FFFF" and busstate /= "01" else
           '0';
   gpio_en <= iorq when cpu_addr(7 downto 3) = "00000" else
              '0';
   io_rd <= iorq and not cpu_uds and     cpu_r_w and not cpu_run1;
   io_wr <= iorq and not cpu_uds and not cpu_r_w and cpu_run1;
   
   Ready <= '0' when (EthWait or FlashWait)='1' else 
            '1';
   process(clk_i,reset_n)
   begin
      if reset_n = '0' then
         ExDI_r      <= (others =>'0');
         ExSel_r     <= '0';
         ExSel_rd_r  <= '0';
         ws_cnt      <= 0;
         gpio_ddr    <= (others =>'0');
         gpio_data   <= (others =>'0');
         io_data_r   <= (others =>'0');
         io_en_r     <= '0';
         flash_ack   <='0';
         boot_rom_always_en <= '1';
         flash_latch_r<= (others => '0');
      elsif rising_edge(clk_i) then
         if boot_active='1' then
            boot_rom_always_en <= '0';
         end if;
         if Ready='1' then
            ExSel_r <= ExSel;
         end if;
         flash_ack<='0';
         if Flash_en='0' then
            if cpu_run1 = '0' then
               ExSel_rd_r <= '0';
               
               if ExSel_rd = '1' then
                  if cpu_addr(1)='1' then
                     ExDI_r <= ExDI(31 downto 16);
                  else
                     ExDI_r <= ExDI(15 downto 0);
                  end if;
                  ExSel_rd_r <= '1';
               end if;
            else
               ExSel_r <= '0';
            end if;
            ws_cnt <= 0;
         else
            -- Flash
            ExSel_rd_r <= '0';
--            if Ready ='1' then
--               if cpu_addr(1)='0' then
--                  ExDI_r <= ExDI(31 downto 16);
--               else
--                  ExDI_r <= ExDI(15 downto 0);
--               end if;
--               ExSel_rd_r <= '1';
--            end if;
            if ws_cnt/=2 then
              ws_cnt <= ws_cnt+1;
            elsif cpu_ack='1' then 
               ws_cnt <= 0;
            end if;
            if ws_cnt=2 then
              flash_ack<='1';
              if cpu_addr(1)='0' then
                  ExDI_r <= ExDI(31 downto 16);
               else
                  ExDI_r <= ExDI(15 downto 0);
               end if;
               ExSel_rd_r <= '1';
            end if;
         end if;
         if (flash_latch_en='1') then
            if cpu_uds='0' then
               flash_latch_r(15 downto 8) <= cpu_dataout(15 downto 8);
            end if;
            if cpu_lds='0' then
               flash_latch_r(7 downto 0) <= cpu_dataout(7 downto 0);
            end if;
         end if;
         -- generic IO
         io_en_r   <= (iorq and not cpu_uds);
         if (iorq and not io_en_r and cpu_r_w)= '1' then
            if gpio_en='1'  then
               io_data_r <= gpio_read_data;
            elsif ser_cs='1' then
               io_data_r <= std_logic_vector(ser_data);
            else
               io_data_r <= (others => '1');
            end if;
         end if;
         -- GPIO
         if (gpio_en and not cpu_uds)='1' then
            if cpu_r_w = '0' then
               if cpu_addr(2 downto 1)="00" then
                  gpio_ddr <= cpu_dataout(15 downto 8);
               elsif cpu_addr(2 downto 1)="01" then
                  gpio_data <= cpu_dataout(15 downto 8);
               end if;
            end if;
         end if;
      end if;
   end process;
   
   with cpu_addr(2 downto 1) select
	  gpio_read_data <= gpio_ddr  when "00",
                       gpio_sync when "01",
                       "000000" & FLASH_nRYBY_sync when others;
                       
   gpio_driver: for i in gpio_io'range generate
      gpio_io(i) <= gpio_data(i) when gpio_ddr(i) = '1' else
                    'Z';
-- pragma translate_off                    
      gpio_io(i) <='H';
-- pragma translate_on
      
      sync: entity work.inputsync
         port map (
            Input  => gpio_io(i),
            clk    => clk_i,
            clr_n  => reset_n,
            q      => gpio_sync(i)
         );
   end generate;
   is_inst: for i in FLASH_nRYBY_i'range generate
    sync: entity work.inputsync
         port map (
            Input  => FLASH_nRYBY_i(i),
            clk    => clk_i,
            clr_n  => reset_n,
            q      => FLASH_nRYBY_sync(i)
         );
  end generate;
   
-- ...._...._...._....__...._...._...._....
--    28   24   20  16     12   8    4    0
-- 1MB RAM, 2x a16mB Flash (0-00FF_FFFF) = 0 - 0200_0000
-- Address map:
-- 0x0000_0000 - 0x000F_FFFF  SRAM
-- 0x0010_0000 - 0x001F_FFFF  Flash
-- 0x0080_0000 - 0x0080_03FF  Boot-rom
   FLASH_nCE_s <= '0' when ((ExSel_rd or ExSel_wr) and Flash_en)='1' else
                  '1';
   FLASH_nWP_o   <= '1';
   FLASH_RESET_o <= reset_n;
   FLASH_nBYTE_o <= '1'; -- select Word mode
   
   --Flash_en1     <= '1' when ExSel='1' and unsigned(cpu_addr(31 downto 1)) >= unsigned(flash_addr_c(31 downto 1)) else
   Flash_en1     <= '1' when ExSel='1' and unsigned(cpu_addr(31 downto 20)) = unsigned(flash_addr_c(31 downto 20)) else
                    '0';
   Flash_en      <= Flash_en1 and (cpu_r_w or (not cpu_r_w and cpu_addr(1)));
   Flash_latch_en<= Flash_en1 and not cpu_r_w and not cpu_addr(1);
   
   SRAM_ADR_s  <= "00000" & cpu_addr(19 downto 2); --cpu_addr(23 downto 1);
   --SRAM_DB_io  <= cpu_dataout & cpu_dataout when ExWr = '1' else
   --              (others => 'Z') after 1 ns;
   ExDI       <= SRAM_DB_io;
   SRAM_nWR_s <= '0' when (ExSel_wr and ExWr)='1' else
                 '1';
   SRAM_nOE_s <= '0' when (ExSel_rd and not ExWr)='1' else
                 '1';
   --SRAM_nCS_s <= '0' when ((ExSel_rd or ExSel_wr) and not Flash_en1)='1' else 
   SRAM_nCS_s <= '0' when ((ExSel_rd or ExSel_wr)='1' and unsigned(cpu_addr(31 downto 20)) = 0) else 
                 '1';
   SRAM_nBE_s(0) <= not (ExSel and not cpu_uds and not cpu_addr(1));
   SRAM_nBE_s(1) <= not (ExSel and not cpu_lds and not cpu_addr(1));
   SRAM_nBE_s(2) <= not (ExSel and not cpu_uds and     cpu_addr(1));
   SRAM_nBE_s(3) <= not (ExSel and not cpu_lds and     cpu_addr(1));
   ExWr          <= not cpu_r_w;
   --ExSel_wr      <= cpu_run1  and  ExSel and ExWr;
   ExSel_wr      <= ExSel and  acc_en and ExWr;
   --ExSel_rd      <= ExSel and  not ExSel_r and not ExWr;
   ExSel_rd      <= ExSel and  acc_en and not ExWr;
   ExSel         <= '1' when boot_rom_always_en = '0' and busstate/="01" and 
                        unsigned(cpu_addr(31 downto 1)) < unsigned(boot_rom_addr_c(31 downto 1)) else
                    '0';
   --ExSel1 <= ExSel and cpu_run1;
   FlashWait <= '1' when Flash_en='1' and flash_ack='0' else
                '0';
   process(clk_i)
   begin
      if falling_edge(clk_i) then
         if Flash_en ='1' then
            EXT_Dout_r  <= flash_latch_r & cpu_dataout;
         else
            EXT_Dout_r  <= cpu_dataout & cpu_dataout;
         end if;
         SRAM_nCS_r  <= SRAM_nCS_s; 
         SRAM_ADR_r  <= SRAM_ADR_s; 
         SRAM_nWR_r  <= FLASH_we_n; --SRAM_nWR_s
         SRAM_nOE_r  <= SRAM_nOE_s; 
         SRAM_nBE_r  <= SRAM_nBE_s; 
         FLASH_nCE_r <= FLASH_nCE_s;
      end if;
   end process;
   
   SRAM_DB_io  <= EXT_Dout_r when SRAM_nWR_r = '0' else
                 (others => 'Z') after 1 ns;
   SRAM_nCS_o  <= SRAM_nCS_r ;
   SRAM_ADR_o  <= "00000" & SRAM_ADR_r(17 downto 0) ;
   SRAM_nWR_o  <= SRAM_nWR_r ;
   SRAM_nOE_o  <= SRAM_nOE_r ;
   SRAM_nBE_o  <= SRAM_nBE_r ;
   FLASH_nCE_o <= FLASH_nCE_r;
   
   
   impl_ser1: if use_ser1_c generate 
     ser_cs <= iorq when cpu_addr(8 downto 3) = SER_BASE_ADDR_c(7 downto 2) else -- 0xF0 - 0xF3
              '0';
     ser : entity work.Ser1
       port map (
         reset_n_i   => reset_n,
         clk_i       => clk_i,
         RxD_i       => RxD_i,
         TxD_o       => TxD_o,
         RTS_o       => RTS_o,
         CTS_i       => CTS_i,
         DTR_o       => open,
         Adr_i       => std_ulogic_vector(cpu_addr(2 downto 1)),
         en_i        => ser_cs,
         DataIn_i    => std_ulogic_vector(cpu_dataout(15 downto 8)),
         Rd_i        => io_rd,
         Wr_i        => io_wr,
         DataOut_o   => ser_data,
         Intr_o      => ser_int
       );
   end generate;
   no_ser1: if not use_ser1_c generate
    ser_data       <= (others =>'0');
    ser_cs         <= '0';
    RTS_o          <= CTS_i;
    TxD_o          <= RxD_i;
    ser_int        <= '0';
   end generate;     
   
   
end rtl;
