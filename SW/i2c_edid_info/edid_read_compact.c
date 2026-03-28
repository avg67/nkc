/* $Workfile:   edid_read.c $                                                  */
/* $Revision:   $                                                               */
/* $Author:     Andreas Voggeneder $                                            */
/* $Date:       12.03.2026 $                                                    */
/* Description: Read and display HDMI EDID data via OpenCores I2C              */
/*              Single-page 80x23 summary display, with color.                 */
/*                                                                              */
/* Remarks:     EDID EEPROM I2C address: 0x50 (7-bit)                          */
/*              I2C prescaler: PRESCALE = (clk_hz / (5 * scl_hz)) - 1          */

#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include "../../nkc_common/nkc/nkc.h"
#include "i2c.h"

/* -----------------------------------------------------------------------
 * Constants
 * ----------------------------------------------------------------------- */
#define EDID_I2C_ADDR      0x50u
#define EDID_BLOCK_SIZE    128u
#define EDID_MAX_BLOCKS    4u

#define SYS_CLK_HZ         40000000UL
#define I2C_SCL_HZ           100000UL
#define I2C_PRESCALE \
    ((uint16_t)((SYS_CLK_HZ / (5UL * I2C_SCL_HZ)) - 1UL))

/* Screen geometry: 80 columns (0-79), 23 rows (0-22) */
#define SCR_COLS    80u
#define SCR_ROWS    23u
#define MAX_COL     79u

/* -----------------------------------------------------------------------
 * Fixed row assignments  (23 rows: 0-22)
 * ----------------------------------------------------------------------- */
#define ROW_TOP_BORDER   0u
#define ROW_HDR1         1u
#define ROW_HDR2         2u
#define ROW_HDR3         3u
#define ROW_SEP1         4u
#define ROW_PREF_TIM     5u
#define ROW_RANGE        6u
#define ROW_MON_NAME     7u
#define ROW_MON_SN       8u
#define ROW_SEP2         9u
#define ROW_STD_TIM     10u
#define ROW_EST_TIM     11u
#define ROW_SEP3        12u
#define ROW_CEA_HDR     13u
#define ROW_CEA_VIC     14u
#define ROW_SEP4        15u
#define ROW_DT_0_1      16u
#define ROW_DT_2_3      17u
#define ROW_SEP5        18u
#define ROW_CSUM        19u
#define ROW_SEP6        20u
#define ROW_STATUS      21u
#define ROW_BOT_BORDER  22u

/* EDID base-block offsets */
#define OFF_MFR_ID        8u
#define OFF_PROD_CODE    10u
#define OFF_SERIAL_NUM   12u
#define OFF_MFR_WEEK     16u
#define OFF_MFR_YEAR     17u
#define OFF_EDID_VER     18u
#define OFF_EDID_REV     19u
#define OFF_INPUT_DEF    20u
#define OFF_H_SIZE_CM    21u
#define OFF_V_SIZE_CM    22u
#define OFF_GAMMA        23u
#define OFF_FEAT_SUPPORT 24u
#define OFF_EST_TIMINGS  35u
#define OFF_STD_TIMINGS  38u
#define OFF_DESCRIPTORS  54u
#define OFF_EXT_COUNT   126u

/* Descriptor tag bytes */
#define DESC_MONITOR_SN    0xFFu
#define DESC_DATA_STRING   0xFEu
#define DESC_RANGE_LIMITS  0xFDu
#define DESC_MONITOR_NAME  0xFCu

/* -----------------------------------------------------------------------
 * Color scheme  (BG is always BLACK – enforced via gp_setfg())
 *
 *  COL_BORDER   – frame borders and separators       CYAN
 *  COL_LABEL    – field labels ("Mfr:", "Range:", …) WHITE
 *  COL_VALUE    – decoded values                     YELLOW
 *  COL_IDENTITY – monitor name / serial string       GREEN
 *  COL_TIMING   – pixel clocks, refresh rates        MAGENTA
 *  COL_CEA      – CEA section header                 CYAN
 *  COL_VIC      – CEA VIC code numbers               YELLOW
 *  COL_VIC_NAT  – native VIC (marked with *)         GREEN
 *  COL_OK       – checksum OK / Y flags              GREEN
 *  COL_ERR      – checksum ERR / error messages      RED
 *  COL_DIM      – N flags, unused slots, n/a         GRAY|DARK
 *  COL_STATUS   – bottom status bar                  WHITE
 * ----------------------------------------------------------------------- */
#define COL_BG        BLACK
#define COL_BORDER    CYAN
#define COL_LABEL     WHITE
#define COL_VALUE     YELLOW
#define COL_IDENTITY  GREEN
#define COL_TIMING    MAGENTA
#define COL_CEA       CYAN
#define COL_VIC       YELLOW
#define COL_VIC_NAT   GREEN
#define COL_OK        GREEN
#define COL_ERR       RED
#define COL_DIM       (GRAY | DARK)
#define COL_STATUS    WHITE

/**
 * @brief  Set foreground color; background is always BLACK.
 *         Single point of truth – BG can never accidentally differ.
 */
static inline void gp_setfg(uint8_t fg)
{
    gp_setcolor(fg, COL_BG);
}

/** Reset to default label color. */
#define SET_LABEL()       gp_setfg(COL_LABEL)
/** Set a specific foreground color; BG stays BLACK. */
#define SET_COL(fg)       gp_setfg(fg)

/* -----------------------------------------------------------------------
 * Cursor-positioned helpers
 * ----------------------------------------------------------------------- */

/** Move cursor then print a plain string. Color must be set by caller. */
static void put_at(uint8_t col, uint8_t row, const char *s)
{
    gp_setcurxy(col, row);
    iprintf("%s", s);
}

/** Clear from col to column 78 with spaces (current color). */
static void clear_to_eol(uint8_t col, uint8_t row)
{
    if (col >= MAX_COL) return;
    gp_setcurxy(col, row);
    uint8_t n = (uint8_t)(MAX_COL - col);
    for (uint8_t i = 0u; i < n; i++) putchar(' ');
}

/** Move cursor then iprintf (formatted). Color must be set by caller. */
#define PRAT(col, row, ...) \
    do { gp_setcurxy((uint8_t)(col), (uint8_t)(row)); \
         iprintf(__VA_ARGS__); } while(0)

/**
 * @brief  Print a label string at (col,row) in COL_LABEL, then switch to
 *         COL_VALUE ready for the following value.
 */
#define LABEL_AT(col, row, str) \
    do { SET_COL(COL_LABEL); put_at((col), (row), (str)); \
         SET_COL(COL_VALUE); } while(0)

/* -----------------------------------------------------------------------
 * Static frame  (borders + separators)
 * ----------------------------------------------------------------------- */
static void draw_frame(void)
{
    /* 79 chars each */
    static const char eq79[] =
        "===============================================================================";
    static const char da79[] =
        "-------------------------------------------------------------------------------";

    SET_COL(COL_BORDER);
    put_at(0u, ROW_TOP_BORDER, eq79);
    put_at(0u, ROW_SEP1,       da79);
    put_at(0u, ROW_SEP2,       da79);
    put_at(0u, ROW_SEP3,       da79);
    put_at(0u, ROW_SEP4,       da79);
    put_at(0u, ROW_SEP5,       da79);
    put_at(0u, ROW_SEP6,       da79);
    put_at(0u, ROW_BOT_BORDER, eq79);
    SET_LABEL();
}

/* -----------------------------------------------------------------------
 * Print a monitor-descriptor string, padded to <width> chars.
 * Prints in COL_IDENTITY.
 * ----------------------------------------------------------------------- */
static void print_desc_str(const uint8_t *desc, uint8_t width)
{
    SET_COL(COL_IDENTITY);
    uint8_t n = 0u;
    for (uint8_t i = 5u; i < 18u && n < width; i++) {
        uint8_t c = desc[i];
        if (c == 0x0Au || c == 0x00u) break;
        if (c >= 0x20u && c < 0x7Fu) { putchar((int)c); n++; }
    }
    while (n < width) { putchar(' '); n++; }
    SET_LABEL();
}

/* -----------------------------------------------------------------------
 * Print a Y / N flag:  Y → COL_OK (green),  N → COL_DIM (dark gray)
 * ----------------------------------------------------------------------- */
static void print_yn(bool val)
{
    SET_COL(val ? COL_OK : COL_DIM);
    putchar(val ? 'Y' : 'N');
    SET_LABEL();
}

/* -----------------------------------------------------------------------
 * Decode 3-letter manufacturer ID
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
 * Integer Newton sqrt
 * ----------------------------------------------------------------------- */
static uint32_t isqrt32(uint32_t n)
{
    if (n == 0u) return 0u;
    uint32_t s = n / 2u;
    for (uint8_t k = 0u; k < 16u; k++) s = (s + n / s) / 2u;
    return s;
}

/* -----------------------------------------------------------------------
 * Block checksum
 * ----------------------------------------------------------------------- */
static bool edid_checksum_ok(const uint8_t *blk)
{
    uint8_t sum = 0u;
    for (uint16_t i = 0u; i < EDID_BLOCK_SIZE; i++)
        sum = (uint8_t)(sum + blk[i]);
    return (sum == 0u);
}

/* -----------------------------------------------------------------------
 * Read one 128-byte EDID block
 * ----------------------------------------------------------------------- */
static oc_i2c_status_t edid_read_block(uint8_t block_num, uint8_t *p_buf)
{
    uint8_t offset = (uint8_t)(block_num * EDID_BLOCK_SIZE);
    return oc_i2c_write_read(EDID_I2C_ADDR,
                             &offset, 1u, p_buf, EDID_BLOCK_SIZE);
}

/* -----------------------------------------------------------------------
 * Detailed-timing descriptor helpers
 * ----------------------------------------------------------------------- */
static uint16_t dt_hactive(const uint8_t *d)
{
    return (uint16_t)(d[2] | ((d[4] & 0xF0u) << 4u));
}
static uint16_t dt_vactive(const uint8_t *d)
{
    return (uint16_t)(d[5] | ((d[7] & 0xF0u) << 4u));
}
static uint32_t dt_clk_khz(const uint8_t *d)
{
    return ((uint32_t)d[1] << 8u | d[0]) * 10UL;
}
static uint32_t dt_refresh(const uint8_t *d)
{
    uint32_t clk  = dt_clk_khz(d);
    uint32_t htot = (uint16_t)(d[2] | ((d[4] & 0xF0u) << 4u))
                  + (uint16_t)(d[3] | ((d[4] & 0x0Fu) << 8u));
    uint32_t vtot = (uint16_t)(d[5] | ((d[7] & 0xF0u) << 4u))
                  + (uint16_t)(d[6] | ((d[7] & 0x0Fu) << 8u));
    if (htot == 0u || vtot == 0u) return 0u;
    return (clk * 1000UL) / (htot * vtot);
}

/* -----------------------------------------------------------------------
 * Print one detailed timing entry: resolution in COL_VALUE,
 * refresh in COL_TIMING, clock in COL_DIM.
 * ----------------------------------------------------------------------- */
static void print_dt(uint8_t col, uint8_t row, uint8_t idx,
                     const uint8_t *d)
{
    gp_setcurxy(col, row);
    SET_COL(COL_DIM);
    iprintf("[%u]", (unsigned)idx);
    SET_COL(COL_VALUE);
    iprintf("%ux%u", (unsigned)dt_hactive(d), (unsigned)dt_vactive(d));
    SET_COL(COL_LABEL);
    iprintf("@~");
    SET_COL(COL_TIMING);
    iprintf("%luHz", (unsigned long)dt_refresh(d));
    SET_COL(COL_LABEL);
    iprintf(" Clk:");
    SET_COL(COL_DIM);
    iprintf("%lukHz  ", (unsigned long)dt_clk_khz(d));
    SET_LABEL();
}

/* -----------------------------------------------------------------------
 * Render the 80x23 EDID summary
 * ----------------------------------------------------------------------- */
static void render_edid_summary(const uint8_t  *base,
                                const uint8_t  *ext[],
                                const bool      csum_ok[])
{
    /* ---- Decode base-block fields ------------------------------------ */
    char     mfr[4];
    decode_mfr_id(base, mfr);

    uint16_t prod = (uint16_t)(((uint16_t)base[OFF_PROD_CODE + 1u] << 8u)
                    | base[OFF_PROD_CODE]);
    uint32_t sn   = ((uint32_t)base[OFF_SERIAL_NUM + 3u] << 24u) |
                    ((uint32_t)base[OFF_SERIAL_NUM + 2u] << 16u) |
                    ((uint32_t)base[OFF_SERIAL_NUM + 1u] <<  8u) |
                     (uint32_t)base[OFF_SERIAL_NUM];
    uint8_t  week = base[OFF_MFR_WEEK];
    uint16_t year = (uint16_t)(base[OFF_MFR_YEAR] + 1990u);
    uint8_t  ver  = base[OFF_EDID_VER];
    uint8_t  rev  = base[OFF_EDID_REV];
    uint8_t  inp  = base[OFF_INPUT_DEF];
    bool     dig  = (inp & 0x80u) != 0u;
    uint8_t  hcm  = base[OFF_H_SIZE_CM];
    uint8_t  vcm  = base[OFF_V_SIZE_CM];
    uint8_t  feat = base[OFF_FEAT_SUPPORT];
    uint8_t  extc = base[OFF_EXT_COUNT];

    uint32_t diag = 0u;
    if (hcm > 0u && vcm > 0u) {
        uint32_t d2 = (uint32_t)hcm * hcm + (uint32_t)vcm * vcm;
        diag = isqrt32(d2) * 10UL / 254UL;
    }

    uint16_t gi = 0u, gf = 0u;
    bool     gnu = (base[OFF_GAMMA] == 0xFFu);
    if (!gnu) {
        uint16_t g100 = (uint16_t)(base[OFF_GAMMA] + 100u);
        gi = g100 / 100u;  gf = g100 % 100u;
    }

    static const char * const bpc_s[]   =
        { "?","6","8","10","12","14","16","?" };
    static const char * const iface_s[] =
        { "?","DVI","HDMI-a","HDMI-b","MDDI","DP","?" };
    uint8_t bpc_i   = dig ? ((inp >> 4u) & 0x07u) : 0u;
    uint8_t iface_i = dig ? ((inp & 0x0Fu) < 6u
                             ? (inp & 0x0Fu) : 6u) : 0u;

    const uint8_t *dpref  = NULL;
    const uint8_t *drange = NULL;
    const uint8_t *dname  = NULL;
    const uint8_t *dsn    = NULL;
    for (uint8_t d = 0u; d < 4u; d++) {
        const uint8_t *dp = base + OFF_DESCRIPTORS + (d * 18u);
        if (dp[0] != 0u || dp[1] != 0u) {
            if (dpref == NULL) dpref = dp;
        } else {
            switch (dp[3]) {
                case DESC_RANGE_LIMITS: drange = dp; break;
                case DESC_MONITOR_NAME: dname  = dp; break;
                case DESC_MONITOR_SN:   dsn    = dp; break;
                default: break;
            }
        }
    }

    /* ---- Draw static frame ------------------------------------------ */
    draw_frame();

    /* ==================================================================
     * ROW 1 – Mfr(green) / product(yellow) / serial(yellow)
     * ================================================================== */
    LABEL_AT(1u, ROW_HDR1, "Mfr:");
    SET_COL(COL_IDENTITY);
    iprintf("%-3s", mfr);
    LABEL_AT(6u, ROW_HDR1, "  Prod:");
    PRAT(13u, ROW_HDR1, "0x%04X", (unsigned)prod);
    LABEL_AT(19u, ROW_HDR1, "  S/N:");
    SET_COL(COL_VALUE);
    iprintf("%-10lu", (unsigned long)sn);
    clear_to_eol(37u, ROW_HDR1);

    /* ==================================================================
     * ROW 2 – EDID version / date / input type / gamma
     * ================================================================== */
    LABEL_AT(1u, ROW_HDR2, "EDID ");
    SET_COL(COL_VALUE);
    iprintf("%u.%u", (unsigned)ver, (unsigned)rev);
    SET_LABEL();
    iprintf("  ");

    if (week == 0xFFu || week == 0u) {
        iprintf("Yr:");
        SET_COL(COL_VALUE);
        iprintf("%u", (unsigned)year);
    } else {
        iprintf("Wk");
        SET_COL(COL_VALUE);
        iprintf("%02u/%u", (unsigned)week, (unsigned)year);
    }
    SET_LABEL();
    iprintf("  ");

    if (dig) {
        SET_COL(COL_VALUE);   iprintf("Digital");
        SET_LABEL();          iprintf("/");
        SET_COL(COL_VALUE);   iprintf("%s", iface_s[iface_i]);
        SET_LABEL();          iprintf("/");
        SET_COL(COL_VALUE);   iprintf("%sbpc", bpc_s[bpc_i]);
    } else {
        SET_COL(COL_VALUE);   iprintf("Analog");
    }
    SET_LABEL();

    /* Gamma right-aligned at col 65 */
    gp_setcurxy(65u, ROW_HDR2);
    iprintf("Gam:");
    if (!gnu) {
        SET_COL(COL_VALUE);
        iprintf("%u.%02u", (unsigned)gi, (unsigned)gf);
    } else {
        SET_COL(COL_DIM);
        iprintf("n/a ");
    }
    SET_LABEL();

    /* ==================================================================
     * ROW 3 – Physical size / DPMS flags / extension count
     * ================================================================== */
    gp_setcurxy(1u, ROW_HDR3);
    SET_LABEL();
    iprintf("Sz:");
    if (hcm > 0u && vcm > 0u) {
        SET_COL(COL_VALUE);
        iprintf("%ux%ucm", (unsigned)hcm, (unsigned)vcm);
        SET_LABEL();
        iprintf("(~");
        SET_COL(COL_VALUE);
        iprintf("%lu\"", (unsigned long)diag);
        SET_LABEL();
        iprintf(")");
    } else {
        SET_COL(COL_DIM);
        iprintf("n/a      ");
    }
    SET_LABEL();

    gp_setcurxy(22u, ROW_HDR3);
    iprintf("DPMS S:");  print_yn((feat & 0x80u) != 0u);
    iprintf(" U:");      print_yn((feat & 0x40u) != 0u);
    iprintf(" O:");      print_yn((feat & 0x20u) != 0u);

    gp_setcurxy(55u, ROW_HDR3);
    SET_LABEL();
    iprintf("ExtBlk:");
    SET_COL(COL_VALUE);
    iprintf("%u", (unsigned)extc);
    SET_LABEL();

    /* ==================================================================
     * ROW 5 – Preferred timing
     * ================================================================== */
    gp_setcurxy(1u, ROW_PREF_TIM);
    SET_LABEL();
    iprintf("Preferred: ");
    if (dpref != NULL) {
        SET_COL(COL_VALUE);
        iprintf("%ux%u", (unsigned)dt_hactive(dpref),
                         (unsigned)dt_vactive(dpref));
        SET_LABEL();
        iprintf("@~");
        SET_COL(COL_TIMING);
        iprintf("%luHz", (unsigned long)dt_refresh(dpref));
        SET_LABEL();
        iprintf("  Clk:");
        SET_COL(COL_DIM);
        iprintf("%lukHz", (unsigned long)dt_clk_khz(dpref));
    } else {
        SET_COL(COL_DIM);
        iprintf("n/a");
    }
    SET_LABEL();
    clear_to_eol(50u, ROW_PREF_TIM);

    /* ==================================================================
     * ROW 6 – Range limits
     * ================================================================== */
    gp_setcurxy(1u, ROW_RANGE);
    SET_LABEL();
    iprintf("Range:  ");
    if (drange != NULL) {
        iprintf("V:");
        SET_COL(COL_VALUE);
        iprintf("%u-%uHz", (unsigned)drange[5], (unsigned)drange[6]);
        SET_LABEL();
        iprintf("  H:");
        SET_COL(COL_VALUE);
        iprintf("%u-%ukHz", (unsigned)drange[7], (unsigned)drange[8]);
        SET_LABEL();
        iprintf("  MaxClk:");
        SET_COL(COL_VALUE);
        iprintf("%uMHz", (unsigned)drange[9] * 10u);
    } else {
        SET_COL(COL_DIM);
        iprintf("n/a");
    }
    SET_LABEL();
    clear_to_eol(50u, ROW_RANGE);

    /* ==================================================================
     * ROW 7 – Monitor name
     * ================================================================== */
    LABEL_AT(1u, ROW_MON_NAME, "Name:   ");
    gp_setcurxy(9u, ROW_MON_NAME);
    if (dname != NULL)
        print_desc_str(dname, 13u);
    else {
        SET_COL(COL_DIM);
        iprintf("n/a          ");
        SET_LABEL();
    }

    /* ==================================================================
     * ROW 8 – Monitor serial string
     * ================================================================== */
    LABEL_AT(1u, ROW_MON_SN, "Serial: ");
    gp_setcurxy(9u, ROW_MON_SN);
    if (dsn != NULL)
        print_desc_str(dsn, 13u);
    else {
        SET_COL(COL_DIM);
        iprintf("n/a (see S/N)");
        SET_LABEL();
    }

    /* ==================================================================
     * ROW 10 – Standard timings
     * ================================================================== */
    gp_setcurxy(1u, ROW_STD_TIM);
    SET_LABEL();
    iprintf("StdTim:");
    uint8_t col = 8u;
    for (uint8_t i = 0u; i < 8u; i++) {
        uint8_t b0 = base[OFF_STD_TIMINGS + i * 2u];
        uint8_t b1 = base[OFF_STD_TIMINGS + i * 2u + 1u];
        if (b0 == 0x01u && b1 == 0x01u) continue;
        if (col >= 71u) break;
        uint16_t hr  = (uint16_t)((b0 + 31u) * 8u);
        uint8_t  rfr = (b1 & 0x3Fu) + 60u;
        gp_setcurxy(col, ROW_STD_TIM);
        SET_COL(COL_VALUE);
        iprintf(" %ux?", (unsigned)hr);
        SET_LABEL();
        iprintf("@");
        SET_COL(COL_TIMING);
        iprintf("%u", (unsigned)rfr);
        SET_LABEL();
        col = (uint8_t)(col + 9u);
    }
    clear_to_eol(col, ROW_STD_TIM);

    /* ==================================================================
     * ROW 11 – Established timings
     * ================================================================== */
    static const char * const en[] = {
        "720x400@70","720x400@88","640x480@60","640x480@67",
        "640x480@72","640x480@75","800x600@56","800x600@60",
        "800x600@72","800x600@75","832x624@75","1024x768@87i",
        "1024x768@60","1024x768@70","1024x768@75","1280x1024@75",
        "1152x870@75"
    };
    uint32_t ebits = ((uint32_t)base[35] << 16u) |
                     ((uint32_t)base[36] <<  8u) |
                      (uint32_t)base[37];
    gp_setcurxy(1u, ROW_EST_TIM);
    SET_LABEL();
    iprintf("EstTim:");
    col = 8u;
    for (uint8_t i = 0u; i < 17u; i++) {
        if (!(ebits & (1UL << (23u - i)))) continue;
        uint8_t len = (uint8_t)strlen(en[i]);
        if ((col + 1u + len) >= MAX_COL) break;
        gp_setcurxy(col, ROW_EST_TIM);
        SET_COL(COL_VALUE);
        iprintf(" %s", en[i]);
        col = (uint8_t)(col + 1u + len);
    }
    SET_LABEL();
    clear_to_eol(col, ROW_EST_TIM);

    /* ==================================================================
     * ROW 13 – CEA extension header  /  ROW 14 – VIC codes + CEA timing
     * ================================================================== */
    if (ext[0] != NULL && ext[0][0] == 0x02u) {
        const uint8_t *cea = ext[0];
        uint8_t        rev = cea[1];
        uint8_t        dto = cea[2];
        uint8_t        flg = cea[3];

        /* Row 13 */
        gp_setcurxy(1u, ROW_CEA_HDR);
        SET_COL(COL_CEA);
        iprintf("CEA");
        SET_LABEL();
        iprintf(" Rev:");
        SET_COL(COL_VALUE);
        iprintf("%u", (unsigned)rev);
        SET_LABEL();
        iprintf(" US:");  print_yn((flg & 0x80u) != 0u);
        iprintf(" Au:");  print_yn((flg & 0x40u) != 0u);
        iprintf(" 444:"); print_yn((flg & 0x20u) != 0u);
        iprintf(" 422:"); print_yn((flg & 0x10u) != 0u);
        iprintf(" NDTD:");
        SET_COL(COL_VALUE);
        iprintf("%u", (unsigned)(flg & 0x0Fu));
        SET_LABEL();
        clear_to_eol(42u, ROW_CEA_HDR);

        /* Row 14 – VIC codes (left) */
        gp_setcurxy(1u, ROW_CEA_VIC);
        SET_LABEL();
        iprintf("VIC:");
        col = 5u;
        if (rev >= 3u && dto > 4u) {
            uint8_t pos = 4u;
            while (pos < dto) {
                uint8_t tag     = (cea[pos] >> 5u) & 0x07u;
                uint8_t dbc_len = cea[pos] & 0x1Fu;
                pos++;
                if (tag == 2u) {
                    for (uint8_t v = 0u; v < dbc_len; v++) {
                        uint8_t vic = cea[pos + v] & 0x7Fu;
                        bool    nat = (cea[pos + v] & 0x80u) != 0u;
                        uint8_t w   = (uint8_t)(vic >= 100u ? 4u :
                                                vic >=  10u ? 3u : 2u)
                                    + (nat ? 1u : 0u);
                        if ((col + w) >= 54u) break;
                        gp_setcurxy(col, ROW_CEA_VIC);
                        SET_COL(nat ? COL_VIC_NAT : COL_VIC);
                        iprintf("%u%s ", (unsigned)vic, nat ? "*" : "");
                        col = (uint8_t)(col + w);
                    }
                }
                pos = (uint8_t)(pos + dbc_len);
            }
        }
        SET_LABEL();
        clear_to_eol(col, ROW_CEA_VIC);

        /* Row 14 – first CEA timing (right half, col 57) */
        if (dto >= 4u && dto < 127u) {
            const uint8_t *dp = cea + dto;
            if (dp[0] != 0u || dp[1] != 0u) {
                gp_setcurxy(57u, ROW_CEA_VIC);
                SET_LABEL();
                iprintf("Tim:");
                SET_COL(COL_VALUE);
                iprintf("%ux%u", (unsigned)dt_hactive(dp),
                                 (unsigned)dt_vactive(dp));
                SET_LABEL();
                iprintf("@~");
                SET_COL(COL_TIMING);
                iprintf("%luHz   ", (unsigned long)dt_refresh(dp));
                SET_LABEL();
            } else {
                gp_setcurxy(57u, ROW_CEA_VIC);
                SET_COL(COL_DIM);
                iprintf("Tim:n/a              ");
                SET_LABEL();
            }
        } else {
            gp_setcurxy(57u, ROW_CEA_VIC);
            SET_COL(COL_DIM);
            iprintf("Tim:n/a              ");
            SET_LABEL();
        }

    } else {
        /* No CEA extension */
        gp_setcurxy(1u, ROW_CEA_HDR);
        SET_COL(COL_DIM);
        iprintf("CEA extension: none");
        SET_LABEL();
        clear_to_eol(20u, ROW_CEA_HDR);
        clear_to_eol(1u,  ROW_CEA_VIC);
    }

    /* ==================================================================
     * ROWs 16-17 – Detailed timings  (up to 4, two per row)
     * ================================================================== */
    const uint8_t *dt[4] = { NULL, NULL, NULL, NULL };
    uint8_t dt_cnt = 0u;

    for (uint8_t d = 0u; d < 4u && dt_cnt < 4u; d++) {
        const uint8_t *dp = base + OFF_DESCRIPTORS + (d * 18u);
        if (dp[0] != 0u || dp[1] != 0u) dt[dt_cnt++] = dp;
    }
    if (ext[0] != NULL && ext[0][0] == 0x02u) {
        uint8_t dto = ext[0][2];
        if (dto >= 4u && dto < 127u) {
            uint8_t p2 = dto;
            while (p2 <= (EDID_BLOCK_SIZE - 18u) && dt_cnt < 4u) {
                const uint8_t *dp = ext[0] + p2;
                if (dp[0] == 0u && dp[1] == 0u) break;
                dt[dt_cnt++] = dp;
                p2 = (uint8_t)(p2 + 18u);
            }
        }
    }

    for (uint8_t row_off = 0u; row_off < 2u; row_off++) {
        uint8_t row = (uint8_t)(ROW_DT_0_1 + row_off);
        for (uint8_t ci = 0u; ci < 2u; ci++) {
            uint8_t n  = (uint8_t)(row_off * 2u + ci);
            uint8_t cx = (ci == 0u) ? 1u : 40u;
            if (n < dt_cnt && dt[n] != NULL) {
                print_dt(cx, row, n, dt[n]);
            } else {
                gp_setcurxy(cx, row);
                SET_COL(COL_DIM);
                iprintf("[%u] ---                       ", (unsigned)n);
                SET_LABEL();
            }
        }
    }

    /* ==================================================================
     * ROW 19 – Checksums
     * ================================================================== */
    gp_setcurxy(1u, ROW_CSUM);
    SET_LABEL();
    iprintf("Chksum base:");
    SET_COL(csum_ok[0] ? COL_OK : COL_ERR);
    iprintf("%s", csum_ok[0] ? "OK " : "ERR");
    SET_LABEL();
    for (uint8_t i = 0u; i < EDID_MAX_BLOCKS && ext[i] != NULL; i++) {
        gp_setcurxy((uint8_t)(15u + i * 9u), ROW_CSUM);
        iprintf(" ext%u:", (unsigned)(i + 1u));
        SET_COL(csum_ok[i + 1u] ? COL_OK : COL_ERR);
        iprintf("%s", csum_ok[i + 1u] ? "OK " : "ERR");
        SET_LABEL();
    }

    /* ==================================================================
     * ROW 21 – Status bar  (blue background, white text)
     * ================================================================== */
    gp_setcolor(COL_STATUS, BLUE);   /* only place BG != BLACK */
    gp_setcurxy(0u, ROW_STATUS);
    /* Flood entire row with blue BG first */
    for (uint8_t i = 0u; i < MAX_COL; i++) putchar(' ');
    PRAT(1u,  ROW_STATUS, "Press any key to exit");
    PRAT(59u, ROW_STATUS, "EDID Reader v1.0 NKC");
    /* Restore black BG for any subsequent output */
    SET_LABEL();
}

/* -----------------------------------------------------------------------
 * Main
 * ----------------------------------------------------------------------- */
int main(void)
{
    static uint8_t  blk[1u + EDID_MAX_BLOCKS][EDID_BLOCK_SIZE];
    const  uint8_t *ext_ptr[EDID_MAX_BLOCKS + 1u]; /* NULL-terminated */
    bool            csum_ok[1u + EDID_MAX_BLOCKS];
    uint8_t         ext_count = 0u;
    oc_i2c_status_t ret;

   setvbuf(stdin, NULL, _IONBF, 0);
   setvbuf(stdout, NULL, _IONBF, 0);
   setvbuf(stderr, NULL, _IONBF, 0);
    gp_clearscreen();
    gp_setflip(10u,0u);
    gp_cursor_on();
    memset(ext_ptr, 0, sizeof(ext_ptr));
    memset(csum_ok, 0, sizeof(csum_ok));

    oc_i2c_init(I2C_PRESCALE);

    /* --- Read & validate base block ---------------------------------- */
    ret = edid_read_block(0u, blk[0]);
    if (ret != OC_I2C_OK) {
        gp_setfg(COL_ERR);
        gp_setcurxy(0u, 0u);
        iprintf("I2C error reading EDID base block (%d)", (int)ret);
        SET_LABEL();
        oc_i2c_disable();
        return 1;
    }

    static const uint8_t hdr[8] = {
        0x00u,0xFFu,0xFFu,0xFFu,0xFFu,0xFFu,0xFFu,0x00u
    };
    if (memcmp(blk[0], hdr, 8u) != 0) {
        gp_setfg(COL_ERR);
        gp_setcurxy(0u, 0u);
        iprintf("Invalid EDID header at I2C addr 0x%02X",
                (unsigned)EDID_I2C_ADDR);
        SET_LABEL();
        oc_i2c_disable();
        return 1;
    }

    csum_ok[0] = edid_checksum_ok(blk[0]);
    ext_count  = blk[0][OFF_EXT_COUNT];
    if (ext_count > EDID_MAX_BLOCKS) ext_count = EDID_MAX_BLOCKS;

    /* --- Read extension blocks -------------------------------------- */
    for (uint8_t i = 0u; i < ext_count; i++) {
        ret = edid_read_block((uint8_t)(i + 1u), blk[i + 1u]);
        if (ret != OC_I2C_OK) break;
        csum_ok[i + 1u] = edid_checksum_ok(blk[i + 1u]);
        ext_ptr[i]      = blk[i + 1u];
    }

    oc_i2c_disable();

    /* --- Render & wait -------------------------------------------- */
    gp_setcurxy(0u, 0u);
    render_edid_summary(blk[0], ext_ptr, csum_ok);

    (void)gp_ci();

    /* Restore clean state for whatever runs next */
    SET_LABEL();
    return 0;
}