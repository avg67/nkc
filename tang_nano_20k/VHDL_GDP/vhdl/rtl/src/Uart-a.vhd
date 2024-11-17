--------------------------------------------------------------------------------
-- Project     : Sandbox AVR Library
-- Module      : UART
-- File        : Uart-a.vhd
-- Description : RS232 Interface 9600,n,8,1.
--------------------------------------------------------------------------------
-- Author       : Andreas Voggeneder
-- Organisation : FH-Hagenberg
-- Department   : Hardware/Software Systems Engineering
-- Language     : VHDL'87
--------------------------------------------------------------------------------
-- Copyright (c) 2003 by Andreas Voggeneder
--------------------------------------------------------------------------------


architecture rtl of Uart is
  component Transmitter
    port (
      clk       : in  std_ulogic;
      clr_n     : in  std_ulogic;
      TxD       : out std_ulogic;
      Busy      : out std_ulogic;
      DinPar    : in  std_ulogic_vector(7 downto 0);
      DataValid : in  std_ulogic);
  end component;
  component Receiver
    port (
      clk        : in  std_ulogic;
      clr_n      : in  std_ulogic;
      RxD        : in  std_ulogic;
      Busy       : in  std_ulogic;
      DoutPar    : out std_ulogic_vector(7 downto 0);
      DataValid  : out std_ulogic;
      ErrorFlags : out std_ulogic_vector(1 downto 0));
  end component;

  component AVRuart is 
  port(
    ireset   : in  std_logic;
    cp2      : in  std_logic;
    adr      : in  std_logic_vector(dUart_Size_c-1 downto 0);
    dbus_in  : in  std_logic_vector(7 downto 0);
    dbus_out : out std_logic_vector(7 downto 0);
    iore     : in  std_logic;
    iowe     : in  std_logic;
    avrcs    : in  std_logic;

    --UART
    rxd   : in  std_logic;
    rx_en : out std_logic;
    txd   : out std_logic;
    tx_en : out std_logic;

    --IRQ
    txcirq     : out std_logic;
    txc_irqack : in  std_logic;
    udreirq    : out std_logic;
    rxcirq     : out std_logic);
  end component;

  signal Status, StatusReg   : std_ulogic_vector(3 downto 0);
  signal DataRegTX,DataRegRX : std_ulogic_vector(7 downto 0);
  signal DoutParRX           : std_ulogic_vector(7 downto 0);
  signal ErrorFlags          : std_ulogic_vector(1 downto 0);
  signal DataValidTX,DataValidRX  : std_ulogic;
  signal BusyTX,BusyRX ,RXOverrun : std_ulogic;
  signal OldBusyTX,OldDataValidRX : std_ulogic;
  signal IrqToggle                : std_ulogic_vector(1 downto 0);

  signal dbout : std_logic_vector(7 downto 0);
  signal txcirq,udreirq,rxcirq : std_logic;
--  signal oldtxcirq,oldudreirq,oldrxcirq : std_ulogic;
begin

AVRUart1: if UseAVRUART_c=true generate
  UART0 : component AVRuart 
  port map(
    -- AVR Control
    ireset   => clr_n_i,
    cp2      => clk_i, 
    adr      => std_logic_vector(AVRAdr_i),
    dbus_in  => std_logic_vector(AVRDataIn_i),
    dbus_out => dbout,
    iore     => std_logic(AVRRd_i),
    iowe     => std_logic(AVRWr_i),
    avrcs    => std_logic(AVRCS_i),

    --UART
    rxd   => rxd,
    rx_en => open,
    txd   => txd,
    tx_en => open,

    --IRQ
    txcirq     => txcirq,  
    txc_irqack => '0',
    udreirq    => udreirq,  
    rxcirq     => rxcirq   
    );
    
    AVRDataOut_o <= std_ulogic_vector(dbout);
    
--    process(clk_i, clr_n_i)
--    begin
--      if clr_n_i = ResetActive_c then
--        IrqToggle   <= (others => '0');
--        oldtxcirq   <= '0';
--        oldudreirq  <= '0';
--        oldrxcirq   <= '0';
--      elsif clk_i'event and clk_i = '1' then
--        oldtxcirq  <=txcirq; 
--        oldudreirq <=udreirq;
--        oldrxcirq  <=rxcirq; 
--        if (rxcirq='1' and oldrxcirq='0') or
--           (udreirq='1' and oldudreirq='0') then
--          IrqToggle(0) <= not IrqToggle(0);       -- RX Interrupt
--        end if;
--
--        if (txcirq='1' and oldtxcirq='0') then
--          IrqToggle(1) <= not IrqToggle(1);       -- TX Interrupt
--        end if;
--      end if;
--    end process;
    AVRIrq_o  <= (rxcirq or udreirq) & txcirq;
end generate;

NoAVRUart: if UseAVRUART_c=false generate


  Tx: Transmitter
    port map (
      clk       => clk_i,
      clr_n     => clr_n_i,
      TxD       => TxD,
      Busy      => BusyTX,
      DinPar    => DataRegTX,
      DataValid => DataValidTX);

  Rx: Receiver
    port map (
      clk        => clk_i,
      clr_n      => clr_n_i,
      RxD        => RxD,
      Busy       => BusyRX,
      DoutPar    => DoutParRX,
      DataValid  => DataValidRX,
      ErrorFlags => ErrorFlags);

  AVRDataOut_o <= StatusReg(3 downto 2)&"0000"&StatusReg(1 downto 0) when AVRAdr_i(0)='0' else
                  DataRegRX;

  -- Es sind z.Zt 4 Adressen (2 bits) für Modul- interne Adressen reserviert
  -- Prozess zum schreiben der Register im FPGA (Led, KeyDDRReg) 
  Regs : process(clk_i, clr_n_i)
  begin
    if clr_n_i = ResetActive_c then
      DataRegTX   <= (others => '0');
      DataRegRX   <= (others => '0');
      StatusReg   <= (others => '0');
      IrqToggle   <= (others => '0');
      DataValidTX <= '0';
      OldBusyTX   <= '0';
      BusyRX      <= '0';
      OldDataValidRX <= '0';
      RXOverrun   <= '0';
    elsif clk_i'event and clk_i = '1' then
      
      OldBusyTX <= BusyTX;
      OldDataValidRX <= DataValidRX;
      if ((OldBusyTX xor BusyTX) and OldBusyTX)='1' then
        DataValidTX  <= '0';
        IrqToggle(1) <= not IrqToggle(1);       -- TX Interrupt
      end if;
      if ((OldDataValidRX xor DataValidRX) and DataValidRX)='1' then
        RXOverrun <= RXOverrun or BusyRX;
        BusyRX    <= '1';
        DataRegRX <= DoutParRX;
        IrqToggle(0) <= not IrqToggle(0);       -- RX Interrupt
      end if;
      if AVRCS_i=activated_c then
        if AVRWr_i = '1' then
          if AVRAdr_i(0) = '1' then
            DataRegTX   <= AVRDataIn_i;
            DataValidTX <= '1';
          end if;
        end if;
        if AVRRd_i = '1' and AVRAdr_i(0) = '1' then      -- Lesen des Datenregisters
          BusyRX    <= '0';
          RXOverrun <= '0';
        end if;
      else
        StatusReg <= Status;
      end if;
    end if;
  end process Regs;

  Status(0) <= BusyRX;
  Status(1) <= not DataValidTX;
  Status(2) <= RXOverrun;
  Status(3) <= ErrorFlags(1);
  AVRIrq_o  <= IrqToggle;
 end generate;  
 

end rtl;




