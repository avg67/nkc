--Copyright (C)2014-2024 Gowin Semiconductor Corporation.
--All rights reserved.
--File Title: Template file for instantiation
--Tool Version: V1.9.9.02
--Part Number: GW2AR-LV18QN88C8/I7
--Device: GW2AR-18
--Device Version: C
--Created Time: Fri Jun 14 16:07:29 2024

--Change the instance name and port connections to the signal names
----------Copy here to design--------

component video_fifo
	port (
		Data: in std_logic_vector(31 downto 0);
		Clk: in std_logic;
		WrEn: in std_logic;
		RdEn: in std_logic;
		Reset: in std_logic;
		AlmostEmptyTh: in std_logic_vector(3 downto 0);
		Almost_Empty: out std_logic;
		Q: out std_logic_vector(31 downto 0);
		Empty: out std_logic;
		Full: out std_logic
	);
end component;

your_instance_name: video_fifo
	port map (
		Data => Data_i,
		Clk => Clk_i,
		WrEn => WrEn_i,
		RdEn => RdEn_i,
		Reset => Reset_i,
		AlmostEmptyTh => AlmostEmptyTh_i,
		Almost_Empty => Almost_Empty_o,
		Q => Q_o,
		Empty => Empty_o,
		Full => Full_o
	);

----------Copy end-------------------
