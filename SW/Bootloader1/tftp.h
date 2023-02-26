#ifndef _TFTP_H
#define _TFTP_H

/*!
 * \addtogroup xgTftp
 */
/*@{*/

typedef struct tftphdr {
    unsigned short th_opcode;            /* packet type */
    union {
        unsigned short tu_block;         /* block # */
        unsigned short tu_code;          /* error code */
        char  tu_stuff[1];      /* request packet stuff */
    } th_u;
    char th_data[512];          /* data or error string */
} TFTPHDR;

#define TFTP_CLIENT_PORT 69u
#define TFTP_SERVER_PORT 1024u

#define TFTP_RRQ     01  /*!< \brief TFTP read request packet. */
#define TFTP_WRQ     02  /*!< \brief TFTP write request packet. */
#define TFTP_DATA    03  /*!< \brief TFTP data packet. */
#define TFTP_ACK     04  /*!< \brief TFTP acknowledgement packet. */
#define TFTP_ERROR   05  /*!< \brief TFTP error packet. */
#define TFTP_OACK    06  /*!< \brief TFTP option acknowledgement packet. */

/*@}*/

int TftpRecv(unsigned long server_ip, char* const p_file_name);

#endif
