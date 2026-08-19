# Tmux Format Modifiers — The Vocabulary

`variable_expansion.md` covers *when* things expand.
This covers *what you can write* inside `#{...}`.
Verified against tmux 3.7b.

---

## Conditionals

```
#{?condition,true-branch,false-branch}
```

The condition is true when it is non-empty and not `0`.
Nesting is arbitrary, but every `#{?` needs its own closing `}` — a chain of six rules ends in six braces.

Inside a conditional, literal `,` and `}` must be escaped as `#,` and `#}` — unless they are part of a nested `#{...}` replacement, which is parsed normally.

```
#{?pane_in_mode,#[fg=white#,bg=red],#[fg=red#,bg=white]}
```

## Matching

```
#{m:pattern,string}        fnmatch-style glob
#{m/r:pattern,string}      regex
#{m/ri:pattern,string}     regex, case-insensitive
```

Both are *searches*, not anchored matches.
To match a whole word, pad both the pattern and the subject with spaces:

```
%hidden PANE_CMDS="#{P: #{pane_current_command} }"
#{m/r: (top|htop) ,$PANE_CMDS}    # does not match "topgrade"
```

## String comparison

```
#{==:a,b}   #{!=:a,b}   #{<:a,b}   #{>:a,b}   #{<=:a,b}   #{>=:a,b}
#{||:a,b}   #{&&:a,b}
```

## Substitution

```
#{s|pattern|replacement|:variable}
```

Any delimiter may be used (`|` avoids escaping paths).
The pattern is a regex and **all** matches are replaced.
Useful idiom — collapse a prefix:

```
#{s|^#{@root}/?|./|:pane_current_path}
```

Greedy matching makes "keep everything before the first X" a one-liner:

```
#{s|/.*||:SOMEVAR}      # "AGENT/EDIT/" -> "AGENT"
```

## Loops

```
#{S:...}   over sessions
#{W:...}   over windows
#{P:...}   over panes
#{L:...}   over clients
```

Optional sort suffixes `/i` (index), `/n` (name), `/t` (activity), `/r` (reverse).

Inside a `W:` loop, neighbouring windows' user options are reachable as `next_@name` / `prev_@name`.

## Double expansion

`#{E:option}` expands the *content* of an option rather than the option name.
Required when an option holds a format string that must itself be evaluated:

```
set -g @rules "#{?#{m/r: git ,$PANE_CMDS},GIT,}"
display -p "#{E:@rules}"     # -> GIT     (plain #{@rules} gives the raw text)
```

`#{T:option}` is `E:` plus strftime expansion.

## Escaping and literals

```
#{l:...}    treat content literally, do not expand
#{q:...}    escape special characters
#{qh:...}   also escape "#" as "##"
#{a:...}    escape as a tmux command argument
```

## Basename / dirname

```
#{b:path}   basename
#{d:path}   dirname
#{n:var}    length of the value
```

---

## Traps

**`automatic-rename-format` re-evaluates on pane activity, not on a timer.**
A window whose process is silent (`tail -f /dev/null`) keeps whatever name it had when the pane last produced output.
Not a format bug — do not chase it.

**`#{session_path}` is empty under automatic-rename** (tmux/tmux#3808).
No format recovers it; stash it per window at creation with an `after-new-window` hook.

**`#()` in a format shells out on every evaluation** and returns empty on its first call (the job runs in the background).
Avoid it in `automatic-rename-format` and keep it out of hot status-line paths.
