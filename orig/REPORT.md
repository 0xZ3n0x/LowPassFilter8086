# Low Pass Filter Calculator

A low-pass filter design tool written in x86 assembly (MASM, using FPU
instructions) that runs in 640×480 graphics mode. The program performs both
**analysis** (compute the cut-off frequency and transient time of an RC filter
from given R and C) and **design** (select the best standard R–C pair for a
target cut-off frequency).

---

## Operation Selection (Main Menu)

At the main menu the program waits for a key press:

| Key        | Action                          |
|------------|---------------------------------|
| `a` / `A`  | Enter **Analysis** mode         |
| `b` / `B`  | Enter **Design** mode           |
| Any other  | Ignored (the menu is redrawn)   |
| `ESC`      | Terminate and return to the OS   |

`ESC` exits the program immediately at *any* point — from the menu or from
inside either operation. The program never blocks in an infinite loop.

---

## a) Analysis

Given a resistor **R** and a capacitor **C**, the program computes:

- **Cut-off frequency:**  `fc = 1 / (2·π·R·C)`
- **Transient time (0% → 90% of steady state):**  `t₉₀ = ln(10)·R·C ≈ 2.3026·R·C`

### Input

- The user enters **R**, then **C**.
- Each value is entered as a four-digit number in `xxx.x` format.
- Small numbers are zero-padded on the left (e.g. `012.0`).
- Internally the value is stored like scientific notation: a mantissa of the
  form `xxx.x` with an exponent that is always a multiple of 3 (engineering
  notation).

### Output

After both values are entered, the program prints R and C back to the screen,
then displays the computed **transient time** and **cut-off frequency**, and
draws the RC low-pass filter circuit together with its components.

---

## b) Design

From a target cut-off frequency the program must find the most accurate
standard **R** and **C** combination. The required RC product is fixed by the
target frequency, so the real challenge is choosing the best pair from the
standard value tables.

### Method

A **brute-force search** is used. Every standard resistor and capacitor value
is held in memory; the program tests every possible R×C pair, computes the
resulting cut-off frequency for each, and keeps the pair with the smallest
error relative to the target.

### Input

- The target cut-off frequency is entered in the same `xxx.x` scientific-
  notation style as in Analysis (four digits, zero-padded on the left,
  exponent a multiple of 3).

### Output

The program prints the **most accurate R–C pair** and the **real cut-off
frequency** produced by that pair.

---

## Program Logic

### Analysis

R and C are read as engineering scientific notation: mantissa `xxx.x`,
exponent a multiple of 3. After `fc` and `t₉₀` are calculated the result's
exponent is re-normalized to the nearest multiple of 3 so that the printed
mantissa stays in the `xxx.x` form. The final values are then shown as a
mantissa together with the appropriate SI prefix (µ, m, k, M, …).

### Design

The target frequency is read in the same scientific-notation style and the
required RC product is derived from it. Because every standard R and C value
resides in memory, the program can enumerate all pairs, compute each pair's
error, and select the one with the smallest error as the best match.

---

## How to Assemble and Run

The program uses **FPU instructions** and therefore does **not** run under
EMU8086. Two assembly source files are provided — one with comment lines and
one without — along with the compiled `LOWPASSF.EXE`.

The assembly source has been placed in the `C:\MASM611\BIN` directory inside
DOSBox.

**Assemble and link:**

```
ML.EXE /Fl LOWPASSF.ASM
```

**Run:**

```
LOWPASSF.EXE
```
