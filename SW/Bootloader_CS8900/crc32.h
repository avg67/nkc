 /*
 * \file
 * \brief  Implements an CRC32.
 * \author Andreas Voggeneder
 */

#ifndef CRC32_H
#define CRC32_H

/******************************************************************************/
/*----------------------------------Includes----------------------------------*/
/******************************************************************************/
#include <stdlib.h>
#include <stdint.h>

/******************************************************************************/
/*-----------------------------Data Structures--------------------------------*/
/******************************************************************************/

/******************************************************************************/
/*-------------------------Global Function Prototypes-------------------------*/
/******************************************************************************/
void gen_crc32_lookup_table(uint32_t p_table[256], const uint32_t polynom, uint16_t poly_width);
uint32_t crc32_calc(const uint32_t crc32_start, const void* const p_mem, const size_t len, const uint32_t p_table[256]);

/******************************************************************************/
/*-------------------------Inline Function Prototypes-------------------------*/
/******************************************************************************/

/******************************************************************************/
/*---------------------Inline Function Implementations------------------------*/
/******************************************************************************/
static inline uint32_t crc32_byte(const uint32_t crc32, const uint32_t p_table[256], const uint8_t byte)
{
    register const uint8_t pos = (uint8_t)((crc32 ^ ((uint32_t)byte << 24u)) >> 24u);
    return (crc32 << 8u) ^ p_table[pos];
}

#endif