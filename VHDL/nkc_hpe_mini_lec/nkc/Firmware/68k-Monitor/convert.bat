..\..\tools\srec_cat Monitor.S68 -crop 0x800000 0x810000 -Offset -0x800000 -Output Monitor.bin -Binary 

..\..\tools\srec_cat Monitor.S68 -crop 0x800000 0x810000 -Offset -0x800000 -Output Monitor.mem -Lattice_Memory_Initialization_Format 16

python ..\..\tools\hex2mem\hex2mem.py Monitor.bin Monitor_rom.v
@rem cd ..\..\fpga
@rem C:\lscc\diamond\3.12\ispfpga\bin\nt64\scuba.exe -w -n Boot_rom -lang vhdl -synth synplify -bus_exp 7 -bb -arch ep5g00p -type bram -wp 00 -rp 1100 -addr_width 10 -data_width 16 -num_rows 1024 -resetmode SYNC -memfile c:/working/_nkc_git_avg/nkc_hpe_mini_lec/nkc/firmware/68k-monitor/monitor.mem -memformat hex -cascade -1 