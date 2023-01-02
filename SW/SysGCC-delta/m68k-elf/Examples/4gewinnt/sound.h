/*- FPGA_Timer definitions
 *
 * Copyright (C) 1991	Andreas Voggeneder
 */
/*-
 * Date		Version	Action						Who
 * 12.02.1991	1.00	created				    avg
 */
#ifndef SOUND_H
#define SOUND_H

#include <stdint.h>
#include <ndrcomp/target.h>

void initSound(void);
void playDrop(void);

#endif