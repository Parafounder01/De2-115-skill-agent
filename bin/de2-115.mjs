#!/usr/bin/env node
/**
 * de2-115 — CLI tool for DE2-115 FPGA board management
 * Usage:  de2-115 <command> [options]
 *         node bin/de2-115.mjs <command>
 *
 * Commands:
 *   build [project]   — Full compile (map → fit → asm → sta)
 *   program [project] — Program .sof to FPGA via USB-Blaster
 *   check             — List JTAG cables and connected devices
 *   project [name]    — Scaffold a new DE2-115 project
 *   info              — Show board info and environment status
 */

import { execSync, spawn } from "node:child_process";
import { existsSync, readFileSync, mkdirSync, writeFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, "..");

// ── Default paths ──────────────────────────────────────────────
const QUARTUS_BIN = "C:\\altera\\10.0\\quartus\\bin";
const DEFAULT_PROJECT = "blink_led";

// ── Helpers ────────────────────────────────────────────────────

function qRun(cmd, label) {
  console.log(`\n  [${label}] ${cmd}`);
  try {
    const out = execSync(cmd, { cwd: ROOT, stdio: "pipe", encoding: "utf8", timeout: 300000 });
    const lastLine = out.trim().split("\n").pop() || "";
    if (lastLine.toLowerCase().includes("error") || lastLine.toLowerCase().includes("unsuccessful")) {
      console.error(`  ✘ ${label} FAILED`);
      console.error(out);
      process.exit(1);
    }
    console.log(`  ✔ ${label} OK`);
    return out;
  } catch (e) {
    console.error(`  ✘ ${label} FAILED`);
    console.error(e.stderr || e.message);
    process.exit(1);
  }
}

function envPath() {
  return `PATH=${QUARTUS_BIN};${process.env.PATH || ""}`;
}

// ── Commands ───────────────────────────────────────────────────

function cmdBuild(project) {
  project = project || DEFAULT_PROJECT;
  const qsf = join(ROOT, `${project}.qsf`);
  if (!existsSync(qsf)) {
    console.error(`  ✘ Project file not found: ${qsf}`);
    process.exit(1);
  }

  console.log(`\n  ┌─────────────────────────────────┐`);
  console.log(`  │  DE2-115 Build: ${project.padEnd(19)}│`);
  console.log(`  └─────────────────────────────────┘`);

  qRun(`quartus_map ${project}`, "1/5 Synthesis");
  qRun(`quartus_fit ${project}`, "2/5 Place & Route");
  qRun(`quartus_asm ${project}`, "3/5 Assemble .sof");
  qRun(`quartus_sta ${project}`, "4/5 Timing Analysis");

  // Check .sof
  const sof = join(ROOT, "output_files", `${project}.sof`);
  if (existsSync(sof)) {
    const size = (readFileSync(sof).length / 1024 / 1024).toFixed(1);
    console.log(`  ───────────────────────────────────`);
    console.log(`  ✔ Build complete: ${project}.sof (${size} MB)`);
    console.log(`  ───────────────────────────────────`);
  } else {
    console.error(`  ✘ .sof not found at output_files/${project}.sof`);
    process.exit(1);
  }
}

function cmdProgram(project) {
  project = project || DEFAULT_PROJECT;
  const sof = join(ROOT, "output_files", `${project}.sof`);
  if (!existsSync(sof)) {
    console.error(`  ✘ .sof not found: ${sof}. Run 'de2-115 build' first.`);
    process.exit(1);
  }

  cmdCheck();

  const cable = "USB-Blaster [USB-0]";
  console.log(`\n  Programming ${project}.sof to ${cable}...`);
  try {
    const out = execSync(
      `quartus_pgm -c "${cable}" -m jtag -o "p;output_files\\${project}.sof"`,
      { cwd: ROOT, env: { ...process.env, PATH: envPath() }, stdio: "pipe", encoding: "utf8", timeout: 60000 }
    );
    if (out.includes("Configuration succeeded")) {
      console.log(`  ✔ FPGA programmed successfully!`);
    } else {
      console.log(out);
    }
  } catch (e) {
    console.error(`  ✘ Programming failed:`);
    console.error(e.stderr || e.message);
    process.exit(1);
  }
}

function cmdCheck() {
  console.log(`\n  ── JTAG Hardware ──`);
  try {
    const out = execSync(`quartus_pgm -l`, {
      env: { ...process.env, PATH: envPath() },
      stdio: "pipe", encoding: "utf8", timeout: 10000
    });
    console.log(out.trim());
    if (out.includes("USB-Blaster")) {
      console.log(`  ✔ USB-Blaster detected`);
    } else {
      console.log(`  ⚠ No USB-Blaster found (driver or cable issue)`);
    }
  } catch (e) {
    console.log(`  ⚠ No JTAG hardware available (jtagd may be missing, try quartus_pgm directly)`);
  }

  console.log(`\n  ── Environment ──`);
  console.log(`  Node:    ${process.version}`);
  console.log(`  Quartus: ${existsSync(QUARTUS_BIN) ? "✔ installed" : "✘ NOT FOUND"}`);
  console.log(`  Project: ${ROOT}`);
}

function cmdScaffold(name) {
  if (!name) {
    console.error("  Usage: de2-115 project <name>");
    process.exit(1);
  }
  const dir = join(process.cwd(), name);
  if (existsSync(dir)) {
    console.error(`  ✘ Directory already exists: ${dir}`);
    process.exit(1);
  }
  mkdirSync(dir, { recursive: true });
  mkdirSync(join(dir, "output_files"));

  // Verilog template
  writeFileSync(join(dir, `${name}.v`), `// ${name}.v — DE2-115 top module
// clk = 50 MHz (PIN_Y2), rst = active-high (PIN_AB28, SW[0])
module ${name} (
    input  wire       clk,
    input  wire       rst,
    output reg [17:0] ledr
);
    reg [24:0] counter;
    localparam HALF_PERIOD = 25'd1_500_000;  // 30 ms @ 50 MHz
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 25'd0;
            ledr    <= 18'h0_0001;
        end else begin
            if (counter >= HALF_PERIOD) begin
                counter <= 25'd0;
                ledr    <= {ledr[16:0], ledr[17]};
            end else begin
                counter <= counter + 25'd1;
            end
        end
    end
endmodule
`);

  // QSF template
  writeFileSync(join(dir, `${name}.qsf`), `# ${name} — DE2-115 Quartus Settings File
set_global_assignment -name FAMILY "Cyclone IV E"
set_global_assignment -name DEVICE EP4CE115F29C7
set_global_assignment -name TOP_LEVEL_ENTITY ${name}
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
set_global_assignment -name SOURCE_FILE ${name}.v

# Clock
set_location_assignment -to clk PIN_Y2

# Reset (SW[0])
set_location_assignment -to rst PIN_AB28

# LEDR[17:0]
set_location_assignment -to ledr[0]  PIN_G19
set_location_assignment -to ledr[1]  PIN_F19
set_location_assignment -to ledr[2]  PIN_E19
set_location_assignment -to ledr[3]  PIN_F21
set_location_assignment -to ledr[4]  PIN_F18
set_location_assignment -to ledr[5]  PIN_E18
set_location_assignment -to ledr[6]  PIN_J19
set_location_assignment -to ledr[7]  PIN_H19
set_location_assignment -to ledr[8]  PIN_J17
set_location_assignment -to ledr[9]  PIN_G17
set_location_assignment -to ledr[10] PIN_J15
set_location_assignment -to ledr[11] PIN_H16
set_location_assignment -to ledr[12] PIN_J16
set_location_assignment -to ledr[13] PIN_H17
set_location_assignment -to ledr[14] PIN_F15
set_location_assignment -to ledr[15] PIN_G15
set_location_assignment -to ledr[16] PIN_G16
set_location_assignment -to ledr[17] PIN_H15
`);

  // Template build script
  writeFileSync(join(dir, `build_${name}.bat`), `@echo off
setlocal enabledelayedexpansion
set PROJECT=${name}
set CABLE=USB-Blaster [USB-0]
set QUARTUS_BIN=C:\\altera\\10.0\\quartus\\bin
set PATH=!QUARTUS_BIN!;!PATH!

echo [1/5] Synthesis...  && call quartus_map  !PROJECT! || goto :fail
echo [2/5] Place+Route.. && call quartus_fit  !PROJECT! || goto :fail
echo [3/5] Assemble...   && call quartus_asm  !PROJECT! || goto :fail
echo [4/5] Timing...     && call quartus_sta  !PROJECT! || goto :fail
echo [5/5] Program...    && call quartus_pgm -c "!CABLE!" -m jtag -o "p;output_files\\!PROJECT!.sof" || goto :fail
echo DONE && goto :end
:fail
echo FAILED
:end
endlocal
`);

  console.log(`\n  ✔ Created project "${name}" at:\n    ${dir}`);
  console.log(`  Files:\n    ${name}.v\n    ${name}.qsf\n    build_${name}.bat\n    output_files/`);
}

function cmdInfo() {
  cmdCheck();
  console.log(`\n  ── Skill Files ──`);
  const files = ["SKILL.md", "QUARTUS_CLI.md", "dancing_led.v", "blink_led.qsf", "build_and_program.bat"];
  for (const f of files) {
    console.log(`  ${existsSync(join(ROOT, f)) ? "✔" : "✘"} ${f}`);
  }
}

// ── Main ───────────────────────────────────────────────────────

const [cmd, ...args] = process.argv.slice(2);

switch (cmd) {
  case "build":
  case "b":     cmdBuild(args[0]); break;
  case "program":
  case "p":     cmdProgram(args[0]); break;
  case "check":
  case "c":     cmdCheck(); break;
  case "project":
  case "new":
  case "n":     cmdScaffold(args[0] || "de2_115_project"); break;
  case "info":
  case "i":     cmdInfo(); break;
  default:
    console.log(`
  DE2-115 Skill Agent — CLI

  Usage:  de2-115 <command> [options]

  Commands:
    build [project]    — Full compile (.v → .sof)
    program [project]  — Program .sof to FPGA
    check              — Detect USB-Blaster + environment
    project <name>     — Scaffold new DE2-115 project
    info               — Show full board/environment status

  Examples:
    de2-115 build
    de2-115 program blink_led
    de2-115 project my_audio_project
    de2-115 check

  Projects map to .qsf files in the current directory.
  Default project: blink_led
`);
    process.exit(cmd ? 1 : 0);
}
