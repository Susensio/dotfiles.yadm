# pi agent configuration

pi agent config lives in `$XDG_CONFIG_HOME/pi/` (`~/.config/pi`).

## What is tracked

Only the hand-maintained harness is tracked here by yadm; runtime state
is ignored. `pi/.gitignore` whitelists exactly the tracked paths and
documents every ignored directory — including the two gitignore layers
(this outer whitelist plus `pi/.gitignore`'s regenerable rules inside
whitelisted trees) and which of its entries are over-defensive
(`agent/model-fallback/config.json`, kept so a future fallback config
lands tracked by default).

Tracked today: `pi/.gitignore`, `pi/agent/AGENTS.md`,
`pi/agent/README.md` (harness overview, model tiers, delegation policy),
`pi/agent/settings.json`, `pi/agent/subagents.json`, `pi/agent/agents/*`,
`pi/agent/skills/*` (except the two Omarchy-provided symlinks, which
omarchy's skills.sh links in), and `pi/agent/extensions/**` — including
the hand-maintained permission-system and auto-review configs and the
kept-dormant `pi/agent/extensions/pi-automode/config.json`; only the
permission-system's JSONL decision logs are ignored as runtime churn.

## What is not tracked

`pi/pi.bin` (the compiled binary), `pi/agent/auth.json` (provider
credentials), `pi/agent/trust.json`, `pi/agent/models-store.json`
(provider model registry cache), `pi/agent/sessions/` (per-project
transcripts), `pi/agent/npm/` (the package checkout; its
`package.json` lists two packages not wired into
`pi/agent/settings.json`: `@latentminds/pi-quotas` and
`pi-quota-monitoring`), `pi/agent/patches/` (local patch library for
re-patching pi's `node_modules` after updates), and `pi/.pi/`
(pi-regenerated runtime copy of the subagent feature flags —
`pi/agent/subagents.json` is the hand-edited authoritative copy).

## Environment

`environment.d/20_pi.conf` (sibling of this directory's parent —
`~/.config/environment.d/`) sets `PI_AUTO_REVIEW_ALLOW_UNTRUSTED_DEV=1`,
which lets the permission system and its auto-review authorizer treat
this dotfiles tree as a dev project without deferring routine work. It
is read from the process environment, not from pi config, hence it lives
in environment.d rather than `pi/agent/settings.json`.

## Further reading

- `pi/agent/README.md` — harness design, model tiers, extension list.
- `~/.config/docs/harness.md` — how the two agent harnesses (pi and
  claude) fit together.
- `~/.config/docs/environment-architecture.md` — shell/env relay and
  `environment.d` precedence.
