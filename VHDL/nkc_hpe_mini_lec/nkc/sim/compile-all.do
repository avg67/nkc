vlog -work work ../Firmware/test_rom.v \
                ../Firmware/68k-Monitor/Monitor_rom.v \
                ../vhdl/tb/flash/mx29LV640B.v

vcom -93  ../vhdl/rtl/gdp_global-p.vhd
vcom -93  ../vhdl/tb/gdp_bitmap-p.vhd
vcom -93  ../vhdl/tb/sram_256x16/package_timing.vhd
vcom -93  ../vhdl/tb/sram_256x16/package_utility.vhd
vcom -93  ../vhdl/tb/sram_256x16/mobl_256Kx16.vhd
vcom -93  ../vhdl/tb/AsyncLog.vhd
vcom -93  ../vhdl/tb/AsyncStim.vhd

vcom -2008  ../vhdl/rtl/dffdecl-p.vhd                  \
           ../vhdl/rtl/InputSync-e.vhd                 \
           ../vhdl/rtl/InputSync-a.vhd                 \
           ../CPU/TG68K_Pack.vhd                       \
           ../CPU/TG68K_ALU.vhd                        \
           ../CPU/TG68KdotC_Kernel.vhd                 \
           ../fpga/boot_rom.vhd                         \
           ../vhdl/rtl/Ser1.vhd                        \
           ../vhdl/rtl/soc_top.vhd                     \
           ../vhdl/tb/nkc_lattice_tb.vhd
#../Firmware/test_ROM.vhd                   

vsim -t ps nkc_lattice_tb
onerror {resume}
add wave -noupdate -divider Testbench
add wave -noupdate -radix hex -group {TB} /*
add wave -noupdate -radix hex -group {RAM0} /nkc_lattice_tb/ram0/*
add wave -noupdate -radix hex -group {RAM1} /nkc_lattice_tb/ram1/*
add wave -noupdate -radix hex -group {Flash0} /nkc_lattice_tb/flash0/*
add wave -noupdate -radix hex -group {Flash0} \
{sim:/nkc_lattice_tb/flash0/BYTE_B } \
{sim:/nkc_lattice_tb/flash0/Q_reg } \
{sim:/nkc_lattice_tb/flash0/latch_A } \
{sim:/nkc_lattice_tb/flash0/latch_Q } \
{sim:/nkc_lattice_tb/flash0/pg_latch_Q } \
{sim:/nkc_lattice_tb/flash0/er_latch_Q } \
{sim:/nkc_lattice_tb/flash0/state } \
{sim:/nkc_lattice_tb/flash0/during_cfi_mode } \
{sim:/nkc_lattice_tb/flash0/during_read_ID } \
{sim:/nkc_lattice_tb/flash0/during_program } \
{sim:/nkc_lattice_tb/flash0/during_erase } \
{sim:/nkc_lattice_tb/flash0/during_susp_read } \
{sim:/nkc_lattice_tb/flash0/suspend_flag } \
{sim:/nkc_lattice_tb/flash0/resume_flag } \
{sim:/nkc_lattice_tb/flash0/pgm_clk } \
{sim:/nkc_lattice_tb/flash0/ers_clk } \
{sim:/nkc_lattice_tb/flash0/hw_reset_b } \
{sim:/nkc_lattice_tb/flash0/d_ce_b } \
{sim:/nkc_lattice_tb/flash0/d_oe_b } \
{sim:/nkc_lattice_tb/flash0/byte_b } \
{sim:/nkc_lattice_tb/flash0/program } \
{sim:/nkc_lattice_tb/flash0/o_dis } \
{sim:/nkc_lattice_tb/flash0/cmd_bus } \
{sim:/nkc_lattice_tb/flash0/start_a } \
{sim:/nkc_lattice_tb/flash0/end_a } \
{sim:/nkc_lattice_tb/flash0/i } 
add wave -noupdate -radix hex -group {Flash1} /nkc_lattice_tb/flash1/*
add wave -noupdate -divider Dut
add wave -noupdate -radix hex -group {Dut} /dut/*
add wave -noupdate -radix hex -group {ROM} /dut/rom_inst/*
add wave -radix hex -group {TG68}    /dut/mytg68/*
add wave -radix hex -group {TG68_ALU}    /dut/mytg68/alu/*
add wave -radix hex -group {Ser1}    /dut/impl_ser1/ser/*
#add wave -noupdate -radix hex /dut/*
#add wave -noupdate -divider Z80
#add wave -noupdate -radix hex /dut/z80/*
#add wave -noupdate -format Logic -radix hexadecimal /dut/z80/u0/*
#add wave -noupdate -divider {Z80_ALU}
#add wave -noupdate -format Logic -radix hexadecimal /dut/z80/u0/alu/*
#add wave -noupdate -divider {Z80_Register}
#add wave -noupdate -format Logic -radix hexadecimal /dut/z80/u0/regs/*
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

TreeUpdate [SetDefaultTree]
configure wave -signalnamewidth 1
