# De2-115-skill-agent

AI agent skill pack for the Terasic DE2-115 FPGA board (Cyclone IV EP4CE115F29C7).

Contains:
- `SKILL.md` — Complete pin reference + CLI build-and-program workflow
- `DE2_115_User_manual.pdf` — Official Terasic user manual
- `dancing_led.v` — Example: running-light across LEDR[17:0]
- `blink_led.qsf` — Example project file (pin assignments for the entire board)
- `build_and_program.bat` — One-click CLI build+program script

## Quick Start

```batch
git clone git@github.com:Parafounder01/De2-115-skill-agent.git
cd De2-115-skill-agent
.\build_and_program.bat
```

Load `SKILL.md` as an agent skill for AI-assisted DE2-115 development.
