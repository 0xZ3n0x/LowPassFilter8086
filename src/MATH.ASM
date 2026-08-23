; =====================================================================
;  MATH.ASM  --  FPU arithmetic: RC loading, transient time, cut-off
;                frequency, brute-force design search, real frequency.
; ---------------------------------------------------------------------
;  Calling convention (cdecl):
;    * Args pushed right-to-left; caller cleans up (ADD SP, n).
;    * Arg 1 at [BP+4], arg 2 at [BP+6], etc.
;    * Return: AX = primary, DX = secondary.
;    * Callee preserves SI, DI, BP; may clobber AX, BX, CX, DX.
;    * No FPU state crosses CALLs except FLOOR_LOG3 (consumes st0).
;
;  Helper PROCs:
;    FLOOR_LOG3   -- floor(log10(st0)) snapped to a multiple of 3 -> AX
;    NORMALIZE    -- bring REAL4 into [1,1000), return dddd + exponent
;    PRINT_RESULT -- print "ddd.d<prefix><unit>" from dddd + exponent
; =====================================================================


FPU_ROUND_DOWN EQU 0400H         ; x87 control-word bits: round down


; ---------------------------------------------------------------------
;  FLOOR_LOG3 -- floor(log10(st0)) snapped down to nearest multiple of 3.
;    in : st0 = value (positive)
;    out: AX = snapped exponent E (multiple of 3, may be negative)
;         st0 consumed (popped)
;  Manages its own FPU control-word save/restore internally.
; ---------------------------------------------------------------------
FLOOR_LOG3 PROC
    PUSH    BP
    MOV     BP, SP
    SUB     SP, 2

    FSTCW   WORD PTR [BP-2]
    MOV     AX, [BP-2]
    PUSH    AX
    OR      AX, FPU_ROUND_DOWN
    MOV     [BP-2], AX
    FLDCW   WORD PTR [BP-2]

    FLD1
    FXCH                       ; stack: [value, 1]
    FYL2X                      ; st0 = log2(value)
    FLDL2T
    FDIV    st(1), st(0)       ; st1 = log10(value)
    FSTP    st(0)
    FRNDINT                    ; floor(log10(value))
    MOV     AX, 3
    MOV     [BP-2], AX
    FIDIV   WORD PTR [BP-2]
    FRNDINT
    FIMUL   WORD PTR [BP-2]    ; snap to multiple of 3
    FISTP   WORD PTR [BP-2]    ; tmp = E, stack empty

    MOV     AX, [BP-2]         ; AX = E (read before slot reuse)
    POP     DX                 ; DX = saved control word
    MOV     [BP-2], DX
    FLDCW   WORD PTR [BP-2]    ; restore CW
    MOV     SP, BP
    POP     BP
    RET
FLOOR_LOG3 ENDP


; ---------------------------------------------------------------------
;  NORMALIZE -- bring a REAL4 into [1,1000) and produce the print integer.
;    in : [BP+4] = val_ptr (ptr to REAL4)
;         [BP+6] = exponent E (word, multiple of 3)
;    out: AX = dddd (scaled integer = mantissa * 10, for SETDIGITS)
;         DX = E   (the same exponent, passed through)
;
;  Caller MUST set FPU round-down before calling and restore after.
; ---------------------------------------------------------------------
NORMALIZE PROC
    PUSH    BP
    MOV     BP, SP
    SUB     SP, 4              ; [BP-2]=exp_save, [BP-4]=1000/result_int
    PUSH    BX

    MOV     AX, [BP+6]
    MOV     [BP-2], AX         ; save E for return in DX
    MOV     BX, [BP+4]
    FLD     DWORD PTR [BX]     ; stack: [val]

    MOV     CL, AL
    MOV     AX, 1000
    MOV     [BP-4], AX         ; integer 1000 (slot rewritten at norm_end)
    CMP     CL, 0
    JE      norm_end
    JG      norm_pos
norm_neg:
    ADD     CL, 3               ; one SI decade up (x1000)
    FIMUL   WORD PTR [BP-4]
    CMP     CL, 0
    JNE     norm_neg
    JMP     norm_end
norm_pos:
    SUB     CL, 3               ; one SI decade down (/1000)
    FIDIV   WORD PTR [BP-4]
    CMP     CL, 0
    JNE     norm_pos
norm_end:
    MOV     AX, 10
    MOV     [BP-4], AX         ; integer 10 (slot rewritten by FISTP below)
    FIMUL   WORD PTR [BP-4]    ; x10
    FISTP   WORD PTR [BP-4]    ; result_int = dddd

    MOV     AX, [BP-4]         ; AX = dddd
    MOV     DX, [BP-2]         ; DX = E
    POP     BX
    MOV     SP, BP
    POP     BP
    RET
NORMALIZE ENDP


; ---------------------------------------------------------------------
;  PRINT_RESULT -- print "ddd.d<prefix><unit1><unit2>" + newline.
;    in : [BP+4]  = val      (word, dddd from NORMALIZE)
;         [BP+6]  = exponent (word, SI decade exponent)
;         [BP+8]  = unit1    (word, first unit char; 0 = none)
;         [BP+10] = unit2    (word, second unit char; 0 = none)
;  Locals: [BP-4..BP-1] = digits (4-byte buffer)
; ---------------------------------------------------------------------
PRINT_RESULT PROC
    PUSH    BP
    MOV     BP, SP
    SUB     SP, 4

    LEA     AX, [BP-4]
    PUSH    AX
    PUSH    WORD PTR [BP+4]
    CALL    SETDIGITS
    ADD     SP, 4

    LEA     AX, [BP-4]
    PUSH    AX
    CALL    PRINTDIGITS
    ADD     SP, 2

    PUSH    WORD PTR [BP+6]
    CALL    PUTUNIT
    ADD     SP, 2

    MOV     AX, [BP+8]
    CMP     AX, 0
    JE      pr_no_unit1
    PUTC    AL
pr_no_unit1:
    MOV     AX, [BP+10]
    CMP     AX, 0
    JE      pr_no_unit2
    PUTC    AL
pr_no_unit2:
    NEWL

    MOV     SP, BP
    POP     BP
    RET
PRINT_RESULT ENDP


; ---------------------------------------------------------------------
;  LOADRC -- build R and C mantissas from Qty buffers, multiply, store.
;    in : [BP+4] = r      (ptr to Qty)
;         [BP+6] = c      (ptr to Qty)
;         [BP+8] = rc_out (ptr to REAL4)
;    out: *rc_out = R*C   (FPU stack empty)
;  Locals: [BP-2] = N (packed 4-digit mantissa), [BP-4] = ten (word, 10)
; ---------------------------------------------------------------------
LOADRC  PROC
    PUSH    BP
    MOV     BP, SP
    SUB     SP, 4
    PUSH    SI
    PUSH    DI
    PUSH    BX

    MOV     AX, 10
    MOV     [BP-4], AX         ; integer 10 for the final /10
    MOV     AX, 0               ; N = 0
    MOV     BX, [BP+4]
    MOV     SI, 0
load_r:
    MOV     DX, 10
    MUL     DX                  ; AX *= 10 (max 9990, fits a word)
    MOV     DL, [BX+SI]
    MOV     DH, 0
    ADD     AX, DX              ; AX = AX*10 + digit
    INC     SI
    CMP     SI, 4
    JB      load_r
    MOV     [BP-2], AX         ; N = d0d1d2d3 (0..9999)
    FILD    WORD PTR [BP-2]
    FIDIV   WORD PTR [BP-4]     ; st0 = mantissa = N/10

    MOV     BX, [BP+6]
    MOV     SI, 0
    MOV     AX, 0               ; N = 0
load_c:
    MOV     DX, 10
    MUL     DX                  ; AX *= 10 (max 9990, fits a word)
    MOV     DL, [BX+SI]
    MOV     DH, 0
    ADD     AX, DX              ; AX = AX*10 + digit
    INC     SI
    CMP     SI, 4
    JB      load_c
    MOV     [BP-2], AX         ; N = d0d1d2d3 (0..9999)
    FILD    WORD PTR [BP-2]
    FIDIV   WORD PTR [BP-4]     ; st0 = mantissa = N/10
    FMUL    st(1), st(0)
    FSTP    st(0)
    MOV     BX, [BP+8]
    FSTP    DWORD PTR [BX]

    POP     BX
    POP     DI
    POP     SI
    MOV     SP, BP
    POP     BP
    RET
LOADRC  ENDP


; ---------------------------------------------------------------------
;  STEADY -- compute/print the 0%->90% transient time:
;               t = ln(10) * R * C   ~= 2.3026 * R * C
;    in : [BP+4] = rc_ptr (ptr to REAL4 R*C)
;         [BP+6] = r      (ptr to Qty, for r.power)
;         [BP+8] = c      (ptr to Qty, for c.power)
;    out: prints "Transient time for steady state: ddd.d<prefix>s"
;
;  Uses a different decade scheme from FREQ/REALFREQ (branches on
;  floor(log10) rather than snapping to a multiple of 3).  Preserved
;  from the original program.
;
;  Locals: [BP-2]=CW save/work, then ten, then dddd (FISTP target,
;             finally pushed to PRINT_RESULT as val), [BP-4]=digitchk,
;          [BP-8]=result, [BP-12]=1000, [BP-14]=exponent
; ---------------------------------------------------------------------
STEADY  PROC
    PUSH    BP
    MOV     BP, SP
    SUB     SP, 14

    MOV     BX, [BP+4]
    FLD     DWORD PTR [BX]
    FLDL2T
    FLDLN2
    FMUL                       ; st0 = ln(10) = log2(10)*ln(2)
    FMUL    st(1), st(0)
    FSTP    st(0)
    FSTP    DWORD PTR [BP-8]   ; result = RC*ln10
    PRINTMSG msg_steady

    ; -- floor(log10(result)) with round-down --
    FSTCW   WORD PTR [BP-2]
    MOV     AX, [BP-2]
    PUSH    AX
    OR      AX, FPU_ROUND_DOWN
    MOV     [BP-2], AX
    FLDCW   WORD PTR [BP-2]
    FLD1
    FLD     DWORD PTR [BP-8]
    FYL2X
    FLDL2T
    FDIV    st(1), st(0)
    FSTP    st(0)
    FRNDINT
    FISTP   WORD PTR [BP-4]    ; digitchk = floor(log10)
    POP     AX
    MOV     [BP-2], AX
    FLDCW   WORD PTR [BP-2]    ; restore CW

    MOV     AX, 1000
    MOV     [BP-12], AX        ; integer 1000 for /1000 scaling

    ; -- pick decade and scale --
    MOV     BX, [BP+8]
    MOV     CL, [BX+4]          ; c.power
    MOV     BX, [BP+6]
    ADD     CL, [BX+4]          ; + r.power

    MOV     AX, 10
    MOV     [BP-2], AX         ; integer 10 for x10 (slot recycled below)

    CMP     WORD PTR [BP-4], 6
    JNE     st_ign1
    ADD     CL, 6
    FLD     DWORD PTR [BP-8]
    FIDIV   WORD PTR [BP-12]
    FIDIV   WORD PTR [BP-12]
    FIMUL   WORD PTR [BP-2]
    FISTP   WORD PTR [BP-2]
    JMP     st_done
st_ign1:
    CMP     WORD PTR [BP-4], 3
    JB      st_ign2
    ADD     CL, 3
    FLD     DWORD PTR [BP-8]
    FIDIV   WORD PTR [BP-12]
    FIMUL   WORD PTR [BP-2]
    FISTP   WORD PTR [BP-2]
    JMP     st_done
st_ign2:
    FLD     DWORD PTR [BP-8]
    FIMUL   WORD PTR [BP-2]
    FISTP   WORD PTR [BP-2]
st_done:
    MOV     [BP-14], CX         ; save exponent (CH undefined; only the
                                ; low byte is consumed by PUTUNIT)

    ; -- print via PRINT_RESULT --
    MOV     AX, 0               ; unit2 = none
    PUSH    AX
    MOV     AX, 's'             ; unit1 = 's'
    PUSH    AX
    PUSH    WORD PTR [BP-14]   ; exponent
    PUSH    WORD PTR [BP-2]    ; val (dddd)
    CALL    PRINT_RESULT
    ADD     SP, 8

    MOV     SP, BP
    POP     BP
    RET
STEADY  ENDP


; ---------------------------------------------------------------------
;  FREQ -- compute/print the cut-off frequency:  fc = 1 / (2*pi*R*C)
;    in : [BP+4] = rc_ptr (ptr to REAL4 R*C)
;         [BP+6] = r      (ptr to Qty, for r.power)
;         [BP+8] = c      (ptr to Qty, for c.power)
;    out: prints "Cutoff frequency: ddd.d<prefix>Hz"
;
;  Locals: [BP-6]  = result (REAL4)
;          [BP-8]  = old control word
;          [BP-10] = CW work area
;          [BP-12] = 1000 during scaling, then saved exponent E
; ---------------------------------------------------------------------
FREQ    PROC
    PUSH    BP
    MOV     BP, SP
    SUB     SP, 12

    ; -- fc_raw = 1 / (2*pi*RC) --
    MOV     BX, [BP+4]
    FLD     DWORD PTR [BX]     ; st0 = RC
    FLDPI
    FLDPI
    FADD                       ; st0 = 2*pi
    FMUL    st(1), st(0)       ; st1 = 2pi*RC
    FSTP    st(0)              ; drop 2pi
    FLD1
    FDIV    st(0), st(1)       ; st0 = 1/(2pi*RC)
    FSTP    DWORD PTR [BP-6]
    FSTP    st(0)

    ; -- scale raw fc to Hz: multiply by 1000 per decade --
    MOV     BX, [BP+8]         ; c ptr
    MOV     CL, [BX+4]         ; c.power
    MOV     BX, [BP+6]         ; r ptr
    ADD     CL, [BX+4]         ; + r.power (always <= 0)
    MOV     AX, 1000
    MOV     [BP-12], AX        ; integer 1000 ([BP-12] dead until E is saved)
    FLD     DWORD PTR [BP-6]
freq_scale:
    CMP     CL, 0
    JE      freq_scaled
    FIMUL   WORD PTR [BP-12]
    ADD     CL, 3               ; one SI decade toward 0
    JMP     freq_scale
freq_scaled:
    FSTP    DWORD PTR [BP-6]   ; result = fc in Hz

    ; -- E = floor(log10(fc)) snapped to multiple of 3 --
    FLD     DWORD PTR [BP-6]
    CALL    FLOOR_LOG3
    MOV     [BP-12], AX

    ; -- round-down for truncating x10 + FISTP in NORMALIZE --
    FSTCW   WORD PTR [BP-10]
    MOV     AX, [BP-10]
    MOV     [BP-8], AX         ; save old CW
    OR      AX, FPU_ROUND_DOWN
    MOV     [BP-10], AX
    FLDCW   WORD PTR [BP-10]

    PUSH    WORD PTR [BP-12]   ; arg 2: exponent
    LEA     AX, [BP-6]
    PUSH    AX                 ; arg 1: val_ptr
    CALL    NORMALIZE
    ADD     SP, 4              ; AX = dddd, DX = E
    MOV     [BP-10], AX        ; keep dddd
    MOV     [BP-12], DX        ; keep E

    FLDCW   WORD PTR [BP-8]    ; restore old CW

    ; -- print --
    PRINTMSG msg_fc
    MOV     AX, 'z'             ; unit2
    PUSH    AX
    MOV     AX, 'H'             ; unit1
    PUSH    AX
    PUSH    WORD PTR [BP-12]   ; exponent
    PUSH    WORD PTR [BP-10]   ; val (dddd)
    CALL    PRINT_RESULT
    ADD     SP, 8

    MOV     SP, BP
    POP     BP
    RET
FREQ    ENDP


; ---------------------------------------------------------------------
;  FINDRC -- brute-force search: find table R and C whose product is
;            closest to the target RC time constant.
;    in : [BP+4] = target_rc (ptr to REAL4)
;    out: AX = best R offset (byte index into res_start)
;         DX = best C offset (byte index into cap_start)
;
;  Optimisation: R is loaded once per outer iteration (FLD st0 dupli-
;  cates it inside the inner loop) instead of reloading every pass.
;
;  Locals: [BP-10..7] = best |diff| found so far (REAL4)
;          [BP-6]     = best_R offset
;          [BP-4]     = best_C offset
;          [BP-2]     = FPU status word scratch (8087 has no FSTSW AX)
;                     All slots are disjoint; none touches the saved BP.
; ---------------------------------------------------------------------
FINDRC  PROC
    PUSH    BP
    MOV     BP, SP
    SUB     SP, 10
    PUSH    SI
    PUSH    DI
    PUSH    BX

    MOV     BX, [BP+4]         ; target ptr
    MOV     WORD PTR [BP-10], 0FFFFh      ; init: near-max float
    MOV     WORD PTR [BP-8], 7F7Fh        ; (low/high word of 7F7FFFFFh)

    MOV     SI, 0
fr_outer:
    FLD     res_start[SI]      ; st0 = R (kept for whole inner loop)
    MOV     DI, 0
fr_inner:
    FLD     st(0)              ; duplicate R
    FMUL    cap_start[DI]      ; st0 = R*C
    FSUB    DWORD PTR [BX]     ; R*C - target
    FABS                       ; |diff|
    FCOM    DWORD PTR [BP-10]  ; compare vs best (no pop)
    FSTSW   WORD PTR [BP-2]    ; 8087: status word to memory
    MOV     AX, [BP-2]
    SAHF                       ; AH -> flags (C0->CF, C3->ZF)
    JAE     fr_discard         ; diff >= best: keep old
    FSTP    DWORD PTR [BP-10]  ; new best diff (popped)
    MOV     [BP-6], SI
    MOV     [BP-4], DI
    JMP     fr_next
fr_discard:
    FSTP    st(0)              ; pop the diff
fr_next:
    ADD     DI, 4
    CMP     DI, C_TABLE_SIZE
    JB      fr_inner
    FSTP    st(0)              ; pop R at end of inner loop
    ADD     SI, 4
    CMP     SI, R_TABLE_SIZE
    JB      fr_outer

    MOV     AX, [BP-6]         ; best R offset
    MOV     DX, [BP-4]         ; best C offset

    POP     BX
    POP     DI
    POP     SI
    MOV     SP, BP
    POP     BP
    RET
FINDRC  ENDP


; ---------------------------------------------------------------------
;  REALFREQ -- print the actual cut-off frequency of a chosen R/C pair
;              straight from the component tables (base units, so no
;              power scaling is needed):
;                 fc = 1 / (2*pi*R*C)   [Hz]
;    in : [BP+4] = r_off (word, byte index into res_start)
;         [BP+6] = c_off (word, byte index into cap_start)
;    out: prints "Real cutoff frequency: ddd.d<prefix>Hz"
;
;  Locals: same layout as FREQ.
; ---------------------------------------------------------------------
REALFREQ PROC
    PUSH    BP
    MOV     BP, SP
    SUB     SP, 12

    ; -- fc = 1 / (2*pi*R*C) --
    MOV     BX, [BP+4]         ; r_off
    FLD     res_start[BX]      ; st0 = R
    MOV     BX, [BP+6]         ; c_off (BX reused)
    FLD     cap_start[BX]      ; st0 = C, st1 = R
    FMUL                       ; st0 = R*C
    FLDPI
    FLDPI
    FADD                       ; st0 = 2*pi
    FMUL                       ; st0 = 2pi*R*C
    FLD1
    FDIV    st(0), st(1)       ; st0 = fc in Hz
    FSTP    DWORD PTR [BP-6]
    FSTP    st(0)

    ; -- E = floor(log10(fc)) snapped to multiple of 3 --
    FLD     DWORD PTR [BP-6]
    CALL    FLOOR_LOG3
    MOV     [BP-12], AX

    ; -- round-down for NORMALIZE's truncating FISTP --
    FSTCW   WORD PTR [BP-10]
    MOV     AX, [BP-10]
    MOV     [BP-8], AX
    OR      AX, FPU_ROUND_DOWN
    MOV     [BP-10], AX
    FLDCW   WORD PTR [BP-10]

    PUSH    WORD PTR [BP-12]
    LEA     AX, [BP-6]
    PUSH    AX
    CALL    NORMALIZE
    ADD     SP, 4
    MOV     [BP-10], AX
    MOV     [BP-12], DX

    FLDCW   WORD PTR [BP-8]

    ; -- print --
    PRINTMSG msg_fc_real
    MOV     AX, 'z'
    PUSH    AX
    MOV     AX, 'H'
    PUSH    AX
    PUSH    WORD PTR [BP-12]
    PUSH    WORD PTR [BP-10]
    CALL    PRINT_RESULT
    ADD     SP, 8

    MOV     SP, BP
    POP     BP
    RET
REALFREQ ENDP
