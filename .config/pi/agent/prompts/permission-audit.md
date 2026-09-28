---
description: Report on permission decisions and propose config.json rule changes
argument-hint: "[denied|review|focus]"
---
Run the permission report script and act on its output in this session:

    python3 ~/.config/pi/agent/extensions/pi-permission-system/report.py ${1:-}

Read its sections (volume, dead rules, external-directory grants, repeated asks, denials, reviewer health) and turn each finding into a concrete `config.json` change — the exact JSON snippet, then a diff against `~/.config/pi/agent/extensions/pi-permission-system/config.json`. Favor allow rules for repeated benign asks, an explicit rule for anything the reviewer denied at high risk, and prunes only for dead deny rules (allow rules look dead under yoloMode; the script's note explains). Show the diff and wait for confirmation before editing.

If the script's "gate asked anyway" section is non-empty, that is the top finding: config allows the package's own evaluator honors are bypassed at runtime — propose the workaround (usually a `piInfrastructureReadPaths` entry for read-heavy paths) and offer to file it upstream.

Save the full script output to /tmp/permission-audit.txt if the user asks for a file copy.
