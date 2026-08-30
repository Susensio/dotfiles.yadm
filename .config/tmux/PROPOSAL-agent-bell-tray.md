# Proposal: bell tray for headless agent-view sessions

Not implemented. A design write-up, not a decision — see `docs/BACKLOG.md`.

## Problem

Claude Code sessions started via `--bg`/`/background` (the agent-view
daemon, managed through `claude agents`) have no pty at all. The existing
notification pipeline — `preferredNotifChannel: "terminal_bell"` writes a
BEL character to the session's own stdout, tmux's `monitor-bell` +
`alert-bell` hook (`conf.d/31_visual.conf`) parses it from the pane's
output and lights up `BELL_TRAY`, clickable via `scripts/bell-menu` — only
works because there's a pane whose output tmux is continuously reading.
A headless session has no pane, so none of that ever fires. The only way
to notice one wants attention today is to manually run `claude agents`.

Sessions that *do* run in a tmux pane are already fully covered by that
existing pipeline — this proposal doesn't touch it.

## Rejected approaches

- **Desktop notification** (`notify-send` from a `Notification` hook) —
  solves "I'm not looking at tmux at all," which turned out not to be the
  actual problem; out of scope for this proposal.
- **Polling `claude agents --json`** — measured at ~1.8–2.3s per
  invocation (a full CLI cold start, not a lightweight daemon query), far
  too slow for a 1s status-bar refresh. Its `state` field also isn't a
  reliable "needs attention" signal: it read `"blocked"` even for a
  session that was actively mid-turn, suggesting it means roughly "not
  currently streaming tokens" rather than "waiting on you."

## Prior art

Researched existing tmux + Claude Code status integrations
(claude-squad, happy-coder, ccstatusline, opensessions, and others). The
mature pattern — e.g.
[tmux-agent-status](https://github.com/samleeney/tmux-agent-status) — is
hook-driven state *files* that later hook events simply overwrite. No
poll loop, no explicit delete logic: `UserPromptSubmit`/`PreToolUse` mark
a session "working", `Stop` marks it "done", `Notification` marks it
"wait", and the status bar just reads the cached files.

## Design

Scaled down to what this repo actually needs — a single bell, not a full
working/done status line — and grafted onto the existing `BELL_TRAY`
instead of a new icon:

**New script `tmux/scripts/agent-notify`** (same `set -eu` / `DEBUG=1`
convention as `bell-flash`/`bell-menu`), invoked as
`agent-notify <EventName>` from two hook events sharing one script:

- Read `session_id` from the hook's stdin JSON (present on every event).
- If `$TMUX` is set, the session has a real pane — the existing
  `terminal_bell` path already covers it, exit 0 immediately (matters
  most for `UserPromptSubmit`, which fires on *every* prompt submit
  across every session, so bail before any real work).
- `Notification`, only for `notification_type` ∈
  `{permission_prompt, idle_prompt, agent_needs_input}`: write
  `~/.cache/claude/agent-alerts/<session_id>`, content = the `cwd`
  basename from the payload (for the menu label).
- `UserPromptSubmit`: `rm -f` that same marker. This is what fires the
  instant the user resumes the session and sends a message — i.e. exactly
  "attending to it now" — so the marker clears itself with no polling and
  no separate cleanup pass.

**`BELL_TRAY`** (`conf.d/31_visual.conf`) gets one more condition ORed in:
does `~/.cache/claude/agent-alerts/` have any entries? A directory
existence check (`find ... -maxdepth 1 -mindepth 1 -print -quit`), not a
CLI spawn — negligible against the already-1s `status-interval`.

**`bell-menu`** gets one more entry per marker file, alongside the
existing detached-window bell entries: label = stored cwd basename,
action = `display-popup -E "claude --resume <session_id>"` (`--resume`
takes a session ID directly, confirmed via `claude --help` and
`claude agents --json`, which reports the same UUID as `sessionId`).

**`~/.claude/settings.json`** (global) — `hooks.Notification` and
`hooks.UserPromptSubmit` both point at `agent-notify`, passing the event
name as `$1`.

## Accepted limitation

A marker for a session that's abandoned outright — never resumed at all —
has nothing to clear it; it sits in the tray until someone eventually
resumes it once. Narrower than it sounds (only truly-abandoned sessions,
not every resumed one), and closing it means reintroducing either a poll
or a staleness timer for what's a cosmetic tray icon. Not worth it.

## If this gets built

1. Pipe-test `agent-notify` directly for both events, with `$TMUX` set and
   unset, confirming marker create/remove and the early-exit path.
2. `jq -e` the hook entries in `~/.claude/settings.json` after adding them.
3. Verify `BELL_TRAY` lighting up and `bell-menu` listing/opening a seeded
   marker against an isolated `-L <socket>` tmux server (never the live
   session) — this repo's `tmux-testing` skill via the `tester` agent.
   Stub the `claude --resume` call (e.g. substitute `echo`) so the test
   doesn't spawn a real session.
4. After adding the hooks, `/hooks` once (or restart) if they don't fire
   on the next real event — the settings-file watcher only tracks
   directories that had a settings file when the session started.
