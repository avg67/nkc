/* $Workfile:   I2C.c $                                        			    		*/
/* $Revision:   $                                                       			*/
/* $Author:     Andreas Voggeneder $                                    			*/
/* $Date:       12.03.2026 $														*/
/* Description: I2C Routinen									 					*/
/*																					*/
/* Remarks:     No remarks.                                             			*/

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdbool.h>
#include "../../nkc_common/nkc/nkc.h"
#include "i2c.h"


#define OC_I2C_TIMEOUT_CYCLES  1000U


/* -----------------------------------------------------------------------
 * Internal helpers
 * ----------------------------------------------------------------------- */

/** Wait until TIP (Transfer In Progress) clears, or timeout. */
static oc_i2c_status_t wait_for_tip(void)
{
    uint16_t timeout = OC_I2C_TIMEOUT_CYCLES;
    while (I2C_sr & OC_I2C_SR_TIP) {
        if (--timeout == 0) return OC_I2C_ERR_TIMEOUT;
    }
    return OC_I2C_OK;
}

/** Check arbitration-lost flag. - not needed for NKC when only one master is there*/
/*static oc_i2c_status_t check_arb(void)
{
    if (I2C_sr & OC_I2C_SR_AL)
        return OC_I2C_ERR_ARB;
    return OC_I2C_OK;
}*/

/** Wait until bus BUSY clears (used after STO), or timeout. */
static oc_i2c_status_t wait_for_bus_free(void)
{
    uint16_t timeout = OC_I2C_TIMEOUT_CYCLES;
    while (I2C_sr & OC_I2C_SR_BUSY) {
        if (--timeout == 0) return OC_I2C_ERR_TIMEOUT;
    }
    return OC_I2C_OK;
}

/** Transmit one byte and wait for completion. */
static oc_i2c_status_t transmit_byte(uint8_t byte, uint8_t cmd)
{
    oc_i2c_status_t ret;
    I2C_txr = byte;
    I2C_cr  = cmd;
    ret = wait_for_tip();
    return ret;
    /*if (ret != OC_I2C_OK) return ret;
    return check_arb(dev);*/
}

/** Read one byte and wait for completion. */
static oc_i2c_status_t receive_byte(uint8_t *p_byte, uint8_t cmd)
{
    oc_i2c_status_t ret;
    I2C_cr = cmd;
    ret = wait_for_tip();
    if (ret != OC_I2C_OK) return ret;
    /*ret = check_arb();
    if (ret != OC_I2C_OK) return ret;*/
    *p_byte = I2C_rxr;
    return OC_I2C_OK;
}

/* -----------------------------------------------------------------------
 * Public API
 * ----------------------------------------------------------------------- */

void oc_i2c_init(const uint16_t prescale)
{
    /* Disable core before configuration */
    I2C_ctr = 0x00;

    /* Set clock prescaler: PRESCALE = (clk_hz / (5 * i2c_hz)) - 1 */
    //uint32_t prescale = (clk_hz / (5u * i2c_hz)) - 1u;
    I2C_prerl = prescale & 0xFFu;
    I2C_prerh = (prescale >> 8u) & 0xFFu;

    /* Enable core (no interrupt) */
    I2C_ctr = OC_I2C_CTR_EN;
}

void oc_i2c_disable(void) {
    I2C_ctr = 0;
}

oc_i2c_status_t oc_i2c_write(uint8_t addr, const uint8_t *p_data, uint16_t len)
{
    oc_i2c_status_t ret;

    /* Send START + slave address (write) */
    ret = transmit_byte((uint8_t)(addr << 1u),
                        OC_I2C_CR_STA | OC_I2C_CR_WR);
    if (ret != OC_I2C_OK) return ret;
    if (I2C_sr & OC_I2C_SR_RXACK)
        return OC_I2C_ERR_NACK;

    /* Send data bytes */
    for (uint16_t i = 0; i < len; i++) {
        uint8_t cmd = OC_I2C_CR_WR;
        if (i == (len - 1u)) cmd |= OC_I2C_CR_STO;  /* STOP on last byte */
        ret = transmit_byte(p_data[i], cmd);
        if (ret != OC_I2C_OK) return ret;
        if (I2C_sr & OC_I2C_SR_RXACK)
            return OC_I2C_ERR_NACK;
    }

    return OC_I2C_OK;
}

oc_i2c_status_t oc_i2c_read(uint8_t addr, uint8_t *p_data, uint16_t len)
{
    oc_i2c_status_t ret;

    /* Send START + slave address (read) */
    ret = transmit_byte((uint8_t)((addr << 1u) | 0x01u),
                        OC_I2C_CR_STA | OC_I2C_CR_WR);
    if (ret != OC_I2C_OK) return ret;
    if (I2C_sr & OC_I2C_SR_RXACK)
        return OC_I2C_ERR_NACK;

    /* Receive data bytes */
    for (uint16_t i = 0; i < len; i++) {
        uint8_t cmd = OC_I2C_CR_RD;
        if (i == (len - 1u)) {
            cmd |= OC_I2C_CR_ACK | OC_I2C_CR_STO;  /* NACK + STOP on last */
        }
        ret = receive_byte(&p_data[i], cmd);
        if (ret != OC_I2C_OK) return ret;
    }

    return OC_I2C_OK;
}

oc_i2c_status_t oc_i2c_write_read( uint8_t addr,
                                   const uint8_t *p_wr_data, uint16_t wr_len,
                                   uint8_t *p_rd_data, uint16_t rd_len)
{
    oc_i2c_status_t ret;

    /* Send START + slave address (write) */
    ret = transmit_byte((uint8_t)(addr << 1u),
                        OC_I2C_CR_STA | OC_I2C_CR_WR);
    if (ret != OC_I2C_OK)
        return ret;
    if (I2C_sr & OC_I2C_SR_RXACK)
        return OC_I2C_ERR_NACK;

    /* Write phase – no STOP at end */
    for (uint16_t i = 0; i < wr_len; i++) {
        ret = transmit_byte(p_wr_data[i], OC_I2C_CR_WR);
        if (ret != OC_I2C_OK)
            return ret;
        if (I2C_sr & OC_I2C_SR_RXACK)
            return OC_I2C_ERR_NACK;
    }

    /* Repeated START + slave address (read) */
    ret = transmit_byte((uint8_t)((addr << 1u) | 0x01u),
                        OC_I2C_CR_STA | OC_I2C_CR_WR);
    if (ret != OC_I2C_OK)
        return ret;
    if (I2C_sr & OC_I2C_SR_RXACK)
        return OC_I2C_ERR_NACK;

    /* Read phase */
    for (uint16_t i = 0; i < rd_len; i++) {
        uint8_t cmd = OC_I2C_CR_RD;
        if (i == rd_len - 1u) {
            cmd |= OC_I2C_CR_ACK | OC_I2C_CR_STO;
        }
        ret = receive_byte(&p_rd_data[i], cmd);
        if (ret != OC_I2C_OK) return ret;
    }

    return OC_I2C_OK;
}

oc_i2c_status_t oc_i2c_scan( uint8_t         *p_found,
                             const uint8_t   found_max,
                             uint8_t         *p_found_cnt)
{
    oc_i2c_status_t ret;
    *p_found_cnt = 0;

    /*
     * Valid 7-bit address range: 0x08 – 0x77
     * Addresses 0x00–0x07 and 0x78–0x7F are reserved by the I2C spec.
     */
    for (uint8_t addr = 0x08; addr <= 0x77; addr++) {

        /* --- Phase 1: START + address byte (write direction) ---
         * TIP is asserted here – safe to call wait_for_tip()
         */
        I2C_txr = (uint8_t)(addr << 1u); /* R/W=0 */
        I2C_cr  = OC_I2C_CR_STA | OC_I2C_CR_WR;

        ret = wait_for_tip();   /* TIP clears when address byte is done */
        if (ret != OC_I2C_OK) return ret;

        /* --- Phase 2: Check ACK/NACK from slave ---
         * Must be read BEFORE issuing STO, as STO may clear status bits.
         */
        uint8_t sr               = I2C_sr;
        //const bool    arbitration_lost = (sr & OC_I2C_SR_AL)    != 0;
        const bool    got_nack   = (sr & OC_I2C_SR_RXACK) != 0;

        /* --- Phase 3: Send STOP (no TIP – wait for BUSY to deassert) --- */
        I2C_cr = OC_I2C_CR_STO;
        ret = wait_for_bus_free();  /* STO does NOT set TIP – poll BUSY */
        if (ret != OC_I2C_OK) return ret;

        /* --- Phase 4: Evaluate result --- */
        /*if (arbitration_lost) {
            I2C_cr = OC_I2C_CR_IACK;
            continue;
        }*/

        if (!got_nack) {
            /* Slave responded with ACK – record the address */
            if (*p_found_cnt < found_max) {
                p_found[(*p_found_cnt)++] = addr;
            }
        }
    }

    return OC_I2C_OK;
}








