---
name: tmux-config
user-invocable: false
description: Use when writing or debugging tmux configuration — a binding, the status line, a pane title, a theme, a plugin, or a value that expands to the wrong thing.
---

# Tmux Config

Reading, editing and debugging the tmux setup.
Anything that needs a running server is `tmux-testing`; never the user's live session.

## 1. Consult authoritative sources first

`references/` holds worked-out answers to the questions that cost the most time to rederive.
Check it before `man tmux` or the web:

- `references/variable_expansion.md` — when `$VAR`, `#{format}`, and `@user-options` each get substituted.
  Read this before debugging anything where a value comes out empty, stale, or expanded one level too early.
- `references/formats.md` — the vocabulary inside `#{...}`: conditionals, matching, modifiers, and how to escape a literal `,` or `}`.
- `references/headless_hooks_and_errors.md` — how tmux routes errors across execution contexts, why headless hooks fail with `(null):0: no current client`, and how to write client-safe hooks.

Beyond that:

- Page `man tmux` with `cat`/`grep` or redirect it to a file — it is too long to read whole.
- Run `tmux -V` before trusting any option: syntax and available formats vary by version.
- Search upstream with `gh search issues ... repo:tmux/tmux` and `gh issue view <n> --repo tmux/tmux`; the maintainer (nicm) often explains the exact mechanism in the comments.

## 2. Directory architecture

`tmux.conf` glob-sources individual config files from `conf.d/`.
Supporting scripts live in `scripts/` and must be executable.
Give each discrete topic (keybindings, theme, plugins) its own `.conf` file rather than extending an unrelated one.

## 3. Configuration practices

- **Performance**: limit the use of `#()` in status lines if they cause lag.
  Use robust scripts with caching where appropriate.
- **Clarity**: unbind default keys explicitly before rebinding them if the behavior changes drastically.
- **Conflicts**: before adding a binding or option, check it against tmux defaults and the existing `conf.d/` files.
- **Colour**: tmux style directives (`fg=`, `bg=`) take explicit gruvbox hex from `conf.d/30_gruvbox.conf`, which is the single source of truth -- tmux has no concept of the terminal's ANSI theme to defer to.
  Scripts whose output prints straight to the terminal use plain ANSI 16-colour escapes (`\e[31m`) instead: the terminal emulator already implements gruvbox at that level, so hardcoding hex there duplicates the palette and pins it in place.
