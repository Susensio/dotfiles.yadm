# State

## Omarchy migration

The dotfiles are ready for an Omarchy laptop (Arch, Hyprland under uwsm) per ADR-0044, 0045, 0048, 0049, 0050, 0051 and 0052, written against Omarchy 4.0.4; what remains happens on that laptop.

Setup and the standing oddities are in `docs/omarchy.md`.

- Ran on the laptop (2026-09-26): the `packages.toml##distro_family.arch` installs, `tool install`'s pacman branch (through its `##` fallback; backlog: mise upstream), `keyd/keyd.sh`, `yadm.sh` from the fresh clone, `omarchy/preinstalls.sh` and `omarchy.toml##distro.omarchy`, whose `tldr` now goes through a `pre-packages` hook.
  ADR-0047's editor sync is untested against a real Omarchy: after bootstrap, `omarchy default editor` should print helix; pick nvim in Omarchy's menu, and `tools.conf` should read `EDITOR=nvim`.
  After `env_reload`, `SUDO_EDITOR` and `sudoedit` should follow nvim, while uwsm's `EDITOR=omarchy-launch-editor --inline` remains per ADR-0051.
  `omarchy/extensions/omarchy-menu.jsonc` should hide Install and Remove › Preinstalls; unchecked against a live menu.
  On Omarchy, verify `env_reload` applies an `environment.d` edit without clearing uwsm's session values.
  Reapply the active Omarchy theme once after cloning so the new tmux palette template is rendered; verify tmux startup and a later theme switch update the pane and status colors.
  During a live switch in Foot inside tmux, watch whether Omarchy's window-style write followed by our hook causes a visible flash, especially on inactive panes.
  Compare the Foot palette and ANSI colors inside tmux with the outer terminal; check whether Omarchy's pane OSC write is needed in addition to `omarchy-theme-set-foot` before removing it.
  Check `tmux show-environment -g GUM_FILTER_MATCH_FOREGROUND` and `tmux show-environment -g COLORFGBG` after switching light and dark themes, then inspect the environment in a newly created pane; these values are separate from tmux's visual roles.
  Watch whether an app such as Neovim resets the cursor to the old Foot color, and whether the updater's `cursor-colour` fallback prevents it.
  After those observations, decide whether to keep Omarchy's tmux updater, shadow it with a local wrapper while restoring useful updates (not reached from the desktop, see `docs/omarchy.md`), or seek a narrower upstream opt-out.
  `omarchy/mime.sh` has run and `mimeapps.list` holds its defaults; still click a `mailto:` link with a subject and check Gmail's compose fills in, and open a text file from Nautilus.
  ADR-0055's bindings load with an empty `hyprctl configerrors`; `hyprctl binds` should still be checked for Omarchy defaults beyond media and clipboard.
  Check Super + P enters window mode and Escape leaves it, Super + I/O skip empty workspaces, the lid and power button still act, and PrtSc's region picker takes Return and the arrows.
- Verified on Mint so far: the same 53 tools resolve after the `conf.d` split; every `tool` command against a scratch config with stub `mise` and `pacman`.
  After the X11 startup-script update and a reboot, `env_reload` added and removed a temporary `environment.d` variable while preserving `EDITOR`, `PATH`, `DISPLAY` and `XAUTHORITY` in the user manager.

### Next, on the laptop (2026-09-26)

Cloned and bootstrapped; foot now starts login shells, and the Goodix reader works through `omarchy/fingerprint.sh`.

- Checked after a reboot (2026-09-26): terminals run `fish --login` with `~/bin/overrides:~/bin` right behind the mise shims, fprintd runs at boot and sudo takes a fingerprint, the bootstrap is silent, the manager holds `EDITOR=omarchy-launch-editor --inline` and `SUDO_EDITOR=env helix`, and the Hyprland `PATH` patch and capture folders are in place.
- `yadm push`: `master` is 40-odd commits ahead of GitHub.
- Sizing: scale 1.25 with bar 12 and Foot 9pt, or scale 1 with bar 15 and Foot 11pt; pick one, then track `omarchy/shell.toml`.
- `fingerprint.sh` has not run on a fresh machine; Dell's driver crashed fprintd once at enroll stage 9 of 12, then enrolled cleanly on a retry.

Delete this file and its `CLAUDE.md` line once the laptop runs clean.
