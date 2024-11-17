//Copyright (C)2014-2024 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//Tool Version: V1.9.10 (64-bit)
//Part Number: GW2AR-LV18QN88C8/I7
//Device: GW2AR-18
//Device Version: C
//Created Time: Fri Oct 18 20:42:04 2024

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    Gowin_rPLL_80 your_instance_name(
        .clkout(clkout), //output clkout
        .lock(lock), //output lock
        .clkoutp(clkoutp), //output clkoutp
        .reset(reset), //input reset
        .clkin(clkin) //input clkin
    );

//--------Copy end-------------------
