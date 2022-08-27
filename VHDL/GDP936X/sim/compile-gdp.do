#vcom -93                  ../../HxCFloppyEmulator_ipcore/rtl/vhdl/ClockGenerator.vhd \
#                          ../../HxCFloppyEmulator_ipcore/rtl/vhdl/Generic_RAM.vhd    \
#                          ../../HxCFloppyEmulator_ipcore/rtl/vhdl/Shifter.vhd        \
#                          ../../HxCFloppyEmulator_ipcore/rtl/vhdl/PulseGenerator.vhd \
#                          ../../HxCFloppyEmulator_ipcore/rtl/vhdl/HeadShifter.vhd    \
#                          ../../HxCFloppyEmulator_ipcore/rtl/vhdl/Latch4.vhd         \
#                          ../../HxCFloppyEmulator_ipcore/rtl/vhdl/ControlCore.vhd    \
#                          ../../HxCFloppyEmulator_ipcore/rtl/vhdl/TrackCore.vhd      \
#                          ../../HxCFloppyEmulator_ipcore/rtl/vhdl/HxCFloppyEmu.vhd

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
                          ../vhdl/rtl/gdp_video.vhd \
                          ../vhdl/rtl/gdp_top.vhd \
                          ../../vhdl/rtl/PS2_Interface.vhd \
                          ../../vhdl/rtl/PS2_Decoder.vhd \
                          ../../vhdl/rtl/FPGA/ps2_fifo.vhd \
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
--                          ../vhdl/rtl/gdp_lattice_top_emu.vhd
vcom -93  ../vhdl/tb/gdp_bitmap-p.vhd
#vcom -93  ../vhdl/tb/sram.vhd
vcom -93  ../vhdl/tb/sram_256x16/package_timing.vhd
vcom -93  ../vhdl/tb/sram_256x16/package_utility.vhd
vcom -93  ../vhdl/tb/sram_256x16/mobl_256Kx16.vhd
#vcom -93  ../vhdl/tb/gdp_kernel_tb.vhd
vcom -93  ../vhdl/tb/gdp_lattice_tb_woflo.vhd


vsim -t ps gdp_lattice_tb
onerror {resume}
add wave -group {TB} -noupdate -radix hex /*
add wave -group {SRAM0} -noupdate -radix hex /vsram0/*
add wave -group {SRAM1} -noupdate -radix hex /vsram1/*
add wave -group {Top} -noupdate -radix hex /dut/*
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
add wave -group {CLUT} -noupdate -radix hex /dut/gdp/video/use_clut/clut_inst/*
add wave -group {Decoder} -noupdate -radix hex /dut/gdp/kernel/dec/*
add wave -group {Kernel} -noupdate -radix hex /dut/gdp/kernel/*
add wave -group {Bresenham} -noupdate -radix hex /dut/gdp/kernel/bres/*
add wave -group {Char} -noupdate -radix hex /dut/gdp/kernel/char/*
add wave -group {VRAM} -noupdate -radix hex /dut/gdp/vram/*
#add wave -noupdate -divider Sound
#add wave -group {Sound} -noupdate -radix hex /dut/impl_sound/sound_inst/*
#add wave -group {Sound_Wave} -noupdate -radix hex /dut/impl_sound/sound_inst/i_psg_wave/*
#add wave -noupdate -divider
#add wave -group {Timer1} -noupdate -radix hex /dut/impl_t1/t1/*

TreeUpdate [SetDefaultTree]
configure wave -signalnamewidth 1
