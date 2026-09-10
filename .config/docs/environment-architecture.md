# Linux Environment Variable Architecture (The "Mess" Explained)

This document explains how environment variables are synchronized across different process hierarchies in this system (Cinnamon + systemd + Fish).
It also details how we maintain strict XDG compliance and the exact boot sequence.

**Historical Context:** This architecture was born during the transition period where Linux desktops moved background services to `systemd --user`, but the UI session remained managed by X11/LightDM.
These two worlds do not naturally share an environment, leading to "stale" variables in terminals and background services.
This setup bridges that gap.

**Note on X11 vs Wayland:** This architecture is specifically designed for X11 environments (like Cinnamon).
Wayland-based compositors often handle environment synchronization differently.

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
    *   **Source of Truth:** `~/.config/environment.d/*.conf` are loaded NOW.
    *   **XDG Foundation:** `10_xdg.conf` sets up the base paths.

### Phase 2: The LightDM Layer (The UI Branch)
1.  **`lightdm-session`:** Starts and sources global and user profiles:
    *   Sourced: `/etc/profile`
    *   Sourced: `~/.config/profile` (Redirected via our XDG bootstrap)
2.  **`Xsession`:** The session script takes over and runs scripts in `/etc/X11/Xsession.d/`:
    *   **Step A: The Pull (`00xdg-compliance` -> `40x11-common_xsessionrc`):**
        *   `00xdg-compliance` redirects `USERXSESSIONRC` to `~/.config/X11/xsessionrc`.
        *   **Action:** `xsessionrc` runs `source <(systemctl --user show-environment)` to pull the systemd variables into the X session, filtering out shell-managed names first (`PWD`, `USER`, `HOME`, `SHELL`, `SHLVL`, `_`) since this process `exec`s onward into `cinnamon-session` — see [ADR-0043](adr/0043-drop-display-guard-filter-env-import.md).
    *   **Step B: The Push (`95dbus_update-activation-env`):**
        *   **Action:** Runs `dbus-update-activation-environment --systemd --all`.
            This pushes the X11 environment (containing `DISPLAY`, `XAUTHORITY`, etc.) back into `systemd --user`.
    *   **Step C: The Unpin (`96fix-env-precedence`):**
        *   **Action:** Runs `_env_unpin` (calling `systemctl --user unset-environment`).
            This unsets the dynamic overrides from Step B for the names `environment.d`'s generator owns, so `environment.d` remains the master for hot-reloads on those names — see [ADR-0002](adr/0002-unset-systemd-overrides.md).
            `DISPLAY` and `XAUTHORITY` are not generator-owned, so they are deliberately left pinned, not unset.

### Phase 3: The Shell Layer (The Interactive Experience)
1.  **Terminal Startup:** You open a terminal.
    `gnome-terminal-server` (child of systemd) spawns a shell.
2.  **The Fish Transition:** `~/.config/bash/bashrc` detects an interactive session and `exec fish --login`.
3.  **The Final Sync:** `01_environment.fish` detects a login shell and calls `_env_pull`.
    *   **Action:** Fetches the absolute latest environment from `systemd --user`, ensuring your shell matches the "Source of Truth".

## 3. The Single Source of Truth: `environment.d`
We use `systemd-environment-d-generator(8)` to maintain a single, static configuration point.
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
`gnome-terminal-server` functionally inherits its environment from the session that first triggered its activation (usually Cinnamon).
* **The Finding:** The terminal server process is often "stuck" with the environment it had at startup.
* **The Consequence:** If you update your environment (e.g., via `env_reload`), the already-running terminal server process does **not** see these changes.
  Every new terminal tab will inherit the server's *stale* environment.
* **The Solution:** By starting a login shell and calling `_env_pull`, we bypass the stale process tree and fetch variables directly from the `systemd --user` manager.

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

### The Bootstrap (`yadm/bootstrap.d/xdg_compliance/`)
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
1.  Unsets dynamic overrides to prevent pinning (`_env_unpin`).
2.  Tells systemd to re-read `environment.d` (`systemctl --user daemon-reload`).
3.  Imports those variables into the *current* shell (`_env_pull`).

## 8. Cheat Sheet & Verification (For the Future)

### Key Commands
*   `env_reload`: The "Sync Everything" button.
    Use this after editing `~/.config/environment.d/*.conf`.
*   `systemctl --user show-environment`: See what the Systemd/DBus world currently believes.
*   `env`: See what your current Shell process believes.

### How to Verify the Sync is Working
1.  **Systemd -> X11:** Run `xprop -root | grep PULSE_SERVER`.
    If it's set in `environment.d`, it should show up here (synced via `xsessionrc`).
2.  **X11 -> Systemd:** Run `systemctl --user show-environment | grep DISPLAY`.
    It should be set (synced via Script 95).
3.  **Systemd -> Shell:** Open a **new** terminal window and run `echo $EDITOR`.
    It should match your `tools.conf`.

### Troubleshooting "Stale" Variables
If a variable isn't updating in your terminal:
1.  **Check if it's a login shell:** Run `status is-login` in Fish.
    If it says `no`, your terminal isn't calling `_env_pull`.
2.  **Check for "Pinning":** Run `systemctl --user show-environment`.
    If the old value is there, run `env_reload`.
