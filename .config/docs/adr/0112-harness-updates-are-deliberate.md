# ADR-0112: Take every harness off mise's auto_update and heal pi's extension install from a tool postinstall hook, instead of letting the background updater land harness versions nobody is watching

Status: Accepted
Date: 2026-11-10

## Context

On 2026-11-10 a five-hour Claude window emptied in under ten minutes.
The token accounting showed the cause was not extra work: turns that had been reading ~217k
tokens of prompt cache began re-writing the same 217k at cache-write rate, seven times in a
row, taking the API-equivalent cost of those turns from ~$1.40 to ~$17.53.
The trigger was a bridge session rebuild, but the conditions that made it expensive were
structural, and three of them were this repository's own configuration.

`pi-claude-bridge` publishes npm releases that declare `peerDependencies` on the pi runtime,
and 0.12.0 required `>=1.5.1`. pi itself is declared in `mise/conf.d/tools.toml` and was
installed by mise, so the two moved on independent schedules.
Three separate mechanisms each failed to notice the pair no longer matched:

- **`pi update --extensions` skips the project postinstall.** Measured: with a marker script
  in `pi/agent/npm/package.json`'s `postinstall`, `pi update --extensions` reported
  "Packages are already up to date" and never ran it, and a forced `npm install` skipped it
  too, because npm only runs the lifecycle when something actually installs. So a package
  update reverts `node_modules` patches and rebuilds nothing until the next pi start, which
  is what `extensions/patch-drift.ts` was written to paper over.
- **Nothing compares an extension's declared peers against the installed pi.** pi suppresses
  automatic peer installation for managed npm packages and does not verify the ranges
  either, so the mismatch is silent until a turn fails.
- **`pi update` cannot update pi here at all**, because mise provides it, and
  `selfUpdateCommand` was unset, so the command that exists to move the runtime was a no-op.

The same day, `mise/conf.d/tools.toml` was found to be silently discarding omarchy's
`minimum_release_age = "0s"` for four agent CLIs.
A later `[tools]` entry for a tool replaces the earlier entry wholesale, so `pi`, `claude`,
`codex` and `opencode` — declared in `/etc/mise/conf.d/omarchy-tools.toml` with `0s` —
fell back to mise's 24h default the moment this repo re-declared them to add `postinstall`
and `auto_update`. `mise current pi` then reported `latest` while `mise ls-remote pi` hid
1.5.1 and 1.5.2 behind a warning only printed on that command.

Three harnesses were additionally on `auto_update = "4h"`, served by the
`mise-tool-update` service, which updates them on an hourly sweep rather than at use.
An unattended harness upgrade unlinks the binary running processes are executing from,
reverts patched `node_modules`, and can install a version an existing extension's peers
reject — with no user present to reload, roll back, or notice.

Alternatives weighed: keep `auto_update` on harnesses and accept background churn; pin every
harness version; leave `selfUpdateCommand` unset and rely on `mise up` by hand; add a hook on
`mise up pi` as a mise task; reuse the existing `herdr-integrations` postinstall for the new
work; have the peer check live in a pi extension instead of the install hook.

## Decision

**No tool in `mise/conf.d/tools.toml` sets `auto_update`.** Harness updates are deliberate.
`mise up <tool>` moves one; `pi update` now moves pi, because `pi/agent/settings.json` sets
`selfUpdateCommand: ["mise", "up", "pi"]`.
The `mise-tool-update` service stays declared in `settings.toml` with nothing to act on, so
the infrastructure is there if a non-harness tool ever wants it.

**`minimum_release_age = "0s"` is repeated on every harness this file re-declares**, with a
comment saying why, because the option is otherwise lost to the wholesale replacement above.
This restores what omarchy already intended for these tools and keeps `latest` floating.

**pi carries `postinstall = "$HOME/.config/mise/tasks/pi-postinstall"`**, a task that runs the
four steps which must follow a pi release, in order:

1. `patches/reapply-all.sh` — restore the local patches the install reverted.
2. `bundler/run.sh` — rebuild the bundles that inline those patched sources.
3. A peer check: for every package declared in `pi/agent/npm/package.json`, compare its
   `@earendil-works/*` `peerDependencies` ranges against `MISE_TOOL_VERSION`, the version
   mise sets for a tool postinstall.
4. `herdr-integrations`, so pi's agent-state integration follows the harness.

The task **fails the install** on an unmet peer or a patch that no longer applies, printing
the package, its version, and the range it wants. Verified against the incident: run with
`MISE_TOOL_VERSION=1.5.0` it reports `pi-claude-bridge@0.12.0 ... requires
@earendil-works/pi-ai >=1.5.1` and exits non-zero; with `1.5.2` it exits zero. A non-zero
tool postinstall aborts `mise install`, so the bad pair cannot be installed quietly.

The other three harnesses keep `herdr-integrations` as their own postinstall; pi's hook
calls it directly instead of `mise run`, per ADR-0060's rule that hooks call the script.

## Consequences

A harness upgrade can no longer happen while nobody is watching. The cost is that staying
current is manual: `mise up` is now the only route, and forgetting it leaves a harness behind.
That is the intended trade, because the failure mode of being behind is a missing feature,
while the failure mode of an unattended upgrade is a broken turn mid-task plus reverted local
patches.

The peer check encodes the assumption that a package declaring `@earendil-works/*` peers is
speaking about the pi runtime. It does not resolve full semver: it understands `*`, `>=`,
`>`, `^` and `~` against a three-part version, which covers every declared range in the
current install. A range it cannot parse is treated as satisfied rather than failing closed,
so a future exotic range will not block an install — it will silently skip that one check,
which is the residual gap.

`pi update --extensions` still skips the postinstall. This record does not fix that; it routes
around it by making pi's own install the healing event, so an extension update is repaired at
the next `mise up pi` rather than immediately. An extension that breaks the runtime while pi
stays put is therefore only caught when pi next moves or the hook is run by hand.

`reapply-all.sh` exits 0 even when a patch no longer applies, so the task reads its output
instead of its status. The same applies to `bundler/run.sh`, which is silent on success; any
output is reported and fails the install. A future patch that prints a normal informational
line would therefore fail installs until this convention is revisited.

herdr is the exception: it prints standing notices on stderr whether or not anything is wrong
(an extension directory shared with OMP, an absent harness), so its output is passed through
and only its exit status is judged. Treating its output as failure made every `mise up pi`
fail on this machine.

The patch library lost `pi-claude-bridge-standalone-prompt-capture`: its three hunks deleted
a `PI_PREAMBLE` guard that 0.12.0 removed upstream, so it could never apply again. `pi-claude-bridge-index`
was rebased onto 0.12.0's layout, where hunk 2's anchor had moved. Both were checked by
diffing the patched tree's `tsc` error set against pristine 0.12.0's: identical, so the
rebase introduced no new type errors.
