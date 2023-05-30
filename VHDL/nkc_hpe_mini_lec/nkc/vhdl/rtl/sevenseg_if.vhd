-- -----------------------------------------------
-- Title:    320 x 240 BW LCD Controller
-- file:     lcd_if.vhd
-- language: VHDL 93
-- author:       HSSE / Andreas Voggeneder
-- comments: 
-- history: 
--   1.2005 creation
-- -----------------------------------------------


library IEEE;
library Work;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity sevenseg_if is
  port(clk_i          : in std_logic;
      reset_n_i      : in std_logic;
      -- Interface to SFR's
      
      Adr_i     : in  std_ulogic_vector(1 downto 0);
      en_i      : in  std_ulogic;
      DataIn_i  : in  std_ulogic_vector(7 downto 0);
      Rd_i      : in  std_ulogic;
      Wr_i      : in  std_ulogic;
      DataOut_o : out std_ulogic_vector(7 downto 0);
                    
      -- Interface to SevenSeg Display
      SevenSeg_D_o     : out std_logic_vector(7 downto 0);
      SevenSeg_D_i     : in  std_logic_vector(7 downto 0);
      SevenSegEn_n_o   : out std_logic_vector(1 downto 0)
   );
end entity sevenseg_if;

architecture RTL of sevenseg_if is

  signal Counter     : unsigned(17 downto 0);   -- 18 bit counter for ~100Hz Mux frequency (25 MHz)

  -- SFR's
  signal sevseg_con_s    : std_logic_vector(5 downto 0);
  signal sevseg_data_reg : std_logic_vector(15 downto 0);
  signal SevenSegVal     : std_logic_vector(3 downto 0);
  signal SevenSegMux     : std_logic;
  signal SevSegLine      : std_logic_vector(7 downto 0);
  signal SevenSegEn      : std_logic;
  signal SevenSegDP      : std_logic;
  signal Mode_s          : std_logic_vector(1 downto 0);
  
begin

  --DataOut_o  <= "0"&SevenSegMux&sevseg_con_s when sevseg_con_sel='1' else
  --               sevseg_data_reg(7 downto 0) when sevseg_dataL_sel = '1' and Mode_s /= "00" else
  --               SevenSeg_D_i when sevseg_dataL_sel = '1' and Mode_s = "00" else
  --               sevseg_data_reg(15 downto 8) when sevseg_dataH_sel = '1' else
  --               (others =>'-');
                 
   with to_integer(unsigned(Adr_i(1 downto 0))) select
      DataOut_o <=  "0"&SevenSegMux&sevseg_con_s when 0,
                    SevenSeg_D_i                 when 1,
                    sevseg_data_reg(15 downto 8) when 2,
                    (others =>'-');              when others;
                 
  -- sevseg_con Register bit assignement
  -- bit 0:   Low Enable
  -- bit 1:   High Enable
  -- bit 2,3: Mode (00 = IO, 01 = HEX, 02 = RAW)
  -- bit 4:   DP low (HEX Mode)
  -- bit 5:   DP high (HEX Mode)

  Mode_s <= sevseg_con_s(3 downto 2);
  
   process (reset_n_i, clk_i)
   begin
      if reset_n_i = '0' then
         sevseg_con_s    <= (others =>'0');
         sevseg_data_reg <= (others =>'0');
      elsif clk_i'event and clk_i = '1' then
         if (en_i and Wr_i)='1' then
            case Adr_i(1 downto 0) is
               when "00" => 
                  sevseg_con_s <= DataIn_i(sevseg_con_s'range);
               when "01" => 
                  sevseg_data_reg(7 downto 0) <= DataIn_i;
               when "10" => 
                  sevseg_data_reg(15 downto 8) <= DataIn_i;
               when others => null;
            end case;
         end if;
      end if;
   end process;
 
   -- 7 Segmentdecoder
  SevSeg : process (SevenSegVal,SevenSegEn,Mode_s,SevenSegDP) is
    variable tmp_v : std_logic_vector(7 downto 0);
  begin
    tmp_v := (others =>'0');
    if SevenSegEn='1' then
      if Mode_s = "01" then
        -- HEX Mode
        case SevenSegVal(3 downto 0) is
          when "0000" => tmp_v := X"3F";
          when "0001" => tmp_v := X"06";
          when "0010" => tmp_v := X"5B";
          when "0011" => tmp_v := X"4F";
          when "0100" => tmp_v := X"66";
          when "0101" => tmp_v := X"6D";
          when "0110" => tmp_v := X"7D";
          when "0111" => tmp_v := X"07";
          when "1000" => tmp_v := X"7F";
          when "1001" => tmp_v := X"6F";
          when "1010" => tmp_v := X"77";
          when "1011" => tmp_v := X"7C";
          when "1100" => tmp_v := X"39";
          when "1101" => tmp_v := X"5E";
          when "1110" => tmp_v := X"79";
          when "1111" => tmp_v := X"71";
          when others => null;
        end case;
      end if;
    end if;
    SevSegLine <= (SevenSegDP & tmp_v(6 downto 0));
  end process SevSeg;
  
  mux : process(clk_i, reset_n_i)
  begin
    if reset_n_i = '0' then
      Counter    <=(others=>'0');
    elsif clk_i'event and clk_i = '1' then
      if sevseg_con_s(1 downto 0) /= "00" then 
        Counter <= Counter + 1;
      end if;
    end if;
  end process mux;
  
  SevenSegEn  <= sevseg_con_s(0) when SevenSegMux='1' else sevseg_con_s(1);
  SevenSegDP  <= sevseg_con_s(4) when SevenSegMux='1' else sevseg_con_s(5);
  SevenSegMux <= Counter(Counter'high);
  SevenSegVal <= sevseg_data_reg(3 downto 0) when SevenSegMux='1' else sevseg_data_reg(7 downto 4);
  
  
  
  SevenSeg_D_o <= not(SevSegLine) when Mode_s = "01" else
                  not(sevseg_data_reg(15 downto 8)) when Mode_s="10" and SevenSegMux='0' else
                  not(sevseg_data_reg(7 downto 0)) when Mode_s="10" and SevenSegMux='1' else
                  sevseg_data_reg(7 downto 0);
                  
  SevenSegEn_n_o(0) <= not (SevenSegMux and sevseg_con_s(0));
  SevenSegEn_n_o(1) <= SevenSegMux or not sevseg_con_s(1);
end RTL;
