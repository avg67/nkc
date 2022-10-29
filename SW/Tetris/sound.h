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
#include <stdbool.h>
#include <ndrcomp/target.h>

#define NOTE_TIME (CLOCKS_PER_SEC*80/1000)
extern bool g_sound_mute;

void initSound(void);
//void playDrop(void);
void playTest(void);
void play_note(const bool init);

#endif