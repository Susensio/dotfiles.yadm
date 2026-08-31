# Tmux Variable Expansion — When Does What Get Substituted?

Tmux has **three different variable systems** that expand at **different times**.
This is the root cause of most debugging pain.

---

## The Three Systems

### 1. `$VAR` — Expanded at **parse time** (when config is read)

These are substituted **once**, the moment tmux reads the line.
The value is baked in.
If the variable doesn't exist yet, it becomes an empty string silently.

Sources for `$VAR`:
- Shell environment inherited by the tmux server
- `set-environment -g VAR value` (server environment)
- `%hidden VAR=value` (config-only, not passed to children)

```bash
# These are identical AFTER parsing:
%hidden FOO="hello"
display "$FOO"          # → display "hello"    (already substituted)

set-environment -g BAR "world"
display "$BAR"          # → display "world"    (already substituted)
```

> [!IMPORTANT]
> `$VAR` substitution happens **as the file is read, line by line**.
> If you `set-environment` on line 5 and use `$VAR` on line 3, it won't work — line 3 was already parsed.

### 2. `#{format}` — Expanded at **runtime** (when the command executes)

These are **live queries** evaluated every time the command runs.
They can read session state, window state, pane state, options, and environment.

```bash
# This is evaluated fresh every time the status bar renders:
set -g status-left "#{session_name}"

# This is evaluated when the key is pressed:
bind x display "#{pane_current_path}"
```

### 3. `%hidden VAR=value` — Available **only during config parsing**

These exist purely for config-time `$VAR` expansion.
They are not environment variables — child processes and `#{format}` can't see them.

```bash
%hidden COLOR="#ff0000"
set -g status-style "fg=$COLOR"   # ✅ works: $COLOR expanded at parse time
display "#{COLOR}"                # ❌ empty: formats can't see %hidden vars
```

---

## The Crucial Question: Which Commands Expand `#{}`?

**Not all commands expand formats.**
This is where most bugs come from.

### Always expand formats (in specific arguments):
| Command | Which argument |
|---------|---------------|
| `display-message` | the message string |
| `if-shell -F` | the condition (with `-F`, no shell) |
| `run-shell` | the shell command string |
| `command-prompt` | the prompt and template |
| `set -F` / `set -aF` | the value (with `-F` flag) |
| `source -F` | the filename (with `-F` flag) |
| `status-left`, `status-right` | always (rendered each interval) |
| `window-status-format` | always (rendered each interval) |
| `set-titles-string` | always (rendered on change) |
| Hooks | the command inside the hook |

### Do NOT expand formats (without `-F`):
| Command | What happens instead |
|---------|---------------------|
| `set option value` | stored literally, `$VAR` expanded at parse time |
| `bind key command` | command stored literally, expanded when key is pressed |
| `set-hook command` | command stored literally, expanded when hook fires |
| `set-environment` | value stored literally, `$VAR` at parse time |

---

## How Your Config Uses This

### Example 1: `tmux.conf` line 1
```bash
set-environment -ghF TMUX_CONFIG_DIR "#{d:current_file}"
```
- `-F` forces format expansion **now** (at parse time)
- `#{d:current_file}` resolves to the directory of the file being parsed
- Without `-F`, it would store the literal string `#{d:current_file}`

### Example 2: `15_aliases.conf`
```bash
set -a command-alias scratchpad="run '$TMUX_SCRIPTS_DIR/scratchpad --client #{client_tty} 2>&1'"
```
Two expansions happen at **different times**:
1. **Parse time**: `$TMUX_SCRIPTS_DIR` → `/home/you/.config/tmux/scripts`
2. **Runtime** (when alias is invoked): `#{client_tty}` → `/dev/pts/3`

After parsing, the stored alias is:
```
run '/home/you/.config/tmux/scripts/scratchpad --client #{client_tty} 2>&1'
```
Then `run` expands `#{client_tty}` when it executes.

### Example 3: `30_gruvbox.conf` + `31_visual.conf`
```bash
# In 30_gruvbox.conf:
%hidden BG0="#282828"

# In 31_visual.conf:
set -g window-active-style fg=$FG0,bg=$BG0
```
- `$BG0` is expanded at parse time → `fg=#fbf1c7,bg=#282828`
- The hex color is baked into the option permanently
- `%hidden` is perfect here: colors are constants, not runtime state

### Example 4: The `pane-exited` hook
```bash
set-hook -ga pane-exited { if -F "#{&&:#{@auto_equalize},#{==:#{hook_window},#{window_id}}}" "equalize-panes" }
```
- The `{ }` braces store the command **literally** (no parse-time expansion)
- When the hook fires, `if -F` expands all the `#{}` formats **at that moment**
- `#{hook_window}` = the window where the pane exited
- `#{window_id}` = the *current* window (which may be different!)

### Example 5: `source -F`
```bash
source -F "#{TMUX_CONFIG_DIR}/conf.d/*.conf"
```
- `-F` expands `#{TMUX_CONFIG_DIR}` as a format (reads from environment)
- The comment in your config explains why: `#{d:current_file}` is a format that only works during parsing, so you first stored it in the environment with `set-environment -ghF`, then retrieve it with `#{}` format expansion

---

## Common Traps

### Trap 1: `$VAR` in `set` vs `set -F`
```bash
set-environment -g MY_PATH "/tmp/foo"

set -g status-right "$MY_PATH"     # ✅ "/tmp/foo" (parse-time $VAR)
set -g status-right "#{MY_PATH}"   # ✅ "/tmp/foo" (runtime format, reads env)

# But if MY_PATH changes later, only #{} version updates!
```

### Trap 2: Quotes matter for `$VAR`
```bash
%hidden X="hello"
display '$X'    # → literal "$X"  (single quotes prevent $VAR expansion)
display "$X"    # → "hello"       (double quotes allow it)
```

### Trap 3: `{ }` braces defer EVERYTHING
```bash
%hidden COLOR="red"
bind x { display "$COLOR" }    # ❌ $COLOR is NOT expanded at parse time
bind x display "$COLOR"        # ✅ $COLOR IS expanded at parse time
```
Braces `{ }` create a command list that is stored **verbatim**.
No `$VAR` expansion happens inside braces at parse time.
Use `#{}` format expansion instead, or expand outside the braces.

### Trap 4: `if` without `-F`
```bash
if "#{session_attached}" { ... }     # ❌ runs "#{session_attached}" as shell!
if -F "#{session_attached}" { ... }  # ✅ evaluates as tmux format
```
Without `-F`, the condition is a **shell command** (exit code 0 = true).
With `-F`, it's a **format string** (non-empty/non-zero = true).

---

## Quick Decision Flowchart

```
Need a value from tmux state (session, window, pane)?
  → Use #{format} — it's resolved at runtime

Need a constant (color, path prefix, feature flag)?
  → Use %hidden + $VAR — it's baked in at parse time

Need a value that updates over time (status bar)?
  → Use #{format} — it re-evaluates on each render

Need to pass a tmux value to a shell script?
  → Use #{format} inside run-shell: run 'script #{pane_id}'

Need to conditionally run tmux commands?
  → Use if -F "#{condition}" { commands }  (not if without -F)
```
