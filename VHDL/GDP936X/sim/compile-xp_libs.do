set xp_src_dir "C:/lscc/diamond/3.12/cae_library/simulation/vhdl/xp/src/"

vlib xp
vcom -work xp $xp_src_dir/ORCA_CMB.vhd
vcom -work xp $xp_src_dir/ORCACOMP.vhd
vcom -work xp $xp_src_dir/ORCA_SEQ.vhd
vcom -work xp $xp_src_dir/ORCA_MISC.vhd
vcom -work xp $xp_src_dir/ORCA_MEM.vhd
vcom -work xp $xp_src_dir/ORCA_LUT.vhd
vcom -work xp $xp_src_dir/ORCA_IO.vhd
vcom -work xp $xp_src_dir/ORCA_CNT.vhd
