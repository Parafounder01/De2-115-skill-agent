#!/usr/bin/env node
/**
 * de2-115-mcp.mjs — Model Context Protocol (MCP) server for DE2-115 FPGA
 *
 * Run as:  node mcp-server/de2-115-mcp.mjs
 * AI tools connect via stdio (JSON-RPC 2.0 / MCP protocol).
 *
 * Exposes:
 *   Tools:
 *     - build_project     — Compile a .qsf project
 *     - program_fpga      — Program .sof to DE2-115
 *     - list_cables       — Detect JTAG hardware
 *     - scaffold_project  — Generate new project template
 *     - read_pin_status   — Return assigned pins from .qsf
 *
 *   Resources:
 *     - de2-115://project/{name}/sof      — .sof file path
 *     - de2-115://board/specs             — Board specifications
 *     - de2-115://pinout/ledr             — LEDR pin table
 *     - de2-115://pinout/ledg             — LEDG pin table
 *     - de2-115://pinout/sw               — SW pin table
 *
 *   Prompts:
 *     - new_project — Template for starting a new DE2-115 design
 *     - debug_build — Template for troubleshooting build errors
 */

import { spawn, execSync } from "node:child_process";
import { existsSync, readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { createInterface } from "node:readline";

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, "..");
const QUARTUS_BIN = "C:\\altera\\10.0\\quartus\\bin";

// ── Minimal JSON-RPC 2.0 / MCP transport over stdio ──────────
// Implements the MCP protocol without the SDK for minimal deps.

const rl = createInterface({ input: process.stdin, crlfDelay: Infinity });
let msgId = 0;

// Resources
const RESOURCES = {
  "de2-115://board/specs": {
    uri: "de2-115://board/specs",
    name: "DE2-115 Board Specifications",
    mimeType: "text/markdown",
    description: "Full specs for the Terasic DE2-115 (Cyclone IV EP4CE115F29C7)"
  },
  "de2-115://pinout/ledr": {
    uri: "de2-115://pinout/ledr",
    name: "LEDR[17:0] Pin Assignments",
    mimeType: "text/markdown",
    description: "18 red LED pin locations on EP4CE115F29C7"
  },
  "de2-115://pinout/ledg": {
    uri: "de2-115://pinout/ledg",
    name: "LEDG[8:0] Pin Assignments",
    mimeType: "text/markdown",
    description: "9 green LED pin locations"
  },
  "de2-115://pinout/sw": {
    uri: "de2-115://pinout/sw",
    name: "SW[17:0] Pin Assignments",
    mimeType: "text/markdown",
    description: "18 slide switch pin locations"
  }
};

const PIN_LEDR = `| Signal    | FPGA Pin |
|-----------|----------|
| LEDR[0]   | PIN_G19  |
| LEDR[1]   | PIN_F19  |
| LEDR[2]   | PIN_E19  |
| LEDR[3]   | PIN_F21  |
| LEDR[4]   | PIN_F18  |
| LEDR[5]   | PIN_E18  |
| LEDR[6]   | PIN_J19  |
| LEDR[7]   | PIN_H19  |
| LEDR[8]   | PIN_J17  |
| LEDR[9]   | PIN_G17  |
| LEDR[10]  | PIN_J15  |
| LEDR[11]  | PIN_H16  |
| LEDR[12]  | PIN_J16  |
| LEDR[13]  | PIN_H17  |
| LEDR[14]  | PIN_F15  |
| LEDR[15]  | PIN_G15  |
| LEDR[16]  | PIN_G16  |
| LEDR[17]  | PIN_H15  |`;

const PIN_LEDG = `| Signal   | FPGA Pin |
|----------|----------|
| LEDG[0]  | PIN_E21  |
| LEDG[1]  | PIN_E22  |
| LEDG[2]  | PIN_E25  |
| LEDG[3]  | PIN_E24  |
| LEDG[4]  | PIN_H21  |
| LEDG[5]  | PIN_G20  |
| LEDG[6]  | PIN_G22  |
| LEDG[7]  | PIN_G21  |
| LEDG[8]  | PIN_F17  |`;

const PIN_SW = `| Signal  | FPGA Pin |
|---------|----------|
| SW[0]   | PIN_AB28 |
| SW[1]   | PIN_AC28 |
| SW[2]   | PIN_AC27 |
| SW[3]   | PIN_AD27 |
| SW[4]   | PIN_AB27 |
| SW[5]   | PIN_AC26 |
| SW[6]   | PIN_AD26 |
| SW[7]   | PIN_AB26 |
| SW[8]   | PIN_AC25 |
| SW[9]   | PIN_AB25 |
| SW[10]  | PIN_AC24 |
| SW[11]  | PIN_AB24 |
| SW[12]  | PIN_AB23 |
| SW[13]  | PIN_AA24 |
| SW[14]  | PIN_AA23 |
| SW[15]  | PIN_AA22 |
| SW[16]  | PIN_Y24  |
| SW[17]  | PIN_Y23  |`;

const BOARD_SPECS = `# DE2-115 Specifications
- FPGA: Cyclone IV EP4CE115F29C7 (114,480 LEs)
- Clock: 50 MHz on PIN_Y2
- Red LEDs: 18 (LEDR[17:0])
- Green LEDs: 9 (LEDG[8:0])
- Switches: 18 slide (SW[17:0]) + 4 push-buttons (KEY[3:0])
- 7-Segment displays: 8 (HEX[7:0])
- SDRAM: 2 × 64 MB | SRAM: 2 MB | Flash: 8 MB
- Ethernet: 2 × 10/100/1000 | VGA | Audio WM8731
- USB-Blaster: Built-in (EPM240)
- I/O voltage: 2.5 V / 3.3 V per bank`;

// ── Tool implementations ────────────────────────────────────

function envPath() {
  return `PATH=${QUARTUS_BIN};${process.env.PATH || ""}`;
}

function toolListCables() {
  try {
    const out = execSync("quartus_pgm -l", {
      env: { ...process.env, PATH: envPath() },
      stdio: "pipe", encoding: "utf8", timeout: 10000
    });
    const cables = out.trim().split("\n").filter(l => l.includes("USB-Blaster") || l.includes(")"))
      .map(l => l.trim());
    return {
      content: [{ type: "text", text: cables.length ? cables.join("\n") : "No cables detected" }],
      isError: cables.length === 0
    };
  } catch {
    return {
      content: [{ type: "text", text: "No JTAG hardware available (jtagd may be missing; try quartus_pgm directly)" }],
      isError: false
    };
  }
}

function toolBuildProject(project) {
  if (!project) return { content: [{ type: "text", text: "Error: project name required" }], isError: true };

  const steps = ["quartus_map", "quartus_fit", "quartus_asm", "quartus_sta"];
  const labels = ["Synthesis", "Place & Route", "Assemble .sof", "Timing Analysis"];
  let log = "";

  for (let i = 0; i < steps.length; i++) {
    log += `[${i + 1}/${steps.length}] ${labels[i]}...\n`;
    try {
      const out = execSync(`${steps[i]} ${project}`, {
        cwd: ROOT,
        env: { ...process.env, PATH: envPath() },
        stdio: "pipe", encoding: "utf8", timeout: 300000
      });
      const ok = out.toLowerCase().includes("successful");
      log += ok ? `  ✔ ${labels[i]} OK\n` : `  ⚠ ${labels[i]} completed with issues\n`;
    } catch (e) {
      log += `  ✘ ${labels[i]} FAILED\n${e.stderr || e.message}\n`;
      return { content: [{ type: "text", text: log }], isError: true };
    }
  }

  const sof = join(ROOT, "output_files", `${project}.sof`);
  if (existsSync(sof)) {
    const size = (readFileSync(sof).length / 1024).toFixed(0);
    log += `\n✔ Build complete: output_files/${project}.sof (${size} KB)`;
  } else {
    log += `\n⚠ .sof not found at output_files/${project}.sof`;
  }

  return { content: [{ type: "text", text: log }], isError: false };
}

function toolProgramFpga(project) {
  if (!project) return { content: [{ type: "text", text: "Error: project name required" }], isError: true };

  const sof = join(ROOT, "output_files", `${project}.sof`);
  if (!existsSync(sof)) {
    return { content: [{ type: "text", text: `Error: ${project}.sof not found. Build first.` }], isError: true };
  }

  try {
    const cable = "USB-Blaster [USB-0]";
    const out = execSync(
      `quartus_pgm -c "${cable}" -m jtag -o "p;output_files\\${project}.sof"`,
      {
        cwd: ROOT,
        env: { ...process.env, PATH: envPath() },
        stdio: "pipe", encoding: "utf8", timeout: 60000
      }
    );
    if (out.includes("Configuration succeeded")) {
      return {
        content: [{ type: "text", text: `✔ FPGA programmed with ${project}.sof — DE2-115 configured successfully` }],
        isError: false
      };
    }
    return { content: [{ type: "text", text: out }], isError: false };
  } catch (e) {
    return { content: [{ type: "text", text: `Error: ${e.stderr || e.message}` }], isError: true };
  }
}

function toolScaffold(name) {
  if (!name) return { content: [{ type: "text", text: "Error: project name required" }], isError: true };

  const dir = join(process.cwd(), name);
  if (existsSync(dir)) return { content: [{ type: "text", text: `Directory exists: ${dir}` }], isError: true };

  mkdirSync(dir, { recursive: true });
  mkdirSync(join(dir, "output_files"));

  writeFileSync(join(dir, `${name}.v`), `// ${name}.v — DE2-115 top module
module ${name} (
    input  wire       clk,
    input  wire       rst,
    output reg [17:0] ledr
);
    reg [24:0] counter;
    localparam HALF_PERIOD = 25'd1_500_000;
    always @(posedge clk or posedge rst) begin
        if (rst) begin counter <= 0; ledr <= 18'h1; end
        else if (counter >= HALF_PERIOD) begin counter <= 0; ledr <= {ledr[16:0], ledr[17]}; end
        else counter <= counter + 1;
    end
endmodule
`);

  writeFileSync(join(dir, `${name}.qsf`), `set_global_assignment -name FAMILY "Cyclone IV E"
set_global_assignment -name DEVICE EP4CE115F29C7
set_global_assignment -name TOP_LEVEL_ENTITY ${name}
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
set_global_assignment -name SOURCE_FILE ${name}.v
set_location_assignment -to clk PIN_Y2
set_location_assignment -to rst PIN_AB28
`);

  return {
    content: [{
      type: "text",
      text: `✔ Created project "${name}" at ${dir}\n- ${name}.v\n- ${name}.qsf\n- output_files/`
    }],
    isError: false
  };
}

function toolReadPinStatus(project) {
  if (!project) return { content: [{ type: "text", text: "Error: project name required" }], isError: true };

  const qsf = join(ROOT, `${project}.qsf`);
  if (!existsSync(qsf)) {
    return { content: [{ type: "text", text: `Project file not found: ${qsf}` }], isError: true };
  }

  const content = readFileSync(qsf, "utf8");
  const pins = content.split("\n")
    .filter(l => l.includes("set_location_assignment"))
    .map(l => l.trim())
    .join("\n");

  return {
    content: [{ type: "text", text: `Pin assignments for ${project}:\n\n${pins}` }],
    isError: false
  };
}

// ── MCP handlers ────────────────────────────────────────────

function handleRequest(req) {
  const { id, method, params = {} } = req;

  switch (method) {

    // ── Initialize ──
    case "initialize":
      respond(id, {
        protocolVersion: "2024-11-05",
        capabilities: {
          tools: {},
          resources: {},
          prompts: {}
        },
        serverInfo: {
          name: "de2-115-mcp",
          version: "1.1.0"
        }
      });
      break;

    case "notifications/initialized":
      // no response needed
      break;

    // ── Tools ──
    case "tools/list":
      respond(id, {
        tools: [
          {
            name: "build_project",
            description: "Compile a DE2-115 Quartus project (map → fit → asm → sta)",
            inputSchema: {
              type: "object",
              properties: {
                project: { type: "string", description: "Project name (matches .qsf file)" }
              },
              required: ["project"]
            }
          },
          {
            name: "program_fpga",
            description: "Program a .sof bitstream to the DE2-115 FPGA via USB-Blaster JTAG",
            inputSchema: {
              type: "object",
              properties: {
                project: { type: "string", description: "Project name for .sof in output_files/" }
              },
              required: ["project"]
            }
          },
          {
            name: "list_cables",
            description: "List connected JTAG cables and devices",
            inputSchema: {
              type: "object",
              properties: {}
            }
          },
          {
            name: "scaffold_project",
            description: "Generate a new DE2-115 project template with .v + .qsf files",
            inputSchema: {
              type: "object",
              properties: {
                name: { type: "string", description: "New project name" }
              },
              required: ["name"]
            }
          },
          {
            name: "read_pin_status",
            description: "Read pin assignments from a project's .qsf file",
            inputSchema: {
              type: "object",
              properties: {
                project: { type: "string", description: "Project name" }
              },
              required: ["project"]
            }
          }
        ]
      });
      break;

    case "tools/call":
      const toolName = params.name;
      const args = params.arguments || {};
      let result;

      switch (toolName) {
        case "build_project":      result = toolBuildProject(args.project); break;
        case "program_fpga":       result = toolProgramFpga(args.project); break;
        case "list_cables":        result = toolListCables(); break;
        case "scaffold_project":   result = toolScaffold(args.name); break;
        case "read_pin_status":    result = toolReadPinStatus(args.project); break;
        default:
          result = { content: [{ type: "text", text: `Unknown tool: ${toolName}` }], isError: true };
      }

      respond(id, result);
      break;

    // ── Resources ──
    case "resources/list":
      respond(id, {
        resources: Object.values(RESOURCES)
      });
      break;

    case "resources/read":
      const uri = params.uri;
      let text = "";
      switch (uri) {
        case "de2-115://board/specs": text = BOARD_SPECS; break;
        case "de2-115://pinout/ledr": text = PIN_LEDR; break;
        case "de2-115://pinout/ledg": text = PIN_LEDG; break;
        case "de2-115://pinout/sw":   text = PIN_SW; break;
        default:
          const r = RESOURCES[uri];
          if (r && uri.startsWith("de2-115://project/")) {
            const parts = uri.split("/");
            const projName = parts[3];
            const fileType = parts[4];
            if (fileType === "sof") {
              const spath = join(ROOT, "output_files", `${projName}.sof`);
              text = existsSync(spath) ? `output_files/${projName}.sof (${(readFileSync(spath).length / 1024).toFixed(0)} KB)` : "Not found";
            }
          } else {
            text = `Unknown resource: ${uri}`;
          }
      }
      respond(id, { contents: [{ uri, mimeType: "text/markdown", text }] });
      break;

    // ── Prompts ──
    case "prompts/list":
      respond(id, {
        prompts: [
          {
            name: "new_project",
            description: "Start a new DE2-115 FPGA design",
            arguments: [
              { name: "name", description: "Project name", required: true }
            ]
          },
          {
            name: "debug_build",
            description: "Troubleshoot a DE2-115 build failure",
            arguments: [
              { name: "error_text", description: "Error message from Quartus", required: true }
            ]
          }
        ]
      });
      break;

    case "prompts/get":
      const pname = params.name;
      if (pname === "new_project") {
        respond(id, {
          messages: [{
            role: "user",
            content: {
              type: "text",
              text: `I want to create a new DE2-115 project called "${params.arguments?.name || "my_project"}".\nPlease scaffold it using the scaffold_project tool, then write the Verilog module with:\n- 50 MHz clock on PIN_Y2\n- Active-high reset on SW[0] (PIN_AB28)\n- Outputs for the 18 red LEDs (LEDR[17:0])`
            }
          }]
        });
      } else if (pname === "debug_build") {
        respond(id, {
          messages: [{
            role: "user",
            content: {
              type: "text",
              text: `My DE2-115 build failed with this error:\n\n${params.arguments?.error_text || "(no error provided)"}\n\nPlease analyze and suggest fixes. Common causes:\n- Illegal pin assignments (wrong FPGA pin)\n- Missing source file (.v not found)\n- Device mismatch (not EP4CE115F29C7)\n- Resource overflow (too many logic elements)`
            }
          }]
        });
      } else {
        respond(id, { messages: [{ role: "user", content: { type: "text", text: `Unknown prompt: ${pname}` } }] });
      }
      break;

    default:
      // Support older MCP versions
      if (method.startsWith("notifications/")) break;
      respond(id, { error: { code: -32601, message: `Method not found: ${method}` } });
  }
}

function respond(id, result) {
  const msg = { jsonrpc: "2.0", id };
  if (result.error) {
    msg.error = result.error;
  } else {
    msg.result = result;
  }
  process.stdout.write(JSON.stringify(msg) + "\n");
}

// ── Startup message (JSON-RPC 2.0 not required for transport) ──
console.error("[de2-115-mcp] MCP server started — awaiting JSON-RPC 2.0 messages on stdin");

// ── Read loop ────────────────────────────────────────────────
let buffer = "";
rl.on("line", (line) => {
  // Handle MCP HTTP-like headers (Content-Length etc.)
  if (line.trim() === "") {
    if (buffer) {
      try {
        const req = JSON.parse(buffer);
        handleRequest(req);
      } catch (e) {
        console.error("[de2-115-mcp] Parse error:", e.message);
      }
      buffer = "";
    }
  } else if (line.startsWith("Content-Length:") || line.startsWith("content-length:")) {
    // ignore headers, buffer is the body
  } else {
    buffer += line;
  }
});

rl.on("close", () => {
  // Process any remaining buffer
  if (buffer) {
    try {
      const req = JSON.parse(buffer);
      handleRequest(req);
    } catch { /* ignore */ }
  }
  process.exit(0);
});
