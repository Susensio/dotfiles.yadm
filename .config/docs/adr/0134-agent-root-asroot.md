# ADR-0134: Give agents root through asroot: pkexec at the desk, sudo -A with a multiplexer popup over SSH, approved per command, instead of an operator-elevated TTY or a shared sudo cache

Status: Accepted
Date: 2026-11-24

## Context

Agents (Claude and Pi) got root through `pkexec` behind an ask in their pane (ADR-0071).
That path needed a polkit agent in a local desktop session.
Harnesses also ran over SSH: on `nuc` (Debian, no `pkexec`, no fingerprint reader) and, from the phone, on `dell`.
There pkexec exited 127 at once with "no authentication agent", and plain `sudo` failed because an agent's commands had no terminal to prompt on.
ADR-0119 had answered remote root with a TTY the operator elevated by hand, which cost too much friction for routine work.

Claude Code had no way to prompt for a password (its feature request was closed as not planned), and its hooks run without a terminal.
Sudo's own `SUDO_ASKPASS` hook could reach the person instead, provided something could draw a prompt where they were looking.
Herdr popups can only be opened by a plugin and are session-modal; tmux 3.8 has floating panes (`new-pane`), which are not.

The requirements were: Claude and Pi alike, local or over SSH, inside herdr, tmux or neither, with or without a reader, one agent turn per root command, low friction, and every root command in front of the person.

Measurements on 2026-11-24:
- Omarchy's `/etc/pam.d/sudo` tries `pam_fprintd` first; an agent's `sudo -A` waited its 30 s with the cue only in the command's output, then fell through to the askpass.
- Sudo's `pam_askpass_service` selects a separate PAM service for `-A`.
- Over Tailscale SSH, fish copies the desktop's `XDG_SESSION_ID` from the user manager into the shell, so a session id alone misreads SSH as local.
- With no terminal, sudo keys its credential cache on the parent process.

## Decision

Agents run `asroot <cmd>`, a script in `~/bin` that makes the choice inside one call.

- In a local login session (no `SSH_CONNECTION`, and `XDG_SESSION_ID` naming a session logind reports as not remote), it runs `pkexec`: polkit's fingerprint dialog, as before.
- With a controlling terminal, it runs plain `sudo`, which prompts there.
- Otherwise it runs `sudo -A` with `SUDO_ASKPASS` set to `sudo-askpass`.
  That script opens a herdr popup through the local herdr plugin `sudo-askpass`, or a non-modal tmux floating pane (3.8+, focused but not modal, sized to the command) where a client is attached, showing the exact command sudo received, quoted.
  With neither, it fails at once with the command to run by hand.
  The password travels popup → mode-0600 FIFO under `$XDG_RUNTIME_DIR` → sudo; the prompt discards keys typed before it appeared, and closes when sudo stops waiting after 90 s.
- Approval is per command, enforced by polkit or sudo rather than by matching command text: no `timestamp_type=global`, so an agent never inherits an earlier approval.
- On Omarchy, the bootstrap step `agent-sudo` installs `/etc/pam.d/sudo-askpass` (the stock stack without `pam_fprintd`) and a sudoers drop-in pointing `pam_askpass_service` at it.
- Claude carries no rule for `asroot`, since the dialog or popup is the approval; Pi allows `asroot *`, keeps the positional `sudo *` deny, and its reviewer keeps denying privilege verbs carried inside a command.
  `pkexec` keeps its ask in both.

This replaces ADR-0119's operator-elevated TTY for remote root; its positional `sudo *` rule and prose-safe reviewer wording stand.
It narrows ADR-0071: an agent's pkexec now comes through `asroot` without a pane ask, because the polkit dialog shows the command itself.

## Consequences

Every agent root command costs one human action: a finger at the desk, the password over SSH.
That is more typing over SSH than a cache would cost; a shared 15-minute cache (`timestamp_type=global`) was tried and dropped because, while fresh, it gave root to any `sudo` an agent hid in a script.
A hidden `sudo` with no terminal now gets the fingerprint stage's unseen wait and then "a terminal is required": no root.

The password reaches no argument, environment variable or file, but while a popup is open any process running as the user can read its FIFO; the design assumes the agent is not adversarial.
Two `sudo` calls inside one agent command share a parent process, so the second rides the first's approval within that command.

A popup steals focus from whatever the person was typing into; the first herdr test captured seven characters meant for another pane, which is why the prompt discards early keystrokes.

Known gaps, accepted for now:
- A herdr server started at the desk and later attached from the phone counts as local, so `asroot` picks pkexec and the dialog opens on `dell`'s unattended screen.
- Phone sessions through Remote Control have no surface the helper can draw on, and a password must not go through chat.
  Root from the phone is SSH into the machine and attaching to the multiplexer, where the popup takes the password outside the chat; the measurements are in [`harness.md`](../harness.md#remote-control-and-root).
  Rejected for now: approving by a tap on the harness prompt (a convention, not a credential: any process running as the user could skip it) and typing the static password in chat (it reaches the transcript and the model).
  Left open: a TOTP factor in sudo's PAM stack (`pam_oath`), so a one-time code pasted in chat reaches `sudo -S`; it keeps the approval in the app at the cost of an authenticator switch, and `CLAUDE_CODE_BRIDGE_SESSION_ID` can only hint that a bridge is connected.
- A non-Omarchy host with a reader (Debian puts `pam_fprintd` in `common-auth`) would bring the 30 s wait back and needs its own askpass PAM service.

Rejected alternatives: forwarded ssh-agent signing to `pam_ssh_agent_auth` (a dedicated key, agent, askpass and PAM module for one box); Tailscale SSH as root (no per-command human factor, Tailscale only); taking over the harness's terminal with job control (it races the harness for keystrokes, so a password could land in the transcript); a desktop-window surface (only reachable at the desk, where pkexec serves); the third-party `herdr-sudo-askpass` plugin (the same few dozen lines, but someone else's code handling the password).
