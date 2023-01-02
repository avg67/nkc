/*-
 * Copyright (C) 1991	Andreas Voggeneder
 */
/*- NKC specific signal definitions */

#ifndef _EXCEPT_H
#define _EXCEPT_H

#ifndef _HARD_SIG_FLAG
#define _HARD_SIG_FLAG 0x100
#endif

#define _HARD_SIG_CNT 0x40

#define SIGSEGV          (2 | _HARD_SIG_FLAG)
#define SIGADR           (3 | _HARD_SIG_FLAG)
#define SIGILL           (4 | _HARD_SIG_FLAG)
#define SIGDIV0          (5 | _HARD_SIG_FLAG)
#define SIGCHK           (6 | _HARD_SIG_FLAG)
#define SIGTRAPV         (7 | _HARD_SIG_FLAG)
#define SIGPRIV          (8 | _HARD_SIG_FLAG)
#define SIGTRACE         (9 | _HARD_SIG_FLAG)
#define SIGLINEA        (10 | _HARD_SIG_FLAG)
#define SIGLINEF        (11 | _HARD_SIG_FLAG)
#define SIGSPURI        (24 | _HARD_SIG_FLAG)
#define SIGAUTO1        (25 | _HARD_SIG_FLAG)
#define SIGAUTO2        (26 | _HARD_SIG_FLAG)
#define SIGAUTO3        (27 | _HARD_SIG_FLAG)
#define SIGAUTO4        (28 | _HARD_SIG_FLAG)
#define SIGAUTO5        (29 | _HARD_SIG_FLAG)
#define SIGAUTO6        (30 | _HARD_SIG_FLAG)
#define SIGAUTO7        (31 | _HARD_SIG_FLAG)
#define SIGTRAP0        (32 | _HARD_SIG_FLAG)
#define SIGTRAP1        (33 | _HARD_SIG_FLAG)
#define SIGTRAP2        (34 | _HARD_SIG_FLAG)
#define SIGTRAP3        (35 | _HARD_SIG_FLAG)
#define SIGTRAP4        (36 | _HARD_SIG_FLAG)
#define SIGTRAP5        (37 | _HARD_SIG_FLAG)
#define SIGTRAP6        (38 | _HARD_SIG_FLAG)
#define SIGTRAP7        (39 | _HARD_SIG_FLAG)
#define SIGTRAP8        (40 | _HARD_SIG_FLAG)
#define SIGTRAP9        (41 | _HARD_SIG_FLAG)
#define SIGTRAP10       (42 | _HARD_SIG_FLAG)
#define SIGTRAP11       (43 | _HARD_SIG_FLAG)
#define SIGTRAP12       (44 | _HARD_SIG_FLAG)
#define SIGTRAP13       (45 | _HARD_SIG_FLAG)
#define SIGTRAP14       (46 | _HARD_SIG_FLAG)
#define SIGTRAP15       (47 | _HARD_SIG_FLAG)
#define SIGMFP0         (48 | _HARD_SIG_FLAG)
#define SIGMFP1         (49 | _HARD_SIG_FLAG)
#define SIGMFP2         (50 | _HARD_SIG_FLAG)
#define SIGMFP3         (51 | _HARD_SIG_FLAG)
#define SIGMFP4         (52 | _HARD_SIG_FLAG)
#define SIGMFP5         (53 | _HARD_SIG_FLAG)
#define SIGMFP6         (54 | _HARD_SIG_FLAG)
#define SIGMFP7         (55 | _HARD_SIG_FLAG)
#define SIGMFP8         (56 | _HARD_SIG_FLAG)
#define SIGMFP9         (57 | _HARD_SIG_FLAG)
#define SIGMFP10        (58 | _HARD_SIG_FLAG)
#define SIGMFP11        (59 | _HARD_SIG_FLAG)
#define SIGMFP12        (60 | _HARD_SIG_FLAG)
#define SIGMFP13        (61 | _HARD_SIG_FLAG)
#define SIGMFP14        (62 | _HARD_SIG_FLAG)
#define SIGMFP15        (63 | _HARD_SIG_FLAG)
#define SIGTLXINT       SIGMFP14

#endif 
