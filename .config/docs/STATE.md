# State

## Omarchy migration

The dotfiles are ready for an Omarchy laptop (Arch, Hyprland under uwsm) per ADR-0044, 0045, 0048, 0049, 0050, 0051 and 0052, written against Omarchy 4.0.4; what remains happens on that laptop.

- Push the local `master` first: GitHub's `master` is behind, and the laptop clones from GitHub.
- Setting up the laptop: in Bash, `source <(curl -fsSL https://bootstrap.yadm.io)`, then `yadm clone --no-bootstrap -b master <url>`; `yadm checkout -- ~/.config/{git,tmux,herdr,lazygit,omarchy,hypr}`, since Omarchy seeds its own copies of those through `/etc/skel`; run the bootstrap, which installs yadm and trims Omarchy's preinstalls; never `omarchy-remove-preinstalls`, whose blanket `rm` hits the tools mise links into `~/.local/bin`, and never `omarchy-reinstall-configs`, which copies `/etc/skel` over them again.
  After every `omarchy update`, `yadm diff`: its migrations edit the tracked tmux and herdr configs.
- The first run on Arch verifies what ADR-0048 was written without: the `packages.toml##distro_family.arch` installs, `tool install`'s direct pacman branch, and `mise config set` writing a bootstrap package into a `##`-named file.
  `keyd.sh` has never run on Arch either: group creation, enabling the service, seeding `/etc/keyd/default.conf`.
  `yadm.sh` drives yadm's repo with plain `git`, no yadm binary; untested on a fresh clone, including one run from `bootstrap.yadm.io`'s remote yadm.
  ADR-0047's editor sync is untested against a real Omarchy: after bootstrap, `omarchy default editor` should print helix; pick nvim in Omarchy's menu, and `tools.conf` should read `EDITOR=nvim`.
  After `env_reload`, `SUDO_EDITOR` and `sudoedit` should follow nvim, while uwsm's `EDITOR=omarchy-launch-editor --inline` remains per ADR-0051.
  `omarchy/preinstalls.sh` has never run: the launcher removal and restore, the wrapper cleanup; nor has `omarchy.toml##distro.omarchy`, whose `absent` packages need mise 2026.9.2+ and whose `tldr` must go before `tealdeer` installs.
  Both alternates assume yadm reads `/etc/os-release`; an installed `lsb_release` would take precedence.
  `omarchy/extensions/omarchy-menu.jsonc` should hide Install and Remove › Preinstalls; unchecked against a live menu.
  In a new terminal, `status is-login`: if terminals start non-login shells, `_env_pull` never runs.
  On Omarchy, verify `env_reload` applies an `environment.d` edit without clearing uwsm's session values.
  Reapply the active Omarchy theme once after cloning so the new tmux palette template is rendered; verify tmux startup and a later theme switch update the pane and status colors.
  During a live switch in Foot inside tmux, watch whether Omarchy's window-style write followed by our hook causes a visible flash, especially on inactive panes.
  Compare the Foot palette and ANSI colors inside tmux with the outer terminal; check whether Omarchy's pane OSC write is needed in addition to `omarchy-theme-set-foot` before removing it.
  Check `bash -lc 'type -a omarchy-theme-set-tmux'`: `~/bin/overrides` must resolve before `/usr/bin` for a local opt-out wrapper.
  Check `tmux show-environment -g GUM_FILTER_MATCH_FOREGROUND` and `tmux show-environment -g COLORFGBG` after switching light and dark themes, then inspect the environment in a newly created pane; these values are separate from tmux's visual roles.
  Watch whether an app such as Neovim resets the cursor to the old Foot color, and whether the updater's `cursor-colour` fallback prevents it.
  After those observations, decide whether to keep Omarchy's tmux updater, shadow it with a local wrapper while restoring useful updates, or seek a narrower upstream opt-out.
  `omarchy/mime.sh` has never run: `xdg-mime query default x-scheme-handler/mailto` should print `Gmail.desktop` and `text/plain` `Helix.desktop`; click a `mailto:` link with a subject and check Gmail's compose fills in, and open a text file from Nautilus.
  Picking nvim in Omarchy's editor menu leaves text files on Helix; `omarchy-editor-sync` changes `EDITOR` only.
  ADR-0055's bindings have never loaded in Hyprland: `hyprctl binds` should list no Omarchy default beyond media and clipboard, and `hyprctl configerrors` should be empty.
  Check Super + P enters window mode and Escape leaves it, Super + I/O skip empty workspaces, the lid and power button still act, and PrtSc's region picker takes Return and the arrows.
- Verified on Mint so far: the same 53 tools resolve after the `conf.d` split; every `tool` command against a scratch config with stub `mise` and `pacman`.
  After the X11 startup-script update and a reboot, `env_reload` added and removed a temporary `environment.d` variable while preserving `EDITOR`, `PATH`, `DISPLAY` and `XAUTHORITY` in the user manager.

Delete this file and its `CLAUDE.md` line once the laptop runs clean.
