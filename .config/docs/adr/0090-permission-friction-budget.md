# ADR-0090: Open the distribution trees and the read-only system trees in the external-directory family, and split the browser profile into readable-minus-credentials, instead of keeping every unproven path under operator review

Status: Accepted
Date: 2026-10-20

## Context

[ADR-0087](0087-licensed-external-directory-allow.md) deleted the delegation-envelope patch and accepted that external asks outside the nothing-on-disk license reach the operator, on the argument that `config.json` already covered the trees routine work touches.
It also fixed the remedy: a path that prompts too often is answered with an explicit rule, not a code patch.

The review log after that decision showed the argument was true for the wrong tree.
Over the window the config had been stable, the auto-reviewer approved 1781 asks and 69 reached the operator, and the split was structural rather than accidental:

- 19 of the 69 were the `path` family, on which the reviewer logged zero approvals. The family sits in `DELEGATION_EXCLUDED_SURFACES`, so no `allow` a link returns can survive the checkpoint — those dialogs were not a reviewer judgement going the wrong way, they were asks the chain could never answer. Eleven of them were `~/.config/chromium/*`, the hottest non-catch-all pattern in the report.
- 14 were `external_directory`, and their shape was consistent: a command outside the pure-reader core (`strings`, `man`, `pacman`, `gh`, `file`, `patch`, `hyprctl`, `timeout`) naming a path under `/usr`, `/etc`, `/run`, `/proc` or `/var/log`. An unproven direction consults both surfaces, the read allow on `/usr/*` covers the read half only, and the write half falls to `"*": "ask"`. ADR-0066 had already diagnosed this exact trigger and solved it with a patch; ADR-0087 removed the patch and kept the trigger.

The two cases need different answers, because the caps differ.
`external_directory` is capped, so the reviewer can approve there and a rule only has to stop the write side of a read.
`path` is capped as a family with no licensed relief on the read side, so a rule is the only mechanism available.

Alternatives were weighed.
Declaring readers in `commandEffects` classifies the commands that prompted, but its effect dies the moment a command is typed that nobody declared — the friction returns with the next probe, and it explains nothing to the reviewer.
Lowering `yoloMode` widens everything at once, including secrets.
Deleting the browser rules entirely removes the dialogs and reopens the gap the audit closed on 2026-09-28, because cookie and session-token stores live in the same directory as the extension sources worth reading.

## Decision

Widen `external_directory` with the distribution trees (`/usr`, `/etc`, `/opt`) and `~/.cache/*`, so an unproven command reading there no longer asks on the write side.
Widen `external_directory_read` with the read-only system trees (`/var/log`, `/run`, `/proc`, `/boot`, `/sys/*`); the redundant `/sys/class/power_supply/*` entry was folded into the last of those.

The read-only system trees are declared in **both** families, and that duplication is deliberate.
A bare-family entry is sugar whose rules load first, while an explicit directional key's entries append after them, so `/proc/*: allow` written only under `external_directory` would be overridden on the read side by that surface's `"*": "ask"` catch-all — and since an unproven direction folds both surfaces most-restrictively, the write-side allow alone would still have prompted.
Naming the same pattern in `external_directory_read` makes the normalizer drop the sugar copy and emit the entry after the catch-all, which is the only spelling that stops the prompt.
`report.py`'s shadowed-entry section reports exactly this shape, and flagged the first draft of this change.

A later audit added `*.credentials.json` to `path` and `path_read`: a Claude credential store sat in the home tree that `external_directory_read` allows wholesale, and no deny covered it, so the agent could read and write an OAuth token.
That audit also widened the `set -eu` allow to `set -e*`, which is what shell probes actually write, and added allows for the repeated read-only bash asks (`command -v`, `yadm log`/`show`, `gh pr view`/`diff`/`list`, `gh search`, and the repo's own skill scripts).
`gh api`, bare `python3`, and whole `gh pr` stay out: they carry mutating calls under the same prefix.

Keep the bare `path` ask on both browser profiles, which is what governs writes, and add an explicit `path_read` allow for each profile so reads stop at the human boundary.
Per-direction sugar composition makes that split safe: the bare entries load first and the explicit `path_read` entries append after them, so last-match-wins gives the directional rule the read and leaves the bare rule the write.
Deny the credential stores by name after the allow (`*Cookies*`, `*Local State*`, `*Login Data*`, `*Web Data*`), matching `Local State` as a filename so the profile-root path is covered as well as the nested one.
The bare map's secret denies that the browser allow would otherwise override (`*.env`, `*.pem`, `*.key`, `*.keyring`, `*auth.json`, `*.envrc`) were repeated after it for the same reason; the rest keep deciding from their sugar position, since no browser allow can match their paths.

## Consequences

An unproven command may now write under `/usr`, `/etc`, `/opt`, `/var/log`, `/run`, `/proc` and `/boot` without a boundary prompt.
Accepted: those trees need root for a real write, the `bash` surface still gates the command itself, and the `path` denies still cover the secret directories.
The `path` family stays capped, so any new `path` allow added later will stop its prompts with no reviewer in the loop — that is the trade for the read/write split above, and a future secret belongs on `path` where the cap protects it.

The browser profile is readable but not writable, and its cookie, session and password stores stay denied by name.
A store the four patterns do not name — an extension's own IndexedDB holding a token — is readable, which is the same exposure the extension-source reads already had whenever an operator approved one.

The friction returns as an explicit rule in a diff rather than as a prompt while working, so the next review can argue about the rule.
`report.py`'s shadowed-entry section stays empty for this config, and the `path_read` allow is the case its guidance already describes: a read ask is answered on a `*_read` surface, never by widening the bare family.

Nothing in the auto-reviewer's `additionalPolicy` changed; it already called system and distribution reads routine, and the friction was the envelope's cap rather than its verdict.
