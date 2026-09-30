---
description: Audit permission decisions and the config itself, propose rule changes
argument-hint: "[denied|review|focus]"
---
Run the permission report script and act on its output in this session:

    python3 ~/.config/pi/agent/extensions/pi-permission-system/report.py ${1:-}

It reports only decisions made under the current config (window starts at config.json's mtime, which any rewrite of that file moves — even one that changes nothing — so use `--all` when the window looks too small).

## From the report

Turn each section into a concrete `config.json` change — the exact JSON snippet, then a diff against `~/.config/pi/agent/extensions/pi-permission-system/config.json`. Favor allow rules for repeated benign asks, an explicit rule for anything the reviewer denied at high risk, and prunes only for dead deny rules (allow rules look dead under yoloMode; the script's note explains).

- "Shadowed entries" non-empty is the top finding: a bare `path`/`external_directory` entry is placed first at load, so the explicit directional catch-all decides instead of it. Move the intended grant into the directional key it was meant to govern (`external_directory_read` for reads), never into `piInfrastructureReadPaths`.
- "Live asks by deciding surface" is where the friction actually is. Propose an allow on the surface named there: a read ask needs `*_read`, a write ask `*_write`, and a bare-family ask needs both.
- "External-directory grants applied" are standing session grants, not dialogs: read them as "this directory keeps needing a grant", never as proof the gate bypassed a config allow. The log carries no path for a live boundary ask, so a bypass claim is not decidable from it.
- Never propose `piInfrastructureReadPaths` as a way to stop prompts: it covers only `read`/`find`/`grep`/`ls` (not bash), never appears in this report, and overrides denies.

## From the config itself

Then read the full `config.json` and judge the rules the log may never have exercised — the report only sees what actually got decided. Flag:

- allows that are too broad to be deliberate (`"*": "allow"` anywhere, write/edit allowed on wide paths, `external_directory` allowing $HOME wholesale)
- allows that contradict their neighbors (an allow more specific than a deny that it could shadow, duplicate or contradictory patterns)
- deny gaps: secrets and destructives not covered — `.env*`, `.pem`/`.key`/`.keyring`, `~/.ssh`, `auth.json`, `sudo`, credentials dirs, `~/.local/share/keyrings`, `~/.local/share/gnupg`; note that an external-directory allow never weakens a `path` deny, so secrets belong on `path`
- rule order inside a pattern map: later rules win, so a hard deny has to sit after any allow or ask covering the same path — a map is an ordered rule list, not a set
- `piInfrastructureReadPaths` entries that are not Pi's own plumbing (its agent dir, package roots and install dir are built in). An entry there is deny-proof and read-tool-only, so one whose paths a read-surface allow already covers is dead weight that still overrides denies — flag it and move it to `external_directory_read`
- anything whose reason comment (if present) no longer matches the rule
- `yoloMode`/`authorizerChain` interactions that make a section decorative

Flag each with severity (dangerous / questionable / stale) and a proposed change. Uncertain calls go to the user, not the diff.

Show the combined diff (report-driven + config-review changes) and wait for confirmation before editing. Save the full script output to /tmp/permission-audit.txt if the user asks for a file copy.
