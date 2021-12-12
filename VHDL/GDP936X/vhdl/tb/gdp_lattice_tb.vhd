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

entity gdp_lattice_tb is

end gdp_lattice_tb;

-------------------------------------------------------------------------------

architecture beh of gdp_lattice_tb is

  -- clock
  signal Clk     : std_logic := '1';
  signal CPU_Clk : std_logic := '1';
  -- component ports
  signal reset_n_i : std_ulogic;
  signal nkc_DB_buf  : std_logic_vector(7 downto 0); 
  signal nkc_DB      : std_logic_vector(7 downto 0);
  signal nkc_ADDR    : std_ulogic_vector(7 downto 0);
  signal nkc_nRD     : std_ulogic;
  signal nkc_nWR     : std_ulogic;
  signal nkc_nIORQ   : std_ulogic;
  signal driver_nEN  : std_ulogic;
  signal driver_DIR  : std_ulogic;

  signal SRAM_addr_o    : std_ulogic_vector(16 downto 0);
--  signal SRAM_data_o    : std_ulogic_vector(7 downto 0);
--  signal SRAM_data_i    : std_ulogic_vector(7 downto 0);
--  signal SRAM_ena_o     : std_ulogic;
--  signal SRAM_we_o      : std_ulogic;
  signal SRAM_Addr      : std_logic_vector(16 downto 0);
  signal SRAM_DB        : std_logic_vector(7 downto 0);
  signal SRAM_nCE       : std_logic;
  signal SRAM_nWR       : std_logic;
  signal SRAM_nOE       : std_logic;
  signal do_dump        : boolean;
  signal Ps2Clk         : std_logic;
  signal Ps2Dat         : std_logic;
  signal Ps2MouseClk    : std_logic;
  signal Ps2MouseDat    : std_logic;
  signal TxD            : std_ulogic;
  signal FTDI_DATA      : std_logic_vector(7 downto 0);
  signal FTDI_nRD_o     : std_logic;
  signal FTDI_WR_o      : std_logic;
  signal FTDI_nTXE_i    : std_logic;
  signal FTDI_nRXF_i    : std_logic;
  signal FTDI_RESET_o   : std_logic;
--	signal FDD_IPn        : std_logic;
--	signal FDD_MOn        : std_logic;
--	signal FDD_STEPn      : std_logic;
--	signal FDD_DIRCn      : std_logic;
--	signal FDD_TR00n      : std_logic;
--	signal track          : natural range 0 to 79;
  
begin  -- beh
  
  -- component instantiation
--  DUT: entity work.gdp_lattice_top
--    generic map(sim_g => true)
--    port map (
--      reset_n_i   => reset_n_i,
--      addr_sel_i  => '1',
--      clk_i       => clk,
--      RxD_i       => TxD,
--      TxD_o       => TxD,
--      CTS_i       => '1',
--      Ps2Clk_io   => Ps2Clk,
--      Ps2Dat_io   => Ps2Dat,
--      Ps2MouseClk_io => Ps2MouseClk,
--      Ps2MouseDat_io => Ps2MouseDat,
--      nkc_DB      => nkc_DB_buf,      
--      nkc_ADDR_i  => nkc_ADDR,  
--      nkc_nRD_i   => nkc_nRD,   
--      nkc_nWR_i   => nkc_nWR,   
--      nkc_nIORQ_i => nkc_nIORQ, 
--      driver_nEN_o=> driver_nEN,
--      driver_DIR_o=> driver_DIR,
--      SRAM1_ADR   => SRAM_addr_o,
--      SRAM1_DB    => SRAM_DB,
--      SRAM1_nCS   => SRAM_nCE,
--      SRAM1_nWR   => SRAM_nWR,
--      SRAM1_nOE   => SRAM_nOE);
  DUT: entity work.gdp_lattice_top
    generic map(sim_g => true)
    port map (
      reset_n_i   => reset_n_i,
      clk_i       => clk,
      RxD_i       => TxD,
      TxD_o       => TxD,
      CTS_i       => '1',
      Ps2Clk_io   => Ps2Clk,
      Ps2Dat_io   => Ps2Dat,
      Ps2MouseClk_io => Ps2MouseClk,
      Ps2MouseDat_io => Ps2MouseDat,
      nkc_DB      => nkc_DB_buf,      
      nkc_ADDR_i  => nkc_ADDR,  
      nkc_nRD_i   => nkc_nRD,   
      nkc_nWR_i   => nkc_nWR,   
      nkc_nIORQ_i => nkc_nIORQ, 
      driver_nEN_o=> driver_nEN,
      driver_DIR_o=> driver_DIR,
      SRAM1_ADR   => SRAM_addr_o,
      SRAM1_DB    => SRAM_DB,
      SRAM1_nCS   => SRAM_nCE,
      SRAM1_nWR   => SRAM_nWR,
      SRAM1_nOE   => SRAM_nOE,
--      FDD_RDn     => '0',
--      FDD_TR00n   => FDD_TR00n,
--      FDD_IPn     => FDD_IPn,
--      FDD_WPRTn   => '0',
--      FDD_MOn     => FDD_MOn,
--      FDD_WGn     => open,
--      FDD_WDn     => open,
--      FDD_STEPn   => FDD_STEPn,
--      FDD_DIRCn   => FDD_DIRCn,
--      FDD_DSELn   => open,
--      FDD_SDSEL   => open,
--      FDD_SIDE    => open
      FTDI_DATA   => FTDI_DATA,   
      FTDI_nRD_o  => FTDI_nRD_o,  
      FTDI_WR_o   => FTDI_WR_o,   
      FTDI_nTXE_i => FTDI_nTXE_i, 
      FTDI_nRXF_i => FTDI_nRXF_i, 
      FTDI_RESET_o=> FTDI_RESET_o
      );
      
  FTDI_DATA <= (others => 'H');
  FTDI_nTXE_i <= '0';
  FTDI_nRXF_i <= '1';

  RX : entity work.RS_232_RX
    port map(RX => TxD);


  -- clock generation
  Clk     <= not Clk after 12.5 ns;  -- 40 MHz
  CPU_Clk <= not CPU_Clk after 63 ns; -- ~8 MHz

  nkc_DB_buf <= nkc_DB after 5 ns when driver_nEN = '0' and driver_DIR = '1' else
                (others => 'Z') after 5 ns;

  nkc_DB     <= nkc_DB_buf after 5 ns when driver_nEN = '0' and driver_DIR = '0' else
                (others => 'Z') after 5 ns;

--  SRAM_DB <= std_logic_vector(SRAM_data_o) after 1 ns when (SRAM_ena_o and SRAM_we_o)='1' else
--             (others => 'Z') after 1 ns;

--  SRAM_data_i <= std_ulogic_vector(SRAM_DB);
--  SRAM_nCE    <= not (SRAM_ena_o and not Clk);
--  SRAM_nWR    <= not (SRAM_we_o and not Clk);
--  SRAM_nOE    <= (SRAM_we_o and not Clk);
  SRAM_Addr   <= std_logic_vector(SRAM_addr_o(15 downto 0)) after 1 ns;
  VSRAM0 : entity work.SRAM
    generic map(
      dump_offset => 0,
      size        => 2**17,
      adr_width   => 17
    )
    port map(
      dump => do_dump,
      nCE => SRAM_nCE,
      nWE => SRAM_nWR,
      nOE => SRAM_nOE,
      A   => SRAM_Addr(16 downto 0),
      D   => SRAM_DB(7 downto 0)
    );
    
  VSRAM1 : entity work.SRAM
    generic map(
      dump_offset => 2,
      size        => 2**17,
      adr_width   => 17
    )
    port map(
      dump => do_dump,
      nCE => SRAM_nCE1,
      nWE => SRAM_nWR,
      nOE => SRAM_nOE,
      A   => SRAM_Addr(16 downto 0),
      D   => SRAM_DB(7 downto 0)
    );


--  process
--  begin
--    loop
--      FDD_IPn <= '1';
--      if FDD_MOn/='1' then
--        wait until FDD_MOn='1';
--      end if;
--      wait for 200 us;
--      FDD_IPn <= '0';
--      wait for 5 us;
--    end loop;
--  end process;
--
--  process
--  begin
--    track     <= 0;
--
--    loop
--      if FDD_MOn/='1' then
--        wait until FDD_MOn='1';
--      end if;
--      wait until FDD_STEPn'event and FDD_STEPn='1';
--      if FDD_DIRCn='0' then
--        if track >0 then
--          track <= track -1;
--        else
--          assert false report "Step Error 1" severity error;
--        end if;
--      else
--        if track < 79 then
--          track <= track +1;
--        else
--          assert false report "Step Error 2" severity error;
--        end if;
--      end if;
--    end loop;
--  end process;
--
--  FDD_TR00n <= '0' when track=0 else
--               '1';


  -- waveform generation
  WaveGen_Proc: process
    procedure write_bus(addr : in bit_vector(7 downto 0); data : in bit_vector(7 downto 0)) is
    begin
      nkc_ADDR    <= to_stdulogicvector(addr) after 80 ns;
      wait until CPU_Clk'event and CPU_Clk='0';
      nkc_DB      <= to_stdlogicvector(data) after 115 ns;
      wait until CPU_Clk'event and CPU_Clk='1';
      
      nkc_nIORQ   <= '0' after 55 ns;
      nkc_nWR     <= '0' after 60 ns;
      
      wait until CPU_Clk'event and CPU_Clk='1';
      wait until CPU_Clk'event and CPU_Clk='1';
      wait until CPU_Clk'event and CPU_Clk='1';
      wait until CPU_Clk'event and CPU_Clk='0';
      nkc_nIORQ   <= '1' after 60 ns;
      nkc_nWR     <= '1' after 60 ns;
      nkc_DB      <= (others => 'Z') after 75 ns;
      wait until CPU_Clk'event and CPU_Clk='1';
      
    end write_bus;
    
    procedure write_bus(addr : in bit_vector(7 downto 0); data : in natural) is
    begin
      nkc_ADDR    <= to_stdulogicvector(addr) after 80 ns;
      wait until CPU_Clk'event and CPU_Clk='0';
      nkc_DB      <= std_logic_vector(to_unsigned(data,8)) after 115 ns;
      wait until CPU_Clk'event and CPU_Clk='1';
      
      
      nkc_nIORQ   <= '0' after 55 ns;
      nkc_nWR     <= '0' after 60 ns;
      
      wait until CPU_Clk'event and CPU_Clk='1';
      wait until CPU_Clk'event and CPU_Clk='1';
      wait until CPU_Clk'event and CPU_Clk='1';
      wait until CPU_Clk'event and CPU_Clk='0';
      nkc_nIORQ   <= '1' after 60 ns;
      nkc_nWR     <= '1' after 60 ns;
      nkc_DB      <= (others => 'Z') after 75 ns;
      wait until CPU_Clk'event and CPU_Clk='1';
      
    end write_bus;

    procedure read_bus(addr : in bit_vector(7 downto 0); data : out std_ulogic_vector(7 downto 0)) is
    begin
      nkc_ADDR    <= to_stdulogicvector(addr) after 80 ns;

      wait until CPU_Clk'event and CPU_Clk='1';
      
      nkc_nIORQ   <= '0' after 55 ns;
      nkc_nRD     <= '0' after 60 ns;
      
      wait until CPU_Clk'event and CPU_Clk='1';
      wait until CPU_Clk'event and CPU_Clk='1';
      wait until CPU_Clk'event and CPU_Clk='1';
      wait until CPU_Clk'event and CPU_Clk='0';
      nkc_nIORQ   <= '1' after 60 ns;
      nkc_nRD     <= '1' after 60 ns;
      assert nkc_DB'stable(30 ns) report "Data Read Error" severity error;
      data        := std_ulogic_vector(nkc_DB);
      wait until CPU_Clk'event and CPU_Clk='1';
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
    
    procedure wait_tx_empty is
      variable tmp_v : std_ulogic_vector(7 downto 0);
    begin
      read_bus(X"F1",tmp_v); -- status register
      while tmp_v(4) = '0' loop
        read_bus(X"F1",tmp_v);
      end loop;
    end wait_tx_empty;
    
    procedure send_uart(data : in bit_vector(7 downto 0)) is
    begin
      wait_tx_empty;
      write_bus(X"F0",data);
    end send_uart;
      
    
    variable read_data : std_ulogic_vector(7 downto 0);
  begin
    -- insert signal assignments here
    do_dump    <= false;
    nkc_DB     <= (others => 'Z');
    nkc_ADDR   <= (others => '0');
    nkc_nRD    <=  '1';
    nkc_nWR    <=  '1';
    nkc_nIORQ  <=  '1';

    reset_n_i  <= '0', '1' after 50 ns;
    wait for 100 ns;
    wait until CPU_Clk'event and CPU_Clk='1';
    
    -- FLO2 Test
--    write_bus(X"C5",X"5A");
--    read_bus(X"C5",read_data);
--    write_bus(X"C5",X"A5");
--    read_bus(X"C5",read_data);
    write_bus(X"C4",X"21");  -- MINI Laufwerk
--    write_bus(X"C0",X"D0");
--    write_bus(X"C0",X"08");  -- restore
--    wait for 1 us;
--    wait until CPU_Clk'event and CPU_Clk='1';
--    write_bus(X"C0",X"D0");

    read_bus(X"C0",read_data); -- Status lesen
    read_bus(X"C4",read_data);
    
--    wait;

    
--    write_bus(X"C0",X"00");  -- restore
    write_bus(X"C0",X"08");  -- restore
    read_bus(X"C0",read_data); -- Status lesen
    loop
      read_bus(X"C4",read_data);
      exit when read_data(6)='1';
    end loop;
    read_bus(X"C0",read_data); -- Status lesen
    wait;

    write_bus(X"C3",X"05");  -- Spur 5
--    write_bus(X"C0",X"17");  -- Seek
    write_bus(X"C0",X"1F");  -- Seek
    
    
    
    write_bus(X"50",0);
    write_bus(X"51",X"55");     -- Frequenz A = 0x055
    read_bus(X"51",read_data);
    write_bus(X"50",2);      
    write_bus(X"51",X"AA");     -- Frequenz B = 0x0AA    
    write_bus(X"50",7);
    write_bus(X"51",X"FC");     -- Freigabe A,B
    write_bus(X"50",8);
    write_bus(X"51",15);        -- Aplitude A = 15
    write_bus(X"50",9);
    write_bus(X"51",31);        -- Aplitude B = Hüllkurve
    write_bus(X"50",X"0D");
    write_bus(X"51",8);
    write_bus(X"50",X"0B");
    write_bus(X"51",X"0F");
    
--    read_bus(X"60",read_data);

    
--    write_bus(X"F3",X"1F"); -- 8 bit
--    write_bus(X"F2",X"66"); -- 8,e,1 bit
----    write_bus(X"FC",X"55");
--    send_uart(X"55");
--    send_uart(X"00");
--    send_uart(X"02");
--    send_uart(X"FF");
--    wait_tx_empty;
--    wait for 600 us;
--    write_bus(X"F3",X"BF"); -- 7,n,2
--    write_bus(X"F2",X"06"); -- 7,n,1 bit
--    send_uart(X"55");
--    send_uart(X"00");
--    send_uart(X"02");
--    
--    read_bus(X"F0",read_data);
--    
--    send_uart(X"FF");
--    
--    
--    
--    read_bus(X"8B",read_data);
--    read_bus(X"8C",read_data);
--    read_bus(X"8D",read_data);
--    read_bus(X"8E",read_data);
--    read_bus(X"8F",read_data);
--    
--    read_bus(X"68",read_data);
--    read_bus(X"69",read_data);
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
    line(100,65,94,79);
    line(94,79, 94,70);
    line(0,0,511,0);
    line(0,0,0,255);
    line(100,2,105,-5);

    write_bus(X"78",X"00");        -- x msb
--    write_bus(X"79",X"10");        -- x lsb
    write_bus(X"79",X"64");        -- x lsb
--    write_bus(X"7A",X"0F");        -- y msb
--    write_bus(X"7B",X"FA");       -- y lsb
    write_bus(X"7A",X"00");        -- y msb
    write_bus(X"7B",X"05");       -- y lsb
    write_bus(X"75",X"0A");        -- dx
    write_bus(X"77",X"0A");        -- dy
    write_bus(X"70",17+1*2+1*4);
--    line(511,0,511,255);
    
    write_bus(X"70",X"0E");  -- y = 0
    write_bus(X"70",X"0D");  -- x = 0
    write_bus(X"70",X"0f");  -- DMA
    wait_ready;
    read_bus(X"60",read_data); 
    write_bus(X"79",X"08");  -- x=8
    write_bus(X"70",X"0f");  -- DMA
    wait_ready;
    read_bus(X"60",read_data);
    
    write_bus(X"60",3*64);   -- Set Write-Page
    write_bus(X"70",X"0C");  -- Fill Screen
    wait_ready;
    
    read_bus(X"68",read_data);
    read_bus(X"69",read_data);
    

    do_dump <= true;
    wait for 1 us;
    assert false report "End of simulation" severity failure;
    wait;
  end process WaveGen_Proc;

  Ps2Clk <= 'H';
  Ps2Dat <= 'H';
  Ps2MouseClk <= 'H';
  Ps2MouseDat <= 'H';
  
  -- waveform generation
  PS2_Proc: process
    procedure sendbit(b : in std_logic) is
    begin
      Ps2Dat <= b;
      Ps2Clk <= '0';
      wait for 25 us;
      Ps2Clk <= '1';
      wait for 25 us;
    end sendbit;
    procedure sendkbd(data : in std_logic_vector(7 downto 0)) is
      variable parity : std_logic :='1';
    begin
      sendbit('0');
      for i in 0 to 7 loop
        sendbit(data(i));
        parity := parity xor data(i);
      end loop;
      sendbit(parity);
      sendbit('1');
      Ps2Clk <= 'Z';
      Ps2Dat <= 'Z';
    end sendkbd;
  begin

    Ps2Clk <= 'Z';
    Ps2Dat <= 'Z';
    wait for 100 us;
    sendkbd(X"1c"); -- a
    wait for 1 ms;
    sendkbd(X"F0");
    sendkbd(X"1c");
    sendkbd(X"12"); -- shift
    sendkbd(X"1c"); -- A
    wait for 1 ms;
    sendkbd(X"F0");
    sendkbd(X"1c");
    sendkbd(X"F0");
    sendkbd(X"12"); -- shift relese
    sendkbd(X"06"); -- F1
    wait for 1 ms;
    sendkbd(X"F0");  
    sendkbd(X"06"); -- F1  
    sendkbd(X"E0");
    sendkbd(X"7d"); -- PGUP
    wait for 1 ms;
    sendkbd(X"E0");
    sendkbd(X"F0");  
    sendkbd(X"7D");
    wait for 1 ms;
    wait;
  end process PS2_Proc;

  PS2_Mouse: process
    procedure sendbit(b : in std_logic) is
    begin
      Ps2MouseDat <= b;
      Ps2MouseClk <= '0';
      wait for 25 us;
      Ps2MouseClk <= '1';
      wait for 25 us;
    end sendbit;
    procedure sendmouse(data : in std_logic_vector(7 downto 0)) is
      variable parity : std_logic :='1';
    begin
      sendbit('0');
      for i in 0 to 7 loop
        sendbit(data(i));
        parity := parity xor data(i);
      end loop;
      sendbit(parity);
      sendbit('1');
      Ps2MouseClk <= 'Z';
      Ps2MouseDat <= 'Z';
    end sendmouse;
  begin

    Ps2MouseClk <= 'Z';
    Ps2MouseDat <= 'Z';
    wait for 100 us;
    sendmouse(X"08"); 
    sendmouse(X"05");
    sendmouse(X"05");
    wait for 1 ms;
    sendmouse(X"38"); 
    sendmouse(X"FB");
    sendmouse(X"FB");
    wait;
  end process PS2_Mouse;

end beh;

