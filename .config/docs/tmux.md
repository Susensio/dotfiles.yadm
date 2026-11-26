# tmux facts

Measured facts about the installed tmux that the config depends on; open work is in the `tmux |` entries of [BACKLOG](BACKLOG.md).

Where tmux knowledge lives:

| What | Where |
| --- | --- |
| What the config does and how to use it | [`tmux/README.md`](../tmux/README.md) |
| Installed-version facts, upstream status, tested costs (this file) | `docs/tmux.md` |
| Version-generic mechanics (format expansion, formats, headless hooks), verified on 3.7b | `claude/skills/tmux-config/references/` |
| How to test against a throwaway server | `claude/skills/tmux-testing/` |
| Why it is built this way | `docs/adr/` (`tmux`, `which-key`, key-table decisions) |
| Planned features | `docs/plans/tmux-notify.md` |

## Floating panes and the scratchpad

Researched 2026-11-25 against tmux 3.8 (installed) and master (`next-3.9`, head `dace7f5b0`); master was not run, its claims come from source and PRs.
3.9 has no release date, milestone or CHANGES section yet.

1. **`display-popup` is already a modal floating pane on master.**
   The overlay code was removed in `34cd5da4` (nicm, 2026-09-21), and `cmd-display-menu.c` spawns `FLOATING|MODAL|FLOATOVERZOOM`.
   On 3.8 it is still the overlay.
   nicm warns that the floating pane needs `TMUX=` for a nested tmux, because his recipe attaches to the same server ([#5135](https://github.com/tmux/tmux/issues/5135), comment 5341139670).
   Tested on 3.8: `TMUX` is set in both the popup and a `new-pane -O -K` pane, and a plain `tmux -L <scratch> attach` still works in both.
   The refusal ("sessions should be nested with care, unset $TMUX to force") fired only when the attach ran inside a pane of the target's own server.
   The scratchpad attaches to a different server, so no `env -u TMUX` guard is needed; it is harmless if added.
   What does change in 3.9 is scope: the popup becomes window-scoped (fact 2), so re-test the scratchpad then.
2. **A floating pane is a layout cell in one window.**
   There is no request, PR or plan for session-, client- or sticky-scoped floats.
   The nearest thread, [#5535](https://github.com/tmux/tmux/discussions/5535) (link one terminal into several panes), is closed and locked.
   The second server stays, because nicm's own answer for scratch sessions is a nested tmux in a floating pane: `new-pane -OK -X10% -Y12% -x80% -y75% 'env TMUX= tmux new-session -A -s scratch'`.
3. **A parking-window toggle works on 3.8 with one server.**
   Tested in a throwaway server: pane id, PID, shell variables and a background loop survived every move, across windows, sessions and detach/reattach.
   Show: `join-pane -d -s $P -t $W \; break-pane -W -d -s $P -x 60% -y 50% -X 10% -Y 10% \; select-pane -t $P`.
   Hide: `break-pane -d -s $P -t <session>: -n scratch` (always pass `-t <session>:`).
   Costs:
   - Floating and geometry are lost on every park, so pass them on each show.
   - There is no hide state, so moving is the only hide.
   - It cannot be modal: `-O` only applies at creation, and modal panes cannot be moved.
   - It fails in a zoomed window.
   - The pane shows briefly as a tiled split; flicker was unobserved without a real display.
   - There are no isolated key tables or session lists.
   - Untested: percentage geometry, `-A` over zoom, several clients on one session.

   Revisit only if the second server hurts, since 3.9 changes zoom and floats underneath it.
4. **Hidden panes are not in 3.8 and may not reach 3.9.**
   `hide-pane`/`show-pane` is draft [#5402](https://github.com/tmux/tmux/pull/5402).
   [#5669](https://github.com/tmux/tmux/pull/5669) (hidden panes, stacked on [#5668](https://github.com/tmux/tmux/pull/5668) zoom and floating) and [#5856](https://github.com/tmux/tmux/pull/5856) (hooks) are open.
   nicm: "I am not sold on hidden panes".
   The roadmap, [#5406](https://github.com/tmux/tmux/issues/5406), lists zoom with floating panes as probably 3.9 and hidden panes as potentially.
   Hidden is still per window, so it would not make a float follow you.
5. **3.8 floating-pane bugs.**
   [#5384](https://github.com/tmux/tmux/issues/5384) (closed): a `run-shell` binding that creates a floating pane and waits on it deadlocks key input; use `new-pane -W`.
   Open: [#5892](https://github.com/tmux/tmux/issues/5892) (a lone float cannot be zoomed) and [#5906](https://github.com/tmux/tmux/issues/5906) (popup output lost on a deferred redraw).
   The `run` aliases are the reason to leave the popup callers alone until 3.9.

### `new-pane` vs `popup` for the scratchpad (tested on 3.8)

Same: both run the nested attach, close on detach, pass every key including the prefix to the nested client, and restore the previous pane on close.
Different:
- `popup -c <client>` becomes `new-pane -t "$(tmux display -c <tty> -p '#{pane_id}')"`.
- The float is a real pane, so it shows in `list-panes` and the status line.
- It is bound to one window: switching windows hides it, which a popup does not.
- A second modal pane errors: `window already has a modal pane`.
- `-O` draws above a zoomed pane without `-A`.
- The toggle-off `detach -t <A's tty>` fails (`can't find client`) because the scratch client has its own tty; the script's bare `tmux detach` fallback works.
- Borders use the pane-border options, not `-b`/`-s`.

Adopted 2026-11-25: `scripts/scratchpad` opens with `new-pane -O -K` (80%x85%, `popup-style` applied to content and borders).
Tested on 3.8 against the real script on throwaway sockets: open, keys including the prefix, toggle-off with the scratch session surviving, named scratchpads, `clean`, panes with a zoomed window.
Costs found:
- `-B rounded` is rejected on 3.8 (`pane-border-lines unknown value: rounded`), so the border is `single` where the popup was rounded.
  Master's `pane-border-lines` lists `rounded` (`options-table.c`, read 2026-11-25, not run), so it should arrive with 3.9; a `TODO:` in `scripts/scratchpad` marks the line to switch.
- `#{window_panes}` counts the float, so `32_visual.conf`'s `>1` zoom/close button range shows on a single-pane window while the scratchpad is open (mouse on only).
- The float's border renders `pane-border-format`, with the index and `pane-title` expansion.

Not verified: rounded borders on a newer build, the real `32_visual.conf` and `pane-title` output, the `M-\`` binding with no `--client`, and the scratch-side `S` bind.
