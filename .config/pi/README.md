# Pi

Pi's user-global harness lives in `~/.config/pi/agent/`, which `PI_CODING_AGENT_DIR` points at.
What it shares with the Claude and Codex harnesses, and where they differ, is in [`docs/harness.md`](../docs/harness.md).
The live agents, skills, extensions and settings are authoritative for their own behaviour; this file covers what is tracked and what is easy to miss when operating it.

## What yadm tracks

`pi/.gitignore` is the whitelist and the only complete list: read it rather than a copy here.
In outline, the hand-maintained harness is tracked — `agent/AGENTS.md`, the settings and model JSON files, `agents/`, `skills/`, `prompts/` (each file becomes a `/`-command), `extensions/` with their configs, the local `patches/` library and the `bundler/`.
Skills the bootstrap links in from elsewhere, credentials, sessions, the npm checkout, caches and extension logs are not.

Track a new file by adding it to the whitelist, above the knockouts at the end, since gitignore's last matching rule wins; never `git add -f`.
`yadm status` showing nothing untracked under `pi/` is the check.

## Operating notes

- **Root commands** go through `pkexec`, never `sudo`, whose fingerprint prompt waits invisibly in Pi's pipes; allow a shell timeout of at least 60 seconds.
  Commands listed in `agent/always-ask.json` always reach you ([ADR-0071](../docs/adr/0071-ask-before-pkexec.md)).
- **`/yolo`** (or `pi --yolo`) approves every ask for the current session only ([ADR-0081](../docs/adr/0081-pi-session-yolo-always-ask.md)).
  Keep `always-ask` first in the authorizer chain so pkexec still prompts under it, and leave `yoloMode` in the permission config off: it applies to every running session.
- **The permission reviewer** asks `alias/reviewer`, a fallback chain defined and explained in `agent/model-alias.json`.
  Only provider failures move down the chain; a reviewer's `defer` is final.
  `/permission-audit` turns the permission log into proposed config edits.
- **Extension bundling** roughly halves startup but changes how modules load ([ADR-0067](../docs/adr/0067-bundle-pi-extensions.md)).
  When an extension hangs or misbehaves, run `node agent/bundler/bundle.mjs --revert` and retest before debugging the extension itself; run `/bundle-review` after installing or updating a package.
- **Local patches** in `agent/patches/` carry upstream fixes not yet released, and keep their package off the bundler; `agent/patches/reapply-all.sh` reapplies them after a package update.
- **Stray extension output** goes to `agent/tui-captured-output.log` with a warning while a TUI session runs, through `agent/extensions/tui-output-guard.ts`, instead of landing in the editor.
- **Web tools** need `/web-tools` run once before `web_search` or `web_fetch` work.
- **`bash-readonly`** gives the explorer and tester a disposable writable view of the project; it does not isolate the network.
- **`environment.d/20_pi.conf`** sets `PI_AUTO_REVIEW_ALLOW_UNTRUSTED_DEV=1`, so the auto-reviewer treats this dotfiles tree as a dev project; it is read from the process environment, not from Pi's config.
