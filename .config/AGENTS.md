# Dotfiles Workspace

XDG config repo for `~/.config`, managed with yadm.

- Use `yadm` for every git operation; its worktree root is `$HOME`, while this workspace is `~/.config`.
  Never derive this workspace's root from `git rev-parse --show-toplevel`.
- Before writing config syntax you have not verified in this session, check the tool's manpage or `--help`.
- Write one-line comments for constraints the config cannot express.
- Split delegated work by config domain (`tmux`, `fish`, `nvim`, `mise`, `keyd`).
- Commit messages: `domain: imperative`, lowercase after the prefix, no trailing period (`fish: add fenv`); the prefix names the config domain.
- Commit one concern with its docs; amend an existing unpushed commit for follow-ups.
  Stage explicit paths and only your own changes.

## Records

- Route decisions through the `adr` skill: comments beside a relevant line, otherwise `docs/adr/`; never auto-memory.
- `docs/BACKLOG.md`: open work with no single line to mark, written by the main agent.
- `docs/STATE.md`: work committed to and unfinished, written by the main agent.
- Find inline work with `rg -n 'BUG:|TODO:'`.
- Record deliberately accepted limitations in an ADR's Consequences.
- The `report-issue` skill files upstream, never against this repo.

## References

- For shell or environment questions, read `docs/environment-architecture.md` before investigating the process tree.
- For Omarchy setup, commands that edit tracked files, or command overrides, read `docs/omarchy.md`.
- Before proposing tools, services or generation mechanisms, read `docs/principles.md`.
- Before changing global Claude configuration, read `docs/harness.md` for its location and sandbox path constraints.
- Before changing bindings shared across tools, read `docs/keybinds.md`.

## tmux/

- Invoke the `tmux-config` skill before any tmux work.
- Use `tmux-testing` for anything run against a tmux server, including shell functions; it owns `-L <socket>` isolation.
