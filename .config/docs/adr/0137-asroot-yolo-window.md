# ADR-0137: Let `asroot --yolo` open a timed window of unprompted root, approved once, instead of approving every command

Status: Accepted
Date: 2026-11-27

## Context

ADR-0134 approves every agent root command, and dropped a shared sudo cache because, while fresh, it gave root to any `sudo` an agent hid in a script.
Bursts of agent root calls (package installs, service edits) meant typing the password into one popup after another.

## Decision

`asroot --yolo [N[s|m]|off]` (default 5m, at most 60m) opens or closes the window.

- Opening is approved through the normal `asroot` path (pkexec dialog or sudo popup), so an agent cannot grant itself the window.
- In the sudo-askpass popup, Ctrl+Y before the password opens a 5-minute window along with the command shown.
  The helper hands sudo the password as usual, then in the background replays it through a mode-0600 FIFO to `sudo -A asroot --yolo-grant`, and notifies the result.
  The polkit dialog at the desk takes no extra key, so there the window comes only from `asroot --yolo`.
- The grant is `/etc/sudoers.d/zz-yolo` (`NOPASSWD: ALL` for the user) plus `/run/asroot-yolo` holding the expiry epoch.
  A transient root timer, `asroot-yolo`, removes both; `--yolo` again restarts it and `off` closes it at once.
- While the flag is unexpired, `asroot <cmd>` runs `sudo -n <cmd>` without a prompt.
- A tmpfiles entry (`r!`, installed by the `agent-sudo` bootstrap step) removes a leftover grant at boot, since the timer does not survive a reboot.

## Consequences

For the window, ADR-0134's per-command approval is suspended: any `sudo` the user's processes run gets root, including one hidden in a script, and Pi's positional `sudo *` deny and the reviewer are the only remaining guards against bare `sudo`.
The window is opt-in and bounded, which is the difference from the shared cache ADR-0134 rejected.
The window is also open to processes that are not agents, by the same user.
With Ctrl+Y one password approves both the command shown and the window; the popup's prompt line says so while it is on.
The window opens about a second after that command authenticates, so only later calls skip the prompt.
