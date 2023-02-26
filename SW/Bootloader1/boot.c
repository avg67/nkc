
#include <ndrcomp/target.h>
#include <stdio.h>
#if USE_ENC28J60
    #include "enc28j60.h"
#endif
#include <string.h>
#include <malloc.h>
//#include <sys/ndrclock.h>
#include <time.h>
#include "stack/stack.h"
#include "stack/dhcpc.h"
#include "../../nkc_common/nkc/nkc.h"
#include "tftp.h"

#if USE_MMC
  #include "sdkarte/fat16.h"
  #include "sdkarte/sdcard.h"
#endif
extern clock_t _clock(void (*clock_fu)(void));
#define TIME (_clock(NULL))
#define HZ CLOCKS_PER_SEC

#if USE_MMC
        LOG_STATUS		logStatus;			//!< Status der Logdatei
#endif

extern volatile unsigned char gp_timer;
extern volatile clock_t _clock_value;

volatile int timer_flag=0;

void timer_func() {
  static short _prescaler = CLOCKS_PER_SEC;
  if (!--_prescaler) {
    _prescaler=  CLOCKS_PER_SEC-1;
    timer_flag=1;
  }
}

/*void _delay_ms(uint16_t delay) {
    const uint32_t end_time = _clock(NULL) + (((uint32_t)delay * 1000) / CLOCKS_PER_SEC);
    while(_clock(NULL) < end_time) {};
}*/

void _delay_ms(uint16_t delay) {
    const uint32_t end_time = _clock_value + (((uint32_t)delay * CLOCKS_PER_SEC) / 1000uL);
    //iprintf("time %d - %d",_clock_value,end_time);
    while(_clock_value < end_time) {
    };
 }

int main(int argc, char **argp, char **envp)
{

  _clock(timer_func);
  setvbuf(stdin, NULL, _IONBF, 0);
  setvbuf(stdout, NULL, _IONBF, 0);
  setvbuf(stderr, NULL, _IONBF, 0);
#if USE_ENC28J60
  SPI_CTRL=0;
#endif
  iprintf("TFTP Loader\r\n");
  iprintf("Compiliert am "__DATE__" um "__TIME__"\r\n");
  iprintf("Compiliert mit GCC Version "__VERSION__"\r\n");

  if (argc<2) {
    iprintf("Usage: 'bootldr <filename>'\r\n");
    return -1;
  }

    stack_init();

 #if USE_DHCP
    iprintf("DHCP query...\r\n");
    dhcp_init();
    if ( dhcp() == 0)
    {
//        save_ip_addresses();
    }
    else
    {
        iprintf("dhcp lease renewal failed\r\n");
        default_ip();
    }
#else
      default_ip();
#endif

  print_ip();

  //TftpRecv(unsigned long server_ip)
  static const IP_ADR server_ip = {
    .bytes[0]= 192,
    .bytes[1]= 168,
    .bytes[2]= 0,
    .bytes[3]= 166
  };
  TftpRecv(server_ip.ipl, argp[1]); //"TESTFILE.68K");
  iprintf("TFTP done\r\n");

  char ch=' ';
  while(ch!='x') {

    poll_isr();
    if (timer_flag) {
      timer_flag=0;
      eth.timer = 1;
#if USE_DHCP
      if ( dhcp_lease > 0 ) dhcp_lease--;
      if ( gp_timer   > 0 ) gp_timer--;
#endif //USE_DHCP
    }
    eth_get_data();



    if(gp_csts()) {
      ch=getchar();
    }
  }

  return 0;
}



