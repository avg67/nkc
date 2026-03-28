{ =========================================================================
  $Workfile:   I2C.PAS $
  $Revision:   $
  $Author:     Andreas Voggeneder $
  $Date:       12.03.2026 $
  Description: OpenCores I2C routines - Turbo Pascal 2 compatible
  Remarks:     - No units (TP2 has no unit system; include with {$I I2C.PAS})
               - Port addresses start at $08
               - All types restricted to TP2 built-ins
  ========================================================================= }

{ -----------------------------------------------------------------------
  Return codes  (Integer replaces ShortInt / enum)
  ----------------------------------------------------------------------- }
const
  OC_I2C_OK           =  0;
  OC_I2C_ERR_NACK     = -1;
  OC_I2C_ERR_BUSY     = -2;
  OC_I2C_ERR_ARB      = -3;
  OC_I2C_ERR_TIMEOUT  = -4;

{ -----------------------------------------------------------------------
  Port addresses  (base $08)
  ----------------------------------------------------------------------- }
  I2C_BASE   = $08;

  PORT_CR    = I2C_BASE + 0;   { $08  Command register       }
  PORT_PRERL = I2C_BASE + 1;   { $09  Prescaler low          }
  PORT_PRERH = I2C_BASE + 2;   { $0A  Prescaler high         }
  PORT_CTR   = I2C_BASE + 3;   { $0B  Control register       }
  PORT_TXR   = I2C_BASE + 4;   { $0C  Transmit register      }
  PORT_RXR   = I2C_BASE + 5;   { $0D  Receive register       }
  PORT_SR    = I2C_BASE + 6;   { $0E  Status register        }

{ -----------------------------------------------------------------------
  Control Register Bits (CTR)
  ----------------------------------------------------------------------- }
  OC_I2C_CTR_EN  = $80;
  OC_I2C_CTR_IEN = $40;

{ -----------------------------------------------------------------------
  Command Register Bits (CR)
  ----------------------------------------------------------------------- }
  OC_I2C_CR_STA  = $80;
  OC_I2C_CR_STO  = $40;
  OC_I2C_CR_RD   = $20;
  OC_I2C_CR_WR   = $10;
  OC_I2C_CR_ACK  = $08;
  OC_I2C_CR_IACK = $01;

{ -----------------------------------------------------------------------
  Status Register Bits (SR)
  ----------------------------------------------------------------------- }
  OC_I2C_SR_RXACK = $80;
  OC_I2C_SR_BUSY  = $40;
  OC_I2C_SR_AL    = $20;
  OC_I2C_SR_TIP   = $02;
  OC_I2C_SR_IF    = $01;

  OC_I2C_TIMEOUT_CYCLES = 1000;

{ -----------------------------------------------------------------------
  I/O helper macros
  Register access via Mem[0:port_address] byte reads/writes.
  Segment 0 maps directly to the I/O address space on this target;
  adjust the segment value if your memory map differs.
  ----------------------------------------------------------------------- }
{ Write byte to port }
procedure PortWrite(PortAddr : Integer; Value : Byte);
begin
  Port[PortAddr] := Value;
end;

{ Read byte from port }
function PortRead(PortAddr : Integer) : Byte;
begin
  PortRead := Port[PortAddr];
end;

{ =======================================================================
  Internal helpers
  ======================================================================= }

function WaitForTip : Integer;
var
  Timeout : Integer;
begin
  Timeout := OC_I2C_TIMEOUT_CYCLES;
  while (PortRead(PORT_SR) and OC_I2C_SR_TIP) <> 0 do
  begin
    Timeout := Timeout - 1;
    if Timeout = 0 then
    begin
      WaitForTip := OC_I2C_ERR_TIMEOUT;
      Exit;
    end;
  end;
  WaitForTip := OC_I2C_OK;
end;

function WaitForBusFree : Integer;
var
  Timeout : Integer;
begin
  Timeout := OC_I2C_TIMEOUT_CYCLES;
  while (PortRead(PORT_SR) and OC_I2C_SR_BUSY) <> 0 do
  begin
    Timeout := Timeout - 1;
    if Timeout = 0 then
    begin
      WaitForBusFree := OC_I2C_ERR_TIMEOUT;
      Exit;
    end;
  end;
  WaitForBusFree := OC_I2C_OK;
end;

function TransmitByte(ByteVal : Byte; Cmd : Byte) : Integer;
begin
  PortWrite(PORT_TXR, ByteVal);
  PortWrite(PORT_CR,  Cmd);
  TransmitByte := WaitForTip;
end;

function ReceiveByte(var ByteVal : Byte; Cmd : Byte) : Integer;
var
  Ret : Integer;
begin
  PortWrite(PORT_CR, Cmd);
  Ret := WaitForTip;
  if Ret <> OC_I2C_OK then
  begin
    ReceiveByte := Ret;
    Exit;
  end;
  ByteVal     := PortRead(PORT_RXR);
  ReceiveByte := OC_I2C_OK;
end;

{ =======================================================================
  Public API
  ======================================================================= }

procedure OcI2cInit(PrescaleLo : Byte; PrescaleHi : Byte);
begin
  PortWrite(PORT_CTR,   $00);
  PortWrite(PORT_PRERL, PrescaleLo);
  PortWrite(PORT_PRERH, PrescaleHi);
  PortWrite(PORT_CTR,   OC_I2C_CTR_EN);
end;

procedure OcI2cDisable;
begin
  PortWrite(PORT_CTR, $00);
end;

{ OcI2cWrite: pData is a Byte array passed by reference.
  Caller declares:  var Buf : array[0..N] of Byte;
  and calls:        OcI2cWrite(addr, Buf, N+1, result); }
procedure OcI2cWrite(Addr : Byte; var pData : Byte;
                     Len : Integer; var Status : Integer);
var
  Ret     : Integer;
  Cmd     : Byte;
  i       : Integer;
  DataPtr : ^Byte;
begin
  Status := OC_I2C_OK;

  { START + address (write: R/W=0) }
  Ret := TransmitByte(Byte(Addr * 2), OC_I2C_CR_STA or OC_I2C_CR_WR);
  if Ret <> OC_I2C_OK then begin Status := Ret; Exit; end;
  if (PortRead(PORT_SR) and OC_I2C_SR_RXACK) <> 0 then
  begin Status := OC_I2C_ERR_NACK; Exit; end;

  DataPtr := Addr(pData);
  for i := 0 to Len - 1 do
  begin
    Cmd := OC_I2C_CR_WR;
    if i = (Len - 1) then Cmd := Cmd or OC_I2C_CR_STO;
    Ret := TransmitByte(DataPtr^, Cmd);
    DataPtr := Ptr(Seg(DataPtr^), Ofs(DataPtr^) + 1);
    if Ret <> OC_I2C_OK then begin Status := Ret; Exit; end;
    if (PortRead(PORT_SR) and OC_I2C_SR_RXACK) <> 0 then
    begin Status := OC_I2C_ERR_NACK; Exit; end;
  end;
end;

procedure OcI2cRead(Addr : Byte; var pData : Byte;
                    Len : Integer; var Status : Integer);
var
  Ret     : Integer;
  Cmd     : Byte;
  i       : Integer;
  DataPtr : ^Byte;
  B       : Byte;
begin
  Status := OC_I2C_OK;

  { START + address (read: R/W=1) }
  Ret := TransmitByte(Byte((Addr * 2) or $01), OC_I2C_CR_STA or OC_I2C_CR_WR);
  if Ret <> OC_I2C_OK then begin Status := Ret; Exit; end;
  if (PortRead(PORT_SR) and OC_I2C_SR_RXACK) <> 0 then
  begin Status := OC_I2C_ERR_NACK; Exit; end;

  DataPtr := Addr(pData);
  for i := 0 to Len - 1 do
  begin
    Cmd := OC_I2C_CR_RD;
    if i = (Len - 1) then Cmd := Cmd or OC_I2C_CR_ACK or OC_I2C_CR_STO;
    Ret := ReceiveByte(B, Cmd);
    DataPtr^ := B;
    DataPtr  := Ptr(Seg(DataPtr^), Ofs(DataPtr^) + 1);
    if Ret <> OC_I2C_OK then begin Status := Ret; Exit; end;
  end;
end;

procedure OcI2cWriteRead(Addr    : Byte;
                         var pWrData : Byte; WrLen : Integer;
                         var pRdData : Byte; RdLen : Integer;
                         var Status  : Integer);
var
  Ret     : Integer;
  Cmd     : Byte;
  i       : Integer;
  WrPtr   : ^Byte;
  RdPtr   : ^Byte;
  B       : Byte;
begin
  Status := OC_I2C_OK;

  { START + address (write) }
  Ret := TransmitByte(Byte(Addr * 2), OC_I2C_CR_STA or OC_I2C_CR_WR);
  if Ret <> OC_I2C_OK then begin Status := Ret; Exit; end;
  if (PortRead(PORT_SR) and OC_I2C_SR_RXACK) <> 0 then
  begin Status := OC_I2C_ERR_NACK; Exit; end;

  { Write phase - no STOP }
  WrPtr := Addr(pWrData);
  for i := 0 to WrLen - 1 do
  begin
    Ret := TransmitByte(WrPtr^, OC_I2C_CR_WR);
    WrPtr := Ptr(Seg(WrPtr^), Ofs(WrPtr^) + 1);
    if Ret <> OC_I2C_OK then begin Status := Ret; Exit; end;
    if (PortRead(PORT_SR) and OC_I2C_SR_RXACK) <> 0 then
    begin Status := OC_I2C_ERR_NACK; Exit; end;
  end;

  { Repeated START + address (read) }
  Ret := TransmitByte(Byte((Addr * 2) or $01), OC_I2C_CR_STA or OC_I2C_CR_WR);
  if Ret <> OC_I2C_OK then begin Status := Ret; Exit; end;
  if (PortRead(PORT_SR) and OC_I2C_SR_RXACK) <> 0 then
  begin Status := OC_I2C_ERR_NACK; Exit; end;

  { Read phase }
  RdPtr := Addr(pRdData);
  for i := 0 to RdLen - 1 do
  begin
    Cmd := OC_I2C_CR_RD;
    if i = (RdLen - 1) then Cmd := Cmd or OC_I2C_CR_ACK or OC_I2C_CR_STO;
    Ret := ReceiveByte(B, Cmd);
    RdPtr^ := B;
    RdPtr  := Ptr(Seg(RdPtr^), Ofs(RdPtr^) + 1);
    if Ret <> OC_I2C_OK then begin Status := Ret; Exit; end;
  end;
end;

procedure OcI2cScan(var pFound    : Byte;
                    FoundMax      : Byte;
                    var pFoundCnt : Byte;
                    var Status    : Integer);
var
  Ret      : Integer;
  Addr     : Byte;
  SR       : Byte;
  GotNack  : Boolean;
  FoundPtr : ^Byte;
begin
  pFoundCnt := 0;
  Status    := OC_I2C_OK;
  FoundPtr  := Addr(pFound);

  Addr := $08;
  while Addr <= $77 do
  begin
    { Phase 1: START + address (write, R/W=0) }
    PortWrite(PORT_TXR, Byte(Addr * 2));
    PortWrite(PORT_CR,  OC_I2C_CR_STA or OC_I2C_CR_WR);

    Ret := WaitForTip;
    if Ret <> OC_I2C_OK then begin Status := Ret; Exit; end;

    { Phase 2: Read ACK/NACK before STO }
    SR      := PortRead(PORT_SR);
    GotNack := (SR and OC_I2C_SR_RXACK) <> 0;

    { Phase 3: STOP - poll BUSY }
    PortWrite(PORT_CR, OC_I2C_CR_STO);
    Ret := WaitForBusFree;
    if Ret <> OC_I2C_OK then begin Status := Ret; Exit; end;

    { Phase 4: Record if ACK }
    if not GotNack then
    begin
      if pFoundCnt < FoundMax then
      begin
        FoundPtr^ := Addr;
        FoundPtr  := Ptr(Seg(FoundPtr^), Ofs(FoundPtr^) + 1);
        pFoundCnt := pFoundCnt + 1;
      end;
    end;

    Addr := Addr + 1;
  end;
end;