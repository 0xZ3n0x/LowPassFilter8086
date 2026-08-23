.MODEL SMALL
.STACK

PUTC    MACRO   char
        PUSH    AX
		PUSH 	DX
        MOV     DL, char;Character is in DL
		MOV     AH, 2;Char print interrupt
        INT     21h     
        POP		DX
		POP     AX
ENDM

clear_screen macro
    pusha
    mov ax, 0600h
    mov bh, 0
    mov cx, 0
    mov dh, 60;Heigth
    mov dl, 80;Width
    int 10h;Clear screen
    mov ah,2;Set cursor interrupt
    mov dx,0
    mov bh,0
    int 10h;Set cursor to (0,0)
    popa
endm

PRINTMSG MACRO message
	PUSH AX
	PUSH DX
	MOV DX,offset message
	MOV AH,9
	INT 21H;Print message interrupt
	POP DX
	POP AX
	
ENDM

GETC MACRO
	mov ah,1
	int 21h;Get character with echo interrupt
ENDM

NUMIN MACRO dataloc
LOCAL numinesc,numinesc2
	GETC
	CMP AL,27;Is button ESC
	JE numinesc
	CMP AL,48;Is button a number
	JB numinesc2
	CMP AL,57;Is button a number
	JA numinesc2
	MOV dataloc[0],AL;Copy button to dataloc
	SUB dataloc[0],30H;Convert ASCII to number
	GETC
	CMP AL,27;Is button ESC
	JE numinesc
	CMP AL,48;Is button a number
	JB numinesc2
	CMP AL,57;Is button a number
	JA numinesc2
	MOV dataloc[1],AL;Copy button to dataloc
	SUB dataloc[1],30H;Convert ASCII to number
	GETC
	CMP AL,27;Is button ESC
	JE numinesc
	CMP AL,48;Is button a number
	JB numinesc2
	CMP AL,57;Is button a number
	JA numinesc2
	mov dataloc[2],AL;Copy button to dataloc
	SUB dataloc[2],30H;Convert ASCII to number
	PUTC '.'
	GETC
	CMP AL,27;Is button ESC
	JE numinesc
	CMP AL,48;Is button a number
	JB numinesc2
	CMP AL,57;Is button a number
	JA numinesc2
	MOV dataloc[3],AL;Copy button to dataloc
	SUB dataloc[3],30H;Convert ASCII to number
	

	jmp numinesc
	numinesc2:
	MOV AL,0;Flag for non number button
	numinesc:
	
ENDM

PRINTDIGITS MACRO digitloc
	PUSH AX
	MOV AL,digitloc[0];Copy digit to AL
	ADD AL,30H;Conver to ASCII
	PUTC AL

	MOV AL,digitloc[1];Copy digit to AL
	ADD AL,30H;Conver to ASCII
	PUTC AL

	MOV AL,digitloc[2];Copy digit to AL
	ADD AL,30H;Conver to ASCII
	PUTC AL
	PUTC '.'

	MOV AL,digitloc[3];Copy digit to AL
	ADD AL,30H;Conver to ASCII
	PUTC AL
	POP AX
ENDM

SETDIGITS MACRO
	mov bx,10;Divisor is 10
	mov ax,tmp;Number is tmp 
	;Digits variable stores 4 digits
	xor dx,dx
	div bx
	mov digits[3],dl
	xor dx,dx
	div bx
	mov digits[2],dl
	xor dx,dx
	div bx
	mov digits[1],dl
	xor dx,dx
	div bx
	mov digits[0],dl
ENDM

NEWL MACRO
	PUTC 13
	PUTC 10
ENDM
.DATA
msg db "a.Analysis",13,10,"b.Design",13,10,"Enter the operation:",'$'
msg2 db "a.1-1000 ohm",13,10,"b.1K-1000K ohm",13,10,"c.1M-1000M ohm",13,10,"Enter the range of Resistor:",'$'
msg3 db 13,10,"Enter the resistor value:",'$'
msg4 db "a.1p-1000p farad",13,10,"b.1n-1000n farad",13,10,"c.1u-1000u farad",13,10,"Enter the range of Capacitor:",'$'
msg5 db 13,10,"Enter the capacitor value:",'$'
msg6 db "Entered resistor value:",'$'
msg7 db "Entered capacitor value:",'$'
msg8 db "Press any key to continue...",'$'
msg9 db "Transient time for steady state:",'$'
msg10 db "Cutoff frequency:",'$'
msg11 db "a.1-1000 Hz",13,10,"b.1K-1000K Hz",13,10,"c.1M-1000M Hz",13,10,"Enter the range of frequency:",'$'
msg12 db 13,10,"Enter the frequency value:",'$'
msg13 db 13,10,"Real cutoff frequency:",'$'
circ0 db "      ",'$'
circ1 db " -----/\/\/\---+---",13,10,'$'
circ2 db "               |   ",13,13,'$'
circ3 db "             ----- ",13,10,'$'
circ4 db "             ----- ",'$'
circ5 db "               |   ",13,10,'$'
circ6 db " --------------+---",13,10,'$'
fpower db ?
fnumber db 4 dup(?)
rpower db ?
rnumber db 4 dup(?)
cpower db ?
cnumber db 4 dup(?)
digits db 4 dup(?)
decvals dword 100.0,10.0,1.0,0.1
result dword ?
resultrc dword ?
digitchk word ?
dec1000 dword 1000 
tmp word ?
ln10 dword 040135d8eH
pitwo dword 040c90fdbH
three dword 3
flag word 0
tmpSI word ?
tmpDI word ?
array0 dword 3f800000H,3f8ccccdH,3f99999aH,3fa66666H,3fc00000H,3fcccccdH,3fe66666H,40000000H,400ccccdH,4019999aH,402ccccdH,40400000H,40533333H,40666666H,4079999aH,4089999aH,40966666H,40a33333H,40b33333H,40c66666H,40d9999aH,40f00000H,41033333H,4111999aH
array1 dword 41200000H,41300000H,41400000H,41500000H,41700000H,41800000H,41900000H,41a00000H,41b00000H,41c00000H,41d80000H,41f00000H,42040000H,42100000H,421c0000H,422c0000H,423c0000H,424c0000H,42600000H,42780000H,42880000H,42960000H,42a40000H,42b60000H
array2 dword 42c80000H,42dc0000H,42f00000H,43020000H,43160000H,43200000H,43340000H,43480000H,435c0000H,43700000H,43870000H,43960000H,43a50000H,43b40000H,43c30000H,43d70000H,43eb0000H,43ff0000H,440c0000H,441b0000H,442a0000H,443b8000H,444d0000H,44638000H
array3 dword 447a0000H,44898000H,44960000H,44a28000H,44bb8000H,44c80000H,44e10000H,44fa0000H,45098000H,45160000H,4528c000H,453b8000H,454e4000H,45610000H,4573c000H,45866000H,4592e000H,459f6000H,45af0000H,45c1c000H,45d48000H,45ea6000H,46002000H,460e3000H
array4 dword 461c4000H,462be000H,463b8000H,464b2000H,466a6000H,467a0000H,468ca000H,469c4000H,46abe000H,46bb8000H,46d2f000H,46ea6000H,4700e800H,470ca000H,47185800H,4727f800H,47379800H,47473800H,475ac000H,47723000H,4784d000H,47927c00H,47a02800H,47b1bc00H
array5 dword 47c35000H,47d6d800H,47ea6000H,47fde800H,48127c00H,481c4000H,482fc800H,48435000H,4856d800H,486a6000H,4883d600H,48927c00H,48a12200H,48afc800H,48be6e00H,48d1f600H,48e57e00H,48f90600H,4908b800H,49175e00H,49260400H,49371b00H,49483200H,495e2b00H
array6 dword 49742400H,49864700H,49927c00H,499eb100H,49b71b00H,49c35000H,49dbba00H,49f42400H,4a064700H,4a127c00H,4a24cb80H,4a371b00H,4a496a80H,4a5bba00H,4a6e0980H,4a8339c0H,4a8f6ec0H,4a9ba3c0H,4aaae600H,4abd3580H,4acf8500H,4ae4e1c0H,4afa3e80H,4b0adae0H
rdigit0 byte "001.0 ","001.1 ","001.2 ","001.3 ","001.5 ","001.6 ","001.8 ","002.0 ","002.2 ","002.4 ","002.7 ","003.0 ","003.3 ","003.6 ","003.9 ","004.3 ","004.7 ","005.1 ","005.6 ","006.2 ","006.8 ","007.5 ","008.2 ","009.1 "
rdigit1 byte "010.0 ","011.0 ","012.0 ","013.0 ","015.0 ","016.0 ","018.0 ","020.0 ","022.0 ","024.0 ","027.0 ","030.0 ","033.0 ","036.0 ","039.0 ","043.0 ","047.0 ","051.0 ","056.0 ","062.0 ","068.0 ","075.0 ","082.0 ","091.0 "
rdigit2 byte "100.0 ","110.0 ","120.0 ","130.0 ","150.0 ","160.0 ","180.0 ","200.0 ","220.0 ","240.0 ","270.0 ","300.0 ","330.0 ","360.0 ","390.0 ","430.0 ","470.0 ","510.0 ","560.0 ","620.0 ","680.0 ","750.0 ","820.0 ","910.0 "
rdigit3 byte "001.0K","001.1K","001.2K","001.3K","001.5K","001.6K","001.8K","002.0K","002.2K","002.4K","002.7K","003.0K","003.3K","003.6K","003.9K","004.3K","004.7K","005.1K","005.6K","006.2K","006.8K","007.5K","008.2K","009.1K"
rdigit4 byte "010.0K","011.0K","012.0K","013.0K","015.0K","016.0K","018.0K","020.0K","022.0K","024.0K","027.0K","030.0K","033.0K","036.0K","039.0K","043.0K","047.0K","051.0K","056.0K","062.0K","068.0K","075.0K","082.0K","091.0K"
rdigit5 byte "100.0K","110.0K","120.0K","130.0K","150.0K","160.0K","180.0K","200.0K","220.0K","240.0K","270.0K","300.0K","330.0K","360.0K","390.0K","430.0K","470.0K","510.0K","560.0K","620.0K","680.0K","750.0K","820.0K","910.0K"
rdigit6 byte "001.0M","001.1M","001.2M","001.3M","001.5M","001.6M","001.8M","002.0M","002.2M","002.4M","002.7M","003.0M","003.3M","003.6M","003.9M","004.3M","004.7M","005.1M","005.6M","006.2M","006.8M","007.5M","008.2M","009.1M"
cdigit0 byte "010.0p","012.0p","015.0p","018.0p","022.0p","027.0p","033.0p","039.0p","047.0p","056.0p","068.0p","082.0p"
cdigit1 byte "100.0p","120.0p","150.0p","180.0p","220.0p","270.0p","330.0p","390.0p","470.0p","560.0p","680.0p","820.0p"
cdigit2 byte "001.0n","001.2n","001.5n","001.8n","002.2n","002.7n","003.3n","003.9n","004.7n","005.6n","006.8n","008.2n"
cdigit3 byte "010.0n","012.0n","015.0n","018.0n","022.0n","027.0n","033.0n","039.0n","047.0n","056.0n","068.0n","082.0n"
cdigit4 byte "100.0n","120.0n","150.0n","180.0n","220.0n","270.0n","330.0n","390.0n","470.0n","560.0n","680.0n","820.0n"
cdigit5 byte "001.0u","001.2u","001.5u","001.8u","002.2u","002.7u","003.3u","003.9u","004.7u","005.6u","006.8u","008.2u"
cdigit6 byte "010.0u","022.0u","033.0u","047.0u"
array7 dword 2d2febffH,2d531b32H,2d83f0ffH,2d9e5466H,2dc18399H,2ded7e98H,2e1122b2H,2e2b8619H,2e4eb54cH,2e764a65H,2e958899H,2eb451e5H,2edbe6ffH,2f03f0ffH,2f24ed3fH,2f45e980H,2f71e47fH,2f946f1fH,2fb56b5eH,2fd6679fH,30013150H,3019ee7fH,303aeabfH,3061665eH
array8 dword 3089705fH,30a4ed3fH,30ce288fH,30f763e0H,31172ecfH,31398ae7H,3162c636H,318600c3H,31a17da4H,31c06a1fH,31e9a56fH,320cdffbH,322bcc77H,324e288fH,3280d959H,329a9e6cH,32bcfa83H,32e7eda1H,330dbbe2H,332780f4H,3349dd0dH,337084a7H,33920765H,33b017faH
array9 dword 33d6bf95H,3400d959H,34210fafH,34414607H,346c3924H,3490f485H,34b12adaH,34d16131H,34fc5450H,351652e8H,3536893eH,355c1df8H,358637bdH,35a10fafH,35c9539bH,35f19789H,3613a3b6H,363531a6H,365d7590H,3682dcbfH,369db4b2H,36bbe7a2H,36e42b8eH,370992bbH,3727c5acH,37b88ca4H,380a697bH,384521deH

.CODE
.STARTUP
MOV AH,0
MOV AL,12h;640x480 video mode
INT 10h
startlbl:
clear_screen
PRINTMSG msg
GETC
CMP AL,27;Is button ESC
JE endl
CMP AL,'a'
JE analysis
CMP AL,'A'
JE analysis 
CMP AL,'b'
JE design
CMP AL,'B'
JE design
JMP startlbl 

analysis:
call AINPUT;Take R and C values
CMP AL,27;Is button ESC
JE endl
call AVALUES;Print R and C values
CMP AL,27;Is button ESC
JE endl
clear_screen
CALL LOADRC;Load R and C values to FPU
CALL STEADY;Calculate transient steady state time
CALL FREQ;Calculate frequency
CALL CIRCUITPRINT;Print the cicuit

JMP endl

design:

CALL FINPUT;Take freq value
CMP AL,27
JE endl
CALL FINDRC;Bruteforce for R C values
CALL DESIGNPRINT;Print the circuit

endl:
.EXIT
POWR PROC
	GETC
	CMP AL,27
	JE powresc
	CMP AL,'a'
	JE LBL1
	CMP AL,'A'
	JE LBL1
	CMP AL,'b'
	JE LBL2
	CMP AL,'B'
	JE LBL2
	CMP AL,'c'
	JE LBL3
	CMP AL,'C'
	JE LBL3
	MOV AL,0
	RET
	LBL1:
	mov rpower,0;1-1000 ohm
	ret
	LBL2:
	mov rpower,3;1-1000 Kohm
	ret
	LBL3:
	mov rpower,6;1-1000 Mohm
	
	powresc:
	RET
POWR ENDP


POWC PROC
	GETC
	CMP AL,27
	JE powcesc
	CMP AL,'a'
	JE LBL4
	CMP AL,'A'
	JE LBL4
	CMP AL,'b'
	JE LBL5
	CMP AL,'B'
	JE LBL5
	CMP AL,'c'
	JE LBL6
	CMP AL,'C'
	JE LBL6
	MOV AL,0
	RET
	LBL4:
	mov cpower,-12;1-1000 pF
	ret
	LBL5:
	mov cpower,-9;1-1000 nF
	ret
	LBL6:
	mov cpower,-6;1-1000 uF
	
	powcesc:
	RET
POWC ENDP

AINPUT PROC
	
	res:
	clear_screen
	PRINTMSG msg2
	call POWR;Take range of resistor
	CMP AL,0;Button is not valid
	JE res
	CMP AL,27;Is button ESC
	JE escend
	
	PRINTMSG msg3
	NUMIN rnumber;Take digits of R
	CMP AL,27;Is button ESC
	JE escend
	CMP AL,0;Button is not valid
	je res

	cap:
	clear_screen
	PRINTMSG msg4
	call POWC;Take range of capacitor
	CMP AL,0;Button is not valid
	JE cap
	CMP AL,27;Is button ESC
	JE escend
	PRINTMSG msg5
	NUMIN cnumber;Take digits of C
	CMP AL,0;Button is not valid
	je cap
	
	escend:
	RET
AINPUT ENDP

AVALUES PROC
	clear_screen
	PRINTMSG msg6
	PRINTDIGITS rnumber
	MOV CL,rpower
	CALL PUTUNIT
	NEWL
	
	PRINTMSG msg7
	PRINTDIGITS cnumber
	MOV CL,cpower
	CALL PUTUNIT
	PUTC 'F'
	NEWL
	PRINTMSG msg8
	GETC
ret
AVALUES ENDP

LOADRC PROC
PUSH AX
PUSH SI
PUSH DI
MOV SI,0
MOV DI,0
LOADR:	
	MOV AX,0
	MOV AL,rnumber[SI]
	MOV tmp,AX
	fild tmp
	fmul decvals[DI]
	INC SI
	ADD DI,4
	CMP SI,4
	JB LOADR
fadd
fadd
fadd
;R(without prefix) is in st(0)
MOV SI,0
MOV DI,0
LOADC:	
	MOV AX,0
	MOV AL,cnumber[SI]
	MOV tmp,AX
	fild tmp
	fmul decvals[DI]
	INC SI
	ADD DI,4
	CMP SI,4
	JB LOADC
fadd
fadd
fadd
;C(without prefix) is in st(0)
fmul st(1),st(0)
fstp st(0)
;st(0) is RC
fst resultrc;Backup of RC
POP DI
POP SI
POP AX
RET
LOADRC ENDP

STEADY PROC
PUSH AX
PUSH BX
PUSH CX
PUSH DX
fld ln10
fmul st(1),st(0)
fstp st(0)
fstp result
PRINTMSG msg9

fstcw tmp
MOV AX,tmp
PUSH AX
OR AX,0400H
MOV tmp,AX
fldcw tmp
;Rounding mode is changed to round down
fld1
fld result
fyl2x
fldl2t
fdiv st(1),st(0)
fstp st(0)
frndint
fistp digitchk
;digitchk=floor(log(ln10*RC))
POP AX
MOV tmp,AX
fldcw tmp
;Restore control word

MOV CL,cpower
ADD CL,rpower

CMP digitchk,6
JNE ign1
add cl,6
fld result
fidiv dec1000
fidiv dec1000
fmul decvals[4]
fistp tmp
jmp ign3
ign1:
CMP digitchk,3
JB ign2
add cl,3
fld result
fidiv dec1000
fmul decvals[4]
fistp tmp
jmp ign3
ign2:
fld result
fmul decvals[4]
fistp tmp
;steady state value adjusted to be between 1-1000 and power is stored in CL
ign3:

SETDIGITS
PRINTDIGITS digits

call PUTUNIT
PUTC 's'
NEWL
POP DX
POP CX
POP BX
POP AX
RET
STEADY ENDP

FREQ PROC

fld resultrc
fld pitwo
fmul st(1),st(0)
fstp st(0)
fld1
fdiv st(0),st(1)
fstp result
fstp st(0)
fld result
MOV CL,cpower
ADD CL,rpower
freqadjust:
	CMP CL,0
	JE freqadjustend 
	fimul dec1000
	ADD CL,3
	jmp freqadjust

freqadjustend:

fstp result

fstcw tmp
MOV AX,tmp
PUSH AX
OR AX,0400H
MOV tmp,AX
fldcw tmp
;Rounding mode is changed to round down 
fld1
fld result
fyl2x
fldl2t
fdiv st(1),st(0)
fstp st(0)
frndint
fidiv three
frndint
fimul three
fistp tmp
fld result
MOV CX,tmp
MOV CH,CL
CMP CL,0
JE freqend
CMP CL,0
JG posl 

negl:
ADD CL,3
fimul dec1000
CMP CL,0
jne negl
jmp freqend

posl:

SUB CL,3
fidiv dec1000
CMP CL,0
jne posl

freqend:
MOV CL,CH
fmul decvals[4]

POP AX
MOV tmp,AX
fldcw tmp
fistp tmp
;Control word is restored 
;Frequency and power is adjusted
SETDIGITS
PRINTMSG msg10
PRINTDIGITS digits

call PUTUNIT
PUTC 'H'
PUTC 'z'

RET
FREQ ENDP

PUTUNIT PROC
;Put prefix due to CL
CMP CL,-12
JNE L1
PUTC 'p'
JMP lend

L1:
CMP CL,-9
JNE L2
PUTC 'n'
JMP lend

L2:
CMP CL,-6
JNE L3
PUTC 'u'
JMP lend

L3:
CMP CL,-3
JNE L4
PUTC 'm'
JMP lend

L4:
CMP CL,0
JNE L5
JMP lend

L5:
CMP CL,3
JNE L6
PUTC 'K'
JMP lend

L6:
CMP CL,6
JNE L7
PUTC 'M'
JMP lend

L7:
CMP CL,9
JNE lend
PUTC 'G'
lend:


RET
PUTUNIT ENDP

CIRCUITPRINT PROC

NEWL
NEWL
PRINTMSG circ0
PRINTDIGITS rnumber
MOV CL,rpower
CALL PUTUNIT
PUTC 'o'
PUTC 'h'
PUTC 'm'
NEWL
PRINTMSG circ1
PRINTMSG circ2
PRINTMSG circ3
PRINTMSG circ4
MOV CL,cpower
PRINTDIGITS cnumber
CALL PUTUNIT
PUTC 'F'
NEWL
PRINTMSG circ5
PRINTMSG circ6

RET
CIRCUITPRINT ENDP

POWF PROC

	GETC
	CMP AL,27
	JE powfesc
	CMP AL,'a'
	JE LBL7
	CMP AL,'A'
	JE LBL7
	CMP AL,'b'
	JE LBL8
	CMP AL,'B'
	JE LBL8
	CMP AL,'c'
	JE LBL9
	CMP AL,'C'
	JE LBL9
	MOV AL,0
	RET
	LBL7:
	mov fpower,0;1-1000 Hz
	ret
	LBL8:
	mov fpower,3;1-1000 KHz
	ret
	LBL9:
	mov fpower,6;1-1000 MHz
	
	powfesc:
	
RET
POWF ENDP

FINPUT PROC
	finstart:
	clear_screen
	PRINTMSG msg11
	call POWF;Take range of frequency
	CMP AL,0;Button is not valid
	JE finstart
	CMP AL,27;Is button ESC
	JE finend
	PRINTMSG msg12
	NUMIN fnumber
	CMP AL,27;Is button ESC
	JE finend
	CMP AL,0;Button is not valid
	je finstart
	MOV SI,0
	MOV DI,0
LOADF:	
	MOV AX,0
	MOV AL,fnumber[SI]
	MOV tmp,AX
	fild tmp
	fmul decvals[DI]
	INC SI
	ADD DI,4
	CMP SI,4
	JB LOADF
fadd
fadd
fadd

CMP fpower,0
JE RCCALC
fimul dec1000
CMP fpower,3
JE RCCALC
fimul dec1000
RCCALC:	
fld pitwo
fmul st(1),st(0)
fstp st(0)
fld1
fdiv st(0), st(1)
fstp result
fstp st(0)	
;Real RC value is in result	
	
	finend:

RET
FINPUT ENDP

FINDRC PROC
;Bruteforce method to find best find R and C value
MOV SI,0
MOV DI,0
MOV tmpSI,SI
MOV tmpDI,DI
fld result
fld array0[0]
fld array7[0]
fmul st(1),st(0)
fstp st(0)

fsub st(0),st(1)
fabs

mov cl,8
OUTER:
MOV DI,0
INNER:
	fld array0[SI]
	fld array7[DI]
	fmul st(1),st(0)
	fstp st(0)
	fsub st(0),st(2)
	fabs
	
	fcom
	fstsw flag
	AND flag,0100H
	SHR flag,cl
	CMP flag,1 
	JNE lab
	MOV tmpSI,SI
	MOV tmpDI,DI
	fst st(1)
	lab:
	fstp st(0)
	ADD DI,4
	CMP DI,304
	JNE INNER
ADD SI,4
CMP SI,672
JNE OUTER

fstp st(0)
fstp st(0)
;tmpSI is offset of best fit R
;tmpDI is offset of best fit C
RET

FINDRC ENDP

DESIGNPRINT PROC
clear_screen
PRINTMSG msg10
PRINTDIGITS fnumber
MOV CL,fpower
call PUTUNIT
PUTC 'H'
PUTC 'z'
CALL REALFREQ
PRINTMSG circ0
MOV AX,tmpSI
SHR AX,1
SHR AX,1
MOV BL,6
MUL BL
MOV SI,AX
PUTC rdigit0[SI]
PUTC rdigit0[SI+1]
PUTC rdigit0[SI+2]
PUTC rdigit0[SI+3]
PUTC rdigit0[SI+4]
PUTC rdigit0[SI+5] 
PUTC 'o'
PUTC 'h'
PUTC 'm'
NEWL
PRINTMSG circ1
PRINTMSG circ2
PRINTMSG circ3
PRINTMSG circ4

MOV AX,tmpDI
SHR AX,1
SHR AX,1
MOV BL,6
MUL BL
MOV SI,AX
PUTC cdigit0[SI]
PUTC cdigit0[SI+1]
PUTC cdigit0[SI+2]
PUTC cdigit0[SI+3]
PUTC cdigit0[SI+4]
PUTC cdigit0[SI+5]
PUTC 'F'
NEWL
PRINTMSG circ5
PRINTMSG circ6
RET
DESIGNPRINT ENDP

REALFREQ PROC
MOV SI,tmpSI
fld array0[SI]
MOV SI,tmpDI
fld array7[SI]
fld pitwo
fmul
fmul
fld1
fdivr st(1),st(0)
fstp st(0)
fstp result
lea bx,result

fstcw tmp
MOV AX,tmp
PUSH AX
OR AX,0400H
MOV tmp,AX
fldcw tmp

fld1
fld result
fyl2x
fldl2t
fdiv st(1),st(0)
fstp st(0)
frndint
fidiv three
frndint
fimul three
fistp tmp
fld result
MOV CX,tmp
MOV CH,CL
CMP CL,0
JE realfreqend
CMP CL,0
JG realposl 

realnegl:
ADD CL,3
fimul dec1000
CMP CL,0
jne realnegl
jmp realfreqend

realposl:

SUB CL,3
fidiv dec1000
CMP CL,0
jne realposl

realfreqend:
MOV CL,CH
fmul decvals[4]

POP AX
MOV tmp,AX
fldcw tmp

fistp tmp

SETDIGITS
PRINTMSG msg13
PRINTDIGITS digits

call PUTUNIT
PUTC 'H'
PUTC 'z'
NEWL

RET
REALFREQ ENDP


END

