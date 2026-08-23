; =====================================================================
;  DISPLAY.ASM  --  screen output routines (values, units, circuit).
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
;  AVALUES -- echo R and C, wait for a key press.
;    in : [BP+4] = r (ptr to Qty)
;         [BP+6] = c (ptr to Qty)
;    out: AX = 0 (success), -1 (ESC at "press any key")
; ---------------------------------------------------------------------
AVALUES  PROC
    PUSH    BP
    MOV     BP, SP
    PUSH    BX
    clear_screen
    PRINTMSG msg_r_echo
    MOV     BX, [BP+4]          ; r ptr
    LEA     AX, [BX+0]          ; &r.mantissa
    PUSH    AX
    CALL    PRINTDIGITS
    ADD     SP, 2
    PUSH    WORD PTR [BX+4]     ; r.power
    CALL    PUTUNIT
    ADD     SP, 2
    NEWL

    PRINTMSG msg_c_echo
    MOV     BX, [BP+6]          ; c ptr
    LEA     AX, [BX+0]          ; &c.mantissa
    PUSH    AX
    CALL    PRINTDIGITS
    ADD     SP, 2
    PUSH    WORD PTR [BX+4]     ; c.power
    CALL    PUTUNIT
    ADD     SP, 2
    PUTC    'F'
    NEWL

    PRINTMSG msg_pause
    GETC
    CMP     AL, ESC_KEY
    JE      av_esc
    MOV     AX, 0
    JMP     av_done
av_esc:
    MOV     AX, -1
av_done:
    POP     BX
    POP     BP
    RET
AVALUES  ENDP


; ---------------------------------------------------------------------
;  PUTUNIT -- print the SI prefix for a signed decade exponent.
;    in : [BP+4] = exponent (word; low byte = signed multiple of 3)
;  Mapping: -12 'p' | -9 'n' | -6 'u' | -3 'm' | 0 (none)
;           |  3 'K' |  6 'M' |  9 'G'
; ---------------------------------------------------------------------
PUTUNIT  PROC
    PUSH    BP
    MOV     BP, SP
    MOV     CL, [BP+4]
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
    JMP     pu_end
pu_k:
    CMP     CL, 3               ; kilo
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
    POP     BP
    RET
PUTUNIT  ENDP


; ---------------------------------------------------------------------
;  CIRCUITPRINT -- draw the RC circuit labelled with R and C.
;    in : [BP+4] = r (ptr to Qty)
;         [BP+6] = c (ptr to Qty)
; ---------------------------------------------------------------------
CIRCUITPRINT PROC
    PUSH    BP
    MOV     BP, SP
    PUSH    BX
    NEWL
    NEWL
    PRINTMSG circ0
    MOV     BX, [BP+4]          ; r ptr
    LEA     AX, [BX+0]
    PUSH    AX
    CALL    PRINTDIGITS
    ADD     SP, 2
    PUSH    WORD PTR [BX+4]
    CALL    PUTUNIT
    ADD     SP, 2
    PUTC    'o'
    PUTC    'h'
    PUTC    'm'
    NEWL

    PRINTMSG circ1
    PRINTMSG circ2
    PRINTMSG circ3
    PRINTMSG circ4
    MOV     BX, [BP+6]          ; c ptr
    LEA     AX, [BX+0]
    PUSH    AX
    CALL    PRINTDIGITS
    ADD     SP, 2
    PUSH    WORD PTR [BX+4]
    CALL    PUTUNIT
    ADD     SP, 2
    PUTC    'F'
    NEWL
    PRINTMSG circ5
    PRINTMSG circ6
    POP     BX
    POP     BP
    RET
CIRCUITPRINT ENDP


; ---------------------------------------------------------------------
;  DESIGNPRINT -- print target fc, real fc (via REALFREQ), and circuit.
;    in : [BP+4] = f     (ptr to Qty for target frequency)
;         [BP+6] = r_off (word, byte offset of best R in res_start)
;         [BP+8] = c_off (word, byte offset of best C in cap_start)
; ---------------------------------------------------------------------
DESIGNPRINT PROC
    PUSH    BP
    MOV     BP, SP
    PUSH    SI
    clear_screen
    PRINTMSG msg_fc
    MOV     BX, [BP+4]          ; f ptr
    LEA     AX, [BX+0]
    PUSH    AX
    CALL    PRINTDIGITS
    ADD     SP, 2
    PUSH    WORD PTR [BX+4]     ; f.power
    CALL    PUTUNIT
    ADD     SP, 2
    PUTC    'H'
    PUTC    'z'

    PUSH    WORD PTR [BP+8]     ; c_off
    PUSH    WORD PTR [BP+6]     ; r_off
    CALL    REALFREQ
    ADD     SP, 4

    ; -- resistor label from rdigit_start -------------------------
    PRINTMSG circ0
    MOV     AX, [BP+6]          ; r_off / 4 = table index, x6 = stride
    SHR     AX, 1
    SHR     AX, 1
    MOV     BL, 6
    MUL     BL
    MOV     SI, AX              ; SI = offset of the 6-byte string
    PUTC    rdigit_start[SI]
    PUTC    rdigit_start[SI+1]
    PUTC    rdigit_start[SI+2]
    PUTC    rdigit_start[SI+3]
    PUTC    rdigit_start[SI+4]
    PUTC    rdigit_start[SI+5]
    PUTC    'o'
    PUTC    'h'
    PUTC    'm'
    NEWL

    PRINTMSG circ1
    PRINTMSG circ2
    PRINTMSG circ3
    PRINTMSG circ4

    ; -- capacitor label from cap_digits_start --------------------
    MOV     AX, [BP+8]          ; c_off / 4 = table index, x6 = stride
    SHR     AX, 1
    SHR     AX, 1
    MOV     BL, 6
    MUL     BL
    MOV     SI, AX              ; SI = offset of the 6-byte string
    PUTC    cap_digits_start[SI]
    PUTC    cap_digits_start[SI+1]
    PUTC    cap_digits_start[SI+2]
    PUTC    cap_digits_start[SI+3]
    PUTC    cap_digits_start[SI+4]
    PUTC    cap_digits_start[SI+5]
    PUTC    'F'
    NEWL

    PRINTMSG circ5
    PRINTMSG circ6
    POP     SI
    POP     BP
    RET
DESIGNPRINT ENDP
