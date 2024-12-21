
#vlog -reportprogress 300 -work work ../../vhdl/rtl/FPGA/SDRAM_controller_top_SIP.vo 
vlog -work work ../fx68k/fx68kAlu.sv \
                ../fx68k/uaddrPla.sv \
                ../fx68k/fx68k.sv \
                ../../Firmware/test.v \
                ../../Firmware/gp710r5.v

vlog -work work ../vhdl/rtl/FPGA/sdram.v \
                ../GDP936X/vhdl/tb/sdram_sim_model_64Mb_16bit.v

vlog -work work ../vhdl/rtl/hdmi/hdmi/audio_clock_regeneration_packet_sim.sv \
                ../vhdl/rtl/hdmi/hdmi/audio_info_frame.sv \
                ../vhdl/rtl/hdmi/hdmi/audio_sample_packet.sv \
                ../vhdl/rtl/hdmi/hdmi/auxiliary_video_information_info_frame.sv \
                ../vhdl/rtl/hdmi/hdmi/hdmi.sv \
                ../vhdl/rtl/hdmi/hdmi/packet_assembler.sv \
                ../vhdl/rtl/hdmi/hdmi/packet_picker.sv \
                ../vhdl/rtl/hdmi/hdmi/serializer.sv \
                ../vhdl/rtl/hdmi/hdmi/source_product_description_info_frame.sv \
                ../vhdl/rtl/hdmi/hdmi/tmds_channel.sv \
                ../vhdl/rtl/hdmi/video2hdmi.sv \
                ../vhdl/rtl/hdmi/gowin_rpll_200/gowin_rpll/pll_200m.v \
                ../vhdl/rtl/hdmi/gowin_clkdiv/gowin_clkdiv.v \
                ../vhdl/rtl/FPGA/gowin_rpll/gowin_rpll_40.v

vcom -2008  ../GDP936X/vhdl/tb/gdp_bitmap-p.vhd \
            ../vhdl/rtl/src/UART_pkg.vhd \
            ../vhdl/rtl/src/TB_sender.vhd

vcom -93                  ../GDP936X/vhdl/rtl/Dffdecl-p.vhd \
                          ../GDP936X/vhdl/rtl/InputSync-e.vhd \
                          ../GDP936X/vhdl/rtl/InputSync-a.vhd \
                          ../GDP936X/vhdl/rtl/gdp_global-p.vhd \
                          ../GDP936X/vhdl/rtl/gdp_bi.vhd  \
                          ../GDP936X/vhdl/rtl/gdp_decoder.vhd \
                          ../GDP936X/vhdl/rtl/gdp_bresenham.vhd \
                          ../GDP936X/vhdl/rtl/gdp_font.vhd \
                          ../GDP936X/vhdl/rtl/gdp_font_ram.vhd \
                          ../GDP936X/vhdl/rtl/gdp_character.vhd \
                          ../GDP936X/vhdl/tb/gdp_screen_saver.vhd \
                          ../GDP936X/vhdl/rtl/gdp_vram.vhd \
                          ../GDP936X/vhdl/rtl/gdp_kernel.vhd \
                          ../GDP936X/vhdl/rtl/gdp_clut.vhd \
                          ../GDP936X/vhdl/rtl/gdp_clut_256.vhd \
                          ../GDP936X/vhdl/rtl/FPGA/fifo_sc_hs/video_fifo.vho \
                          ../GDP936X/vhdl/rtl/gdp_video.vhd \
                          ../GDP936X/vhdl/rtl/gdp_top.vhd \
                          ../vhdl/rtl/PS2_Interface.vhd \
                          ../vhdl/rtl/PS2_Decoder.vhd \
                          ../vhdl/rtl/FPGA/ps2_fifo.vho \
                          ../vhdl/rtl/PS2Keyboard.vhd \
                          ../vhdl/rtl/PS2Mouse.vhd \
                          ../vhdl/rtl/Ser1.vhd \
                          ../vhdl/rtl/Ser_key.vhd \
                          ../vhdl/rtl/SPI_Interface.vhd \
                          ../vhdl/rtl/SPI_Vdip.vhd \
                          ../vhdl/rtl/Timer.vhd \
                          ../vhdl/rtl/GPIO_Interface.vhd \
                          ../vhdl/rtl/src/UART_pkg.vhd \
                          ../vhdl/rtl/src/TB_Receiver.vhd \
                          ../vhdl/rtl/src/TB_Sender.vhd \
                          ../vhdl/rtl/sound/wf2149ip_pkg.vhd \
                          ../vhdl/rtl/sound/wf2149ip_wave.vhd \
                          ../vhdl/rtl/sound/dac.vhd \
                          ../vhdl/rtl/sound/wf2149ip_top_soc.vhd \
                          ../vhdl/rtl/nkc_gowin_top.vhd \
                          ../vhdl/tb/nkc_gowin_tb.vhd


vsim -t ps -L gw2a -voptargs=+acc nkc_gowin_tb gw2a.GSR

onerror {resume}
add wave -group {TB} -noupdate -radix hex /*
add wave -group {TB_Sender} -noupdate -radix hex /tx/*
add wave -group {sdram} -noupdate -radix hex /dram_1/*
add wave -group {Top} -noupdate -radix hex /dut/*
add wave -group {Top} -noupdate -divider
add wave -group {Top} -noupdate -radix hex /dut/CPU/*

add wave -group {FX68k} -noupdate -radix hex /dut/CPU/fx68k/*
add wave -group {ROM} -noupdate -radix hex /dut/CPU/test_rom/*
add wave -group {Register} -noupdate -radix hex /dut/CPU/fx68k/excUnit/regs68H 
add wave -group {Register} -noupdate -radix hex /dut/CPU/fx68k/excUnit/regs68L

add wave -group {Video} -noupdate -radix hex /dut/gdp/video/*
add wave -group {video2hdmi} -noupdate -radix hex /dut/video2hdmi/*
add wave -group {CLUT} -noupdate -radix hex /dut/gdp/video/use_clut/clut_inst/*
add wave -group {Decoder} -noupdate -radix hex /dut/gdp/kernel/dec/*
add wave -group {Kernel} -noupdate -radix hex /dut/gdp/kernel/*
add wave -group {Bresenham} -noupdate -radix hex /dut/gdp/kernel/bres/*
add wave -group {Char} -noupdate -radix hex /dut/gdp/kernel/char/*
add wave -group {VRAM} -noupdate -radix hex /dut/gdp/vram/*
add wave -group {VRAM} -noupdate -divider
add wave -group {VRAM} -noupdate -radix hex /dut/gdp/vram/CPU_RD/*
add wave -group {sdram_ctrl} -noupdate -radix hex /dut/gdp/vram/sdram_inst/*
add wave -group {GDP_Top} -noupdate -radix hex /dut/gdp/*
add wave -noupdate -divider
add wave -group {Ser1} -noupdate -radix hex /dut/impl_key1/Ser_key/*
add wave -group {SPI} -noupdate -radix hex /dut/impl_spi/spi/*


TreeUpdate [SetDefaultTree]
configure wave -signalnamewidth 1
