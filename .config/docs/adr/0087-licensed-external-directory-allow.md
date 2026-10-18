# ADR-0087: Adopt the permission system's licensed external-directory allow and drop the delegation-envelope patch

Status: Accepted
Date: 2026-10-18
Supersedes: [ADR-0066](0066-trust-auto-reviewer-external-directory.md)

## Context

[ADR-0066](0066-trust-auto-reviewer-external-directory.md) patched the permission system's delegation envelope to drop `external_directory` from `DELEGATION_EXCLUDED_SURFACES`, so the auto-reviewer's `allow` on that family stood instead of being capped to `defer`.
Its own drop condition was upstream [#983](https://github.com/gotgenes/pi-packages/pull/983) or [#620](https://github.com/gotgenes/pi-packages/issues/620) shipping an equivalent, operator-controlled capability; neither shipped.

`pi update --extensions` on 2026-10-18 moved the package to 41.0.0, which replaced the blanket cap with a licensed allow.
`encloseInDelegationEnvelope` now caps an `allow` on an excluded surface unless the ask carries a license, and `licenseFor` grants `nothing-on-disk` to an `external_directory`-family ask whose gate-computed access facts carry it.
`bash-external-directory.ts` sets that fact when the bash program reads verbatim and every uncovered entry is a non-write path naming nothing on disk, so the relief reaches exactly the asks that cannot touch anything.

The patch stopped applying in that update, which is the drift the patch library reports by design.
Its remaining effect had already narrowed: `config.json` allows the routine external trees (`~`, `/tmp`, `/usr`, `/etc`, `/opt`, `/home`), so only paths no rule covers still depended on it.
Keeping it meant rebasing a diff against security-relevant code on every permission-system release, and left a buggy or over-eager reviewer able to approve any external path that no rule grants.

## Decision

Delete the `pi-external-directory-trust` patch.
The `external_directory` family keeps upstream's cap, relieved only by the `nothing-on-disk` license.

Keep ADR-0066's other half: the auto-reviewer's `additionalPolicy` still calls system and distribution reads routine, because that governs the reviewer's own verdicts rather than the envelope's cap.
A path that prompts too often is answered with an explicit `config.json` rule, not a code patch.

## Consequences

The permission system now runs unpatched, so a package update cannot silently lapse the trust and the library carries one fewer patch.
The guarantee ADR-0066 weakened is restored: an `allow` on an external path with no matching rule needs the license or the operator.

External asks outside the licensed case reach the operator where the patch would have let the reviewer approve them.
Accepted: the config already covers the trees routine work touches, and the friction returns as a prompt rather than as a silent widening.

The reviewer policy text in `pi-permission-auto-review/config.json` remains coupled to ADR-0066's reasoning; if it is ever trimmed, that record's policy half governs the change.
