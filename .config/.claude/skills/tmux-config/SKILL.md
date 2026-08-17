---
name: tmux-config
user-invocable: false
description: Use when writing or debugging tmux configuration — a binding, the status line, a pane title, a theme, a plugin, or a value that expands to the wrong thing.
---

# Tmux Config

Reading, editing and debugging the tmux setup. Anything that needs a running
server is `tmux-testing`.

## 1. Consult authoritative sources first

`references/` holds worked-out answers to the questions that cost the most time
to rederive. Check it before `man tmux` or the web:

- `references/variable_expansion.md` — when `$VAR`, `#{format}`, and
  `@user-options` each get substituted. Read this before debugging anything
  where a value comes out empty, stale, or expanded one level too early.
- `references/formats.md` — the vocabulary inside `#{...}`: conditionals,
  matching, modifiers, and how to escape a literal `,` or `}`.

Beyond that:

- Page `man tmux` with `cat`/`grep` or redirect it to a file — it is too long to
  read whole.
- Run `tmux -V` before trusting any option: syntax and available formats vary by
  version.
- Search upstream with `gh search issues ... repo:tmux/tmux` and
  `gh issue view <n> --repo tmux/tmux`; the maintainer (nicm) often explains the
  exact mechanism in the comments.

## 2. Directory architecture

`tmux.conf` glob-sources individual config files from `conf.d/`. Supporting
scripts live in `scripts/` and must be executable. Give each discrete topic
(keybindings, theme, plugins) its own `.conf` file rather than extending an
unrelated one.

## 3. Configuration practices

- **Performance**: limit the use of `#()` in status lines if they cause lag. Use
  robust scripts with caching where appropriate.
- **Clarity**: unbind default keys explicitly before rebinding them if the
  behavior changes drastically.
- **Conflicts**: before adding a binding or option, check it against tmux
  defaults and the existing `conf.d/` files.

## 4. Verifying a change

Does this binding fire, does this format expand, does this popup render — every
such question needs a running server, so it goes to `tmux-testing`, or to the
`tester` agent with `tmux-testing` named. Never check against the user's live
session.
