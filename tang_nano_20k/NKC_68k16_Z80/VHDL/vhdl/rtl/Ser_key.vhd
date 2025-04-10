--------------------------------------------------------------------------------
-- Project     : Single Chip NDR Computer
-- Module      : SER_Key
-- File        : Ser1.vhd
-- Description : Serial Interface for NKC.
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

entity ser_key is
  port(
    reset_n_i    : in  std_logic;
    clk_i        : in  std_logic;
    --------------------------
    -- UART signals
    --------------------------
    RxD_i    : in  std_ulogic;
    ----------------------------------
    -- Data Bus
    ----------------------------------
    KeyCS_i   : in  std_ulogic;
    DipCS_i   : in  std_ulogic;
    Rd_i      : in  std_ulogic;
    DataOut_o : out std_ulogic_vector(7 downto 0)
  );
end ser_key;

architecture rtl of ser_key is
  
  constant BAUD_c : natural := CLK_FREQ_c / (9600*16);

  constant baud_cnt_bits_c : natural := 14;
--  type tx_state_t is (IDLE_e, SHIFTING_e, STOP_BIT_e);
--  signal Status               : std_ulogic_vector(7 downto 0);
--  -- Registers 
  signal Data_in_reg          : std_ulogic_vector(7 downto 0);
  signal KbdDataReg_valid     : std_ulogic;
--  signal Data_out_reg         : std_ulogic_vector(8 downto 0);
--  signal Status_reg           : std_ulogic_vector(7 downto 0);
--  signal Control_reg          : std_ulogic_vector(7 downto 0);
--  signal Command_reg          : std_ulogic_vector(7 downto 0);
--
  signal baud_cnt             : unsigned(baud_cnt_bits_c -1 downto 0);
  signal baud_stb             : std_ulogic;
--
--
  signal rxd_sync             : std_ulogic;
--  signal CTS_sync             : std_ulogic;
--
--  signal soft_reset           : std_ulogic;
--  signal max_bit_cnt          : natural range 5 to 8; -- Wordlength
--  -- Transmitter signals
--  signal tx_state             : tx_state_t;
--  signal next_tx_state        : tx_state_t;
--  signal tx_ack               : std_ulogic;
--  signal TxD,next_TxD         : std_ulogic;
--  signal tx_sr                : std_ulogic_vector(8 downto 0);
--  signal set_tx_sr            : std_ulogic;
--  signal next_tx_sr           : std_ulogic_vector(8 downto 0);
--  signal set_tx_baud_divider  : std_ulogic;
--  signal tx_baud_divider      : unsigned(3 downto 0);
--  signal next_tx_baud_divider : unsigned(3 downto 0);
--  signal set_tx_bit_cnt       : std_ulogic;
--  signal tx_bit_cnt           : unsigned(3 downto 0);
--  signal next_tx_bit_cnt      : unsigned(3 downto 0);
  -- Receiverr signals
  type rx_state_t is (IDLE_e, SHIFTING_e, STOP_BIT_e);
  signal rx_state             : rx_state_t;
  signal next_rx_state        : rx_state_t;
  signal rx_stb               : std_ulogic;
  signal set_framing_error    : std_ulogic;
  signal rx_sr                : std_ulogic_vector(8 downto 0); --1start+8d
  signal set_rx_sr            : std_ulogic;
  signal next_rx_sr           : std_ulogic_vector(8 downto 0);
  signal set_rx_baud_divider  : std_ulogic;
  signal rx_baud_divider      : unsigned(3 downto 0);
  signal next_rx_baud_divider : unsigned(3 downto 0);
  signal set_rx_bit_cnt       : std_ulogic;
  signal rx_bit_cnt           : unsigned(3 downto 0);
  signal next_rx_bit_cnt      : unsigned(3 downto 0);


begin
  ISRxD : entity work.InputSync
   generic map (
     levels_g => 2,
     ResetValue_g => '1')
   port map (
     Input => RxD_i,
     clk   => Clk_i,
     clr_n => reset_n_i,
     q     => rxd_sync);
     
    
    DataOut_o <=  not KbdDataReg_valid & Data_in_reg(6 downto 0);

    baudrate_gen : process(Clk_i, reset_n_i)
    begin
      if reset_n_i= ResetActive_c then
        baud_cnt <= (others => '0');
        baud_stb <= '0';
      elsif rising_edge(clk_i) then
        baud_stb <= '0';
        if baud_cnt /=0 then
          baud_cnt <= baud_cnt - 1;
        else
          baud_cnt <= to_unsigned(BAUD_c,baud_cnt_bits_c);
          baud_stb <= '1';
        end if;
      end if;
    end process;


  rx_fsm: process(rx_state,rxd_sync, baud_stb, rx_baud_divider, rx_bit_cnt, rx_sr)
  begin
    next_rx_state        <= rx_state;
    rx_stb               <= '0';
    set_rx_baud_divider  <= '0';
    next_rx_baud_divider <= (others => '-');
    set_rx_bit_cnt       <= '0';
    next_rx_bit_cnt      <= (others => '-');
    set_rx_sr            <= '0';
    next_rx_sr           <= (others => '-');
    set_framing_error    <= '0';

    case rx_state is
      when IDLE_e =>
        if (baud_stb and not rxd_sync)='1' then
          next_rx_state        <= SHIFTING_e;
          -- set sampling point to middle of bit
          set_rx_baud_divider  <= '1';
          next_rx_baud_divider <= "1000";  -- bittime / 2
          set_rx_bit_cnt       <= '1';
          next_rx_bit_cnt      <= (others => '0');
        end if;

      when SHIFTING_e =>
        if baud_stb = '1' then
          set_rx_baud_divider  <= '1';
          next_rx_baud_divider <= rx_baud_divider + 1;
          if rx_baud_divider = "1111" then
            set_rx_bit_cnt   <= '1';
            next_rx_bit_cnt  <= rx_bit_cnt +1;
            set_rx_sr        <= '1';
            next_rx_sr       <= rxd_sync & rx_sr(8 downto 1);

            if rx_bit_cnt = 8 then
              next_rx_state <= STOP_BIT_e;
            end if;
          end if;
        end if;

      when STOP_BIT_e =>
        if baud_stb = '1' then
          set_rx_baud_divider  <= '1';
          next_rx_baud_divider <= rx_baud_divider + 1;          
          if rx_baud_divider = "1111" then
            next_rx_state <= IDLE_e;
            rx_stb <= '1';
            -- check frame
            if rx_sr(0)='1' or rxd_sync='0' then
              set_framing_error <= '1';
            end if;
          end if;
        end if;

      when others => 
        next_rx_state <= IDLE_e;
    end case;
  end process;

  uart_rx : process(Clk_i, reset_n_i)
    begin
      if reset_n_i= ResetActive_c then
        rx_state         <= IDLE_e;
        rx_bit_cnt       <= (others => '0');
        rx_baud_divider  <= (others => '0');
                         
        rx_bit_cnt       <= (others => '0');
        rx_sr            <= (others => '0');
        Data_in_reg      <= (others => '0');
        KbdDataReg_valid <= '0';
      elsif rising_edge(clk_i) then
        rx_state   <= next_rx_state;

        if set_rx_baud_divider='1' then
          rx_baud_divider <= next_rx_baud_divider;
        end if;
        if set_rx_bit_cnt='1' then
          rx_bit_cnt <= next_rx_bit_cnt;
        end if;
        if set_rx_sr = '1' then
          rx_sr <= next_rx_sr;
        end if;
        -- frame complete and well-formed
        if rx_stb = '1' and set_framing_error='0' then
          Data_in_reg      <= rx_sr(8 downto 1);
          KbdDataReg_valid <= '1';
        end if;
        if (DipCS_i and Rd_i) = '1' then
          KbdDataReg_valid <= '0';
        end if;
      end if;
    end process;

end rtl;
