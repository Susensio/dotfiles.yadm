# State

## ai-usagebar chip icon gap

[#313](https://github.com/akitaonrails/ai-usagebar/pull/313) drops the 6 px spacer 1.30.0 put between a bar chip's icon and its value (the gap was 14 px, wider than between chips) and is open.
The clone `~/.config/omarchy/plugins/akitaonrails.ai-usagebar` sits on `fix/omarchy-chip-icon-gap`, one commit ahead of upstream `main`, so the bar keeps the fix until it merges; then fast-forward `main`, delete the branch locally and on the fork, and drop this section.

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

Setup and the standing oddities are in `docs/omarchy.md`; `~/Projects/omarchy` is the upstream checkout.

- Observe the next live theme switch in Foot inside tmux (ADR-0075): pane and status colours, no intermediate flash on inactive panes, the cursor colour after an app sends OSC 112, and `tmux show-environment -g COLORFGBG` plus a new pane's environment.
  If a pane's ANSI palette or a redraw turns out to matter, the dropped pane-TTY OSC writes and `SIGWINCH`/`refresh-client` are the first candidates to restore into the hook.
- ADR-0069: observe menu Suspend on battery hibernating after 5h, the lid on AC staying suspended, and an unplug during sleep starting the countdown.
- `fingerprint.sh` has not run on a fresh machine; Dell's driver crashed fprintd once at enroll stage 9 of 12, then enrolled cleanly on a retry.
- `yadm push`: `master` stood 222 commits ahead of GitHub on 2026-09-30.
- ADR-0076 applied 2026-09-29: window mode replaced by chords (Super + Ctrl + hjkl resize, repeatable; Super + Shift + hjkl swap; Super + Alt + hjkl window to monitor), the power key climbing modifiers (suspend-then-hibernate, Ctrl lock, Super system menu, Alt screensaver, all `locked`), the Print family (plain screenshot, Super capture menu, Shift OCR, Ctrl QR, Alt color picker), notification history on Super + Ctrl + comma and silencing on Super + Alt + comma, and the Super + Ctrl panel family (W network, B bluetooth, A audio, D display, P power; the clipboard manager keeps Super + Ctrl + V).
  `hyprctl reload` clean, `hyprctl configerrors` empty, binds with mods spot-checked (SHIFT 65, CTRL 68), `omarchy menu keybindings --print` lists the chords; `omarchy-restart-shell` picked up the bar without the poctek submap widget.
  Same-day additions: Super + Alt + the panel letter flips the thing (W wifi radio via nmcli, B bluetooth rfkill via omarchy-bluetooth-power, P power-profile cycle via the local `omarchy-powerprofiles-cycle` — wraps performance → power-saver → balanced and notifies with the profile's icon; the one-liner first bound inline was reversed per request and moved into `~/bin`; P first sat on Super + Alt + power and moved), dictation on Insert push-to-talk with Shift + Insert latching hands-free and bare Insert ending the latch (moved off F9, whose bare press emits no event; observe live: hold, latch, and latch-then-Insert), and zen mode as Super + Z maximize itself (a `f[1]` workspace rule widens the side gaps to 160, about 4:3 here; replaces the square-aspect toggle).
  The initial local square-aspect binding mistakenly used `o.bind_toggle`, which prefixes `omarchy-toggle-` onto its third argument; Omarchy correctly uses plain `o.bind` for this command, and the binding that replaced it is a Lua function of our own. `omarchy-powerprofiles-cycle` ran a full verified cycle (performance → power-saver → balanced → performance) and restored balanced afterwards.
  Observe live: the chords (especially Super + Alt + hjkl's `window.move({ monitor })`, wiki-verified but unexercised here), Shift + Power's suspend (untestable without sleeping; the command matches the lid and the menu's overridden Suspend), Ctrl + Print's QR decode, zen mode (2026-10-02: on throwaway windows the maximized window measured 1212x910 under the bar and the hidden tiles kept their pixels through a zen/un-zen; kept by the user 2026-10-03), and the wifi/bluetooth toggles' state reaching the bar panels.
  Not adopted, still menu-reachable: calculator, keybindings menus, dictation, bar-panel digits, reminders, transparency/gaps toggles, cursor zoom, width save/restore, monitor scaling.

### Bugfix steps waiting on upstream

Each is an ADR-0057 step under `yadm/bootstrap.d/omarchy/bugfix/`; delete it once its PR ships.

- `uwsm-mise-shims.sh`: [#13364](https://github.com/omacom/omarchy/pull/13364) drops `10-omarchy`'s `mise activate bash --shims`, which put the shims ahead of `environment.d`'s `PATH`.
- `hypr-envs-path.sh`: [#13351](https://github.com/omacom/omarchy/pull/13351) drops the `PATH` prepend from `default/hypr/envs.lua`.
- `keybindings-menu-submaps.sh`: [#13461](https://github.com/omacom/omarchy/pull/13461) prefixes submap bindings in the keybindings menu with the chord that enters their mode.
  ADR-0076 removed every submap, so the step is a no-op locally.
- `keyboard-backlight-restore.sh`: applies [#10364](https://github.com/omacom/omarchy/pull/10364) (revision `b206a62e`) for [issue #10767](https://github.com/omacom/omarchy/issues/10767), where dismissing the screensaver restored a stale saved zero and left the Dell backlight off.
  Observe the next normal screensaver dismissal and lock/unlock cycle; neither was forced during testing.
- `keyboard-backlight-hibernate.sh`: [#13729](https://github.com/omacom/omarchy/pull/13729) (worktree `~/Projects/omarchy-kbd-hibernate`) restores the backlight after hibernation, which the pre-hibernate hook set to 0 with no `post` restore.
  Observe the next suspend-then-hibernate resume.
- `nightlight-schedule-refresh.sh`: [#13684](https://github.com/omacom/omarchy/pull/13684) (worktree `~/Projects/omarchy-nightlight`) re-probes hyprsunset a second past every minute, so the 07:00/20:00 switches reach the bar ([issue #8286](https://github.com/omacom/omarchy/issues/8286)); `nightlight-probe-guard.patch` drops a probe that lands while a toggle is applying.
  Observe the next scheduled switches, including one crossed while suspended.
  If [hyprwm/hyprsunset#95](https://github.com/hyprwm/hyprsunset/pull/95) (per-profile `on-switch`) ships, `on-switch = omarchy-shell -q nightlight refresh` in `hypr/hyprsunset.conf` replaces the polling.
- `pi-theme-agent-dir.sh`: applies [#13693](https://github.com/omacom/omarchy/pull/13693), so `omarchy-theme-set-pi` honours `PI_CODING_AGENT_DIR` ([issue #13691](https://github.com/omacom/omarchy/issues/13691)).
- `wheel-scroll.sh`: applies [#8959](https://github.com/omacom/omarchy/pull/8959), so touchpad scrolling moves the menus and the emoji picker by an eighth of the list per notch (the slowness is [issue #7361](https://github.com/omacom/omarchy/issues/7361); Hyprland's `touchpad.scroll_factor = 0.4` applies to layer surfaces and has no layer-rule override).
  Dry-run applies to the installed 4.0.4 files; pending a terminal `yadm bootstrap` for the sudo patch and `omarchy-restart-shell`, then a real touchpad check that rows still hover and click.

## pi session naming

ADR-0062: sessions are named from their first prompt by `pi/agent/extensions/session-name.ts`.
[TinySquid/pi-agent-extensions#19](https://github.com/TinySquid/pi-agent-extensions/pull/19) merged 2026-09-28 but is unreleased (npm `pi-agent-extensions` is still 0.5.4, from 2026-08-22); once a newer version ships, point `settings.json` back at the package and delete the extension.

## pi permission reviewer

Committed 2026-09-29: the permission system's auto-reviewer calls `alias/reviewer` from `pi-model-fallback-alias` (chain in `pi/agent/model-alias.json`), so an exhausted Codex quota fails over instead of turning every ask into a prompt.

- The `claude-bridge/claude-haiku-4-5` target works only through the `pi-claude-bridge-standalone-index` and `-prompt-capture` patches plus `provider.allowExtensionSystemPrompts: true` in `pi/agent/claude-bridge.json`; drop the patches once [#148](https://github.com/elidickinson/pi-claude-bridge/pull/148) ships in a release.
- `pi-model-alias-shared-registry` stays until [unrelentingfox/pi-model-fallback-alias#30](https://github.com/unrelentingfox/pi-model-fallback-alias/pull/30) ships: a per-subagent copy of the extension re-registered the process-wide `alias` provider with no registry, failing every alias call, and wrote failover warnings to stderr over the TUI ([earendil-works/pi#10002](https://github.com/earendil-works/pi/issues/10002)).
- Untested: whether `deepseek-v4.1-flash` and `mimo-v2.6-flash` judge risky asks as well as `codex-auto-review` does; only safe commands were exercised.

## pi subagent resume

Committed 2026-09-30 (`pi: carry pi-subagents#286 for evicted subagent resume`): the `pi-subagents-resume-evicted-*` patches carry [tintinweb/pi-subagents#286](https://github.com/tintinweb/pi-subagents/pull/286), so the `Agent` tool resumes an evicted subagent from its saved session, across `/reload` and restarts.

- Drop both patches when #286 ships; upstream had been idle since 2026-09-03, with 55 open PRs.
- Keeps `@tintinweb/pi-subagents` on source (~190 ms of startup, ADR-0067).
- Verified live 2026-09-30: after `/reload` wiped the in-memory record, resuming a probe agent by its old ID reopened the saved conversation (it answered a token only that conversation held) and kept the same ID.
