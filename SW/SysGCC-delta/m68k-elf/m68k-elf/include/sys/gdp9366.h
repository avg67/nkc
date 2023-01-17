/*- GDP 9366 definitions
 *
 * Copyright (C) 1991	Andreas Voggeneder
 *
 */
/*-
 * Date		Version	Action						Who
 * 12.02.1991	1.00	created						avg
 */

#ifndef GDP_PADDING
#ifdef PADDING
#define GDP_PADDING PADDING
#else
#error "padding not defined"
#endif
#endif

#if GDP_PADDING == 0
#define _(x) volatile unsigned char (x);
#else
#define _(x) volatile unsigned char (x); unsigned char _pad_ ## x [GDP_PADDING]; // 16bit-bus (CPU==2)
#endif
// CMD-Register - Sign bits for Line command
#define SX_BIT 2u
#define SY_BIT 4u

typedef struct gdp {
    _(cmd)
    _(ctrl1)
    _(ctrl2)
    _(csize)
    _(deltax_h)
    _(deltax)
    _(deltay_h)
    _(deltay)
    _(xh)
    _(xl)
    _(yh)
    _(yl)
    _(xlp)
    _(ylp)
    _(res3)
    _(res4)
} GDP9366;

typedef struct {
    _(fg)
    _(bg)
} GDP_Col;

typedef struct {
    _(page_dma)   // Write: Page+XOR; Read: DMA
    _(hscroll)    // Write: scroll; Read: -
} GDP_Page;

typedef struct {
    _(color_idx)
    _(color_h)
    _(color_l)
} GDP_Clut;

#undef _
