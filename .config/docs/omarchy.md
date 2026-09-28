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

## Agent skills

Omarchy symlinks its skills into `$HOME`-relative agent roots: `~/.agents`, `~/.claude`, `~/.codex`, `~/.pi/agent`, `~/.hermes`, and later `~/.gemini/config`.
This layout rehomes the agents that take a config-directory variable and deletes those `$HOME` copies, leaving the skills in `~/.config/claude`, `~/.config/codex`, `~/.config/pi/agent`, `~/.config/hermes` and the generic `~/.config/.agents` ([ADR-0068](adr/0068-xdg-agent-skill-roots.md)).
`omarchy update` migrations recreate the `$HOME` links, so the post-update bootstrap removes them again.
Antigravity has no such variable, so the agent and its skill were removed instead.

## Omarchy writes into tracked files

Several Omarchy commands edit files yadm tracks, so a `yadm diff` after them is expected, not drift:

- `omarchy update` runs migrations that edit the tmux and herdr configs, among others.
  Omarchy has a `post-update` hook but no pre-update one; review the diff by hand.
  The post-update hook reruns `yadm bootstrap`, which reapplies what the update undid.
- The editor menu writes `EDITOR` into `environment.d/tools.conf` ([ADR-0047](adr/0047-helix-canonical-editor-name.md)).
- The text-size slider (`omarchy display text size`) sets three things at once: `[font] base-size` in `omarchy/shell.toml`, the font size in `foot/foot.ini`, and GTK's `text-scaling-factor` in dconf, which is not tracked.

After `yadm pull`, the `post_pull` hook reruns the bootstrap, which is silent when there is nothing to do ([ADR-0056](adr/0056-silent-idempotent-bootstrap.md)).

## Theme templates

Omarchy renders `omarchy/themed/` into `~/.local/state/omarchy/current/theme`, state yadm ignores, only during a theme set ([ADR-0052](adr/0052-direct-omarchy-tmux-palette.md)).
Hyprland cannot read `colors.toml` at load time, so `hypr/looknfeel.lua` requires the rendered `hypr-palette.lua`, and a clone that predates the template fails its config rather than merely losing styling.
`bootstrap.d/omarchy/theme.sh` re-renders whenever a tracked or update-refreshed template, or the current theme's `colors.toml`, is missing from the theme directory or newer than its render; it reloads Hyprland after (headless rendering skips Omarchy's reload) and stays silent when nothing is stale.
`themed/shell.toml.tpl` pins only the bar surface to the theme's `darker_background`, shadowing the stock shell template that renders every other surface; a machine-level `omarchy/shell.toml` key would win over the rendered file.
The step renders files only: running apps retint through Omarchy's theme-set hook, and the rest of what a theme ships — backgrounds, icons — still arrives only with a theme set, so editing one of those wants an explicit `omarchy-theme-refresh`.

## Overriding Omarchy commands

Omarchy's `default/hypr/envs.lua` puts `/usr/share/omarchy/bin` first on `PATH` for everything Hyprland starts, and its `autostart.lua` imports that into the user manager, so a wrapper in `~/bin/overrides` would never be reached in the session.
`bootstrap.d/omarchy/bugfix/hypr-envs-path.sh` patches the prepend out until the upstream fix ships ([ADR-0057](adr/0057-omarchy-bugfix-patch-steps.md)); a relogin applies it.

## Patching Omarchy bugs

A bug in an Omarchy system file that has a PR upstream gets a step in `bootstrap.d/omarchy/bugfix/`, one per PR, linking it ([ADR-0057](adr/0057-omarchy-bugfix-patch-steps.md)).
Each step sources `lib.sh` and passes its patch filename; the helper resolves it from its own `assets/` directory.
`omarchy update` restores the unpatched files, and its `post-update.d/yadm-bootstrap.hook` reruns the bootstrap to patch them again.

`bugfix/codex-usage-rpc.sh` applies [Omarchy PR #12979](https://github.com/omacom/omarchy/pull/12979): Codex usage checks read replies and notifications from a shared byte buffer, so a reply arriving alongside a notification does not cause a false timeout.

`bugfix/keyboard-backlight-restore.sh` applies [Omarchy PR #10364](https://github.com/omacom/omarchy/pull/10364): keyboard brightness is saved for one blank/restore cycle, and manual brightness changes discard that snapshot.
This prevents screensaver dismissal from restoring an old off value, as reported in [issue #10767](https://github.com/omacom/omarchy/issues/10767), while preserving a deliberately disabled backlight.

## Editor

uwsm keeps `EDITOR=omarchy-launch-editor --inline` for the session ([ADR-0051](adr/0051-keep-uwsm-editor-launcher.md)); `SUDO_EDITOR` follows the editor picked in Omarchy's menu.
Tools that match `EDITOR` against a list of known editors, like lazygit's edit presets, cannot recognise the launcher and need the editor named in their own config.
The menu changes `EDITOR` only: text files keep opening in the editor set as the MIME default by the bootstrap.

## Distro detection

yadm alternates such as `##distro.omarchy` and `##distro_family.arch` read `/etc/os-release`, which says `ID=omarchy`, `ID_LIKE=arch`.
An installed `lsb_release` takes precedence and would change what they match.

## Chromium stays running

`chromium.service`, installed by `bootstrap.d/omarchy/chromium.sh`, starts Chromium without a window at login, so a new window opens in about 0.5 s instead of a 1.3 s cold start, for about 0.5 GB of memory.
Chromium exits with no window open unless started with `--keep-alive-for-test`, a switch meant for its own tests; if a release drops it, the service just exits and launches go back to cold starts.
A change to `chromium-flags.conf` applies after `systemctl --user restart chromium`, and quitting Chromium from its menu stops the service until the next login.

`chromium-flags.conf` is tracked directly, including `--force-device-scale-factor=0.9` and Omarchy's bundled Google OAuth flags.
The Chromium bootstrap installs and enables the background service and refreshes a user-local desktop entry from the packaged launcher, changing all its `Exec` commands to `chromium`.
Set **Page zoom → 125%** manually in `chrome://settings/appearance`; later zoom changes stay in Chromium's profile and are not managed by bootstrap.

## Chromium popup windows

The workaround is contained in the commit titled `omarchy: float native chromium popups`.
Revert that commit to remove it.

`~/bin/overrides/chromium` launches native Wayland Chromium through [wl-relabel](https://github.com/valentin-morice/wl-relabel), pinned to 0.1.1 in mise's Omarchy tools.
The existing mise `system-install` hook links the proxy into `~/.local/bin`.
The override uses `_super` to find the underlying Chromium without recursion and passes every argument through.
It runs Chromium directly outside Wayland or when the proxy is missing; proxy errors otherwise surface rather than silently restarting the browser.

`wl-relabel/rules.toml` labels Chromium windows requesting server-side decorations with a minimum width below 400 as `chromium-popup` before their first mapping commit.
Normal windows declared a 500px minimum and popups 179px when checked with Chromium 152.
Undocked DevTools is claimed first and keeps its original class.
The popup label avoids Omarchy's forced browser tiling rule, and `hypr/hyprland.lua` floats and centres it without overriding Chromium's requested geometry.
Title-change handlers were rejected because they briefly tiled the popup and rearranged existing windows before floating it.

Both the service (`/usr/bin/env chromium`) and the local desktop entry (`Exec=chromium`) resolve the session PATH, whose overrides directory precedes system directories.
Omarchy's browser and web-app launchers read the desktop entry's first executable, so it must remain `chromium`, rather than a multiword proxy command.
The first process for a Chromium profile must use the proxy; later launches reuse that process.
Installing or bypassing the override therefore takes effect after Chromium restarts, or at the next login.

The proxy remains in the browser's Wayland connection for its lifetime, and a proxy failure disconnects that display connection.
Its protocol library hides unsupported compositor protocols, and browser updates can change the classification hints, so test a newer proxy or Chromium version with a disposable profile before changing this workaround.
A roughly five-second page-loading pause was reported after enabling the proxy, but disposable-profile comparisons did not reproduce a consistent proxy-only delay and encountered network failures with both launch paths.
The cause remains unconfirmed.

[Chromium's Linux window setup](https://github.com/chromium/chromium/blob/main/chrome/browser/ui/views/frame/browser_native_widget_aura_linux.cc) exposes `browser`/`pop-up` roles for X11 but assigns ordinary browser and login popup windows the same Wayland app ID.
No Chromium issue tracking this exact fix was found; the [related upstream browser bug](https://bugzilla.mozilla.org/show_bug.cgi?id=1864115) belongs to Firefox.
Remove the workaround when Chromium exposes popup identity before mapping, for example through [the Wayland toplevel-tag protocol](https://gitlab.freedesktop.org/wayland/wayland-protocols/-/blob/main/staging/xdg-toplevel-tag/xdg-toplevel-tag-v1.xml), which would let a compositor rule distinguish these windows directly.
