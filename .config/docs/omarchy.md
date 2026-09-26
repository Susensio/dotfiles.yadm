# Omarchy

How these dotfiles live on an Omarchy laptop (Arch, Hyprland under uwsm), where Omarchy and yadm both want to own `~/.config`.
Written against Omarchy 4.0.4; the session environment is §8 of `environment-architecture.md`.

## Setting up a machine

Follow the README in `~/.github`, which covers the clone, restoring the configs Omarchy seeds through `/etc/skel`, and the bootstrap.
The bootstrap trims Omarchy's preinstalls itself ([ADR-0049](adr/0049-omarchy-preinstalls-mise-bootstrap.md)), so two Omarchy commands are not needed, and each breaks something a bootstrap rerun does not repair:

- `omarchy-remove-preinstalls` deletes mise's links in `~/.local/bin`, such as `claude` and `pi`.
  They come from the `system-install` task, which runs only when mise installs a tool; `mise run system-install` restores them.
- `omarchy-reinstall-configs` copies `/etc/skel` over the tracked configs.
  `yadm checkout -- ~/.config` restores them, after `yadm diff` to keep any local edit.

## Omarchy writes into tracked files

Several Omarchy commands edit files yadm tracks, so a `yadm diff` after them is expected, not drift:

- `omarchy update` runs migrations that edit the tmux and herdr configs, among others.
  Omarchy has a `post-update` hook but no pre-update one; review the diff by hand.
  The post-update hook reruns `yadm bootstrap`, which reapplies what the update undid.
- The editor menu writes `EDITOR` into `environment.d/tools.conf` ([ADR-0047](adr/0047-helix-canonical-editor-name.md)).
- The text-size slider (`omarchy display text size`) sets three things at once: `[font] base-size` in `omarchy/shell.toml`, the font size in `foot/foot.ini`, and GTK's `text-scaling-factor` in dconf, which is not tracked.

After `yadm pull`, the `post_pull` hook reruns the bootstrap, which is silent when there is nothing to do ([ADR-0056](adr/0056-silent-idempotent-bootstrap.md)).

## Overriding Omarchy commands

Omarchy's `default/hypr/envs.lua` puts `/usr/share/omarchy/bin` first on `PATH` for everything Hyprland starts, and its `autostart.lua` imports that into the user manager, so a wrapper in `~/bin/overrides` would never be reached in the session.
`bootstrap.d/omarchy/bugfix/hypr-envs-path.sh` patches the prepend out until the upstream fix ships ([ADR-0057](adr/0057-omarchy-bugfix-patch-steps.md)); a relogin applies it.

## Patching Omarchy bugs

A bug in an Omarchy system file that has a PR upstream gets a step in `bootstrap.d/omarchy/bugfix/`, one per PR, linking it ([ADR-0057](adr/0057-omarchy-bugfix-patch-steps.md)).
`omarchy update` restores the unpatched files, and its `post-update.d/yadm-bootstrap.hook` reruns the bootstrap to patch them again.

## Editor

uwsm keeps `EDITOR=omarchy-launch-editor --inline` for the session ([ADR-0051](adr/0051-keep-uwsm-editor-launcher.md)); `SUDO_EDITOR` follows the editor picked in Omarchy's menu.
Tools that match `EDITOR` against a list of known editors, like lazygit's edit presets, cannot recognise the launcher and need the editor named in their own config.
The menu changes `EDITOR` only: text files keep opening in the editor set as the MIME default by the bootstrap.

## Distro detection

yadm alternates such as `##distro.omarchy` and `##distro_family.arch` read `/etc/os-release`, which says `ID=omarchy`, `ID_LIKE=arch`.
An installed `lsb_release` takes precedence and would change what they match.
