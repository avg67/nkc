@srec_cat gp710r5.S68 -Output gp710r5.bin -Binary 
@python hex2mem.py gp710r5.bin  -w 4 gp710r5.v
@move /Y gp710r5.v ../gp710r5_tg68.v
@copy /Y ..\gp710r5_tg68.v C:\working\_Tang_nano\gdp_fpga\Firmware\
@python bin_to_mem_Version2.py  -w 2 --big-endian gp710r5.bin ..\gp710r5_tg68.mem
@copy /Y ..\gp710r5_tg68.mem C:\working\_Tang_nano\gdp_fpga\Firmware\
@Pause

