# Quartus II 10.0 CLI Command Reference (DE2-115)

> **Quartus II 10.0 Build 218 06/27/2010 SJ Web Edition**
> Cyclone IV EP4CE115F29C7 — Terasic DE2-115

## 1. Environment Setup

Add the Quartus bin directory to PATH before running any commands:

```batch
set QUARTUS_ROOTDIR=C:\altera\10.0\quartus
set QUARTUS_BIN=%QUARTUS_ROOTDIR%\bin
set PATH=%QUARTUS_BIN%;%PATH%
```

Or use the provided `setenv.bat`.

---

## 2. Build Flow Commands

### 2.1 `quartus_map` — Analysis & Synthesis

Converts HDL (Verilog/VHDL) into a gate-level netlist mapped to the device logic elements.

```
quartus_map <project_name> [-c <revision>]
```

| Option | Description |
|--------|-------------|
| `-c <rev>` | Compile a specific revision |
| `-f <file>` | Read options from argument file |
| `-p` | Preserve synthesis netlist |
| `--64bit` | Use 64-bit mode (if available) |

**Example:**
```batch
quartus_map blink_led
```

### 2.2 `quartus_fit` — Fitter (Place & Route)

Places the synthesized netlist into the device's logic cells and routes the connections.

```
quartus_fit <project_name> [-c <revision>]
```

| Option | Description |
|--------|-------------|
| `--check_netlist` | Check netlist legality only (no fitting) |
| `-c <rev>` | Specific revision |
| `--64bit` | 64-bit mode |

**Example:**
```batch
quartus_fit blink_led
```

### 2.3 `quartus_asm` — Assembler

Generates the `.sof` (SRAM Object File) bitstream from the fitted design.

```
quartus_asm <project_name> [-c <revision>]
```

| Option | Description |
|--------|-------------|
| `-c <rev>` | Specific revision |
| `--64bit` | 64-bit mode |

**Example:**
```batch
quartus_asm blink_led
```

Output: `output_files/<project>.sof` (if `PROJECT_OUTPUT_DIRECTORY` is set in `.qsf`).

### 2.4 `quartus_sta` — TimeQuest Timing Analyzer

Performs static timing analysis against the design's clock constraints.

```
quartus_sta <project_name> [-c <revision>]
quartus_sta -t <script.tcl>           # Run a Tcl script
quartus_sta -s                         # Interactive Tcl shell
quartus_sta --tcl_eval <tcl_command>   # Run one Tcl command
```

**Example:**
```batch
quartus_sta blink_led
```

Add a `.sdc` file for clock constraints:
```tcl
create_clock -period 20.0 [get_ports clk]
```
Reference it in `.qsf`:
```tcl
set_global_assignment -name SDC_FILE blink_led.sdc
```

### 2.5 `quartus_pgm` — Programmer

Programs the configuration bitstream (.sof) into the FPGA via JTAG.

```
quartus_pgm -l                                    # List available cables
quartus_pgm -c <cable> -a                         # List devices on cable
quartus_pgm -c <cable> -m <mode> -o <op>          # Program FPGA
```

| Option | Description |
|--------|-------------|
| `-l` | List JTAG cables (Quartus 10.0 uses **single dash**) |
| `-c <name>` | Cable name (e.g. `"USB-Blaster [USB-0]"`) |
| `-m <mode>` | Programming mode: `jtag`, `as`, `ps`, `ppa` |
| `-o <op>` | Operation: `p;<file>.sof`, `b;<file>.sof`, `e` |

**Common operations:**
```batch
:: List cables
quartus_pgm -l

:: Program .sof via JTAG
quartus_pgm -c "USB-Blaster [USB-0]" -m jtag -o "p;output_files\blink_led.sof"

:: Program configuration device (EPCS) via JTAG in AS mode
quartus_pgm -c "USB-Blaster [USB-0]" -m as -o "p;output_files\blink_led.pof"

:: Erase device
quartus_pgm -c "USB-Blaster [USB-0]" -m jtag -o "e"

:: Blank-check
quartus_pgm -c "USB-Blaster [USB-0]" -m jtag -o "b"
```

> **⚠️ Syntax note (Quartus 10.0):** Use `-l` (single dash), NOT `--l` (double dash).  
> `--l` produces: `Error: Unknown long option --l`

### 2.6 `quartus_sh` — Shell (Flow Automation)

Runs compilation flows or Tcl scripts with a single command.

```
quartus_sh --flow <flow_name> <project> [-c <revision>]
quartus_sh -t <script.tcl> [<args>]
quartus_sh --tcl_eval <tcl_command>
quartus_sh -s                            # Interactive Tcl shell
```

**Available flows:**
| Flow | Description |
|------|-------------|
| `compile` | Full compilation (map + fit + asm + sta) |
| `compile_and_simulate` | Full compilation + simulation |
| `functional_simulation_netlist_generation` | Generate VQM for functional sim |
| `early_timing_estimate` | Quick timing check (after fitting) |
| `early_timing_estimate_with_synthesis` | Synthesis + quick timing |

**Examples:**
```batch
:: Single-command full compile
quartus_sh --flow compile blink_led

:: Run a Tcl build script
quartus_sh -t build.tcl

:: Execute a Tcl command inline
quartus_sh --tcl_eval "project_open blink_led; project_close"
```

### 2.7 `quartus_cpf` — Convert Programming Files

Converts `.sof` to other programming formats (.pof, .jic, .hex, .rpd).

```
quartus_cpf -c [options] <input> <output>
```

| Option | Description |
|--------|-------------|
| `-c` | Convert (required) |
| `-d <device>` | Target configuration device (e.g. `EPCS64`) |
| `-g <voltage>` | I/O voltage (e.g. `3.3-V`) |
| `-a <addr>` | Start address (hex) |

**Examples:**
```batch
:: SOF → POF for EPCS64 configuration device
quartus_cpf -c -d EPCS64 blink_led.sof blink_led.pof

:: SOF → JIC (JTAG Indirect Configuration)
quartus_cpf -c -d EPCS64 blink_led.sof blink_led.jic

:: SOF → RPD (Raw Programming Data)
quartus_cpf -c -d EPCS64 blink_led.sof blink_led.rpd

:: SOF → HEX (for external flash)
quartus_cpf -c blink_led.sof blink_led.hex
```

### 2.8 `quartus_drc` — Design Rule Check

Checks the design for violations of Altera's design rules.

```
quartus_drc <project_name> [-c <revision>]
```

### 2.9 `quartus_eda` — EDA Netlist Writer

Writes netlist files for third-party EDA tools (ModelSim, Synopsys, etc.).

```
quartus_eda <project_name> [-c <revision>]
```

### 2.10 `quartus_sim` — Simulator

Gate-level simulation using the Quartus II built-in simulator.

```
quartus_sim <project_name> [-c <revision>]
quartus_sim -s                               # Interactive mode
quartus_sim --tcl_eval <tcl_command>
quartus_sim -t <script.tcl>
```

### 2.11 `quartus_pow` — Power Analyzer

Estimates dynamic and static power consumption (requires VCD/SAIF from simulation or gate-level toggle rates).

```
quartus_pow <project_name> [-c <revision>]
```

### 2.12 `quartus_cdb` — Compiler Database

Manages the compiler database for incremental compilation.

```
quartus_cdb <project_name> [-c <revision>]
quartus_cdb --export <partition> <output.qdb>
quartus_cdb --import <input.qdb> <partition>
quartus_cdb --merge
```

---

## 3. Multi-Step vs. Single-Step Compile

### Step-by-step (recommended for debugging)

```batch
quartus_map  blink_led
quartus_fit  blink_led
quartus_asm  blink_led
quartus_sta  blink_led
quartus_pgm -l
quartus_pgm -c "USB-Blaster [USB-0]" -m jtag -o "p;output_files\blink_led.sof"
```

Each step gives you visibility into where errors occur.

### Single-command compile

```batch
quartus_sh --flow compile blink_led
quartus_pgm -c "USB-Blaster [USB-0]" -m jtag -o "p;output_files\blink_led.sof"
```

Faster but less granular error reporting.

---

## 4. JTAG Utilities

### 4.1 `jtagconfig` — JTAG Hardware Configuration

Enumerates and manages JTAG hardware.

```
jtagconfig                    # List cables and devices
jtagconfig --enum             # Same as default
jtagconfig --version          # Version info
jtagconfig --serverinfo       # Query JTAG server
```

**Example output on DE2-115:**
```
1) USB-Blaster [USB-0]
   EP4CE115 (0x020F70DD)
```

> ⚠️ Requires `jtagd.exe` to be present. In some Quartus 10.0 copies `jtagd.exe` may be missing — in that case `jtagconfig` returns `No JTAG hardware available`, even though `quartus_pgm` works fine.

### 4.2 `jtagserver` — Remote JTAG Server

For remote debugging/programming across a network.

```
jtagserver
jtagserver --add <server> <password>
jtagserver --enableremote <password>
jtagserver --disableremote
```

---

## 5. File Format Conversions

| Input | Output | Command |
|-------|--------|---------|
| `.v` / `.vhd` | Synthesized netlist | `quartus_map` |
| Synthesized netlist | Fitted netlist | `quartus_fit` |
| Fitted netlist | `.sof` (SRAM) | `quartus_asm` |
| `.sof` | `.pof` (EPCS/CFI Flash) | `quartus_cpf -c -d EPCS64` |
| `.sof` | `.jic` (JTAG Indirect) | `quartus_cpf -c -d EPCS64` |
| `.sof` | `.rbf` (Raw Binary) | `quartus_cpf -c` |
| `.sof` | `.hex` (Hex) | `quartus_cpf -c` |
| `.sof` | `.ekp` (Encrypted Key) | `quartus_cpf -e -k <key>` |

---

## 6. Nios II Embedded Commands

> **Nios II EDS bin:** `C:\altera\10.0\nios2eds\bin`

### 6.1 `nios2-terminal` — JTAG UART Terminal

Connects to a Nios II processor's JTAG UART for stdio I/O.

```
nios2-terminal [--instance=<n>] [--cable=<cable>] [--device=<n>]
```

| Option | Description |
|--------|-------------|
| `--instance=<n>` | JTAG UART instance (default: 0) |
| `--cable=<cable>` | Cable name |
| `--device=<n>` | Device index in JTAG chain |

**Example:**
```batch
nios2-terminal
nios2-terminal --cable="USB-Blaster [USB-0]" --instance=0
```

**To exit:** `Ctrl+C`

### 6.2 `nios2-flash-programmer` — Flash Programming

Programs the EPCS configuration device with Nios II software + FPGA config.

```
nios2-flash-programmer --fpga=<sof> --epcs --base=<base_address> --go
```

### 6.3 Nios II GNU Toolchain (complete)

The Nios II EDS includes a full GNU cross-compilation toolchain:
```
nios2-elf-gcc.exe     nios2-elf-as.exe      nios2-elf-ld.exe
nios2-elf-gdb.exe     nios2-elf-objcopy.exe nios2-elf-objdump.exe
nios2-elf-ar.exe      nios2-elf-size.exe    nios2-elf-strip.exe
```

---

## 7. Other Utilities

| Command | Description |
|---------|-------------|
| `quartus_g2b` | Generate SignalTap II trigger signal |
| `quartus_jli` | JTAG LUT Initialization |
| `quartus_jbcc` | JTAG Bitstream Compression Check |
| `pll_cmd` | PLL calibration utility |
| `mif2hex` | Convert `.mif` to `.hex` format |
| `tclsh85` | Tcl 8.5 shell (standalone) |
| `qmegawiz` | MegaWizard Plug-In Manager (GUI) |

---

## 8. DE2-115 Typical Build Script Template

```batch
@echo off
set PROJECT=blink_led
set CABLE=USB-Blaster [USB-0]
set QUARTUS_BIN=C:\altera\10.0\quartus\bin
set PATH=%QUARTUS_BIN%;%PATH%

echo [1/5] Synthesis...
quartus_map  %PROJECT% || exit /b 1

echo [2/5] Place & Route...
quartus_fit  %PROJECT% || exit /b 1

echo [3/5] Assembler...
quartus_asm  %PROJECT% || exit /b 1

echo [4/5] Timing Analysis...
quartus_sta  %PROJECT% || exit /b 1

echo [5/5] Program...
quartus_pgm -c "%CABLE%" -m jtag -o "p;output_files\%PROJECT%.sof" || exit /b 1

echo DONE — DE2-115 configured.
```

---

## 9. Common Error Messages & Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| `Illegal location assignment PIN_J2` | Pin is a dedicated configuration pin | Use correct pin from official DE2-115 CSV |
| `Can't place node "ledr[1]" -- illegal location` | Wrong pin for this I/O bank | Cross-check with SKILL.md pin tables |
| `Error: Unknown long option --l` | `--l` used instead of `-l` | Use `quartus_pgm -l` |
| `No JTAG hardware available` | `jtagd.exe` missing or driver issue | `quartus_pgm` still works directly |
| `Error: Can't fit design in device` | Too many resources or illegal pin assignments | Check pin legality, reduce logic |
| `Warning: Feature LogicLock is only available with a valid subscription license` | Web Edition limitation — safe to ignore | Not needed for basic designs |
| `Warning: Timing requirements not met` | No `.sdc` clock constraint | Add `create_clock -period 20 [get_ports clk]` |
