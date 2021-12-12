vcom ../../vhdl/rtl/fdc/wf1772ip_pkg.vhd         \
     ../../vhdl/rtl/fdc/wf1772ip_digital_pll.vhd \
     ../../vhdl/rtl/fdc/wf1772ip_crc_logic.vhd   \
     ../../vhdl/rtl/fdc/wf1772ip_registers.vhd   \
     ../../vhdl/rtl/fdc/wf1772ip_transceiver.vhd \
     ../../vhdl/rtl/fdc/wf1772ip_control.vhd     \
     ../../vhdl/rtl/fdc/wf1772ip_am_detector.vhd \
     ../../vhdl/rtl/fdc/wf1772ip_top_soc.vhd     \
     ../../HxCFloppyEmulator_ipcore/rtl/vhdl/ClockGenerator.vhd \
     ../../HxCFloppyEmulator_ipcore/rtl/vhdl/ControlCore.vhd    \
     ../../HxCFloppyEmulator_ipcore/rtl/vhdl/HeadShifter.vhd    \
     ../../HxCFloppyEmulator_ipcore/rtl/vhdl/Latch4.vhd         \
     ../../HxCFloppyEmulator_ipcore/rtl/vhdl/PulseGenerator.vhd \
     ../../HxCFloppyEmulator_ipcore/rtl/vhdl/Shifter.vhd        \
     ../../HxCFloppyEmulator_ipcore/rtl/vhdl/TrackCore.vhd      \
     ../../HxCFloppyEmulator_ipcore/rtl/vhdl/HxCFloppyEmu.vhd   \
     ../../HxCFloppyEmulator_ipcore/rtl/vhdl/Generic_RAM.vhd
     
#vcom -93 -check_synthesis ../vhdl/rtl/Dffdecl-p.vhd 
vcom -93                  ../vhdl/rtl/Dffdecl-p.vhd \
                          ../vhdl/rtl/InputSync-e.vhd \
                          ../vhdl/rtl/InputSync-a.vhd \
                          ../vhdl/rtl/gdp_global_flo-p.vhd \
                          ../vhdl/rtl/gdp_bi.vhd  \
                          ../vhdl/rtl/gdp_decoder.vhd \
                          ../vhdl/rtl/gdp_bresenham.vhd \
                          ../vhdl/rtl/gdp_font.vhd \
                          ../vhdl/rtl/gdp_character.vhd \
                          ../vhdl/rtl/gdp_vram.vhd \
                          ../vhdl/rtl/gdp_kernel.vhd \
                          ../vhdl/rtl/gdp_video.vhd \
                          ../vhdl/rtl/gdp_top.vhd \
                          ../vhdl/rtl/FPGA/pll.vhd \
                          ../../vhdl/rtl/PS2_Interface.vhd \
                          ../../vhdl/rtl/PS2_Decoder.vhd \
                          ../../vhdl/rtl/FPGA/ps2_fifo.vhd \
                          ../../vhdl/rtl/PS2Keyboard.vhd \
                          ../../vhdl/rtl/PS2Mouse.vhd \
                          ../../vhdl/rtl/Ser1.vhd \
                          ../../vhdl/rtl/SPI_Interface.vhd \
                          ../../vhdl/rtl/src/UART_pkg.vhd \
                          ../../vhdl/rtl/src/TB_Receiver.vhd \
                          ../../vhdl/rtl/src/TB_Sender.vhd \
                          ../../vhdl/rtl/sound/wf2149ip_pkg.vhd \
                          ../../vhdl/rtl/sound/wf2149ip_wave.vhd \
                          ../../vhdl/rtl/sound/dac.vhd \
                          ../../vhdl/rtl/sound/wf2149ip_top_soc.vhd \
                          ../../vhdl/rtl/clk_gate-xp.vhd   \
                          ../../vhdl/rtl/flo2_top.vhd        \
                          ../vhdl/rtl/gdp_lattice_top_emu.vhd 
##                          ../vhdl/rtl/gdp_lattice_top.vhd
vcom -93  ../vhdl/tb/gdp_bitmap-p.vhd
vcom -93  ../vhdl/tb/sram.vhd
#vcom -93  ../vhdl/tb/gdp_kernel_tb.vhd
vcom -93  ../vhdl/tb/fgdp_lattice_tb.vhd
#vcom -93  ../vhdl/tb/gdp_lattice_tb.vhd


vsim -t ps gdp_lattice_tb
onerror {resume}
add wave -noupdate -divider Testbench
add wave -noupdate -radix hex /*
add wave -noupdate -divider Top
add wave -noupdate -radix hex /dut/*
add wave -noupdate -radix hex /dut/floppy/*
add wave -noupdate -divider Businterface
add wave -noupdate -radix hex /dut/bi_inst/*
add wave -noupdate -divider Businterface_flo
add wave -noupdate -radix hex /dut/floppy/bi_flo_inst/*
add wave -noupdate -divider PS2
add wave -noupdate -radix hex /dut/impl_key2/kbd/*
add wave -noupdate -divider PS2_if
add wave -noupdate -radix hex /dut/impl_key2/kbd/PS2if/*
add wave -noupdate -divider PS2_Decoder
add wave -noupdate -radix hex /dut/impl_key2/kbd/PS2dec/*
add wave -noupdate -divider Mouse
add wave -noupdate -radix hex /dut/impl_mouse/mouse/*
add wave -noupdate -radix hex /dut/impl_mouse/mouse/nkc_mouse/*
add wave -noupdate -divider Mouse_PS2_if
add wave -noupdate -radix hex /dut/impl_mouse/mouse/PS2if/*
add wave -noupdate -divider Ser1
add wave -noupdate -radix hex /dut/impl_ser1/ser/*
add wave -noupdate -divider TB-Receiver
add wave -noupdate -radix hex /rx/*
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
add wave -noupdate -divider SOUND
add wave -noupdate -radix hex /dut/impl_sound/sound_inst/*
add wave -noupdate -divider SOUND-WAVE
add wave -noupdate -radix hex /dut/impl_sound/sound_inst/i_psg_wave/*
add wave -noupdate -divider FLO2
add wave -noupdate -radix hex /gdp_lattice_tb/dut/nkc_db 
add wave -noupdate -radix hex /gdp_lattice_tb/dut/nkc_addr_i 
add wave -noupdate -radix hex /gdp_lattice_tb/dut/nkc_nrd_i 
add wave -noupdate -radix hex /gdp_lattice_tb/dut/nkc_nwr_i 
add wave -noupdate -radix hex /gdp_lattice_tb/dut/nkc_niorq_i 
add wave -noupdate -radix hex /gdp_lattice_tb/dut/driver_nen_o 
add wave -noupdate -radix hex /gdp_lattice_tb/dut/driver_dir_o 
add wave -noupdate -radix hex /dut/floppy/* 
add wave -noupdate -radix hex /dut/floppy/flo2/* 
add wave -noupdate -divider Floppy_control
add wave -noupdate -radix hex /dut/floppy/flo2/fdc/i_control/*
add wave -noupdate -divider EMULATOR
add wave -noupdate -radix hex /dut/floppy/floemu/*
add wave -noupdate -divider EMULATOR/THM
add wave -noupdate -radix hex /dut/floppy/floemu/thm/*
add wave -noupdate -divider EMULATOR/CC
add wave -noupdate -radix hex /dut/floppy/floemu/cc/*
add wave -noupdate -divider EMULATOR/CC/CG
add wave -noupdate -radix hex /dut/floppy/floemu/cc/cg/*
add wave -noupdate -divider EMULATOR/CC/hdc
add wave -noupdate -radix hex /dut/floppy/floemu/cc/hdc/*
add wave -noupdate -divider EMULATOR/PL
add wave -noupdate -radix hex /dut/floppy/floemu/cc/pl/*
TreeUpdate [SetDefaultTree]
configure wave -signalnamewidth 1
