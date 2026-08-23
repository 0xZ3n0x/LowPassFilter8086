; =====================================================================
;  math.asm  --  FPU arithmetic: RC loading, transient time, cut-off
;                frequency, brute-force design search, real frequency.
; ---------------------------------------------------------------------
;  Included inside the .CODE segment of LOWPASSF.asm.  Contains only
;  procedure definitions (no segment directives).
;
;  FPU stack conventions:
;    * Single (REAL4) precision.  16-bit 'tmp' is the FPU<->integer
;      bridge (FILD tmp / FISTP tmp).
;    * "FLD x; FMUL st(1),st(0); FSTP st(0)" == "st0 = st0 * x"
;      (multiply st1 by x, then pop x).
;    * FMUL / FADD with NO operands are the POP forms (FMULP/FADDP):
;      st1 = st1 OP st0, then pop st0.  Required by REALFREQ.
;
;  Engineering-notation normalisation:
;    Each result prints as ddd.d + SI prefix from a signed decade
;    exponent (multiple of 3) in CL.  Two routes find that exponent:
;      STEADY               : branches on floor(log10) in {6}/[3,5]/[0,2]
;                             and divides by 1e6, 1e3 or 1.
;      FREQ / REALFREQ      : snaps floor(log10) down to the nearest
;                             multiple of 3 (E), then loops x/1000 or
;                             x1000 until the value is in [1,1000).
;    Both finish with x10 (decvals[4]) so the tenths digit becomes the
;    integer units for FISTP + SETDIGITS, and leave the exponent in CL.
;    The FPU control-word save/restore order differs between STEADY and
;    FREQ/REALFREQ and is preserved exactly (see each routine).
; =====================================================================


; ---------------------------------------------------------------------
;  LOADRC -- build R and C mantissas from rnumber[]/cnumber[], multiply
;            them, and leave R*C on the FPU stack and in resultrc.
;    in : rnumber[0..3], cnumber[0..3] (one digit/byte; byte 0 = thousands)
;    out: FPU st0 = R_mant * C_mant  (also saved in resultrc)
; ---------------------------------------------------------------------
LOADRC  PROC
        PUSH    AX
        PUSH    SI
        PUSH    DI
        MOV     SI, 0
        MOV     DI, 0
load_r:
        MOV     AX, 0
        MOV     AL, rnumber[SI]
        MOV     tmp, AX
        FILD    tmp
        FMUL    decvals[DI]       ; digit * place value (100,10,1,0.1)
        INC     SI
        ADD     DI, 4
        CMP     SI, 4
        JB      load_r
        FADD                      ; sum the 4 R contributions -> st0 = R
        FADD
        FADD

        MOV     SI, 0
        MOV     DI, 0
load_c:
        MOV     AX, 0
        MOV     AL, cnumber[SI]
        MOV     tmp, AX
        FILD    tmp
        FMUL    decvals[DI]
        INC     SI
        ADD     DI, 4
        CMP     SI, 4
        JB      load_c
        FADD                      ; sum the 4 C contributions -> st0 = C
        FADD                      ;                  (st1 still = R)
        FADD
        ; stack: [C, R]
        FMUL    st(1), st(0)      ; st1 = R * C          stack: [C, R*C]
        FSTP    st(0)             ; drop C               stack: [R*C]
        FST     resultrc          ; resultrc = R*C (kept on stack too)
        POP     DI
        POP     SI
        POP     AX
        RET
LOADRC  ENDP


; ---------------------------------------------------------------------
;  STEADY -- compute/print the 0%->90% transient (rise) time:
;               t = ln(10) * R * C   ~= 2.3026 * R * C
;    in : FPU st0 = R*C (from LOADRC); rpower, cpower
;    out: prints "Transient time for steady state: ddd.d<prefix>s"
;
;  result = ln10 * R*C (mantissa only; 10^(rpower+cpower) carried in CL).
;  digitchk = floor(log10(result)) selects the decade.  The control word
;  is restored to round-to-nearest BEFORE the divide / x10 / FISTP, so
;  those ops round normally.
; ---------------------------------------------------------------------
STEADY  PROC
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX

        FLD     ln10              ; stack: [ln10, RC]
        FMUL    st(1), st(0)      ; st1 = RC * ln10
        FSTP    st(0)             ; drop ln10        stack: [RC*ln10]
        FSTP    result            ; result = RC*ln10, stack empty
        PRINTMSG msg9

        ; -- floor(log10(result)) using round-down mode ---------------
        FSTCW   tmp               ; save FPU control word
        MOV     AX, tmp
        PUSH    AX
        OR      AX, 0400H         ; RC field = 11b (round down)
        MOV     tmp, AX
        FLDCW   tmp
        FLD1
        FLD     result            ; stack: [1, result]
        FYL2X                     ; st0 = 1 * log2(result) = log2(result)
        FLDL2T                    ; push log2(10)  stack: [log2(10), log2(result)]
        FDIV    st(1), st(0)      ; st1 = log2(result)/log2(10) = log10(result)
        FSTP    st(0)             ; drop log2(10)  stack: [log10(result)]
        FRNDINT                   ; st0 = floor(log10(result))
        FISTP   digitchk          ; digitchk = floor(log10(result))
        POP     AX
        MOV     tmp, AX
        FLDCW   tmp               ; restore control word (round-to-nearest)

        ; -- pick the decade and scale result into [1,1000) -----------
        MOV     CL, cpower
        ADD     CL, rpower        ; CL = exponent of the RC product

        CMP     digitchk, 6
        JNE     st_ign1
        ADD     CL, 6             ; result ~ 1e6..1e7 -> /1e6
        FLD     result
        FIDIV   dec1000
        FIDIV   dec1000
        FMUL    decvals[4]        ; x10 (tenths digit -> units)
        FISTP   tmp
        JMP     st_done
st_ign1:
        CMP     digitchk, 3
        JB      st_ign2
        ADD     CL, 3             ; result ~ 1e3..1e6 -> /1e3
        FLD     result
        FIDIV   dec1000
        FMUL    decvals[4]
        FISTP   tmp
        JMP     st_done
st_ign2:                          ; result ~ 1..1e3 -> no division
        FLD     result
        FMUL    decvals[4]
        FISTP   tmp
        ; tmp = dddd (= mantissa * 10); CL = signed SI decade exponent.
st_done:
        SETDIGITS                 ; split tmp into digits[0..3]
        PRINTDIGITS digits        ; print "ddd.d"
        CALL    PUTUNIT           ; print SI prefix from CL
        PUTC    's'
        NEWL

        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
STEADY  ENDP


; ---------------------------------------------------------------------
;  FREQ -- compute/print the cut-off frequency:  fc = 1 / (2*pi*R*C)
;    in : resultrc (= R*C, saved by LOADRC); rpower, cpower
;    out: prints "Cutoff frequency: ddd.d<prefix>Hz"
;
;  The raw 1/(2*pi*R*C) is a mantissa in the R,C component decades, so
;  it is first scaled by 10^(-(rpower+cpower)) (the freqadjust loop) to
;  get fc in Hz.  Then E = floor(log10(fc)) snapped down to a multiple
;  of 3 selects the SI decade; the scale loop brings fc into [1,1000).
;  NOTE: the control word stays round-down through the scale loop AND
;  the final x10; it is restored only just before FISTP.  Preserved
;  exactly as the original.
; ---------------------------------------------------------------------
FREQ    PROC
        FLD     resultrc          ; stack: [RC]
        FLD     pitwo             ; stack: [2pi, RC]
        FMUL    st(1), st(0)      ; st1 = RC * 2pi
        FSTP    st(0)             ; drop 2pi        stack: [RC*2pi]
        FLD1                      ; stack: [1, RC*2pi]
        FDIV    st(0), st(1)      ; st0 = 1/(RC*2pi)
        FSTP    result            ; result = 1/(2piRC), pop
        FSTP    st(0)             ; drop remainder  stack: empty
        FLD     result            ; stack: [fmant]

        MOV     CL, cpower
        ADD     CL, rpower        ; CL = cpower+rpower (<= 0)
freq_scale:
        CMP     CL, 0
        JE      freq_scaled       ; bring fmant up to Hz: x1000 per +3 in CL
        FIMUL   dec1000
        ADD     CL, 3
        JMP     freq_scale
freq_scaled:
        FSTP    result            ; result = fc in Hz

        ; -- E = floor(log10(fc)) snapped down to a multiple of 3 -----
        FSTCW   tmp
        MOV     AX, tmp
        PUSH    AX
        OR      AX, 0400H         ; round down
        MOV     tmp, AX
        FLDCW   tmp
        FLD1
        FLD     result
        FYL2X                     ; st0 = log2(result)
        FLDL2T                    ; push log2(10)
        FDIV    st(1), st(0)      ; st1 = log10(result)
        FSTP    st(0)             ; drop log2(10)
        FRNDINT                   ; st0 = floor(log10(result))
        FIDIV   three             ; /3
        FRNDINT                   ; floor(/3)
        FIMUL   three             ; x3  -> largest multiple of 3 <= floor(log10)
        FISTP   tmp               ; tmp = E
        FLD     result            ; stack: [fc]
        MOV     CX, tmp           ; CX = E
        MOV     CH, CL            ; save CL (E low byte) in CH across the loop
        CMP     CL, 0
        JE      freq_norm_end
        CMP     CL, 0
        JG      freq_pos
freq_neg:                         ; E < 0: multiply up by 1000 per decade
        ADD     CL, 3
        FIMUL   dec1000
        CMP     CL, 0
        JNE     freq_neg
        JMP     freq_norm_end
freq_pos:                         ; E > 0: divide down by 1000 per decade
        SUB     CL, 3
        FIDIV   dec1000
        CMP     CL, 0
        JNE     freq_pos
freq_norm_end:
        MOV     CL, CH            ; restore CL = E (SI decade exponent)
        FMUL    decvals[4]        ; x10 (still in round-down mode)

        POP     AX
        MOV     tmp, AX
        FLDCW   tmp               ; restore control word (round-to-nearest)
        FISTP   tmp               ; tmp = dddd (= mantissa * 10), stack empty

        SETDIGITS
        PRINTMSG msg10
        PRINTDIGITS digits
        CALL    PUTUNIT
        PUTC    'H'
        PUTC    'z'
        RET
FREQ    ENDP


; ---------------------------------------------------------------------
;  FINDRC -- brute-force search of the standard R/C tables for the pair
;            whose R*C is closest to the target RC (held in 'result',
;            set by FINPUT).
;    in : result = target RC
;    out: tmpSI = byte offset of best R in R_dec0 (0..668, step 4)
;         tmpDI = byte offset of best C in C_dec0 (0..300, step 4)
;
;  168 resistors (SI: 0..668) x 76 capacitors (DI: 0..300) = 12768 pairs.
;  The current best |R*C - target| is kept in st0; each candidate is
;  compared against it via FCOM, and the pair is saved whenever a
;  smaller error is found.  FPU stack during the search:
;     [cand_err, best_err, target].
; ---------------------------------------------------------------------
FINDRC  PROC
        MOV     SI, 0
        MOV     DI, 0
        MOV     tmpSI, SI         ; best R offset (start with R0)
        MOV     tmpDI, DI         ; best C offset (start with C0)
        FLD     result            ; stack: [target]
        FLD     R_dec0[0]         ; stack: [R0, target]
        FLD     C_dec0[0]         ; stack: [C0, R0, target]
        FMUL    st(1), st(0)      ; st1 = R0*C0     stack: [C0, R0*C0, target]
        FSTP    st(0)             ; drop C0         stack: [R0*C0, target]
        FSUB    st(0), st(1)      ; st0 = R0*C0 - target
        FABS                      ; st0 = |R0*C0 - target| = best_err
        ; stack: [best_err, target]

        MOV     CL, 8             ; will shift the C0 condition bit to bit 0
fr_outer:
        MOV     DI, 0
fr_inner:
        FLD     R_dec0[SI]        ; stack: [R[i], best_err, target]
        FLD     C_dec0[DI]        ; stack: [C[j], R[i], best_err, target]
        FMUL    st(1), st(0)      ; st1 = R[i]*C[j]  stack: [C[j], R[i]C[j], best_err, target]
        FSTP    st(0)             ; drop C[j]        stack: [R[i]C[j], best_err, target]
        FSUB    st(0), st(2)      ; st0 = R[i]C[j] - target
        FABS                      ; st0 = cand_err   stack: [cand_err, best_err, target]

        FCOM                      ; compare st0 (cand_err) vs st1 (best_err)
        FSTSW   flag              ; store FPU status word into 'flag'
        AND     flag, 0100H       ; isolate C0 (bit 8 of the status word)
        SHR     flag, CL          ; shift it into bit 0
        CMP     flag, 1           ; C0 = 1 means cand_err < best_err
        JNE     fr_keep           ; otherwise keep the old best
        MOV     tmpSI, SI         ; new best R offset
        MOV     tmpDI, DI         ; new best C offset
        FST     st(1)             ; best_err := cand_err
fr_keep:
        FSTP    st(0)             ; drop cand_err  stack: [best_err, target]
        ADD     DI, 4
        CMP     DI, 304           ; 76 caps * 4 bytes
        JNE     fr_inner
        ADD     SI, 4
        CMP     SI, 672           ; 168 resistors * 4 bytes
        JNE     fr_outer

        FSTP    st(0)             ; drop best_err
        FSTP    st(0)             ; drop target     stack: empty
        RET
FINDRC  ENDP


; ---------------------------------------------------------------------
;  REALFREQ -- compute and print the real cut-off frequency produced by
;              the R/C pair chosen by FINDRC:  fc = 1/(2*pi*R*C).
;    in : tmpSI, tmpDI (offsets of chosen R, C in R_dec0 / C_dec0)
;    out: prints "Real cutoff frequency: ddd.d<prefix>Hz"
;
;  R and C are read straight from the standard-value tables (in ohms
;  and farads), so fc comes out in Hz directly -- no decade pre-scaling.
;  Normalisation is the same snapped-multiple-of-3 scheme as FREQ.
; ---------------------------------------------------------------------
REALFREQ PROC
        MOV     SI, tmpSI
        FLD     R_dec0[SI]        ; push R (ohms)        stack: [R]
        MOV     SI, tmpDI
        FLD     C_dec0[SI]        ; push C (farads)      stack: [C, R]
        FLD     pitwo             ; stack: [2pi, C, R]
        FMUL                      ; pop: st0 = 2pi * C   stack: [2pi*C, R]
        FMUL                      ; pop: st0 = 2pi * C * R   stack: [2piRC]
        FLD1                      ; stack: [1, 2piRC]
        FDIVR   st(1), st(0)      ; st1 = st0/st1 = 1/(2piRC)
        FSTP    st(0)             ; drop 1            stack: [fc]
        FSTP    result            ; result = fc, pop  stack: empty
        LEA     BX, result        ; (kept for fidelity; BX is unused after this)

        ; -- E = floor(log10(fc)) snapped down to a multiple of 3 -----
        FSTCW   tmp
        MOV     AX, tmp
        PUSH    AX
        OR      AX, 0400H         ; round down
        MOV     tmp, AX
        FLDCW   tmp
        FLD1
        FLD     result
        FYL2X                     ; st0 = log2(result)
        FLDL2T                    ; push log2(10)
        FDIV    st(1), st(0)      ; st1 = log10(result)
        FSTP    st(0)             ; drop log2(10)
        FRNDINT                   ; st0 = floor(log10(result))
        FIDIV   three
        FRNDINT
        FIMUL   three             ; snap to multiple of 3
        FISTP   tmp               ; tmp = E
        FLD     result            ; stack: [fc]
        MOV     CX, tmp
        MOV     CH, CL            ; save CL (E low byte) in CH
        CMP     CL, 0
        JE      rf_norm_end
        CMP     CL, 0
        JG      rf_pos
rf_neg:                           ; E < 0: multiply up by 1000 per decade
        ADD     CL, 3
        FIMUL   dec1000
        CMP     CL, 0
        JNE     rf_neg
        JMP     rf_norm_end
rf_pos:                           ; E > 0: divide down by 1000 per decade
        SUB     CL, 3
        FIDIV   dec1000
        CMP     CL, 0
        JNE     rf_pos
rf_norm_end:
        MOV     CL, CH            ; restore CL = E
        FMUL    decvals[4]        ; x10 (still round-down)

        POP     AX
        MOV     tmp, AX
        FLDCW   tmp               ; restore control word (round-to-nearest)
        FISTP   tmp               ; tmp = dddd, stack empty

        SETDIGITS
        PRINTMSG msg13
        PRINTDIGITS digits
        CALL    PUTUNIT
        PUTC    'H'
        PUTC    'z'
        NEWL
        RET
REALFREQ ENDP

