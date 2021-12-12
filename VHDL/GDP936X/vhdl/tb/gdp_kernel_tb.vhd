-------------------------------------------------------------------------------
-- Title      : Testbench for design "gdp_kernel"
-- Project    :
-------------------------------------------------------------------------------
-- File       : gdp_kernel_tb.vhd
-- Author     :   <Andreas Voggeneder@LAPI>
-- Company    :
-- Created    : 2007-04-08
-- Last update: 2007-04-08
-- Platform   :
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Copyright (c) 2007
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2007-04-08  1.0      Andreas Voggeneder	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

-------------------------------------------------------------------------------

entity gdp_kernel_tb is

end gdp_kernel_tb;

-------------------------------------------------------------------------------

architecture beh of gdp_kernel_tb is
  constant GDP_BASE_ADDR_c  : std_ulogic_vector(7 downto 0) := X"70"; -- r/w
  constant SFR_BASE_ADDR_c  : std_ulogic_vector(7 downto 0) := X"60"; -- w  
--  component gdp_kernel
--    port (
--      reset_n_i : in  std_ulogic;
--      clk_i     : in  std_ulogic;
--      clk_en_i  : in  std_ulogic;
--      Adr_i     : in  std_ulogic_vector(3 downto 0);
--      CS_i      : in  std_ulogic;
--      DataIn_i  : in  std_ulogic_vector(7 downto 0);
--      Rd_i      : in  std_ulogic;
--      Wr_i      : in  std_ulogic;
--      DataOut_o : out std_ulogic_vector(7 downto 0);
--      addr_o    : out std_ulogic_vector(15 downto 0);
--      data_o    : out std_ulogic_vector(7 downto 0);
--      data_i    : in  std_ulogic_vector(7 downto 0);
--      ena_o     : out std_ulogic;
--      we_o      : out std_ulogic);
--  end component;
  -- clock
  signal Clk : std_logic := '1';
  -- component ports
  signal reset_n_i : std_ulogic;
  signal Adr_i     : std_ulogic_vector(7 downto 0);
  signal CS_i      : std_ulogic;
  signal DataIn_i  : std_ulogic_vector(7 downto 0);
  signal Rd_i      : std_ulogic;
  signal Wr_i      : std_ulogic;
  signal DataOut_o : std_ulogic_vector(7 downto 0);
  signal gdp_en,sfr_en : std_ulogic;

  signal SRAM_addr_o    : std_ulogic_vector(15 downto 0);
  signal SRAM_data_o    : std_ulogic_vector(7 downto 0);
  signal SRAM_data_i    : std_ulogic_vector(7 downto 0);
  signal SRAM_ena_o     : std_ulogic;
  signal SRAM_we_o      : std_ulogic;
  signal SRAM_Addr      : std_logic_vector(15 downto 0);
  signal  SRAM_DB       : std_logic_vector(7 downto 0);
  signal SRAM_nCE       : std_logic;
  signal SRAM_nWR       : std_logic;
  signal SRAM_nOE       : std_logic;
  signal do_dump        : boolean;


begin  -- beh

  -- component instantiation
  DUT: entity work.gdp_top
    port map (
      reset_n_i   => reset_n_i,
      clk_i       => clk,
      clk_en_i    => '1',
      Adr_i       => Adr_i(3 downto 0),
--      CS_i        => CS_i,
      gdp_en_i    => gdp_en,
      sfr_en_i    => sfr_en,
      DataIn_i    => DataIn_i,
      Rd_i        => Rd_i,
      Wr_i        => Wr_i,
      DataOut_o   => DataOut_o,
      pixel_o     => open,
      Hsync_o     => open,
      Vsync_o     => open,
      sram_addr_o => SRAM_addr_o,
      sram_data_o => SRAM_data_o,
      sram_data_i => SRAM_data_i,
      sram_ena_o  => SRAM_ena_o,
      sram_we_o   => SRAM_we_o);

  -- clock generation
  Clk <= not Clk after 12.5 ns;

  SRAM_DB <= std_logic_vector(SRAM_data_o) after 1 ns when (SRAM_ena_o and SRAM_we_o)='1' else
             (others => 'Z') after 1 ns;

  SRAM_data_i <= std_ulogic_vector(SRAM_DB);
  SRAM_nCE    <= not (SRAM_ena_o and not Clk);
  SRAM_nWR    <= not (SRAM_we_o and not Clk);
  SRAM_nOE    <= (SRAM_we_o and not Clk);
  SRAM_Addr   <= std_logic_vector(SRAM_addr_o) after 1 ns;
  RSRAM : entity work.SRAM
     port map(
     dump => do_dump,
     nCE => SRAM_nCE,
     nWE => SRAM_nWR,
     nOE => SRAM_nOE,
     A   => SRAM_Addr(15 downto 0),
     D   => SRAM_DB(7 downto 0)
   );


  gdp_en <= CS_i when Adr_i (7 downto 4) = GDP_BASE_ADDR_c(7 downto 4) else
            '0';
  sfr_en <= CS_i when Adr_i (7 downto 4) = SFR_BASE_ADDR_c(7 downto 4) else
            '0';

  -- waveform generation
  WaveGen_Proc: process
    procedure write_bus(addr : in bit_vector(7 downto 0); data : in bit_vector(7 downto 0)) is
    begin
      CS_i <= '1' after 1 ns;
      Wr_i <= '1' after 1 ns;
      Adr_i <= to_stdulogicvector(addr) after 1 ns;
      DataIn_i <= to_stdulogicvector(data) after 1 ns;
      wait until Clk'event and Clk='1';
      CS_i       <= '0' after 1 ns;
      Wr_i       <= '0' after 1 ns;
      wait until Clk'event and Clk='1';
    end write_bus;
    
    procedure write_bus(addr : in bit_vector(7 downto 0); data : in natural) is
    begin
      CS_i <= '1' after 1 ns;
      Wr_i <= '1' after 1 ns;
      Adr_i <= to_stdulogicvector(addr) after 1 ns;
      DataIn_i <= std_ulogic_vector(to_unsigned(data,8)) after 1 ns;
      wait until Clk'event and Clk='1';
      CS_i       <= '0' after 1 ns;
      Wr_i       <= '0' after 1 ns;
      wait until Clk'event and Clk='1';
    end write_bus;

    procedure read_bus(addr : in bit_vector(7 downto 0); data : out std_ulogic_vector(7 downto 0)) is
    begin
      CS_i <= '1' after 1 ns;
      Rd_i <= '1' after 1 ns;
      Adr_i <= to_stdulogicvector(addr) after 1 ns;
      wait until Clk'event and Clk='1';
      CS_i       <= '0' after 1 ns;
      Rd_i       <= '0' after 1 ns;
      wait until Clk'event and Clk='1';
      data       := DataOut_o;
     end read_bus;

    procedure wait_ready is
      variable tmp_v : std_ulogic_vector(7 downto 0);
    begin
      read_bus(X"70",tmp_v);
      while tmp_v(2) = '0' loop
        read_bus(X"70",tmp_v);
      end loop;
    end wait_ready;

    procedure line(x1,y1,x2,y2 : integer) is
      variable dx,dy : integer;
      variable xp,yp,sx,sy : integer;
    begin
      write_bus(X"78",x1/256);        -- x msb
      write_bus(X"79",x1 mod 256);   -- x lsb
      write_bus(X"7A",y1/256);        -- y msb
      write_bus(X"7B",y1 mod 256);   -- y lsb
      xp:=x1;
      yp:=y1;
      sx := 0;sy :=0;
      if x1>x2 then sx:=1; end if;
      if y1>y2 then sy:=1; end if;
      loop
        dx := abs(x2-xp);
        dy := abs(y2-yp);


        
        if dx > 255 then
          dx := 255;
        end if;
        if dy > 255 then
          dy := 255;
        end if;
        write_bus(X"75",dx);        -- dx
        write_bus(X"77",dy);        -- dy
        write_bus(X"70",17+sx*2+sy*4);        -- dy
        wait_ready;
        if sx>0 then
          xp := xp - dx;
        else
          xp := xp + dx;
        end if;
        if sy>0 then
          yp := yp - dy;
        else
          yp := yp + dy;
        end if;
        
        exit when xp=x2 and yp=y2;
      end loop;
    end line;

  begin
    -- insert signal assignments here
    do_dump    <= false;
    Adr_i      <= (others => '0');
    DataIn_i   <= (others => '0');
    CS_i       <= '0';
    Rd_i       <= '0';
    Wr_i       <= '0';
    reset_n_i  <= '0', '1' after 20 ns;
    wait for 100 ns;
    wait until Clk'event and Clk='1';
    wait_ready;
    for i in 3 downto 0 loop
      write_bus(X"60",i*64);   -- Set Write-Page
      write_bus(X"70",X"07");  -- Clear Screen
      wait_ready;
    end loop;
    wait for 1500 us;
    write_bus(X"75",X"04");  -- dx = 5
    write_bus(X"71",X"03");  --  CTRL1 = 3
    write_bus(X"72",X"01");  --  CTRL2 = 1
--    write_bus(X"70",X"00");
--    write_bus(X"70",X"02");
--    write_bus(X"70",X"11");
    write_bus(X"70",X"10");  -- x+=5
    wait_ready;
    write_bus(X"70",X"E6");  -- x-=4
    wait_ready;
    write_bus(X"70",X"A6");  -- x-=2
    wait_ready;
    write_bus(X"70",X"80");  -- x+=1
    wait_ready;
--    write_bus(X"70",X"F9");  -- x+=4, Y+=4
    write_bus(X"75",X"ff");  -- dx = 255
--    write_bus(X"70",X"19");  -- x+=255
    wait_ready;

    write_bus(X"70",X"05");  -- x,y=0
    write_bus(X"73",X"11");  -- CSIZE = 0x22
    write_bus(X"70",X"21");  --
    wait_ready;
    write_bus(X"70",X"7f");  --
    wait_ready;
    write_bus(X"70",X"41");  --
    wait_ready;
    write_bus(X"70",X"0B");  -- 4x4
    wait_ready;
    write_bus(X"70",X"0A");  -- 5x8
    wait_ready;
    write_bus(X"72",X"00");  --
    write_bus(X"79",X"64");  -- x=100
    write_bus(X"7B",X"64");  -- y=100
    write_bus(X"70",X"E0");  -- x+=4 draw marker
    wait_ready;
    write_bus(X"79",X"64");  -- x=100
    write_bus(X"70",X"9C");  -- y-=4 draw marker
    wait_ready;
    write_bus(X"79",X"32");  -- x=50
    write_bus(X"7B",X"32");  -- y=50
    write_bus(X"72",X"04");  --
    write_bus(X"70",X"41");  --
    wait_ready;
    write_bus(X"79",X"32");  -- x=50
    wait_ready;
    write_bus(X"72",X"0C");  --
    write_bus(X"79",X"64");  -- x=100
    write_bus(X"7B",X"64");  -- y=100
    write_bus(X"70",X"41");  --
    wait_ready;
    
--    write_bus(X"71",X"0B");  --  CTRL1 = b, neverLeave=1
    write_bus(X"79",X"A0");  -- 
    write_bus(X"78",X"01");  -- x=0x1A0
    write_bus(X"7B",X"64");  -- y=100
    write_bus(X"77",X"10");  -- dy = 10
    write_bus(X"70",X"11");  -- x+=255, y+=10
    wait_ready;
    write_bus(X"70",X"0E");  -- y = 0
    write_bus(X"70",X"0D");  -- x = 0
    wait_ready;
    write_bus(X"72",X"00");  -- CTRL2 = 0
    write_bus(X"79",X"16");  -- x=22
    write_bus(X"70",X"01");  -- Löschstift
    write_bus(X"70",X"0B");  -- 4x4
    wait_ready;
    write_bus(X"79",X"20");  -- x=32
    write_bus(X"70",X"00");  -- Schreibstift
    write_bus(X"70",X"0B");  -- 4x4
    wait_ready;
    write_bus(X"72",X"04");  -- CTRL2 = 4
    write_bus(X"79",X"28");  -- x=40
    write_bus(X"70",X"0B");  -- 4x4
    wait_ready;
    write_bus(X"60",X"01");  -- XOR Mode
    write_bus(X"79",X"05");   -- x=5
    write_bus(X"72",X"00");  -- CTRL2 = 0
    write_bus(X"70",X"0B");  -- 4x4
    wait_ready;
--    line(47,75,30,88);
    write_bus(X"60",1*64);   -- Set Write-Page
    line(0,0,0,0);
    line(1,1,1,1);
    line(2,2,2,2);
    write_bus(X"60",0*64);   -- Set Write-Page
    line(100,65,94,79);
    line(94,79, 94,70);
    line(0,0,511,0);
    line(0,0,0,255);
--    line(511,0,511,255);
    write_bus(X"78",X"00");  
    write_bus(X"79",X"32");  -- x=50
    write_bus(X"7A",X"00");  -- y=50
    write_bus(X"7B",X"32");  -- y=50
    write_bus(X"73",X"00");  -- Max Size
    write_bus(X"70",X"0B");  -- 4x4
    wait_ready;
    
    write_bus(X"60",3*64);   -- Set Write-Page
    write_bus(X"70",X"0C");  -- Fill Screen
    wait_ready;
    
    do_dump <= true;
    wait for 1 us;
    assert false report "End of simulation" severity failure;
    wait;
  end process WaveGen_Proc;



end beh;

