; =====================================================================
;  data.inc  --  messages, circuit artwork, state and math constants.
; ---------------------------------------------------------------------
;  Included inside the .DATA segment of LOWPASSF.asm. Contains only
;  data declarations (no segment directives).
;
;  Number-entry / result scheme (engineering notation):
;    * Every quantity is a 4-digit mantissa ddd.d stored as 4 separate
;      bytes in a '...number' / 'digits' buffer (byte 0 = thousands,
;      byte 3 = tenths), plus a signed '...power' field that is always
;      a multiple of 3 (the SI decade exponent).
;    * The real value = mantissa * 10^power, and power is mapped to an
;      SI prefix by PUTUNIT (p,n,u,m,(none),K,M,G).
; =====================================================================


; ---------------------------------------------------------------------
;  Menu and prompt strings  (DOS INT 21h AH=09h, '$'-terminated).
;  13,10 = CR,LF.  msg ids are kept identical to the original program.
; ---------------------------------------------------------------------
msg     DB  "a.Analysis",13,10,"b.Design",13,10,"Enter the operation:",  '$'
msg2    DB  "a.1-1000 ohm",13,10,"b.1K-1000K ohm",13,10,"c.1M-1000M ohm",13,10,"Enter the range of Resistor:", '$'
msg3    DB  13,10,"Enter the resistor value:", '$'
msg4    DB  "a.1p-1000p farad",13,10,"b.1n-1000n farad",13,10,"c.1u-1000u farad",13,10,"Enter the range of Capacitor:", '$'
msg5    DB  13,10,"Enter the capacitor value:", '$'
msg6    DB  "Entered resistor value:", '$'
msg7    DB  "Entered capacitor value:", '$'
msg8    DB  "Press any key to continue...", '$'
msg9    DB  "Transient time for steady state:", '$'
msg10   DB  "Cutoff frequency:", '$'
msg11   DB  "a.1-1000 Hz",13,10,"b.1K-1000K Hz",13,10,"c.1M-1000M Hz",13,10,"Enter the range of frequency:", '$'
msg12   DB  13,10,"Enter the frequency value:", '$'
msg13   DB  13,10,"Real cutoff frequency:", '$'


; ---------------------------------------------------------------------
;  ASCII artwork of the RC low-pass filter circuit.
;  Drawn line by line in CIRCUITPRINT / DESIGNPRINT.
;
;  NOTE: circ2 ends in 13,13 (CR,CR) -- a missing LF that is preserved
;  here verbatim so the on-screen output matches the original program
;  byte-for-byte.  Fixing it to 13,10 would shift the drawing.
; ---------------------------------------------------------------------
circ0   DB  "      ",           '$'
circ1   DB  " -----/\/\/\---+---",13,10,'$'
circ2   DB  "               |   ",13,13,'$'
circ3   DB  "             ----- ",13,10,'$'
circ4   DB  "             ----- ",        '$'
circ5   DB  "               |   ",13,10,'$'
circ6   DB  " --------------+---",13,10,'$'


; ---------------------------------------------------------------------
;  Input / result state.
;    fpower/rpower/cpower : signed decade exponent (multiple of 3).
;    fnumber/rnumber/cnumber : 4-byte mantissa buffer per quantity.
;    digits : 4-byte buffer filled by SETDIGITS, printed by PRINTDIGITS.
; ---------------------------------------------------------------------
fpower  DB  ?
fnumber DB  4 DUP(?)
rpower  DB  ?
rnumber DB  4 DUP(?)
cpower  DB  ?
cnumber DB  4 DUP(?)
digits  DB  4 DUP(?)


; ---------------------------------------------------------------------
;  FPU scratch / results.
;    tmp      : 16-bit integer scratch (fild/fistp target, FPU cw save).
;    result   : REAL4 general result (transient time, frequency, RC).
;    resultrc : REAL4 saved RC product (loaded by LOADRC, reused by FREQ).
;    digitchk : 16-bit holder of floor(log10(x)) during normalisation.
;    flag     : FPU condition-code mirror during the brute-force search.
;    tmpSI/tmpDI : offsets of the best R / C found by FINDRC.
; ---------------------------------------------------------------------
tmp      DW ?
result   DWORD ?
resultrc DWORD ?
digitchk DW ?
flag     DW 0
tmpSI    DW ?
tmpDI    DW ?


; ---------------------------------------------------------------------
;  Math constants used by the FPU.
;
;  ln10, pitwo are kept as their original raw hex bit patterns.  The
;  original program stored slightly-inexact (truncated-by-one-ULP)
;  values rather than the round-to-nearest IEEE-754 encodings that
;  MASM would produce from a decimal literal; keeping the hex here
;  preserves byte-for-byte behaviour.  The intended value is shown in
;  the comment next to each constant.
; ---------------------------------------------------------------------
ln10    DWORD  040135d8eH    ;  ln(10)  ~= 2.3026   (transient time factor)
pitwo   DWORD  040c90fdbH    ;  2*pi    ~= 6.2832   (angular frequency)


; ---------------------------------------------------------------------
;  Small numeric constants for the FPU.
;    three   : 3.0          (snap exponent to nearest multiple of 3)
;    dec1000 : 1000.0       (shift a mantissa one SI decade up/down)
;    decvals : place-value table for a 4-digit mantissa.  Indexing is by
;              BYTE offset (MASM `decvals[n]` = address OFFSET decvals+n):
;                 decvals[ 0] = 100.0   (thousands digit)
;                 decvals[ 4] =  10.0   (hundreds  digit)
;                 decvals[ 8] =   1.0   (tens      digit)
;                 decvals[12] =   0.1   (tenths    digit)
;              The normalisation code reuses decvals[4] (= 10.0) as the
;              "x10" factor applied after dividing by 1000, so a value
;              like 0.123e3 is brought back into the 1..999.9 band.
; ---------------------------------------------------------------------
three   DWORD  3
dec1000 DWORD  1000
decvals DWORD  100.0, 10.0, 1.0, 0.1
