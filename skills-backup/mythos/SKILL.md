# DE2-115 Skill Pack — Terasic Cyclone IV E FPGA Board

> **Skill ID:** `de2-115-skill-agent`
> **Version:** 1.0.0
> **Board:** Terasic DE2-115 (Altera Cyclone IV EP4CE115F29C7)
> **Reference:** `DE2_115_User_manual.pdf` (included in this repo)

---

## 1. Board Specifications

| Parameter           | Value                        |
|---------------------|------------------------------|
| FPGA                | Cyclone IV EP4CE115F29C7     |
| Logic Elements      | 114,480                      |
| Memory              | 3,981 M9K blocks (432 KB)    |
| Embedded Multipliers| 266 9-bit                    |
| PLLs                | 4                            |
| Global Clock Nets   | 20                           |
| User I/O Banks      | 8                            |
| User I/O Pins       | 520                          |
| Core Voltage        | 1.2 V                        |
| I/O Standard        | 2.5 V / 3.3 V (per bank)    |
| Clock Source        | 50 MHz oscillator (PIN_Y2)   |

### On-Board Peripherals

| Peripheral         | Quantity | Notes                              |
|--------------------|----------|-------------------------------------|
| Red LEDs (LEDR)    | 18       | Active-high, output                 |
| Green LEDs (LEDG)  | 9        | Active-high, output                 |
| Slide Switches (SW)| 18       | Active-high, input                  |
| Push Buttons (KEY) | 4        | Active-low (pulled high), input     |
| 7-Seg Displays     | 8        | HEX0–HEX7, active-low segments      |
| LCD Module         | 1        | 16×2 character, Hitachi HD44780     |
| SDRAM              | 2×64 MB  | 32M×16 each, 128 MB total           |
| SRAM               | 2 MB     | 1M×16 ISSI IS61WV10248BLL          |
| FLASH              | 8 MB     | 8-bit, CFI compliant                |
| EPCS64 Config      | 1        | 64 Mb serial config device          |
| VGA DAC            | 1        | ADV7123 10-bit triple DAC           |
| Audio CODEC        | 1        | Wolfson WM8731 with Mic/Line In/Out |
| Ethernet PHY       | 2        | Marvell 88E1111 (10/100/1000)       |
| USB Blaster        | 1        | On-chip (EPM240 MAX II)             |
| USB Host/Slave     | 1+1      | Cypress CY7C67200                    |
| RS-232             | 1        | ZT3232LEEY transceiver              |
| IR Receiver        | 1        | 38 kHz demodulator                   |
| PS/2               | 2        | Mouse + Keyboard                     |
| SD Card Socket     | 1        | SPI mode                            |
| TV Decoder         | 1        | ADV7180 (NTSC/PAL)                  |
| HSMC Connector     | 1        | High-speed mezzanine                |
| GPIO Header        | 1        | 36 pins (JP5)                       |
| SMA Clock I/O      | 1+1      | External clock in/out               |

---

## 2. Complete Pin Assignments

Pin assignments from the official Terasic `DE2_115_pin_assignments.csv` (Quartus II 9.1 SP2).

### 2.1 Clock and Reset

| Signal     | FPGA Pin | I/O Std     | Description               |
|------------|----------|-------------|---------------------------|
| CLOCK_50   | PIN_Y2   | 3.3-V LVTTL | Main 50 MHz oscillator    |
| CLOCK2_50  | PIN_AG14 | 3.3-V LVTTL | Secondary 50 MHz          |
| CLOCK3_50  | PIN_AG15 | 3.3-V LVTTL | Tertiary 50 MHz           |
| SMA_CLKIN  | PIN_AH14 | 3.3-V LVTTL | External clock input      |
| SMA_CLKOUT | PIN_AE23 | 3.3-V LVTTL | External clock output     |
| KEY[0]     | PIN_M23  | 2.5 V       | Push-button (active-low)  |
| KEY[1]     | PIN_M21  | 2.5 V       | Push-button (active-low)  |
| KEY[2]     | PIN_N21  | 2.5 V       | Push-button (active-low)  |
| KEY[3]     | PIN_R24  | 2.5 V       | Push-button (active-low)  |
| SW[0]      | PIN_AB28 | 2.5 V       | Slide switch              |
| SW[1]      | PIN_AC28 | 2.5 V       | Slide switch              |
| SW[2]      | PIN_AC27 | 2.5 V       | Slide switch              |
| SW[3]      | PIN_AD27 | 2.5 V       | Slide switch              |
| SW[4]      | PIN_AB27 | 2.5 V       | Slide switch              |
| SW[5]      | PIN_AC26 | 2.5 V       | Slide switch              |
| SW[6]      | PIN_AD26 | 2.5 V       | Slide switch              |
| SW[7]      | PIN_AB26 | 2.5 V       | Slide switch              |
| SW[8]      | PIN_AC25 | 2.5 V       | Slide switch              |
| SW[9]      | PIN_AB25 | 2.5 V       | Slide switch              |
| SW[10]     | PIN_AC24 | 2.5 V       | Slide switch              |
| SW[11]     | PIN_AB24 | 2.5 V       | Slide switch              |
| SW[12]     | PIN_AB23 | 2.5 V       | Slide switch              |
| SW[13]     | PIN_AA24 | 2.5 V       | Slide switch              |
| SW[14]     | PIN_AA23 | 2.5 V       | Slide switch              |
| SW[15]     | PIN_AA22 | 2.5 V       | Slide switch              |
| SW[16]     | PIN_Y24  | 2.5 V       | Slide switch              |
| SW[17]     | PIN_Y23  | 2.5 V       | Slide switch              |

### 2.2 Red LEDs — LEDR[17:0]

| Signal     | FPGA Pin | I/O Std | Description      |
|------------|----------|---------|------------------|
| LEDR[0]    | PIN_G19  | 2.5 V   | Red LED 0 (right)|
| LEDR[1]    | PIN_F19  | 2.5 V   | Red LED 1        |
| LEDR[2]    | PIN_E19  | 2.5 V   | Red LED 2        |
| LEDR[3]    | PIN_F21  | 2.5 V   | Red LED 3        |
| LEDR[4]    | PIN_F18  | 2.5 V   | Red LED 4        |
| LEDR[5]    | PIN_E18  | 2.5 V   | Red LED 5        |
| LEDR[6]    | PIN_J19  | 2.5 V   | Red LED 6        |
| LEDR[7]    | PIN_H19  | 2.5 V   | Red LED 7        |
| LEDR[8]    | PIN_J17  | 2.5 V   | Red LED 8        |
| LEDR[9]    | PIN_G17  | 2.5 V   | Red LED 9        |
| LEDR[10]   | PIN_J15  | 2.5 V   | Red LED 10       |
| LEDR[11]   | PIN_H16  | 2.5 V   | Red LED 11       |
| LEDR[12]   | PIN_J16  | 2.5 V   | Red LED 12       |
| LEDR[13]   | PIN_H17  | 2.5 V   | Red LED 13       |
| LEDR[14]   | PIN_F15  | 2.5 V   | Red LED 14       |
| LEDR[15]   | PIN_G15  | 2.5 V   | Red LED 15       |
| LEDR[16]   | PIN_G16  | 2.5 V   | Red LED 16       |
| LEDR[17]   | PIN_H15  | 2.5 V   | Red LED 17 (left)|

### 2.3 Green LEDs — LEDG[8:0]

| Signal    | FPGA Pin | I/O Std | Description      |
|-----------|----------|---------|------------------|
| LEDG[0]   | PIN_E21  | 2.5 V   | Green LED 0 (right) |
| LEDG[1]   | PIN_E22  | 2.5 V   | Green LED 1      |
| LEDG[2]   | PIN_E25  | 2.5 V   | Green LED 2      |
| LEDG[3]   | PIN_E24  | 2.5 V   | Green LED 3      |
| LEDG[4]   | PIN_H21  | 2.5 V   | Green LED 4      |
| LEDG[5]   | PIN_G20  | 2.5 V   | Green LED 5      |
| LEDG[6]   | PIN_G22  | 2.5 V   | Green LED 6      |
| LEDG[7]   | PIN_G21  | 2.5 V   | Green LED 7      |
| LEDG[8]   | PIN_F17  | 2.5 V   | Green LED 8 (left) |

### 2.4 Seven-Segment Displays — HEX0–HEX7

| Signal     | FPGA Pin | Bank | Signal     | FPGA Pin | Bank |
|------------|----------|------|------------|----------|------|
| HEX0[0]    | PIN_G18  | 7    | HEX4[0]    | PIN_AB19 | 4    |
| HEX0[1]    | PIN_F22  | 7    | HEX4[1]    | PIN_AA19 | 4    |
| HEX0[2]    | PIN_E17  | 7    | HEX4[2]    | PIN_AG21 | 4    |
| HEX0[3]    | PIN_L26  | 6    | HEX4[3]    | PIN_AH21 | 4    |
| HEX0[4]    | PIN_L25  | 6    | HEX4[4]    | PIN_AE19 | 4    |
| HEX0[5]    | PIN_J22  | 6    | HEX4[5]    | PIN_AF19 | 4    |
| HEX0[6]    | PIN_H22  | 6    | HEX4[6]    | PIN_AE18 | 4    |
| HEX1[0]    | PIN_M24  | 6    | HEX5[0]    | PIN_AD18 | 4    |
| HEX1[1]    | PIN_Y22  | 5    | HEX5[1]    | PIN_AC18 | 4    |
| HEX1[2]    | PIN_W21  | 5    | HEX5[2]    | PIN_AB18 | 4    |
| HEX1[3]    | PIN_W22  | 5    | HEX5[3]    | PIN_AH19 | 4    |
| HEX1[4]    | PIN_W25  | 5    | HEX5[4]    | PIN_AG19 | 4    |
| HEX1[5]    | PIN_U23  | 5    | HEX5[5]    | PIN_AF18 | 4    |
| HEX1[6]    | PIN_U24  | 5    | HEX5[6]    | PIN_AH18 | 4    |
| HEX2[0]    | PIN_AA25 | 5    | HEX6[0]    | PIN_AA17 | 4    |
| HEX2[1]    | PIN_AA26 | 5    | HEX6[1]    | PIN_AB16 | 4    |
| HEX2[2]    | PIN_Y25  | 5    | HEX6[2]    | PIN_AA16 | 4    |
| HEX2[3]    | PIN_W26  | 5    | HEX6[3]    | PIN_AB17 | 4    |
| HEX2[4]    | PIN_Y26  | 5    | HEX6[4]    | PIN_AB15 | 4    |
| HEX2[5]    | PIN_W27  | 5    | HEX6[5]    | PIN_AA15 | 4    |
| HEX2[6]    | PIN_W28  | 5    | HEX6[6]    | PIN_AC17 | 4    |
| HEX3[0]    | PIN_V21  | 5    | HEX7[0]    | PIN_AD17 | 4    |
| HEX3[1]    | PIN_U21  | 5    | HEX7[1]    | PIN_AE17 | 4    |
| HEX3[2]    | PIN_AB20 | 4    | HEX7[2]    | PIN_AG17 | 4    |
| HEX3[3]    | PIN_AA21 | 4    | HEX7[3]    | PIN_AH17 | 4    |
| HEX3[4]    | PIN_AD24 | 4    | HEX7[4]    | PIN_AF17 | 4    |
| HEX3[5]    | PIN_AF23 | 4    | HEX7[5]    | PIN_AG18 | 4    |
| HEX3[6]    | PIN_Y19  | 4    | HEX7[6]    | PIN_AA14 | 3    |

**7-segment encoding (common-anode, active-low):**

```
  a
f   b
  g
e   c
  d   dp

Segment:   --abcdefg (7-bit, active low)
Number 0:  7'b1000000
Number 1:  7'b1111001
Number 2:  7'b0100100
Number 3:  7'b0110000
Number 4:  7'b0011001
Number 5:  7'b0010010
Number 6:  7'b0000010
Number 7:  7'b1111000
Number 8:  7'b0000000
Number 9:  7'b0010000
```

All HEX segments are **active-low** — set the bit to 0 to light the segment.

### 2.5 Other Key Peripherals

**VGA (ADV7123 DAC)**
| Signal      | FPGA Pin | Signal     | FPGA Pin |
|-------------|----------|------------|----------|
| VGA_R[0]    | PIN_E12  | VGA_G[0]   | PIN_G8   |
| VGA_R[1]    | PIN_E11  | VGA_G[1]   | PIN_G11  |
| VGA_R[2]    | PIN_D10  | VGA_G[2]   | PIN_F8   |
| VGA_R[3]    | PIN_F12  | VGA_G[3]   | PIN_H12  |
| VGA_R[4]    | PIN_G10  | VGA_G[4]   | PIN_C8   |
| VGA_R[5]    | PIN_J12  | VGA_G[5]   | PIN_B8   |
| VGA_R[6]    | PIN_H8   | VGA_G[6]   | PIN_F10  |
| VGA_R[7]    | PIN_H10  | VGA_G[7]   | PIN_C9   |
| VGA_B[0]    | PIN_B10  | VGA_HS     | PIN_G13  |
| VGA_B[1]    | PIN_A10  | VGA_VS     | PIN_C13  |
| VGA_B[2]    | PIN_C11  | VGA_CLK    | PIN_A12  |
| VGA_B[3]    | PIN_B11  | VGA_BLANK_N| PIN_F11  |
| VGA_B[4]    | PIN_A11  | VGA_SYNC_N | PIN_C10  |
| VGA_B[5]    | PIN_C12  |            |          |
| VGA_B[6]    | PIN_D11  |            |          |
| VGA_B[7]    | PIN_D12  |            |          |

**Audio (Wolfson WM8731)**
| Signal         | FPGA Pin |
|----------------|----------|
| AUD_ADCDAT     | PIN_D2   |
| AUD_ADCLRCK    | PIN_C2   |
| AUD_BCLK       | PIN_F2   |
| AUD_DACDAT     | PIN_D1   |
| AUD_DACLRCK    | PIN_E3   |
| AUD_XCK        | PIN_E1   |

**SDRAM (Bank 0)**
| Signal          | FPGA Pin |
|-----------------|----------|
| DRAM_ADDR[12:0] | Multiple |
| DRAM_DQ[15:0]   | Multiple |
| DRAM_BA[1:0]    | PIN_R4, PIN_U7 |
| DRAM_CLK        | PIN_AE5  |
| DRAM_CKE        | PIN_AA6  |
| DRAM_CS_N       | PIN_T4   |
| DRAM_RAS_N      | PIN_U6   |
| DRAM_CAS_N      | PIN_V7   |
| DRAM_WE_N       | PIN_V6   |

**Ethernet 0 (Marvell 88E1111)**
| Signal            | FPGA Pin |
|-------------------|----------|
| ENET0_TX_DATA[3:0]| B19,A19,D19,C18 |
| ENET0_RX_DATA[3:0]| C15,D17,D16,C16 |
| ENET0_MDC        | PIN_C20  |
| ENET0_MDIO       | PIN_B21  |
| ENET0_GTX_CLK    | PIN_A17  |
| ENET0_RX_CLK     | PIN_A15  |
| ENET0_TX_CLK     | PIN_B17  |
| ENET0_RST_N      | PIN_C19  |
| ENET0_INT_N      | PIN_A21  |

**GPIO Header (JP5)**
| Signal      | FPGA Pin | Signal     | FPGA Pin |
|-------------|----------|------------|----------|
| GPIO[0]     | PIN_AB22 | GPIO[18]   | PIN_AE22 |
| GPIO[1]     | PIN_AC15 | GPIO[19]   | PIN_AF21 |
| GPIO[2]     | PIN_AB21 | GPIO[20]   | PIN_AF22 |
| GPIO[3]     | PIN_Y17  | GPIO[21]   | PIN_AD22 |
| GPIO[4]     | PIN_AC21 | GPIO[22]   | PIN_AG25 |
| GPIO[5]     | PIN_Y16  | GPIO[23]   | PIN_AD25 |
| GPIO[6]     | PIN_AD21 | GPIO[24]   | PIN_AH25 |
| GPIO[7]     | PIN_AE16 | GPIO[25]   | PIN_AE25 |
| GPIO[8]     | PIN_AD15 | GPIO[26]   | PIN_AG22 |
| GPIO[9]     | PIN_AE15 | GPIO[27]   | PIN_AE24 |
| GPIO[10]    | PIN_AC19 | GPIO[28]   | PIN_AH22 |
| GPIO[11]    | PIN_AF16 | GPIO[29]   | PIN_AF26 |
| GPIO[12]    | PIN_AD19 | GPIO[30]   | PIN_AE20 |
| GPIO[13]    | PIN_AF15 | GPIO[31]   | PIN_AG23 |
| GPIO[14]    | PIN_AF24 | GPIO[32]   | PIN_AF20 |
| GPIO[15]    | PIN_AE21 | GPIO[33]   | PIN_AH26 |
| GPIO[16]    | PIN_AF25 | GPIO[34]   | PIN_AH23 |
| GPIO[17]    | PIN_AC22 | GPIO[35]   | PIN_AG26 |

---

> **Full CLI command reference:** [`QUARTUS_CLI.md`](./QUARTUS_CLI.md) — covers all 20+ Quartus II 10.0 commands, JTAG utilities, Nios II tools, file format conversions, error troubleshooting, and script templates.
>
> **npm package:** `de2-115-skill-agent` — install via `npm install` for CLI tool (`de2-115` command), MCP server, and automatic AI skill registration.
>
> **MCP server:** `mcp-server/de2-115-mcp.mjs` — lets AI agents build, program, and query the DE2-115 via JSON-RPC 2.0 over stdio.

## 3. DE2-115 CLI Workflow

### 3.1 Conceptual Stack

```
Top-level module (e.g. dancing_led.v)
       │
       ▼
Project file (.qsf) — FAMILY, DEVICE, TOP_LEVEL_ENTITY, pin assignments
       │
       ▼
quartus_map          → Synthesis (analyse + elaborate + map to logic)
quartus_fit          → Place & Route (fit design into device)
quartus_asm          → Assemble (.sof bitstream generation)
quartus_sta          → Static Timing Analysis
quartus_pgm          → Program FPGA via JTAG/USB-Blaster
```

### 3.2 Build and Program Script

The reference script `build_and_program.bat` automates the full flow:

```batch
@echo off
setlocal enabledelayedexpansion

set PROJECT=blink_led
set CABLE=USB-Blaster [USB-0]
set QUARTUS_ROOTDIR=C:\altera\10.0\quartus
set QUARTUS_BIN=%QUARTUS_ROOTDIR%\bin
set PATH=%QUARTUS_BIN%;%PATH%

:: ── Build steps ──
echo [1/5] Synthesis (quartus_map)...
call quartus_map %PROJECT% || goto :fail

echo [2/5] Place and route (quartus_fit)...
call quartus_fit %PROJECT% || goto :fail

echo [3/5] Assemble .sof (quartus_asm)...
call quartus_asm %PROJECT% || goto :fail

echo [4/5] Timing analysis (quartus_sta)...
call quartus_sta %PROJECT% || goto :fail

if not exist "output_files\%PROJECT%.sof" (
    echo ERROR: output_files\%PROJECT%.sof was not produced.
    exit /b 1
)

echo [5/5] Programming via %CABLE%...
call quartus_pgm -c "%CABLE%" -m jtag -o "p;output_files\%PROJECT%.sof" || goto :fail

echo.
echo ============================================================
echo  DONE. DE2-115 configured with %PROJECT%.
echo ============================================================
goto :end

:fail
echo.
echo BUILD/PROGRAM FAILED at the step shown above.
exit /b 1

:end
endlocal
```

### 3.3 Critical Notes

- **quartus_pgm option syntax**: Quartus II 10.0 uses **`-l`** (single dash), NOT `--l` (double dash).
- **Pin assignments must come from the official Terasic CSV** — many pins are illegal for user I/O (e.g., J2, J8, J9, J11, J18 are dedicated configuration pins).
- **Timing warnings** from `quartus_sta` are benign for simple designs without clock constraints. Add a `.sdc` file for precise constraint:
  ```tcl
  # <project>.sdc
  create_clock -period 20.0 [get_ports clk]
  ```
- **USB-Blaster driver**: On Windows 11 64-bit, the signed driver from Quartus Prime (2.12.28) works with `quartus_pgm` even though `jtagd.exe` may be missing from Quartus 10.0. The modern driver is compatible because `quartus_pgm` opens the cable directly.
- **Missing jtagd.exe**: Only breaks `jtagconfig`/jtag server — does NOT affect `quartus_pgm`.
- **Output directory**: If `PROJECT_OUTPUT_DIRECTORY` is set in `.qsf`, all outputs (`.sof`, `.rpt`, etc.) go there, not the root.

### 3.4 Project File Template (.qsf)

```tcl
# DE2-115 Quartus Settings File
set_global_assignment -name FAMILY "Cyclone IV E"
set_global_assignment -name DEVICE EP4CE115F29C7
set_global_assignment -name TOP_LEVEL_ENTITY <top_module>
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
set_global_assignment -name SOURCE_FILE <top_module>.v

# Clock
set_location_assignment -to clk PIN_Y2

# Switches / Buttons
set_location_assignment -to sw[0] PIN_AB28
# ... (add all used SW/KEY pins per the tables above)

# LEDs
set_location_assignment -to ledr[0] PIN_G19
# ... (add all LED pins per the tables above)
```

### 3.5 Timing reference for common operations

| Operation           | Counter width | Period @ 50 MHz |
|---------------------|---------------|------------------|
| 1 ms tick           | 16-bit        | 50,000 cycles    |
| 10 ms tick          | 19-bit        | 500,000 cycles   |
| 30 ms tick          | 25-bit        | 1,500,000 cycles |
| 100 ms tick         | 22-bit?       | 5,000,000 cycles |
| 1 s tick            | 26-bit        | 50,000,000 cycles|

> 50 MHz = 50,000,000 cycles/second. Period (in cycles) = time_s × 50e6.
> Use 25-bit counter (`[24:0]`) for up to 335 ms, 26-bit (`[25:0]`) for up to 671 ms.

---

## 4. How to Use This Skill

When asked to help with a DE2-115 project:

1. **Pin assignments**: Always cross-reference against the pin tables in Section 2. Never guess pin numbers — the EP4CE115F29C7 has many dedicated configuration pins that will cause "Illegal location assignment" errors.
2. **Project structure**: Create a `.v` top module, a `.qsf` project file, and optionally a `.sdc` timing constraint. Use the `build_and_program.bat` pattern for CLI automation.
3. **USB-Blaster**: The cable name is almost always `"USB-Blaster [USB-0]"`. Verify with `quartus_pgm -l` before programming.
4. **Active-low vs active-high**: LEDs and 7-segment displays on DE2-115 are active-high for LEDR/LEDG, and active-low for HEX segments.

### 4.1 Agent Prompt Pattern

```
You are a DE2-115 FPGA designer with access to the official pin reference.
Load skill: de2-115-skill-agent
Follow the CLI workflow in Section 3 to build and program the design.
```

---

## 5. Reproducing the Board's Pin CSV

The official Terasic `DE2_115_pin_assignments.csv` is archived at:
https://github.com/Parafounder01/De2-115-skill-agent/blob/main/DE2_115_User_manual.pdf

For reference, the CSV was generated by Terasic's DE2-115 System Builder tool (version 1.0.1) and validates against Quartus II 9.1 SP2 and later.
