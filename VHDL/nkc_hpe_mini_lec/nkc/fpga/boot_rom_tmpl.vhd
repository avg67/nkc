-- VHDL module instantiation generated by SCUBA Diamond (64-bit) 3.12.1.454
-- Module  Version: 5.4
-- Tue May 30 19:45:10 2023

-- parameterized module component declaration
component boot_rom
    port (Address: in  std_logic_vector(10 downto 0); 
        OutClock: in  std_logic; OutClockEn: in  std_logic; 
        Reset: in  std_logic; Q: out  std_logic_vector(15 downto 0));
end component;

-- parameterized module component instance
__ : boot_rom
    port map (Address(10 downto 0)=>__, OutClock=>__, OutClockEn=>__, 
        Reset=>__, Q(15 downto 0)=>__);
