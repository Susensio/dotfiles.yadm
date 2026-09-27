# ADR-0059: Keys the herdr scratchpad on workspace-ID sessions under a shared `_scratchpad` socket, with no cleanup and a shim instead of the full tmux config

Status: Accepted
Date: 2026-09-27

## Context

The herdr `` alt+` `` popup script ran one tmux session per workspace ID on a single shared server (`tmux -L herdr_scratchpad new-session -A -s "$WORKSPACE_ID"`), with no guard against attaching into another workspace's scratch, no chrome control, and no invariant caller context: a workspace lookup without a fallback produced a literal `null` session in practice.

The tmux-native scratchpad (ADR-0015) keys its scratch by originating `session_id` on a `_scratchpad`-suffixed socket, strips chrome via a socket guard in `conf.d/50_scratchpad.conf`, closes by having the same keybinding loaded on the scratch server, and cleans on `session-closed`. Those mechanics transfer to herdr only partially: tmux popups and herdr popups are alike in being modal (the binding that opens a popup cannot fire while it is open, so the close key must live inside the thing it opens), but herdr popup processes inherit their caller context at launch only and cannot re-resolve it, tmux has no hook that fires when a herdr workspace closes, and herdr has no primitive that hosts a persistent non-tiled pane — popups have no pane ID, emit no lifecycle events, and close and exit their process together, so tmux-in-herdr stays necessary.

Keying schemes weighed:

- a workspace **label** key (`_config`, `_herdr`): readable names, but not derivable from an ID without a lookup (herdr exposes no label sidecar on `tab get`), forcing an owners sidecar plus a self-healing read and GC on the hot path of a keybinding popup;
- the workspace **ID as the tmux session name** on a shared server: herdr never reuses workspace IDs, so a session name permanently identifies its workspace and needs no lookup;
- the workspace **ID in the socket name** (one server per workspace, constant session): explored in detail, but without a GC hook its leaks are no more attributable than session names given never-reused IDs, and it costs one tmux process per workspace while departing from the tmux-native topology.

## Decision

Mirror the tmux-native scratchpad: one shared server on `herdr_scratchpad`, one session per herdr workspace named after the workspace ID, addressed only through `=` exact-match targets (tmux target resolution otherwise falls back to prefix and glob matching, and `w5` would reach a session named `w50`). The mapping rests on herdr never reusing workspace IDs, so orphaned sessions stay unambiguous against `herdr workspace list`.

The key comes from the popup's launch-baked caller context: `HERDR_ACTIVE_WORKSPACE_ID` (popup commands) with `HERDR_WORKSPACE_ID` (pane children) as fallback, then a refusal — never a guess. Server config comes from an `-f` shim next to the script that sources only tmux's own `conf.d/50_scratchpad.conf`, so chrome stripping, `detach-on-destroy`, and the `window-unlinked` detach keep their single source of truth, while TPM boot, plugins, and the main key surface stay off these popups. The shim supplies what the sourced file cannot under herdr: fish as default shell (popup env carries no `$SHELL`), `` alt+` `` as the in-popup toggle, and a rebind of the native `S` delegation to plain detach, since the parent tmux socket it targets does not exist under herdr.

## Consequences

Every workspace, including worktree workspaces (separate IDs), gets an independent scratch session under the shared server, chromeless and fish-shelled. Cross-workspace attach requires an exact session-name match; the tmux-side `$ENV` leakage possible on shared servers is limited to deliberate in-session mutations, since the shim loads no env-pushing config.

No cleanup mechanism exists. Closing a herdr workspace leaves its session running in the shared server, identifiable against `herdr workspace list`; sessions die only at reboot or a manual `kill-session`/`kill-server`. This is a deliberate absence: GC logic on a hot-path popup was rejected as disproportionate, and the tmux-native `session-closed` hook has no herdr equivalent.

Shared tmux global state (`set-environment -g`) is common to all workspaces' scratch sessions; the shim loads no config that mutates it, and in-session mutation is deliberate and user-visible.

A herdr change that stops popup commands from receiving the `HERDR_ACTIVE_*` caller context breaks the binding loudly (the script exits with a message), not silently. The shim's toggle and the sourced tmux branch are two views of one contract: changes to the tmux file's guard or branch shape reach herdr's popups with them — the point of sourcing it — while changes to the herdr env contract surface as the refusal message instead of a wrong-workspace scratchpad.

Switching herdr workspaces while a scratch popup is open leaves the tmux client attached invisibly; `` alt+` `` is a herdr-level toggle, not a tmux-level one.
