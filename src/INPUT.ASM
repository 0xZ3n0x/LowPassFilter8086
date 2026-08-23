; =====================================================================
;  INPUT.ASM  --  keyboard input routines.
; ---------------------------------------------------------------------
;  Included inside the .CODE segment of LOWPASSF.ASM.
;
;  Calling convention (cdecl):
;    * Args pushed right-to-left; caller cleans up (ADD SP, n).
;    * Arg 1 at [BP+4], arg 2 at [BP+6], etc.
;    * Return: AX = result.  AX = -1 = ESC, AX = -2 = invalid.
;    * Callee preserves SI, DI, BP; may clobber AX, BX, CX, DX.
; =====================================================================


; ---------------------------------------------------------------------
;  POW_SELECT -- read a range key (a/b/c) and return the corresponding
;                decade exponent: base + 0 / 3 / 6 for a/b/c.
;    in : [BP+4] = base power (word, SI exponent of range 'a')
;    out: AX = selected power, or -1 (ESC), -2 (invalid key)
;
;  Replaces the original POWR / POWC / POWF trio.  The caller chooses
;  the component type by passing the base (R: 0, C: -12, F: 0).
; ---------------------------------------------------------------------
POW_SELECT PROC
    PUSH    BP
    MOV     BP, SP
    GETC
    CMP     AL, ESC_KEY
    JE      ps_esc
    CMP     AL, 'a'
    JE      ps_a
    CMP     AL, 'A'
    JE      ps_a
    CMP     AL, 'b'
    JE      ps_b
    CMP     AL, 'B'
    JE      ps_b
    CMP     AL, 'c'
    JE      ps_c
    CMP     AL, 'C'
    JE      ps_c
    MOV     AX, -2
    JMP     ps_done
ps_a:
    MOV     AX, [BP+4]
    JMP     ps_done
ps_b:
    MOV     AX, [BP+4]
    ADD     AX, 3               ; b = one SI decade above base
    JMP     ps_done
ps_c:
    MOV     AX, [BP+4]
    ADD     AX, 6               ; c = two SI decades above base
    JMP     ps_done
ps_esc:
    MOV     AX, -1
ps_done:
    POP     BP
    RET
POW_SELECT ENDP


; ---------------------------------------------------------------------
;  AINPUT -- Analysis mode input: read R then C from the user.
;    in : [BP+4] = r (ptr to Qty for resistor)
;         [BP+6] = c (ptr to Qty for capacitor)
;    out: AX = 0 (success, r and c filled in), -1 (ESC)
;
;  Fills r.mantissa, r.power, c.mantissa, c.power.  Re-prompts on
;  invalid input.  ESC at any point returns AX = -1.
; ---------------------------------------------------------------------
AINPUT  PROC
    PUSH    BP
    MOV     BP, SP
    PUSH    BX
res_retry:
    clear_screen
    PRINTMSG msg_r_range
    MOV     AX, 0               ; base 0: a=1-1000 ohm, b=kohm, c=Mohm
    PUSH    AX
    CALL    POW_SELECT
    ADD     SP, 2
    CMP     AX, -2
    JE      res_retry
    CMP     AX, -1
    JE      ainput_done

    MOV     BX, [BP+4]          ; r ptr
    MOV     [BX+4], AX          ; r.power = selected power

    PRINTMSG msg_r_val
    LEA     AX, [BX+0]          ; &r.mantissa
    PUSH    AX
    CALL    NUMIN
    ADD     SP, 2
    CMP     AX, -1
    JE      ainput_done
    CMP     AX, -2
    JE      res_retry

cap_retry:
    clear_screen
    PRINTMSG msg_c_range
    MOV     AX, -12             ; base -12: a=pF, b=nF, c=uF
    PUSH    AX
    CALL    POW_SELECT
    ADD     SP, 2
    CMP     AX, -2
    JE      cap_retry
    CMP     AX, -1
    JE      ainput_done

    MOV     BX, [BP+6]          ; c ptr
    MOV     [BX+4], AX          ; c.power = selected power

    PRINTMSG msg_c_val
    LEA     AX, [BX+0]          ; &c.mantissa
    PUSH    AX
    CALL    NUMIN
    ADD     SP, 2
    CMP     AX, -2
    JE      cap_retry
    CMP     AX, -1
    JE      ainput_done
    ; fall through: AX = 0 (success) from NUMIN.
ainput_done:
    POP     BX
    POP     BP
    RET
AINPUT  ENDP


; ---------------------------------------------------------------------
;  FINPUT -- Design mode input: read target cut-off frequency, compute
;            the required RC product.
;    in : [BP+4] = f     (ptr to Qty for frequency)
;         [BP+6] = rc_out (ptr to REAL4 for the RC product)
;    out: AX = 0 (success), -1 (ESC)
;         f.mantissa and f.power filled in; *rc_out = 1/(2*pi*f)
;
;  Locals: [BP-2] = N (packed 4-digit mantissa), then 1000
;          [BP-4] = ten (word, 10)
; ---------------------------------------------------------------------
FINPUT  PROC
    PUSH    BP
    MOV     BP, SP
    SUB     SP, 4
    PUSH    SI
    PUSH    DI
    PUSH    BX
fin_retry:
    clear_screen
    PRINTMSG msg_f_range
    MOV     AX, 0               ; base 0: a=Hz, b=KHz, c=MHz
    PUSH    AX
    CALL    POW_SELECT
    ADD     SP, 2
    CMP     AX, -2
    JE      fin_retry
    CMP     AX, -1
    JE      fin_done

    MOV     BX, [BP+4]          ; f ptr
    MOV     [BX+4], AX          ; f.power = selected power

    PRINTMSG msg_f_val
    LEA     AX, [BX+0]          ; &f.mantissa
    PUSH    AX
    CALL    NUMIN
    ADD     SP, 2
    CMP     AX, -1
    JE      fin_done
    CMP     AX, -2
    JE      fin_retry

    ; -- build the frequency mantissa ddd.d on the FPU stack ----
    MOV     AX, 10
    MOV     [BP-4], AX         ; integer 10 for the final /10
    MOV     AX, 0               ; N = 0
    MOV     BX, [BP+4]          ; f ptr
    MOV     SI, 0
load_f:
    MOV     DX, 10
    MUL     DX                  ; AX *= 10 (max 9990, fits a word)
    MOV     DL, [BX+SI]         ; f.mantissa[SI]
    MOV     DH, 0
    ADD     AX, DX              ; AX = AX*10 + digit
    INC     SI
    CMP     SI, 4
    JB      load_f
    MOV     [BP-2], AX         ; N = d0d1d2d3 (0..9999)
    FILD    WORD PTR [BP-2]
    FIDIV   WORD PTR [BP-4]     ; st0 = mantissa = N/10

    MOV     AX, 1000
    MOV     [BP-2], AX         ; integer 1000 ([BP-2] dead after the FILD)

    ; -- apply the SI decade chosen by the user -----------------
    MOV     CL, [BX+4]          ; f.power (low byte)
    CMP     CL, 0
    JE      have_freq
    FIMUL   WORD PTR [BP-2]
    CMP     CL, 3               ; one SI decade up?
    JE      have_freq
    FIMUL   WORD PTR [BP-2]
have_freq:
    ; st0 = frequency in Hz.  Convert to the required RC product.
    FLDPI
    FLDPI
    FADD                       ; st0 = 2*pi, st1 = f
    FMUL    st(1), st(0)       ; st1 = 2*pi*f
    FSTP    st(0)              ; drop 2pi
    FLD1
    FDIV    st(0), st(1)       ; st0 = 1/(2*pi*f) = required RC
    MOV     BX, [BP+6]          ; rc_out ptr
    FSTP    DWORD PTR [BX]
    FSTP    st(0)
fin_done:
    POP     BX
    POP     DI
    POP     SI
    MOV     SP, BP
    POP     BP
    RET
FINPUT  ENDP
