
<img valign='middle' alt='Altera Blue' src='https://readme-swatches.vercel.app/0078C0?style=square&size=30'/>
<img valign='middle' alt='Cyclone' src='https://readme-swatches.vercel.app/00A651?style=square&size=30'/>
<img valign='middle' alt='FPGA' src='https://readme-swatches.vercel.app/ED1C24?style=square&size=30'/>
<img valign='middle' alt='DE2-115' src='https://readme-swatches.vercel.app/000000?style=square&size=30'/>

# <img valign='middle' alt='' src='https://readme-swatches.vercel.app/0078C0?style=square&size=24'/> DE2-115 Skill Agent — Terasic Cyclone IV FPGA

> **AI skill pack + CLI toolset for the Terasic DE2-115 board**  
> FPGA: Cyclone IV <img valign='middle' alt='#00A651' src='https://readme-swatches.vercel.app/00A651?style=round&size=16'/> EP4CE115F29C7  
> Logic Elements: 114,480 &nbsp;|&nbsp; 50 MHz clock <img valign='middle' alt='#FFD700' src='https://readme-swatches.vercel.app/FFD700?style=circle&size=14'/> PIN_Y2

---

## <img valign='middle' alt='swatch' src='https://readme-swatches.vercel.app/0078C0?style=square&size=18'/> What's Inside

| File | What it does |
|------|-------------|
| <img valign='middle' alt='red' src='https://readme-swatches.vercel.app/ED1C24?style=square&size=14'/> `SKILL.md` | Full AI agent skill — pin tables, workflows, agent prompt |
| <img valign='middle' alt='blue' src='https://readme-swatches.vercel.app/0078C0?style=square&size=14'/> `QUARTUS_CLI.md` | Quartus II 10.0 CLI reference — 20+ commands, error guide |
| <img valign='middle' alt='green' src='https://readme-swatches.vercel.app/00A651?style=square&size=14'/> `DE2_115_User_manual.pdf` | Official Terasic manual (14 MB) |
| <img valign='middle' alt='yellow' src='https://readme-swatches.vercel.app/FFD700?style=square&size=14'/> `dancing_led.v` | Example: bouncing LED across all 18 red LEDs |
| <img valign='middle' alt='purple' src='https://readme-swatches.vercel.app/7B2CBF?style=square&size=14'/> `blink_led.qsf` | Reference project file with verified pin assignments |
| <img valign='middle' alt='orange' src='https://readme-swatches.vercel.app/FF8C00?style=square&size=14'/> `build_and_program.bat` | One-click build + program script |
| <img valign='middle' alt='cyan' src='https://readme-swatches.vercel.app/00B4D8?style=square&size=14'/> `setenv.bat` | PATH helper for Quartus CLI |

**npm package** <img valign='middle' alt='npm' src='https://readme-swatches.vercel.app/CB3837?style=square&size=16'/>

| Module | What it does |
|--------|-------------|
| <img valign='middle' alt='npm' src='https://readme-swatches.vercel.app/CB3837?style=square&size=14'/> `package.json` | npm package — install via `npm install .` |
| <img valign='middle' alt='pink' src='https://readme-swatches.vercel.app/FF69B4?style=square&size=14'/> `bin/de2-115.mjs` | CLI tool `de2-115` — build, program, scaffold, check |
| <img valign='middle' alt='purple' src='https://readme-swatches.vercel.app/9D4EDD?style=square&size=14'/> `mcp-server/de2-115-mcp.mjs` | MCP server — AI agents control FPGA via JSON-RPC |
| <img valign='middle' alt='grey' src='https://readme-swatches.vercel.app/888888?style=square&size=14'/> `agent-config/` | Skill configs for Mythos Router, opencode, Claude Desktop |
| <img valign='middle' alt='blue' src='https://readme-swatches.vercel.app/0078C0?style=square&size=14'/> `scripts/install-skill.mjs` | Postinstall: auto-copies skill to all AI platforms |

---

## <img valign='middle' alt='swatch' src='https://readme-swatches.vercel.app/CB3837?style=square&size=18'/> Install via npm

```bash
git clone git@github.com:Parafounder01/De2-115-skill-agent.git
cd De2-115-skill-agent

# Local install (adds CLI + MCP server + AI skill files)
npm install

# Or globally for the de2-115 CLI command
npm install -g .
```

### What `npm install` does

1. Installs the `@modelcontextprotocol/sdk` dependency
2. Runs `postinstall` → `scripts/install-skill.mjs` which:
   - Copies `SKILL.md` + pin reference to `~/.mythos-router/skills/de2-115/`
   - Copies to `~/.config/opencode/skills/de2-115/`
   - Merges MCP server config into `claude_desktop_config.json`

### Use the CLI

```bash
# Check environment and cable
de2-115 check

# Full build
de2-115 build blink_led

# Program the FPGA
de2-115 program blink_led

# Scaffold a new project
de2-115 project my_design
```

---

## <img valign='middle' alt='swatch' src='https://readme-swatches.vercel.app/FF8C00?style=square&size=18'/> Step-by-Step: Your First DE2-115 Project

### <img valign='middle' alt='step1' src='https://readme-swatches.vercel.app/ED1C24?style=circle&size=16'/> Step 1 — Set up the environment

Open a **Command Prompt** (not PowerShell) and run:

```batch
C:\> cd De2-115-skill-agent
C:\De2-115-skill-agent> setenv.bat
```

This adds `C:\altera\10.0\quartus\bin` to your PATH so you can call `quartus_*` commands from anywhere.

> <img valign='middle' alt='warning' src='https://readme-swatches.vercel.app/FFD700?style=square&size=14'/> **Important:** Your Quartus installation must be at `C:\altera\10.0\quartus`. If it's elsewhere, edit `setenv.bat` first.

---

### <img valign='middle' alt='step2' src='https://readme-swatches.vercel.app/ED1C24?style=circle&size=16'/> Step 2 — Understand the hardware

The DE2-115 has:

| Peripheral | Count | Color |
|-----------|:-----:|-------|
| Red LEDs | 18 | <img valign='middle' alt='red' src='https://readme-swatches.vercel.app/ED1C24?style=square&size=14'/> <img valign='middle' alt='red' src='https://readme-swatches.vercel.app/ED1C24?style=square&size=14'/> <img valign='middle' alt='red' src='https://readme-swatches.vercel.app/ED1C24?style=square&size=14'/> LEDR[17:0] — active-high |
| Green LEDs | 9 | <img valign='middle' alt='green' src='https://readme-swatches.vercel.app/00A651?style=square&size=14'/> <img valign='middle' alt='green' src='https://readme-swatches.vercel.app/00A651?style=square&size=14'/> LEDG[8:0] — active-high |
| Slide switches | 18 | <img valign='middle' alt='grey' src='https://readme-swatches.vercel.app/888888?style=square&size=14'/> SW[17:0] — slide up = logic 1 |
| Push buttons | 4 | <img valign='middle' alt='grey' src='https://readme-swatches.vercel.app/555555?style=round&size=14'/> KEY[3:0] — press = logic 0 (active-low!) |
| 7-segment displays | 8 | <img valign='middle' alt='red' src='https://readme-swatches.vercel.app/FF4444?style=square&size=14'/> HEX0–HEX7 — common-anode, active-low segments |
| 50 MHz clock | 1 | <img valign='middle' alt='yellow' src='https://readme-swatches.vercel.app/FFD700?style=circle&size=14'/> CLOCK_50 → PIN_Y2 |

---

### <img valign='middle' alt='step3' src='https://readme-swatches.vercel.app/ED1C24?style=circle&size=16'/> Step 3 — Write your Verilog

Create a top-level module. Here's the `dancing_led` example that bounces a single lit LED across all 18 red LEDs:

```verilog
// dancing_led.v — Bouncing LED across LEDR[17:0]
// clk = 50 MHz (PIN_Y2), rst = SW[0] (PIN_AB28, active-high)
module dancing_led(
    input  wire       clk,
    input  wire       rst,
    output reg [17:0] ledr
);

    reg [24:0] counter;
    localparam HALF_PERIOD = 25'd1_500_000;  // 30 ms step @ 50 MHz

    reg dir;  // 0 = move toward LEDR17, 1 = move toward LEDR0
    localparam TO_HIGH = 1'b0, TO_LOW = 1'b1;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 25'd0;
            ledr    <= 18'h0_0001;  // start at LEDR[0] (rightmost)
            dir     <= TO_HIGH;
        end else begin
            if (counter >= HALF_PERIOD) begin
                counter <= 25'd0;
                if (dir == TO_HIGH) begin
                    if (ledr[17]) begin dir <= TO_LOW;  ledr <= ledr >> 1; end
                    else            ledr <= ledr << 1;
                end else begin
                    if (ledr[0])  begin dir <= TO_HIGH; ledr <= ledr << 1; end
                    else            ledr <= ledr >> 1;
                end
            end else begin
                counter <= counter + 25'd1;
            end
        end
    end

endmodule
```

**What happens:**
- <img valign='middle' alt='red' src='https://readme-swatches.vercel.app/ED1C24?style=square&size=14'/> LEDR[0] lights up first (rightmost)
- Every 30 ms, the lit LED moves one position left
- <img valign='middle' alt='red' src='https://readme-swatches.vercel.app/ED1C24?style=square&size=14'/> When it hits LEDR[17] (leftmost), it reverses direction
- <img valign='middle' alt='red' src='https://readme-swatches.vercel.app/ED1C24?style=square&size=14'/> The LED bounces back and forth forever
- Slide <img valign='middle' alt='switch' src='https://readme-swatches.vercel.app/888888?style=round&size=14'/> **SW[0]** up to reset

---

### <img valign='middle' alt='step4' src='https://readme-swatches.vercel.app/ED1C24?style=circle&size=16'/> Step 4 — Create the Quartus project file

`blink_led.qsf` (the file name defines the project name):

```tcl
# DE2-115 Quartus Settings File
set_global_assignment -name FAMILY "Cyclone IV E"
set_global_assignment -name DEVICE EP4CE115F29C7
set_global_assignment -name TOP_LEVEL_ENTITY dancing_led
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
set_global_assignment -name SOURCE_FILE dancing_led.v

# Clock — 50 MHz
set_location_assignment -to clk PIN_Y2

# Reset — SW[0] (slide up = logic 1 = reset)
set_location_assignment -to rst PIN_AB28
```

---

### <img valign='middle' alt='step5' src='https://readme-swatches.vercel.app/ED1C24?style=circle&size=16'/> Step 5 — Build via CLI

Run each step in order:

```batch
:: [1/5] Synthesis: converts Verilog to gate-level netlist
quartus_map  blink_led
```
<img valign='middle' alt='success' src='https://readme-swatches.vercel.app/00A651?style=circle&size=14'/> `Info: Quartus II Analysis & Synthesis was successful`

```batch
:: [2/5] Fitter: places logic cells and routes connections
quartus_fit  blink_led
```
<img valign='middle' alt='success' src='https://readme-swatches.vercel.app/00A651?style=circle&size=14'/> `Info: Fitter was successful`

```batch
:: [3/5] Assembler: generates the .sof bitstream
quartus_asm  blink_led
```
<img valign='middle' alt='success' src='https://readme-swatches.vercel.app/00A651?style=circle&size=14'/> You now have `output_files/blink_led.sof`

```batch
:: [4/5] Timing analysis: checks clock constraints
quartus_sta  blink_led
```
<img valign='middle' alt='success' src='https://readme-swatches.vercel.app/00A651?style=circle&size=14'/> `Info: TimeQuest Timing Analyzer was successful`

---

### <img valign='middle' alt='step6' src='https://readme-swatches.vercel.app/ED1C24?style=circle&size=16'/> Step 6 — Program the FPGA

First, check that your USB-Blaster is detected:

```batch
quartus_pgm -l
```
<img valign='middle' alt='expected' src='https://readme-swatches.vercel.app/00A651?style=square&size=14'/> Expected output: `1) USB-Blaster [USB-0]`

> <img valign='middle' alt='tip' src='https://readme-swatches.vercel.app/FFD700?style=circle&size=14'/> If you see `No JTAG hardware available` but `quartus_pgm -c "USB-Blaster [USB-0]"` works, your `jtagd.exe` is missing. This is normal for some Quartus 10.0 copies — `quartus_pgm` opens the cable directly and doesn't need the daemon.

Now program:

```batch
quartus_pgm -c "USB-Blaster [USB-0]" -m jtag -o "p;output_files\blink_led.sof"
```

<img valign='middle' alt='success' src='https://readme-swatches.vercel.app/00A651?style=circle&size=14'/> `Info: Configuration succeeded -- 1 device(s) configured`

**Your DE2-115 is now running!** <img valign='middle' alt='red' src='https://readme-swatches.vercel.app/ED1C24?style=square&size=14'/> <img valign='middle' alt='red' src='https://readme-swatches.vercel.app/ED1C24?style=square&size=14'/> <img valign='middle' alt='red' src='https://readme-swatches.vercel.app/ED1C24?style=square&size=14'/>

---

### <img valign='middle' alt='step7' src='https://readme-swatches.vercel.app/ED1C24?style=circle&size=16'/> Step 7 — Use the one-click script

For subsequent builds, just run:

```batch
build_and_program
```

This runs all 5 steps (map → fit → asm → sta → pgm) in sequence and stops on any error.

---

## <img valign='middle' alt='swatch' src='https://readme-swatches.vercel.app/7B2CBF?style=square&size=18'/> Pin Reference (Color-Coded)

### <img valign='middle' alt='red' src='https://readme-swatches.vercel.app/ED1C24?style=square&size=16'/> LEDR[17:0] — 18 Red LEDs

```
LEDR[0]  <img valign='middle' alt='red' src='https://readme-swatches.vercel.app/ED1C24?style=square&size=14'/>  PIN_G19   │  LEDR[9]  <img valign='middle' alt='red' src='https://readme-swatches.vercel.app/ED1C24?style=square&size=14'/>  PIN_G17
LEDR[1]  <img valign='middle' alt='red' src='https://readme-swatches.vercel.app/ED1C24?style=square&size=14'/>  PIN_F19   │  LEDR[10] <img valign='middle' alt='red' src='https://readme-swatches.vercel.app/ED1C24?style=square&size=14'/>  PIN_J15
LEDR[2]  <img valign='middle' alt='red' src='https://readme-swatches.vercel.app/ED1C24?style=square&size=14'/>  PIN_E19   │  LEDR[11] <img valign='middle' alt='red' src='https://readme-swatches.vercel.app/ED1C24?style=square&size=14'/>  PIN_H16
LEDR[3]  <img valign='middle' alt='red' src='https://readme-swatches.vercel.app/ED1C24?style=square&size=14'/>  PIN_F21   │  LEDR[12] <img valign='middle' alt='red' src='https://readme-swatches.vercel.app/ED1C24?style=square&size=14'/>  PIN_J16
LEDR[4]  <img valign='middle' alt='red' src='https://readme-swatches.vercel.app/ED1C24?style=square&size=14'/>  PIN_F18   │  LEDR[13] <img valign='middle' alt='red' src='https://readme-swatches.vercel.app/ED1C24?style=square&size=14'/>  PIN_H17
LEDR[5]  <img valign='middle' alt='red' src='https://readme-swatches.vercel.app/ED1C24?style=square&size=14'/>  PIN_E18   │  LEDR[14] <img valign='middle' alt='red' src='https://readme-swatches.vercel.app/ED1C24?style=square&size=14'/>  PIN_F15
LEDR[6]  <img valign='middle' alt='red' src='https://readme-swatches.vercel.app/ED1C24?style=square&size=14'/>  PIN_J19   │  LEDR[15] <img valign='middle' alt='red' src='https://readme-swatches.vercel.app/ED1C24?style=square&size=14'/>  PIN_G15
LEDR[7]  <img valign='middle' alt='red' src='https://readme-swatches.vercel.app/ED1C24?style=square&size=14'/>  PIN_H19   │  LEDR[16] <img valign='middle' alt='red' src='https://readme-swatches.vercel.app/ED1C24?style=square&size=14'/>  PIN_G16
LEDR[8]  <img valign='middle' alt='red' src='https://readme-swatches.vercel.app/ED1C24?style=square&size=14'/>  PIN_J17   │  LEDR[17] <img valign='middle' alt='red' src='https://readme-swatches.vercel.app/ED1C24?style=square&size=14'/>  PIN_H15
```

### <img valign='middle' alt='green' src='https://readme-swatches.vercel.app/00A651?style=square&size=16'/> LEDG[8:0] — 9 Green LEDs

```
LEDG[0]  <img valign='middle' alt='green' src='https://readme-swatches.vercel.app/00A651?style=square&size=14'/>  PIN_E21   │  LEDG[5]  <img valign='middle' alt='green' src='https://readme-swatches.vercel.app/00A651?style=square&size=14'/>  PIN_G20
LEDG[1]  <img valign='middle' alt='green' src='https://readme-swatches.vercel.app/00A651?style=square&size=14'/>  PIN_E22   │  LEDG[6]  <img valign='middle' alt='green' src='https://readme-swatches.vercel.app/00A651?style=square&size=14'/>  PIN_G22
LEDG[2]  <img valign='middle' alt='green' src='https://readme-swatches.vercel.app/00A651?style=square&size=14'/>  PIN_E25   │  LEDG[7]  <img valign='middle' alt='green' src='https://readme-swatches.vercel.app/00A651?style=square&size=14'/>  PIN_G21
LEDG[3]  <img valign='middle' alt='green' src='https://readme-swatches.vercel.app/00A651?style=square&size=14'/>  PIN_E24   │  LEDG[8]  <img valign='middle' alt='green' src='https://readme-swatches.vercel.app/00A651?style=square&size=14'/>  PIN_F17
LEDG[4]  <img valign='middle' alt='green' src='https://readme-swatches.vercel.app/00A651?style=square&size=14'/>  PIN_H21   │
```

### <img valign='middle' alt='yellow' src='https://readme-swatches.vercel.app/FFD700?style=square&size=16'/> SW[17:0] — 18 Slide Switches

```
SW[0]   PIN_AB28   │  SW[6]   PIN_AD26   │  SW[12]  PIN_AB23
SW[1]   PIN_AC28   │  SW[7]   PIN_AB26   │  SW[13]  PIN_AA24
SW[2]   PIN_AC27   │  SW[8]   PIN_AC25   │  SW[14]  PIN_AA23
SW[3]   PIN_AD27   │  SW[9]   PIN_AB25   │  SW[15]  PIN_AA22
SW[4]   PIN_AB27   │  SW[10]  PIN_AC24   │  SW[16]  PIN_Y24
SW[5]   PIN_AC26   │  SW[11]  PIN_AB24   │  SW[17]  PIN_Y23
```

> <img valign='middle' alt='info' src='https://readme-swatches.vercel.app/0078C0?style=circle&size=14'/> Slide **up** (toward the LEDs) = logic `1` in the FPGA. Slide **down** = logic `0`.

### <img valign='middle' alt='grey' src='https://readme-swatches.vercel.app/888888?style=square&size=16'/> KEY[3:0] — 4 Push Buttons

```
KEY[0]  PIN_M23   │  KEY[2]  PIN_N21
KEY[1]  PIN_M21   │  KEY[3]  PIN_R24
```

> <img valign='middle' alt='warning' src='https://readme-swatches.vercel.app/FFD700?style=circle&size=14'/> **KEYs are active-low!** Pressed = logic `0`, released = logic `1`.  
> They have internal pull-up resistors, so they default to `1` when not pressed.

### <img valign='middle' alt='orange' src='https://readme-swatches.vercel.app/FF8C00?style=square&size=16'/> HEX[7:0] — 8 Seven-Segment Displays

Each display uses 7 segments (a,b,c,d,e,f,g) plus a decimal point (dp):

```
    a
   ───
f │   │ b
   ─ g
e │   │ c
   ───
    d     dp
```

**Segment-to-pin mapping (HEX0 example):**

| Segment | FPGA Pin |
|---------|----------|
| a (HEX0[0]) | PIN_G18 |
| b (HEX0[1]) | PIN_F22 |
| c (HEX0[2]) | PIN_E17 |
| d (HEX0[3]) | PIN_L26 |
| e (HEX0[4]) | PIN_L25 |
| f (HEX0[5]) | PIN_J22 |
| g (HEX0[6]) | PIN_H22 |

**Segment encoding** (7-bit, **active-low** — clear bit = segment on, set bit = segment off):
```
Number 0:  7'b1000000    Number 5:  7'b0010010
Number 1:  7'b1111001    Number 6:  7'b0000010
Number 2:  7'b0100100    Number 7:  7'b1111000
Number 3:  7'b0110000    Number 8:  7'b0000000
Number 4:  7'b0011001    Number 9:  7'b0010000
```

---

## <img valign='middle' alt='swatch' src='https://readme-swatches.vercel.app/00B4D8?style=square&size=18'/> One-Command Build Script Explained

`build_and_program.bat` does this:

```mermaid
flowchart LR
    A[<b>.v file</b><br/>Verilog] --> B[<b>quartus_map</b><br/>Synthesis]
    B --> C[<b>quartus_fit</b><br/>Place & Route]
    C --> D[<b>quartus_asm</b><br/>Assemble .sof]
    D --> E[<b>quartus_sta</b><br/>Timing Analysis]
    E --> F[<b>quartus_pgm</b><br/>Program FPGA]
    F --> G[<img valign='middle' alt='done' src='https://readme-swatches.vercel.app/00A651?style=circle&size=14'/><br/>LEDs dancing!]
```

If any step fails, the script stops immediately (via `|| goto :fail`).

**Key details:**
- <img valign='middle' alt='' src='https://readme-swatches.vercel.app/ED1C24?style=square&size=14'/> The `.sof` is generated in `output_files/` (controlled by `PROJECT_OUTPUT_DIRECTORY` in the `.qsf`)
- <img valign='middle' alt='' src='https://readme-swatches.vercel.app/FFD700?style=square&size=14'/> `quartus_pgm -l` uses a **single dash** in Quartus 10.0 (not `--l`)
- <img valign='middle' alt='' src='https://readme-swatches.vercel.app/0078C0?style=square&size=14'/> Cable name is almost always `"USB-Blaster [USB-0]"`

---

---

## <img valign='middle' alt='swatch' src='https://readme-swatches.vercel.app/9D4EDD?style=square&size=18'/> MCP Server — AI Agents Control the DE2-115

The MCP server (`mcp-server/de2-115-mcp.mjs`) lets AI agents (Claude Desktop, Mythos Router, opencode) interact with your FPGA in real time via the [Model Context Protocol](https://modelcontextprotocol.io).

### Connect from Claude Desktop

Add this to your `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "de2-115": {
      "command": "node",
      "args": ["C:\\path\\to\\De2-115-skill-agent\\mcp-server\\de2-115-mcp.mjs"],
      "env": {}
    }
  }
}
```

Or use the auto-merge config from `npm install` (see above).

### Tools the AI gets

| Tool | What the AI can ask |
|------|-------------------|
| `build_project` | "Compile the blink_led project" |
| `program_fpga` | "Program the DE2-115 with my design" |
| `list_cables` | "Is the USB-Blaster connected?" |
| `scaffold_project` | "Create a new project called my_audio_dsp" |
| `read_pin_status` | "What pins does blink_led use?" |

### Resources the AI can read

| URI | Content |
|-----|---------|
| `de2-115://board/specs` | Full board specifications |
| `de2-115://pinout/ledr` | LEDR[17:0] pin table |
| `de2-115://pinout/ledg` | LEDG[8:0] pin table |
| `de2-115://pinout/sw` | SW[17:0] pin table |
| `de2-115://project/{name}/sof` | `.sof` file status |

### Start manually

```bash
node mcp-server/de2-115-mcp.mjs
```

The server listens on stdin/stdout for JSON-RPC 2.0 messages conforming to the MCP spec.

---

## <img valign='middle' alt='swatch' src='https://readme-swatches.vercel.app/FFD700?style=square&size=18'/> Full Installation & Workflow Diagram

```mermaid
flowchart TB
    %% ── STYLES ──
    classDef install fill:#0078C0,color:#fff,stroke:#005A8C,stroke-width:2px
    classDef write fill:#7B2CBF,color:#fff,stroke:#5A189A,stroke-width:2px
    classDef build fill:#FF8C00,color:#fff,stroke:#CC7000,stroke-width:2px
    classDef prog fill:#ED1C24,color:#fff,stroke:#B8151C,stroke-width:2px
    classDef test fill:#00A651,color:#fff,stroke:#007A3D,stroke-width:2px
    classDef tool fill:#00B4D8,color:#fff,stroke:#0096B4,stroke-width:2px

    subgraph INSTALL["📦  INSTALL (one time)"]
        A1["Download Quartus II 10.0<br/>Web Edition (Altera/Intel)"]:::install
        A2["Install to<br/>C:\\altera\\10.0"]:::install
        A3["Connect DE2-115 via<br/>USB-Blaster cable"]:::install
        A4["Power on DE2-115<br/>(12V DC adapter)"]:::install
        A5["Windows detects USB-Blaster<br/>→ install driver automatically"]:::install
    end

    subgraph SETUP["⚙️  SETUP (each session)"]
        B1["Clone this repo:<br/>git clone git@github.com:Parafounder01/<br/>De2-115-skill-agent.git"]:::write
        B2["Run setenv.bat to add<br/>Quartus to PATH"]:::write
        B3["Check cable detection:<br/>quartus_pgm -l"]:::tool
    end

    subgraph CREATE["📝  CREATE your design"]
        C1["Write your top-level<br/>Verilog module (.v)"]:::write
        C2["Create .qsf project file<br/>with pin assignments"]:::write
        C3["(Optional) Add timing<br/>constraints (.sdc)"]:::write
    end

    subgraph BUILD["🔨  BUILD the bitstream"]
        D1["Step 1/5: quartus_map<br/>Analysis & Synthesis"]:::build
        D2["Step 2/5: quartus_fit<br/>Place & Route"]:::build
        D3["Step 3/5: quartus_asm<br/>Assemble .sof"]:::build
        D4["Step 4/5: quartus_sta<br/>Timing Analysis"]:::build
    end

    subgraph PROGRAM["🚀  PROGRAM the FPGA"]
        E0{"quartus_pgm -l<br/>cable detected?"}:::tool
        E1["quartus_pgm -c<br/>'USB-Blaster [USB-0]'<br/>-m jtag -o p;file.sof"]:::prog
        E2["JTAG ID 0x020F70DD<br/>= EP4CE115 detected"]:::test
        E3["Configuration succeeded<br/>1 device(s) configured"]:::test
    end

    subgraph VERIFY["✅  VERIFY"]
        F1["<b>dancing_led:</b> LEDR bounces<br/>left → right → left"]:::test
        F2["<b>blink_led:</b> LEDG[0] blinks<br/>every 30 ms"]:::test
        F3["Change SW[0] to reset<br/>the design"]:::tool
    end

    A1 --> A2 --> A3 --> A4 --> A5
    A5 --> B1 --> B2 --> B3
    B3 -->|"✅ USB-Blaster [USB-0]"| C1
    B3 -->|"❌ No hardware"| B3
    
    C1 & C2 & C3 --> D1
    D1 --> D2 --> D3 --> D4
    
    D4 -->|"✅ All steps pass"| E0
    D4 -->|"❌ Error"| D1
    
    E0 -->|"✅ Cable OK"| E1
    E0 -->|"❌ No cable<br/>check driver"| B3
    E1 --> E2 --> E3
    
    E3 --> F1 & F2 & F3
```

---

## <img valign='middle' alt='swatch' src='https://readme-swatches.vercel.app/7B2CBF?style=square&size=18'/> Troubleshooting

| Problem <img valign='middle' alt='' src='https://readme-swatches.vercel.app/ED1C24?style=square&size=14'/> | Cause <img valign='middle' alt='' src='https://readme-swatches.vercel.app/FFD700?style=square&size=14'/> | Fix <img valign='middle' alt='' src='https://readme-swatches.vercel.app/00A651?style=square&size=14'/> |
|---------|-------|-----|
| `Illegal location assignment PIN_J2` | Wrong pin — J2 is a dedicated config pin | Use the correct pin from the tables above |
| `Unknown long option --l` | Used `--l` instead of `-l` | Change to `quartus_pgm -l` |
| `No JTAG hardware available` | `jtagd.exe` missing from Quartus 10.0 | Ignore it — `quartus_pgm -c "USB-Blaster [USB-0]"` still works |
| `Can't fit design in device` | Too many resources or illegal pin | Check pins, reduce logic |
| `Timing requirements not met` | No clock constraint (.sdc) | Benign for simple designs. Add `.sdc` if needed |
| Device not detected by `quartus_pgm -l` | Driver issue on Windows 11 | Use Quartus Prime driver (signed) — `quartus_pgm` opens cable directly |

---

## <img valign='middle' alt='swatch' src='https://readme-swatches.vercel.app/00A651?style=square&size=18'/> Loading as an AI Agent Skill

Tell your AI agent:

> Load skill: de2-115-skill-agent  
> Reference: SKILL.md for pin tables + QUARTUS_CLI.md for commands  
> Board: DE2-115 (Cyclone IV EP4CE115F29C7), 50 MHz, 18 red LEDs, 9 green LEDs  
> Workflow: map → fit → asm → sta → pgm via Quartus II 10.0 CLI

---

## <img valign='middle' alt='swatch' src='https://readme-swatches.vercel.app/888888?style=square&size=18'/> License

Reference material (pin assignments, manual) copyright © Terasic Technologies Inc.  
Tool scripts and documentation provided as-is for AI-assisted DE2-115 development.

---

<p align="center">
<img valign='middle' alt='red' src='https://readme-swatches.vercel.app/ED1C24?style=square&size=20'/>
<img valign='middle' alt='green' src='https://readme-swatches.vercel.app/00A651?style=square&size=20'/>
<img valign='middle' alt='blue' src='https://readme-swatches.vercel.app/0078C0?style=square&size=20'/>
<img valign='middle' alt='yellow' src='https://readme-swatches.vercel.app/FFD700?style=round&size=20'/>
<br/>
<strong>DE2-115 Skill Agent</strong> — Built for the <a href="https://www.terasic.com.tw">Terasic</a> DE2-115 FPGA Board
</p>
