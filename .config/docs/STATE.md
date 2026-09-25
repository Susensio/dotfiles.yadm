# State

## Omarchy migration

The dotfiles are ready for an Omarchy laptop (Arch, Hyprland under uwsm) per ADR-0044, 0045 and 0046; what remains happens on that laptop.

- Push the yadm repo first: the laptop clones from GitHub, and everything since `c41f054` is local on `wip`.
  `master` is about 280 commits behind `wip`, so the laptop clones `wip`, or `wip` is merged into `master` first.
- Setting up the laptop: `yadm clone -b wip <url>`; `yadm checkout -- ~/.config/{git,tmux,herdr,lazygit}`, since Omarchy seeds its own copies of those through `/etc/skel`; run the bootstrap; run `omarchy-remove-preinstalls` to drop the agent wrappers from `~/.local/bin`; never run `omarchy-reinstall-configs`, which copies `/etc/skel` over them again.
  After every `omarchy update`, `yadm diff`: its migrations edit the tracked tmux and herdr configs.
- The first run on Arch verifies what ADR-0048 was written without: the `packages.toml##distro.arch` installs and hook (`tldr` removal), `tool install`'s direct pacman branch, and `mise config set` writing a bootstrap package into a `##`-named file.
  `keyd.sh` has never run on Arch either: group creation, enabling the service, seeding `/etc/keyd/default.conf`.
  `yadm.sh` drives yadm's repo with plain `git`, no yadm binary; untested on a fresh clone, including one run from `bootstrap.yadm.io`'s remote yadm.
  ADR-0047's editor sync is untested against a real Omarchy: after bootstrap, `omarchy default editor` should print helix; pick nvim in Omarchy's menu, and `tools.conf` should read `EDITOR=nvim` and, after `env_reload`, `EDITOR` and `sudoedit` should follow.
  In a new terminal, `status is-login`: if terminals start non-login shells, `_env_pull` never runs.
- Verified on Mint so far: the same 53 tools resolve after the `conf.d` split; every `tool` command against a scratch config with stub `mise` and `pacman`; the bootstrap hooks run under `--only packages`.
- Next: an Omarchy packages step in the bootstrap that removes the unwanted preinstalls and restores what is actually used, mainly the webapps.

Delete this file and its `CLAUDE.md` line once the laptop runs clean.
