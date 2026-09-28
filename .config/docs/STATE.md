# State

## Omarchy migration

Source checkout for the migration: `~/Projects/omarchy` (upstream, read-only; ported items land under `~/.config`). Ported 2026-09-26: `fish/completions/omarchy.fish` — a full port of Omarchy's `default/bash/completions` (prefix-tree walk over the omarchy-* executables plus the `# omarchy:args=` spec parser, `commands` and its flags included; the only hardcoded strings are those and the flag descriptions). Verified via `complete -C` against the live tree (27 cases, side-by-side with the upstream bash script; candidate words identical, the 3 diffs being fish's fuzzy matcher and bash's invisible readline file fallback): first/second/deeper levels, hyphen-split routes (`audio output volume`), literal/choice gating (`audio output-volume raise` vs a bogus token), `bar position` choices, flag skipping, explicit file completion only at dynamic `<name>` placeholder positions (file completions are otherwise disabled for the command, so `omarchy <TAB>` lists only subcommands). Descriptions beyond the bash port: level-1 groups from the dispatcher's GROUP_DESCRIPTIONS table, deeper levels from each first child's `# omarchy:summary=` line, `commands` and its flags from the dispatcher's usage text. Costs ~78 ms at the first level, ~30–60 ms deeper. Omarchy accepts both the hyphen-split (`omarchy bar text color`) and hyphenated (`omarchy bar text-color`) forms; completions suggest the split form, as upstream bash does. Known deviation, accepted: the bash line hiding `omarchy-*` binaries from first-word completion has no fish equivalent (`complete -c X -e` does not remove a PATH command from command-name completion; verified). Out of scope here: menu-keybinds and pi harness (other agents).

The dotfiles are ready for an Omarchy laptop (Arch, Hyprland under uwsm) per ADR-0044, 0045, 0048, 0049, 0050, 0051 and 0052, written against Omarchy 4.0.4; what remains happens on that laptop.

Setup and the standing oddities are in `docs/omarchy.md`.

- Ran on the laptop (2026-09-26): the `packages.toml##distro_family.arch` installs, `tool install`'s pacman branch (through its `##` fallback; backlog: mise upstream), `keyd/keyd.sh`, `yadm.sh` from the fresh clone, `omarchy/preinstalls.sh` and `omarchy.toml##distro.omarchy`, whose `tldr` now goes through a `pre-packages` hook.
  ADR-0047's editor sync verified on Omarchy (2026-09-27): `omarchy default editor` prints helix, `sudoedit` opens helix, the sync path unit is enabled and watching, and `env_reload` applies an `environment.d` edit without clearing uwsm's session values; after those reads, the menu pick is the only direction unexercised — pick nvim in the menu, check `tools.conf` flips to `EDITOR=nvim` and `SUDO_EDITOR` follows, then pick helix back.
  `omarchy/theme.sh` renders the tracked theme templates (see `docs/omarchy.md`); verify tmux startup and a later theme switch update the pane and status colors.
  Found live 2026-09-27 and fixed: the template's `MESSAGE_BG` mixed yellow toward the background, too dark for its black text (`#806125`); it now mixes toward the foreground (`#dcaa45` on gruvbox-classic), rendered via `omarchy-theme-refresh`. And the status tab separators drew U+25E2/3, which JetBrains Mono lacks — Mint's DejaVu fallback seated them, Omarchy's Noto Sans Symbols centers them in the em box, visibly shifted; they now use JBMNF's own powerline corner triangles (U+E0B8/E0BA). Both need a tmux reload to reach the live server.
  During a live switch in Foot inside tmux, watch whether Omarchy's window-style write followed by our hook causes a visible flash, especially on inactive panes.
  Compare the Foot palette and ANSI colors inside tmux with the outer terminal; check whether Omarchy's pane OSC write is needed in addition to `omarchy-theme-set-foot` before removing it.
  Check `tmux show-environment -g GUM_FILTER_MATCH_FOREGROUND` and `tmux show-environment -g COLORFGBG` after switching light and dark themes, then inspect the environment in a newly created pane; these values are separate from tmux's visual roles.
  Watch whether an app such as Neovim resets the cursor to the old Foot color, and whether the updater's `cursor-colour` fallback prevents it.
  After those observations, decide whether to keep Omarchy's tmux updater, shadow it with a local wrapper while restoring useful updates (not reached from the desktop, see `docs/omarchy.md`), or seek a narrower upstream opt-out.
  `omarchy/mime.sh` has run and `mimeapps.list` holds its defaults; still click a `mailto:` link with a subject and check Gmail's compose fills in, and open a text file from Nautilus.
  `omarchy/extensions/omarchy-menu.jsonc` hides Install and Remove › Preinstalls, confirmed against the live menu 2026-09-27.
  ADR-0069 applied 2026-09-29 (logind reports `HandleLidSwitchExternalPower=suspend-then-hibernate`); observe menu Suspend on battery hibernating after 5h, the lid on AC staying suspended, and an unplug during sleep starting the countdown.
- Bugfix step `yadm/bootstrap.d/omarchy/bugfix/keybindings-menu-submaps.sh` (new 2026-09-27, ADR-0057 pattern): Omarchy's keybindings menu listed submap bindings as global chords; the patch prefixes each with the chord that enters its mode (`SUPER + P > H`, entry guessed from the Lua bind cache or `hyprctl binds`) and sorts each mode's rows right behind its entry chord.
  Applied live and confirmed by an `omarchy menu keybindings --print` before/after diff (2026-09-27); the GUI menu is still unexercised.
  Filed upstream as [omacom/omarchy#13461](https://github.com/omacom/omarchy/pull/13461) 2026-09-27 (branch rebased onto `quattro`, its 18-case test file passing); the step's link replaces the TODO and the step dies when it merges.
  The bugfix steps share the apply dance in `bugfix/lib.sh`, sourced by each step: non-executable so bootstrap's step discovery skips it, and carrying `# shellcheck shell=bash` so CI's fragment scan checks it; the log fallback covers a standalone run without `~/bin`, which previously would have died on a stale warning.
  ADR-0055's bindings load with an empty `hyprctl configerrors`; `hyprctl binds` checked 2026-09-27: all 99 binds trace to `media.lua`, `clipboard.lua` or `bindings.lua`, no Omarchy defaults leaked.
  Added 2026-09-27: `SUPER + CTRL + RETURN` opens herdr (`{ omarchy = "terminal-herdr" }`, the target upstream's stock binding uses); layer-local launches, so keybinds.md stays out of it.
  Split the webapp installs out of `bootstrap.d/omarchy/00_preinstalls.sh` into `webapps.sh`, and moved the Disk Usage TUI entry plus new Tmux and Herdr entries into `tui-apps.sh`; the `00_` prefix pins the removal sweep ahead of every unprefixed step, and its remove-alls match on Exec so they would take the entries otherwise; the entries install through `omarchy-webapp-install` / `omarchy-tui-install` directly (no assets) — tmux and herdr attach via the same commands `omarchy-launch-terminal-{tmux,herdr}` wrap. The two entries attach and open, checked live.
  Check Super + P enters window mode and Escape leaves it, Super + I/O skip empty workspaces, the lid and power button still act, and PrtSc's region picker takes Return and the arrows.
- Bugfix step `yadm/bootstrap.d/omarchy/bugfix/keyboard-backlight-restore.sh` (new 2026-09-28, ADR-0057 pattern) applies the command patch from [Omarchy PR #10364](https://github.com/omacom/omarchy/pull/10364), revision `b206a62ee15a4faa180e1507e50b9fe400e36352`.
  The existing [issue #10767](https://github.com/omacom/omarchy/issues/10767) covers the observed screensaver bug: dismissing it restored a stale saved zero from an earlier lock and disabled the Dell backlight until its brightness key was pressed.
  Isolated verification reproduced that failure before the patch; the PR's 11 assertions and three additional screensaver cases passed after it, including repeated blanking and intentional off settings.
  Applied to the installed command on 2026-09-28; the patched file matched the tested copy and a second bootstrap-step run was silent.
  Observe the next normal screensaver dismissal and lock/unlock cycle; neither was forced during testing.
  The upstream PR remains open; delete the step once its fix ships.
- Verified on Mint so far: the same 53 tools resolve after the `conf.d` split; every `tool` command against a scratch config with stub `mise` and `pacman`.
  After the X11 startup-script update and a reboot, `env_reload` added and removed a temporary `environment.d` variable while preserving `EDITOR`, `PATH`, `DISPLAY` and `XAUTHORITY` in the user manager.

### Next, on the laptop (2026-09-26)

- tpm replaced by tpack 2026-09-27, per ADR-0061: tpm's text parser cannot see `@plugin` lines behind the `-F` wildcard include, so installs silently did nothing; tpack resolves the config the way tmux runs it. `tools.toml` carries the binary via mise's `github:` backend (the `go:` backend pins v1, which lacks the parser); decls live in `conf.d/90_plugins.conf`. `99_tpack.conf` self-bootstraps through `mise exec` -- a `/usr/bin` binary, so it works from a broken session PATH; it auto-installs tpack when missing, `tpack install` clones missing plugins (~250 ms when nothing is), and the `I`/`U`/`M-u` unbinds sit as plain lines after it (`run` blocks the parse, so they land after tpack's binds). tpack's TUI key is a throwaway chord its resolver always binds (empty falls back to `T`) that 99 unbinds; the TUI lives in the config table on `T`. Unexercised live: the first real server start doing the bootstrap, and the leftover `~/.local/share/tmux/plugins/tpm` directory that `tpack clean` (config table M-u) should remove.

Cloned and bootstrapped; foot now starts login shells, and the Goodix reader works through `omarchy/fingerprint.sh`.

- Checked after a reboot (2026-09-26): terminals run `fish --login` with `~/bin/overrides:~/bin` right behind the mise shims, fprintd runs at boot and sudo takes a fingerprint, the bootstrap is silent, the manager holds `EDITOR=omarchy-launch-editor --inline` and `SUDO_EDITOR=env helix`, and the Hyprland `PATH` patch and capture folders are in place.
- `yadm push`: `master` is 40-odd commits ahead of GitHub.
- Sizing: scale 1.25 with bar 12 and Foot 9pt, or scale 1 with bar 15 and Foot 11pt; pick one, then track `omarchy/shell.toml`.
- `fingerprint.sh` has not run on a fresh machine; Dell's driver crashed fprintd once at enroll stage 9 of 12, then enrolled cleanly on a retry.

Delete this file and its `CLAUDE.md` line once the laptop runs clean.

## pi session naming

Committed 2026-09-28 (`pi: name sessions from the first prompt`, ADR-0062): sessions are named from their first prompt by a tracked extension, `pi/agent/extensions/session-name.ts`, after every published namer turned out unusable on opencode-go (one built the missing header by hand but put its instruction where the provider drops it; the rest made header-less side calls that 400 and resolve empty).

- [TinySquid/pi-agent-extensions#19](https://github.com/TinySquid/pi-agent-extensions/pull/19), filed 2026-09-28, passes the session id its naming call was missing; branch `fix/auto-session-name-session-id` on our fork, whose checkout sits in `/tmp/pi-agent-extensions` until it merges. When it ships, point `settings.json` back at the package and delete the extension.
- No pi report: the residual gap is [earendil-works/pi#9290](https://github.com/earendil-works/pi/issues/9290) (closed no-action) and [#10053](https://github.com/earendil-works/pi/issues/10053) (closed not planned), and pi-ai 0.87.1 already derives `x-opencode-session` from `options.sessionId` ([#9326](https://github.com/earendil-works/pi/issues/9326), fixed and shipped).
- Naming runs on the pinned `opencode-go/gpt-6-luna`, falling back to the session model when scoped out.
- A first turn that ends in an unanswered `ask_user_question` defers the name to the next `agent_end` (observed; `agent_end` does not fire while a tool blocks on input).
