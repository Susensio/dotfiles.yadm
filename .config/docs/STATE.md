# State

## Omarchy migration

The dotfiles are ready for an Omarchy laptop (Arch, Hyprland under uwsm) per ADR-0044, 0045 and 0046; what remains happens on that laptop.

- Push the yadm repo first: the laptop clones from GitHub, and everything since `c41f054` is local.
- Setting up the laptop: `yadm clone`; `yadm checkout -- ~/.config/{git,tmux,herdr,lazygit}`, since Omarchy seeds its own copies of those through `/etc/skel`; run the bootstrap; never run `omarchy-reinstall-configs`, which copies `/etc/skel` over them again.
- The first run on Arch verifies what ADR-0046 was written without: the `packages.toml##distro.arch` installs and hooks (`tldr` removal, `hx` link), `tool install`'s pacman branch, and `mise bootstrap packages use` writing to a `##`-named file.
  `keyd.sh` has never run on Arch either: group creation, enabling the service, seeding `/etc/keyd/default.conf`.
  In a new terminal, `status is-login`: if terminals start non-login shells, `_env_pull` never runs.
- Verified on Mint so far: the same 53 tools resolve after the `conf.d` split; every `tool` command against a scratch config with stub `mise` and `pacman`; the bootstrap hooks run under `--only packages`.

Delete this file and its `CLAUDE.md` line once the laptop runs clean.
