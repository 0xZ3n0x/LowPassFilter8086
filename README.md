# RC Low-Pass Filter Calculator

An RC low-pass filter design calculator written in **16-bit x86 assembly**
(MASM 6.11, x87 FPU instructions) for DOS, running in 640×480 VGA graphics
mode (mode 12h).

This project exists in two versions side by side:

- **`orig/`** — the original program, written for a university microprocessor lab course.
- **`src/`** — the same program refactored years later, with AI assistance,
  into a small documented module set — while keeping the program's behavior

`requirements.md` is the original assignment specification.

---

## Table of contents

1. [What the program does](#what-the-program-does)
2. [Build and run](#build-and-run)
3. [The original code](#the-original-code)
4. [The refactor — methods used](#the-refactor--methods-used)

---

## Repository layout

```
.
├── README.md            this file
├── requirements.md      original assignment specification
├── orig/                university-era original (frozen)
│   ├── LOWPASSF.asm     the whole program, one file, 912 lines
│   └── REPORT.md        the course report (functional description)
└── src/                 the refactored program
    ├── LOWPASSF.ASM     assembly "spine": model, includes, main flow
    ├── MACROS.INC       I/O and screen macros
    ├── DATA.INC         Qty STRUCT, message strings, circuit art
    ├── RES.INC          standard resistor tables (E24, 168 values)
    ├── CAP.INC          standard capacitor tables (E12, 76 values)
    ├── UTIL.ASM         digit input/output helpers (NUMIN, SETDIGITS, …)
    ├── INPUT.ASM        keyboard input flows (POW_SELECT, AINPUT, FINPUT)
    ├── DISPLAY.ASM      screen output (units, values, circuit drawing)
    ├── MATH.ASM         FPU arithmetic, normalization, design search
    └── BUILD.BAT        build script (MASM 6.11, output to src\BUILD\)
```

---

## What the program does

A passive RC low-pass filter (series R, shunt C) design tool with two modes,
selected from the main menu:

| Key       | Action                                       |
|-----------|----------------------------------------------|
| `a` / `A` | **Analysis** mode                            |
| `b` / `B` | **Design** mode                              |
| other     | ignored — the menu is redrawn                |
| `ESC`     | terminate and return to DOS (works anywhere) |

**Analysis** — given R and C, compute and print:

- cut-off frequency: `fc = 1 / (2·π·R·C)`
- transient time (0% → 90% of steady state): `t₉₀ = ln(10)·R·C ≈ 2.3026·R·C`

and draw the RC circuit with the component values labelled.

**Design** — given a target cut-off frequency, brute-force search all
168 × 76 = 12,768 standard R–C pairs (E24 resistor and E12 capacitor series,
see `requirements.md` §3) for the pair whose RC product is closest to the
required `1/(2·π·fc)`, then print the chosen pair and the *real* cut-off
frequency it produces, with the circuit drawing.

**Input format** — every value is entered as a four-digit engineering
mantissa `ddd.d` (zero-padded on the left, e.g. `012.0`), preceded by a
range key that picks the SI decade:

| Component  | `a`     | `b`      | `c`      |
|------------|---------|----------|----------|
| Resistor   | 1–1000 Ω | 1–1000 kΩ | 1–1000 MΩ |
| Capacitor  | 1–1000 pF | 1–1000 nF | 1–1000 µF |
| Frequency  | 1–1000 Hz | 1–1000 kHz | 1–1000 MHz |

Results are printed in the same `ddd.d` + SI prefix (p, n, u, m, -, K, M, G)
engineering notation. The program never blocks in an infinite loop and ESC
exits cleanly from any prompt.

A fuller functional description is in [`orig/REPORT.md`](orig/REPORT.md).

---

## Build and run

The program uses **x87 FPU instructions**, so it does not run under EMU8086.
It needs MASM 6.11 and DOSBox (or a real DOS box).

**Original** (`orig/`): copy `LOWPASSF.asm` into your MASM directory
(e.g. `C:\MASM611\BIN` inside DOSBox), then:

```
ML.EXE /Fl LOWPASSF.ASM
LOWPASSF.EXE
```

**Refactored** (`src/`): with `ML.EXE` on the path, run the build script
from the `src` directory:

```
BUILD
```

which assembles `..\LOWPASSF.ASM` inside a `BUILD\` subdirectory (the
`/I..\` switch locates the `.INC` files) and reports pass/fail via the
MASM error level. Then run `BUILD\LOWPASSF.EXE` under DOSBox.

---

## The original code

`orig/LOWPASSF.asm` is a classic single-file course program:

- **Everything in one file** — macros, data tables, all procedures, and the
  main flow interleaved, 912 lines.
- **Logic in macros** — `NUMIN` (read a 4-digit mantissa), `PRINTDIGITS`,
  `SETDIGITS` are text-substitution macros. `NUMIN` contains the four
  digit-reads *unrolled*, so every call site pastes ~45 lines of near
  identical GETC/validate/store blocks into the binary.
- **Copy-paste procedures** — `POWR`, `POWC`, `POWF` are three copies of
  the same a/b/c range-key dispatch, differing only in which global
  (`rpower`/`cpower`/`fpower`) they write. Similarly, `FREQ` and `REALFREQ`
  duplicate the whole "floor(log10) → snap to multiple of 3 → scale →
  print" pipeline.
- **Global mutable state everywhere** — 14 mutable globals
  (`rnumber`, `cnumber`, `fnumber`, `rpower`, `cpower`, `fpower`, `result`,
  `resultrc`, `digits`, `digitchk`, `tmp`, `flag`, `tmpSI`, `tmpDI`) form
  the implicit interface between procedures; nothing takes arguments.
- **Hand-transcribed hex data** — the E24/E12 component tables are arrays
  of raw IEEE-754 hex bit patterns (`3f800000H`, `2d2febffH`, …), and
  constants like `ln10` and `2π` are hex dwords.
- **In-band flag signaling** — input routines signal "ESC" and "invalid
  key" by returning `AL = 27` or `AL = 0`, which callers compare with
  `CMP AL,...` right after unrelated operations.

It works, and it earned its grade — but every cross-procedure contract is
implicit, and any change risks breaking a distant caller.

---

## The refactor — methods used

The refactor was done with AI assistance, in small verifiable steps (the
git history mirrors this: *original files → split into multiple files →
overall refactor*). One rule was fixed up front and drove every decision:

> **Behavior preservation.** The refactored program must produce the same
> screen output as the original, byte for byte. Improvements go into
> structure, naming, and documentation — never into what the user sees.

### 1. Modularization by responsibility

The single file was split into modules, included by a thin `LOWPASSF.ASM`
spine (MASM 6.11 has no multi-module linking workflow this simple, so a
single translation unit with `INCLUDE`s was chosen deliberately):

| Module         | Responsibility                                        |
|----------------|-------------------------------------------------------|
| `MACROS.INC`   | trivial I/O wrappers only (PUTC, GETC, PRINTMSG, …)   |
| `DATA.INC`     | read-only data: `Qty` STRUCT, messages, circuit art   |
| `RES.INC`      | resistor tables + their display strings               |
| `CAP.INC`      | capacitor tables + their display strings              |
| `UTIL.ASM`     | digit-level helpers (NUMIN, PRINTDIGITS, SETDIGITS)   |
| `INPUT.ASM`    | keyboard flows (POW_SELECT, AINPUT, FINPUT)           |
| `DISPLAY.ASM`  | formatting and drawing (PUTUNIT, CIRCUITPRINT, …)     |
| `MATH.ASM`     | FPU arithmetic, normalization, design search          |
| `LOWPASSF.ASM` | memory model, includes, main menu and flow            |

### 2. A documented calling convention

The biggest structural change: **every procedure now takes stack
arguments and returns values in registers**, under one cdecl-style
convention written down once in each module header:

- arguments pushed right-to-left; caller cleans up (`ADD SP, n`);
- arg 1 at `[BP+4]`, arg 2 at `[BP+6]`, …; every proc builds a standard
  `PUSH BP / MOV BP, SP` frame;
- return: `AX` = primary, `DX` = secondary;
- sentinel returns: `AX = -1` → ESC, `AX = -2` → invalid key;
- callee preserves `SI`, `DI`, `BP`; may clobber `AX`, `BX`, `CX`, `DX`;
- the only value allowed to cross a `CALL` on the FPU stack is
  `FLOOR_LOG3` (documented at both ends).

Contracts that were previously folklore are now explicit and uniform.

### 3. Macros → procedures

`NUMIN`, `PRINTDIGITS` and `SETDIGITS` moved from macros to `PROC`s in
`UTIL.ASM` with pointer arguments (`NUMIN(buf)` writes through `[BP+4]`).
This removes the unrolled 4× digit reads from every call site and makes
the code emitted *once*. Macros remain only for the trivial
one-interrupt wrappers where a call would cost more than the macro body.

### 4. Deduplication

- `POWR` / `POWC` / `POWF` (3 copies of range-key dispatch) → one
  **`POW_SELECT(base)`** that returns `base + 0/3/6` for a/b/c. The
  caller picks the component by passing the base (R: 0, C: −12, F: 0).
- The mantissa-loading loops (`LOADR`, `LOADC`, `LOADF` — digit-by-digit
  `FILD` + multiply by 100/10/1/0.1, then three `FADD`s) → one helper
  pattern: pack the 4 digits into a word with integer `MUL 10 / ADD`,
  then a single `FILD` + `FIDIV 10`.
- The duplicated "normalize to engineering notation and print" pipeline
  in `FREQ`/`REALFREQ` → three reusable helpers in `MATH.ASM`:
  **`FLOOR_LOG3`** (floor(log10) snapped to a multiple of 3, manages its
  own FPU control-word save/restore), **`NORMALIZE`** (scale a REAL4 into
  `[1,1000)` and produce the print integer), **`PRINT_RESULT`**
  (`ddd.d` + SI prefix + unit chars + newline).
- FPU constants replaced by computed ones: `2π` is `FLDPI; FLDPI; FADD`,
  and `ln(10)` is `FLDL2T × FLDLN2` — no more hex dword constants to
  transcribe wrongly.

### 5. Global mutable state → stack frames and arguments

All 14 mutable globals are gone:

- the `(mantissa, power)` pairs became a **`Qty` STRUCT** (`DATA.INC`);
  instances are stack-allocated in `main`'s frame (`SUB SP, 16` /
  `SUB SP, 14` with the frame layout documented in comments) and passed
  **by pointer** to `AINPUT`, `AVALUES`, `LOADRC`, …;
- intermediate results (`result`, `resultrc`) became caller-provided
  output pointers or locals;
- `tmpSI`/`tmpDI` (best-pair indices) became `FINDRC`'s **return values**
  (`AX` = R table offset, `DX` = C table offset).

`DATA.INC` now contains *only read-only* data — the constraint "no
mutable globals" is stated in its header and holds.

### 6. Data restructuring with documented invariants

- Anonymous `array0..array9`, `rdigit0..6`, `cdigit0..6` became semantically
  named, contiguous blocks bounded by `res_start`/`res_end`,
  `cap_start`/`cap_end`, with sizes as named constants
  (`R_TABLE_SIZE = 672`, `C_TABLE_SIZE = 304`) used by `FINDRC`'s loop
  bounds instead of magic immediates (`CMP DI,304`).
- **Resistor table**: rewritten from raw hex to decimal `REAL4` literals
  (`1.0, 1.1, 1.2, …`), verified entry-by-entry to assemble to the same
  IEEE-754 bytes the original used.
- **Capacitor table**: deliberately *kept as raw hex*. 21 of the 76 values
  differ by one ULP from what MASM produces for the clean decimal literal
  (the original tables were generated by repeated floating-point
  multiplication). Decimal literals would silently change the bytes and
  break equivalence — `CAP.INC` documents exactly why the hex stays.
- Layout invariants ("do not insert anything between these arrays", the
  6-byte display-string stride) are written as comments next to the data,
  where a future editor will actually see them.

### 7. Explicit error returns instead of in-band flags

Input routines return the sentinel codes `0 / −1 / −2` (ok / ESC /
invalid) in `AX`, and every caller checks them immediately. The original's
`AL = 27` / `AL = 0` conventions — which could collide with data values —
are gone, and re-prompt loops (`res_retry`, `cap_retry`, `fin_retry`)
handle invalid input uniformly.

### 8. Small optimizations (structure-neutral)

- `FINDRC` hoists `FLD res_start[SI]` out of the inner loop and duplicates
  it with `FLD st(0)` per iteration, instead of reloading R 76 times.
- The FPU comparison path uses `FSTSW [mem]` + `SAHF` + `JAE` — 8087-safe
  (no `FSTSW AX`) and shorter than the original's memory-flag `AND/SHR`
  dance.

### 9. Build and documentation hygiene

- `BUILD.BAT` with an explicit output directory and `errorlevel` check;
  `BUILD/` git-ignored.
- Explicit `.8086`/`.8087` directives, `.STACK 1024`, a single `FINIT`
  at startup.
- Every module opens with a header comment stating its responsibility,
  the calling convention, and anything surprising (e.g. `circ2`'s quirky
  `13,13` line ending preserved verbatim, and `STEADY`'s slightly
  different decade scheme kept as-is, both with comments saying *why*:
  byte-for-byte output compatibility).

---