set z80dir "C:/HGB_Work/ARCADE_Cores/t80"

vcom ${z80dir}/rtl/vhdl/T80_Pack.vhd  \
     ${z80dir}/rtl/vhdl/T80_MCode.vhd \
     ${z80dir}/rtl/vhdl/T80_ALU.vhd   \
     ${z80dir}/rtl/vhdl/T80_Reg.vhd   \
     ${z80dir}/rtl/vhdl/T80.vhd       \
     ${z80dir}/rtl/vhdl/T80se.vhd

vcom ../../vhdl/rtl/fdc/wf1772ip_pkg.vhd         \
     ../../vhdl/rtl/fdc/wf1772ip_digital_pll.vhd \
     ../../vhdl/rtl/fdc/wf1772ip_crc_logic.vhd   \
     ../../vhdl/rtl/fdc/wf1772ip_registers.vhd   \
     ../../vhdl/rtl/fdc/wf1772ip_transceiver.vhd \
     ../../vhdl/rtl/fdc/wf1772ip_control.vhd     \
     ../../vhdl/rtl/fdc/wf1772ip_am_detector.vhd \
     ../../vhdl/rtl/fdc/wf1772ip_top_soc.vhd
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
                          ../../vhdl/rtl/flomon_sim.vhd \
                          ../../vhdl/rtl/gru_sim.vhd \
                          ../../vhdl/rtl/ram.vhd \
                          ../../vhdl/rtl/src/InputSync-e.vhd \
                          ../../vhdl/rtl/src/InputSync-a.vhd \
                          ../../vhdl/rtl/src/ControlPath.vhd \
                          ../../vhdl/rtl/src/DataPathRx.vhd  \
                          ../../vhdl/rtl/src/BaudRateRX.vhd  \
                          ../../vhdl/rtl/src/Receiver.vhd    \
                          ../../vhdl/rtl/clk_gate-fpga.vhd   \
                          ../../vhdl/rtl/flo2_top.vhd        \
                          ../../vhdl/rtl/nkc_top.vhd
vcom -93  ../vhdl/tb/gdp_bitmap-p.vhd
vcom -93  ../vhdl/tb/sram.vhd
vcom -93  ../../vhdl/tb/nkc_tb.vhd
#vcom -93  ../vhdl/tb/gdp_kernel_tb.vhd


#vsim -t ps gdp_kernel_tb
vsim -t ps nkc_tb
onerror {resume}
add wave -noupdate -divider Testbench
add wave -noupdate -radix hex /*
add wave -noupdate -divider Top
add wave -noupdate -radix hex /dut/*
add wave -noupdate -divider Z80
add wave -noupdate -radix hex /dut/z80/*
add wave -noupdate -format Logic -radix hexadecimal /dut/z80/u0/*
add wave -noupdate -divider {Z80_ALU}
add wave -noupdate -format Logic -radix hexadecimal /dut/z80/u0/alu/*
add wave -noupdate -divider {Z80_Register}
add wave -noupdate -format Logic -radix hexadecimal /dut/z80/u0/regs/*
add wave -noupdate -divider Video
add wave -noupdate -radix hex /dut/gdp/video/*
add wave -noupdate -divider Decoder
add wave -noupdate -radix hex /dut/gdp/kernel/dec/*
add wave -noupdate -divider Kernel
add wave -noupdate -radix hex /dut/gdp/kernel/*
add wave -noupdate -divider Bresenham
add wave -noupdate -radix hex /dut/gdp/kernel/bres/*
add wave -noupdate -divider Character
add wave -noupdate -radix hex /dut/gdp/kernel/char/*
add wave -noupdate -divider VRAM
add wave -noupdate -radix hex /dut/gdp/vram/*

TreeUpdate [SetDefaultTree]
configure wave -signalnamewidth 1
