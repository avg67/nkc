//Copyright (C)2014-2024 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//Tool Version: V1.9.10.03 (64-bit)
//Part Number: GW2AR-LV18QN88C8/I7
//Device: GW2AR-18
//Device Version: C
//Created Time: Sat Apr  5 20:00:16 2025

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    pll_80m your_instance_name(
        .clkout(clkout), //output clkout
        .lock(lock), //output lock
        .clkoutd(clkoutd), //output clkoutd
        .reset(reset), //input reset
        .clkin(clkin) //input clkin
    );

//--------Copy end-------------------
