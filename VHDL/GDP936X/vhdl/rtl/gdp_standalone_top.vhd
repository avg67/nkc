--------------------------------------------------------------------------------
-- Project     : Single Chip NDR Computer
-- Module      : GDP 936X Display processor - Toplevel for Lattice FPGA
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
use IEEE.numeric_std.all;
use work.DffGlobal.all;
use work.gdp_global.all;

entity gdp_standalone_top is
  generic(sim_g      : boolean := false);
  port(reset_n_i     : in  std_ulogic;
       clk_i         : in  std_ulogic;

       driver_nEN_o  : out std_ulogic;
       driver_DIR_o  : out std_ulogic;
       endflag_o     : out std_ulogic;
       --------------------------
       -- Video out
       --------------------------
       Red_o      : out std_logic_vector(2 downto 0);
       Green_o    : out std_logic_vector(2 downto 0);
       Blue_o     : out std_logic_vector(2 downto 0);
       Hsync_o    : out std_ulogic;
       Vsync_o    : out std_ulogic;
       --------------------------
       -- Video-Memory data bus
       --------------------------
       SRAM1_nCS    : out std_ulogic;
       SRAM1_ADR    : out std_ulogic_vector(17 downto 0);
       SRAM1_DB     : inout std_logic_vector(7 downto 0);
       SRAM1_nWR    : out std_ulogic;
       SRAM1_nOE    : out std_ulogic
       );
end gdp_standalone_top;


architecture rtl of gdp_standalone_top is

  component gdp_top is
    generic(INT_CHR_ROM_g : boolean := true); 
    port(reset_n_i     : in  std_ulogic;
         clk_i         : in  std_ulogic;
         clk_en_i      : in  std_ulogic;
         --------------------------
         -- internal data bus (Register)
         --------------------------
         Adr_i     : in  std_ulogic_vector(3 downto 0);
         gdp_en_i  : in  std_ulogic;
         sfr_en_i  : in  std_ulogic;
         DataIn_i  : in  std_ulogic_vector(7 downto 0);
         Rd_i      : in  std_ulogic;
         Wr_i      : in  std_ulogic;
         DataOut_o : out std_ulogic_vector(7 downto 0);
         --------------------------
         -- Video out
         --------------------------
         pixel_o    : out std_ulogic;
         Hsync_o    : out std_ulogic;
         Vsync_o    : out std_ulogic;
         --------------------------
         -- Video-Memory data bus
         --------------------------
         sram_addr_o : out std_ulogic_vector(15 downto 0);
         sram_data_o : out std_ulogic_vector(7 downto 0);
         sram_data_i : in  std_ulogic_vector(7 downto 0);
         sram_ena_o  : out std_ulogic;
         sram_we_o   : out std_ulogic;
         rom_ena_o   : out std_ulogic
         );
  end component;

  component InputSync
    generic(levels_g     : natural :=2;
            ResetValue_g : std_ulogic := '0');
    port (
      Input : in  std_ulogic;
      clk   : in  std_ulogic;
      clr_n : in  std_ulogic;
      q     : out std_ulogic);
  end component;
  
  type state_t is (IDLE_e,DELAY_e,NOP_e,READ_CMD_e, PROCESS_e, WAIT_e, END_e);
  

  signal state,next_state  : state_t;
  signal reset_n           : std_ulogic;
  signal GDP_SRAM_ADDR     : std_ulogic_vector(15 downto 0);
  signal GDP_SRAM_datao    : std_ulogic_vector(7 downto 0);
  signal GDP_DataOut       : std_ulogic_vector(7 downto 0);
  signal GDP_SRAM_datai    : std_ulogic_vector(7 downto 0);
  signal GDP_SRAM_ena      : std_ulogic;
  signal GDP_SRAM_we       : std_ulogic;
  signal VGA_pixel         : std_ulogic;
  signal gdp_Rd,gdp_Wr     : std_ulogic;
  signal gdp_cs            : std_ulogic;
  signal gdp_en,sfr_en     : std_ulogic;

  signal Addr              : std_ulogic_vector(7 downto 0);
  signal data_in           : std_ulogic_vector(7 downto 0);
  signal output_en         : std_ulogic;
  signal endflag           : std_ulogic;
  signal A, next_A : unsigned(4 downto 0);
  signal CMD       : std_ulogic_vector(15 downto 0);
  signal cnt,next_cnt : unsigned(15 downto 0); 
  
begin

  reset_sync: process(clk_i)
    variable tmp_v : std_ulogic_vector(1 downto 0);
  begin
    if rising_edge(clk_i) then
      reset_n  <= tmp_v(1);
      tmp_v(1) := tmp_v(0);
      tmp_v(0) := reset_n_i;
    end if;
  end process reset_sync;

  
--  ISIORQ : InputSync
--  port map (
--      Input => nkc_nIORQ_i,
--      clk   => Clk_i,
--      clr_n => Reset_n,
--      q     => nIORQ);
--      
--  ISRD : InputSync
--  port map (
--      Input => nkc_nRD_i,
--      clk   => Clk_i,
--      clr_n => Reset_n,
--      q     => nRD);
--      
--  ISWR : InputSync
--  port map (
--      Input => nkc_nWR_i,
--      clk   => Clk_i,
--      clr_n => Reset_n,
--      q     => nWR);
--  
--  process(clk_i,reset_n)
--  begin
--    if reset_n = '0' then
--      nIORQ_d      <= '1';
--      nRD_d        <= '1';
--      nWR_d        <= '1';
--      gdp_Rd       <= '0';
--      gdp_Wr       <= '0';
--      Addr         <= (others => '0');
--      data_in      <= (others => '0');
--      output_en    <= '0';
--    elsif rising_edge(clk_i) then
--      nIORQ_d      <= nIORQ; -- for edge detection
--      nWR_d        <= '1';
--      nRD_d        <= '1';
--      output_en    <= gdp_cs;
--      
--      gdp_Rd  <= '0';
--      gdp_Wr  <= '0';
--      if nIORQ = '0' then
--        if nIORQ_d = '1' then
--          -- IORQ  had an falling edge.
--          -- Store Address
--          Addr <= nkc_ADDR_i;
--        elsif output_en = '1' or nRD = '0' then
--          nWR_d  <= nWR;
--          nRD_d  <= nRD;
--          gdp_Rd <= not nRD and nRD_d;
--          gdp_Wr <= not nWR and nWR_d;
--          if (not nWR and nWR_d)='1' then
--            data_in <= std_ulogic_vector(nkc_DB);
--          end if;
--        end if;
--      end if;
--    end if;
--  end process;

  driver_nEN_o <= '1'; 
  driver_DIR_o <= '1';
  
      
  GDP: gdp_top
    port map (
      reset_n_i   => reset_n,
      clk_i       => clk_i,
      clk_en_i    => '1',
      Adr_i       => Addr(3 downto 0),
--      CS_i        => gdp_cs,
      gdp_en_i    => gdp_en,
      sfr_en_i    => sfr_en,

      DataIn_i    => data_in,
      Rd_i        => gdp_Rd,
      Wr_i        => gdp_Wr,
      DataOut_o   => GDP_DataOut,
      pixel_o     => VGA_pixel,
      Hsync_o     => Hsync_o,
      Vsync_o     => Vsync_o,
      sram_addr_o => GDP_SRAM_ADDR,
      sram_data_o => GDP_SRAM_datao,
      sram_data_i => GDP_SRAM_datai,
      sram_ena_o  => GDP_SRAM_ena,
      sram_we_o   => GDP_SRAM_we);
  
--  gdp_cs <= (not nIORQ and not nIORQ_d) when  Addr(7 downto 4) = "0111" or  -- GDP
--                                             (Addr(7 downto 4) = "0110" and nWR='0')  else -- SFRs
--            '0';
--  gdp_cs <= (not nIORQ and not nIORQ_d) when  Addr(7 downto 4) = GDP_BASE_ADDR_c(7 downto 4) or  -- GDP
--                                             (Addr(7 downto 4) = SFR_BASE_ADDR_c(7 downto 4) and nWR='0')  else -- SFRs
--            '0';
  

  
--  gdp_cs <= '1' when (CPUEN and not IORq_n)='1' and Cpu_A(7 downto 5) = "011" else
--            '0';
  SRAM1_ADR <= "00" & GDP_SRAM_ADDR after 1 ns;
  SRAM1_DB  <= std_logic_vector(GDP_SRAM_datao) after 1 ns when (GDP_SRAM_ena and GDP_SRAM_we)='1' else
               (others => 'Z') after 1 ns;
  GDP_SRAM_datai <= std_ulogic_vector(SRAM1_DB);
  SRAM1_nCS      <= not GDP_SRAM_ena; -- and not clk);

--  sim_ram : if sim_g generate
--    SRAM1_nOE      <= not (GDP_SRAM_ena and not GDP_SRAM_we and not clk);
--    SRAM1_nWR      <= not (GDP_SRAM_we and not clk);
    SRAM1_nWR      <= not (GDP_SRAM_we and not clk_i);
--  end generate;
--  rtl_ram : if not sim_g generate
    SRAM1_nOE      <= not (GDP_SRAM_ena and not GDP_SRAM_we);
--    SRAM1_nWR      <= not (GDP_SRAM_we);
--  end generate;
  
  Red_o   <= (others => VGA_pixel);
  Green_o <= (others => VGA_pixel);
  Blue_o  <= (others => VGA_pixel);

  gdp_en <= gdp_cs when Addr(7 downto 4) = X"7" else
            '0';
  sfr_en <= gdp_cs when Addr(7 downto 4) = X"6" else
            '0';


	process (A)
	begin
		case to_integer(A) is
		when 000000 => CMD <= X"6000";	-- Set write-page
		when 000001 => CMD <= X"7007";	-- clear screen
		when 000002 => CMD <= X"6040";	-- Set write-page
		when 000003 => CMD <= X"7007";	-- clear screen
		when 000004 => CMD <= X"6080";	-- Set write-page
		when 000005 => CMD <= X"7007";	-- clear screen
		when 000006 => CMD <= X"60C0";	-- Set write-page
		when 000007 => CMD <= X"7007";	-- clear screen
		when 000008 => CMD <= X"6000";	-- Set write-page
		when 000009 => CMD <= X"7000";	-- set write pen
		when 000010 => CMD <= X"7002";	-- pen down
		when 000011 => CMD <= X"7048";	-- 'H'
		when 000012 => CMD <= X"7061";	-- 'a'
		when 000013 => CMD <= X"706c";	-- 'l'
		when 000014 => CMD <= X"706c";	-- 'l'
		when 000015 => CMD <= X"706f";	-- 'o'
		when 000016 => CMD <= X"7510";	-- dx=0x10
		when 000017 => CMD <= X"7710";	-- dy=0x10
		when 000018 => CMD <= X"7011";	-- Line
	
			
        
		when others => CMD <= X"0000" ;  -- End
		end case;
	end process;


  process(state,A,CMD,GDP_DataOut, cnt) 
  begin
    next_state <= state;
    next_A     <= A;
    Addr       <= CMD(15 downto 8);
    data_in    <= CMD(7 downto 0);
    gdp_cs     <= '0';
    gdp_Rd     <= '0';
    gdp_Wr     <= '0';
    endflag    <= '0';
    next_cnt   <= cnt;
    case state is
      when IDLE_e =>
        next_state <= DELAY_e;
        next_cnt   <= (others => '1');
      when DELAY_e =>
        next_cnt   <= cnt -1;
        if cnt=X"0000" then
          next_state <= READ_CMD_e;
        end if;
      when READ_CMD_e =>
        
        gdp_cs  <= '1';
        Addr    <= CMD(15 downto 8);
        data_in <= CMD(7 downto 0);
        gdp_Wr  <= '1';
        next_state <= NOP_e;
        if CMD = X"0000" then
          next_state <= END_e;
        end if;
     when NOP_e =>      
        if CMD(15 downto 8) = X"70" then
          next_state <= PROCESS_e;
        else
          next_A <= A + 1;
          next_state <= READ_CMD_e;
        end if;
      when PROCESS_e =>
        gdp_cs  <= '1';
        Addr    <= X"70";
        gdp_Rd  <= '1';
        next_state <= WAIT_e;
      when WAIT_e =>
        Addr    <= X"70";
        next_state <= PROCESS_e;
        if GDP_DataOut(2)='1' then
          next_state <= READ_CMD_e;
          next_A <= A + 1;
        end if;
        
      when END_e =>
        endflag <= '1';
      when others =>
        next_state <= IDLE_e;
    end case;
  end process;

  process(clk_i,reset_n)
  begin
    if reset_n = '0' then
      A         <= (others => '0');
      state     <= IDLE_e;
      cnt       <= (others => '0');
    elsif rising_edge(clk_i) then
      A     <= next_A;
      state <= next_state;
      cnt   <= next_cnt;
    end if;
  end process;
  
  endflag_o <= endflag;
end rtl;
