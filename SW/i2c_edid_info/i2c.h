/* $Workfile:   I2C.h $                                        			    		*/
/* $Revision:   $                                                       			*/
/* $Author:     Andreas Voggeneder $                                    			*/
/* $Date:       12.03.2026 $														*/
/* Description: I2C Routinen									 					*/
/*																					*/
/* Remarks:     No remarks.                                             			*/


#ifndef ___I2C_H
#define ___I2C_H

#include <stdbool.h>
#include "../../nkc_common/nkc/nkc.h"

/* -----------------------------------------------------------------------
 * Registers
 * ----------------------------------------------------------------------- */
#define I2C_base  0xffffff08
#define I2C_cr    (*((volatile uint8_t*)((I2C_base+0)*cpu)))
#define I2C_prerl (*((volatile uint8_t*)((I2C_base+1)*cpu)))
#define I2C_prerh (*((volatile uint8_t*)((I2C_base+2)*cpu)))
#define I2C_ctr   (*((volatile uint8_t*)((I2C_base+3)*cpu)))
#define I2C_txr   (*((volatile uint8_t*)((I2C_base+4)*cpu)))
#define I2C_rxr   (*((volatile uint8_t*)((I2C_base+5)*cpu)))
#define I2C_sr    (*((volatile uint8_t*)((I2C_base+6)*cpu)))

/* -----------------------------------------------------------------------
 * Control Register Bits (CTR)
 * ----------------------------------------------------------------------- */
#define OC_I2C_CTR_EN   (1 << 7)  /**< Enable core              */
#define OC_I2C_CTR_IEN  (1 << 6)  /**< Enable interrupt         */

/* -----------------------------------------------------------------------
 * Command Register Bits (CR)
 * ----------------------------------------------------------------------- */
#define OC_I2C_CR_STA   (1 << 7)  /**< Generate START condition  */
#define OC_I2C_CR_STO   (1 << 6)  /**< Generate STOP condition   */
#define OC_I2C_CR_RD    (1 << 5)  /**< Read from slave           */
#define OC_I2C_CR_WR    (1 << 4)  /**< Write to slave            */
#define OC_I2C_CR_ACK   (1 << 3)  /**< Acknowledge (NACK when 1) */
#define OC_I2C_CR_IACK  (1 << 0)  /**< Interrupt Acknowledge     */

/* -----------------------------------------------------------------------
 * Status Register Bits (SR)
 * ----------------------------------------------------------------------- */
#define OC_I2C_SR_RXACK (1 << 7)  /**< Received ACK (0=ACK, 1=NACK) */
#define OC_I2C_SR_BUSY  (1 << 6)  /**< Bus busy                     */
#define OC_I2C_SR_AL    (1 << 5)  /**< Arbitration lost             */
#define OC_I2C_SR_TIP   (1 << 1)  /**< Transfer in progress         */
#define OC_I2C_SR_IF    (1 << 0)  /**< Interrupt flag               */

/* -----------------------------------------------------------------------
 * Return codes
 * ----------------------------------------------------------------------- */
typedef enum {
    OC_I2C_OK        =  0,
    OC_I2C_ERR_NACK  = -1,
    OC_I2C_ERR_BUSY  = -2,
    OC_I2C_ERR_ARB   = -3,
    OC_I2C_ERR_TIMEOUT = -4,
} oc_i2c_status_t;

/* -----------------------------------------------------------------------
 * API
 * ----------------------------------------------------------------------- */

/**
 * @brief  Initialize the OpenCores I2C controller.
 */
void oc_i2c_init(const uint16_t prescale);

/**
 * @brief  Disables the OpenCores I2C controller.
 */
void oc_i2c_disable(void);

/**
 * @brief  Write bytes to an I2C slave device.
 * @param  addr     7-bit slave address.
 * @param  p_data   Pointer to data buffer.
 * @param  len      Number of bytes to write.
 * @return OC_I2C_OK on success, error code otherwise.
 */
oc_i2c_status_t oc_i2c_write(const uint8_t addr, const uint8_t *p_data, const uint16_t len);

/**
 * @brief  Read bytes from an I2C slave device.
 * @param  addr     7-bit slave address.
 * @param  p_data   Pointer to receive buffer.
 * @param  len      Number of bytes to read.
 * @return OC_I2C_OK on success, error code otherwise.
 */
oc_i2c_status_t oc_i2c_read(const uint8_t addr, uint8_t *p_data, const uint16_t len);

/**
 * @brief  Write then read (combined transaction) from an I2C slave.
 * @param  addr       7-bit slave address.
 * @param  p_wr_data  Pointer to write buffer.
 * @param  wr_len     Number of bytes to write.
 * @param  p_rd_data  Pointer to read buffer.
 * @param  rd_len     Number of bytes to read.
 * @return OC_I2C_OK on success, error code otherwise.
 */
oc_i2c_status_t oc_i2c_write_read(const uint8_t addr, const uint8_t *p_wr_data, const uint16_t wr_len, uint8_t *p_rd_data, const uint16_t rd_len);

/**
 * @brief  Scans I2C Bus for slave devices.
 * @param  p_found     Pointer to buffer for found device addresses.
 * @param  found_max   Max. number of devices to return.
 * @param  p_found_cnt Pointer to variable for found devices.
 * @return OC_I2C_OK on success, error code otherwise.
 */
oc_i2c_status_t oc_i2c_scan(uint8_t *p_found, const uint8_t found_max, uint8_t *p_found_cnt);

#endif