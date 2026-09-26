# Linux Environment Variable Architecture (The "Mess" Explained)

This document explains how environment variables move between systemd, the Mint Cinnamon session, and Fish, with the Omarchy uwsm path described separately.
It also details the XDG setup and the relevant boot sequences.

**Historical Context:** This architecture was born during the transition period where Linux desktops moved background services to `systemd --user`, but the UI session remained managed by X11/LightDM.
These two worlds do not naturally share an environment, leading to "stale" variables in terminals and background services.
This setup bridges that gap.

Sections 1–6 describe Mint's X11/LightDM setup.
Section 8 describes the planned Omarchy Wayland/uwsm setup.

## 1. The Core Problem: Two Hierarchies
On a modern Linux desktop, there isn't a single "root" process for everything.
At login, the system splits into two independent branches:

### Simplified Process Tree
```text
systemd (PID 1)
├── lightdm (Display Manager)
│   └── lightdm --session-child
│       └── cinnamon-session
│           ├── cinnamon (Window Manager)
│           └── [Graphical Apps] (e.g., Chrome)
└── systemd --user
    ├── dbus-daemon (Session Bus)
    ├── gnome-terminal-server
    │   └── fish (Your Shell)
    └── [Background Services] (Pipewire, GVFS, Portals)
```

Because these two branches are independent, a variable set in one (e.g., via `lightdm`) is **not** automatically visible to the other (e.g., a service started by `systemd --user`).

## 2. The X11 Boot & Sourcing Sequence
Understanding *when* files are sourced is critical to avoiding race conditions.

### Phase 1: The PAM/Systemd Layer (The Foundation)
1.  **PAM Login:** When you enter your password, `pam_systemd` starts the `systemd --user` manager.
2.  **Environment Generators:** `systemd --user` immediately runs generators, including `systemd-environment-d-generator`.
    *   **Static base:** `~/.config/environment.d/*.conf` are loaded now.
    *   **XDG Foundation:** `10_xdg.conf` sets up the base paths.

### Phase 2: The LightDM Layer (The UI Branch)
1.  **`lightdm-session`:** Starts and sources global and user profiles:
    *   Sourced: `/etc/profile`
    *   Sourced: `~/.config/profile` (Redirected via our XDG bootstrap)
2.  **Xsession scripts:** The same Bash wrapper sources `/etc/X11/Xsession.d/` in filename order:
    *   **Step A: The Pull (`00xdg-compliance` -> `40x11-common_xsessionrc`):**
        *   `00xdg-compliance` redirects `USERXSESSIONRC` to `~/.config/X11/xsessionrc`.
        *   **Action:** `xsessionrc` runs `source <(systemctl --user show-environment)` to pull the systemd variables into the X session, filtering out shell-managed names first (`PWD`, `USER`, `HOME`, `SHELL`, `SHLVL`, `_`) since this process `exec`s onward into `cinnamon-session` — see [ADR-0043](adr/0043-drop-display-guard-filter-env-import.md).
    *   **Step B: The Push (`95dbus_update-activation-env`):**
        *   **Action:** Runs `dbus-update-activation-environment --systemd --all`.
            This pushes the X11 environment (containing `DISPLAY`, `XAUTHORITY`, etc.) back into `systemd --user`.
    *   **Step C: The Unpin (`96fix-env-precedence`):**
        *   **Action:** Calls `systemctl --user unset-environment` for the names `environment.d`'s generator owns.
            This clears the dynamic overrides from Step B once at X11 session startup, so later `environment.d` reloads can take effect — see [ADR-0050](adr/0050-unpin-x11-at-session-start.md).
            `DISPLAY` and `XAUTHORITY` are not generator-owned, so they are deliberately left pinned, not unset.

### Phase 3: The Shell Layer (The Interactive Experience)
1.  **Terminal Startup:** You open a terminal.
    `gnome-terminal-server` (child of systemd) spawns a shell.
2.  **The Fish Transition:** `~/.config/bash/bashrc` detects an interactive session and `exec fish --login`.
3.  **The Final Sync:** `01_environment.fish` detects a login shell and calls `_env_pull`.
    *   **Action:** Fetches the current environment from `systemd --user`, including session overrides.

## 3. The Static Base: `environment.d`
We use `systemd-environment-d-generator(8)` to maintain the static configuration shared by user services.
Session managers can override individual names in the same user manager.
*   **Location:** `~/.config/environment.d/*.conf`
*   **The Foundation (`10_xdg.conf`):** This is the cornerstone of our XDG compliance.
    It:
    1.  Defines the standard XDG base directories (`XDG_CONFIG_HOME`, `XDG_CACHE_HOME`, etc.).
    2.  Forces many standard tools (Rust, Node, Python, GnuPG, GTK) to use these directories instead of their default dotfiles in `$HOME`.
*   **Excluded from every import:** `systemctl --user show-environment` also reports shell-managed names that must never be imported verbatim: `PWD`, `USER`, `HOME`, `SHELL`, `SHLVL`, `_`.
    Importing `PWD` would desynchronise it from the real working directory; `SHLVL` is load-bearing in `bash/bashrc`'s exec-into-fish condition (`^[12]$`).
    Every consumer of `show-environment` filters these six names out before importing: `fish/functions/environment/_env_fetch.fish`'s `readonly_vars` list, and an inline `grep -Ev '^(PWD|USER|HOME|SHELL|SHLVL|_)='` in both `~/.config/profile` and `~/.config/X11/xsessionrc`.
    See [ADR-0043](adr/0043-drop-display-guard-filter-env-import.md) for why each of the three keeps its own copy instead of sharing one.

## 4. Why `_env_pull` and Login Shells are Mandatory
A new terminal inherits its environment from whatever launched it, and that launcher's environment was fixed when the session started.
On Mint that is `gnome-terminal-server`, activated once by Cinnamon; on Omarchy it is Hyprland, started once by uwsm.
* **The Consequence:** If you update your environment (e.g., via `env_reload`), the launcher does **not** see these changes.
  Every new terminal would inherit its *stale* environment.
* **The Solution:** By starting a login shell and calling `_env_pull`, we bypass the stale process tree and fetch variables directly from the `systemd --user` manager.
* **The Limit:** Only shells get this.
  Anything else Hyprland or Cinnamon launches (apps, launchers, menus) keeps the session-start environment until the next login.

## 5. Shell Lifecycle & Transitions

### The Bash-to-Fish Relay
While Fish is our primary interactive shell, we use Bash as the entry point for compatibility:
1.  **Entry:** Most sessions start `/bin/bash`.
2.  **Relay (`~/.config/bash/bashrc`):** If the shell is interactive, it `exec`s into `fish`.
3.  **State Preservation:** Bash checks if it is a login shell and passes the `--login` flag to Fish, ensuring the environment sync logic is triggered.

### Login Shell Support (`~/.config/profile`)
This architecture works seamlessly on TTYs, via SSH, and for any other login shell:
1.  **Login:** `/bin/bash` starts as a login shell and sources `~/.config/profile`, which sources `bashrc` first.
2.  **Interactive Transition:** If interactive, `bashrc` `exec`s into `fish` here, replacing the process before it ever reaches step 3 below.
3.  **Systemd Sync:** Otherwise (a non-interactive login shell, e.g. `bash -lc '...'`, or an interactive shell past `SHLVL` 2), control returns to `profile`, which unconditionally pulls the latest environment from `systemctl --user show-environment`, filtering out shell-managed names first.
    Before [ADR-0043](adr/0043-drop-display-guard-filter-env-import.md) this step only ran when no graphical display was detected, leaving a non-interactive login shell in a graphical session unable to reconstruct its own `$PATH` — the gap that ADR closes.

## 6. XDG Compliance & Dotfile Management
Our system is designed to keep `$HOME` clean by adhering strictly to the **XDG Base Directory Specification**.

### The Bootstrap (`yadm/bootstrap.d/10_xdg_compliance/`)
These scripts perform the initial "surgical" moves and configuration:
*   **Bash:** Config is moved to `~/.config/bash/` and patched via `/etc/bash.bashrc`.
*   **Profile:** Moved to `~/.config/profile` and sourced via `/etc/profile.d/`.
*   **X11:** `xsessionrc` is moved to `~/.config/X11/xsessionrc`.
*   **XAuthority:** Moved to `/var/run/lightdm/` (via `lightdm.conf`) to avoid `.Xauthority` in `$HOME`.
*   **Sudo:** Disables the `~/.sudo_as_admin_successful` flag.

### Known Exception: `~/.xsession-errors`
Unfixable in userspace: LightDM writes it internally, compiled into the daemon (`strings /usr/sbin/lightdm` shows the literal path), before our `session-wrapper` (`/usr/sbin/lightdm-session`, not `/etc/X11/Xsession`) even runs.
No env var, patch, or symlink reaches it.
Longstanding upstream request, unaddressed: [canonical/lightdm#95](https://github.com/canonical/lightdm/issues/95).
Not self-truncating — worth an occasional manual check.

## 7. Hot-Reloading (`env_reload`)
The `env_reload` function is the manual "Sync Now" button.
It:
1.  Tells systemd to re-read `environment.d` (`systemctl --user daemon-reload`).
2.  Imports the resulting manager environment into the *current* shell (`_env_pull`).
3.  If called inside tmux, pushes it to the current server and its scratchpad server (`_env_sync_tmux`).

It preserves dynamic session values, including values exported by uwsm.
The X11 blanket import is cleared separately at session startup by `96fix-env-precedence`.
The user manager is shared across sessions, so a reload cannot infer ownership from the calling shell's X11 or Wayland variables.

## 8. Omarchy: Wayland via uwsm

This account was checked live on the laptop with Omarchy 4.0.4.
SDDM starts Omarchy's `omarchy.desktop` session, which runs `uwsm start` for Hyprland.
The systemd user manager loads `environment.d` as its static base, and uwsm sources Omarchy's `/usr/share/uwsm/env.d/10-omarchy` during session setup.
That script sets `EDITOR=omarchy-launch-editor --inline` and `TERMINAL=xdg-terminal-exec`, then runs mise activation, which can change `PATH`.
uwsm exports the resulting changes into the user manager.
uwsm also exports compositor variables such as `WAYLAND_DISPLAY` when the session starts; it tracks its exports for cleanup when the session ends.
This path does not run Mint's Xsession scripts or their blanket import and unpin steps.

uwsm sources every `uwsm/env.d/*` file in each config directory, the system ones first, so `~/.config/uwsm/env.d/*` runs after `10-omarchy`, and a same-named file adds to Omarchy's rather than masking it.
Variables that mean something only in the Omarchy session, like `OMARCHY_SCREENSHOT_DIR` in `uwsm/env.d/capture`, go there rather than into `environment.d`, which Mint and SSH or TTY logins also load ([ADR-0058](adr/0058-omarchy-session-env-uwsm.md)).
Hyprland then applies Omarchy's `default/hypr/envs.lua` to everything it starts, and `autostart.lua` imports Hyprland's whole environment into the user manager at session start, so a `hl.env` there overrides both layers above.
That is how `/usr/share/omarchy/bin` came first on the session `PATH`; `bootstrap.d/omarchy/bugfix/hypr-envs-path.sh` patches it out until Omarchy PR #13351 ships.
The session `PATH` is then `environment.d`'s order behind the mise shims that `10-omarchy` prepends.

`env_reload` reruns the `environment.d` generator and pulls the resulting manager environment into the current shell.
It does not rerun uwsm's session files or remove their overrides.
An `environment.d` change to an overridden name stays masked until the session owner changes or removes its value.
Omarchy's launcher remains the manager's `EDITOR` while `SUDO_EDITOR` follows the selected terminal editor tracked in `tools.conf`.
See [ADR-0051](adr/0051-keep-uwsm-editor-launcher.md).

`PATH` is one of those overridden names: uwsm exports it after mise activation, so a `PATH` change in `environment.d` reaches nothing until the next login, `env_reload` included.
The first bootstrap writes `environment.d` inside a session that started without it, so `yadm/bootstrap` ends by warning to log out when any `environment.d` file is newer than the user manager.

foot, Omarchy's terminal, starts a non-login shell by default, so `bashrc` would relay into a non-login `fish` and `_env_pull` would never run.
`foot/foot.ini` sets `shell=/usr/bin/bash --login` for §4 to hold; its `login-shell=yes` would also prefix commands run with `-e`, which breaks mise shims that dispatch on their name.

## 9. Cheat Sheet & Verification (For the Future)

### Key Commands
*   `env_reload`: Reload `environment.d` into the user manager and current shell.
    Use this after editing `~/.config/environment.d/*.conf`.
*   `systemctl --user show-environment`: See the systemd user manager's current environment.
*   `env`: See what your current Shell process believes.

### How to Verify the Sync is Working
1.  **X11 -> Systemd:** Run `systemctl --user show-environment | grep DISPLAY`.
    It should be set (synced via Script 95).
2.  **Systemd -> Shell on Mint:** Open a **new** terminal window and run `echo $EDITOR`.
    It should match `tools.conf` after the login-shell pull.

### Troubleshooting "Stale" Variables
If a variable isn't updating in your terminal:
1.  **Check if it's a login shell:** Run `status is-login` in Fish.
    If it says `no`, your terminal isn't calling `_env_pull`.
2.  **Check the manager value:** Run `systemctl --user show-environment`.
    If it is stale after `env_reload`, check for a later dynamic override; the reload no longer removes session values.
