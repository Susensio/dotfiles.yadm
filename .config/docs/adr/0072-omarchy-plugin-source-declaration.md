# ADR-0072: Record marketplace Omarchy plugin sources at lifecycle events instead of tracking their clones

Status: Accepted
Date: 2026-09-29

## Context

ADR-0065 left marketplace plugins as untracked git clones under `~/.config/omarchy/plugins/`, so a fresh machine could restore their tracked `shell.json` placement but not the plugins themselves.
The clones' `origin` remotes held the source URLs only on the machine with the clones; `omarchy plugin list` did not expose those URLs, and Omarchy had no plugin add/remove hook.
Tracking the clones in yadm would create embedded-repository gitlinks, not copy their contents; ignoring all of `plugins/` would also hide locally authored plain-file plugins such as `susensio.scratchpad`.
A draft bootstrap step inferred declarations from installed clones and removed a declaration when a previously seen clone was absent.
That mistook transient or accidental absence for the user's intent and made observed runtime state override the tracked declaration.

## Decision

Keep locally authored plain-file plugins in `omarchy/plugins/` tracked by yadm, and ignore downloaded clone directories individually in `omarchy/.gitignore`.
Record marketplace manifest ids and git URLs in the tracked `omarchy/plugins.conf` at successful `plugin-added` and `plugin-removed` lifecycle hooks; the same hooks maintain the matching ignore lines.
Omarchy's native add/remove commands need a small upstream change to emit those events, with a guarded bootstrap patch until it ships, so direct CLI and menu invocations use the same writer.
Bootstrap reads the declaration only: install a missing clone through `omarchy plugin add`, leave existing clones untouched, and never infer an addition or removal from the plugin directory.
Keep enablement and placement in the shell-owned `omarchy/shell.json`.

## Consequences

A fresh machine fetches the declared plugins without vendoring their code or losing yadm's ability to see new plain-file plugins.
Adding or removing a marketplace plugin updates the declaration and ignore rules as part of the native operation; the user commits the resulting tracked diff to carry it to another machine.
A missing clone is restored from the declaration at the next bootstrap, even if it was removed outside `omarchy plugin remove`; intentional removal must go through the lifecycle command or change the tracked declaration.
The bootstrap does not uninstall a clone on another machine when its declaration disappears: without a managed-install record, it cannot safely distinguish that clone from an independent local install, so uninstalling it there remains explicit.
Plugin updates retain their own git history and local edits; `omarchy plugin update` may still conflict with an uncommitted local patch.
The local hooks require Omarchy to emit the lifecycle events; the guarded system patch must be kept until the upstream hook change ships.
Only portable HTTPS and Git-over-SSH source URLs without embedded credentials are recorded; local paths and credential-bearing URLs can still be installed by Omarchy, but the hook reports failure and does not put them into yadm.
The hook runner does not make a completed install fail when a hook fails, so check its `Hook failed` message and the yadm diff after installing a plugin.
A locally copied built-in plugin (`omarchy plugin clone`) has no git remote and is not declared here; add its plain files to yadm explicitly.
