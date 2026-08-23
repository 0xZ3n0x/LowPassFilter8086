# Requirements — Low Pass Filter Design Calculator

## 1. Project Overview

A low-pass filter passes signals with frequency components lower than the filter's
cut-off frequency. This project is a design tool that calculates the properties of a
simple passive **RC low-pass filter** (resistor in series, capacitor in shunt — see
Figure 1 of the assignment).

## 2. Functional Requirements

### 2.1 Main Menu

The program shall present a menu allowing the user to select one of two calculation
modes:

- **a) Analysis** — Cut-off frequency and transient time from given R, C values.
- **b) Design (Synthesis)** — R and C selection from standard values for a given
  cut-off frequency, plus the real frequency resulting from those values.

### 2.2 Analysis Mode

- **Input:** Any resistor value R (ohms) and capacitor value C (farads) entered by
  the user.
- **Output:**
  - Cut-off frequency:
    `fc = 1 / (2 * pi * R * C)`
  - Transient (rise) time for the steady-state value, 0% to 90%:
    `t ≈ 2.2 * R * C`

### 2.3 Design (Synthesis) Mode

- **Input:** A target cut-off frequency entered by the user.
- **Processing:** Search the standard component tables (Section 3) to find the R and
  C combination whose resulting cut-off frequency is closest to the target.
- **Output:**
  - Selected standard R and C values.
  - The **real** cut-off frequency calculated from the selected R and C values.

### 2.4 Program Control

- The program shall terminate at any time when the **ESC** key is pressed and shall
  return to the operating system successfully.
- The application shall not get stuck in any infinite loops.
- Required values shall be entered by the user according to the menu option selected.

## 3. Standard Component Values (Reference Data)

### 3.1 Standard Resistor Values (±5%, E24 series)

| #  | Ω    | ×10     | ×100     | kΩ      | ×10 kΩ   | ×100 kΩ   | MΩ      |
|----|------|---------|----------|---------|----------|-----------|---------|
| 1  | 1.0  | 10      | 100      | 1.0K    | 10K      | 100K      | 1.0M    |
| 2  | 1.1  | 11      | 110      | 1.1K    | 11K      | 110K      | 1.1M    |
| 3  | 1.2  | 12      | 120      | 1.2K    | 12K      | 120K      | 1.2M    |
| 4  | 1.3  | 13      | 130      | 1.3K    | 13K      | 130K      | 1.3M    |
| 5  | 1.5  | 15      | 150      | 1.5K    | 15K      | 150K      | 1.5M    |
| 6  | 1.6  | 16      | 160      | 1.6K    | 16K      | 160K      | 1.6M    |
| 7  | 1.8  | 18      | 180      | 1.8K    | 18K      | 180K      | 1.8M    |
| 8  | 2.0  | 20      | 200      | 2.0K    | 20K      | 200K      | 2.0M    |
| 9  | 2.2  | 22      | 220      | 2.2K    | 22K      | 220K      | 2.2M    |
| 10 | 2.4  | 24      | 240      | 2.4K    | 24K      | 240K      | 2.4M    |
| 11 | 2.7  | 27      | 270      | 2.7K    | 27K      | 270K      | 2.7M    |
| 12 | 3.0  | 30      | 300      | 3.0K    | 30K      | 300K      | 3.0M    |
| 13 | 3.3  | 33      | 330      | 3.3K    | 33K      | 330K      | 3.3M    |
| 14 | 3.6  | 36      | 360      | 3.6K    | 36K      | 360K      | 3.6M    |
| 15 | 3.9  | 39      | 390      | 3.9K    | 39K      | 390K      | 3.9M    |
| 16 | 4.3  | 43      | 430      | 4.3K    | 43K      | 430K      | 4.3M    |
| 17 | 4.7  | 47      | 470      | 4.7K    | 47K      | 470K      | 4.7M    |
| 18 | 5.1  | 51      | 510      | 5.1K    | 51K      | 510K      | 5.1M    |
| 19 | 5.6  | 56      | 560      | 5.6K    | 56K      | 560K      | 5.6M    |
| 20 | 6.2  | 62      | 620      | 6.2K    | 62K      | 620K      | 6.2M    |
| 21 | 6.8  | 68      | 680      | 6.8K    | 68K      | 680K      | 6.8M    |
| 22 | 7.5  | 75      | 750      | 7.5K    | 75K      | 750K      | 7.5M    |
| 23 | 8.2  | 82      | 820      | 8.2K    | 82K      | 820K      | 8.2M    |
| 24 | 9.1  | 91      | 910      | 9.1K    | 91K      | 910K      | 9.1M    |

Range: 1 Ω to 9.1 MΩ (24 values per decade × 7 decades = 168 values).

### 3.2 Standard Capacitor Values (±10%, E12 series)

| #  | pF   | ×10 pF | nF (×1000 pF) | ×0.01 µF | ×0.1 µF | µF   | ×10 µF |
|----|------|--------|---------------|----------|---------|------|--------|
| 1  | 10   | 100    | 1000          | .010     | .10     | 1.0  | 10     |
| 2  | 12   | 120    | 1200          | .012     | .12     | 1.2  | —      |
| 3  | 15   | 150    | 1500          | .015     | .15     | 1.5  | —      |
| 4  | 18   | 180    | 1800          | .018     | .18     | 1.8  | —      |
| 5  | 22   | 220    | 2200          | .022     | .22     | 2.2  | 22     |
| 6  | 27   | 270    | 2700          | .027     | .27     | 2.7  | —      |
| 7  | 33   | 330    | 3300          | .033     | .33     | 3.3  | 33     |
| 8  | 39   | 390    | 3900          | .039     | .39     | 3.9  | —      |
| 9  | 47   | 470    | 4700          | .047     | .47     | 4.7  | 47     |
| 10 | 56   | 560    | 5600          | .056     | .56     | 5.6  | —      |
| 11 | 68   | 680    | 6800          | .068     | .68     | 6.8  | —      |
| 12 | 82   | 820    | 8200          | .082     | .82     | 8.2  | —      |

Range: 10 pF to 47 µF (the last decade only contains 10, 22, 33, and 47 µF — marked "—" otherwise).

## 4. Graphics & Output Requirements

- Results shall be drawn in **graphics mode 640×480** on the screen.
- A simple graphic of the RC low-pass filter circuit (like Figure 1) shall be drawn.
- Results shall be printed on the screen in a clear and understandable way.

## 5. Inputs & Outputs Summary

| Mode      | From (Input)      | To (Output)                                            |
|-----------|-------------------|--------------------------------------------------------|
| Analysis  | Any R-C values    | Cut-off frequency, transient time (0% to 90%)          |
| Synthesis | Cut-off frequency | Standard R-C values, real frequency calculated from R-C |

## 6. Non-Functional Requirements

- **Reliability:** No infinite loops; the program must always respond to user input
  and to the ESC key.
- **Clean termination:** Successful return to the operating system on exit.
- **Code quality:** Clear general template and intelligible, readable code.
