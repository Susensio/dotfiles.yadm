# State

## Omarchy gruvbox and Helix upstream handoff (2026-09-30)

Goal: submit a faithful classic-gruvbox theme, improve the generic Helix fallback, and use Helix's bundled vendor themes where there is a defensible match.
These are separate contributions; the naming of stock `gruvbox` (currently gruvbox-material) is a related, potentially breaking decision, not an approved rename.
Do not treat scratch `gruvbox-vivid` or a swap of the classic palette tiers as accepted.

### Completed upstream work

- Commented on [Helix template PR #6696](https://github.com/omacom/omarchy/pull/6696#issuecomment-5905412528): supported its semantic palette and contrast-safe transparent/inverted UI, asked whether removing `color0`–`color8` aliases should retain compatibility for custom themes inheriting `omarchy` or be called out as a migration, and noted that generic `bright_*` syntax defaults vary in contrast and meaning across themes.
  PR #6696 was open at the time of the comment; check its current status and responses before proposing template edits.
- Opened [Omarchy PR #13843](https://github.com/omacom/omarchy/pull/13843) (`Susensio:fix/helix-theme-link`, commit `1cc49b20`) for the Helix provisioning bug.
  It adds a one-time migration for already-installed Helix and provisions the link on future theme switches for Helix installed outside Omarchy's installer; both paths only create a missing `~/.config/helix/themes/omarchy.toml` if the rendered target exists, preserving existing files and even dangling custom symlinks.
  No dotfiles patch is required: it does not change the selected Helix theme or overwrite user config.
  Focused regression (7 checks), staging suite, `bash -n`, and `git diff --check` pass in an isolated upstream checkout at `/tmp/helix-provision-pr.nHsC8l`.
  `./test/all` was attempted there but failed in 15 unrelated shell suites and `test/cli` (missing companion `omarchy-pkgs` checkout and `omasnap`, other baseline/environment failures); the Helix regression passed in that full run.
  Follow the PR to merge and test on update; if the rendered target is absent during its one-time migration, the next theme change will provision it.
  Do not apply the migration to the live machine just to exercise it.

### Current local experiment (not the intended upstream implementation)

- `omarchy/themes/gruvbox-classic/colors.toml` maps morhetz gruvbox's neutral hues to plain `red`…`cyan` and its actual bright hues to `bright_*`; background `#282828`, darker surfaces `#1d2021`/`#161616`, foreground `#ebdbb2`, accent `#fe8019`.
  **Do not swap tiers without a new decision**: that would change terminal ANSI 1–6 and throw away the faithful 0/1 gruvbox mapping.
  Omarchy's resolver forces `color7 = foreground`, so fully canonical ANSI white is not representable here; this is an accepted constraint to describe when proposing the theme, not a reason to reverse hue tiers.
  Decide explicitly whether the non-ANSI `orange` role should remain neutral `#d65d0e` or become vivid `#fe8019` for generated clients; avoid silently changing it.
- `omarchy/themes/gruvbox-vivid/` and `helix/themes/omarchy-gruvbox-{classic,vivid}.toml` are **scratch** comparisons, not PR material.
  The two Helix previews use Omarchy's **stock** rules, which read plain slots and therefore favor vivid; they do not show the installed local override's rendering.
  Vivid omits `bright_*`, which the resolver fills with 20%-white mixes, and does not preserve classic terminal ANSI.
  Retain the scratch files until the comparison is finished; clean them up by explicit decision, not as part of the provisioning PR.
- `omarchy/themed/helix.toml.tpl` is a local, untracked override with vivid syntax roles (`red_bright`, `green_bright`, etc.) and transparent `ui.background`.
  It was rendered and parsed without unresolved placeholders or Helix warnings, but it can wash out other themes whose bright roles are lighter tints and should **not** be submitted wholesale as a generic fallback.
  `helix/config.toml` still selects `gruvbox_transparent` (a small overlay inheriting Helix's `gruvbox`); Herdr selects vendor `gruvbox`.
  The observed vendor theme preference and transparent Helix background should be preserved in later comparisons.

### Remaining contributions and decisions

1. **Classic gruvbox theme PR:** audit all current `gruvbox-classic` assets and compare the palette against morhetz gruvbox, terminal/Omarchy rendering, and vendor Helix before touching tiers; retain neutral→plain and bright→`bright_*` unless a specific counterexample justifies a change.
   The local theme presently has `backgrounds/`, `colors.toml`, `icons.theme`, and `neovim.lua`; a representative stock theme also ships `hyprland.lua`, `vscode.json`, `preview.png`, `preview-unlock.png`, and `unlock.png`.
   Verify which assets Omarchy actually requires before creating them, produce legitimate previews/background permissions, run upstream `./test/all` in a proper checkout, and provide before/after images for visual changes.
   Current stock `gruvbox` uses gruvbox-material colors but classic `ellisonleao/gruvbox.nvim`, so check Neovim integration for both themes.
   Posted [Suggestions Discussion #13864](https://github.com/omacom/omarchy/discussions/13864) (2026-09-30): option 1 adds `gruvbox-classic` beside unchanged `gruvbox`; option 2 renames stock to `gruvbox-material` with a `theme.name` migration and gives classic the short name (our lean).
   The editor-config mismatch (material palette, classic `neovim.lua`/`vscode.json`) was kept out of the discussion on purpose, as an implementation detail for the PR.
   Wait for a maintainer answer before implementing; do not bundle the rename without one.
2. **Better generic Helix fallback:** first follow [#6696](https://github.com/omacom/omarchy/pull/6696) and the review comment, and compare its result against the stock template and the local override across dark and light stock themes.
   The stock template largely uses only plain hues and collapses some syntax distinctions; #6696 names the palette semantically, adds bare `markup.heading`, moves constants to orange, and refines parameters/special roles.
   Do not open a competing change to the same file while that PR is live.
   Establish concrete remaining regressions with contrast and screenshots before a follow-up PR; bright roles are **not** universally safe as generic drawing roles (especially on light themes), and transparency plus legible statusline/menu must survive.
   The local override should eventually be revised or removed by explicit choice after testing the merged fallback; no local config rewrite was approved in this session.
3. **Vendor-Helix `inherits` mapping:** the existing theme-staging/rendering path already honors a theme-shipped `helix.toml` ahead of `default/themed/helix.toml.tpl`.
   Propose a **Suggestions Discussion**, then a small PR with verified vendor-name overlays rather than copied full theme implementations; [closed PR #945](https://github.com/omacom/omarchy/pull/945) was rejected for maintaining full per-editor schemes, so explain how vendor inheritance reduces that burden, without assuming a maintainer will accept it.
   Candidate pairs to verify against the actual stock colors/backgrounds and installed Helix runtime: `gruvbox` (material)→`gruvbox-material`, `gruvbox-classic`→`gruvbox`, `catppuccin`→`catppuccin_mocha`, `catppuccin-latte`→`catppuccin_latte`, `everforest`→`everforest_dark`, `flexoki-light`→`flexoki_light`, `kanagawa`→`kanagawa`, `nord`→`nord`, `rose-pine`→`rose_pine_dawn`, `tokyo-night`→`tokyonight`; `ristretto`→`monokai_pro_ristretto` needs closer visual checking.
   Exclude generic lookalikes such as `white`→`emacs` or `vantablack`→`modus_vivendi` without a real brand match.
   Each overlay must include `"ui.background" = { }` beside `inherits = "…"`; shipping it suppresses fallback-template generation, and a bare inherit would lose Omarchy's transparency.
   Confirm Helix syntax and palette compatibility for each pair, test switching and cloning/staging, and re-evaluate if classic/stock gruvbox names change.

Upstream procedure: work in an Omarchy fork checkout, follow upstream `AGENTS.md` and `agents/skills/{migrations,install-scripts}.md` as applicable, run focused tests and `./test/all`, and keep upstream source edits out of `/usr/share/omarchy` and this dotfiles tree.
The local contribution guide still says `basecamp/omarchy`, while the live GitHub repository used for these PRs is `omacom/omarchy`; verify the live destination before filing.

## Omarchy migration

Source checkout for the migration: `~/Projects/omarchy` (upstream, read-only; ported items land under `~/.config`). Ported 2026-09-26: `fish/completions/omarchy.fish` — a full port of Omarchy's `default/bash/completions` (prefix-tree walk over the omarchy-* executables plus the `# omarchy:args=` spec parser, `commands` and its flags included; the only hardcoded strings are those and the flag descriptions). Verified via `complete -C` against the live tree (27 cases, side-by-side with the upstream bash script; candidate words identical, the 3 diffs being fish's fuzzy matcher and bash's invisible readline file fallback): first/second/deeper levels, hyphen-split routes (`audio output volume`), literal/choice gating (`audio output-volume raise` vs a bogus token), `bar position` choices, flag skipping, explicit file completion only at dynamic `<name>` placeholder positions (file completions are otherwise disabled for the command, so `omarchy <TAB>` lists only subcommands). Descriptions beyond the bash port: level-1 groups from the dispatcher's GROUP_DESCRIPTIONS table, deeper levels from each first child's `# omarchy:summary=` line, `commands` and its flags from the dispatcher's usage text. Costs ~78 ms at the first level, ~30–60 ms deeper. Omarchy accepts both the hyphen-split (`omarchy bar text color`) and hyphenated (`omarchy bar text-color`) forms; completions suggest the split form, as upstream bash does. Known deviation, accepted: the bash line hiding `omarchy-*` binaries from first-word completion has no fish equivalent (`complete -c X -e` does not remove a PATH command from command-name completion; verified). Out of scope here: menu-keybinds and pi harness (other agents).

The dotfiles are ready for an Omarchy laptop (Arch, Hyprland under uwsm) per ADR-0044, 0045, 0048, 0049, 0050, 0051 and 0052, written against Omarchy 4.0.4; what remains happens on that laptop.

Setup and the standing oddities are in `docs/omarchy.md`.

- Ran on the laptop (2026-09-26): the `packages.toml##distro_family.arch` installs, `tool install`'s pacman branch (through its `##` fallback; backlog: mise upstream), `keyd/keyd.sh`, `yadm.sh` from the fresh clone, `omarchy/preinstalls.sh` and `omarchy.toml##distro.omarchy`, whose `tldr` now goes through a `pre-packages` hook.
  ADR-0047's editor sync verified on Omarchy (2026-09-27): `omarchy default editor` prints helix, `sudoedit` opens helix, the sync path unit is enabled and watching, and `env_reload` applies an `environment.d` edit without clearing uwsm's session values; the menu pick confirmed 2026-09-29.
  `omarchy/theme.sh` renders the tracked theme templates (see `docs/omarchy.md`); verify tmux startup and a later theme switch update the pane and status colors.
  Found live 2026-09-27 and fixed: the template's `MESSAGE_BG` mixed yellow toward the background, too dark for its black text (`#806125`); it now mixes toward the foreground (`#dcaa45` on gruvbox-classic), rendered via `omarchy-theme-refresh`. And the status tab separators drew U+25E2/3, which JetBrains Mono lacks — Mint's DejaVu fallback seated them, Omarchy's Noto Sans Symbols centers them in the em box, visibly shifted; they now use JBMNF's own powerline corner triangles (U+E0B8/E0BA). Both need a tmux reload to reach the live server.
  Applied 2026-09-29 ([ADR-0075](adr/0075-omit-omarchy-tmux-updater.md)): `omarchy-theme-set-tmux` is a no-op override in `~/bin/overrides`, and `theme-set.d/tmux` owns live retint — a config reload on every configured server, plus the theme's Gum values and `COLORFGBG` for panes started later; `CURSOR` is a palette role now, so the cursor fallback no longer waits for a switch; the template reaches the rendered palette on the next `yadm bootstrap`, whose `theme.sh` re-renders a newer template.
  Observe the next live switch in Foot inside tmux: pane and status colours, no intermediate flash on inactive panes, the cursor colour after an app sends OSC 112, and `tmux show-environment -g COLORFGBG` plus a new pane's environment.
  If a pane's ANSI palette or a redraw turns out to matter, the dropped pane-TTY OSC writes and `SIGWINCH`/`refresh-client` are the first candidates to restore into the hook.
  `omarchy/mime.sh` has run and `mimeapps.list` holds its defaults; a text file opens in helix inside Foot and a `mailto:` link fills Gmail's compose (both via `gio open`, 2026-09-29).
  `omarchy/extensions/omarchy-menu.jsonc` hides Install and Remove › Preinstalls, confirmed against the live menu 2026-09-27.
  ADR-0069 applied 2026-09-29 (logind reports `HandleLidSwitchExternalPower=suspend-then-hibernate`); observe menu Suspend on battery hibernating after 5h, the lid on AC staying suspended, and an unplug during sleep starting the countdown.
- Bugfix step `yadm/bootstrap.d/omarchy/bugfix/keybindings-menu-submaps.sh` (new 2026-09-27, ADR-0057 pattern): Omarchy's keybindings menu listed submap bindings as global chords; the patch prefixes each with the chord that enters its mode (`SUPER + P > H`, entry guessed from the Lua bind cache or `hyprctl binds`) and sorts each mode's rows right behind its entry chord.
  Applied live and confirmed by an `omarchy menu keybindings --print` before/after diff (2026-09-27); the GUI menu is still unexercised.
  Filed upstream as [omacom/omarchy#13461](https://github.com/omacom/omarchy/pull/13461) 2026-09-27 (branch rebased onto `quattro`, its 18-case test file passing); the step's link replaces the TODO and the step dies when it merges.
  The bugfix steps share the apply dance in `bugfix/lib.sh`, sourced by each step: non-executable so bootstrap's step discovery skips it, and carrying `# shellcheck shell=bash` so CI's fragment scan checks it; the log fallback covers a standalone run without `~/bin`, which previously would have died on a stale warning.
  ADR-0055's bindings load with an empty `hyprctl configerrors`; `hyprctl binds` checked 2026-09-27: all 99 binds trace to `media.lua`, `clipboard.lua` or `bindings.lua`, no Omarchy defaults leaked.
  Added 2026-09-27: `SUPER + CTRL + RETURN` opens herdr (`{ omarchy = "terminal-herdr" }`, the target upstream's stock binding uses); layer-local launches, so keybinds.md stays out of it.
  Split the webapp installs out of `bootstrap.d/omarchy/00_preinstalls.sh` into `webapps.sh`, and moved the Disk Usage TUI entry plus new Tmux and Herdr entries into `tui-apps.sh`; the `00_` prefix pins the removal sweep ahead of every unprefixed step, and its remove-alls match on Exec so they would take the entries otherwise; the entries install through `omarchy-webapp-install` / `omarchy-tui-install` directly (no assets) — tmux and herdr attach via the same commands `omarchy-launch-terminal-{tmux,herdr}` wrap. The two entries attach and open, checked live.
  Super + P window mode and Super + I/O skipping empty workspaces confirmed 2026-09-29, as are the lid's suspend-then-hibernate, the power button's system menu, and PrtSc's region picker taking Return and the arrows.
- Bugfix step `yadm/bootstrap.d/omarchy/bugfix/keyboard-backlight-restore.sh` (new 2026-09-28, ADR-0057 pattern) applies the command patch from [Omarchy PR #10364](https://github.com/omacom/omarchy/pull/10364), revision `b206a62ee15a4faa180e1507e50b9fe400e36352`.
  The existing [issue #10767](https://github.com/omacom/omarchy/issues/10767) covers the observed screensaver bug: dismissing it restored a stale saved zero from an earlier lock and disabled the Dell backlight until its brightness key was pressed.
  Isolated verification reproduced that failure before the patch; the PR's 11 assertions and three additional screensaver cases passed after it, including repeated blanking and intentional off settings.
  Applied to the installed command on 2026-09-28; the patched file matched the tested copy and a second bootstrap-step run was silent.
  Observe the next normal screensaver dismissal and lock/unlock cycle; neither was forced during testing.
  The upstream PR remains open; delete the step once its fix ships.
- Bugfix step `yadm/bootstrap.d/omarchy/bugfix/keyboard-backlight-hibernate.sh` (new 2026-09-29, ADR-0057 pattern): a suspend-then-hibernate on 2026-09-29 woke with the backlight off, because Omarchy's pre-hibernate sleep hook sets it to 0 with no `post` restore; the patch routes the hook through `omarchy-brightness-keyboard off`/`restore` around hibernation only, so it works with or without PR #10364.
  Hook branches checked with a stubbed command for every sleep action; real runs on `dell::kbd_backlight` restored the level both alone and nested inside a session blank (root and session snapshots stay separate).
  Installed live 2026-09-29 via pkexec; observe the next suspend-then-hibernate resume.
  Filed upstream as [omacom/omarchy#13729](https://github.com/omacom/omarchy/pull/13729) 2026-09-29 (branch `sleep-hook-restore-keyboard-backlight`, worktree `~/Projects/omarchy-kbd-hibernate`, with a migration and tests), linked from #10364; delete the step once it ships.
- Bugfix step `yadm/bootstrap.d/omarchy/bugfix/nightlight-schedule-refresh.sh` (new 2026-09-28, ADR-0057 pattern): the bar's night light service probed hyprsunset only at start and after an Omarchy toggle, so the 07:00/20:00 schedule switches left the indicator stale ([issue #8286](https://github.com/omacom/omarchy/issues/8286)); the patch re-probes a second past every wall-clock minute, when hyprsunset lands its switches.
  Applied live 2026-09-28: a raw `hyprctl hyprsunset temperature` change reached `omarchy-shell nightlight status` at the next minute boundary, both directions; the step is silent on rerun.
  Filed upstream as [omacom/omarchy#13684](https://github.com/omacom/omarchy/pull/13684) 2026-09-28 (branch `nightlight-follow-schedule`, worktree `~/Projects/omarchy-nightlight`); delete the step once it ships.
  `nightlight-probe-guard.patch` (2026-09-29, from the PR review) drops a probe result that lands while a toggle is still applying, so an in-flight probe can't flip the bar back; applied live 2026-09-29.
  Observe the next scheduled 07:00 and 20:00 switches, including one crossed while suspended.
  The polling is a stopgap: if [hyprwm/hyprsunset#95](https://github.com/hyprwm/hyprsunset/pull/95) (per-profile `on-switch`) ships, `on-switch = omarchy-shell -q nightlight refresh` in `hypr/hyprsunset.conf` replaces it.
- Bugfix step `yadm/bootstrap.d/omarchy/bugfix/pi-theme-agent-dir.sh` (new 2026-09-29, ADR-0057 pattern) applies [Omarchy PR #13693](https://github.com/omacom/omarchy/pull/13693): `omarchy-theme-set-pi` hardcoded `~/.pi/agent` while its `-claude` and `-hermes` siblings read their agent's variable, so a pi rehomed by `PI_CODING_AGENT_DIR` never received the Omarchy palette ([issue #13691](https://github.com/omacom/omarchy/issues/13691)); our own [PR #13694](https://github.com/omacom/omarchy/pull/13694) was closed for it as the duplicate.
  Applied live 2026-09-29 by `yadm bootstrap`; the step also syncs the theme into the agent dir once, because the patch changes the command and not the copy written before pi moved to XDG. `~/.pi` was removed after the patch landed — only the next `omarchy update` migration and `omarchy-provision-user` recreate it, and `skills.sh` strips those links again.
  Delete the step once #13693 ships.
- Verified on Mint so far: the same 53 tools resolve after the `conf.d` split; every `tool` command against a scratch config with stub `mise` and `pacman`.
  After the X11 startup-script update and a reboot, `env_reload` added and removed a temporary `environment.d` variable while preserving `EDITOR`, `PATH`, `DISPLAY` and `XAUTHORITY` in the user manager.

### Next, on the laptop (2026-09-26)

- tpm replaced by tpack 2026-09-27, per ADR-0061: tpm's text parser cannot see `@plugin` lines behind the `-F` wildcard include, so installs silently did nothing; tpack resolves the config the way tmux runs it. `tools.toml` carries the binary via mise's `github:` backend (the `go:` backend pins v1, which lacks the parser); decls live in `conf.d/90_plugins.conf`. `99_tpack.conf` self-bootstraps through `mise exec` -- a `/usr/bin` binary, so it works from a broken session PATH; it auto-installs tpack when missing, `tpack install` clones missing plugins (~250 ms when nothing is), and the `I`/`U`/`M-u` unbinds sit as plain lines after it (`run` blocks the parse, so they land after tpack's binds). tpack's TUI key is a throwaway chord its resolver always binds (empty falls back to `T`) that 99 unbinds; the TUI lives in the config table on `T`. The first real server start ran the bootstrap (2026-09-29, `tmux-uzi` cloned); `tpack clean` left the old `plugins/tpm` clone behind, so it was deleted by hand.

Cloned and bootstrapped; foot now starts login shells, and the Goodix reader works through `omarchy/fingerprint.sh`.

- Checked after a reboot (2026-09-26): terminals run `fish --login` with `~/bin/overrides:~/bin` right behind the mise shims, fprintd runs at boot and sudo takes a fingerprint, the bootstrap is silent, the manager holds `EDITOR=omarchy-launch-editor --inline` and `SUDO_EDITOR=env helix`, and the Hyprland `PATH` patch and capture folders are in place.
- `yadm push`: `master` stood 152 commits ahead of GitHub on 2026-09-29.
- `fingerprint.sh` has not run on a fresh machine; Dell's driver crashed fprintd once at enroll stage 9 of 12, then enrolled cleanly on a retry.

Delete this file and its `CLAUDE.md` line once the laptop runs clean.

## pi session naming

Committed 2026-09-28 (`pi: name sessions from the first prompt`, ADR-0062): sessions are named from their first prompt by a tracked extension, `pi/agent/extensions/session-name.ts`, after every published namer turned out unusable on opencode-go (one built the missing header by hand but put its instruction where the provider drops it; the rest made header-less side calls that 400 and resolve empty).

- [TinySquid/pi-agent-extensions#19](https://github.com/TinySquid/pi-agent-extensions/pull/19), filed 2026-09-28, passes the session id its naming call was missing; branch `fix/auto-session-name-session-id` on our fork, whose checkout sits in `/tmp/pi-agent-extensions` until it merges. When it ships, point `settings.json` back at the package and delete the extension.
- No pi report: the residual gap is [earendil-works/pi#9290](https://github.com/earendil-works/pi/issues/9290) (closed no-action) and [#10053](https://github.com/earendil-works/pi/issues/10053) (closed not planned), and pi-ai 0.87.1 already derives `x-opencode-session` from `options.sessionId` ([#9326](https://github.com/earendil-works/pi/issues/9326), fixed and shipped).
- Naming runs on the pinned `opencode-go/gpt-6-luna`, falling back to the session model when scoped out.
- A first turn that ends in an unanswered `ask_user_question` defers the name to the next `agent_end` (observed; `agent_end` does not fire while a tool blocks on input).

## pi permission reviewer

Committed 2026-09-29 (`pi: fall back from codex in the permission reviewer`, and the alias map's tier commit): the permission system's auto-reviewer calls `alias/reviewer` from `pi-model-fallback-alias`, so an exhausted Codex quota fails over instead of turning every ask into a prompt.

- Chain: `openai-codex/codex-auto-review` → `opencode-go/deepseek-v4.1-flash` → `opencode-go/glm-5.3-flash` → `claude-bridge/claude-haiku-4-5`, with a 15s first-event budget: a stalled reviewer holds up a permission prompt, where a session turn can afford the 30s default. Only provider failures advance the chain — a reviewer `defer` verdict still reaches the human.
- `models.json` registers `openai-codex/codex-auto-review`, which the authorizer otherwise synthesizes outside the registry where the alias cannot reach it.
- The haiku target is inert: `pi-claude-bridge` refuses system prompts it has not captured from a real session, and the reviewer sends the Guardian policy. Harmless, and it starts working if the bridge relaxes that.
- The `pi-auto-review-session-id` patch was deleted when [mzwing/pi-packages#22](https://github.com/mzwing/pi-packages/pull/22) shipped in 0.5.2. `pi-model-alias-shared-registry` stays until [unrelentingfox/pi-model-fallback-alias#30](https://github.com/unrelentingfox/pi-model-fallback-alias/pull/30) ships: pi loads a copy of the extension per subagent session, and the last copy re-registers the process-wide `alias` provider while holding no registry, which failed every alias call in the process.
- Tiers `alias/top` (`claude-opus-5-5` → `gpt-6-sol` → `mimo-v2.6-pro`), `alias/mid` and `alias/fast` live in the same file; `alias/top` is verified end to end, and nothing points at them yet (see BACKLOG).
- Sessions started before 2026-09-29 need `/reload` to pick up auto-review 0.5.2 and the patched alias.
- Untested: whether `deepseek-v4.1-flash` and `glm-5.3-flash` judge risky asks as well as `codex-auto-review` does; only safe commands were exercised.
