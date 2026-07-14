#!/usr/bin/env node
/**
 * install-skill.mjs — postinstall hook for de2-115-skill-agent
 *
 * Installs the skill for all supported AI agent platforms:
 *   1. Mythos Router  → ~/.mythos-router/skills/de2-115/
 *   2. Opencode       → ~/.config/opencode/skills/de2-115/
 *   3. Claude Desktop → ~/.config/Claude/claude_desktop_config.json (merge)
 *
 * Run automatically on `npm install` or manually:
 *   node scripts/install-skill.mjs
 */

import { copyFileSync, mkdirSync, existsSync, readFileSync, writeFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { homedir, platform } from "node:os";

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, "..");

const HOME = homedir();
const PLATFORM = platform();

const SKILL_FILES = [
  "SKILL.md",
  "QUARTUS_CLI.md",
  "dancing_led.v",
  "blink_led.qsf",
  "build_and_program.bat",
  "setenv.bat",
  "DE2_115_User_manual.pdf"
];

// ── Platform skill directories ──────────────────────────────

const TARGETS = [
  {
    name: "Mythos Router",
    dir: join(HOME, ".mythos-router", "skills", "de2-115"),
    configFile: join(HOME, ".mythos-router", "skills", "de2-115", "mythos-skill.json"),
    configSrc: join(ROOT, "agent-config", "mythos-skill.json")
  },
  {
    name: "Opencode",
    dir: join(HOME, ".config", "opencode", "skills", "de2-115"),
    configFile: join(HOME, ".config", "opencode", "skills", "de2-115", "opencode-skill.json"),
    configSrc: join(ROOT, "agent-config", "opencode-skill.json")
  }
];

// ── Claude Desktop config path (platform-specific) ──────────

function claudeConfigPath() {
  if (PLATFORM === "win32") {
    return join(process.env.APPDATA || join(HOME, "AppData", "Roaming"), "Claude", "claude_desktop_config.json");
  } else if (PLATFORM === "darwin") {
    return join(HOME, "Library", "Application Support", "Claude", "claude_desktop_config.json");
  } else {
    return join(HOME, ".config", "Claude", "claude_desktop_config.json");
  }
}

// ── Installer ───────────────────────────────────────────────

let installed = 0;
let errors = 0;

console.log("");
console.log("  ┌────────────────────────────────────────────┐");
console.log("  │  DE2-115 Skill Agent — AI Platform Install │");
console.log("  └────────────────────────────────────────────┘");
console.log("");

// 1. Copy skill files to each platform
for (const target of TARGETS) {
  try {
    mkdirSync(target.dir, { recursive: true });
    console.log(`  [${target.name}] Installing to ${target.dir}`);

    for (const file of SKILL_FILES) {
      const src = join(ROOT, file);
      if (existsSync(src)) {
        copyFileSync(src, join(target.dir, file));
        installed++;
      }
    }

    // Copy platform config
    if (existsSync(target.configSrc)) {
      copyFileSync(target.configSrc, target.configFile);
      console.log(`  [${target.name}] Config copied`);
    }

    console.log(`  [${target.name}] ✔ Installed ${installed} files\n`);
  } catch (e) {
    errors++;
    console.error(`  [${target.name}] ✘ Error: ${e.message}\n`);
  }
}

// 2. Claude Desktop config merge
try {
  const claudePath = claudeConfigPath();
  console.log(`  [Claude Desktop] Config at ${claudePath}`);

  let config = { mcpServers: {} };
  if (existsSync(claudePath)) {
    config = JSON.parse(readFileSync(claudePath, "utf8"));
  }

  const mcpEntry = {
    command: "node",
    args: [join(ROOT, "mcp-server", "de2-115-mcp.mjs")],
    env: { DE2_115_ROOT: ROOT }
  };

  if (!config.mcpServers) config.mcpServers = {};
  config.mcpServers["de2-115"] = mcpEntry;

  mkdirSync(dirname(claudePath), { recursive: true });
  writeFileSync(claudePath, JSON.stringify(config, null, 2), "utf8");
  console.log(`  [Claude Desktop] ✔ MCP server merged into config`);
} catch (e) {
  errors++;
  console.error(`  [Claude Desktop] ✘ Error: ${e.message}`);
}

console.log("");
console.log(`  ───────────────────────────────────────────────`);
console.log(`  ✔ ${installed} files installed across ${TARGETS.length} platforms`);
if (errors) console.log(`  ⚠ ${errors} errors encountered`);
console.log(`  ───────────────────────────────────────────────`);
console.log(`  Tip: If paths change, re-run: node scripts/install-skill.mjs`);
console.log("");
