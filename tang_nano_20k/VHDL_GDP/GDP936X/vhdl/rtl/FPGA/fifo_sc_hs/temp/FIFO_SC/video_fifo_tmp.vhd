--Copyright (C)2014-2024 Gowin Semiconductor Corporation.
--All rights reserved.
--File Title: Template file for instantiation
--Tool Version: V1.9.10 (64-bit)
--Part Number: GW2AR-LV18QN88C8/I7
--Device: GW2AR-18
--Device Version: C
--Created Time: Wed Sep  4 18:15:42 2024

--Change the instance name and port connections to the signal names
----------Copy here to design--------

component video_fifo
	port (
		Data: in std_logic_vector(31 downto 0);
		Clk: in std_logic;
		WrEn: in std_logic;
		RdEn: in std_logic;
		Reset: in std_logic;
		AlmostEmptyTh: in std_logic_vector(4 downto 0);
		Almost_Empty: out std_logic;
		Q: out std_logic_vector(31 downto 0);
		Empty: out std_logic;
		Full: out std_logic
	);
end component;

your_instance_name: video_fifo
	port map (
		Data => Data,
		Clk => Clk,
		WrEn => WrEn,
		RdEn => RdEn,
		Reset => Reset,
		AlmostEmptyTh => AlmostEmptyTh,
		Almost_Empty => Almost_Empty,
		Q => Q,
		Empty => Empty,
		Full => Full
	);

----------Copy end-------------------
