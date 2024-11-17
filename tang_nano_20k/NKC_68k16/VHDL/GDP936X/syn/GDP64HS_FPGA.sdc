//Copyright (C)2014-2023 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.9 Beta-4
//Created Time: 2023-09-22 09:53:28
create_clock -name clk_hdmi -period 5.00 -waveform {0 3.125} [get_nets {video2hdmi/clk_pixel_x5}] -add
//create_clock -name clk_spi -period 10 -waveform {0 5} [get_ports {mspi_clk}] -add
create_clock -name clk_osc -period 37 -waveform {0 18} [get_ports {refclk_i}] -add
//create_clock -name clk_32 -period 31 -waveform {0 15} [get_ports {O_sdram_clk}] -add

