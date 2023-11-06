#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <assert.h>
#include "net.h"
#include "tftp.h"
#include <sys/ndrclock.h>
#include "../../nkc_common/nkc/nkc.h"
#include "crc32.h"


//#define TFTP_DEBUG iprintf
#define TFTP_DEBUG(...)

#define RX_BUF_SIZE (JD_BLOCKSIZE*32u)   // RX-Buffer for 32 Blocks

//#define USE_CRC



/*static inline uint16_t min(const uint16_t a, const uint16_t b) {
    return (a<=b)?a:b;
}*/

//extern const volatile clock_t _clock_value;

static bool fn_valid(const char* const p_filename)
{
    bool valid=false;
    const char* p_name = p_filename;
    const char* const p_colon = strchr(p_filename,':');
    // check if filename starts with an drive letter (e.g. A:xy.ext)
    if(p_colon && (p_filename[1]==':')) {
        p_name = &p_filename[2];
    }
    // filename neet to follow 8.3 rule
    const size_t len = strlen(p_name);
    if (len<=12u) {
        const char* const p_dot = strchr(p_name,'.');
        if (p_dot) {
            if (strlen(&p_dot[1])<=3) {
                const uint16_t n = (uint16_t)(p_dot - p_name);
                if(n<=8) {
                    valid=true;
                }
            }
        }else if(len<=8){
            // filename without extension
            valid=true;
        }
    }
    return valid;
}

//Sendet TFTP messages
static void tftp_message (unsigned short request, const char * name, const char * mode, char* tx_buf)
{
    TFTPHDR *msg = (TFTPHDR *)tx_buf;

    memset(msg,0,sizeof (TFTPHDR));

    msg->th_opcode = request;
    //strcpy(msg->th_u.tu_stuff,name);
    register char * cp = msg->th_u.tu_stuff;
    while(*name){
        *cp++ = *name++;
    }
    *cp++ = 0;
    while(*mode) {
        *cp++ = *mode++;
    }
	*cp++ = 0;
    const uint16_t len = (uint16_t)(cp - tx_buf);
    send_socket_udp(UDP_SOCK,(const uchar* const)tx_buf,len);
}


static inline void tftp_ack (unsigned short block_nr, char* tx_buf)
{
    TFTPHDR *msg = (TFTPHDR *)tx_buf;

    //memset(msg,0,sizeof (TFTPHDR));

    msg->th_opcode = TFTP_ACK;
    msg->th_u.tu_block = block_nr;
    send_socket_udp(UDP_SOCK,(const uchar * const)tx_buf,4u);
}

static inline void tftp_error (const uint16_t tu_code, const char* const err_msg, char* const tx_buf)
{
    TFTPHDR *msg = (TFTPHDR *)tx_buf;

    //memset(msg,0,sizeof (TFTPHDR));

    msg->th_opcode = TFTP_ERROR;
    msg->th_u.tu_code = tu_code;
    const uint16_t len = strlen(err_msg);
    strcpy(msg->th_data, err_msg);
    send_socket_udp(UDP_SOCK,(const uchar * const)tx_buf,len+1u+4u);
}


static inline void tftp_data (unsigned short block_nr, const char* const p_buf, const size_t len, char* tx_buf)
{
    TFTPHDR *msg = (TFTPHDR *)tx_buf;

    //memset(&eth_buffer[UDP_DATA_START],0u,sizeof(TFTPHDR));

    msg->th_opcode     = TFTP_DATA;
    msg->th_u.tu_block = block_nr;
    memcpy(msg->th_data,p_buf,len);
    send_socket_udp(UDP_SOCK, (const uchar * const)tx_buf, 4+len);
}

bool tftp_recv_int(const unsigned long remote_ip, const uint16_t remote_port, const uint16_t local_port, const char* const p_file_name, const bool server, const bool dry_run)
{
    unsigned short block = 0u;

    if (dry_run) {
        iprintf(" with a dry-run!");
    }
    iprintf("\r\n");

    // Buffer for one sector

    bool done = false;
    bool error = false;
    uint32_t total_size = 0u;

    bool fnvalid = fn_valid(p_file_name);
#ifdef USE_CRC
    uint32_t crc32=0xffffffffu;
    uint32_t crc32_table[256]={0u};
    if (!dry_run) {
        gen_crc32_lookup_table(crc32_table, 0x04C11DB7u,32u);
    }
#endif

    jdfcb_t myfcb={0u};
    uint8_t result = 0u;
    if (!dry_run && fnvalid) {
        result = jd_fillfcb(&myfcb,p_file_name);
        if(result!=0) {
            iprintf("Error %u creating FCB!\r\n", result);
            fnvalid = false;
        }
        result = jd_create(&myfcb);
        if(result!=0) {
            iprintf("Error %u creating File!\r\n", result);
            fnvalid = false;
        }
    }

    //Port in Anwendungstabelle eintragen für eingehende TFTP Daten!
    SOCKET_SETUP(UDP_SOCK, SOCKET_UDP, local_port, FLAG_PASSIVE_OPEN);
    if(open_socket_udp(UDP_SOCK, remote_ip, remote_port)!=0) {
        puts("Error opening UDP Socket");
        return 0;
    }

    TX_BUFFER * const pbuf = allocate_tx_buf();
    const time_t start_time = _gettime();
    const clock_t start_clock =  _times(NULL);

    if (!fnvalid) {
        tftp_error(16u,"Invalid file name",pbuf->buffer);
        puts("Invalid file name!");
    }else{

        char* block_buf = malloc(RX_BUF_SIZE);

        if(server) {
            tftp_ack(block, pbuf->buffer);
        }else{
            tftp_message(TFTP_RRQ, (const char *)p_file_name, (const char *)"octet", pbuf->buffer);
        }

        /*
        * Loop until we receive a packet with less than 512 bytes of data.
        */
        uint16_t block_size = 0u;
        do {
            const clock_t timeout =  _times(NULL) + ((clock_t)(5u * CLOCKS_PER_SEC));
            bool data_ready = false;

            do {
                const uint16_t res=poll_net();
                if((res & 0xff00)==EVENT_UDP_DATARECEIVED) {
                    //iprintf("Event: 0x%04X %u\n",res,rcv_len);
                    data_ready=true;
                    break;
                }

                /*if(gp_csts()) {
                    const char ch = gp_ci();
                    if (ch=='i') {
                        iprintf("Frame #%u %u < %u %u ",block, now, timeout, data_ready);
                    }
                }*/


            }while(_times(NULL)<timeout);

            if (!data_ready) {
                iprintf("Timeout!\r\n");
                if(server) {
                    tftp_error(16u,"Timeout",pbuf->buffer);
                    continue;
                }else{
                    error = true;
                    done=false;
                    break; //return false;
                }
            } else {
                /*
                * Send file request or acknowledge and receive
                * a data block.
                */
                data_ready = false;
                if(rcv_len < 516u) {
                    done = true;
                }
                TFTPHDR  *msg = (TFTPHDR *)rcv_buf;
                if(msg->th_opcode == TFTP_ERROR) {
                    if(!server) {
                        iprintf("TFTP-Error %u: '%s'\n", msg->th_u.tu_code, msg->th_data);
                    }else{
                        iprintf("TFTP-Error %u\n", msg->th_u.tu_code);
                    }
                    error=true;
                    break;
                }else if(msg->th_opcode != TFTP_DATA) {
                    //iprintf("No data-block - ignore\r\n");
                    //return -1;
                    gp_co('i');
                    continue;
                }
                //iprintf("Received %u Port %u\r\n", msg->th_u.tu_block, uc_socket[sock].sremote_port);
                /*
                * If this block is out of sequence, we ignore it.
                * However, if we missed the first block, return
                * with an error.
                */
                if(msg->th_u.tu_block != (block + 1u)) {
                    // Is is prev. block again -> Ack was lost on remote side
                    if(msg->th_u.tu_block == block ) {
                        tftp_ack(block, pbuf->buffer);
                        gp_co('r');
                    }else{
                        iprintf("mb error %u != %u ",msg->th_u.tu_block, block + 1u);
                        if(block == 0u){
                            error = true;
                            break; //return false;
                        }
                    }
                    continue;
                }
                // ignore a package when it's too big
                if(rcv_len<=(TFTP_BLOCKSIZE+4u)) {
                    // ack the block to remote
                    block++;
                    //msg->th_u.tu_block = block;
                    tftp_ack(block, pbuf->buffer);
                    //bool store = false;
                    if(rcv_len > 4u) {
                        const uint16_t rx_data_len = rcv_len - 4u;
                        total_size += (uint32_t)rx_data_len;
                        //TFTP_DEBUG("TFTP-RX %d: %u Bytes ", block, (unsigned int)(rx_data_len));
                        memcpy(&block_buf[block_size],msg->th_data, rx_data_len);
#ifdef USE_CRC
                        //crc32=crc32_calc(crc32, msg->th_data, rx_data_len, crc32_table);
                        if (!dry_run) {
                            crc32=crc32_calc(crc32, &block_buf[block_size], rx_data_len, crc32_table);
                        }
#endif
                        block_size+=rx_data_len;
                        //store = ((block_size>=JD_BLOCKSIZE) || done);
                    }

                    // In the meanwhile write block to disk
                    if ((block_size>=RX_BUF_SIZE) || done) {
                        uint16_t nr_blocks = RX_BUF_SIZE / JD_BLOCKSIZE;
                        if(done) {
                            nr_blocks = block_size / JD_BLOCKSIZE;
                            if ((block_size % JD_BLOCKSIZE)!=0u) {
                                nr_blocks++;
                            }
                        }
                        if (!dry_run) {
                            result = jd_blockwrite(&myfcb, block_buf, nr_blocks);
                            if(result!=0u) {
                                error=true;
                                iprintf("Jados Error %u\r\n", result);
                                break;
                            }
                        }
                        TFTP_DEBUG("disk write: 0x%X %u blocks, remaining: %u\r\n", result, nr_blocks, block_size);
                        block_size -= min(RX_BUF_SIZE,block_size);
                        gp_co('.');
                        assert(block_size==0u);
                    }else{
                        //TFTP_DEBUG("Append %u\r\n",block_size);
                    }
                }
            }
        } while(!done);
        free(block_buf); block_buf=NULL;
    }
    free_tx_buf(pbuf);
    close_socket_udp(UDP_SOCK);
    if (!error && fnvalid) {
        const clock_t end_clock = _times(NULL);
        const time_t end_time = _gettime();
        if (!dry_run) {
            jd_close(&myfcb);
        }

        // Timer-Interrupt is not precise because jados disables interrupts :-()
        unsigned int bps = 0u;
        uint32_t duration = (end_time - start_time);
        const char* p_unit = NULL;
        if (!dry_run) {
            p_unit = "s";
            //iprintf("\r\nDuration for %u Bytes: %u ms with %u kB/s\r\n",(unsigned int)total_size, (unsigned int)duration,(unsigned int)((total_size/1024u)*1000u/duration));
            if (duration!=0u) {
                bps = (unsigned int)((total_size/1024u)/duration);
            }
        }else{
            p_unit = "ms";
            duration = (uint32_t)(1000u*(end_clock - start_clock)/CLOCKS_PER_SEC);
            if (duration!=0u) {
                bps = (unsigned int)((total_size/1024u)*1000u/duration);
            }
        }
        iprintf("\r\nDuration for %u Bytes: %u %s with %u kB/s\r\n",(unsigned int)total_size, (unsigned int)duration, p_unit, bps);
#ifdef USE_CRC
        if (!dry_run) {
            iprintf("\rCRC32: 0x%08X  \r\n",(unsigned int)crc32);
        }
#endif
    }
    iprintf("\ndone with %u\n",error);
    return !error;
}

bool tftp_transm_int(const unsigned long remote_ip, const uint16_t remote_port, const uint16_t local_port, const char* const p_file_name, const bool server)
{
    unsigned short block = 0u;
    bool error = false;
    bool done = false;

    const bool fnvalid = fn_valid(p_file_name);

    jdfcb_t myfcb={0u};
    jdfile_info_t info __attribute__ ((aligned (4))) = {0u};
    uint8_t result = 0xFFu;
    if(fnvalid) {
        result = jd_fillfcb(&myfcb,p_file_name);
        if(result!=0) {
            iprintf("Error %u creating FCB!\r\n", result);
        }else{
            result = jd_fileinfo(&myfcb, &info);
            iprintf("\r\nFileinfo-Result: 0x%X length: %u date:0x%lX, att:0x%X\r\n",result, (unsigned int)info.length, info.date, info.attribute);
        }
    }

    //Port in Anwendungstabelle eintragen für eingehende TFTP Daten!
    SOCKET_SETUP(UDP_SOCK, SOCKET_UDP, local_port, FLAG_PASSIVE_OPEN);
    if(open_socket_udp(UDP_SOCK, remote_ip, remote_port)!=0) {
        puts("Error opening UDP Socket");
        return false;
    }
    TX_BUFFER * const pbuf = allocate_tx_buf();

    if (result==0u) {
        char * p_buf = malloc(info.length);
        iprintf("Buffer @0x%X\n",(unsigned int)p_buf);
        p_buf[0]='\0';

        result = jd_fileload(&myfcb, p_buf);
        //p_buf[100]=0;
        //iprintf("Fileread-Result: 0x%X\r\n%s\r\n",result, p_buf);
        if (result!=0) {
            iprintf("Error %u reading file\r\n",result);
            return false;
        }

        const clock_t start_time = _times(NULL);
        const char* p_fn_temp = p_file_name;
        if(p_fn_temp[1]==':') {
            p_fn_temp = &p_file_name[2];
        }
        uint32_t total_size = 0u;
        if(server) {
            //tftp_ack(block, pbuf->buffer);
            block = 1u;
            const size_t xfer_len = (size_t)min((info.length - total_size),TFTP_BLOCKSIZE);
            tftp_data(block,&p_buf[total_size],xfer_len, pbuf->buffer);
            total_size += (uint32_t)xfer_len;
        }else{
            tftp_message(TFTP_WRQ, (const char *)p_fn_temp, (const char *)"octet", pbuf->buffer);
        }

        do {
            const clock_t timeout =  _times(NULL) + ((time_t)5000u * CLOCKS_PER_SEC)/1000u;
            uint16_t res = 0u;
            bool data_ready = false;
            do {
                res=poll_net();
                if((res&0xff00)==EVENT_UDP_DATARECEIVED) {
                    //iprintf("Event: 0x%04X %u\n",res,rcv_len);
                    data_ready=true;
                    break;
                }
            }while(_times(NULL)<timeout);
            if (!data_ready) {
                iprintf("Timeout!\r\n");
                error = true;
                break; //return false;
            }
            if (data_ready) {
                data_ready = false;
                //const uchar sock = res & 0xffu;

                TFTPHDR  *msg = (TFTPHDR *)rcv_buf;
                //TFTP_DEBUG("Received %u Port %u,%u\r\n", msg->th_u.tu_block, udp->udp_SrcPort, udp->udp_Hdrlen);

                if(msg->th_opcode == TFTP_ERROR) {
                    //TFTP_DEBUG("TFTP-Error '%u': %s\r\n",msg->th_u.tu_code,msg->th_data);
                    if(!server) {
                        iprintf("TFTP-Error %u: '%s'\n", msg->th_u.tu_code, msg->th_data);
                    }else{
                        iprintf("TFTP-Error %u\n", msg->th_u.tu_code);
                    }
                    error=true;
                    break;
                }else if(msg->th_opcode == TFTP_ACK) {
                    block++;
                }else{
                    TFTP_DEBUG("No ack - ignore\r\n");
                    gp_co('i');
                    continue;
                }
                const size_t xfer_len = (size_t)min((info.length - total_size),TFTP_BLOCKSIZE);
                tftp_data(block,&p_buf[total_size],xfer_len, pbuf->buffer);

                total_size += (uint32_t)xfer_len;
                if (xfer_len<TFTP_BLOCKSIZE) {
                    done=true;
                }
                TFTP_DEBUG("TFTP-TX %d: %u Bytes, total_size: %u %u\r\n", block, (unsigned int)(xfer_len), total_size, info.length);

                //gp_co('.');
            }

        } while(!done);

        if (!error) {
            const clock_t end_time = _times(NULL);
            free(p_buf);

            iprintf(" %u - %u ",(unsigned int)start_time, (unsigned int)end_time);
            const uint32_t duration = (uint32_t)(1000uL*(end_time - start_time)/CLOCKS_PER_SEC);
            iprintf("\r\nDuration for %u Bytes: %u ms with %u kB/s\r\n",(unsigned int)total_size, (unsigned int)duration,(unsigned int)((total_size/1024u)*1000u/duration));
        }

    }else{
        tftp_error(16u,"Invalid file name",pbuf->buffer);
        puts("Invalid file name!");
        error=true;
    }
    free_tx_buf(pbuf);
    close_socket_udp(UDP_SOCK);
    return !error;
}

bool check_wr_rd_command(const char* const p_buf, const size_t name_len, char* const p_filename) {
    if (strcmp(&p_buf[name_len+1u],"octet")!=0) {
        puts("unknown command");
        return false;
    }
    strcpy(p_filename, p_buf);
    return true;
}

bool TftpServer(const bool dry_run)
{
    bool success = false;
    //SOCKET_SETUP(UDP_SOCK, SOCKET_UDP, TFTP_CLIENT_PORT, FLAG_PASSIVE_OPEN);
    SOCKET_SETUP(UDP_SERVER_SOCK, SOCKET_UDP, TFTP_CLIENT_PORT, FLAG_PASSIVE_OPEN);
    uint16_t res = open_socket_udp(UDP_SERVER_SOCK, 0xffffffff, TFTP_SERVER_PORT);
    if(res!=0) {
        iprintf("Error 0x%X opening UDP Socket\n",res);
        return 0;
    }
    char ch=0;
    do {

        //bool data_ready = false;
        uint32_t remote_ip=0;
        uint16_t remote_port=0;
        do {
            res=poll_net();
            if((res&0xff00)==EVENT_UDP_DATARECEIVED) {
                const uchar sock = res & 0xffu;
                remote_port = uc_socket[sock].sremote_port;
                remote_ip   = uc_socket[sock].sremote_ip;
                //iprintf("Event: 0x%04X socket:%u 0x%08X Port:%u\n",res,sock,uc_socket[sock].sremote_ip,uc_socket[sock].sremote_port);
                //data_ready=true;
                break;
            }
            if(gp_csts()) {
                ch=gp_ci();
            }
        }while(ch!='x');
        if(ch=='x') {
            break;
        }
        TFTPHDR  *msg = (TFTPHDR *)rcv_buf;
        char filename[128]={0};
        TFTP_DEBUG("Request: %u, payload %s\n",msg->th_opcode, msg->th_u.tu_stuff);
        {
            const size_t name_len = strnlen(msg->th_u.tu_stuff, sizeof(filename)-1u);
            //iprintf("Debug %u %s\n",name_len, &msg->th_u.tu_stuff[name_len+1u]);

            if(name_len>=(sizeof(filename)-1u)) {
                iprintf("file name '%s' too long (%u, max allowed: %u)\r\n",msg->th_u.tu_stuff, (unsigned int)name_len, (unsigned int)sizeof(filename)-1u);
                continue;
            }

            switch(msg->th_opcode) {
                case TFTP_RRQ:
                    // client read-request (server -> client transfer)
                    //success = tftp_server_rrq(filename, remote_ip, remote_port);
                    if (check_wr_rd_command(msg->th_u.tu_stuff, name_len, filename)) {
                        iprintf("Transmit '%s'",filename);
                        success = tftp_transm_int(remote_ip, remote_port, TFTP_CLIENT_PORT, filename, true);
                    }
                    success=false;
                    break;
                case TFTP_WRQ:
                    // client write-request (client -> server transfer)
                    //success = tftp_server_wrq(filename, remote_ip, remote_port, dry_run);
                    if (check_wr_rd_command(msg->th_u.tu_stuff, name_len, filename)) {
                        iprintf("Receive '%s'",filename);
                        success = tftp_recv_int(remote_ip, remote_port, TFTP_CLIENT_PORT, filename, true, dry_run);
                    }
                    break;
            }
        }
    }while(1);

    return success;
}
