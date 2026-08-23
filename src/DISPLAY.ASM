; =====================================================================
;  display.asm  --  screen output routines (values, units, circuit).
; ---------------------------------------------------------------------
;  Included inside the .CODE segment of LOWPASSF.asm.  Contains only
;  procedure definitions (no segment directives).
;
;  All printing goes through the macros in macros.inc (PUTC, PRINTMSG,
;  PRINTDIGITS, NEWL) and DOS INT 21h.  SI prefixes are emitted by
;  PUTUNIT from the signed decade exponent carried in CL.
; =====================================================================


; ---------------------------------------------------------------------
;  AVALUES -- Analysis mode: echo the entered R and C back to the user
;             and wait for a key press before continuing.
;    in : rnumber/rpower, cnumber/cpower already filled by AINPUT
;    out: AL = the key pressed at "press any key" (27 = ESC -> caller
;         will exit, any other key -> continue to the computation)
; ---------------------------------------------------------------------
AVALUES  PROC
        clear_screen
        PRINTMSG msg6               ; "Entered resistor value:"
        PRINTDIGITS rnumber
        MOV     CL, rpower
        CALL    PUTUNIT
        NEWL

        PRINTMSG msg7               ; "Entered capacitor value:"
        PRINTDIGITS cnumber
        MOV     CL, cpower
        CALL    PUTUNIT
        PUTC    'F'
        NEWL

        PRINTMSG msg8               ; "Press any key to continue..."
        GETC
        RET
AVALUES  ENDP


; ---------------------------------------------------------------------
;  PUTUNIT -- print the SI prefix that corresponds to the signed decade
;             exponent in CL.  Used for R, C, time and frequency output.
;    in : CL = exponent (a multiple of 3)
;    out: one character printed, or nothing for the base (x1) decade
;
;  Mapping:  -12 'p' | -9 'n' | -6 'u' | -3 'm' | 0 (none)
;           |  3 'K' |  6 'M' |  9 'G'
; ---------------------------------------------------------------------
PUTUNIT  PROC
        CMP     CL, -12
        JNE     pu_n
        PUTC    'p'
        JMP     pu_end
pu_n:
        CMP     CL, -9
        JNE     pu_u
        PUTC    'n'
        JMP     pu_end
pu_u:
        CMP     CL, -6
        JNE     pu_m
        PUTC    'u'
        JMP     pu_end
pu_m:
        CMP     CL, -3
        JNE     pu_none
        PUTC    'm'
        JMP     pu_end
pu_none:
        CMP     CL, 0
        JNE     pu_k
        JMP     pu_end             ; base decade: no prefix
pu_k:
        CMP     CL, 3
        JNE     pu_meg
        PUTC    'K'
        JMP     pu_end
pu_meg:
        CMP     CL, 6
        JNE     pu_g
        PUTC    'M'
        JMP     pu_end
pu_g:
        CMP     CL, 9
        JNE     pu_end
        PUTC    'G'
pu_end:
        RET
PUTUNIT  ENDP


; ---------------------------------------------------------------------
;  CIRCUITPRINT -- draw the RC low-pass filter ASCII circuit and label
;             its components with the R and C entered in Analysis mode.
;    in : rnumber/rpower, cnumber/cpower
; ---------------------------------------------------------------------
CIRCUITPRINT PROC
        NEWL
        NEWL
        PRINTMSG circ0             ; leading spaces (R label column)
        PRINTDIGITS rnumber
        MOV     CL, rpower
        CALL    PUTUNIT
        PUTC    'o'
        PUTC    'h'
        PUTC    'm'
        NEWL

        PRINTMSG circ1             ;  -----/\/\/\---+---
        PRINTMSG circ2             ;                |     (see data.inc: CR,CR kept)
        PRINTMSG circ3             ;              -----
        PRINTMSG circ4             ;              -----
        MOV     CL, cpower
        PRINTDIGITS cnumber
        CALL    PUTUNIT
        PUTC    'F'
        NEWL
        PRINTMSG circ5             ;                |
        PRINTMSG circ6             ;  --------------+---
        RET
CIRCUITPRINT ENDP


; ---------------------------------------------------------------------
;  DESIGNPRINT -- Design mode: print the target frequency, the real
;             frequency produced by the chosen R-C pair (via REALFREQ),
;             and the circuit drawing labelled with that pair.
;    in : fnumber/fpower        (target frequency, as entered)
;         tmpSI, tmpDI          (byte offsets of best R, best C in the
;                               R_dec0 / C_dec0 tables, set by FINDRC)
; ---------------------------------------------------------------------
DESIGNPRINT PROC
        clear_screen
        PRINTMSG msg10             ; "Cutoff frequency:"
        PRINTDIGITS fnumber
        MOV     CL, fpower
        CALL    PUTUNIT
        PUTC    'H'
        PUTC    'z'

        CALL    REALFREQ           ; prints "Real cutoff frequency: ..."

        ; -- resistor label: pick the 6-byte string from rdigit0 -----
        PRINTMSG circ0
        MOV     AX, tmpSI          ; byte offset in R table
        SHR     AX, 1              ; /4  (one REAL4 = 4 bytes)
        SHR     AX, 1
        MOV     BL, 6              ; each display string is 6 bytes
        MUL     BL                 ; AX = (tmpSI/4) * 6 = string offset
        MOV     SI, AX
        PUTC    rdigit0[SI]
        PUTC    rdigit0[SI+1]
        PUTC    rdigit0[SI+2]
        PUTC    rdigit0[SI+3]
        PUTC    rdigit0[SI+4]
        PUTC    rdigit0[SI+5]
        PUTC    'o'
        PUTC    'h'
        PUTC    'm'
        NEWL

        PRINTMSG circ1
        PRINTMSG circ2
        PRINTMSG circ3
        PRINTMSG circ4

        ; -- capacitor label: pick the 6-byte string from cdigit0 -----
        MOV     AX, tmpDI
        SHR     AX, 1
        SHR     AX, 1
        MOV     BL, 6
        MUL     BL
        MOV     SI, AX
        PUTC    cdigit0[SI]
        PUTC    cdigit0[SI+1]
        PUTC    cdigit0[SI+2]
        PUTC    cdigit0[SI+3]
        PUTC    cdigit0[SI+4]
        PUTC    cdigit0[SI+5]
        PUTC    'F'
        NEWL

        PRINTMSG circ5
        PRINTMSG circ6
        RET
DESIGNPRINT ENDP
