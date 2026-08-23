; =====================================================================
;  macros.inc  --  I/O and screen macros for the RC low-pass filter
; ---------------------------------------------------------------------
;  Included once near the top of LOWPASSF.asm, before any segment that
;  uses them. Defines no data and emits no code by itself.
;
;  Conventions:
;    * DOS INT 21h services handle all character I/O.
;    * BIOS INT 10h services handle screen clearing / video mode.
;    * Every macro preserves AX and DX (the registers they touch),
;      except GETC, which returns the pressed key in AL (by design).
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
; ---------------------------------------------------------------------
clear_screen MACRO
        PUSHA
        MOV     AX, 0600h
        MOV     BH, 0
        MOV     CX, 0
        MOV     DH, 60         ; window height (rows)
        MOV     DL, 80         ; window width  (cols)
        INT     10h
        MOV     AH, 2          ; set cursor position
        MOV     DX, 0
        MOV     BH, 0
        INT     10h
        POPA
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
;  Uses DOS function 01h. The pressed key (ASCII) is returned in AL.
;  On return AL holds: the key's ASCII value, or 27 (ESC) if ESC was
;  pressed.
; ---------------------------------------------------------------------
GETC    MACRO
        MOV     AH, 1
        INT     21h
        ENDM


; ---------------------------------------------------------------------
;  NUMIN  dataloc      -- read a 4-digit mantissa of the form xxx.x
;  into the 4-byte buffer 'dataloc' (one byte per digit, as raw value).
;
;  Behaviour (identical to the original program):
;    * Four numeric keys are expected in this exact order: d0 d1 d2 . d3
;      A '.' is printed after the third digit so the echo looks like
;      "xxx." while the user types the final digit.
;    * Each digit is converted from ASCII to its numeric value
;      (SUB 30h) and stored at dataloc[0..3].
;    * If a non-digit key is pressed at any position, the macro stops,
;      sets AL = 0   (invalid flag) and returns.
;    * If ESC is pressed at any position, the macro stops, leaves
;      AL = 27 (ESC flag) and returns.
;    * On a full, valid read, AL holds the ASCII of the last digit
;      (>= '0'), which callers treat as "valid, not ESC".
; ---------------------------------------------------------------------
NUMIN   MACRO   dataloc
        LOCAL   done, invalid
        ; -- digit 0 --
        GETC
        CMP     AL, 27
        JE      done
        CMP     AL, '0'
        JB      invalid
        CMP     AL, '9'
        JA      invalid
        MOV     dataloc[0], AL
        SUB     dataloc[0], 30h
        ; -- digit 1 --
        GETC
        CMP     AL, 27
        JE      done
        CMP     AL, '0'
        JB      invalid
        CMP     AL, '9'
        JA      invalid
        MOV     dataloc[1], AL
        SUB     dataloc[1], 30h
        ; -- digit 2 --
        GETC
        CMP     AL, 27
        JE      done
        CMP     AL, '0'
        JB      invalid
        CMP     AL, '9'
        JA      invalid
        MOV     dataloc[2], AL
        SUB     dataloc[2], 30h
        PUTC    '.'            ; echo the decimal point
        ; -- digit 3 --
        GETC
        CMP     AL, 27
        JE      done
        CMP     AL, '0'
        JB      invalid
        CMP     AL, '9'
        JA      invalid
        MOV     dataloc[3], AL
        SUB     dataloc[3], 30h
        JMP     done
invalid:
        MOV     AL, 0          ; flag: non-digit entered
done:
        ENDM


; ---------------------------------------------------------------------
;  PRINTDIGITS  digitloc
;                     -- print a 4-digit mantissa stored in
;                        digitloc[0..3] as "ddd.d" (no sign, no prefix).
;  Each byte is converted back to ASCII (ADD 30h) and printed; the '.'
;  is printed between byte 2 and byte 3.
; ---------------------------------------------------------------------
PRINTDIGITS MACRO digitloc
        PUSH    AX
        MOV     AL, digitloc[0]
        ADD     AL, 30h
        PUTC    AL
        MOV     AL, digitloc[1]
        ADD     AL, 30h
        PUTC    AL
        MOV     AL, digitloc[2]
        ADD     AL, 30h
        PUTC    AL
        PUTC    '.'
        MOV     AL, digitloc[3]
        ADD     AL, 30h
        PUTC    AL
        POP     AX
        ENDM


; ---------------------------------------------------------------------
;  SETDIGITS           -- split the 16-bit value in 'tmp' into 4 decimal
;                        digits (thousands..units) stored in 'digits'.
;  digits[3] = ones, digits[2] = tens, digits[1] = hundreds,
;  digits[0] = thousands.  tmp is expected to hold a value in 0..9999.
; ---------------------------------------------------------------------
SETDIGITS MACRO
        MOV     BX, 10
        MOV     AX, tmp
        XOR     DX, DX
        DIV     BX
        MOV     digits[3], DL
        XOR     DX, DX
        DIV     BX
        MOV     digits[2], DL
        XOR     DX, DX
        DIV     BX
        MOV     digits[1], DL
        XOR     DX, DX
        DIV     BX
        MOV     digits[0], DL
        ENDM


; ---------------------------------------------------------------------
;  NEWL                -- move the cursor to the start of the next line
;                        by printing CR (13) then LF (10).
; ---------------------------------------------------------------------
NEWL    MACRO
        PUTC    13
        PUTC    10
        ENDM
