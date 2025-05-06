--Copyright (C)2014-2024 Gowin Semiconductor Corporation.
--All rights reserved.
--File Title: Template file for instantiation
--Tool Version: V1.9.10.03 (64-bit)
--Part Number: GW2AR-LV18QN88C8/I7
--Device: GW2AR-18
--Device Version: C
--Created Time: Mon Apr  7 19:25:26 2025

--Change the instance name and port connections to the signal names
----------Copy here to design--------

component dual_video_fifo
	port (
		Data: in std_logic_vector(31 downto 0);
		WrReset: in std_logic;
		RdReset: in std_logic;
		WrClk: in std_logic;
		RdClk: in std_logic;
		WrEn: in std_logic;
		RdEn: in std_logic;
		AlmostEmptyTh: in std_logic_vector(4 downto 0);
		Almost_Empty: out std_logic;
		Q: out std_logic_vector(31 downto 0);
		Empty: out std_logic;
		Full: out std_logic
	);
end component;

your_instance_name: dual_video_fifo
	port map (
		Data => Data,
		WrReset => WrReset,
		RdReset => RdReset,
		WrClk => WrClk,
		RdClk => RdClk,
		WrEn => WrEn,
		RdEn => RdEn,
		AlmostEmptyTh => AlmostEmptyTh,
		Almost_Empty => Almost_Empty,
		Q => Q,
		Empty => Empty,
		Full => Full
	);

----------Copy end-------------------
