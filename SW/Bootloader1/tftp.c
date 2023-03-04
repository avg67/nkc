#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <assert.h>
#include "stack/stack.h"
#include "tftp.h"
#include "../../nkc_common/nkc/nkc.h"


//#define TFTP_DEBUG iprintf
#define TFTP_DEBUG(...)

static bool data_ready = false;
static unsigned short data_len =0;

static inline uint16_t min(const uint16_t a, const uint16_t b) {
    return (a<=b)?a:b;
}

//Wertet message vom TFTP Server aus
static void tftp_get (void)
{
  //struct TFTPHDR  *msg;
  struct IP_Header *ip;
  //unsigned char *p;
//  unsigned int i;
  ip  = (struct IP_Header *)&eth_buffer[IP_OFFSET];
  //struct UDP_Header *udp = (struct UDP_Header *)&eth_buffer[UDP_OFFSET];
  //iprintf("tftp_get called %u\r\n",ip->IP_Pktlen-sizeof(struct IP_Header)-sizeof(struct UDP_Header));
  if ( htons(ip->IP_Pktlen) > MTU_SIZE )
  {
    TFTP_DEBUG("TFTP too big, discarded\r\n");
    return;
  }


  data_ready = true;
  data_len = ip->IP_Pktlen-sizeof(struct IP_Header)-sizeof(struct UDP_Header);

}

//Sendet TFTP messages
static void tftp_message (unsigned long server_ip, unsigned short request, const char * name, const char * mode)
{
    TFTPHDR *msg;

    for (unsigned int i=0; i < sizeof (TFTPHDR); i++) //clear eth_buffer to 0
    {
        eth_buffer[UDP_DATA_START+i] = 0u;
    }

    msg = (TFTPHDR *)&eth_buffer[UDP_DATA_START];
    msg->th_opcode = request;
    char * cp = msg->th_u.tu_stuff;
    while(*name){
        *cp++ = *name++;
    }
    *cp++ = 0;
    while(*mode) {
        *cp++ = *mode++;
    }
	*cp++ = 0;
    create_new_udp_packet((u_int)cp - (u_int)msg,TFTP_SERVER_PORT, TFTP_CLIENT_PORT,server_ip);
}

static inline void tftp_ack (unsigned long server_ip, unsigned short tport, unsigned short block_nr)
{
    TFTPHDR *msg;

    for (unsigned int i=0; i < sizeof (TFTPHDR); i++) //clear eth_buffer to 0
    {
        eth_buffer[UDP_DATA_START+i] = 0u;
    }

    msg = (TFTPHDR *)&eth_buffer[UDP_DATA_START];
    msg->th_opcode = htons(TFTP_ACK);
    msg->th_u.tu_block = htons(block_nr);
    create_new_udp_packet(4, TFTP_SERVER_PORT, tport, server_ip);
}

/*!
 * \brief Download a file from a TFTP server and burn it into the flash ROM.
 *
 * \return 0 on success, -1 otherwise.
 */
bool TftpRecv(const unsigned long server_ip, const char* const p_file_name, const bool dry_run)
{
    unsigned short tport = TFTP_CLIENT_PORT;
    unsigned short block = 0u;


    if (dry_run) {
        iprintf(" with a dry-run!");
    }
    iprintf("\r\n");

    // Buffer for one sector
    char* block_buf = malloc(JD_BLOCKSIZE);
    uint16_t block_size = 0u;
    bool done = false;
    bool error = false;
    uint32_t total_size = 0u;

    //Port in Anwendungstabelle eintragen für eingehende ´TFTP Daten!
    add_udp_app (TFTP_SERVER_PORT, (void(*)(unsigned char))tftp_get);

    jdfcb_t myfcb={0u};
    uint8_t result = 0u;
    if (!dry_run) {
        result = jd_fillfcb(&myfcb,p_file_name);
        if(result!=0) {
            iprintf("Error %u creating FCB!\r\n", result);
            return -1;
        }
        result = jd_create(&myfcb);
        if(result!=0) {
            iprintf("Error %u creating File!\r\n", result);
            return -1;
        }
    }

    const clock_t start_time = _clock(NULL);
    /*
     * Prepare the transmit buffer for a file request.
     */
    //slen = MakeRequest(&sframe.u.tftp, TFTP_RRQ, bootfile, "octet");
    //tftp_message(server_ip, TFTP_RRQ, bootfile, "octet");
    tftp_message(server_ip, TFTP_RRQ, (const char *)p_file_name, (const char *)"octet");

    /*
     * Loop until we receive a packet with less than 512 bytes of data.
     */
    do {
        const clock_t timeout =  _clock(NULL) + ((time_t)5000u * CLOCKS_PER_SEC)/1000u;
        do {
            poll_isr();
            eth_get_data();
        }while(!data_ready && _clock(NULL)<timeout);
        if (!data_ready) {
            iprintf("Timeout!\r\n");
            return false;
        }
        /*
         * Send file request or acknowledge and receive
         * a data block.
         */
        if (data_ready) {
            data_ready = false;
            if(data_len < 516) {
                done = true;
            }
            TFTPHDR  *msg = (TFTPHDR *)&eth_buffer[UDP_DATA_START];

            if(htons(msg->th_opcode) == TFTP_ERROR) {
                iprintf("TFTP-Error '%u': %s\r\n",msg->th_u.tu_code,msg->th_data);
                error=true;
                break;
            }else if(htons(msg->th_opcode) != TFTP_DATA) {
                //iprintf("No data-block - ignore\r\n");
                //return -1;
                gp_co('i');
                continue;
            }


            /*
            * If this was the first block we received, prepare
            * the send buffer for sending ACKs.
            */
            struct UDP_Header *udp = (struct UDP_Header *)&eth_buffer[UDP_OFFSET];
            if(block == 0) {
                tport = udp->udp_SrcPort;
            }
            //iprintf("Received %u Port %u,%u\r\n", msg->th_u.tu_block, udp->udp_SrcPort, udp->udp_Hdrlen);
            /*
            * If this block is out of sequence, we ignore it.
            * However, if we missed the first block, return
            * with an error.
            */
            if(htons(msg->th_u.tu_block) != (block + 1u)) {
                if(block == 0)
                    return -1;
                continue;
            }
            bool store = false;
            if(data_len > 4) {
                const uint16_t rx_data_len = data_len - 4u;
                total_size += (uint32_t)rx_data_len;
                TFTP_DEBUG("TFTP-RX %d: %u Bytes ", block, (unsigned int)(rx_data_len));
                memcpy(&block_buf[block_size],msg->th_data, rx_data_len);
                block_size+=rx_data_len;
                store = ((block_size>=JD_BLOCKSIZE) || done);
            }
            // ack the block to TFTP Server
            block++;
            msg->th_u.tu_block = htons(block);
            tftp_ack(server_ip, tport, block);
            // In the meanwhile write block to disk
            if (store) {
                if (!dry_run) {
                    result = jd_blockwrite(&myfcb, block_buf, 1u);
                }
                block_size -= min(JD_BLOCKSIZE,block_size);
                TFTP_DEBUG("disk write: 0x%X remaining: %u\r\n", result, block_size);
                gp_co('.');
                assert(block_size==0u);
            }else{
                TFTP_DEBUG("Append %u\r\n",block_size);
            }
        }else{
            done=false;
        }
    } while(!done);
    if (!error) {
        const clock_t end_time = _clock(NULL);
        if (!dry_run) {
            jd_close(&myfcb);
        }
        free(block_buf);
        const uint32_t duration = (uint32_t)(1000u*(end_time - start_time)/CLOCKS_PER_SEC);
        iprintf("\r\nDuration for %u Bytes: %u ms with %u kB/s\r\n",(unsigned int)total_size, (unsigned int)duration,(unsigned int)((total_size/1024u)*1000u/duration));
    }

    return !error;
}


