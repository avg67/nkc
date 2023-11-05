
#include <ndrcomp/target.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <malloc.h>
//#include <sys/ndrclock.h>
#include <time.h>

#include "net.h"
#include "netutil.h"
#include "dhcp.h"
#include "cs8900_eth.h"
#include "../../nkc_common/nkc/nkc.h"
#include "tftp.h"

extern clock_t _clock(void (*clock_fu)(void));
#define TIME (_clock(NULL))
#define HZ CLOCKS_PER_SEC

static const char* p_tx_file_name = NULL;
static const char* p_rx_file_name = NULL;
static const char* p_server_ip_string = NULL;
static bool dry_run = false;
static bool host_mode = false;


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
                case 'T':
                    // Transmit file to TFTP-Server
                    p_tx_file_name = parse_string(argc, argp, i);
                    //i++;
                    break;
                case 'R':
                    p_rx_file_name = parse_string(argc, argp, i);
                    //i++;
                    break;
                case 'D':
                    // do not write anything to Jados disk
                    dry_run = true;
                    break;
                case 'S':
                    // specify Server IP
                    p_server_ip_string = parse_string(argc, argp, i);
                    break;
                case 'H':
                    host_mode = true;
                    break;
            }
        }
        i++;
    }
    return (host_mode || (p_rx_file_name!=NULL) || (p_tx_file_name!=NULL));
}

static void usage(void) {
    iprintf("Usage client-mode: 'tftp -[r,t] <filename> [-s <server-ip>] [-d]'\r\n");
    iprintf("Usage server-mode: 'tftp -h [-d]'\r\n");
}

int main(int argc, char **argp, char **envp)
{

    setvbuf(stdin, NULL, _IONBF, 0);
    setvbuf(stdout, NULL, _IONBF, 0);
    setvbuf(stderr, NULL, _IONBF, 0);

    iprintf("TFTP Loader\r\n");
    //iprintf("Compiliert am "__DATE__" um "__TIME__"\r\n");
    //iprintf("Compiliert mit GCC Version "__VERSION__"\r\n");

    if (!(parse_args(argc, argp))) {
        usage();
        return -1;
    }

    if(Init_net()) {
        puts("<NET FAILURE>");
        return -1;
    }


    DHCP_SetIP();

    iprintf("IP:  %u.%u.%u.%u\r\n",my_ip.bytes[0],my_ip.bytes[1],my_ip.bytes[2],my_ip.bytes[3]);

    IP_ADR server_ip = {
        .bytes[0]= 192,
        .bytes[1]= 168,
        .bytes[2]= 0,
        .bytes[3]= 166
    };

    if(p_server_ip_string!=NULL) {
        server_ip.ipl = parse_ip_string(p_server_ip_string);
    }
    bool success = false;
    if(host_mode) {
        iprintf("Starting TFTP-Server\npress 'x' to abort\n");
        success = TftpServer(dry_run);
    }else if (p_tx_file_name!=NULL) {
        iprintf("TFTP1 %s from %u.%u.%u.%u", p_tx_file_name,server_ip.bytes[0],server_ip.bytes[1],server_ip.bytes[2],server_ip.bytes[3] );
        success = tftp_transm_int(server_ip.ipl,TFTP_CLIENT_PORT, TFTP_SERVER_PORT, p_tx_file_name, false);
    }else if (p_rx_file_name!=NULL) {
        iprintf("TFTP1 %s to %u.%u.%u.%u", p_rx_file_name,server_ip.bytes[0],server_ip.bytes[1],server_ip.bytes[2],server_ip.bytes[3] );
        //success = TftpRecv(server_ip.ipl, p_rx_file_name, dry_run);
        success = tftp_recv_int(server_ip.ipl, TFTP_CLIENT_PORT, TFTP_SERVER_PORT, p_rx_file_name, false, dry_run);
    }
    if (success) {
        iprintf("\nTFTP done\r\n");
    }


  /*char ch=' ';
  while(ch!='x') {

    const uint16_t res=poll_net();



    if(gp_csts()) {
      ch=getchar();
    }
  }*/

  return 0;
}



