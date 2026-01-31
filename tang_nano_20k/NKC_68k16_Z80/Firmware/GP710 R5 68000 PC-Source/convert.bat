@srec_cat gp710r5.S68 -Output gp710r5.bin -Binary 
@python hex2mem.py gp710r5.bin  -w 4 gp710r5.v
@move /Y gp710r5.v ../gp710r5_tg68.v
