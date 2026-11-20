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

One passphraseless keypair per machine, registered on GitHub in **both** slots: the signing slot (its original job) and the authentication slot, so the account's key list is the directory of who "I" am.
Both slots title the key with the bare machine name (`dell`, `nuc`): each list is read on its own, and the name says which machine exists, not which use the key serves; ADR-0109's `-signing` suffix went when the key stopped being single-purpose (the existing registrations were re-titled 2026-11-20, same key material).
Publish and subscribe are both automated, on the bootstrap: the signing-key step registers the keypair in both slots, and a new authorized_keys step seeds every machine whose sshd answers from the account's public key list, replacing the file wholesale so a revoked key leaves on the next bootstrap.
The account is read only when a bootstrap runs — a first install or a `yadm pull`'s rerun — never on a timer: those are the moments the machine already bets on the account (it just cloned the account's repositories), so the trust window adds nothing new.
The keypair never authenticates anything over the tailnet; Tailscale SSH stays the mesh.

Password authentication stays off everywhere; `nuc`'s LAN sshd is key-only like every other path, and the tailnet-down/GitHub-up lockout the directory answers is covered by the seeded LAN fallback rather than a password.

## Consequences

A stolen private key from any machine now both forges commits and opens the LAN fallback on `nuc`; the blast radii merge, accepted because they only separate against threats that take whole home directories anyway.
Rotating a signing key (a suspected leak, a machine's retirement) now also rotates that machine's SSH credential: the authentication-slot entry is deleted on GitHub, the signing entry and the `allowed_signers` line change with it, and every machine's next bootstrap drops the old public half from `authorized_keys` — the wholesale replace is what makes revocation propagate.
A compromised account can now add an authentication key that grants the LAN fallback on every sshd machine at its next bootstrap; this is the accepted cost of the directory, narrower than a standing pull (which would make it silent root within a cycle) because a bootstrap is an operator-initiated moment, and the account already needed re-signing keys to be similarly trusted by deploys.
The account's key list is load-bearing for the LAN fallbacks; `new-machine`'s login now requests the `admin:public_key` scope beside the signing one.
The same load-bearing list sets a scope rule for every agent's GitHub token, recorded on the homelab side and binding here: no token an agent holds may carry `admin:public_key` (or `admin:ssh_signing_key`), because an agent that can plant a key on the account can plant one its own box trusts at the next bootstrap; tokens stay read-scoped, and only the owner's interactive logins ever hold an admin scope. ADR-0111 already keeps bootstrap steps from starting logins; this closes the token half.

`nuc`'s LAN fallback needs no paste at the rebuild (the bootstrap seeds it once sshd answers); `docs/access.md`'s matrix row for it flips to "seeded from the account's key list".
Fail2ban or sshd rate-limiting on the LAN is optional hardening rather than the guard a password door would need, since nothing guesses at keys.
The machine-key bootstrap step (`35_machine_key.sh`) keeps refusing to mint a passphraseless key where the root is not encrypted, per ADR-0100; the homelab rebuild makes that premise true on every machine, so no exception is expected.
