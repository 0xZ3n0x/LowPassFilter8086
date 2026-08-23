; =====================================================================
;  MACROS.INC  --  I/O and screen macros for the RC low-pass filter
; ---------------------------------------------------------------------
;  Included once by LOWPASSF.ASM inside .CODE, before any code that
;  uses them. Defines no data and emits no code by itself.
;
;  Conventions:
;    * DOS INT 21h services handle all character I/O.
;    * BIOS INT 10h services handle screen clearing / video mode.
;    * Every macro preserves AX and DX (the registers they touch),
;      except GETC, which returns the pressed key in AL (by design).
;
;  NUMIN, PRINTDIGITS and SETDIGITS were macros in the original program;
;  they are now PROCs in UTIL.ASM with proper stack-based arguments.
; =====================================================================


; ---------------------------------------------------------------------
;  PUTC  char          -- print a single character on the screen.
;  Uses DOS function 02h (write character, DL = char).
; ---------------------------------------------------------------------
PUTC    MACRO   char
        PUSH    AX
        PUSH    DX
        MOV     DL, char
        MOV     AH, 2
        INT     21h
        POP     DX
        POP     AX
        ENDM


; ---------------------------------------------------------------------
;  clear_screen        -- erase the screen and home the cursor.
;  BIOS INT 10h, AH=06h scrolls the whole window up by 0 rows (clears),
;  then AH=02h moves the cursor to row 0, column 0.
;  CX/DX bound the cleared window: CX = upper-left corner (0,0), DX =
;  lower-right corner (DH/DL are row/col indices, not a count).  Mode
;  12h has only 30 text rows, so row 60 is clamped by the BIOS.
; ---------------------------------------------------------------------
clear_screen MACRO
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX
        MOV     AX, 0600h
        MOV     BH, 0
        MOV     CX, 0
        MOV     DH, 60         ; lower-right row index (BIOS clamps)
        MOV     DL, 80         ; lower-right col index (0-based)
        INT     10h
        MOV     AH, 2          ; set cursor position
        MOV     DX, 0
        MOV     BH, 0
        INT     10h
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        ENDM


; ---------------------------------------------------------------------
;  PRINTMSG  message   -- print a '$'-terminated string.
;  Uses DOS function 09h (DS:DX -> string ending in '$').
; ---------------------------------------------------------------------
PRINTMSG MACRO  message
        PUSH    AX
        PUSH    DX
        MOV     DX, OFFSET message
        MOV     AH, 9
        INT     21h
        POP     DX
        POP     AX
        ENDM


; ---------------------------------------------------------------------
;  GETC                -- read one key from the keyboard, with echo.
;  Uses DOS function 01h. On return AL holds the key's ASCII code
;  (ESC = 27).
; ---------------------------------------------------------------------
GETC    MACRO
        MOV     AH, 1
        INT     21h
        ENDM


; ---------------------------------------------------------------------
;  NEWL                -- move the cursor to the start of the next line
;                        by printing CR (13) then LF (10).
; ---------------------------------------------------------------------
NEWL    MACRO
        PUTC    13
        PUTC    10
        ENDM
