*-----------------------------------------------------------
* Title      : 68k Homebrew ROM Monitor
* Written by : Hayden Kroepfl (ChartreuseK)
* Date       : August 24th 2015
* Description: A simple ROM monitor for my homebrew 68k
*              breadboard computer.
*-----------------------------------------------------------
*
* To make this responsive to different terminal widths we need to change the number of bytes printed
* on a line from 16, which fits exactly on a 72 column screen, to an ammount based on a formula.
*  Sizes: 
*   Address:      "000000: " 8
*   Each Byte:    "00 "      3
*   Start ASCII:  "|"        1
*   Each ASCII:   "."        1
*   End ASCII:    "|"        1
*
*   Width = 8 + numBytes*(3 + 1) + 2
*   numBytes = (Width - 10)/4 = (Width - 10)>>2
*  Examples:
*    (80 - 10)/4 = 70/4 = 16 Bytes
*    (40 - 10)/4 = 30/4 =  7 Bytes
*    (32 - 10)/4 = 22/4 =  5 Bytes
* On small screens we should not show the start and end characters on the ASCII section
* 40 Characters wide or less
*    (40 - 8)/4  = 32/4 =  8 Bytes
*    (32 - 8)/4  = 24/4 =  6 Bytes



**********************************
* Defines
*
; CRC Polynomial
POLY equ $1021  ; CCITT CRC16 Polynomial
CPU equ 2
DRAM_START EQU 0
DRAM_END EQU $100000

RAM_START           equ     (DRAM_END-$4000) ;$00000 ;
RAM_END             equ     DRAM_END ;$04000 ;
VAR_START           equ     RAM_END-1024
MAX_LINE_LENGTH     equ     80

MIN_BS equ 64
MAX_BS equ 1024
MAX_HEADER equ 27
MAGIC_PATT equ $deadbeef
buffer equ $400



SER_CHK_ERR MACRO 
        btst.b #2,ser_stat      ; lange Adresse
        bne err2
    ENDM

*********************************
* 68681 Duart Register Addresses
*
*DUART equ $1C0000       * Base Addr of DUART
*MRA   equ DUART+0       * Mode Register A           (R/W)
*SRA   equ DUART+2       * Status Register A         (r)
*CSRA  equ DUART+2       * Clock Select Register A   (w)
*CRA   equ DUART+4       * Commands Register A       (w)
*RBA   equ DUART+6       * Receiver Buffer A         (r)
*TBA   equ DUART+6       * Transmitter Buffer A      (w)
*ACR   equ DUART+8       * Aux. Control Register     (R/W)
*ISR   equ DUART+10      * Interrupt Status Register (R)
*IMR   equ DUART+10      * Interrupt Mask Register   (W)
*MRB   equ DUART+16      * Mode Register B           (R/W)
*SRB   equ DUART+18      * Status Register B         (R)
*CSRB  equ DUART+18      * Clock Select Register B   (W)
*CRB   equ DUART+20      * Commands Register B       (W)
*RBB   equ DUART+22      * Reciever Buffer B         (R)
*TBB   equ DUART+22      * Transmitter Buffer B      (W)
*IVR   equ DUART+24      * Interrupt Vector Register (R/W)

*********************************
* 6851 Uart Register Addresses
ser_base equ $fffffff0          ; lange Adressen
ser_data equ (ser_base)*CPU
ser_stat equ (ser_base+1)*CPU
ser_cmd equ  (ser_base+2)*CPU
ser_ctrl equ (ser_base+3)*CPU

GPIO_SFR_BASE EQU $ffffff00*CPU
FLASH_START EQU $100000
EIGHTK_SECTORS EQU 8

CTRL_BR115200 equ $13    ; 115200 Baud
CTRL_BR57600 equ $14    ; GDP-FPGA only

DEBUG equ 0

**********************************
* ASCII Control Characters
*
BEL   equ $07
BKSP  equ $08       * CTRL-H
TAB   equ $09
LF    equ $0A
CR    equ $0D
ESC   equ $1B

CTRLC	EQU	$03     
CTRLX	EQU	$18     * Line Clear


**********************************
* Variables
*
varCurAddr  equ     RAM_END-4                        * Last address accessed
varLineBuf  equ     varCurAddr-MAX_LINE_LENGTH-2     * Line buffer

     org VAR_START
header:
hdr_len: ds.w 1         ;2
hdr_code: ds.b 1        ;1
hdr_bs: ds.b 1          ;1      Block size
hdr_fs: ds.l 1          ;4      File Size
hdr_fn: ds.b 16         ;16     Name
;hdr_crc: ds.b 2

con_stat: ds.b 1

bytes_read: ds.l 1        ; bytes_read
crc_buffer: ds.w 256

  IFNE DEBUG
len_debug: ds.w 1
crc_debug: ds.w 1
ser_debug: dc.b 1
status_debug: dc.b 1
  endc
magic_pattern: dc.l 1
flash_info: ds.l 4 
varLast     equ VAR_START-4


**********************************
* Defines 2 
*
STACK_START         equ     varLast



**** PROGRAM STARTS HERE ****
    
    ORG     $800000
    
**** FIRST 8 bytes loaded after reset ****
    DC.l    STACK_START  * Supervisor stack pointer
    DC.l    START        * Initial PC    
    
    
********************************************
* Cold start entry point
*
START:
    lea     STACK_START, SP     * Set our stack pointer to be sure
     move.b #$ff,GPIO_SFR_BASE.w
     move.b #$FF,(GPIO_SFR_BASE+2).w
    
;    lea header,a0
;    move.w #$14,(a0)+
;    move.b #'H',(a0)+
;    addq.l #1,a0
;    ;move.l #$63E8,(a0)
;    move.l #263000,(a0)
    
;    move.w #$ffff,d0
;    bsr fill_buffer

    
;    bsr fileWrite


;     move.b (GPIO_SFR_BASE+4).w,d0
   
;    lea $400,a1
    lea FLASH_START,a0
    move.l (a0)+,d0
    move.l (a0),d1

;    move.l #$00980098,($55*4,a0)
;    move.l ($20*2,a0),(a1)+
;    move.l ($22*2,a0),(a1)+
;    move.l ($24*2,a0),(a1)+
    
;    move.l ($4e*2,a0),(a1)+    ; Device size = 2^n
;    move.l #$00F000F0,($55*4,a0)
    
;    move.l #$12345678,(a0)
    bsr init_vector
    bsr initDuart           * Setup the serial port

;    move.w #80,d0
;    bsr fill_buffer

;    lea FLASH_START,a0
;;    bsr erase_flash
;;    bsr erase_sectors
;    clr.l d0    ; Sector 0
;    moveq #20,d1   ; 20 words
;    lea buffer,a1
;    bsr write_flash
********************************************
* Simple Ram Readback Test
*    
ramCheck:
;    bra.s .loop
;    bra.s monitorStart
;    bra.s monitorLine
    
    move.l #MAGIC_PATT,d1
    lea magic_pattern,A1
    cmp.l (a1),d1
    beq.s .skip

    lea     msgRamCheck(pc), A0
    bsr.w   printString

    lea     RAM_START, A2
 .loop:
    move.b  #$AA, (A2)   * First test with 10101010
;    cmp.b   #$AA, (A2)
    move.b (a2),d0
    cmp.b   #$AA, d0
    bne.s   .fail
    move.b  #$55, (A2)   * Then with 01010101
;    cmp.b   #$55, (A2)
    move.b (a2),d0
    cmp.b #$55,d0
    bne.s   .fail
    move.b  #$00, (A2)   * And finally clear the memory
    move.b (a2)+,d0
    cmp.b #$00,d0
;    cmp.b   #$00, (A2)+  * And move to the next byte
    bne.s   .fail 
    cmp.l   #RAM_END, A2  
    blt.s   .loop        * While we're still below the end of ram to check
    bra.s   .succ
 .fail:                  * One of the bytes of RAM failed to readback test
    lea     msgRamFail(pc), A0
    bsr.w   printString
    move.l  A2, D0
    bsr.w   printHexLong * Print out the address that failed
    bsr.w   printNewline
 .haltloop:              * Sit forever in the halt loop
    bra.s   .haltloop
 .succ:                  * All bytes passed the readback test
    move.l d1,(a1)
    lea     msgRamPass(pc), A0
    bsr.w   printString
.skip
;    move.b #$01,(GPIO_SFR_BASE+2).w


**************************************************
* Warm Restart entry point
*
monitorStart:
    lea     msgBanner(pc), A0   * Show our banner
    bsr.w   printString
    lea     msgHelp(pc),   A0   * And the command help message
    bsr.w   printString

monitorLine:                * Our main monitor loop
    lea     msgPrompt(pc), a0   * Prompt
    bsr.w   printString
;    move.b #$01,(GPIO_SFR_BASE+2).w

;m1:
    bsr.w   readLine        * Read in the line
;    move.b #$02,(GPIO_SFR_BASE+2).w

    bsr.w   lineToUpper     * Convert to upper-case for ease of parsing
;    move.b #$03,(GPIO_SFR_BASE+2).w

;    lea     varLineBuf, a0
;    bsr     printString

    bsr.w   parseLine       * Then parse and respond to the line
    
    bra.s   monitorLine
    
    
    
    
***************************************
* Converts input line to uppercase
lineToUpper:
    lea     varLineBuf, a0   * Get the start of the line buffer
uppercase:
    move.l d0, -(sp)
 .loop:
    move.b  (a0), d0         * Read in a character
;    move.b  d0,(GPIO_SFR_BASE+2).w
    cmp.b   #'a', d0         
    blt.s   .next            * Is it less than lower-case 'a', then move on
    cmp.b   #'z', d0
    bgt.s   .next            * Is it greater than lower-case 'z', then move on
    sub.b   #$20, d0         * Then convert a to A, b to B, etc.
 .next:
    move.b  d0, (a0)+        * Store the character back into a0, and move to the next
    bne.s   .loop            * Keep going till we hit a null terminator
    move.l (sp)+,d0
    rts


***************************************
* Parse Line
parseLine:
    movem.l a2-a3, -(SP)        * Save registers
    lea     varLineBuf, a0
 .findCommand:
    move.b  (a0)+, d0
    cmp.b   #' ', d0            * Ignore spaces
    beq.w   .findCommand    
    cmp.b   #'E', d0            * Examine command
    beq.w   .examine
    cmp.b   #'D', d0            * Deposit command
    beq.w   .deposit
    cmp.b   #'R', d0            * Run command
    beq.w   .run
    cmp.b   #'H', d0            * Help command
    beq.w   .help
    cmp.b   #'W', d0            * Download
    beq    bootload
    cmp.b   #'I', d0            * Info Command
    beq    fileInfo             * Print Info about downloaded file
    cmp.b   #'F',d0             * Write downloaded programm to flash
    beq    fileWrite
    cmp.b   #0, d0              * Ignore blank lines
    beq.s   .exit               
 .invalid:   
    lea     msgInvalidCommand(pc), a0
    bsr.w   printString
;exit_w:
 .exit:
    movem.l (SP)+, a2-a3        * Restore registers
    rts

**********************
* Examines memory addresses
* Valid modes:
*   e ADDR                  Displays a single byte
*   e ADDR-ADDR             Dispalys all bytes between the two addresses
*   e ADDR+LEN              Dispays LEN bytes after ADDR
*   e ADDR;                 Interactive mode, space shows 16 lines, enter shows 1.
*   e ADDR.                 Quick line, displays one line 
 .examine:
    bsr.w   parseNumber         * Read in the start address
    tst.b   d1                  * Make sure it's valid (parseNumber returns non-zero in d1 for failure)
    bne.w   .invalidAddr        
    move.l  d0, a3              * Save the start address
 .exloop:
    move.b  (a0)+, d0
    cmp.b   #' ', d0            * Ignore spaces
    beq.s   .exloop
    cmp.b   #'-', d0            * Check if it's a range specifier
    beq.s   .exrange
    cmp.b   #'+', d0            * Check if it's a length specifier
    beq.s   .exlength
    cmp.b   #';', d0            * Check if we're going interactive
    beq.s   .exinter
    cmp.b   #'.', d0            * Check if quick 16 
    beq.s   .exquick
    move.l  #1, d0              * Otherwise read in a single byte
    bra.s   .exend              
 .exrange:
    bsr.w   parseNumber         * Find the end address
    tst.b   d1                  * Check if we found a valid address
    bne.w   .invalidAddr
    sub.l   a3, d0              * Get the length
    bra.s   .exend
 .exquick:                      * Quick mode means show one line of 16 bytes
    move.l  #$10, d0
    bra.s   .exend
 .exlength:                     * Length mode means a length is specified
    bsr.w   parseNumber         * Find the length
    tst.b   d1
    bne.w   .invalidAddr
 .exend:                        * We're done parsing, give the parameters to dumpRAM and exit
    move.l  a3, a0
    bsr.w   dumpRAM
    bra.s   .exit
 .exinter:                      * Interactive mode, Space shows 16 lines, enter shows 1.
    move.l  a3, a0              * Current Address
    move.l  #$10, d0            * 16 bytes
    bsr.w   dumpRAM             * Dump this line
    add.l   #$10, a3            * Move up the current address 16 bytes
 .exinterend:
    bsr.w   inChar
    cmp.b   #CR, d0             * Display another line
    beq.s   .exinter
    cmp.b   #' ', d0            * Display a page (256 bytes at a time)
    beq.s   .exinterpage
    bra.s   .exit               * Otherwise exit
 .exinterpage:
    move.l  a3, a0
    move.l  #$100, d0           * 256 bytes
    bsr.w   dumpRAM             * Dump 16 lines of RAM
    add.l   #$100, a3           * Move up the current address by 256
    bra.s   .exinterend

****************************************
* Deposit values into RAM
* d ADDR VAL VAL            Deposit value(s) into RAM
* d ADDR VAL VAL;           Deposit values, continue with values on next line
*  VAL VAL VAL;              - Continuing with further continue
* d: VAL VAL                Continue depositing values after the last address written to
 .deposit:
    move.b  (a0), d0
    cmp.b   #':', d0            * Check if we want to continue from last
    beq.s   .depCont
    
    bsr.w   parseNumber         * Otherwise read the address
    tst.b   d1
    bne.s   .invalidAddr
    move.l  d0, a3              * Save the start address
 .depLoop:
    move.b  (a0), d0            
    cmp.b   #';', d0            * Check for continue
    beq.s   .depMultiline
    tst     d0                  * Check for the end of line
    beq     .depEnd
    
    bsr.s   parseNumber         * Otherwise read a value
    tst.b   d1
    bne.s   .invalidVal
    cmp.w   #255, d0            * Make sure it's a byte
    bgt.s   .invalidVal
    
    move.b  d0, (a3)+           * Store the value into memory
    bra.s   .depLoop
    
 .depCont:
    move.l  varCurAddr, a3      * Read in the last address 
    addq.l  #1, a0              * Skip over the ':'
    bra.s   .depLoop
    
 .depMultiline:
    lea     msgDepositPrompt(pc), a0
    bsr.w   printString
    bsr.w   readLine            * Read in the next line to be parsed
    bsr.w   lineToUpper         * Convert to uppercase
    lea     varLineBuf, a0      * Reset our buffer pointer
    bra.s   .depLoop            * And jump back to decoding
 .depEnd:
    move.l  a3, varCurAddr
    bra.w   .exit
****************************************
* 
 .run:
    bsr.w   parseNumber         * Otherwise read the address
    tst.b   d1
    bne.s   .invalidAddr
    move.l  d0, a0
    jsr     (a0)                * Jump to the code! 
                                * Go as subroutine to allow code to return to us
;    jsr          monitorStart        * Warm start after returning so everything is in
    bra .exit
                                * a known state.
    
 .help:
    lea     msgHelp(pc), a0
    bsr.w   printString
    bra.w   .exit
 .invalidAddr:
    lea     msgInvalidAddress(pc), a0
    bsr.w   printString
    bra.w   .exit
 .invalidVal:
    lea     msgInvalidValue(pc), a0
    bsr.w   printString
    bra.w   .exit
    
    
**************************************
* Find and parse a hex number
*  Starting address in A0
*  Number returned in D0
*  Status in D1   (0 success, 1 fail)
*  TODO: Try and merge first digit code with remaining digit code
parseNumber:
    eor.l   d0, d0           * Zero out d0
    move.b  (a0)+, d0
    cmp.b   #' ', d0         * Ignore all leading spaces
    beq.s   parseNumber
    cmp.b   #'0', d0         * Look for hex digits 0-9
    blt.s   .invalid
    cmp.b   #'9', d0
    ble.s   .firstdigit1

    cmp.b   #'A', d0         * Look for hex digits A-F
    blt.s   .invalid    
    cmp.b   #'F', d0
    ble.s   .firstdigit2
 .invalid:
    move.l  #1, d1          * Invalid character, mark failure and return
    rts
 .firstdigit2:
    sub.b   #'7', d0        * Turn 'A' to 10
    bra.s   .loop
 .firstdigit1:
    sub.b   #'0', d0        * Turn '0' to 0
 .loop:
    move.b  (a0)+, d1       * Read in a digit
    cmp.b   #'0', d1        * Look for hex digits 0-9
    blt.s   .end            * Any other characters mean we're done reading
    cmp.b   #'9', d1
    ble.s   .digit1
    cmp.b   #'A', d1        * Look for hex digits A-F
    blt.s   .end
    cmp.b   #'F', d1
    ble.s   .digit2

.end:                       * We hit a non-hex digit character, we're done parsing
    subq.l  #1, a0          * Move the pointer back before the end character we read
    move.l  #0, d1
    rts
 .digit2:
    sub.b   #'7', d1        * Turn 'A' to 10
    bra.s   .digit3
 .digit1:
    sub.b   #'0', d1        * Turn '0' to 0
 .digit3:
    lsl.l   #4, d0          * Shift over to the next nybble
    add.b   d1, d0          * Place in our current nybble (could be or.b instead)
    bra.s   .loop
    
    
****************************************
* Dumps a section of RAM to the screen
* Displays both hex values and ASCII characters
* d0 - Number of bytes to dump
* a0 - Start Address
dumpRAM:
    movem.l d2-d4/a2, -(SP)  * Save registers
    move.l  a0, a2           * Save the start address
    move.l  d0, d2           * And the number of bytes
 .line:
    move.l  a2, d0          
    bsr.w   printHexAddr     * Starting address of this line
    lea     msgColonSpace(pc), a0
    bsr.w   printString
    move.l  #16, d3          * 16 Bytes can be printed on a line
    move.l  d3, d4           * Save number of bytes on this line
 .hexbyte:
    tst.l   d2               * Check if we're out of bytes
    beq.s   .endbytesShort
    tst.b   d3               * Check if we're done this line
    beq.s   .endbytes    
    move.b  (a2)+, d0        * Read a byte in from RAM
    bsr.w   printHexByte     * Display it
    move.b  #' ', d0
    bsr.w   outChar          * Space out bytes
    subq.l  #1, d3    
    subq.l  #1, d2        
    bra.s   .hexbyte
 .endbytesShort:
    sub.b   d3, d4           * Make d4 the actual number of bytes on this line
    move.b  #' ', d0
 .endbytesShortLoop:
    tst.b   d3               * Check if we ended the line
    beq.s   .endbytes
    move.b  #' ', d0
    bsr.w   outChar          * Three spaces to pad out
    move.b  #' ', d0
    bsr.w   outChar
    move.b  #' ', d0
    bsr.w   outChar
    
    subq.b  #1, d3
    bra.s   .endbytesShortLoop
 .endbytes:
    suba.l  d4, a2           * Return to the start address of this line
 .endbytesLoop:
    tst.b   d4               * Check if we're done printing ascii
    beq     .endline    
    subq.b  #1, d4
    move.b  (a2)+, d0        * Read the byte again
    cmp.b   #' ', d0         * Lowest printable character
    blt.s   .unprintable
    cmp.b   #'~', d0         * Highest printable character
    bgt.s   .unprintable
    bsr.w   outChar
    bra.s   .endbytesLoop
 .unprintable:
    move.b  #'.', d0
    bsr.w   outChar
    bra.s   .endbytesLoop
 .endline:
    lea     msgNewline(pc), a0
    bsr.w   printString
    tst.l   d2
    ble.s   .end
    bra.w   .line
 .end:
    movem.l (SP)+, d2-d4/a2  * Restore registers
    rts
    
    
        
    
******
* Read in a line into the line buffer
readLine:
    movem.l d2/a2, -(SP)     * Save changed registers
    lea     varLineBuf, a2   * Start of the lineBuffer
    eor.w   d2, d2           * Clear the character counter
 .loop:
    bsr.w   inChar           * Read a character from the serial port
    cmp.b   #BKSP, d0        * Is it a backspace?
    beq.s   .backspace
    cmp.b   #CTRLX, d0       * Is it Ctrl-H (Line Clear)?
    beq.s   .lineclear
    cmp.b   #CR, d0          * Is it a carriage return?
    beq.s   .endline
    cmp.b   #LF, d0          * Is it anything else but a LF?
    beq.s   .loop            * Ignore LFs and get the next character
 .char:                      * Normal character to be inserted into the buffer
    cmp.w   #MAX_LINE_LENGTH, d2
    bge.s   .loop            * If the buffer is full ignore the character
    move.b  d0, (a2)+        * Otherwise store the character
    addq.w  #1, d2           * Increment character count
    bsr.w   outChar          * Echo the character
    bra.s   .loop            * And get the next one
 .backspace:
    tst.w   d2               * Are we at the beginning of the line?
    beq.s   .loop            * Then ignore it
    bsr.w   outChar          * Backspace
    move.b  #' ', d0
    bsr.w   outChar          * Space
    move.b  #BKSP, d0
    bsr.w   outChar          * Backspace
    subq.l  #1, a2           * Move back in the buffer
    subq.l  #1, d2           * And current character count
    bra.s   .loop            * And goto the next character
 .lineclear:
    tst     d2               * Anything to clear?
    beq.s   .loop            * If not, fetch the next character
    suba.l  d2, a2           * Return to the start of the buffer
 .lineclearloop:
    move.b  #BKSP, d0
    bsr.w   outChar          * Backspace
    move.b  #' ', d0
    bsr.w   outChar          * Space
    move.b  #BKSP, d0
    bsr.w   outChar          * Backspace
    subq.w  #1, d2          
    bne.s   .lineclearloop   * Go till the start of the line
    bra.s   .loop   
 .endline:
    bsr.w   outChar          * Echo the CR
    move.b  #LF, d0
    bsr.w   outChar          * Line feed to be safe
    move.b  #0, (a2)         * Terminate the line (Buffer is longer than max to allow this at full length)
    movea.l a2, a0           * Ready the pointer to return (if needed)
    
    movem.l (SP)+, d2/a2     * Restore registers
    rts                      * And return




    
******
* Prints a newline (CR, LF)
printNewline:
    lea     msgNewline(pc), a0
******
* Print a null terminated string
*
printString:
 .loop:
    move.b  (a0)+, d0    * Read in character
    beq.s   .end         * Check for the null
    
    bsr.s   outChar      * Otherwise write the character
    bra.s   .loop        * And continue
 .end:
    rts

** KEEP All printHex functions together **
******
* Print a hex word
printHexWord:
    move.l  d2, -(SP)    * Save D2
    move.l  d0, d2       * Save the address in d2
    
    rol.l   #8, d2       * 4321 -> 3214
    rol.l   #8, d2       * 3214 -> 2143 
    bra.s   printHex_wordentry  * Print out the last 16 bits
*****
* Print a hex 24-bit address
printHexAddr:
    move.l d2, -(SP)     * Save D2
    move.l d0, d2          * Save the address in d2
    
    rol.l   #8, d2       * 4321 -> 3214
    bra.s   printHex_addrentry  * Print out the last 24 bits
******
* Print a hex long
printHexLong:
    move.l  d2, -(SP)     * Save D2
    move.l  d0, d2        * Save the address in d2
    
    rol.l   #8, d2        * 4321 -> 3214 high byte in low
    move.l  d2, d0
    bsr.s   printHexByte  * Print the high byte (24-31)
printHex_addrentry:     
    rol.l   #8, d2        * 3214 -> 2143 middle-high byte in low
    move.l  d2, d0              
    bsr.s   printHexByte  * Print the high-middle byte (16-23)
printHex_wordentry:    
    rol.l   #8, d2        * 2143 -> 1432 Middle byte in low
    move.l  d2, d0
    bsr.s   printHexByte  * Print the middle byte (8-15)
    rol.l   #8, d2
    move.l  d2, d0
    bsr.s   printHexByte  * Print the low byte (0-7)
    
    move.l (SP)+, d2      * Restore D2
    RTS
    
******
* Print a hex byte
*  - Takes byte in D0
printHexByte:
    move.l  D2, -(SP)
    move.b  D0, D2
    lsr.b   #$4, D0
    add.b   #'0', D0
    cmp.b   #'9', D0     * Check if the hex number was from 0-9
    ble.s   .second
    add.b   #7, D0       * Shift 0xA-0xF from ':' to 'A'
.second:
    bsr.s   outChar      * Print the digit
    andi.b  #$0F, D2     * Now we want the lower digit Mask only the lower digit
    add.b   #'0', D2
    cmp.b   #'9', D2     * Same as before    
    ble.s   .end
    add.b   #7, D2
.end:
    move.b  D2, D0
    bsr.s   outChar      * Print the lower digit
    move.l  (SP)+, D2
    rts
    
    
    
    
    
    
*****
* Writes a character to Port A, blocking if not ready (Full buffer)
*  - Takes a character in D0
ser_so:
outChar:
*    btst    #2, SRA      * Check if transmitter ready bit is set
*    beq     outChar     
*    move.b  d0, TBA      * Transmit Character
*    rts
    btst.b #4,ser_stat      ; lange Adresse
    beq.s outChar
    move.b d0,ser_data      ; lange Adresse
    rts

*****
* Reads in a character from Port A, blocking if none available
*  - Returns character in D0
*    
ser_si
inChar:
*    btst    #0,  SRA     * Check if receiver ready bit is set
*    beq     inChar
*    move.b  RBA, d0      * Read Character into D0
*    rts
    btst.b #3,ser_stat      ; lange Adresse
    beq.s inChar
    move.b ser_data,d0      ; lange Adresse
;    move.b d0,(GPIO_SFR_BASE+2).w
    rts
*****
* Initializes the 68681 DUART port A as 9600 8N1 
initDuart:
*    move.b  #$30, CRA       * Reset Transmitter
*    move.b  #$20, CRA       * Reset Reciever
*    move.b  #$10, CRA       * Reset Mode Register Pointer
*    
*    move.b  #$80, ACR       * Baud Rate Set #2
*    move.b  #$BB, CSRA      * Set Tx and Rx rates to 9600
*    move.b  #$93, MRA       * 7-bit, No Parity ($93 for 8-bit, $92 for 7-bit)
*    move.b  #$07, MRA       * Normal Mode, Not CTS/RTS, 1 stop bit
*    
*    move.b  #$05, CRA       * Enable Transmit/Recieve
*    rts    
    move.b #CTRL_BR57600,ser_ctrl.w
    move.b #$0B, ser_cmd.w
    move.b ser_ctrl.w,d0
    move.b ser_cmd.w,d1
    rts

init_vector:
    lea $00000008,a0
    move.w #($100-2-1),d7
    lea default_handler(pc),a1
.m1: move.l a1,(a0)+
    dbra d7,.m1
    rts
    
default_handler:
        move.b #$7F,(GPIO_SFR_BASE+2).w
.m1:    bra.s .m1


init_crc: lea crc_buffer,a1

        clr.w d0        ; set b to 0
i1:     move.w d0,d1
        lsl.w #8,d1
        moveq #7,d7
i2:     lsl.w #1,d1
        bcc.s i3
        eor.w #POLY,d1
i3:     dbra d7,i2
        move.w d1,(a1)+
        addq.w #1,d0
        cmp.w #256,d0
        bne.s i1
        lea crc_buffer,a1
        rts

; A1 has to point to CRC_TAB
; d0.b contains byte
; d1.w contains crc
upd_crc: move.w d1,d2
        lsl.w #8,d1
        lsr.w #8,d2
        eor.b d0,d2
        lsl.w #1,d2
        move.w 0(a1,d2.w),d2
        eor.w d2,d1
        rts

; if D0.b=0 -> ACK otherwise NACK
ack_nack:
        move.b #'O',d1
        tst.b d0
        beq.s an_ok
        move.b #'N',d1
an_ok:  exg d1,d0
        bsr ser_so
        exg d1,d0
        rts

rx_header: lea header,a0
        lea crc_buffer,a1
        moveq #$FF,d1   ; init CRC
        ; 1. Length (two byte)
        moveq #1,d6
hdr1:
;        btst.b #2,ser_stat
;        bne.s err2
        SER_CHK_ERR

        bsr ser_si

        bsr upd_crc
        lsl.w #8,d3
        or.b d0,d3
        dbra d6,hdr1
        cmp.w #MAX_HEADER,d3
        bhi.s err1
        move.w d3,(a0)+
        subq.w #4,d3
        move.w d3,d6

        ; 2. Header opcode 'H'
;        btst.b #2,ser_stat
;        bne.s err2
        SER_CHK_ERR

        bsr ser_si
        bsr upd_crc
        cmp.b #'H',d0
        bne.s err1
        move.b d0,(a0)+

rx1:
;        btst.b #2,ser_stat
;        bne.s err2
        SER_CHK_ERR

        bsr ser_si
        move.b d0,(a0)+     ; Block size
        bsr upd_crc
        dbra d6,rx1
  IFNE DEBUG
        move.w d1, crc_debug
  ENDC        
        moveq #0, d0        ; status ok
        tst.w d1
        beq.s rx_crc_ok
        addq.b #1,d0    ; Indicate an error
rx_crc_ok:
        lea hdr_fn,a0
        bsr uppercase         ; Upper Case
  IFNE DEBUG        
        move.b d0,status_debug
  ENDC
        rts
err1:   moveq #1,d0
  IFNE DEBUG
        move.b d0, status_debug
  ENDC
        rts
err2:   moveq #2,d0    ; Overflow occured
  IFNE DEBUG
        move.b d0,status_debug
  ENDC
        rts

; A0 points to buffer
; A2 points to function to print status info. Ignored if null
; nr of bytes received in D4
rx_frame:
        lea crc_buffer,a1
  IFNE DEBUG
        clr.w len_debug
  ENDC

        moveq #5,d7        ; max. retries
frame2:
        ; 1. Length (two byte)
        moveq #1,d6
        moveq #$FF,d1           ; init CRC
        movea.l a0,a5           ; backup A0 in A5
frame1:
;        btst.b #2,ser_stat      ; abort in case of an overflow
;        bne.s err2
        SER_CHK_ERR

        bsr ser_si

        bsr upd_crc
  IFNE DEBUG        
        move.w d1, crc_debug
  ENDC
        lsl.w #8,d3
        or.b d0,d3      ; store len in d3
        dbra d6,frame1
  IFNE DEBUG        
        move.w d3,len_debug
  ENDC

        move.b hdr_bs,d0    ; check against Blocksize
        lsl.w #8,d0
        subq.w #4,d3            ; - header - crc
        cmp.w d0,d3
        bls.s rx_ok1            ; abort transfer in case of an size error
        moveq #1,d0
        bsr ack_nack            ; NACK
        bra.s err1           ; abort transfer -> not recoverable
rx_ok1:

;        move.w d3,(a0)+

        move.w d3,d4            ; store len in D4
        move.w d3,d6
        subq.w #1,d6            ; correct for dbra

rx2:
;        btst.b #2,ser_stat
;        bne.s err2
        SER_CHK_ERR

        bsr ser_si
        move.b d0,(a0)+
        bsr upd_crc
  IFNE DEBUG        
        move.w d1, crc_debug
  ENDC
        dbra d6,rx2
        ; Now read 2 bytes CRC
        moveq #1,d6
f_crc:
;        btst.b #2,ser_stat      ; abort in case of an overflow
;        bne.s err2
        SER_CHK_ERR

        bsr ser_si
        move.b d0,(a0)+

        bsr upd_crc
        dbra d6,f_crc
  IFNE DEBUG
        move.w d1, crc_debug
  ENDC
        tst.w d1        ; CRC should be zero now if everything is OK
        beq.s f_crc_ok

        ;; add progress status here
        move.l a2,d0
        tst.l d0
        beq.s np1
        moveq #'!',d0
        jsr (a2)        ; print progress
np1:    moveq #1,d0
        bsr ack_nack
        movea.l a5,a0   ; Restore A0
        dbra d7,frame2  ; Retry in case of an CRC error
        rts             ; max retries reached
f_crc_ok:
        subq.l #2,a0
        move.l a2,d0
        tst.l d0
        beq.s no_progress
        moveq #'.',d0   ; print progress
        jsr (a2)
no_progress:        
        moveq #0,d0
        bsr ack_nack
        rts

bootload:
        bsr init_crc
        moveq #$ff,d1
        move.b #$01,d0
        bsr upd_crc
        


wait_cmd:
        move.b #$fe,(GPIO_SFR_BASE+2).w
        moveq #'?',d0
        bsr ser_so
m2:     btst.b #3,ser_stat      ; Byte received?
        beq.s m2
        bsr ser_si
b1:     cmp.b #'X',d0
        beq rx_done
        cmp.b #'D',d0
        bne.s wait_cmd
        
        move.b #$3,(GPIO_SFR_BASE+2).w

        moveq #'O',d0
        bsr ser_so

        bsr rx_header   ; d0=0 -> OK; 1 -> Err; 2 -> Overflow
        tst.b d0
        bne.s rx_fail
        ; Success -> Print Message before ACKing
;        lea rx_msg(pc),a0
        lea hdr_fn,a1
        move.l hdr_fs,d5
;        bsr print_info
;        moveq #1,d0
;        bsr pr_crlf
        bra.s rx_payload
rx_fail:
        ; Failure -> Print error Message
;        lea err_str_table(pc),a0
;        bsr pr_err
        moveq #1,d0
        bsr ack_nack
        bra wait_cmd

;err_str_table:
;        dc.l rx_err
;        dc.l overflow

rx_payload:
        clr.b d0
        bsr ack_nack
        lea bytes_read,a3
        lea hdr_fs,a4
        lea buffer,a0
        clr.l (a3)
        lea progress(pc),a2
;        lea 0,a2
rx_loop:
        bsr rx_frame  ; nr of bytes in D4.w afterwards
        tst.b d0
        bne.s rx_fail
        ext.l d4
        move.l (a3),d0
        add.l d4,d0     ; add to bytes aready received
        move.l d0,(a3)
        cmp.l (a4),d0   ; Compare against filesize d0-(a4)
        blo.s rx_loop

rx_done:
        ;movem.l (SP)+, d2-d4/a2  * Restore registers
        movem.l (SP)+, a2-a3
        move.b #$ff,(GPIO_SFR_BASE+2).w
        rts
;        bra exit_w

progress:
    move.b (GPIO_SFR_BASE+2).w,d0
    not.b d0
    addq.b #1,d0
    not.b d0
    move.b d0,(GPIO_SFR_BASE+2).w
    rts

; Z-flag=1 -> Pass
checkFile:
        lea header,a0
        ;cmp.w #$14,(a0)+
        tst.w (a0)+         ; Length must be > 0
        beq.s .cf1
        cmp.b #'H',(a0)     ; Header ID valid?
        rts
.cf1:   andi #$fb,ccr       ; Clear Z
        rts


fileInfo:
        bsr.s checkFile
        bne.s exit
        addq.l #2,a0
        move.l (a0)+,d1     ; File-size
        bsr printString     ; Print file-name
        lea msgLen(pc),a0
        bsr printString       
        move.l d1,d0
        bsr printHexLong    ; Print length in Hex
        lea     msgNewline(pc), a0
        bsr     printString

exit:
        movem.l (SP)+, a2-a3        * Restore registers
        rts
        
        
fileWrite:
        bsr.s checkFile
        bne.s exit
        add.l #2,a0 
        move.l (a0),d1     ; File-size
        move.l d1,d2
        lsr.l #2,d2         ; /4 -> # dwords
                            ; Check if the length is not dividable by 4
        and.b #$03,d1
        beq.s .fw2
        addq.l #1,d2    ; add one word if not
.fw2:
    ; D2 has now # of DWORDS to write

        clr.l d0            ; Start with Sector 0
        lea FLASH_START,a0
        lea buffer,a1
        move.l #(8192 / 2),d4   ; (8192*2)/4
        moveq #$fe,d6

.fw3:        
        bsr erase_flash   ; Erase sector first
        ; estimate sector length
        move.l d4,d1    ; 8192
        cmp.w #(EIGHTK_SECTORS),d0
        blo.s .fw1
        lsl.l #3,d1     ; * 8
        ; D1... Current sector-length (# DWORDS)
        
.fw1:
        move.l d1,d3
        cmp.l d3,d2     ; Compare sector length with remaining file length
        bhs.s .fw4
        move.l d2,d1    ; copy remaining length to block-size
.fw4:
        bsr write_flash
        addq.w #1,d0    ; Next sector
        move.b d6,(GPIO_SFR_BASE+2).w
        rol.b #1,d6

        
        sub.l d1,d2
        bne.s .fw3
        move.b #$ff,(GPIO_SFR_BASE+2).w

        bra exit        
        
        
        



; ****************************************************

; D0.w size
;fill_buffer:
;    subq.w #1,d0
;    clr.w d1
;    lea buffer,a0
;.f1:
;    move.w d1,(a0)+
;    addq.w #1,d1
;    dbra d0,.f1
;    rts


FLASH_ERASE: 
    move.b #$00,(GPIO_SFR_BASE+2).w
    lea FLASH_START,a0
    bsr.s query_flash
    moveq #7,d0
    bsr.s erase_sectors
    rts

;FLASH_WRITE:
;    move.w #80,d0
;    bsr.s fill_buffer
;    lea FLASH_START,a0
;    clr.l d0    ; Sector 0
;    moveq #20,d1   ; 20 words
;    lea buffer,a1
;    bsr write_flash
;    rts


; D0.w sector-nr
; Returns offset address in D0.l
get_sector_base:
    cmp.w #EIGHTK_SECTORS,d0
    bhs.s .gs1
    mulu #8,d0
    bra.s .gs2
.gs1:
    sub.w #EIGHTK_SECTORS,d0
    mulu #64,d0
    add.w #(EIGHTK_SECTORS*8),d0
.gs2:
    lsl.l #8,d0
    lsl.l #(11 - 8),d0  ; * 1024
    rts     

; A0 needs to point to Flash-start
query_flash:
    lea flash_info,a1
    move.l #$00980098,($55*4,a0)
    move.l ($20*2,a0),(a1)+
    move.l ($22*2,a0),(a1)+
    move.l ($24*2,a0),(a1)+
   
    move.l ($4e*2,a0),(a1)+    ; Device size = 2^n
    move.l #$00F000F0,($55*4,a0) ; Flash-Reset
    rts
;    move.l #$12345678,(a0)

; d0.w number of sectors to erase (0 - n)
erase_sectors:
    movem.l d1/d7,-(sp)
    move.w d0,d7
    subq.w #1,d7
    clr.l d0
    moveq #$fe,d1
.e1:    
    move.b d1,(GPIO_SFR_BASE+2).w
    rol.b #1,d1
    bsr.s erase_flash
    addq.w #1,d0
    dbra d7, .e1

    movem.l (sp)+,d1/d7
    rts

; D0.l sector_nr
; D0.w = 0xffff -> whole chip
; A0 needs to point to Flash-start
erase_flash:
;    lea FLASH_START,a0
    movem.l d0-d3,-(sp)
    move.w #$555*4,d1
    move.w #$2AA*4,d2
    move.l #$00AA00AA,(0,a0,d1.w) ; ($555*2,a0)   ; 1.
    move.l #$00550055,(0,a0,d2.w) ; ($2AA*2,a0)   ; 2.
    move.l #$00800080,(0,a0,d1.w) ; ($555*2,a0)   ; 3.
    move.l #$00AA00AA,(0,a0,d1.w) ; ($555*2,a0)   ; 4.
    move.l #$00550055,(0,a0,d2.w) ; ($2AA*2,a0)   ; 5.
    cmp.w #$ffff,d0
    beq.s .e_full
    bsr.w get_sector_base
;    moveq #11,d3
;    lsl.l d3,d0
    
    move.l #$00300030,(0,a0,d0.l)
    bra.s .e_done
    
.e_full:
    move.l #$00100010,(0,a0,d1.w) ; ($555*2,a0)

.e_done
.w1    
    move.b (GPIO_SFR_BASE+4).w,d0
    and.b #3,d0
    cmp.b #3,d0
    bne.s .w1

    move.w #$ff,d0
.w2:
    dbra d0,.w2
    move.l #$00F000F0,($55*4,a0) ; Flash-Reset
    movem.l (sp)+,d0-d3
    rts

; A0 needs to point to Flash-start
; A1 needs to point to data
; D1.w length of data (# of DWORDS)
; D0.l Flash block-nr
; Write Data in 16 word chunks
write_flash:
    movem.l d0-d4/d7/a2,-(sp)
    move.w #$555*4,d3
    move.w #$2AA*4,d2
    bsr.w get_sector_base
    movea.l a0,a2
    adda.l d0,a2
    move.w d1,d7    ; copy # words to d7
    subq.w #1,d7    ; adjust for dbra

.wf2:
    move.l #$00AA00AA,(0,a0,d3.w) ; ($555*2,a0)   ; 1.
    move.l #$00550055,(0,a0,d2.w) ; ($2AA*2,a0)   ; 2.
    move.l #$00A000A0,(0,a0,d3.w) ; ($555*2,a0)   ; 3.
    
    move.l (a1)+,d0
    move.l d0,(a2)

.wf3:    
    move.b (GPIO_SFR_BASE+4).w,d4
    and.b #3,d4
    cmp.b #3,d4
    bne.s .wf3
    
    cmp.l (a2),d0
    bne.s .wf3
    addq.l #4,a2    ; next write address
    dbra d7,.wf2    

    movem.l (sp)+,d0-d4/d7/a2
    rts

**********************************
* Strings
*
msgBanner:
    dc.b CR,LF,'Chartreuse''s 68000 ROM Monitor',CR,LF
    dc.b       '==============================',CR,LF,0
msgHelp:
    dc.b 'Available Commands: ',CR,LF
    dc.b ' (E)xamine    (D)eposit    (R)un     (H)elp     (I)Info',CR,LF,0
msgDepositPrompt:
    dc.b ': ',0
msgPrompt:
    dc.b '> ',0
msgInvalidCommand:
    dc.b 'Invalid Command',CR,LF,0
msgInvalidAddress:
    dc.b 'Invalid Address',CR,LF,0
msgInvalidValue:
    dc.b 'Invalid Value',CR,LF,0
msgRamCheck:
    dc.b 'Checking RAM...',CR,LF,0
msgRamFail:
    dc.b 'Failed at: ',0
msgRamPass:
    dc.b 'Passed.',CR,LF,0
msgNewline:
    dc.b CR,LF,0
msgColonSpace:
    dc.b ': ',0
msgTermWidth:
    dc.b 'Term Width? ',0
msgLen: 
    dc.b ' Length: ',0
    





    END    START            * last line of source









*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
