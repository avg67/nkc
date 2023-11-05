#include <stdio.h>
#include <sys/ndrclock.h>
#include <sys/file.h>
#include <sys/path.h>
#include <sys/m68k.h>
#include <time.h>
#include <stdlib.h>
#include <stdint.h>
#include "../../nkc_common/nkc/nkc.h"
#include "crc32.h"


#ifdef USE_CRC
static inline uint32_t crc_bytecalc(uint8_t byte, uint32_t crc, uint32_t polynom, uint16_t poly_width)
{
    // mask bit for poly msb
    const uint32_t msb = (1uL << (poly_width - 1u));
    // Mask rg. to poly width
    const uint32_t mask = (poly_width < 32u) ? ~((uint32_t)((~0uL) << poly_width)) : 0xFFFFFFFFu;
    // Calculate xor value for current byte
    const uint8_t byte_to_calc = (uint8_t)((crc >> (poly_width - 8u)) ^ byte);
    uint32_t xor_value         = (uint32_t)byte_to_calc << (poly_width - 8u);
    for (uint16_t i = 0u; i < 8u; ++i) {
        if ((xor_value & msb) != 0u) {
            //crc = (crc>>1)^polynom;
            xor_value = ((xor_value << 1u) ^ polynom) & mask;
        } else {
            xor_value = (xor_value << 1u) & mask;
        }
    }
    // Now do the CRC calculation
    //return ((crc << 8u) ^ xor_value) & mask;
    return xor_value;
}

static inline uint8_t reflect(const uint8_t data)
{
    register uint8_t data_in  = data;
    register uint8_t b=0u;
    for(register uint16_t i=0;i<8u;i++) {
      b<<=1u;
      b|= (data_in & 1u);
      data_in >>=1u;
    }
    return b;
}

void gen_crc32_lookup_table(uint32_t p_table[256], const uint32_t polynom, uint16_t poly_width)
{
    for(uint16_t i=0u;i<256u;i++) {
        const uint32_t xor_value = crc_bytecalc((uint8_t)i,0u, polynom, poly_width);
        //iprintf("Xor[%u]=0x%08X ",i, xor_value);
        p_table[i]=xor_value;
    }
}

uint32_t crc32_calc(const uint32_t crc32_start, const void* const p_mem, const size_t len, const uint32_t p_table[256])
{
    register const uint8_t* p_bytes = (const uint8_t*) p_mem;
    register const uint32_t* p_lt  = p_table;
    register uint32_t crc32 = crc32_start;
    register size_t i = len+1u;
    while(--i) {
        register const uint8_t pos = (uint8_t)((crc32 ^ (*p_bytes++ << 24u)) >> 24u);
        crc32 = (crc32 << 8u) ^ p_lt[pos];
    }
    return crc32;
}
#endif

