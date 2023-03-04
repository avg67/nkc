
#include <ndrcomp/target.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <malloc.h>
//#include <sys/ndrclock.h>
#include <time.h>

#include "stack/stack.h"
#include "stack/dhcpc.h"
#include "../../nkc_common/nkc/nkc.h"
#include "tftp.h"
#if USE_ENC28J60
    #include "enc28j60.h"
    #include "spi.h"
#endif

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
static const char* p_file_name = NULL;
static const char* p_server_ip_string = NULL;
static bool dry_run = false;

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

void _delay_ms(const uint16_t delay) {
    const uint32_t end_time = _clock_value + (((uint32_t)delay * CLOCKS_PER_SEC) / 1000uL);
    //iprintf("time %d - %d",_clock_value,end_time);
    while(_clock_value < end_time) {
    };
}

static inline const char* parse_string(const int argc, char **argp, const uint16_t index)
{
    const char* p_string = NULL;
    if (argc>(index+1u)) {
        p_string = argp[index + 1u];
    }
    return p_string;
}

uint32_t parse_ip_string(const char* const ip_str)
{
    uint8_t s_idx=0;
    uint8_t part=0;
    char bfr[8]= {0};
    const size_t len = strlen(ip_str);

    IP_ADR ip;
    ip.ipl=0u;
    while(s_idx<len) {
        // 1. search for '.' or '\0'
        uint8_t d_idx=0u;
        for(uint16_t i=0u;i<10u;i++) {
            const char ch=ip_str[s_idx++];
            if(!ch || ch=='.') {
                bfr[d_idx]='\0';
                break;
            }
            bfr[d_idx]=ch;
            d_idx++;
        }
        // 2. convert string in bfr into decimal value
        const int number = atoi(bfr);
        ip.bytes[part++]=(unsigned char)number;
    }

    return ip.ipl;
}

static bool parse_args(const int argc, char **argp)
{
    uint16_t i = 1u;
    // 5 parameters max possible in Jados
    while(i<argc)
    {
        //iprintf("arg: %u: %s\r\n",i, argp[i]);
        if (argp[i][0] == '-'){
            switch(argp[i][1]) {
                case 'F':
                    /*if (argc>(i+1u)) {
                        i++;
                        p_file_name = argp[i];
                    }*/
                    p_file_name = parse_string(argc, argp, i);
                    break;
                case 'D':
                    dry_run = true;
                    break;
                case 'S':
                    p_server_ip_string = parse_string(argc, argp, i);
                    break;
            }
        }
        i++;
    }
    return (p_file_name!=NULL);
}

static void usage(void) {
    iprintf("Usage: 'bootldr -f <filename> [-d]'\r\n");
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

  if ((argc<3) || !(parse_args(argc, argp))) {
    usage();
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

  IP_ADR server_ip = {
    .bytes[0]= 192,
    .bytes[1]= 168,
    .bytes[2]= 0,
    .bytes[3]= 166
  };
    /*{
        unsigned int arr[4]={0u};
        if(p_server_ip_string!=NULL) {
            if(siscanf(p_server_ip_string, "%u.%u.%u.%u", &arr[0],&arr[1],&arr[2],&arr[3])==4u){
                server_ip.bytes[0]=(unsigned char)arr[0];
                server_ip.bytes[1]=(unsigned char)arr[1];
                server_ip.bytes[2]=(unsigned char)arr[2];
                server_ip.bytes[3]=(unsigned char)arr[3];
            }
        }
    }*/
  if(p_server_ip_string!=NULL) {
    server_ip.ipl = parse_ip_string(p_server_ip_string);
  }
  iprintf("TFTP1 %s from %u.%u.%u.%u", p_file_name,server_ip.bytes[0],server_ip.bytes[1],server_ip.bytes[2],server_ip.bytes[3] );
  if(TftpRecv(server_ip.ipl, p_file_name, dry_run)) {
    iprintf("TFTP done\r\n");
  }

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



