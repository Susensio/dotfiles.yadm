# State

## Secrets: the pass vault (2026-11-18, accepted)

The cloud session that designed this ended here; the agent on the owner's machine continues from this section.

Done:
- ADR-0115 (git-crypt in the dotfiles, `yadm add-secret`, the `pre_commit` hook) is live; aichat's `.env` is encrypted.
- `docs/plans/vault.md` is accepted: `~/.local/share/secrets` becomes a `pass` store whose GPG key, committed there protected by the master passphrase, also unlocks the dotfiles' git-crypt (`yadm git-crypt add-gpg-user`), replacing `dotfiles.git-crypt.key.age` and age.
- Agents are denied `gpg`, `pass` and the vault directory (Claude and pi); `gnupg` and `pass` are dependencies; `PASSWORD_STORE_DIR` is set in `environment.d/tools.conf`. The vault moved from `~/Projects/secrets` to `~/.local/share/secrets` on 2026-11-20: a tool-read store, not a project one; `new-machine` and the docs follow.
- The homelab no longer keeps secrets in git (its `docs/plans/secrets.md`); only its restic password goes into this vault.

Now, the owner, by hand, outside any AI session: the migration in `docs/plans/vault.md`, steps 0 to 6. An agent never runs it, and never reads the store, the key or the passphrase.

Steps 0–4 passed on `dell` on 2026-11-20 (stub published, throwaway clone unlocked by it alone, `.env` sum equal to the live file, fresh-keyring passphrase asked); step 5 rides the fresh-format `nuc`, whose `new-machine` bootstrap carries the vault steps below and is itself the second-machine proof; step 6 retires the age file afterwards.
The paper copy of the master passphrase was declined: it is held in memory only, verified by drill (`CLEAR_PASSPHRASE --mode=normal`, then a decrypt), a drill to repeat occasionally. This amends the follow-up ADR below.

After step 5 passes on `nuc`, the agent:
1. Done 2026-11-20, ahead of the rest because the fresh `nuc` bootstrap needs it: `new-machine` now clones `secrets`, `gpg --import vault-key.asc`, `yadm git-crypt unlock`, skipped quietly when the store cannot be cloned, as the logins are. The old `TODO:` is gone (commit `yadm: new-machine imports the vault key and unlocks git-crypt`).
2. Amend ADR-0115 where it says how the key is kept (the GPG key in the vault, no age file, no paper copy, memory-only with the drill above), and bring `docs/secrets.md` and `docs/access.md` in line; the agent denies for `age` can go once nothing uses age.
3. `maintenance`: report commits in `~/.local/share/secrets` not yet pushed (`git -C ~/.local/share/secrets status -sb`, no decryption).
4. On a real machine, the login checks still open in `docs/BACKLOG.md`.

Until step 6 retires it, the old path stays: `dotfiles.git-crypt.key.age` in `secrets`, opened with `age -d`, then `yadm git-crypt unlock <key>`.

## Omamail keepLoaded patch (2026-11-06)

Goal: Omamail's window appears as soon as the bar icon is clicked, instead of rebuilding its whole QML composition on every summon (~1.3 s here).
Omarchy's panel loader keeps a plugin's panel between summons only when its manifest sets `keepLoaded`, so the key belongs in Omamail's manifest; [huacnlee/omamail#464](https://github.com/huacnlee/omamail/pull/464) carries it and [ADR-0106](adr/0106-omamail-keep-loaded-patch.md) holds the reasoning and the drop condition.
Locally, `yadm/bootstrap.d/omarchy/bugfix/omamail-keep-loaded.sh` inserts it into the untracked clone and rescans plugins.
Finish it by deleting that step once a release carries the key; until then `omarchy plugin update omamail` needs `git -C ~/.config/omarchy/plugins/omamail checkout -- manifest.json` first, and the bootstrap after the update re-applies the step.
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

- Not yet applied: `sudo cryptsetup refresh --allow-discards --persistent root` needs the passphrase in a terminal; until then `bootstrap.d/luks-discards.sh` warns.
- Unverified: after the next boot, `findmnt -no OPTIONS /` should list `discard=async`; if not, enable `fstrim.timer` instead.

## Tailscale mesh and signing keys (2026-11-10)

`dell` and `nuc` both answer Tailscale SSH on their tailnet IP, and `dell` reaches `nuc` by name with no key; `nuc` keeps OpenSSH on its LAN address as the fallback ([ADR-0109](adr/0109-tailscale-ssh-mesh-per-machine-signing-keys.md), matrix in [access.md](access.md)).
`35_signing_key.sh` mints and registers a per-machine signing key, and CI checks the second bootstrap by what it changed ([ADR-0111](adr/0111-rerun-checked-by-state-logins-warn.md)).

- Unverified: the phone reaching `nuc` by tailnet name with no credential. Termux's `ssh` should offer "none" authentication; a phone app that demands one cannot.
- `dell` runs no sshd, so it is reachable only through Tailscale SSH, and every other machine's bootstrap has yet to run the signing step.
- `nuc`'s homelab `docs/STATE.md` still lists an SSH key added to GitHub as signing *and* auth, which ADR-0109 rejects; the auth half should go when that file is next edited.
- Left over on GitHub: `chuwi`'s authentication key (162582085) and `nuc`'s 2023 RSA key (87867050) contradict the record and are unreferenced by it.

## yadm alt race and commit signing (2026-10-24)

`~/.ssh/id_ed25519` now exists without a passphrase and `commit.gpgsign` is on, so every commit signs unattended ([ADR-0100](adr/0100-passphraseless-signing-key.md)).
`git/allowed_signers` carries the same public key, which is what turns the local `U` (signed, unknown signer) into `G`.

- Opened [yadm PR #550](https://github.com/yadm-dev/yadm/pull/550), which restores `ln -nfs` in `ln_relative()` so two concurrent `auto-alt` runs replace the link instead of one failing; reported `verified: true` on `develop` `bbb58e6`, with [issue #549](https://github.com/yadm-dev/yadm/issues/549) as the report and a comment on [#538](https://github.com/yadm-dev/yadm/pull/538) recording that #538 fixes only the steady-state case.
- Until a yadm release carries the change, `bootstrap.d/omarchy##distro.omarchy/omarchy##distro.omarchy` regenerates whenever two yadm commands overlap; `bootstrap.d/yadm-alt-selflink.sh` removes it on every bootstrap (so after a pull or an `omarchy update`), and the link is untracked either way.
  Delete that step once PR #550 is in a release: `maintenance` reports the PR when it merges, and merged is not released, so compare `yadm version` first.
- The PR's `test_alt_concurrent` is the only new failure-free test: the 20 other failures in `test/test_alt.py` need template processors (`envtpl`, `j2cli`, `j2`, `esh`) this machine does not have, and predate the change.
