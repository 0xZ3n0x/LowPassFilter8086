; =====================================================================
;  UTIL.ASM  --  utility procedures (digit I/O helpers).
; ---------------------------------------------------------------------
;  Included inside the .CODE segment of LOWPASSF.ASM.
;
;  Calling convention (cdecl):
;    * Args pushed right-to-left; caller cleans up (ADD SP, n).
;    * Arg 1 at [BP+4], arg 2 at [BP+6], etc.
;    * Return: AX = result.  AX = -1 = ESC, AX = -2 = invalid.
;    * Callee preserves SI, DI, BP; may clobber AX, BX, CX, DX.
; =====================================================================


ASCII_DIGIT    EQU 30H           ; '0' -- digit <-> value conversions


; ---------------------------------------------------------------------
;  NUMIN -- read a 4-digit mantissa (xxx.x) into a buffer.
;    in : [BP+4] = buf (near pointer to 4-byte buffer)
;    out: AX =  0  success
;         AX = -1  ESC pressed
;         AX = -2  non-digit key pressed
;
;  Keys echo on screen (DOS INT 21h AH=01h reads with echo); the '.'
;  printed after the third digit is cosmetic feedback only.
; ---------------------------------------------------------------------
NUMIN   PROC
    PUSH    BP
    MOV     BP, SP
    PUSH    BX
    MOV     BX, [BP+4]

    GETC
    CMP     AL, ESC_KEY
    JE      numin_esc
    CMP     AL, '0'
    JB      numin_bad
    CMP     AL, '9'
    JA      numin_bad
    SUB     AL, ASCII_DIGIT
    MOV     [BX+0], AL

    GETC
    CMP     AL, ESC_KEY
    JE      numin_esc
    CMP     AL, '0'
    JB      numin_bad
    CMP     AL, '9'
    JA      numin_bad
    SUB     AL, ASCII_DIGIT
    MOV     [BX+1], AL

    GETC
    CMP     AL, ESC_KEY
    JE      numin_esc
    CMP     AL, '0'
    JB      numin_bad
    CMP     AL, '9'
    JA      numin_bad
    SUB     AL, ASCII_DIGIT
    MOV     [BX+2], AL
    PUTC    '.'

    GETC
    CMP     AL, ESC_KEY
    JE      numin_esc
    CMP     AL, '0'
    JB      numin_bad
    CMP     AL, '9'
    JA      numin_bad
    SUB     AL, ASCII_DIGIT
    MOV     [BX+3], AL
    JMP     numin_ok
numin_bad:
    MOV     AX, -2
    JMP     numin_done
numin_esc:
    MOV     AX, -1
    JMP     numin_done
numin_ok:
    MOV     AX, 0
numin_done:
    POP     BX
    POP     BP
    RET
NUMIN   ENDP


; ---------------------------------------------------------------------
;  PRINTDIGITS -- print a 4-digit mantissa as "ddd.d".
;    in : [BP+4] = buf (near pointer to 4-byte buffer)
; ---------------------------------------------------------------------
PRINTDIGITS PROC
    PUSH    BP
    MOV     BP, SP
    MOV     BX, [BP+4]

    MOV     AL, [BX+0]
    ADD     AL, ASCII_DIGIT
    PUTC    AL
    MOV     AL, [BX+1]
    ADD     AL, ASCII_DIGIT
    PUTC    AL
    MOV     AL, [BX+2]
    ADD     AL, ASCII_DIGIT
    PUTC    AL
    PUTC    '.'
    MOV     AL, [BX+3]
    ADD     AL, ASCII_DIGIT
    PUTC    AL

    POP     BP
    RET
PRINTDIGITS ENDP


; ---------------------------------------------------------------------
;  SETDIGITS -- split a 16-bit value into 4 decimal digits.
;    in : [BP+4] = val  (word, 0..9999)
;         [BP+6] = out  (near pointer to 4-byte buffer)
;    out: out[0]=thousands, out[1]=hundreds, out[2]=tens, out[3]=ones
; ---------------------------------------------------------------------
SETDIGITS PROC
    PUSH    BP
    MOV     BP, SP
    PUSH    SI
    MOV     BX, 10
    MOV     AX, [BP+4]
    MOV     SI, [BP+6]
    XOR     DX, DX
    DIV     BX
    MOV     [SI+3], DL
    XOR     DX, DX
    DIV     BX
    MOV     [SI+2], DL
    XOR     DX, DX
    DIV     BX
    MOV     [SI+1], DL
    XOR     DX, DX
    DIV     BX
    MOV     [SI+0], DL
    POP     SI
    POP     BP
    RET
SETDIGITS ENDP
