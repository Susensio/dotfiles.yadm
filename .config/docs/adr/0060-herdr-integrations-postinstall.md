# ADR-0060: Install herdr integrations from per-tool postinstall hooks scoped by the fired tool's name, instead of a hardcoded harness list or a global sync on every tool

Status: Accepted
Date: 2026-09-27

## Context

herdr ships an agent-state integration per harness — a pi extension, a claude hook, a codex hook — that reports the pane's working/blocked/idle state to herdr over its socket. The integrations had drifted (pi at v8, claude at v9 while herdr 0.9.1 carried newer ones) because installation was manual and machine-specific, and herdr's `integration status` was never checked.

Two findings made the install worth automating and shaped how. First, the `@juicesharp/rpiv-ask-user-question` package leaves the pane in the working state while its questionnaire waits for input: herdr's pi integration listens for a `herdr:blocked` event nothing emits, while the package emits its own stable `rpiv:ask-user:blocked` channel — a hand-written bridge extension forwards one to the other as a stopgap. Second, probing herdr's installers on a clean environment showed fresh-machine pitfalls: they read only the per-agent roots defined in `environment.d/10_xdg.conf` (`PI_CODING_AGENT_DIR`, `CLAUDE_CONFIG_DIR`) and fall back to untracked defaults (`~/.pi`, `~/.claude`) when unset; systemd applies environment.d only at login, which a bootstrap can precede; herdr's pi installer creates no directories and otherwise installs into `~/.pi`, which this layout does not use; and herdr's claude uninstaller rewrites herdr's own hook entry in the tracked `settings.json`, normalizing its matcher, so an uninstall+install cycle churns the file.

Alternatives weighed: running `herdr integration install <harness>` by hand after tool changes; one unconditional install line in ADR-0007's batch `system-install` postinstall; hardcoding the harness list in the task; waiting for herdr to manage its own integrations.

## Decision

Every integrated harness's tool entry and herdr's own entry declare the same tool-level postinstall: `mise run herdr-integrations`. The shared task (`mise/tasks/herdr-integrations`, quiet per ADR-0056) derives its scope from `MISE_TOOL_NAME`, which mise sets in the tool postinstall context: a harness's hook installs only that harness's integration, while herdr's own hook — whose content change is what integration versions derive from — and manual runs sync every harness present, judged from `herdr integration status` target paths. Agent roots are sourced live from the checked-out `environment.d/10_xdg.conf`, the single source, instead of duplicating defaults; the same yadm checkout owns both the variables and the harness configs, so a bare machine without them has nothing to integrate.

The task is install-only (never uninstalls, because of the claude churn above), skips integrations that are already current, gates each harness on its target directory existing, and treats herdr's own refusals (absent harness, the pi/omp shared-directory collision) as the final authority rather than duplicating that knowledge.

## Consequences

A fresh bootstrap self-integrates every harness the checkout carries, in any tool-install order. Adding a harness means one `tools.toml` line — the postinstall — and nothing else; removing one is an uninstall away. No environment defaults are duplicated, and the task cannot outdate its own variable knowledge.

Machine-local harnesses installed after herdr through plain `mise use -g` (ADR-0045) carry no hook and wait for herdr's next install or a manual run. Presence is the opt-in: a harness whose config directory exists is integrated, with no per-harness opt-out. Integration version bumps rewrite the tracked managed files and surface as ordinary yadm diffs to commit as herdr bumps. A distro-packaged herdr older than mise's must not win binary resolution, so the task prefers the hook's install path. The bridge extension for ask_user_question's blocked event stays until herdr consumes `rpiv:ask-user:blocked` natively, at which point it is deleted.

## Corrections

2026-10-07: the hooks run `mise run --skip-tools herdr-integrations`, not `mise run herdr-integrations`.
Without the flag `mise run` installs every missing tool before the task, so on a fresh machine each hook started a nested install racing the outer one, three levels deep once those tools' hooks fired; the bootstrap CI saw the claude and pi hooks fail with another tool's error, and whole runs hung.
The task also takes an exclusive `flock` for its run: under parallel installs a harness's hook and herdr's full sync fire together and both write that harness's config.
