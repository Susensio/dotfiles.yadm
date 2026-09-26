# Omarchy

How these dotfiles live on an Omarchy laptop (Arch, Hyprland under uwsm), where Omarchy and yadm both want to own `~/.config`.
Written against Omarchy 4.0.4; the session environment is §8 of `environment-architecture.md`.

## Setting up a machine

In Bash, `source <(curl -fsSL https://bootstrap.yadm.io)`, then `yadm clone --no-bootstrap -b master <url>`.
Omarchy seeds its own copies of some configs through `/etc/skel`, so restore ours before bootstrapping: `yadm checkout -- ~/.config/{git,tmux,herdr,lazygit,omarchy,hypr}`.
Then run `yadm bootstrap`, which installs the tools and trims Omarchy's preinstalls ([ADR-0049](adr/0049-omarchy-preinstalls-mise-bootstrap.md)).

Never run `omarchy-remove-preinstalls`: its blanket `rm` hits the tools mise links into `~/.local/bin`.
Never run `omarchy-reinstall-configs`: it copies `/etc/skel` over the tracked configs again.

## Omarchy writes into tracked files

Several Omarchy commands edit files yadm tracks, so a `yadm diff` after them is expected, not drift:

- `omarchy update` runs migrations that edit the tmux and herdr configs, among others.
  Omarchy has a `post-update` hook but no pre-update one; review the diff by hand.
- The editor menu writes `EDITOR` into `environment.d/tools.conf` ([ADR-0047](adr/0047-helix-canonical-editor-name.md)).
- The text-size slider (`omarchy display text size`) sets three things at once: `[font] base-size` in `omarchy/shell.toml`, the font size in `foot/foot.ini`, and GTK's `text-scaling-factor` in dconf, which is not tracked.

After `yadm pull`, the `post_pull` hook reruns the bootstrap, which is silent when there is nothing to do ([ADR-0056](adr/0056-silent-idempotent-bootstrap.md)).

## Overriding Omarchy commands

The Omarchy shell's `PATH` puts `/usr/share/omarchy/bin` before `~/bin/overrides`.
A wrapper in `~/bin/overrides` shadowing an `omarchy-*` command works from a terminal but is never reached from keybindings, menus or hooks.

## Editor

uwsm keeps `EDITOR=omarchy-launch-editor --inline` for the session ([ADR-0051](adr/0051-keep-uwsm-editor-launcher.md)); `SUDO_EDITOR` follows the editor picked in Omarchy's menu.
Tools that match `EDITOR` against a list of known editors, like lazygit's edit presets, cannot recognise the launcher and need the editor named in their own config.
The menu changes `EDITOR` only: text files keep opening in the editor set as the MIME default by the bootstrap.

## Distro detection

yadm alternates such as `##distro.omarchy` and `##distro_family.arch` read `/etc/os-release`, which says `ID=omarchy`, `ID_LIKE=arch`.
An installed `lsb_release` takes precedence and would change what they match.
