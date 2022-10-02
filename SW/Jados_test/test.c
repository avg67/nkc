#include <stdio.h>
#include <sys/ndrclock.h>
#include <sys/file.h>
#include <sys/path.h>
#include <time.h>
#include <stdlib.h>
#include <stdint.h>
#include "../../nkc_common/nkc/nkc.h"

int main(int argc, char **argp, char **envp)
{
	char ch[40];
	time_t now;

	puts("Hello World\n\r");
	iprintf("Argumente: %d %s\n\r",argc,argp[0]);
	for(int i=0;i<argc;i++) {
		iprintf("Arg %d: %s\n\r",i,argp[i]);
	}

//	printf("Environment: %s\n\r",*envp);

  now = _gettime();
 iprintf("Current date and Time: %s\n\r",asctime(localtime(&now)));
 {
 	const uint32_t jd_vers = jd_getversi();
 	char bfr[8]  __attribute__ ((aligned (4))) = {0};
 	*((uint32_t* )bfr) = jd_vers;
 	iprintf("Jados-Version: %s\r\n",bfr);
 }
 
  puts("Return - weiter\n\r");
  gets(ch); 
 // Change to drive A
 jd_set_drive(DISK_A);
 {
 	uint8_t buf[4096];
 	uint8_t result = jd_directory((void*)buf, (void*)"*.*", 0u, 4u, sizeof(buf));
 	iprintf("Result: 0x%x\r\n%s",result,buf);
 }
 puts("Bitte Dateinamen eingeben");
 gets(ch); 
 puts("\r\n");
 {
	jdfcb_t myfcb={0};
	uint8_t result = jd_fillfcb(&myfcb,ch);
	iprintf("FillFcb-Result: 0x%X filename:%s\r\n",result, myfcb.filename);
	
	jdfile_info_t info __attribute__ ((aligned (4))) = {0};
	char * p_buf = NULL;
	if (result ==0) {
		result = jd_fileinfo(&myfcb, &info);

		iprintf("Fileinfo-Result: 0x%X length: %u date:0x%lX, att:0x%X\r\n",result, info.length, info.date, info.attribute);
		p_buf = malloc(info.length);
		p_buf[0]='\0';
	}
	
	if (p_buf!=NULL) {
		result = jd_fileload(&myfcb, p_buf);
		//p_buf[100]=0;
		iprintf("Fileread-Result: 0x%X\r\n%s\r\n",result, p_buf);
	}

 }

 

}
	