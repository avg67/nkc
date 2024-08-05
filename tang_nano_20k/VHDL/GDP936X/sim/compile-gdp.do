
#vlog -reportprogress 300 -work work ../../vhdl/rtl/FPGA/SDRAM_controller_top_SIP.vo 
vlog -work work ../../vhdl/rtl/FPGA/sdram.v \
                ../vhdl/tb/sdram_sim_model_64Mb_16bit.v

vlog -work work ../../vhdl/rtl/hdmi/hdmi/audio_clock_regeneration_packet_sim.sv \
                ../../vhdl/rtl/hdmi/hdmi/audio_info_frame.sv \
                ../../vhdl/rtl/hdmi/hdmi/audio_sample_packet.sv \
                ../../vhdl/rtl/hdmi/hdmi/auxiliary_video_information_info_frame.sv \
                ../../vhdl/rtl/hdmi/hdmi/hdmi.sv \
                ../../vhdl/rtl/hdmi/hdmi/packet_assembler.sv \
                ../../vhdl/rtl/hdmi/hdmi/packet_picker.sv \
                ../../vhdl/rtl/hdmi/hdmi/serializer.sv \
                ../../vhdl/rtl/hdmi/hdmi/source_product_description_info_frame.sv \
                ../../vhdl/rtl/hdmi/hdmi/tmds_channel.sv \
                ../../vhdl/rtl/hdmi/video2hdmi.sv \
                ../../vhdl/rtl/hdmi/gowin_rpll_200/gowin_rpll/pll_200m.v \
                ../../vhdl/rtl/hdmi/gowin_clkdiv/gowin_clkdiv.v

#vcom -93 -check_synthesis ../vhdl/rtl/Dffdecl-p.vhd
vcom -93                  ../vhdl/rtl/Dffdecl-p.vhd \
                          ../vhdl/rtl/InputSync-e.vhd \
                          ../vhdl/rtl/InputSync-a.vhd \
                          ../vhdl/rtl/gdp_global-p.vhd \
                          ../vhdl/rtl/gdp_bi.vhd  \
                          ../vhdl/rtl/gdp_decoder.vhd \
                          ../vhdl/rtl/gdp_bresenham.vhd \
                          ../vhdl/rtl/gdp_font.vhd \
                          ../vhdl/rtl/gdp_font_ram.vhd \
                          ../vhdl/rtl/gdp_character.vhd \
                          ../vhdl/rtl/gdp_vram.vhd \
                          ../vhdl/rtl/gdp_kernel.vhd \
                          ../vhdl/rtl/gdp_clut.vhd \
                          ../vhdl/rtl/FPGA/fifo_sc_hs/video_fifo.vho \
                          ../vhdl/rtl/gdp_video.vhd \
                          ../vhdl/rtl/gdp_top.vhd \
                          ../../vhdl/rtl/PS2_Interface.vhd \
                          ../../vhdl/rtl/PS2_Decoder.vhd \
                          ../../vhdl/rtl/FPGA/ps2_fifo.vho \
                          ../../vhdl/rtl/PS2Keyboard.vhd \
                          ../../vhdl/rtl/PS2Mouse.vhd \
                          ../../vhdl/rtl/Ser1.vhd \
                          ../../vhdl/rtl/SPI_Interface.vhd \
                          ../../vhdl/rtl/SPI_Vdip.vhd \
                          ../../vhdl/rtl/Timer.vhd \
                          ../../vhdl/rtl/GPIO_Interface.vhd \
                          ../../vhdl/rtl/src/UART_pkg.vhd \
                          ../../vhdl/rtl/src/TB_Receiver.vhd \
                          ../../vhdl/rtl/src/TB_Sender.vhd \
                          ../../vhdl/rtl/sound/wf2149ip_pkg.vhd \
                          ../../vhdl/rtl/sound/wf2149ip_wave.vhd \
                          ../../vhdl/rtl/sound/dac.vhd \
                          ../../vhdl/rtl/sound/wf2149ip_top_soc.vhd \
                          ../vhdl/rtl/gdp_lattice_top_woflo.vhd
vcom -93  ../vhdl/tb/gdp_bitmap-p.vhd
#vcom -93  ../vhdl/tb/sram.vhd
vcom -93  ../vhdl/tb/sram_256x16/package_timing.vhd
vcom -93  ../vhdl/tb/sram_256x16/package_utility.vhd
vcom -93  ../vhdl/tb/sram_256x16/mobl_256Kx16.vhd
#vcom -93  ../vhdl/tb/gdp_kernel_tb.vhd
vcom -93  ../vhdl/tb/gdp_tb.vhd


vsim -t ps -L gw2a -voptargs=+acc gdp_tb gw2a.GSR
onerror {resume}
add wave -group {TB} -noupdate -radix hex /*
add wave -group {sdram} -noupdate -radix hex /dram_1/*
add wave -group {Top} -noupdate -radix hex /dut/*
#add wave -group {sdram_arbiter_top} -noupdate -radix hex /dut/sdram_top_inst/*
add wave -group {Businterface} -noupdate -radix hex /dut/bi_inst/*
#add wave -noupdate -divider Keyboard
#add wave -group {PS2} -noupdate -radix hex /dut/impl_key2/kbd/*
#add wave -group {PS2_if} -noupdate -radix hex /dut/impl_key2/kbd/PS2if/*
#add wave -group {PS2_Decoder} -noupdate -radix hex /dut/impl_key2/kbd/PS2dec/*
#add wave -noupdate -divider Mouse
#add wave -group {Mouse} -noupdate -radix hex /dut/impl_mouse/mouse/*
#add wave -group {Mouse} -noupdate -radix hex /dut/impl_mouse/mouse/nkc_mouse/*
#add wave -group {Mouse_PS2_IF} -noupdate -radix hex /dut/impl_mouse/mouse/PS2if/*
add wave -noupdate -divider
#add wave -group {SPI} -noupdate -radix hex /dut/impl_spi/spi/*
##add wave -group {VDIP} -noupdate -radix hex /dut/impl_vdip/vdip/*
#add wave -group {GPIO} -noupdate -radix hex /dut/impl_GPIO/GPIO/*
#add wave -group {Ser1} -noupdate -radix hex /dut/impl_ser1/ser/*
#add wave -group {TB_Receiver} -noupdate -radix hex /rx/*
add wave -noupdate -divider GDP
add wave -group {Video} -noupdate -radix hex /dut/gdp/video/*
add wave -group {video2hdmi} -noupdate -radix hex /dut/video2hdmi/*
add wave -group {CLUT} -noupdate -radix hex /dut/gdp/video/use_clut/clut_inst/*
add wave -group {Decoder} -noupdate -radix hex /dut/gdp/kernel/dec/*
add wave -group {Kernel} -noupdate -radix hex /dut/gdp/kernel/*
add wave -group {Bresenham} -noupdate -radix hex /dut/gdp/kernel/bres/*
add wave -group {Char} -noupdate -radix hex /dut/gdp/kernel/char/*
add wave -group {VRAM} -noupdate -radix hex /dut/gdp/vram/*
add wave -group {sdram_ctrl} -noupdate -radix hex /dut/gdp/vram/sdram_inst/*
add wave -group {GDP_Top} -noupdate -radix hex /dut/gdp/*
#add wave -noupdate -divider Sound
#add wave -group {Sound} -noupdate -radix hex /dut/impl_sound/sound_inst/*
#add wave -group {Sound_Wave} -noupdate -radix hex /dut/impl_sound/sound_inst/i_psg_wave/*
#add wave -noupdate -divider
#add wave -group {Timer1} -noupdate -radix hex /dut/impl_t1/t1/*

TreeUpdate [SetDefaultTree]
configure wave -signalnamewidth 1
