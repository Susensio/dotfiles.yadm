# pi agent configuration

pi agent config lives in `$XDG_CONFIG_HOME/pi/` (`~/.config/pi`).

Only the hand-maintained harness is tracked here by yadm; runtime state is ignored.

## What is tracked

- `pi/.gitignore` — whitelists exactly these paths, with one-line comments only; this README is the documentation
- `pi/README.md` — this file
- `pi/agent/AGENTS.md` — universal behaviour and pre-routing triggers
- `pi/agent/README.md` — Pi-specific operating notes and validation boundaries
- `pi/agent/settings.json` — theme, default provider/model, package list
- `pi/agent/keybindings.json` — disables the stock thinking-level and model-cycle shortcuts in favor of Shift+Up/Down from `thinking-direction.ts` and Shift+Left/Right from `cycled-models.ts`
- `pi/agent/cycled-models.json` — the ordered models Shift+Left/Right step through, edited by `/cycled-models`
- `pi/agent/subagents.json` — hand-edited global subagent feature flags
- `pi/agent/agents/*` — subagent definitions
- `pi/agent/prompts/*` — prompt templates; each file becomes a `/`-command (`/permission-audit` briefs the session to analyze the permission log and propose rule changes)
- `pi/agent/skills/*` — hand-written skills; the two Omarchy-provided symlinks (`omarchy`, `diagnose-crash`) are ignored, Omarchy's skills.sh links them in
- `pi/agent/extensions/**` — including the hand-maintained permission-system and auto-review configs and the kept-dormant `pi-automode/config.json`
- `pi/agent/patches/**` — local patch library for re-patching pi's `node_modules`; each patch directory carries `target`, `marker`, `orig`, a pristine `.orig` copy and the `.patch` diff, and `reapply-all.sh` runs them all

See the tracked set with `git --git-dir="$HOME/.local/share/yadm/repo.git" ls-files -- .config/pi`, and confirm nothing runtime-generated shows as untracked with `yadm status`. Track a file by adding it to the whitelist (keeping it out of the knockouts), never by `git add -f`.

The gitignore has two layers: the `!` whitelist, and the regenerable knockouts at the end, which must stay below the whitelist because gitignore's last matching rule wins. The knockouts are written against shapes, not names — any `logs/` under any extension, not a specific package — so swapping an extension does not touch the file.

## What is not tracked

- `pi/pi.bin` — the compiled binary
- `pi/agent/auth.json` — provider credentials
- `pi/agent/trust.json` — trusted-directory markers
- `pi/agent/models-store.json` — provider model registry cache
- `pi/agent/sessions/` — per-project session transcripts
- `pi/agent/npm/` — the package checkout; `package.json` also lists two packages not wired into `settings.json`: `@latentminds/pi-quotas` and `pi-quota-monitoring`
- `pi/.pi/` — per-project subagent feature-flag overrides written by the `/agents` Settings menu; `agent/subagents.json` is the hand-edited global defaults file, which the menu never writes
- any `logs/` directory under `pi/agent/extensions/` — extension run logs

## Environment

`environment.d/20_pi.conf` sets `PI_AUTO_REVIEW_ALLOW_UNTRUSTED_DEV=1`, which lets the permission system and its auto-review authorizer treat this dotfiles tree as a dev project without deferring routine work. It is read from the process environment, not from pi config, hence it lives in environment.d rather than `agent/settings.json`.

## Further reading

- `agent/README.md` — Pi-specific operating notes
- `~/.config/docs/harness.md` — shared harness approach and Pi/Claude/Codex boundaries
- `~/.config/docs/environment-architecture.md` — shell/env relay and `environment.d` precedence
