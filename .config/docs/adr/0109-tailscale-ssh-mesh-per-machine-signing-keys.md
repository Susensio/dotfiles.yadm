# ADR-0109: Mesh the machines on Tailscale SSH and mint one passphraseless signing key per machine, instead of reusing signing keys as SSH auth keys or syncing GitHub auth keys

Status: Accepted
Date: 2026-11-10

## Context

Three Linux machines run Tailscale, and reaching any of them from any other needed hand-placed keys.
`nuc` ran OpenSSH with a single `authorized_keys` entry, the signing key of the laptop it was copied from; `dell` ran no sshd at all; `chuwi` had its own key registered on GitHub.
The mesh worked only along the pairs someone had configured, and each new machine meant copying private key material by hand.

GitHub already held the public halves of every machine's signing key, which made two shortcuts look cheap.
The first was to register the existing signing keys as *authentication* keys, turning one `gh ssh-key add` per machine into a working mesh.
The second was to treat the account as a key directory: each machine generates its own key, uploads the public half, and every host pulls `https://api.github.com/users/Susensio/keys` into `authorized_keys`.
Both collapse the distribution problem to nothing, because the public halves already exist in a known place.

An ed25519 keypair carries no notion of purpose, so the first shortcut is one command away at any time.
What it costs is the distinction between the two uses.
[ADR-0100](0100-passphraseless-signing-key.md) generated a passphraseless key and made it every commit's signature; its Consequences already warn that any copy is a total compromise.
Reusing that key for authentication widens one blast radius to cover two unrelated failures: a stolen signing key forges commits, which GitHub's persistent verification records keep from rewriting history, while a stolen authentication key opens a shell on every host that lists it.
It also puts the fleet's authentication fingerprints in `git/allowed_signers`, a tracked, public file that is deliberately, harmlessly public only for as long as it holds nothing that opens a door.

The directory shortcut has a narrower but sharper cost: whoever controls the GitHub account controls shell access to every machine that pulls the list.
It also needs `admin:public_key`, which the `gh` token only gained incidentally, and it cannot be fully bootstrapped because the ACL and the account are browser-shaped steps.

Tailscale SSH needs none of this.
It authenticates over WireGuard node keys, authorizes per tailnet policy, never writes `authorized_keys`, and on both hosts was already installed.
It claims port 22 only on the Tailscale IP, so a local OpenSSH server keeps answering on its LAN address and remains a break-glass path when `tailscaled` is not running.

## Decision

Mesh every machine with Tailscale SSH, accepting connections without a per-connection check via a tailnet policy rule of `action: accept` for `autogroup:self`, and keep local OpenSSH on hosts that run it as the fallback that does not depend on `tailscaled`.
Decline both shortcuts: no signing key is ever registered as an authentication key, and GitHub is never read as an `authorized_keys` source.
GitHub keeps doing exactly one job for this fleet, verifying commit signatures, which is the job the public halves are for.

Mint one passphraseless signing key per machine, named `<machine>-signing`, and register it as a *signing* key.
The key generation, the upload, and the `git/allowed_signers` line are automatable; the line stays a tracked-file edit that a person commits, because `allowed_signers` is the fleet's trust list and a bootstrap step has no business rewriting it silently.
Key generation refuses to run where the root filesystem is not encrypted, since [ADR-0100](0100-passphraseless-signing-key.md) accepted a passphraseless key only because LUKS covers it at rest.

The Tailscale SSH opt-in becomes an idempotent bootstrap step for the existing Tailscale step.
Tailnet policy stays out of it: no local `tailscale` subcommand reads or writes the policy, so the step warns and names the console page rather than pretending.

## Consequences

Reaching any machine from any other needs no key, no `authorized_keys` and no distribution, and revoking access is a policy edit that takes effect within seconds and drops live sessions.
The mesh's availability is now `tailscaled`'s availability; where a host runs OpenSSH, its `authorized_keys` is what gets a person back in, and it is deliberately kept rather than cleaned up.
The signing keys stay single-purpose, so a compromise forfeits commits or a shell but not both, and `git/allowed_signers` stays a file that leaks nothing.

The `accept` rule is the accepted limitation: a device key plus tailnet membership is enough to open a shell, with no second factor and no re-authentication.
The default `check` rule would have required a browser round-trip every twelve hours; it remains the answer for any host that later holds something worth a second factor, and switching is one policy edit.

A new machine has two browser steps no bootstrap can do, `gh auth login` and `tailscale up`, and one commit-shaped step, the `allowed_signers` line.
`dell` still runs no OpenSSH server, so it is reachable only through Tailscale SSH; enabling its sshd would restore a fallback at the cost of a listening daemon on every network it joins.
Almost nothing spans enough machines to exercise it yet: `nuc` and `dell` do, `chuwi` is the machine that has to adopt the per-machine key name, and a fresh machine has never run the generation step.

`chuwi`'s authentication key on GitHub is the one leftover that predates this record, and it should be removed rather than kept now that authentication has left the account.
`nuc`'s 2023 RSA authentication key is unreferenced by anything in this design and can go with it.
