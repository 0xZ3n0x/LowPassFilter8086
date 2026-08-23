; =====================================================================
;  DATA.INC  --  structures and messages.
; ---------------------------------------------------------------------
;  Included inside the .DATA segment of LOWPASSF.ASM. Contains only
;  data declarations and structure definitions (no segment directives).
;
;  All mutable state is stack-allocated in the procedures that use it.
;  Only read-only constant data remains here.
; =====================================================================

; ---------------------------------------------------------------------
;  Qty STRUCT -- a quantity in engineering notation.
;    mantissa : 4-byte digit buffer (byte 0 = hundreds, byte 3 = tenths)
;    power    : signed word, always a multiple of 3 (SI decade exponent)
;
;  The real value = mantissa * 10^power.  PUTUNIT maps 'power' to an
;  SI prefix (p, n, u, m, none, K, M, G).
;
;  Typedef only -- emits no bytes.  Instances are stack-allocated by
;  the callers; field offsets (+0 mantissa, +4 power) are hardcoded
;  at the use sites.
; ---------------------------------------------------------------------
Qty     STRUCT
    mantissa BYTE 4 DUP(?)
    power    DW ?
Qty     ENDS

; ---------------------------------------------------------------------
;  Menu and prompt strings (DOS INT 21h AH=09h, '$'-terminated).
; ---------------------------------------------------------------------
msg_menu    DB  "a.Analysis",13,10,"b.Design",13,10,"Enter the operation:",  '$'
msg_r_range DB  "a.1-1000 ohm",13,10,"b.1K-1000K ohm",13,10,"c.1M-1000M ohm",13,10,"Enter the range of Resistor:", '$'
msg_r_val   DB  13,10,"Enter the resistor value:", '$'
msg_c_range DB  "a.1p-1000p farad",13,10,"b.1n-1000n farad",13,10,"c.1u-1000u farad",13,10,"Enter the range of Capacitor:", '$'
msg_c_val   DB  13,10,"Enter the capacitor value:", '$'
msg_r_echo  DB  "Entered resistor value:", '$'
msg_c_echo  DB  "Entered capacitor value:", '$'
msg_pause   DB  "Press any key to continue...", '$'
msg_steady  DB  "Transient time for steady state:", '$'
msg_fc      DB  "Cutoff frequency:", '$'
msg_f_range DB  "a.1-1000 Hz",13,10,"b.1K-1000K Hz",13,10,"c.1M-1000M Hz",13,10,"Enter the range of frequency:", '$'
msg_f_val   DB  13,10,"Enter the frequency value:", '$'
msg_fc_real DB  13,10,"Real cutoff frequency:", '$'

; ---------------------------------------------------------------------
;  ASCII artwork of the RC low-pass filter circuit.
;  NOTE: circ2 ends in 13,13 (CR,CR) -- preserved verbatim to match
;  the original program's output byte-for-byte.
; ---------------------------------------------------------------------
circ0   DB  "      ",           '$'
circ1   DB  " -----/\/\/\---+---",13,10,'$'
circ2   DB  "               |   ",13,13,'$'
circ3   DB  "             ----- ",13,10,'$'
circ4   DB  "             ----- ",        '$'
circ5   DB  "               |   ",13,10,'$'
circ6   DB  " --------------+---",13,10,'$'
