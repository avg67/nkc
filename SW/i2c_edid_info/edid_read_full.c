/* $Workfile:   edid_read.c $                                                   */
/* $Revision:   $                                                                */
/* $Author:     Andreas Voggeneder $                                             */
/* $Date:       12.03.2026 $                                                     */
/* Description: Read and display HDMI EDID data via OpenCores I2C               */
/*                                                                               */
/* Remarks:     EDID is located on the DDC bus of the HDMI connector.            */
/*              The DDC bus is a standard I2C bus.                               */
/*              EDID EEPROM I2C address: 0x50 (7-bit)                            */
/*              EDID block size: 128 bytes                                       */
/*              Up to 4 extension blocks possible (byte[126] = extension count) */
/*                                                                               */
/*  I2C prescaler formula: PRESCALE = (clk_hz / (5 * scl_hz)) - 1               */
/*  Example: 40MHz clock, 100kHz I2C -> PRESCALE = (40000000/(5*100000))-1 = 79 */

#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include "../../nkc_common/nkc/nkc.h"
#include "../I2C_HW_Routines/i2c.h"

/* -----------------------------------------------------------------------
 * EDID / DDC constants
 * ----------------------------------------------------------------------- */
#define EDID_I2C_ADDR       0x50u   /**< 7-bit DDC/EDID EEPROM address      */
#define EDID_BLOCK_SIZE     128u    /**< Bytes per EDID block                */
#define EDID_MAX_BLOCKS     4u      /**< Maximum supported extension blocks  */
#define EDID_EXT_COUNT_OFF  126u    /**< Offset of extension-block count     */
#define EDID_CHECKSUM_OFF   127u    /**< Offset of block checksum            */

/** Expected EDID header pattern (bytes 0-7) */
static const uint8_t EDID_HEADER[8] = {
    0x00u, 0xFFu, 0xFFu, 0xFFu, 0xFFu, 0xFFu, 0xFFu, 0x00u
};

/* -----------------------------------------------------------------------
 * I2C clock configuration
 * PRESCALE = (SYS_CLK_HZ / (5 * I2C_SCL_HZ)) - 1
 * ----------------------------------------------------------------------- */
#define SYS_CLK_HZ   40000000UL  /**< NKC system clock: 40 MHz             */
#define I2C_SCL_HZ     100000UL  /**< I2C standard mode: 100 kHz           */
#define I2C_PRESCALE  ((uint16_t)((SYS_CLK_HZ / (5UL * I2C_SCL_HZ)) - 1UL))

/* -----------------------------------------------------------------------
 * EDID Base Block field offsets (VESA EDID 1.4 spec)
 * ----------------------------------------------------------------------- */
#define OFF_MFR_ID          8u
#define OFF_PROD_CODE       10u
#define OFF_SERIAL_NUM      12u
#define OFF_MFR_WEEK        16u
#define OFF_MFR_YEAR        17u
#define OFF_EDID_VER        18u
#define OFF_EDID_REV        19u
#define OFF_INPUT_DEF       20u
#define OFF_H_SIZE_CM       21u
#define OFF_V_SIZE_CM       22u
#define OFF_GAMMA           23u
#define OFF_FEAT_SUPPORT    24u
#define OFF_CHROMA_BASE     25u  /* 10 bytes */
#define OFF_EST_TIMINGS     35u  /* 3 bytes  */
#define OFF_STD_TIMINGS     38u  /* 16 bytes, 8 x 2-byte entries */
#define OFF_DESCRIPTORS     54u  /* 4 x 18-byte descriptors      */
#define OFF_EXT_COUNT       126u
#define OFF_CHECKSUM        127u

/* Descriptor types (first 2 bytes = 0x0000 means monitor descriptor) */
#define DESC_MONITOR_SN     0xFFu
#define DESC_DATA_STRING    0xFEu
#define DESC_RANGE_LIMITS   0xFDu
#define DESC_MONITOR_NAME   0xFCu
#define DESC_STD_TIMING_3   0xFBu
#define DESC_COLOR_POINT    0xFAu

/* -----------------------------------------------------------------------
 * Paged output: line counter + helpers
 * ----------------------------------------------------------------------- */
#define PAGE_LINES  25u   /**< Lines per screen page */

static uint8_t g_line_count = 0u;

/**
 * @brief  Call after every line printed. Pauses with a prompt every
 *         PAGE_LINES lines, waiting for a single keypress via gp_ci().
 */
static void next_line(void)
{
    g_line_count++;
    if (g_line_count >= PAGE_LINES) {
        iprintf("  -- Press any key for next page --");
        (void)gp_ci();   /* blocking key read, no echo */
        putchar('\r');
        /* overwrite the prompt line with spaces then CR */
        iprintf("                                   \r");
        g_line_count = 0u;
    }
}

/** Convenience: print a newline-terminated line and count it. */
#define PRINTLN(...)  do { iprintf(__VA_ARGS__); putchar('\n'); next_line(); } while(0)

/** Convenience: print just a blank line and count it. */
#define BLANKLINE()   do { putchar('\n'); next_line(); } while(0)

/* -----------------------------------------------------------------------
 * Helper: print i2c error  (no paging needed – always ≤ 2 lines)
 * ----------------------------------------------------------------------- */
static void print_i2c_error(const char *ctx, oc_i2c_status_t err)
{
    iprintf("  [I2C ERROR in %s: ", ctx);
    switch (err) {
        case OC_I2C_ERR_NACK:    iprintf("NACK");     break;
        case OC_I2C_ERR_BUSY:    iprintf("BUSY");     break;
        case OC_I2C_ERR_ARB:     iprintf("ARB LOST"); break;
        case OC_I2C_ERR_TIMEOUT: iprintf("TIMEOUT");  break;
        default:                 iprintf("(%d)", (int)err); break;
    }
    iprintf("]\n");
    next_line();
}

/* -----------------------------------------------------------------------
 * Helper: validate EDID block checksum
 * ----------------------------------------------------------------------- */
static bool edid_checksum_ok(const uint8_t *blk)
{
    uint8_t sum = 0u;
    for (uint16_t i = 0u; i < EDID_BLOCK_SIZE; i++) {
        sum = (uint8_t)(sum + blk[i]);
    }
    return (sum == 0u);
}

/* -----------------------------------------------------------------------
 * Helper: validate EDID base-block header bytes
 * ----------------------------------------------------------------------- */
static bool edid_header_ok(const uint8_t *blk)
{
    return (memcmp(blk, EDID_HEADER, sizeof(EDID_HEADER)) == 0);
}

/* -----------------------------------------------------------------------
 * Helper: read one EDID block (128 bytes) from the EEPROM.
 * ----------------------------------------------------------------------- */
static oc_i2c_status_t edid_read_block(uint8_t block_num, uint8_t *p_buf)
{
    uint8_t offset = (uint8_t)(block_num * EDID_BLOCK_SIZE);
    return oc_i2c_write_read(EDID_I2C_ADDR,
                             &offset, 1u,
                             p_buf,  EDID_BLOCK_SIZE);
}

/* -----------------------------------------------------------------------
 * Decode manufacturer ID (3 packed 5-bit letters, big-endian)
 * ----------------------------------------------------------------------- */
static void decode_mfr_id(const uint8_t *blk, char out[4])
{
    uint16_t id = ((uint16_t)blk[OFF_MFR_ID] << 8u) | blk[OFF_MFR_ID + 1u];
    out[0] = (char)('@' + ((id >> 10u) & 0x1Fu));
    out[1] = (char)('@' + ((id >>  5u) & 0x1Fu));
    out[2] = (char)('@' + ( id         & 0x1Fu));
    out[3] = '\0';
}

/* -----------------------------------------------------------------------
 * Print a monitor descriptor string (strip trailing spaces / 0x0A)
 * ----------------------------------------------------------------------- */
static void print_descriptor_string(const uint8_t *desc)
{
    for (uint8_t i = 5u; i < 18u; i++) {
        uint8_t c = desc[i];
        if (c == 0x0Au) break;
        if (c >= 0x20u && c < 0x7Fu) {
            putchar((int)c);
        }
    }
}

/* -----------------------------------------------------------------------
 * Decode and print all four 18-byte descriptors in the base block
 * ----------------------------------------------------------------------- */
static void print_descriptors(const uint8_t *blk)
{
    PRINTLN("  Descriptors:");
    for (uint8_t d = 0u; d < 4u; d++) {
        const uint8_t *desc = blk + OFF_DESCRIPTORS + (d * 18u);

        if (desc[0] != 0x00u || desc[1] != 0x00u) {
            uint32_t pixel_clk_khz = ((uint32_t)desc[1] << 8u | desc[0]) * 10UL;
            uint16_t h_active = (uint16_t)(desc[2] | ((desc[4] & 0xF0u) << 4u));
            uint16_t h_blank  = (uint16_t)(desc[3] | ((desc[4] & 0x0Fu) << 8u));
            uint16_t v_active = (uint16_t)(desc[5] | ((desc[7] & 0xF0u) << 4u));
            uint16_t v_blank  = (uint16_t)(desc[6] | ((desc[7] & 0x0Fu) << 8u));
            uint32_t h_total  = (uint32_t)h_active + h_blank;
            uint32_t v_total  = (uint32_t)v_active + v_blank;
            uint32_t refresh  = (h_total > 0u && v_total > 0u)
                                ? (pixel_clk_khz * 1000UL) / (h_total * v_total)
                                : 0UL;
            PRINTLN("    [%u] Detailed Timing: %ux%u @ ~%lu Hz  (clk=%lu kHz)",
                    (unsigned)d,
                    (unsigned)h_active, (unsigned)v_active,
                    (unsigned long)refresh,
                    (unsigned long)pixel_clk_khz);
        } else {
            switch (desc[3]) {
                case DESC_MONITOR_NAME:
                    iprintf("    [%u] Monitor Name   : ", (unsigned)d);
                    print_descriptor_string(desc);
                    putchar('\n'); next_line();
                    break;
                case DESC_MONITOR_SN:
                    iprintf("    [%u] Monitor Serial : ", (unsigned)d);
                    print_descriptor_string(desc);
                    putchar('\n'); next_line();
                    break;
                case DESC_DATA_STRING:
                    iprintf("    [%u] Data String    : ", (unsigned)d);
                    print_descriptor_string(desc);
                    putchar('\n'); next_line();
                    break;
                case DESC_RANGE_LIMITS:
                    PRINTLN("    [%u] Range Limits   : "
                            "V %u-%u Hz, H %u-%u kHz, Max clk %u MHz",
                            (unsigned)d,
                            (unsigned)desc[5], (unsigned)desc[6],
                            (unsigned)desc[7], (unsigned)desc[8],
                            (unsigned)desc[9] * 10u);
                    break;
                default:
                    PRINTLN("    [%u] Descriptor type 0x%02X",
                            (unsigned)d, (unsigned)desc[3]);
                    break;
            }
        }
    }
}

/* -----------------------------------------------------------------------
 * Decode established timings (bytes 35-37)
 * ----------------------------------------------------------------------- */
static void print_established_timings(const uint8_t *blk)
{
    static const char * const est_names[] = {
        "720x400@70Hz",  "720x400@88Hz",  "640x480@60Hz",  "640x480@67Hz",
        "640x480@72Hz",  "640x480@75Hz",  "800x600@56Hz",  "800x600@60Hz",
        "800x600@72Hz",  "800x600@75Hz",  "832x624@75Hz",  "1024x768@87Hz(i)",
        "1024x768@60Hz", "1024x768@70Hz", "1024x768@75Hz", "1280x1024@75Hz",
        "1152x870@75Hz"
    };

    PRINTLN("  Established Timings:");
    uint32_t bits = ((uint32_t)blk[35] << 16u) |
                    ((uint32_t)blk[36] <<  8u) |
                     (uint32_t)blk[37];

    bool any = false;
    for (uint8_t i = 0u; i < 17u; i++) {
        if (bits & (1UL << (23u - i))) {
            PRINTLN("    %s", est_names[i]);
            any = true;
        }
    }
    if (!any) PRINTLN("    (none)");
}

/* -----------------------------------------------------------------------
 * Decode standard timings (8 x 2-byte entries, bytes 38-53)
 * ----------------------------------------------------------------------- */
static void print_standard_timings(const uint8_t *blk)
{
    PRINTLN("  Standard Timings:");
    bool any = false;
    for (uint8_t i = 0u; i < 8u; i++) {
        uint8_t b0 = blk[OFF_STD_TIMINGS + i * 2u];
        uint8_t b1 = blk[OFF_STD_TIMINGS + i * 2u + 1u];
        if (b0 == 0x01u && b1 == 0x01u) continue;

        uint16_t h_res   = (uint16_t)((b0 + 31u) * 8u);
        uint8_t  ar_code = (b1 >> 6u) & 0x03u;
        uint8_t  refresh = (b1 & 0x3Fu) + 60u;

        static const char * const ar_str[] = { "16:10", "4:3", "5:4", "16:9" };
        PRINTLN("    %ux?@%uHz  AR=%s",
                (unsigned)h_res, (unsigned)refresh, ar_str[ar_code]);
        any = true;
    }
    if (!any) PRINTLN("    (none)");
}

/* -----------------------------------------------------------------------
 * Print the decoded base-block summary
 * ----------------------------------------------------------------------- */
static void print_base_block(const uint8_t *blk)
{
    char mfr[4];
    decode_mfr_id(blk, mfr);

    uint16_t prod_code  = (uint16_t)((uint16_t)blk[OFF_PROD_CODE + 1u] << 8u)
                          | blk[OFF_PROD_CODE];
    uint32_t serial_num = ((uint32_t)blk[OFF_SERIAL_NUM + 3u] << 24u) |
                          ((uint32_t)blk[OFF_SERIAL_NUM + 2u] << 16u) |
                          ((uint32_t)blk[OFF_SERIAL_NUM + 1u] <<  8u) |
                           (uint32_t)blk[OFF_SERIAL_NUM];
    uint8_t  mfr_week   = blk[OFF_MFR_WEEK];
    uint16_t mfr_year   = (uint16_t)(blk[OFF_MFR_YEAR] + 1990u);
    uint8_t  edid_ver   = blk[OFF_EDID_VER];
    uint8_t  edid_rev   = blk[OFF_EDID_REV];
    uint8_t  input      = blk[OFF_INPUT_DEF];
    bool     is_digital = (input & 0x80u) != 0u;
    uint8_t  h_cm       = blk[OFF_H_SIZE_CM];
    uint8_t  v_cm       = blk[OFF_V_SIZE_CM];
    uint8_t  feat       = blk[OFF_FEAT_SUPPORT];
    bool     dpms_stby  = (feat & 0x80u) != 0u;
    bool     dpms_susp  = (feat & 0x40u) != 0u;
    bool     dpms_off   = (feat & 0x20u) != 0u;
    uint8_t  ext_count  = blk[OFF_EXT_COUNT];

    PRINTLN("============================================================");
    PRINTLN("  EDID Base Block");
    PRINTLN("============================================================");
    PRINTLN("  Manufacturer ID  : %s",     mfr);
    PRINTLN("  Product Code     : 0x%04X", (unsigned)prod_code);
    PRINTLN("  Serial Number    : %lu",     (unsigned long)serial_num);

    iprintf("  Manufacture Date : ");
    if (mfr_week == 0xFFu)
        { iprintf("Year %u (model year)\n", (unsigned)mfr_year); next_line(); }
    else if (mfr_week == 0x00u)
        { iprintf("Year %u\n",              (unsigned)mfr_year); next_line(); }
    else
        { iprintf("Week %u / %u\n", (unsigned)mfr_week, (unsigned)mfr_year); next_line(); }

    PRINTLN("  EDID Version     : %u.%u",  (unsigned)edid_ver, (unsigned)edid_rev);
    PRINTLN("  Input Type       : %s",      is_digital ? "Digital" : "Analog");

    if (is_digital) {
        static const char * const bpc_str[] = {
            "undefined","6","8","10","12","14","16","reserved"
        };
        PRINTLN("  Color Bit Depth  : %s bpc", bpc_str[(input >> 4u) & 0x07u]);
        static const char * const iface_str[] = {
            "undefined","DVI","HDMI-a","HDMI-b","MDDI","DisplayPort"
        };
        uint8_t iface = input & 0x0Fu;
        PRINTLN("  Video Interface  : %s", iface < 6u ? iface_str[iface] : "reserved");
    }

    iprintf("  Display Size     : %u cm x %u cm", (unsigned)h_cm, (unsigned)v_cm);
    if (h_cm > 0u && v_cm > 0u) {
        uint32_t d2 = (uint32_t)h_cm * h_cm + (uint32_t)v_cm * v_cm;
        uint32_t s  = d2 / 2u;
        if (s > 0u) {
            for (uint8_t k = 0u; k < 16u; k++) s = (s + d2 / s) / 2u;
        }
        iprintf("  (~%lu\")\n", (unsigned long)(s * 10UL / 254UL));
    } else {
        putchar('\n');
    }
    next_line();

    if (blk[OFF_GAMMA] != 0xFFu) {
        uint16_t g100 = (uint16_t)(blk[OFF_GAMMA] + 100u);
        PRINTLN("  Gamma            : %u.%02u",
                (unsigned)(g100 / 100u), (unsigned)(g100 % 100u));
    } else {
        PRINTLN("  Gamma            : undefined (defined in DisplayID ext)");
    }

    PRINTLN("  DPMS Standby     : %s", dpms_stby ? "yes" : "no");
    PRINTLN("  DPMS Suspend     : %s", dpms_susp ? "yes" : "no");
    PRINTLN("  DPMS Active-Off  : %s", dpms_off  ? "yes" : "no");
    PRINTLN("  Extension Blocks : %u", (unsigned)ext_count);

    BLANKLINE();
    print_established_timings(blk);
    BLANKLINE();
    print_standard_timings(blk);
    BLANKLINE();
    print_descriptors(blk);
    BLANKLINE();
}

/* -----------------------------------------------------------------------
 * Print a CEA/CTA-861 extension block summary (tag = 0x02)
 * ----------------------------------------------------------------------- */
static void print_cea_extension(const uint8_t *blk, uint8_t block_num)
{
    PRINTLN("============================================================");
    PRINTLN("  CEA/CTA-861 Extension Block %u", (unsigned)block_num);
    PRINTLN("============================================================");

    uint8_t revision    = blk[1];
    uint8_t dtd_offset  = blk[2];
    uint8_t flags       = blk[3];
    bool    underscan   = (flags & 0x80u) != 0u;
    bool    audio       = (flags & 0x40u) != 0u;
    bool    ycbcr444    = (flags & 0x20u) != 0u;
    bool    ycbcr422    = (flags & 0x10u) != 0u;
    uint8_t native_dtds = flags & 0x0Fu;

    PRINTLN("  CEA Revision     : %u", (unsigned)revision);
    PRINTLN("  Underscan        : %s", underscan ? "yes" : "no");
    PRINTLN("  Basic Audio      : %s", audio     ? "yes" : "no");
    PRINTLN("  YCbCr 4:4:4      : %s", ycbcr444  ? "yes" : "no");
    PRINTLN("  YCbCr 4:2:2      : %s", ycbcr422  ? "yes" : "no");
    PRINTLN("  Native DTDs      : %u", (unsigned)native_dtds);

    if (revision < 3u || dtd_offset <= 4u) {
        PRINTLN("  (No data block collection)");
        BLANKLINE();
        return;
    }

    PRINTLN("  Data Blocks:");
    uint8_t pos = 4u;
    while (pos < dtd_offset) {
        uint8_t tag     = (blk[pos] >> 5u) & 0x07u;
        uint8_t dbc_len = blk[pos] & 0x1Fu;
        pos++;

        static const char * const tag_str[] = {
            "Reserved", "Audio", "Video", "Vendor Specific",
            "Speaker Alloc", "VESA DTC", "Reserved", "Extended"
        };
        PRINTLN("    Tag=%-18s  len=%u",
                tag_str[tag < 8u ? tag : 0u], (unsigned)dbc_len);

        if (tag == 2u) {
            iprintf("      CEA VIC codes:");
            for (uint8_t v = 0u; v < dbc_len; v++) {
                uint8_t vic = blk[pos + v] & 0x7Fu;
                bool    nat = (blk[pos + v] & 0x80u) != 0u;
                iprintf(" %u%s", (unsigned)vic, nat ? "*" : "");
            }
            putchar('\n'); next_line();
        }
        pos = (uint8_t)(pos + dbc_len);
    }

    if (dtd_offset >= 4u && dtd_offset < 127u) {
        PRINTLN("  Detailed Timings in CEA extension:");
        uint8_t p2 = dtd_offset;
        while (p2 <= (EDID_BLOCK_SIZE - 18u)) {
            const uint8_t *desc = blk + p2;
            if (desc[0] == 0u && desc[1] == 0u) break;
            uint32_t pixel_clk_khz = ((uint32_t)desc[1] << 8u | desc[0]) * 10UL;
            uint16_t h_active = (uint16_t)(desc[2] | ((desc[4] & 0xF0u) << 4u));
            uint16_t v_active = (uint16_t)(desc[5] | ((desc[7] & 0xF0u) << 4u));
            uint16_t h_blank  = (uint16_t)(desc[3] | ((desc[4] & 0x0Fu) << 8u));
            uint16_t v_blank  = (uint16_t)(desc[6] | ((desc[7] & 0x0Fu) << 8u));
            uint32_t h_total  = (uint32_t)h_active + h_blank;
            uint32_t v_total  = (uint32_t)v_active + v_blank;
            uint32_t refresh  = (h_total && v_total)
                                ? (pixel_clk_khz * 1000UL) / (h_total * v_total)
                                : 0UL;
            PRINTLN("    %ux%u @ ~%lu Hz  (clk=%lu kHz)",
                    (unsigned)h_active, (unsigned)v_active,
                    (unsigned long)refresh, (unsigned long)pixel_clk_khz);
            p2 = (uint8_t)(p2 + 18u);
        }
    }
    BLANKLINE();
}

/* -----------------------------------------------------------------------
 * Dump a block as a hex table (for debugging / raw view)
 * ----------------------------------------------------------------------- */
static void print_hex_dump(const uint8_t *blk, uint8_t block_num)
{
    PRINTLN("  Raw hex dump of block %u:", (unsigned)block_num);
    for (uint16_t row = 0u; row < EDID_BLOCK_SIZE; row += 16u) {
        iprintf("  %02X: ", (unsigned)row);
        for (uint8_t col = 0u; col < 16u; col++) {
            iprintf("%02X ", (unsigned)blk[row + col]);
            if (col == 7u) putchar(' ');
        }
        iprintf(" |");
        for (uint8_t col = 0u; col < 16u; col++) {
            uint8_t c = blk[row + col];
            putchar((c >= 0x20u && c < 0x7Fu) ? (int)c : '.');
        }
        iprintf("|\n");
        next_line();
    }
    BLANKLINE();
}

/* -----------------------------------------------------------------------
 * Main
 * ----------------------------------------------------------------------- */
int main(void)
{
    uint8_t          edid_buf[EDID_BLOCK_SIZE];
    oc_i2c_status_t  ret;
    uint8_t          ext_count;

    BLANKLINE();
    PRINTLN("============================================================");
    PRINTLN("  HDMI EDID Reader  (OpenCores I2C / NKC System)           ");
    PRINTLN("============================================================");
    PRINTLN("  I2C prescaler    : %u  (clk=%lu Hz, scl=%lu Hz)",
            (unsigned)I2C_PRESCALE,
            (unsigned long)SYS_CLK_HZ,
            (unsigned long)I2C_SCL_HZ);
    PRINTLN("  EDID I2C address : 0x%02X", (unsigned)EDID_I2C_ADDR);
    BLANKLINE();

    /* --- Initialise I2C controller ------------------------------------ */
    oc_i2c_init(I2C_PRESCALE);

    /* --- Read base block (block 0) ------------------------------------ */
    PRINTLN("Reading EDID base block (block 0)...");
    ret = edid_read_block(0u, edid_buf);
    if (ret != OC_I2C_OK) {
        print_i2c_error("block 0 read", ret);
        PRINTLN("ERROR: No EDID device found at address 0x%02X.",
                (unsigned)EDID_I2C_ADDR);
        PRINTLN("       Check DDC wiring and HDMI connection.");
        goto done;
    }

    /* --- Validate header --------------------------------------------- */
    if (!edid_header_ok(edid_buf)) {
        PRINTLN("ERROR: Invalid EDID header. Raw bytes 0-7:");
        iprintf("  ");
        for (uint8_t i = 0u; i < 8u; i++) iprintf("%02X ", edid_buf[i]);
        putchar('\n'); next_line();
        print_hex_dump(edid_buf, 0u);
        goto done;
    }

    /* --- Validate checksum ------------------------------------------- */
    if (!edid_checksum_ok(edid_buf)) {
        PRINTLN("WARNING: Base block checksum FAILED (block may be corrupt).");
    } else {
        PRINTLN("Base block checksum OK.");
    }
    BLANKLINE();

    /* --- Print decoded base block ------------------------------------ */
    print_base_block(edid_buf);
    print_hex_dump(edid_buf, 0u);

    /* --- Read extension blocks --------------------------------------- */
    ext_count = edid_buf[EDID_EXT_COUNT_OFF];
    if (ext_count > EDID_MAX_BLOCKS) {
        PRINTLN("NOTE: %u extension blocks reported; reading only first %u.",
                (unsigned)ext_count, (unsigned)EDID_MAX_BLOCKS);
        BLANKLINE();
        ext_count = EDID_MAX_BLOCKS;
    }

    for (uint8_t blk_idx = 1u; blk_idx <= ext_count; blk_idx++) {
        PRINTLN("Reading extension block %u...", (unsigned)blk_idx);
        ret = edid_read_block(blk_idx, edid_buf);
        if (ret != OC_I2C_OK) {
            print_i2c_error("extension block read", ret);
            break;
        }

        if (!edid_checksum_ok(edid_buf)) {
            PRINTLN("WARNING: Extension block %u checksum FAILED.", (unsigned)blk_idx);
        } else {
            PRINTLN("Extension block %u checksum OK.", (unsigned)blk_idx);
        }
        BLANKLINE();

        uint8_t tag = edid_buf[0];
        switch (tag) {
            case 0x02u:
                print_cea_extension(edid_buf, blk_idx);
                break;
            case 0xF0u:
                PRINTLN("Extension block %u: Block Map", (unsigned)blk_idx);
                BLANKLINE();
                break;
            default:
                PRINTLN("Extension block %u: unknown tag 0x%02X",
                        (unsigned)blk_idx, (unsigned)tag);
                BLANKLINE();
                break;
        }
        print_hex_dump(edid_buf, blk_idx);
    }

done:
    oc_i2c_disable();
    PRINTLN("Done.");
    return 0;
}