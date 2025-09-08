#ifndef FXM_H
#define FXM_H

#include <stdint.h>

// fxm must point to the program memory
void fxm_init(const uint8_t *fxm);
void fxm_loop();

#endif

