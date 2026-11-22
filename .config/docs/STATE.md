# State

## Speaker calibrator plugin: two crackles (2026-11-22, patch pending upstream)

Two separate crackles with separate causes, both on `dell`.

- **Random, under load:** realtime scheduling was missing. The plugin's filter-chain unit asks RTKit to make its data thread realtime, but nothing installs `rtkit` on x86_64 Omarchy (upstream adds it only for aarch64). Installed and enabled here; the plugin's DSP thread and PipeWire's ALSA thread both run `SCHED_RR 20`. Upstream, [issue #40](https://github.com/thefreshoffice/omarchy-speaker-calibrator/issues/40) asks for it in the dependency table and the panel's package check.
- **On every volume change:** the loudness tracker forked a `pw-cli` and connected a client per ramp step, 7–16 per key press. [PR #42](https://github.com/thefreshoffice/omarchy-speaker-calibrator/pull/42) streams the ramp through one session; verified here (a 12-step ramp lands on its target, ~100 ms warm, eight writes 135 ms forked against 1 ms). [issue #41](https://github.com/thefreshoffice/omarchy-speaker-calibrator/issues/41) carries the report, corrected to withdraw its measured claims after the capture path proved unreliable (`omarchy_speaker_tuning.monitor` taps the filter's input, not its output).

The plugin clone's `origin` is `Susensio/omarchy-speaker-calibrator` and `upstream` is `thefreshoffice/omarchy-speaker-calibrator`, with `origin/main` holding the fix commit, so `omarchy plugin update thefreshoffice.speaker-calibrator` reports "up to date" instead of failing ([ADR-0122](adr/0122-plugin-patch-on-fork.md)); `plugins.conf` and the shell placement are untouched.

Still open:
- Once #42 merges, reset the fork and delete it: `git -C ~/.config/omarchy/plugins/thefreshoffice.speaker-calibrator fetch upstream && git reset --hard upstream/main && git push --force origin main`.
- `rtkit` is in no bootstrap step, and the plugin's dependency table omits it, so a rebuilt machine loses realtime scheduling and the random crackle returns. `dependencies.txt` entries are `command [package]`, so the candidate is `rtkit-daemon rtkit` (the same package name on pacman and apt). Held back until #40 decides whether the plugin should offer it itself.
- Neither fix has been through a fresh-machine bootstrap; both are verified on `dell` only.

## Secrets: the pass vault (2026-11-18, accepted; migration complete on `dell`)

`docs/plans/vault.md` is done on `dell` (steps 0–4 passed 2026-11-20: stub published, throwaway clone unlocked by it alone, `.env` sum equal, fresh-keyring passphrase asked) and step 6 retired the age file with it; ADR-0115's Corrections section now records the key-keeping change (vault GPG key, no age file) and the memory-only master passphrase with its decrypt drill, replacing the paper copy the plan first wanted.
The vault lives at `~/.local/share/secrets` (tool-read, not a project), `new-machine` clones it, imports `vault-key.asc` and runs `yadm git-crypt unlock` with no key file, and the homelab keeps no secrets in git at all (its own plans); only its restic password is a `pass` entry.
Agents stay denied `gpg`, `pass`, `age` and `git-crypt` and the vault directory (Claude and pi): the `age` deny is a guardrail now, not part of the flow, and a step never runs those commands (ADR-0111).

Still open:
- The nuc rebuild proved the flow on a real machine (2026-11-21): vault cloned, key imported, git-crypt unlocked after the tree was cleaned, keypair registered in both GitHub slots (titled `nuc`), `authorized_keys` seeded, and `ssh nuc` from dell passwordless over the LAN. Two bugs it surfaced are fixed and pushed: the tracked alt link that dirtied every non-Omarchy tree (`helix: untrack the alt link...`), and `new-machine`'s masked errexit (`yadm: catch failures in new-machine subshells...`); a third, found later, was the `36_authorized_keys.sh` mode (`yadm: mark the authorized_keys step executable...`) — added `100644`, it never ran on any bootstrap, only when run by hand.
- Left on nuc: the fossil autostash of the moot link rewrite (`yadm stash drop`), and a logout/login for `environment.d`.
- `maintenance` reports unpushed commits in `~/.local/share/secrets` and entries not in git (built 2026-11-20, `maintenance: report the vault's unpushed and uncommitted drift`), because `pass` commits without pushing and its git half fails silently.

## Omamail keepLoaded patch (2026-11-06)

Goal: Omamail's window appears as soon as the bar icon is clicked, instead of rebuilding its whole QML composition on every summon (~1.3 s here).
Omarchy's panel loader keeps a plugin's panel between summons only when its manifest sets `keepLoaded`, so the key belongs in Omamail's manifest; [huacnlee/omamail#464](https://github.com/huacnlee/omamail/pull/464) carries it and [ADR-0106](adr/0106-omamail-keep-loaded-patch.md) holds the reasoning and the drop condition.
Locally the clone's `origin` is `Susensio/omamail` and `upstream` is huacnlee's, with `keepLoaded` committed on the fork's `main`, so `omarchy plugin update omamail` fast-forwards instead of refusing ([ADR-0122](adr/0122-plugin-patch-on-fork.md)); the bootstrap step that used to insert the line is gone.
Finish it by resetting the fork to `upstream` and dropping it once a release carries the key.
The resident panel costs about 40 MB of shell RSS and lives for the session; a leak across a long session is unverified.

## pi-permission-system cd home-prefix patch (2026-10-24)

The patch library carries `pi-permission-cd-home-prefix`, the `~` / `~/…` cd-target fold, because 41.0.0 resolves a relative token after such a `cd` against the session cwd and asks about a path that does not exist.
[ADR-0101](adr/0101-cd-home-prefix-patch.md) holds the reasoning and the drop condition; [gotgenes/pi-packages#1083](https://github.com/gotgenes/pi-packages/issues/1083) and [PR #1084](https://github.com/gotgenes/pi-packages/pull/1084) carry the upstream change.
Finish it by deleting `pi/agent/patches/pi-permission-cd-home-prefix/` once a release contains the fix, then `pi update --extensions`; do not adapt the patch if the upstream shape differs.
The patch only takes effect after a `/reload` or restart, since the bundle is built from it.

## Omarchy gruvbox and Helix upstream handoff (2026-09-30)

The roadmap, completed upstream work and local-experiment constraints are in [`docs/plans/gruvbox-upstream.md`](plans/gruvbox-upstream.md); this section holds only live state.

- Open upstream: [PR #13843](https://github.com/omacom/omarchy/pull/13843) (Helix theme provisioning) and Suggestions Discussion [#13864](https://github.com/omacom/omarchy/discussions/13864) (gruvbox naming), waiting on maintainer answers; #6696 (Helix template) was open at the time of its review comment — check before proposing template edits.
- The local override `omarchy/themed/helix.toml.tpl` is live (vivid syntax roles, transparent background) and must be revised or removed by explicit choice after the merged fallback is tested.
- Live selections: Helix uses `omarchy`, Herdr uses vendor `gruvbox`.
- Standing constraint: do not swap the classic gruvbox palette tiers or submit the vivid variant wholesale; the vivid scratch themes were tried and deleted on 2026-10-03.

## Omarchy migration

Setup and the standing oddities are in `docs/omarchy.md`; `~/Projects/omarchy` is the upstream checkout.

- Observe the next live theme switch in Foot inside tmux (ADR-0075): pane and status colours, no intermediate flash on inactive panes, the cursor colour after an app sends OSC 112, and `tmux show-environment -g COLORFGBG` plus a new pane's environment.
  If a pane's ANSI palette or a redraw turns out to matter, the dropped pane-TTY OSC writes and `SIGWINCH`/`refresh-client` are the first candidates to restore into the hook.
- ADR-0069: observe menu Suspend on battery hibernating after 5h, the lid on AC staying suspended, and an unplug during sleep starting the countdown.
- `fingerprint.sh` has not run on a fresh machine; Dell's driver crashed fprintd once at enroll stage 9 of 12, then enrolled cleanly on a retry.
- ADR-0076 applied 2026-09-29: chords, the power-key cluster, the Print family, the notification and panel families, and zen mode are all live; the full inventory and its corrections live in the record (`omarchy menu keybindings --print` lists the set).
  Still to observe live: Super + Alt + hjkl's `window.move({ monitor })` (wiki-verified, unexercised), Shift + Power's suspend, Ctrl + Print's QR decode, dictation's hold/latch/latch-then-Insert, and the wifi/bluetooth toggles' state reaching the bar panels; zen mode was measured and kept 2026-10-03, and the later-adopted keys (keybindings menu, nightlight/idle toggles, last notification, cursor zoom) load clean but are unexercised from the keyboard.

### Bugfix steps waiting on upstream

Each is an ADR-0057 step under `yadm/bootstrap.d/omarchy/bugfix/`; delete it once its PR ships.

- `uwsm-mise-shims.sh`: [#13364](https://github.com/omacom/omarchy/pull/13364) drops `10-omarchy`'s `mise activate bash --shims`, which put the shims ahead of `environment.d`'s `PATH`.
- `hypr-envs-path.sh`: [#13351](https://github.com/omacom/omarchy/pull/13351) drops the `PATH` prepend from `default/hypr/envs.lua`.
- `keybindings-menu-submaps.sh` was dropped after 4.5: with no submap bindings left (ADR-0076) it patched a menu that had nothing to group, and the patch no longer applies.
- `keyboard-backlight-hibernate.sh`: [#13729](https://github.com/omacom/omarchy/pull/13729) restores the backlight after hibernation, which the pre-hibernate hook sets to 0 with no `post` restore.
  Closed 2026-10-29 in favour of #15908, which does not touch the hook (4.5.0-3 still zeroes with no restore); a reopen request was posted 2026-11-06 and is unanswered (checked 2026-11-11), so the step stays.
  Observe the next suspend-then-hibernate resume.
- `nightlight-schedule-refresh.sh`: [#13684](https://github.com/omacom/omarchy/pull/13684) (worktree `~/Projects/omarchy-nightlight`) re-probes hyprsunset a second past every minute, so the 07:00/20:00 switches reach the bar ([issue #8286](https://github.com/omacom/omarchy/issues/8286)); `nightlight-probe-guard.patch` drops a probe that lands while a toggle is applying.
  Observe the next scheduled switches, including one crossed while suspended.
  [hyprwm/hyprsunset#95](https://github.com/hyprwm/hyprsunset/pull/95) (per-profile `on-switch`) merged 2026-10-09, but the newest release is still v0.4.0 (2026-07-13) and the installed binary has no `on-switch` flag, so the polling stays until the first release after v0.4.0 ships (checked 2026-11-11; no later tag exists yet); `on-switch = omarchy-shell -q nightlight refresh` in `hypr/hyprsunset.conf` then replaces it.
- `pi-theme-agent-dir.sh`: applies [#13693](https://github.com/omacom/omarchy/pull/13693), so `omarchy-theme-set-pi` honours `PI_CODING_AGENT_DIR` ([issue #13691](https://github.com/omacom/omarchy/issues/13691)).
  #13693 closed unmerged 2026-11-07 for review-queue hygiene; #13691 is still open and 4.5.0-3 still hardcodes the path, so the patch stays (checked 2026-11-11).
- `default-editor-mime.sh`: applies [#7446](https://github.com/omacom/omarchy/pull/7446), so text files opened from a file manager follow the menu's editor; `mime.sh` points at its handler and keeps doing so after the step goes.
  A review proposing the handler in the shipped `mimeapps.list` instead is on the PR, branch `default-editor-handler-review` on the fork; refresh the patch if the PR adopts it.
- `default-filemanager.sh`: applies [#10542](https://github.com/omacom/omarchy/pull/10542), a Defaults entry for the file manager; Super + E calls its `omarchy-launch-filemanager`, so revert that binding if the PR is rejected.
  A review with three follow-up commits (launch through the desktop entry, shims for `omarchy-launch-nautilus`, leave foreign FileManager1 registrations alone) is on the PR, branch `default-filemanager-review` on the fork; refresh the step if the PR adopts them.
- `wheel-scroll.sh`: applies [#8959](https://github.com/omacom/omarchy/pull/8959), so touchpad scrolling moves the menus and the emoji picker by an eighth of the list per notch (the slowness is [issue #7361](https://github.com/omacom/omarchy/issues/7361); Hyprland's `touchpad.scroll_factor = 0.4` applies to layer surfaces and has no layer-rule override).
  Applied by a terminal `yadm bootstrap` on 2026-10-05; pending `omarchy-restart-shell`, then a real touchpad check that rows still hover and click.

## pi session naming

ADR-0062: sessions are named from their first prompt by `pi/agent/extensions/session-name.ts`, running on the cheap alias tier and renaming the herdr tab over the socket — the shipped `@tinysquid/pi-auto-session-name` alternative (checked 2026-10-18) names with the session's own model and knows nothing about herdr tabs, so the extension stays.

## pi permission reviewer

Committed 2026-09-29, reordered 2026-10-18 ([ADR-0092](../adr/0092-pi-tier-order-by-intelligence.md)) and 2026-11-05 ([ADR-0103](../adr/0103-pi-rung-order-shared-quota.md)): the auto-reviewer calls `alias/reviewer` from `pi-model-fallback-alias` (`pi/agent/model-alias.json`).

- The `claude-bridge/claude-haiku-5-5` rung works only through three patches carrying [pi-claude-bridge#216](https://github.com/elidickinson/pi-claude-bridge/pull/216) (open): `pi-claude-bridge-index` and `-prompt-capture` add the standalone route, `pi-permission-auto-review-standalone` marks the reviewer's calls `promptKind: "standalone"`; the reviewer runs with `followUpReviews: "off"` because the standalone route takes user messages only.
  Drop the bridge patches once #216 ships in a release, and the auto-review patch once the extension sets the marker itself.
- Untested: whether `deepseek-v4.1-flash` and `mimo-v2.6-flash` judge risky asks as well as `codex-auto-review` does; only safe commands were exercised.

## pi model catalog

Committed 2026-10-18 ([ADR-0094](../adr/0094-pi-model-catalog-bootstrap.md)): `yadm/bootstrap.d/pi/models.sh` refreshes `pi/agent/models-store.json` once a day, because pi only refreshes when the TUI model selector opens and a headless machine therefore keeps the catalog bundled with its installed version.

- The step never fails the bootstrap: a refresh that times out exits non-zero upstream, so the step converts it to a warning. pi leaves an existing store untouched when a refresh fails, so the retry is free.
- A store written before any provider is authenticated is `{}`; the next run with credentials overwrites it, and the daily gate stops that from repeating on every attempt.
- Untested on a machine that has never run pi: the step's fresh-store path was exercised against scratch agent directories, not a real first bootstrap.

## pi model fallback

Committed 2026-10-05 and reordered on 2026-10-18 ([ADR-0092](../adr/0092-pi-tier-order-by-intelligence.md), [ADR-0093](../adr/0093-pi-tier-lead-by-capability.md)) and 2026-11-05 ([ADR-0103](../adr/0103-pi-rung-order-shared-quota.md)); the ADRs carry the chain orders and their reasons.

- `pi-claude-bridge-index` now carries only the #216 standalone route (since 2026-11-06, the #163 half having shipped in 0.9.2).
- Untested live: the failover fix is covered by pi-claude-bridge's own test, not by an exhausted-quota run against a real chain.
- claude-bridge once rewrote `pi/agent/claude-bridge.json` during this work and a `yadm restore` brought back the committed file; cause unknown, watch for a repeat before blaming the patch.

## SSD trim

[ADR-0098](adr/0098-luks-discards-header-flag.md): TRIM reaches the SSD through the LUKS2 header's persistent `allow-discards` flag and btrfs's default async discard.

- Applied and verified 2026-11-20: `lsblk --discard` shows the `root` mapping passing discards (`DISC-MAX 2T`) and `findmnt -no OPTIONS /` lists `discard=async`, so `fstrim.timer` stays off.
- `bootstrap.d/luks-discards.sh` now walks the device chain to find the crypt device instead of asking the root's own device, so a rebuilt host whose root sits on LVM above the LUKS mapping is checked rather than silently skipped.

## Tailscale mesh and signing keys (2026-11-10)

`dell` and `nuc` both answer Tailscale SSH on their tailnet IP, and `dell` reaches `nuc` by name with no key; `nuc` keeps OpenSSH on its LAN address as the fallback ([ADR-0109](adr/0109-tailscale-ssh-mesh-per-machine-signing-keys.md), superseded for the signing/auth split by [ADR-0117](adr/0117-one-key-two-slots.md); matrix in [access.md](access.md)).
`35_machine_key.sh` mints and registers the per-machine keypair in both GitHub slots, and CI checks the second bootstrap by what it changed ([ADR-0111](adr/0111-rerun-checked-by-state-logins-warn.md)).

- Unverified: the phone reaching `nuc` by tailnet name with no credential. Termux's `ssh` should offer "none" authentication; a phone app that demands one cannot.
- `dell` runs no sshd, so it is reachable only through Tailscale SSH, and every other machine's bootstrap has yet to run the signing step.
- `nuc`'s homelab `docs/STATE.md` listed an SSH key added to GitHub as signing *and* auth; [ADR-0117](adr/0117-one-key-two-slots.md) now allows one keypair filling both, so that line is no longer a contradiction, though the auth registration itself is unused.
- Left over on GitHub: none — `gh api user/keys` returns an empty list (checked 2026-11-20), so `chuwi`'s authentication key (162582085) and `nuc`'s 2023 RSA key (87867050) are both gone; the account holds three signing keys only (`chuwi`, `dell`, `nuc`).

## yadm alt race and commit signing (2026-10-24)

`~/.ssh/id_ed25519` now exists without a passphrase and `commit.gpgsign` is on, so every commit signs unattended ([ADR-0100](adr/0100-passphraseless-signing-key.md)).
`git/allowed_signers` carries the same public key, which is what turns the local `U` (signed, unknown signer) into `G`.

- Opened [yadm PR #550](https://github.com/yadm-dev/yadm/pull/550), which restores `ln -nfs` in `ln_relative()` so two concurrent `auto-alt` runs replace the link instead of one failing; reported `verified: true` on `develop` `bbb58e6`, with [issue #549](https://github.com/yadm-dev/yadm/issues/549) as the report and a comment on [#538](https://github.com/yadm-dev/yadm/pull/538) recording that #538 fixes only the steady-state case.
- Until a yadm release carries the change, `bootstrap.d/omarchy##distro.omarchy/omarchy##distro.omarchy` regenerates whenever two yadm commands overlap; `bootstrap.d/yadm-alt-selflink.sh` removes it on every bootstrap (so after a pull or an `omarchy update`), and the link is untracked either way.
  Delete that step once PR #550 is in a release: `maintenance` reports the PR when it merges, and merged is not released, so compare `yadm version` first.
- The PR's `test_alt_concurrent` is the only new failure-free test: the 20 other failures in `test/test_alt.py` need template processors (`envtpl`, `j2cli`, `j2`, `esh`) this machine does not have, and predate the change.
