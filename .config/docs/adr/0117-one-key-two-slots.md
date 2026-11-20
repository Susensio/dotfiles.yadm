# ADR-0117: Fill both GitHub key slots with one per-machine keypair and keep the account a trust anchor only for signatures

Status: Accepted
Date: 2026-11-20
Supersedes: [ADR-0109](0109-tailscale-ssh-mesh-per-machine-signing-keys.md)

## Context

[ADR-0109](0109-tailscale-ssh-mesh-per-machine-signing-keys.md) meshed the machines on Tailscale SSH and minted one passphraseless signing key per machine, but forbade a signing key from also authenticating SSH, and declined to read GitHub as an `authorized_keys` source.
The owner reviewing it (2026-11-20, ahead of `nuc`'s LUKS rebuild) judged the reuse ban too hard: a published public half gives an attacker nothing (ed25519 is not reversible, and `sshsig` namespacing keeps a git signature from replaying as an SSH authentication), the realistic compromise path steals whole home directories and would take a dedicated second key sitting beside the first, and a fresh keypair for one LAN fallback path felt like ceremony.

The reasoning ADR-0109 did not have was that on `dell` a dedicated auth key would sit passphraseless in the same `~/.ssh` directory as the signing key, protected by the same LUKS root: against a compromised machine the separation buys nothing, and against a stolen key file it buys nothing either.
What the separation still buys is real but modest: an independent rotation path (the signing key is the fleet's most exposed key, its public half in public repositories), and keeping `git/allowed_signers` and the GitHub profile from becoming a published directory of fingerprints that open shells.

The other half of ADR-0109 — declining the GitHub account as a key directory that every machine pulls into `authorized_keys` — gains force with the reuse allowed: the account's `admin:public_key` scope (the agent on `nuc` holds a token with it) becomes a shell on every pulling machine, and the public `user/keys` endpoint lists authentication keys only, so the directory shape requires registering auth keys on the account at all.
The directory would automate one pasted line — `nuc`'s LAN fallback — that rebuild-day types at a console anyway.

`nuc`'s rebuilt root is LUKS-encrypted (the homelab rebuild plans, 2026-11-20), which closes the gap [ADR-0100](0100-passphraseless-signing-key.md) left when it accepted a passphraseless key only where LUKS covers it at rest: after the rebuild the premise holds on every machine, so that record needs no revisit.

## Decision

One passphraseless keypair per machine, registered on GitHub in the signing slot, and wherever a machine needs an SSH credential (today only `nuc`'s LAN sshd fallback), the same keypair fills the authentication slot too: pasted into `authorized_keys` by hand at the box, never fetched from GitHub, and not registered in the account's authentication-key list beyond what a LAN fallback ever needs.
The keypair never authenticates anything over the tailnet; Tailscale SSH stays the mesh.

Keep declining the key directory: no machine reads `api.github.com/users/…/keys` as an `authorized_keys` source, and GitHub's job stays signature verification.

Password authentication stays off everywhere; `nuc`'s LAN sshd is key-only like every other path.

## Consequences

A stolen private key from any machine now both forges commits and opens the LAN fallback on `nuc`; the blast radii merge, accepted because they only separate against threats that take whole home directories anyway.
Rotating a signing key (a suspected leak, a machine's retirement) now also rotates that machine's SSH credential, so the paste into `authorized_keys` and the `allowed_signers` line change together, and both are printed by the bootstrap step.
`git/allowed_signers` and the GitHub profile now name fingerprints that open a shell on `nuc`'s LAN fallback; the account that hosts them stays guarded by its two-factor and its scoped tokens, which is the same trust it already carries for signatures.

`nuc`'s LAN fallback needs its line pasted once at the rebuild (the wipe erases the entry that held `dell`'s key); `docs/access.md`'s matrix row for it flips to the same keypair.
Fail2ban or sshd rate-limiting on the LAN is optional hardening rather than the guard a password door would need, since nothing guesses at keys.
The signing-key bootstrap step keeps refusing to mint a passphraseless key where the root is not encrypted, per ADR-0100; the homelab rebuild makes that premise true on every machine, so no exception is expected.
