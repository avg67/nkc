#include <stdio.h>
#include <sys/ndrclock.h>
#include <sys/file.h>
#include <sys/path.h>
#include <sys/m68k.h>
#include <time.h>
#include <stdlib.h>
#include <stdint.h>
#include "../../nkc_common/nkc/nkc.h"
#include "i2c.h"

#define BUS_SPEED 40000 // 40 Mhz
#define I2C_SPEED 100 // 100 kHz
#define I2CP_PRER(speed_khz) (BUS_SPEED/(5*speed_khz)-1)

#define PCF8574_SLAVE_ADDRESS 0x20


int main(int argc, char **argp, char **envp)
{
	DISABLE_CPU_INTERRUPTS;

    setvbuf(stdin, NULL, _IONBF, 0);
    setvbuf(stdout, NULL, _IONBF, 0);
    setvbuf(stderr, NULL, _IONBF, 0);

    oc_i2c_init(I2CP_PRER(I2C_SPEED));
    iprintf("I2C Init done\r\n");
    // 1. Scan I2C Bus for devices and print them
    {
        uint8_t found[10] = {0};
        uint8_t found_cnt = 0;
        oc_i2c_status_t stat = oc_i2c_scan(found, sizeof(found), &found_cnt);
        iprintf("oc_i2c_scan status: %d, found %u devices\r\n", stat, found_cnt);
        if (found_cnt>0) {
            for(uint8_t i=0; i<found_cnt;i++) {
                iprintf("Found Device at Address: 0x%02x\r\n",found[i]);
            }
        }
    }
    // 2. Write 0x5A to an PCF8574
    {
        const uint8_t bfr[]={0x5a};
        oc_i2c_status_t stat = oc_i2c_write(PCF8574_SLAVE_ADDRESS, bfr, sizeof(bfr));
        iprintf("\r\noc_i2c_write status: %d\r\n", stat);
    }
    // 3. Read it back from PCF8574
    {
        uint8_t rx_bfr[5]={0};
        oc_i2c_status_t stat = oc_i2c_read(PCF8574_SLAVE_ADDRESS, rx_bfr, 1);
        iprintf("\r\noc_i2c_read status: %d PCF8574 value: 0x%02X\r\n", stat, rx_bfr[0]);
    }

    oc_i2c_disable();


}
