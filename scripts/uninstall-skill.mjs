#!/usr/bin/env node
/**
 * uninstall-skill.mjs — postuninstall hook for de2-115-skill-agent
 *
 * Removes skill files from all AI agent platforms.
 * Run automatically on `npm uninstall` or manually:
 *   node scripts/uninstall-skill.mjs
 */

import { rmSync, existsSync } from "node:fs";
import { join } from "node:path";
import { homedir } from "node:os";

const HOME = homedir();

const TARGETS = [
  { name: "Mythos Router",  dir: join(HOME, ".mythos-router", "skills", "de2-115") },
  { name: "Opencode",       dir: join(HOME, ".config", "opencode", "skills", "de2-115") }
];

console.log("");
console.log("  ┌──────────────────────────────────────────────┐");
console.log("  │  DE2-115 Skill Agent — Uninstall             │");
console.log("  └──────────────────────────────────────────────┘\n");

for (const target of TARGETS) {
  try {
    if (existsSync(target.dir)) {
      rmSync(target.dir, { recursive: true, force: true });
      console.log(`  [${target.name}] ✔ Removed ${target.dir}`);
    } else {
      console.log(`  [${target.name}] — Not installed`);
    }
  } catch (e) {
    console.error(`  [${target.name}] ✘ Error: ${e.message}`);
  }
}

console.log("\n  ───────────────────────────────────────────────");
console.log("  ✔ Uninstall complete");
console.log("  ───────────────────────────────────────────────\n");
