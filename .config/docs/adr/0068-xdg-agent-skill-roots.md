# ADR-0068: Rehome Omarchy's agent skills under XDG and delete the $HOME links it provisions, instead of leaving them or deleting every $HOME copy

Status: Accepted
Date: 2026-09-28

## Context

Omarchy provisioned its skills by symlinking them into `$HOME`-relative agent roots, from both its user provisioning and its update migrations: `~/.agents/skills`, `~/.claude/skills`, `~/.codex/skills`, `~/.pi/agent/skills`, `~/.hermes/skills`, and, once Antigravity replaced the Gemini agent, `~/.gemini/config/skills`.
This layout points the agents that accept a config-directory variable at `$XDG_CONFIG_HOME` ([ADR-0036](0036-claude-config-dir-over-binds.md), [ADR-0060](0060-herdr-integrations-postinstall.md)), so the bootstrap linked Omarchy's skills into those directories but left the `$HOME` copies behind.
Nothing removed them, and every `omarchy update` migration recreated them.

Three ways to clear them were weighed.
Leaving them keeps the duplication and misleads any tool that reads the `$HOME` root instead of the variable.
Deleting everything under `$HOME` that is not under `$XDG_CONFIG_HOME` also deletes `~/.hermes`, which belongs to a tool with no XDG root, and cannot tell an Omarchy link from a user's own skill.
Taking a list from Omarchy was not available: it exports no manifest and hardcodes the same paths inline in its user provisioning, its migrations and its Quattro upgrade, and its own copies already disagree — the installed 4.0.4 predates the Antigravity root that the source tree adds.

The two agents that could not simply be pointed elsewhere differ.
Hermes exposes `HERMES_HOME` as a single root for config, data and state, the compromise [ADR-0036](0036-claude-config-dir-over-binds.md) already accepted for Claude Code.
Antigravity exposes no config-directory variable at all.

## Decision

Every Omarchy-provisioned agent that accepts a config-directory variable gets it in `environment.d`, pointing into `$XDG_CONFIG_HOME`: the existing `CLAUDE_CONFIG_DIR`, `CODEX_HOME` and `PI_CODING_AGENT_DIR`, plus `HERMES_HOME`.

The skills bootstrap step links Omarchy's skills into those directories, for installed agents only, and deletes the `$HOME` link each one supersedes.
Deletion is keyed on the link's resolved target being inside Omarchy's skills tree, so a real directory, or a link to anywhere else, is never touched.
It runs only while the redirect variable is set, because `environment.d` applies from login on and a pre-login run would otherwise remove the only copy the tool can currently reach.
The directories the deletion empties are removed up to `$HOME`.

`~/.agents` has no agent and no variable of its own.
This layout's generic location is `$XDG_CONFIG_HOME/.agents` — the herdr integration writes it and the harness reads it — so the `$HOME` one is always removed, with no install check.

Antigravity is not kept: with no variable to point elsewhere, its skill was removed with the tool rather than linked from `$HOME`.

## Consequences

`$HOME` keeps no Omarchy skill links, and rerunning the bootstrap after an update removes whatever the migrations recreate.
An agent's `$HOME` root, and the generic `.agents` one, disappear when the removal empties them, so an Omarchy install leaves no agent remnants in `$HOME`.

The superseded roots are this repository's own table, one line per agent, not a copy of Omarchy's.
A root Omarchy adds later is cleaned only once a line is added, and nothing warns when one appears.
An agent whose variable is not yet applied keeps its `$HOME` copy until a login and a bootstrap run; for the same reason, the links the step writes are reachable only from the next login.
Omarchy's Hermes provisioning keeps writing into `~/.hermes`, which Hermes no longer reads, until an Omarchy release follows `HERMES_HOME`; its Hermes removal deletes `~/.hermes` and `~/.config/Hermes`, so a Hermes moved to `~/.config/hermes` has to be cleaned up by hand.

Antigravity's separate-quota fallback, its bwrap wrapper and its harness mention are gone.

## Corrections

2026-11-20: the claim that an Omarchy install leaves no agent remnants in `$HOME` was false for links outside Omarchy's own tree.
Superwhisper's `setup-user` links its agent skill into the same `$HOME` roots (`~/.agents/skills`, `~/.claude/skills`, `~/.codex/skills`, `~/.pi/agent/skills`) from the dictation installer and Omarchy's migrations, and the removal keyed on Omarchy's skills tree never touched it.
The skills bootstrap step now also rehomes that link, keyed on its `/opt/superwhisper/assets/agent-skill` target, into each installed agent's XDG skills root — same Decision, extended to a second vendor's links.
Not into `$XDG_CONFIG_HOME/.agents/skills`: that generic root is read only by project-level discovery (pi scans `.agents/skills` walking up from the working directory, herdr's mirrors are this repo's project skills), while the agents' user-level generic root stays hardcoded at `~/.agents/skills`.

2026-11-20: the installed Omarchy now writes one root the 4.0.4 tree did not — Antigravity's `~/.gemini/config/skills`, from migration and provisioning.
No redirect variable exists (the original Decision's ground for not keeping it), so it gets the generic-`.agents` treatment instead: the skills step unconditionally drops links keyed on Omarchy's tree, and a warning pass derived from the agents table flags whatever remains in a `$HOME` skill root — closing this record's "nothing warns when one appears" limitation for known writers; a new root still needs its own drop line or table entry, and a warning, to be handled.
