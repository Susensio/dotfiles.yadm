---
description: Audit permission decisions and the config itself, propose rule changes
argument-hint: "[denied|review|focus]"
---
Run the permission report script and act on its output in this session:

    python3 ~/.config/pi/agent/extensions/pi-permission-system/report.py ${1:-}

It reports only decisions made under the current config (window starts at config.json's mtime); add `--all` for full history.

## From the report

Turn each section into a concrete `config.json` change — the exact JSON snippet, then a diff against `~/.config/pi/agent/extensions/pi-permission-system/config.json`. Favor allow rules for repeated benign asks, an explicit rule for anything the reviewer denied at high risk, and prunes only for dead deny rules (allow rules look dead under yoloMode; the script's note explains). If the script's "gate asked anyway" section is non-empty, that is the top finding: config allows the package's own evaluator honors are bypassed at runtime — propose the workaround (usually `piInfrastructureReadPaths` entries for read-heavy paths) and offer to file it upstream.

## From the config itself

Then read the full `config.json` and judge the rules the log may never have exercised — the report only sees what actually got decided. Flag:

- allows that are too broad to be deliberate (`"*": "allow"` anywhere, write/edit allowed on wide paths, `external_directory` allowing $HOME wholesale)
- allows that contradict their neighbors (an allow more specific than a deny that it could shadow, duplicate or contradictory patterns)
- deny gaps: secrets and destructives not covered — `.env*`, `.pem/.key`, `~/.ssh`, `auth.json`, `sudo`, credentials dirs; a deny that exists on `path` but is bypassable via `bash` cat
- anything whose reason comment (if present) no longer matches the rule
- `yoloMode`/`authorizerChain` interactions that make a section decorative

Flag each with severity (dangerous / questionable / stale) and a proposed change. Uncertain calls go to the user, not the diff.

Show the combined diff (report-driven + config-review changes) and wait for confirmation before editing. Save the full script output to /tmp/permission-audit.txt if the user asks for a file copy.
