--Copyright (C)2014-2024 Gowin Semiconductor Corporation.
--All rights reserved.
--File Title: Template file for instantiation
--Tool Version: V1.9.10 (64-bit)
--Part Number: GW2AR-LV18QN88C8/I7
--Device: GW2AR-18
--Device Version: C
--Created Time: Sun Oct 20 18:18:33 2024

--Change the instance name and port connections to the signal names
----------Copy here to design--------

component Gowin_rPLL_40
    port (
        clkout: out std_logic;
        lock: out std_logic;
        clkoutp: out std_logic;
        reset: in std_logic;
        clkin: in std_logic
    );
end component;

your_instance_name: Gowin_rPLL_40
    port map (
        clkout => clkout,
        lock => lock,
        clkoutp => clkoutp,
        reset => reset,
        clkin => clkin
    );

----------Copy end-------------------
