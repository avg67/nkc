
/***************************************************************************
 *                                  _   _ ____  _
 *  Project                     ___| | | |  _ \| |
 *                             / __| | | | |_) | |
 *                            | (__| |_| |  _ <| |___
 *                             \___|\___/|_| \_\_____|
 *
 * Copyright (C) 1998 - 2004, Daniel Stenberg, <daniel@haxx.se>, et al.
 *
 * This software is licensed as described in the file COPYING, which
 * you should have received as part of this distribution. The terms
 * are also available at http://curl.haxx.se/docs/copyright.html.
 *
 * You may opt to use, copy, modify, merge, publish, distribute and/or sell
 * copies of the Software, and permit persons to whom the Software is
 * furnished to do so, under the terms of the COPYING file.
 *
 * This software is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY
 * KIND, either express or implied.
 *
 * $Id: base64.c,v 1.31 2004/06/24 11:54:11 bagder Exp $
 ***************************************************************************/

/* Base64 encoding/decoding
 *
 * Test harnesses down the bottom - compile with -DTEST_ENCODE for
 * a program that will read in raw data from stdin and write out
 * a base64-encoded version to stdout, and the length returned by the
 * encoding function to stderr. Compile with -DTEST_DECODE for a program that
 * will go the other way.
 *
 * This code will break if int is smaller than 32 bits
 */

//#include "setup.h"

#include <stdlib.h>
#include <string.h>


//#include "base64.h"
//#include "memory.h"

/* include memdebug.h last */
//#include "memdebug.h"


static void decodeQuantum(unsigned char *dest, const char *src)
{
  unsigned long x = 0;
  unsigned char i;
  for(i = 0; i < 4; i++) {
    if(src[i] >= 'A' && src[i] <= 'Z')
      x = (x << 6) + (unsigned int)(src[i] - 'A' + 0);
    else if(src[i] >= 'a' && src[i] <= 'z')
      x = (x << 6) + (unsigned int)(src[i] - 'a' + 26);
    else if(src[i] >= '0' && src[i] <= '9')
      x = (x << 6) + (unsigned int)(src[i] - '0' + 52);
    else if(src[i] == '+')
      x = (x << 6) + 62;
    else if(src[i] == '/')
      x = (x << 6) + 63;
    else if(src[i] == '=')
      x = (x << 6);
  }

  dest[2] = (unsigned char)(x & 255);
  x >>= 8;
  dest[1] = (unsigned char)(x & 255);
  x >>= 8;
  dest[0] = (unsigned char)(x & 255);
}

/*
 * Curl_base64_decode()
 *
 * Given a base64 string at src, decode it into the memory pointed to by
 * dest. Returns the length of the decoded data.
 */
size_t Curl_base64_decode(const char *src, char *dest)
{
  unsigned char length = 0;
  unsigned char equalsTerm = 0;
  unsigned char i;
  unsigned char numQuantums;
   unsigned char lastQuantum[3];
  size_t rawlen=0;

  while((src[length] != '=') && src[length])
    length++;
  while(src[length+equalsTerm] == '=')
    equalsTerm++;

  numQuantums = (length + equalsTerm) / 4;

  rawlen = ((int)numQuantums * 3) - equalsTerm;

  for(i = 0; i < numQuantums - 1; i++) {
    decodeQuantum((unsigned char  *)dest, src);
    dest += 3; src += 4;
  }

  decodeQuantum(lastQuantum, src);
  for(i = 0; i < 3 - equalsTerm; i++)
    dest[i] = lastQuantum[i];

  return rawlen;
}

/* ---- Base64 Encoding --- */
/*char code table64[]=
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
*/

/*
 * Curl_base64_encode()
 *
 * Returns the length of the newly created base64 string. The third argument
 * is a pointer to an allocated area holding the base64 data. If something
 * went wrong, -1 is returned.
 *
 */
/*size_t Curl_base64_encode(const char *inp, size_t insize, char **outptr)
{
  unsigned char ibuf[3];
  unsigned char obuf[4];
  int i;
  int inputparts;
  char *output;
  char *base64data;

  char *indata = (char *)inp;

  *outptr = NULL; // set to NULL in case of failure before we reach the end

  if(0 == insize)
    insize = strlen(indata);

  base64data = output = (char*)malloc(insize*4/3+4);
  if(NULL == output)
    return 0;

  while(insize > 0) {
    for (i = inputparts = 0; i < 3; i++) {
      if(insize > 0) {
        inputparts++;
        ibuf[i] = *indata;
        indata++;
        insize--;
      }
      else
        ibuf[i] = 0;
    }

    obuf [0] = (ibuf [0] & 0xFC) >> 2;
    obuf [1] = ((ibuf [0] & 0x03) << 4) | ((ibuf [1] & 0xF0) >> 4);
    obuf [2] = ((ibuf [1] & 0x0F) << 2) | ((ibuf [2] & 0xC0) >> 6);
    obuf [3] = ibuf [2] & 0x3F;

    switch(inputparts) {
    case 1: // only one byte read
      snprintf(output, 5, "%c%c==",
               table64[obuf[0]],
               table64[obuf[1]]);
      break;
    case 2: // two bytes read
      snprintf(output, 5, "%c%c%c=",
               table64[obuf[0]],
               table64[obuf[1]],
               table64[obuf[2]]);
      break;
    default:
      snprintf(output, 5, "%c%c%c%c",
               table64[obuf[0]],
               table64[obuf[1]],
               table64[obuf[2]],
               table64[obuf[3]] );
      break;
    }
    output += 4;
  }
  *output=0;
  *outptr = base64data; // make it return the actual data memory

  return strlen(base64data); // return the length of the new data
}*/
/* ---- End of Base64 Encoding ---- */







