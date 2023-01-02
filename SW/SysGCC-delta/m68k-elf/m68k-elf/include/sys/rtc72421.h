/*- RTC72421 definitions
 *
 * Copyright (C) 1991	Andreas Voggeneder
 *
 */

#ifndef RTC_PADDING
#ifdef PADDING
#define RTC_PADDING PADDING
#else
#error "padding not defined"
#endif
#endif

#if RTC_PADDING == 0
#define _(x) volatile unsigned char (x);
#else
#define _(x) unsigned char _pad_ ## x [RTC_PADDING];  volatile unsigned char (x);
#endif

typedef struct rtc72421 {
	_(sec)
	_(secd)
	_(min)
	_(mind)
	_(hour)
	_(hourd)
	_(day)
	_(dayd)
	_(mon)
	_(mond)
	_(year)
	_(yeard)
	_(week)
	_(ctld)
	_(ctle)
	_(ctlf)
    } rtc72421;


typedef struct rtc72421buf {
	unsigned char sec;
	unsigned char secd;
	unsigned char min;
	unsigned char mind;
	unsigned char hour;
	unsigned char hourd;
	unsigned char day;
	unsigned char dayd;
	unsigned char mon;
	unsigned char mond;
	unsigned char year;
	unsigned char yeard;
	unsigned char week;
    } rtc72421buf;

#undef _
