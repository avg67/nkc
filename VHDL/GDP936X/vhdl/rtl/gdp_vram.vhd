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
  use work.DffGlobal.all;

entity gdp_vram is
  generic(INT_CHR_ROM_g : boolean := true);
  port (
    clk_i             : in  std_ulogic;
    clk_en_i          : in  std_ulogic;
    reset_n_i         : in  std_ulogic;
    -- kernel port (read & write)
    kernel_clk_en_i   : in  std_ulogic;
    kernel_req_i      : in  std_ulogic;
    kernel_wr_i       : in  std_ulogic;
    kernel_addr_i     : in  std_ulogic_vector(17 downto 0);
    kernel_data_i     : in  std_ulogic_vector(7 downto 0);
    kernel_data_o     : out std_ulogic_vector(7 downto 0);
    kernel_busy_o     : out std_ulogic;
    kernel_ack_o      : out std_ulogic;
    -- character ROM and VRAM shares Address & Data-bus
    chr_rom_addr_i    : in  std_ulogic_vector(8 downto 0);
    chr_rom_data_o    : out std_ulogic_vector(7 downto 0);
    chr_rom_ena_i     : in  std_ulogic;
    chr_rom_busy_o    : out std_ulogic;

    -- video port (only read)
    rd_req_i          : in  std_ulogic;
    rd_addr_i         : in  std_ulogic_vector(17 downto 0);
    rd_data_o         : out std_ulogic_vector(7 downto 0);
    rd_busy_o         : out std_ulogic;
    rd_ack_o          : out std_ulogic;
    -- SRAM control signals
    sram_addr_o       : out std_ulogic_vector(16 downto 0);
    sram_data_o       : out std_ulogic_vector(7 downto 0);
    sram_data_i       : in  std_ulogic_vector(7 downto 0);
    sram_ena_o        : out std_ulogic_vector(1 downto 0);
    sram_we_o         : out std_ulogic;
    rom_ena_o         : out std_ulogic
  );
end;

architecture rtl of gdp_vram is


  type state_t is(idle_e,kernel_read_e,vid_read_e,rom_read_e);
  signal wr_data                            : std_ulogic_vector(7 downto 0);
  signal rd_data, next_rd_data              : std_ulogic_vector(7 downto 0);
  signal set_rd_data                        : std_ulogic;
  signal kernel_data, next_kernel_data      : std_ulogic_vector(7 downto 0);
  signal set_kernel_data                    : std_ulogic;
  signal state,next_state                   : state_t;
  signal ram_address, next_ram_address      : std_ulogic_vector(16 downto 0);
  signal set_ram_address                    : std_ulogic;
  signal kernel_req_pend                    : std_ulogic;
  signal next_kernel_ack                    : std_ulogic;
  signal rd_pend                            : std_ulogic;
  signal next_rd_ack                        : std_ulogic;
  signal ram_wren, next_ram_wren            : std_ulogic;
  signal ram_en, next_ram_en                : std_ulogic_vector(1 downto 0);
  signal srom_en, rom_en, next_rom_en       : std_ulogic;
  signal next_rom_ack                       : std_ulogic;
  signal srom_req_pend,rom_req_pend         : std_ulogic;
  signal srom_data,rom_data, next_rom_data  : std_ulogic_vector(7 downto 0);
  signal set_rom_data                       : std_ulogic;
begin



  -- DP-RAM Controller FSM for ext. SRAM
  process(state,ram_address, kernel_addr_i,kernel_wr_i,rd_addr_i,wr_data,rd_data,ram_wren,
          kernel_req_i,kernel_req_pend,rd_req_i,rd_pend,kernel_data,kernel_clk_en_i,
          sram_data_i, chr_rom_ena_i, rom_req_pend, chr_rom_addr_i, rom_data)
    procedure do_kernel_acc_p is
    begin
      set_ram_address  <= '1';
      next_ram_address <= kernel_addr_i(next_ram_address'range);
      next_ram_wren    <= kernel_wr_i;
      if kernel_addr_i(17)='1' then
        next_ram_en <= "10";
      else
        next_ram_en <= "01";
      end if;
      if kernel_wr_i='0' then
        next_state     <= kernel_read_e;
      else
        next_kernel_ack  <= '1';
      end if;
    end procedure;
    procedure do_vid_rd_p is
    begin
      set_ram_address  <= '1';
      next_ram_address <= rd_addr_i(next_ram_address'range);
      if rd_addr_i(17)='1' then
        next_ram_en <= "10";
      else
        next_ram_en <= "01";
      end if;
      next_ram_wren    <= '0';
      next_state       <= vid_read_e;
    end procedure;
    procedure do_rom_acc_p is
    begin
      set_ram_address  <= '1';
      next_ram_address <= (others => '0');
      next_ram_address(chr_rom_addr_i'range) <= chr_rom_addr_i;
      next_rom_en      <= '1';
      next_state       <= rom_read_e;
    end procedure;   
  begin
    next_state      <= state;
    next_kernel_ack <= '0';
    next_rd_ack     <= '0';
    next_ram_address <= (others => '-');
    set_ram_address  <= '0';
--    next_wr_data    <= wr_data;
    next_rd_data     <= (others => '-');
    set_rd_data      <= '0';
    next_kernel_data <= (others => '-');
    set_kernel_data  <= '0';
    next_ram_wren    <= '0';
    next_ram_en      <= (others => '0');
    next_rom_en      <= '0';
    next_rom_data    <= (others => '-');
    set_rom_data     <= '0';
    next_rom_ack     <= '0';

    case state is
      when idle_e =>
        -- a video read has always a higher priority than a kernel access
        if (rd_req_i or rd_pend)='1' then
          do_vid_rd_p;
        elsif ((kernel_clk_en_i and kernel_req_i) or kernel_req_pend)='1' then
          do_kernel_acc_p;
        elsif not INT_CHR_ROM_g and
              ((kernel_clk_en_i and chr_rom_ena_i) or rom_req_pend)='1' then
          do_rom_acc_p;
        end if;

      when vid_read_e =>
        next_state   <= idle_e;
        next_rd_ack  <= '1';
        set_rd_data  <= '1';
        next_rd_data <= sram_data_i;
        if (rd_req_i)='1' then
          do_vid_rd_p;
        elsif ((kernel_clk_en_i and kernel_req_i) or kernel_req_pend)='1' then
          do_kernel_acc_p;
        end if;
        

      when kernel_read_e =>
        next_state   <= idle_e;
        next_kernel_ack  <= '1';
        set_kernel_data  <= '1';
        next_kernel_data <= sram_data_i;
        if (rd_req_i or rd_pend)='1' then
          do_vid_rd_p;
        elsif (kernel_clk_en_i and kernel_req_i)='1' then
          do_kernel_acc_p;
        end if;
      when rom_read_e =>
        -- FIXME: configurable waitstates for slower ROMs
        if not INT_CHR_ROM_g then
          next_state    <= idle_e;
          next_rom_ack  <= '1';
          set_rom_data  <= '1';
          next_rom_data <= sram_data_i;
          if (rd_req_i or rd_pend)='1' then
            do_vid_rd_p;
          end if;
        else
          next_state <= idle_e;
        end if;
      
      
      when others =>
        next_state <= idle_e;
    end case;
  end process;

  process(clk_i,reset_n_i)
  begin
    if reset_n_i = ResetActive_c then
      state <= idle_e;
      ram_address <= (others => '0');
      wr_data     <= (others => '0');
      rd_data     <= (others => '0');
      kernel_data <= (others => '0');
      ram_wren    <= '0';
      ram_en      <= (others => '0');
      kernel_req_pend <= '0';
      rd_pend     <= '0';
      kernel_ack_o<= '0';
      rd_ack_o    <= '0';
      if not INT_CHR_ROM_g then
        srom_en      <= '0';
        srom_req_pend<= '0';
        srom_data    <= (others => '0');
      end if;
    elsif rising_edge(clk_i) then
      if clk_en_i = '1' then
        state       <= next_state;
        if set_ram_address  = '1' then
          ram_address <= next_ram_address;
        end if;
        if set_rd_data = '1' then
          rd_data     <= next_rd_data;
        end if;
        if set_kernel_data = '1' then
          kernel_data <= next_kernel_data;
        end if;
        ram_wren    <= next_ram_wren;
        ram_en      <= next_ram_en;
        kernel_ack_o<= next_kernel_ack;
        rd_ack_o    <= next_rd_ack;
        if not INT_CHR_ROM_g then
          srom_en    <= next_rom_en;
          if set_rom_data = '1' then
            srom_data  <= next_rom_data;
          end if;
        end if;
        if (kernel_clk_en_i and kernel_req_i)='1' then
          kernel_req_pend  <= '1';
  --        case(wr_addr_i(0)) is
  --          when '0' =>
  --            wr_data(7 downto 0)  <= wr_data_i;
  --          when '1' =>
  --            wr_data(15 downto 8) <= wr_data_i;
  --          when others => null;
  --        end case;
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
        if not INT_CHR_ROM_g then
          if (kernel_clk_en_i and chr_rom_ena_i)='1' then
            srom_req_pend <= '1';
          end if;
          if next_rom_ack ='1' then
            srom_req_pend <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;

  rom_en <= srom_en when not INT_CHR_ROM_g else
            '0';
  rom_req_pend <= srom_req_pend when not INT_CHR_ROM_g else
            '0';
  rom_data <= srom_data when not INT_CHR_ROM_g else
            (others =>'0');


  kernel_busy_o   <= kernel_req_pend;
  rd_busy_o       <= rd_pend;
  rd_data_o       <= rd_data;
  kernel_data_o   <= kernel_data;
  chr_rom_data_o  <= rom_data;
  chr_rom_busy_o  <= rom_req_pend;
  --
  sram_addr_o <= ram_address;
  sram_data_o <= wr_data;
  sram_ena_o  <= ram_en;
  sram_we_o   <= ram_wren;
  rom_ena_o   <= rom_en;

end architecture rtl;

