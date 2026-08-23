; =====================================================================
;  LOWPASSF.ASM  --  RC Low-Pass Filter Design Calculator
; ---------------------------------------------------------------------
;  A passive RC low-pass filter design tool.  Runs on the x86 real-mode
;  FPU under DOS (INT 10h / INT 21h) in 640x480 graphics mode (VGA
;  mode 12h).  Assemble with MASM 6.11 and link, then run under DOSBox.
;
;  Two modes, selected from the main menu:
;     a) Analysis   -- R and C in  ->  cut-off frequency + rise time
;     b) Design     -- target fc in ->  best standard R-C pair + real fc
;
;  ESC exits the program at any time; the program never blocks in an
;  infinite loop.  Values are entered as a 4-digit engineering mantissa
;  ddd.d together with an SI-decade range key (a/b/c).
;
;  Calling convention (cdecl):
;    * Args pushed right-to-left; caller cleans up (ADD SP, n).
;    * Arg 1 at [BP+4], arg 2 at [BP+6], etc.
;    * Return: AX = primary, DX = secondary.
;    * AX = -1 = ESC, AX = -2 = invalid key (input PROCs).
;    * Callee preserves SI, DI, BP; may clobber AX, BX, CX, DX.
;    * REAL4 values pass via pointers; the only FPU stack crossing
;      is FLOOR_LOG3 (consumes st0, pops it).
;
;  This file is the assembly spine: it sets the memory model, includes
;  the macros, data tables and procedures, and contains the main flow
;  with stack-allocated locals (no global mutable state).
;
;  Build (inside DOSBox, with MASM 6.11 on the path, from this src dir):
;        BUILD
;    or  ML.EXE /Fl LOWPASSF.ASM
; =====================================================================

.MODEL  SMALL
.8086                   ; Enable 8086 CPU instructions
.8087                   ; Enable 8087 Math Coprocessor instructions
.STACK 1024

.DATA
    INCLUDE DATA.INC         ; Qty STRUCT, messages, circuit art
    INCLUDE RES.INC          ; res_start..end + rdigit_start..end
    INCLUDE CAP.INC          ; cap_start..end + cap_digits_start..end

.CODE
    INCLUDE MACROS.INC       ; I/O + screen macros (no segment)

ESC_KEY        EQU 27            ; shared by LOWPASSF + included modules

    INCLUDE UTIL.ASM         ; NUMIN, PRINTDIGITS, SETDIGITS
    INCLUDE INPUT.ASM        ; POW_SELECT, AINPUT, FINPUT
    INCLUDE DISPLAY.ASM      ; AVALUES, PUTUNIT, CIRCUITPRINT, DESIGNPRINT
    INCLUDE MATH.ASM         ; FLOOR_LOG3, NORMALIZE, PRINT_RESULT,
                             ; LOADRC, STEADY, FREQ, FINDRC, REALFREQ

.STARTUP
    MOV     AH, 0
    MOV     AL, 12h          ; VGA 640x480, 16-colour graphics mode
    INT     10h
    FINIT                    ; reset FPU once, up front

; ---------------------------------------------------------------------
;  Main menu: read a key, dispatch to Analysis / Design, redraw on any
;  other key, exit on ESC.  After one operation the program ends.
; ---------------------------------------------------------------------
startlbl:
    clear_screen
    PRINTMSG msg_menu
    GETC
    CMP     AL, ESC_KEY      ; ESC -> exit
    JE      endl
    CMP     AL, 'a'
    JE      analysis
    CMP     AL, 'A'
    JE      analysis
    CMP     AL, 'b'
    JE      design
    CMP     AL, 'B'
    JE      design
    JMP     startlbl         ; unknown key -> redraw menu

; -- a) Analysis -----------------------------------------------------
;  Stack frame (SUB SP, 16):
;    [BP-6]   = r_qty  (Qty, 6 bytes)
;    [BP-12]  = c_qty  (Qty, 6 bytes)
;    [BP-16]  = rc_val (REAL4)
analysis:
    PUSH    BP
    MOV     BP, SP
    SUB     SP, 16

    ; AINPUT(r, c) -> AX = 0 / -1
    LEA     AX, [BP-12]      ; &c_qty
    PUSH    AX
    LEA     AX, [BP-6]       ; &r_qty
    PUSH    AX
    CALL    AINPUT
    ADD     SP, 4
    CMP     AX, -1
    JE      analysis_done

    ; AVALUES(r, c) -> AX = 0 (any key) / -1 (ESC)
    LEA     AX, [BP-12]
    PUSH    AX
    LEA     AX, [BP-6]
    PUSH    AX
    CALL    AVALUES
    ADD     SP, 4
    CMP     AX, -1             ; AVALUES returns -1 on ESC (not ESC_KEY)
    JE      analysis_done

    clear_screen

    ; LOADRC(r, c, rc_out)
    LEA     AX, [BP-16]      ; &rc_val
    PUSH    AX
    LEA     AX, [BP-12]      ; &c_qty
    PUSH    AX
    LEA     AX, [BP-6]       ; &r_qty
    PUSH    AX
    CALL    LOADRC
    ADD     SP, 6

    ; STEADY(rc_ptr, r, c)
    LEA     AX, [BP-12]
    PUSH    AX
    LEA     AX, [BP-6]
    PUSH    AX
    LEA     AX, [BP-16]
    PUSH    AX
    CALL    STEADY
    ADD     SP, 6

    ; FREQ(rc_ptr, r, c)
    LEA     AX, [BP-12]
    PUSH    AX
    LEA     AX, [BP-6]
    PUSH    AX
    LEA     AX, [BP-16]
    PUSH    AX
    CALL    FREQ
    ADD     SP, 6

    ; CIRCUITPRINT(r, c)
    LEA     AX, [BP-12]
    PUSH    AX
    LEA     AX, [BP-6]
    PUSH    AX
    CALL    CIRCUITPRINT
    ADD     SP, 4

analysis_done:
    MOV     SP, BP
    POP     BP
    JMP     endl

; -- b) Design -------------------------------------------------------
;  Stack frame (SUB SP, 14):
;    [BP-6]   = f_qty     (Qty, 6 bytes)
;    [BP-10]  = target_rc (REAL4)
;    [BP-12]  = r_off     (word)
;    [BP-14]  = c_off     (word)
design:
    PUSH    BP
    MOV     BP, SP
    SUB     SP, 14

    ; FINPUT(f, rc_out) -> AX = 0 / -1
    LEA     AX, [BP-10]      ; &target_rc
    PUSH    AX
    LEA     AX, [BP-6]       ; &f_qty
    PUSH    AX
    CALL    FINPUT
    ADD     SP, 4
    CMP     AX, -1
    JE      design_done

    ; FINDRC(target_rc) -> AX = R offset, DX = C offset
    LEA     AX, [BP-10]
    PUSH    AX
    CALL    FINDRC
    ADD     SP, 2
    MOV     [BP-12], AX      ; r_off
    MOV     [BP-14], DX      ; c_off

    ; DESIGNPRINT(f, r_off, c_off)
    PUSH    WORD PTR [BP-14] ; c_off
    PUSH    WORD PTR [BP-12] ; r_off
    LEA     AX, [BP-6]       ; &f_qty
    PUSH    AX
    CALL    DESIGNPRINT
    ADD     SP, 6

design_done:
    MOV     SP, BP
    POP     BP

endl:
.EXIT
END
