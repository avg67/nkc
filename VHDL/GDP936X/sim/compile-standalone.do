vcom -93 -check_synthesis ../vhdl/rtl/Dffdecl-p.vhd \
                          ../vhdl/rtl/gdp_global-p.vhd \
                          ../vhdl/rtl/gdp_decoder.vhd \
                          ../vhdl/rtl/gdp_bresenham.vhd \
                          ../vhdl/rtl/gdp_font.vhd \
                          ../vhdl/rtl/gdp_character.vhd \
                          ../vhdl/rtl/gdp_vram.vhd \
                          ../vhdl/rtl/gdp_kernel.vhd \
                          ../vhdl/rtl/gdp_video.vhd \
                          ../vhdl/rtl/gdp_top.vhd \
                          ../vhdl/rtl/gdp_standalone_top.vhd
vcom -93  ../vhdl/tb/gdp_bitmap-p.vhd
vcom -93  ../vhdl/tb/sram.vhd
vcom -93  ../vhdl/tb/gdp_kernel_tb.vhd
#vcom -93  ../vhdl/tb/gdp_standalone_tb.vhd


#vsim -t ps gdp_standallone_tb
vsim -t ps gdp_kernel_tb
onerror {resume}
#add wave -noupdate -divider Testbench
#add wave -noupdate -radix hex /*
#add wave -noupdate -divider FSM
#add wave -noupdate -radix hex /dut/*
#add wave -noupdate -divider Video
#add wave -noupdate -radix hex /dut/gdp/video/*
#add wave -noupdate -divider Decoder
#add wave -noupdate -radix hex /dut/gdp/kernel/dec/*
#add wave -noupdate -divider Kernel
#add wave -noupdate -radix hex /dut/gdp/kernel/*
#add wave -noupdate -divider Bresenham
#add wave -noupdate -radix hex /dut/gdp/kernel/bres/*
#add wave -noupdate -divider Character
#add wave -noupdate -radix hex /dut/gdp/kernel/char/*
#add wave -noupdate -divider VRAM
#add wave -noupdate -radix hex /dut/gdp/vram/*

add wave -noupdate -divider Testbench
add wave -noupdate -radix hex /*
add wave -noupdate -divider GDP_TOP
add wave -noupdate -radix hex /dut/*
add wave -noupdate -divider Video
add wave -noupdate -radix hex /dut/video/*
add wave -noupdate -divider Decoder
add wave -noupdate -radix hex /dut/kernel/dec/*
add wave -noupdate -divider Kernel
add wave -noupdate -radix hex /dut/kernel/*
add wave -noupdate -divider Bresenham
add wave -noupdate -radix hex /dut/kernel/bres/*
add wave -noupdate -divider Character
add wave -noupdate -radix hex /dut/kernel/char/*
add wave -noupdate -divider VRAM
add wave -noupdate -radix hex /dut/vram/*

TreeUpdate [SetDefaultTree]
configure wave -signalnamewidth 1











