#include <stdio.h>
#include <sys/ndrclock.h>
#include <sys/file.h>
#include <sys/path.h>
#include <time.h>
#include <stdint.h>
#include "../../nkc_common/nkc/nkc.h"

main(int argc, char **argp, char **envp)
{
	char ch[40];
	time_t now;

	puts("Hello World\n\r");
	iprintf("Argumente: %d %s\n\r",argc,argp[0]);
	for(int i=1;i<argc;i++) {
		iprintf("Arg %d: %s\n\r",i,argp[i]);
	}

//	printf("Environment: %s\n\r",*envp);
	puts("Return - weiter\n\r");
	gets(ch);
	
  now = _gettime();
 iprintf("Current date and Time: %s\n\r",asctime(localtime(&now)));

 const uint32_t jd_vers = jd_getversi();
 char bfr[8]  __attribute__ ((aligned (4))) = {0};
 *((uint32_t* )bfr) = jd_vers;
 iprintf("Jados-Version: %s\r\n",bfr);
 uint8_t buf[4096];
 uint8_t result = jd_directory((void*)buf, (void*)"A:*.*", 0, 1, sizeof(buf));
 iprintf("Result: 0x%x\r\n%s",result,buf);
}
	