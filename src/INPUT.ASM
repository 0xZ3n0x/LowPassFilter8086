; =====================================================================
;  input.asm  --  keyboard input routines.
; ---------------------------------------------------------------------
;  Included inside the .CODE segment of LOWPASSF.asm.  Contains only
;  procedure definitions (no segment directives).
;
;  Shared input contract used by every routine here:
;    AL on return  = 27      -> ESC was pressed, caller must bail out
;                  = 0       -> invalid key, caller should retry
;                  = other   -> valid selection (the accepted key)
;
;  The "...power" fields store a signed decade exponent that is always
;  a multiple of 3, matching the SI prefix chosen by the user:
;     resistor : a=0 (1-1000 ohm)   b=3 (1-1000 kohm)  c=6 (1-1000 Mohm)
;     capacitor: a=-12 (pF)          b=-9 (nF)           c=-6 (uF)
;     frequency: a=0 (Hz)            b=3 (KHz)           c=6 (MHz)
; =====================================================================


; ---------------------------------------------------------------------
;  POWR -- read the resistor range key and set rpower accordingly.
;    in : key from keyboard
;    out: rpower = 0 / 3 / 6, or AL = 0 (bad key) / 27 (ESC)
; ---------------------------------------------------------------------
POWR    PROC
        GETC
        CMP     AL, 27
        JE      powr_esc
        CMP     AL, 'a'
        JE      powr_a
        CMP     AL, 'A'
        JE      powr_a
        CMP     AL, 'b'
        JE      powr_b
        CMP     AL, 'B'
        JE      powr_b
        CMP     AL, 'c'
        JE      powr_c
        CMP     AL, 'C'
        JE      powr_c
        MOV     AL, 0              ; unknown key
        RET
powr_a:
        MOV     rpower, 0          ; 1 - 1000 ohm
        RET
powr_b:
        MOV     rpower, 3          ; 1 - 1000 kohm
        RET
powr_c:
        MOV     rpower, 6          ; 1 - 1000 Mohm
powr_esc:
        RET
POWR    ENDP


; ---------------------------------------------------------------------
;  POWC -- read the capacitor range key and set cpower accordingly.
;    in : key from keyboard
;    out: cpower = -12 / -9 / -6, or AL = 0 (bad key) / 27 (ESC)
; ---------------------------------------------------------------------
POWC    PROC
        GETC
        CMP     AL, 27
        JE      powc_esc
        CMP     AL, 'a'
        JE      powc_a
        CMP     AL, 'A'
        JE      powc_a
        CMP     AL, 'b'
        JE      powc_b
        CMP     AL, 'B'
        JE      powc_b
        CMP     AL, 'c'
        JE      powc_c
        CMP     AL, 'C'
        JE      powc_c
        MOV     AL, 0
        RET
powc_a:
        MOV     cpower, -12        ; 1 - 1000 pF
        RET
powc_b:
        MOV     cpower, -9         ; 1 - 1000 nF
        RET
powc_c:
        MOV     cpower, -6         ; 1 - 1000 uF
powc_esc:
        RET
POWC    ENDP


; ---------------------------------------------------------------------
;  POWF -- read the frequency range key and set fpower accordingly.
;    in : key from keyboard
;    out: fpower = 0 / 3 / 6, or AL = 0 (bad key) / 27 (ESC)
; ---------------------------------------------------------------------
POWF    PROC
        GETC
        CMP     AL, 27
        JE      powf_esc
        CMP     AL, 'a'
        JE      powf_a
        CMP     AL, 'A'
        JE      powf_a
        CMP     AL, 'b'
        JE      powf_b
        CMP     AL, 'B'
        JE      powf_b
        CMP     AL, 'c'
        JE      powf_c
        CMP     AL, 'C'
        JE      powf_c
        MOV     AL, 0
        RET
powf_a:
        MOV     fpower, 0          ; 1 - 1000 Hz
        RET
powf_b:
        MOV     fpower, 3          ; 1 - 1000 KHz
        RET
powf_c:
        MOV     fpower, 6          ; 1 - 1000 MHz
powf_esc:
        RET
POWF    ENDP


; ---------------------------------------------------------------------
;  AINPUT -- Analysis mode input: read R then C from the user.
;    out: rnumber/rpower, cnumber/cpower filled in
;         AL = 27 if ESC was pressed at any point (bail out)
;
;  The resistor section is re-prompted on a bad range key or a bad
;  mantissa; the capacitor section is re-prompted the same way.  ESC
;  at any point returns immediately with AL = 27.
; ---------------------------------------------------------------------
AINPUT  PROC
res_retry:
        clear_screen
        PRINTMSG msg2
        CALL    POWR
        CMP     AL, 0
        JE      res_retry         ; bad range key -> ask again
        CMP     AL, 27
        JE      ainput_done       ; ESC

        PRINTMSG msg3
        NUMIN   rnumber           ; read 4-digit mantissa of R
        CMP     AL, 27
        JE      ainput_done       ; ESC
        CMP     AL, 0
        JE      res_retry         ; bad mantissa  -> redo R entirely

cap_retry:
        clear_screen
        PRINTMSG msg4
        CALL    POWC
        CMP     AL, 0
        JE      cap_retry
        CMP     AL, 27
        JE      ainput_done

        PRINTMSG msg5
        NUMIN   cnumber
        CMP     AL, 0
        JE      cap_retry         ; bad mantissa -> redo C entirely
        ; NOTE: ESC here (AL = 27) is not re-checked; it falls through
        ;       to ainput_done, which is exactly what the original does
        ;       -- the caller still sees AL = 27 and bails out.
ainput_done:
        RET
AINPUT  ENDP


; ---------------------------------------------------------------------
;  FINPUT -- Design mode input: read the target cut-off frequency and
;            leave the required RC product in the REAL4 'result'.
;    out: fnumber/fpower filled in
;         result = 1 / (2*pi*f)   (the RC product needed for frequency f)
;         AL = 27 if ESC was pressed (bail out)
;
;  FPU stack on exit: empty.  The mantissa is assembled from fnumber[]
;  with the decvals place-value table, scaled by 10^fpower, then
;  inverted through 2*pi to obtain RC.
; ---------------------------------------------------------------------
FINPUT  PROC
fin_retry:
        clear_screen
        PRINTMSG msg11
        CALL    POWF
        CMP     AL, 0
        JE      fin_retry
        CMP     AL, 27
        JE      fin_done

        PRINTMSG msg12
        NUMIN   fnumber
        CMP     AL, 27
        JE      fin_done
        CMP     AL, 0
        JE      fin_retry

        ; -- build the frequency mantissa ddd.d on the FPU stack ----
        ;    fnumber[0]*100 + fnumber[1]*10 + fnumber[2]*1 + fnumber[3]*0.1
        MOV     SI, 0
        MOV     DI, 0
load_f:
        MOV     AX, 0
        MOV     AL, fnumber[SI]
        MOV     tmp, AX
        FILD    tmp
        FMUL    decvals[DI]       ; multiply this digit by its place value
        INC     SI
        ADD     DI, 4
        CMP     SI, 4
        JB      load_f
        FADD                      ; st0 = d3*0.1 + d2*1
        FADD                      ;            + d1*10
        FADD                      ;            + d0*100   (= ddd.d mantissa)

        ; -- apply the SI decade chosen by the user -----------------
        CMP     fpower, 0
        JE      have_freq         ; Hz   -> no scaling
        FIMUL   dec1000           ; KHz  -> x1000
        CMP     fpower, 3
        JE      have_freq
        FIMUL   dec1000           ; MHz  -> x1000 again
have_freq:
        ; st0 = frequency in Hz.  Convert to the required RC product.
        FLD     pitwo             ; push 2*pi           stack: [2pi, f]
        FMUL    st(1), st(0)      ; st1 = f * 2*pi      stack: [2pi, f*2pi]
        FSTP    st(0)             ; drop 2pi            stack: [f*2pi]
        FLD1                      ; push 1              stack: [1, f*2pi]
        FDIV    st(0), st(1)      ; st0 = 1/(f*2pi)     stack: [RC, f*2pi]
        FSTP    result            ; result = RC, pop    stack: [f*2pi]
        FSTP    st(0)             ; drop remainder      stack: empty
fin_done:
        RET
FINPUT  ENDP
