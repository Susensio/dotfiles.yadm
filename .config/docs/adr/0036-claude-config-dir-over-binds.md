# ADR-0036: Point CLAUDE_CONFIG_DIR at .config/claude instead of symlinking or bind-mounting into ~/.claude

Status: Accepted
Date: 2026-08-26
Supersedes: [ADR-0024](0024-track-agent-config-in-dotfiles.md)

## Context

ADR-0024 hoisted the hand-written harness into `~/.config/agents/` and symlinked `~/.claude/{agents,skills,rules,hooks}` back at it, because `~/.claude/` could not be tracked.
It left the premise intact: `~/.claude/` and `~/.claude.json` still existed in `$HOME`, still held the state, and the links still had to be made by hand on a fresh machine.

Two attempts were made to remove that residue outright.
The first replaced the symlinks with `bwrap` bind mounts from a wrapper on `$PATH`, splitting the tree three ways across `XDG_CONFIG_HOME`, `XDG_STATE_HOME` and `XDG_CACHE_HOME`.
The mounts worked, and `~/.claude` kept reappearing anyway.
`bwrap` cannot mount onto a path that does not exist, so it issues `mkdir` before `mount`; under `--dev-bind / /` the new root is the same superblock as the old, and that `mkdir` allocates a real directory entry in `$HOME` that the mount then hides from inside.
A mount namespace isolates the mount table, not the filesystem.

The second attempt made `$HOME` itself a `tmpfs` inside the namespace and bound the real entries back through an alias, so the mountpoint would land in RAM.
It was tested and it works: bind mounts do reach a clean `$HOME`.
What they cost is a nested `bwrap`, a rebuild of `$HOME` from one bind per top-level entry on every launch, and the silent loss of anything written directly to `$HOME` during a session — a wrapper script to maintain in perpetuity, standing between the shell and every invocation, in exchange for one directory entry.

Claude Code 2.1.238 was then found to honour `CLAUDE_CONFIG_DIR` as the root of everything it writes locally — verified by pointing it at a scratch directory, where it created `.claude.json`, `projects/`, `sessions/` and `backups/` and touched nothing in `$HOME`.
Upstream issue #1455, which asks for XDG compliance by default, was open with no maintainer response and described the variable only as putting "some file" there.

## Decision

`CLAUDE_CONFIG_DIR` is set to `$XDG_CONFIG_HOME/claude` in `environment.d`, and everything Claude Code owns lives in that one directory as real files.
No wrapper, no bind mounts, no symlinks.
`yadm/exclude` and a `.gitignore` inside the directory each restrict tracking to the hand-written config, so the credentials and transcripts beside it stay out of the repo.

The three-way XDG split is abandoned rather than deferred.
`CLAUDE_CONFIG_DIR` is a single knob, so state and cache live under `XDG_CONFIG_HOME` too; expressing the split needs bind mounts, and a script to maintain forever is the price this decision declines to pay.

The compromise that makes one directory tolerable is a `.gitignore` inside it.
The layout stops being strictly XDG, and the repo stays honest anyway, at the cost of one file rather than a wrapper.

## Consequences

`$HOME` is clean, a fresh machine needs no link-making step, and the harness is one directory that can be read without knowing where anything points.
`agents/agents/` from ADR-0024 is gone with the symlinks that motivated it.

Cost: `XDG_CONFIG_HOME` now holds session transcripts and a credential file, which is not what the spec means by configuration.
Two exclusion layers guard that, and both were tested — a blanket `add` of the directory picks up nothing but the `.gitignore`.
The inner one carries the weight, since it overrides `yadm/exclude` from deeper in the path and survives the outer allowlist being simplified.

The tracked config sits among churn, so staging by explicit path matters more here than elsewhere in this tree.

Absolute paths pointing at the old location are the failure mode a move produces.
The statusline and hook commands in `settings.json` were rewritten to `$CLAUDE_CONFIG_DIR`, which the shell expands at run time, so they follow the directory rather than pinning it.
The plugin manifests cannot: Claude Code writes absolute install paths there itself and would overwrite any variable, so a future move has to rewrite them again.

Depending on an undocumented variable is the standing risk: issue #1455 is open, so the behaviour is not contractual and an upstream change to it breaks this silently.
Native XDG support landing upstream would supersede this record rather than confirm it.
ADR-0004 patched system files to enforce XDG where a tool offered no hook; this is the same goal reached through a hook the tool did offer.

## Corrections

2026-08-26 — The Context originally described the `tmpfs` attempt as working but costly, which read as a technical shortfall.
Bind mounts reach a clean `$HOME`; they were rejected for the wrapper script they oblige, not for failing.
The Decision and Consequences were sharpened to say so, and to name the `.gitignore` as the compromise accepted in exchange.
