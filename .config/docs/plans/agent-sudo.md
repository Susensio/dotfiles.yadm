# Agent root through `asroot`

Status: proposed 2026-11-24, built and tested on `dell`; the ADR is written, and this plan deleted, once `nuc` passes.

## Problem

Agents (Claude and Pi) got root through `pkexec` behind a pane ask ([ADR-0071](../adr/0071-ask-before-pkexec.md)).
That needs a polkit agent in a local desktop session, so it fails wherever the harness runs over SSH: `nuc` has no `pkexec` and no reader, and over Tailscale SSH into `dell` pkexec exits 127 at once ("no authentication agent").
[ADR-0119](../adr/0119-privilege-out-of-command-text.md) answered remote root with a TTY the person elevates by hand, too much friction for routine work.
Plain `sudo` from an agent fails because its commands have no terminal to prompt on.

The design must work for Claude and Pi, locally or over SSH, inside herdr, tmux or neither, with or without a reader, cost one agent turn per root command, and put every root command in front of the person.

## Design

Agents run `asroot <cmd>` (`~/bin/asroot`), unsandboxed in Claude since both routes are setuid.

- **Local login session** (`XDG_SESSION_ID` local and no `SSH_CONNECTION`; fish copies the desktop's session id into SSH shells, so SSH decides first): `pkexec`, polkit's fingerprint dialog.
- **A person at a terminal:** plain `sudo`, prompting there.
- **Otherwise** (agents over SSH): `sudo -A` with `SUDO_ASKPASS=~/bin/sudo-askpass`, which opens a herdr popup (local plugin `herdr/plugins/sudo-askpass`; only plugins can open one) or a tmux `display-popup` where a client is attached, showing the exact quoted command; with neither it fails at once with "run it yourself".
  The password goes popup → mode-0600 FIFO under `$XDG_RUNTIME_DIR` → sudo, never an argument or a file; the prompt drops keys typed before it appeared, and closes when sudo stops waiting (90 s).
- **Approval is per command and enforced by polkit or sudo, not by matching command text.** No `timestamp_type=global`: with no terminal sudo keys its cache on the parent process, which is new on every tool call, so an agent never inherits an approval.
  A `sudo` hidden in `bash -c` or a script gets the fingerprint stage's unseen 30 s and then "a terminal is required": no root.
- **Reader hosts:** Omarchy puts `pam_fprintd` in `/etc/pam.d/sudo`, where it would wait unseen before the popup; `Defaults pam_askpass_service=sudo-askpass` gives `sudo -A` a stock stack without it (bootstrap step `omarchy/agent-sudo.sh`).
  Other hosts need no `/etc` change.
- **Rules:** Claude has no rule for `asroot` (the dialog or popup is the approval); Pi allows `asroot *` and keeps the bare `sudo *` deny; `pkexec` keeps its ask in both.

Accepted:
- A same-user process can read the FIFO while a popup is open; the design assumes the agent is not adversarial.
- Two `sudo` calls inside one agent command share a parent, so the second rides the first's approval within that command.

Rejected: a global sudo cache (lets hidden sudo through for its window), forwarded ssh-agent signing to `pam_ssh_agent_auth`, Tailscale SSH root, job-control takeover of the harness terminal, a desktop-window surface (only reachable at the desk, where pkexec serves), the upstream `herdr-sudo-askpass` plugin (same logic, third-party code handling the password).

## Tested on `dell` (2026-11-24)

- [x] Desk, from a harness: `asroot id -u` twice → fingerprint dialog each time.
- [x] Over Tailscale SSH in tmux: popup with `sudo -A id -u`, password → `0`; a second call asks again; Ctrl+C refuses; an unanswered popup closes at the timeout and leaves no FIFO directory.
- [x] Over SSH with no multiplexer: fails at once with "run it yourself".
- [x] Hidden `bash -c 'sudo true'` with no terminal: no root.
- [x] herdr popup opened and closed; the earlier herdr overlay passed end to end.
- [ ] The herdr popup answered end to end, and its typeahead drain.

## Next

1. **`nuc`:** a harness in herdr there runs `asroot id -u`.
2. **Records:** the ADR (supersedes ADR-0119's remote clause, amends ADR-0071: agents reach pkexec through `asroot`); `docs/harness.md`; `docs/access.md` (`nuc`'s LAN address is `192.168.1.8`, not `.103`).
3. **Later:**
   - A herdr server started at the desk and attached from the phone counts as local, so `asroot` picks pkexec and the dialog opens on `dell`'s screen.
   - Phone sessions: a TOTP factor in sudo's PAM stack (`pam_google_authenticator` or `pam_oath`, codes from Google Authenticator) would let the agent ask for a six-digit code in chat and pipe it to `sudo -S`; a single-use code is harmless in a transcript.
   - "Press Enter to approve", the askpass fetching the password from the `pass` vault, would cut a remote approval to one key and keep the password out of the FIFO.
   - A non-Omarchy host with a reader (Debian puts `pam_fprintd` in `common-auth`) would need its own askpass PAM service.
