# Past issues corpus (Susensio, github.com/omacom/omarchy)

Repo-specific evidence backing `../voice.md`, and the concrete authority for omacom/omarchy specifically.
Pulled via `gh pr view <n> --repo omacom/omarchy`.
Re-run that if you need a comment thread or exact wording beyond what's excerpted here — do not treat this file as more current than the live repo.

## #13351 — PR: Stop prepending OMARCHY_PATH/bin to PATH in Hyprland envs (open)

Repo default branch is `quattro`; the PR was filed from the `Susensio/omarchy` fork. No CONTRIBUTING.md or PR template exists.

```
`default/hypr/envs.lua` prepends `$OMARCHY_PATH/bin` to `PATH` for everything Hyprland spawns, on every install, and `autostart.lua` then imports that `PATH` into the systemd user manager. ...
```

Notable, in the user's own writing style:

- Plain declarative context in the first paragraph, backed by a fenced code block with the observed artifact, not a complaint.
- Heading-per-argument analysis: `### Why it's a leftover`, `### Problems it causes`, `### Fix`. Each bullet carries its own linked upstream commit as evidence (`4f031e1`, `64581ec`).
- Bullet lists causally ordered, each bullet one full sentence-per-clause, names of commands inline-formatted.
- The fix section names the test added, path `test/shell.d/hyprland-envs-path-test.sh`, and asserts "It fails before this change and passes after", then lists the other tests it does not break (`hyprland-paths`, `dev-env-path`, `dev-link`, `dev-unlink`, `editor-env`).
- Closes with the trailer `🤖 Generated with [Claude Code](https://claude.com/claude-code)`.
- #13461 dropped the trailer without complaint — the robot line is optional here, not a hard convention.

## #13364 — PR: Stop prepending mise shims to the uwsm session PATH (open)

Same voice and heading scheme as #13351.
