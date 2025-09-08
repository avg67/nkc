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

static inline __attribute__((always_inline)) void setSoundRegister(uint8_t reg, uint8_t value) {
  SOUND.cmd0 = reg;
  SOUND.cmd1 = value;
}

void initSound(void);
void playDrop(void);
void silence(void);

#endif