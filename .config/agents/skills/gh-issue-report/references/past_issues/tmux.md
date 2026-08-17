# Past issues corpus (Susensio, github.com/tmux/tmux)

Repo-specific evidence backing `../voice.md`, and the concrete authority for
tmux/tmux specifically. Pulled via `gh issue view <n> --repo tmux/tmux`.
Re-run that if you need a comment thread or exact wording beyond what's
excerpted here — do not treat this file as more current than the live issue.

## #4985 — Feature Request: Preserve originating context in hooks (closed)

```
### Issue description

Currently, when a pane is destroyed, pane-level hooks (`pane-exited`, `after-kill-pane`) lose their original window context if the destroyed pane was the last pane in that window.

Because Tmux destroys the empty window and shifts focus to the next available window before executing the hook queue, the hook implicitly runs in the context of the newly focused window. This makes it impossible to safely execute scoped layout commands (like `select-layout -E`) on pane death without resorting to `remain-on-exit` hacks.

Hook variables exist `hook_{pane,window,session,...}` but they are only sparsely populated: if a `pane-exited` hook is fired, only `hook_pane` has information.

### Desired Behavior

There should be a way to programmatically identify the full context where a hook was fired, without dropping the _upper_ context. That is,

- `pane` hooks should populate `hook_{pane,window,window_name,session,session_name}`
- `window` hooks should populate `hook_{window,window_name,session,session_name}`
- `session` hooks should populate `hook_{session,session_name}`

The logic of this may be implemented in:

https://github.com/tmux/tmux/blob/31d77e29b6c9fbb07d032018da78db3a8a38d979/notify.c#L179-L227

maybe with something like
```c
if (w != NULL) {
        format_add(ne->formats, "hook_window", "@%u", w->id);
        format_add(ne->formats, "hook_window_name", "%s", w->name);
} else if (wp->window != NULL) {
        format_add(ne->formats, "hook_window", "@%u", wp->window->id);
        format_add(ne->formats, "hook_window_name", "%s", wp->window->name);
}
```

### Required information

* tmux version `3.6a`
* Platform `Linux x86_64`
* Terminal in use: `Gnome Terminal`
* $TERM *inside* tmux `tmux-256color`
* $TERM *outside* tmux `xterm-256color`
```

No logs — this is a feature request, not a reproducible bug.

## #4984 — Rebind prefix does not work (closed)

```
### Issue description

I expect that the tmux default binding does something like `switch-client -T prefix`. I would like to hook into that to add my custom logic. But rebinding the prefix does not work, it appears that `prefix` variable intercepts the keybind.

```
unbind C-b
set -g prefix C-Space      # <------ Problematic line
bind -n C-Space 'display "Prefix pressed"; switch-client -T prefix'
```
`Prefix pressed` is never shown, the keybind is not working.

If I don't `set -g prefix C-Space`, it works but some other things get messed up (and probably more than I haven't run into):

- output of `tmux list-keys -N`
- `client_prefix` variable

### Required information

* tmux version `3.6a`
* Platform `Linux x86_64`
* Terminal in use: `Gnome Terminal`
* $TERM *inside* tmux `tmux-256color`
* $TERM *outside* tmux `xterm-256color`
* Logs from tmux (relevant part): <details>...trimmed excerpt around the key press, not the full -vv capture...</details>
```

Note the inline annotation `# <------ Problematic line` pointing straight at
the offending config line. Logs present but hand-trimmed to the relevant
window, wrapped in `<details>`.

## #4012 — `previous-prompt -o` does not work on the same line (closed)

```
### Issue description
Jump to the beginning of the current command output does not work as expected. When inside a command output, it should go to the the beginning of the same output, but it goes 1 prompt too far.

### Steps to reproduce

```
tmux kill-server; tmux -vv -L test -f /dev/null new bash
```
```
PS1='\[\e]133;A\e\\\]$ ' # prompt start
PS0='\[\e]133;C\e\\\]'   # command output start
```
```
echo 1111
```
```
echo 2222
```
```
Ctrl+B [                          # enter copy-mode
k                                 # jump to the end of line with the 2222 output
Ctr+B :send -X previous-prompt -o # this should jump to the start of the line with the 2 output, but goes up to 1111
```

`previous-prompt` (without `-o`) works fine

https://asciinema.org/a/j4wyrcsKscalH51bebDnRU5Bq

### Required information

tmux next-3.5
Linux unknown
tmux-256color
```

Note: split the repro into several small fenced steps rather than one block,
because each step needed a comment explaining what to look at. Linked an
asciinema recording instead of describing the visual behavior in prose.
Required-information block was terse — one line each, no bullets, no logs
even though `-vv` was used to build (this is not a crash, just a copy-mode
behavior question).

Maintainer thread: nicm explained the line-based grid model made the request
infeasible as literally asked, then offered a workaround
(`start-of-line` + `jump-forward`). Susensio thanked him, adapted it into a
concrete keybinding, and closed out — didn't argue the point further once the
maintainer explained the underlying constraint.

## #3808 — Cannot use `#{session_path}` inside `automatic-rename-format` (closed)

```
# Issue

I want to use `session_path` inside `automatic-rename-format`, but the variable never gets substituted.

Example command:
```bash
 tmux -Ltest kill-server; tmux -v -f/dev/null -Ltest set-option -g automatic-rename on \; set-option -g automatic-rename-format "#{session_path}" \; new \; display-message -pF "#{session_path}"
```
`session_path` gets printed, but the window does not rename correctly. It gets an empty name.

logs for `display-message`:
```
...4-line trimmed excerpt...
```

logs for window renaming:
```
...4-line trimmed excerpt showing 'format_replace: format 'session_path' not found'...
```
```

Two short log snippets placed directly under the description, each captioned
by what it's log *of* (`logs for display-message` vs `logs for window
renaming`) — used to prove the two code paths diverge, not as a blanket
attachment. Required-information block still present at the bottom inside
`<details>`, no full `-vv` file. (Note: this one used `# Issue` instead of
`### Issue description` — the template heading isn't followed to the letter
every time, but the *content* — problem statement, repro, required info — always
is. Prefer the literal template heading unless there's a similar reason to
deviate.)

Maintainer thread: nicm explained the root cause in one sentence
(`automatic-rename` operates on a window, doesn't know its session) and
attached a candidate diff. Issue closed without Susensio needing to reply —
not every thread needs a reply once the explanation is complete.

## #3776 — Server exited unexpectedly when `switch-client` from `pane-died` hook (closed)

```
### Issue description
I'm trying to create a custom `detach-on-destroy` behaviour because default options are not sufficient for my use case.
So I want to intercept session closing and switch to another session.
**Server crashes** when running the following command:
```bash
tmux -Ltest kill-server; \
tmux -f/dev/null -Ltest \
  set -g remain-on-exit on \; \
  set-hook -g pane-died "switch-client -p" \; \
  new \; \
  new \; \
  send exit Enter
```
The command creates an empty server, changes some options, spawns two sessions and kills the later. Hook should switch to the former, but `[server exited unexpectedly]` is received.

The following command **does work** (the only change is `send exit Enter` for `send ^c`):
```bash
...
```

And using the native `detach-on-destroy` also works:
```bash
...
```
but this is **not enough** because...

### Context
I want to mimic `detach-on-destroy no-detached` but using a custom filter. I want to filter out, not only attached sessions, but also other sessions based on some custom option.

So in the example above, `switch-client -p` would be a script that

0. Checks if the pane is the last of the current session
1. list all tmux sessions
2. filters out attached sessions
3. filters out sessions based on custom session option
4. sort by most recent used
5. switch to that session or detach if not found.

That way, I can manage a subset of `@hidden` sessions such as _scrachpads_, _persistent popups_, etc. without landing of them unless explicitly switched to.

Everything else is relatively easy and I got it working: `switch` between filtered sessions, `choose-tree` with filter... I can hide my `@hidden` sessions in every place but I keep failing with `detach-on-destroy`...

Maybe there is another way of accomplishing what I'm after?

### Required information
<details>
* tmux version 3.3a
* Platform Linux ...
* $TERM inside/outside ...
* Logs from tmux: [tmux-server-*.log](...) [tmux-client-*.log](...)
</details>
```

This is the only one of the five with full `-vv` log *files* attached (GitHub
file-upload links, not pasted) — because it's a genuine crash, not a logic
bug, and the maintainer needed the whole capture plus a backtrace. Three
minimal repro variants shown side by side (crashes / doesn't crash / native
option that isn't flexible enough) to isolate the trigger precisely, each
one-line different from the last.

Follow-up thread is the longest of the five and shows the debugging-with-a-
maintainer pattern in full: nicm couldn't reproduce, asked for a
build-from-master check → Susensio confirmed still crashes → nicm asked for
"is there a core, what's the backtrace" → Susensio didn't have one, asked
"how can I debug this" → nicm pointed at the FAQ entry rather than
re-explaining it inline → Susensio followed it, got a backtrace, iterated
with nicm (`f 1`, `p *wp`) down to a one-line fix candidate → asked
"Should I submit a PR for this?" rather than assuming → nicm said he'd apply
it himself → applied upstream, thanked.

Pattern for follow-ups in general: quote the relevant fragment of the
maintainer's message with `>`, answer precisely what was asked, don't pad,
offer rather than assume when it comes to next steps (PRs, closing the
issue).
