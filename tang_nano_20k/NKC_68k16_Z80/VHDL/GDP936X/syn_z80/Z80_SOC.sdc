//Copyright (C)2014-2025 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.11.03 (64-bit) 
//Created Time: 2025-08-14 21:42:08
create_clock -name clk_hdmi -period 5 -waveform {0 3.125} [get_nets {video2hdmi/clk_pixel_x5}] -add
create_clock -name clk_osc -period 37 -waveform {0 18} [get_ports {refclk_i}] -add
//set_false_path -from [get_pins {video2hdmi/n30_s1/I0}] -through [get_nets {video2hdmi/clk_audio}] -to [get_pins {video2hdmi/clk_audio_s0/D}] 
//set_false_path -from [get_pins {video2hdmi/n30_s1/I0}] -to [get_pins {video2hdmi/clk_audio_s0/D}] 
