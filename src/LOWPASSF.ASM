; =====================================================================
;  LOWPASSF.ASM  --  RC Low-Pass Filter Design Calculator (refactor)
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
;  This file is the assembly spine: it sets the memory model, includes
;  the macros, data tables and procedures, and contains the main flow.
;  Behaviour is byte-for-byte identical to the original LOWPASSF.asm in
;  ../orig/ ; only the organisation and comments have changed.
;
;  Build (inside DOSBox, with MASM 6.11 on the path, from this src dir):
;        ML.EXE /Fl LOWPASSF.ASM
;  (ML finds the INCLUDE files in the same directory automatically.)
; =====================================================================

        .MODEL  SMALL
        .STACK

        INCLUDE MACROS.INC       ; I/O + screen macros (no segment)

        .DATA
        INCLUDE DATA.INC         ; messages, circuit art, state, constants
        INCLUDE RES.INC          ; R_dec0..6 + rdigit0..6 (contiguous)
        INCLUDE CAP.INC          ; C_dec0..6 + cdigit0..6 (contiguous)

        .CODE
        INCLUDE MATH.ASM         ; LOADRC, STEADY, FREQ, FINDRC, REALFREQ
        INCLUDE INPUT.ASM        ; POWR, POWC, POWF, AINPUT, FINPUT
        INCLUDE DISPLAY.ASM      ; AVALUES, PUTUNIT, CIRCUITPRINT, DESIGNPRINT

        .STARTUP
        MOV     AH, 0
        MOV     AL, 12h          ; VGA 640x480, 16-colour graphics mode
        INT     10h

; ---------------------------------------------------------------------
;  Main menu: read a key, dispatch to Analysis / Design, redraw on any
;  other key, exit on ESC.  After one operation the program ends.
; ---------------------------------------------------------------------
startlbl:
        clear_screen
        PRINTMSG msg
        GETC
        CMP     AL, 27           ; ESC -> exit
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
analysis:
        CALL    AINPUT           ; read R and C
        CMP     AL, 27
        JE      endl
        CALL    AVALUES          ; echo R and C, "press any key"
        CMP     AL, 27
        JE      endl
        clear_screen
        CALL    LOADRC           ; FPU st0 = R*C ; resultrc = R*C
        CALL    STEADY           ; print transient time
        CALL    FREQ             ; print cut-off frequency
        CALL    CIRCUITPRINT     ; draw the circuit with R and C
        JMP     endl

; -- b) Design -------------------------------------------------------
design:
        CALL    FINPUT           ; read target fc ; result = required RC
        CMP     AL, 27
        JE      endl
        CALL    FINDRC           ; brute-force best standard R-C pair
        CALL    DESIGNPRINT      ; print target, real fc and circuit

endl:
        .EXIT
        END
