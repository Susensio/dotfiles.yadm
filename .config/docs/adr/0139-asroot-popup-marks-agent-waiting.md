# ADR-0139: Mark the agent's herdr pane as waiting while asroot's sudo popup is open: pi through its herdr:blocked channel, Claude through a statusline marker and a generated detection override, instead of a separate state report

Status: Accepted
Date: 2026-11-27

## Context

ADR-0134's sudo popup only announced itself through a herdr toast, which goes unseen when the terminal is not focused.
A permission prompt instead turns the agent's pane to `blocked`: the sidebar marker, the rollup, and the request sound.
The popup was expected to behave the same.

Measured against herdr 0.9.5 and Claude Code 2.1.322 on 2026-11-27:
- While an integration holds a pane, herdr silently ignores `pane.report_agent` from any other source, whatever the `--agent` label; pi's integration owns pi panes, and Claude panes are held by `herdr:claude` even though their state comes from the screen.
- Reporting under an integration's own source collides with its sequence numbers: pi numbers reports from its load time, so one report stamped with the current time would make herdr drop pi's later ones.
- Claude's state is screen detection; its terminal title spins during a tool call, and herdr's title rule (priority 1100) outranks the blocked-form rules (980).
- A local manifest override replaces herdr's rules for that agent outright, and `herdr server reload-agent-manifests` drops every agent pane to `unknown` until its screen next changes.
- Claude's `refreshInterval` reruns the statusline mid-tool; between events only `cost.total_duration_ms` changes in its input.

## Decision

`sudo-askpass` writes `$XDG_RUNTIME_DIR/asroot-waiting/<HERDR_PANE_ID>` holding its PID while a herdr popup is open; readers trust it only while that PID lives.

- Pi: the `asroot-waiting` extension watches the flag and emits `herdr:blocked`, the channel pi's herdr integration already serves for ask_user and permission dialogs.
- Claude: the statusline entry `statusline-refresh.sh`, rerun every second, prints `asroot: password in the sudo popup` while the flag is live, and reruns `statusline.sh` only when the input changed beyond the duration.
  A local detection override adds one rule (priority 1200) that matches that text below the last horizontal rule.
  `herdr/scripts/claude-rules`, from Claude's SessionStart hook, regenerates the override from herdr's cached Claude rules and reloads herdr only when the result differs; a hand-written override is left alone.

## Consequences

The override stays installed permanently, so a reload happens only when herdr's Claude rules change, not per popup.
Herdr's rule updates for Claude reach detection only at the next Claude session start; when the bundled manifest is newer than the cached remote one, the override keeps the cached one.
Each Claude session runs its statusline entry every second, about 20 ms per tick when nothing changed.
The marker shows within a tick of the popup opening; the pane returns to `working` within a tick of it closing.
tmux popups and panes outside herdr get no flag.
