# Proposal: tmux-notify — floating-pane notifications for agents and bells

Status: deferred — blocked on tmux ≥ 3.8 (this box is `tmux 3.7_c-1`).
Not implemented. A design write-up, not a decision — see `docs/BACKLOG.md`.
The shape below is frozen for when the gate opens; herdr's own `[ui.toast]`
and agent tracking (added after this write-up, now at 0.8.2) are worth a
quick overlap check at that point, but do not change the decision.

## Problem

Notification handling in this repo is a workaround built on tmux's bell
engine:

- `monitor-bell` + the `alert-bell` hook (`conf.d/32_visual.conf`) turn any
  BEL written to a pane into `window_bell_flag`; `BELL_TRAY` lights a
  `[range=control|7]`-clickable icon and `scripts/bell-menu` lists the
  pending windows.
- The tray only lights for **detached** sessions (`session_attached == 0`);
  an attached bell just blinks the tab (`window-status-bell-style`) and rings
  (`bell-action any`). There is no toast anywhere.
- Bells are window-scoped and clear on focus; they carry no metadata (agent
  identity, kind, session-resume target) and cannot express "agent needs
  input".
- Claude Code's `preferredNotifChannel: "terminal_bell"`
  (`~/.config/claude/settings.json`) only reaches tmux when the session has a
  pane. `--bg`/`/background` headless sessions have no pty, so nothing ever
  fires for them — the gap the original version of this proposal targeted.

Goal: one small system that makes agents (and any event) first-class — a
persistent server-wide **inbox** in the status bar with clear-on-focus
semantics, and a transient **floating-pane toast** on arrival — replacing the
bell workaround wholesale.

## Rejected approaches

- **Desktop notification** (`notify-send` from a `Notification` hook) —
  solves "I'm not looking at tmux at all," which turned out not to be the
  actual problem; out of scope.
- **Polling `claude agents --json`** — measured at ~1.8–2.3s per invocation
  (a full CLI cold start), far too slow for a 1s status-bar refresh; its
  `state` field isn't a reliable "needs attention" signal.
- **`display-popup` toasts** — popups are modal and capture the client's
  input for their whole lifetime; there's no non-interactive flag. `new-pane`
  floating panes (below) are strictly better: non-modal, behave as panes, and
  `-d` never steals focus.

## Prior art

Researched existing tmux + Claude Code status integrations (claude-squad,
happy-coder, ccstatusline, opensessions, and others). The mature pattern — e.g.
[tmux-agent-status](https://github.com/samleeney/tmux-agent-status) — is
hook-driven state *files* that later hook events simply overwrite. No poll
loop, no explicit delete logic: `UserPromptSubmit`/`PreToolUse` mark a session
"working", `Stop` marks it "done", `Notification` marks it "wait", and the
status bar just reads the cached files. This proposal keeps exactly that
pattern but generalizes it: bells are one more source feeding the same store.

## Decisions

**A first-party plugin, not config.** `~/Projects/tmux-notify` with a
`notify.tmux` entrypoint. Plugins here are managed by tpack, declared as
`set -g @plugin` in `90_plugins.conf` ([ADR-0061](../docs/adr/0061-adopt-tpack-for-plugins.md));
a local, not-yet-published checkout doesn't qualify for that path, so it is
sourced instead by an explicit `run-shell` line in `90_plugins.conf`, guarded
on the checkout existing. The engine is generic and reusable; this repo keeps
only glue.

**One store.** `$XDG_CACHE_HOME/tmux-notify/<ts>-<key>`, one file per pending
notification, `0x1f`-TSV: `label<1f>action<1f>kind<1f>window_id<1f>pane_id`
(the same SEP convention as `bell-menu`/`sessionizer`). Cleared = file
removed. `TMUX_NOTIFY_DIR` overrides the path for tests.

**One CLI.** `scripts/notify add|clear|count|list|tray|menu|toast`, `set -eu`
/ `DEBUG=1`. Dedupe by key (`bell` → window id, `agent` → session id) so a
chatty agent stays one tray item. Called by full path only — a `notify`
command-alias already means `display-message` (`15_aliases.conf`).

**Toast = a native floating pane, not a popup.** `new-pane -d -x <w> -y <h>`
`-X <winW-w> -Y <winH-h>` — a floating pane sits above the tiled layout like a
popup but is non-modal and behaves like a pane; `-d` keeps the current pane
active, so it never steals focus; it closes by itself when the toast command
exits. Bottom-right anchored, ~44×3, `-T`/`-B` for frame and title.
**Requires tmux ≥ 3.8** for the geometry flags; 3.7.x floating panes were
mouse-movable only. (This box is on 3.7c — upgrade first.)

**Tray reads the store.** `#(notify tray)` in `status-right` renders
`[range=control|7]   n` or nothing, keeping the existing click region →
`notify menu` (each entry jumps via its stored action and clears; a *Clear
all* entry is last). `Prefix n` (`20_keybinds.conf`) and `MouseUp1Control7`
(`22_mouse.conf`) already point at `scripts/bell-menu` today — this retargets
them to `notify menu` rather than adding new bindings.

**Clear semantics: focusing the pane clears.** The `pane-focus-in` hook
(focus-events already on, `32_visual.conf`) runs `notify clear --pane`. Items
keep both `window_id` and `pane_id`: bell items (window-scoped — tmux has no
per-pane bell) clear on any pane in the window; agent items clear when their
own pane is focused. Headless agents have no pane and clear on
`UserPromptSubmit`; an abandoned, never-resumed session's marker lingers until
someone resumes it once (the original proposal's accepted limitation — the
price of no polling).

**Events.**

- `alert-bell` → `notify add --kind bell` (this hook moves out of
  `32_visual.conf` into the plugin).
- Claude Code hooks in `~/.config/claude/settings.json`, registered beside but
  **perpendicular to** the harness's lifecycle hooks (harness.md): same
  carrier (the `hooks` block), different axis — outward telemetry vs behavior
  patching (`herdr-agent-state.sh` is the precedent). Own `matcher`s
  (`Notification`, `UserPromptSubmit`); handlers point at the plugin path,
  never under `~/.config/claude/hooks/`; pure signal: cheap, early exit, no
  context injection.
  - `Notification`, for `notification_type` ∈
    {permission_prompt, idle_prompt, agent_needs_input} → `notify add --kind
    agent`. In-pane (`$TMUX`/`pane_id`): action `select-pane -t <pane>`.
    Headless (no pty): action `claude --resume <session_id>`.
  - `UserPromptSubmit` → `notify clear --session <session_id>`.

## Replacements

`scripts/bell-flash` (its detach-ringing folds into `notify add`'s bell path),
`scripts/bell-menu`, `BELL_TRAY`, and `32_visual.conf`'s `alert-bell` hook all
retire. The `window_bell_flag` tab blink (`window-status-bell-style`) and the
`session_alerts` title stay — the per-window complement to a server-wide tray.

## Prerequisite

tmux ≥ 3.8 installed (this box currently runs 3.7c).

## Accepted limitations

- One floating toast per window at a time; rapid-fire events dedupe by key and
  a new toast replaces the previous one.
- The tray renders via `#()`, so a change lands up to one `status-interval`
  (1s) late, and the first render after a change shows the stale value.
- A floating-pane toast briefly overlaps whatever you're typing in; it is
  non-modal and `-d`, so it disturbs nothing, and the "target is the focused
  pane" rule suppressses the pointless case entirely.

## If this gets built

1. Confirm `tmux -V` reports ≥ 3.8 (the gate) and probe the geometry flags
   and `-T`/`-B` on a throwaway server (`tmux-testing` skill).
2. Scaffold `~/Projects/tmux-notify` (`notify.tmux`, `scripts/notify`), then
   exercise the store and CLI standalone with `TMUX_NOTIFY_DIR` pointed at a
   tmpdir.
3. `tester` agent on an isolated `-L` socket: store CRUD, `tray`/`menu`
   output, toast `new-pane -d` geometry and auto-close, clear-on-focus, no
   double hook registration across `reload-config`; stub the agent jump
   actions with `echo` so nothing real is spawned.
4. Wire the glue (`90_plugins.conf` run-shell, `32_visual.conf` tray slot,
   `20_keybinds.conf` `Prefix n`, `22_mouse.conf` `MouseUp1Control7`) and the
   claude hooks; run `/hooks` once if they don't fire on the next real event —
   the settings-file watcher only tracks directories that had a settings file
   when the session started.
5. Promote to `docs/adr/0081` (next free number as of this deferral) once
   it's no longer a proposal, and delete this file and its `docs/BACKLOG.md`
   entry.