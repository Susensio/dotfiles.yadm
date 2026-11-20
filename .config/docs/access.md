# Access

How to reach each machine, and with what credential.
[ADR-0109](adr/0109-tailscale-ssh-mesh-per-machine-signing-keys.md) recorded why the mesh is Tailscale SSH rather than keys, and why the account is never read as an `authorized_keys` source; [ADR-0117](adr/0117-one-key-two-slots.md) supersedes its signing/auth separation: one per-machine keypair now fills both GitHub slots where a path needs a key at all.

## The matrix

| From | To | Path | Credential |
|---|---|---|---|
| `dell` | `nuc` | tailnet name, `ssh nuc` | Tailscale identity |
| `dell` | `nuc` | `192.168.1.103`, port 22 | `dell`'s signing key in `~/.ssh/authorized_keys` — the same keypair in both GitHub slots ([ADR-0117](adr/0117-one-key-two-slots.md)); the bootstrap seeds the file from the account's key list, so the rebuild needs no paste |
| phone | `nuc` | tailnet name, port 22 | Tailscale identity, no key |
| phone | `nuc` | LAN address | not set up: no phone key on `nuc` |
| anything | `dell` | tailnet name | Tailscale identity: `dell` runs no sshd |

No machine offers password authentication over either path.
The homelab repo owns `nuc`'s `/etc/ssh/sshd_config.d/10-homelab.conf` and sets `PasswordAuthentication no` with `KbdInteractiveAuthentication no`; the applied file and `host/sshd/10-homelab.conf` match, and `just apply` is how it changes.

The phone needs no credential on the tailnet because Tailscale SSH authenticates the device, not a key.
A phone SSH app that insists on a credential before offering "none" authentication cannot use that path; Termux's `ssh` can.
Over the LAN the phone needs a key of its own in `nuc`'s `authorized_keys`, and none is there.

## Why port 22 on the tailnet is Tailscale's

`tailscale set --ssh` makes `tailscaled` answer port 22 on the Tailscale IP, replacing OpenSSH for traffic that arrives over the tailnet.
OpenSSH keeps the LAN address, which is why the matrix has two rows per host and why the LAN row is the recovery path when `tailscaled` is not running.
`25_tailscale.sh` runs the opt-in on every machine that has the daemon, so a fresh machine gets it on its first bootstrap once `tailscale up` has been done by hand.
The tailnet policy is not in the repository: no local `tailscale` subcommand reads or writes it, so it stays a console edit.

## GitHub

The account is the directory of who "I" am ([ADR-0117](adr/0117-one-key-two-slots.md)): each machine's one keypair is registered in the signing slot and the authentication slot, and every machine whose sshd answers seeds `authorized_keys` from the account's public key list when the bootstrap runs — publish and subscribe both on the bootstrap, never on a timer, so the account is read only at moments the machine already trusts it (a first install, a `yadm pull`).
Every machine pushes over HTTPS with `gh`'s token, including `nuc`, whose yadm and homelab remotes are both `https://` and whose `gh auth status` reports the `https` protocol.
A machine that later needs `git@github.com:` clones finds the same keypair already in the authentication slot; nothing registers a second keypair.
The slots differ only in what a stolen private half buys. As a signing key it forges commits, which GitHub's persistent verification records keep from rewriting history; as an authentication key it opens the LAN fallbacks seeded from the account's list — the merged blast radius [ADR-0117](adr/0117-one-key-two-slots.md) accepted.

## Signing keys

Each machine mints its own passphraseless keypair and registers its public half on GitHub in **both** slots, titled with the bare machine name: signing (always) and authentication (so the fleet's sshd machines can seed `authorized_keys` from the account's list; `36_authorized_keys.sh` does the seeding).
`35_machine_key.sh` does that, and refuses to generate on a machine whose root is not encrypted, since [ADR-0100](adr/0100-passphraseless-signing-key.md) accepted a passphraseless key only because LUKS covers it at rest; after `nuc`'s LUKS rebuild the premise holds fleet-wide.
A new machine's line in `git/allowed_signers` is printed for a person to commit, because that file is this fleet's trust list and a bootstrap step has no business rewriting it.

## Logins a step cannot do

No step starts a login.
On every run a step that needs a login warns with the exact command and exits, and the warning reaches `~/.local/state/yadm/bootstrap.log` for `maintenance` to replay ([ADR-0111](adr/0111-rerun-checked-by-state-logins-warn.md)).

Neither login needs a browser on the machine itself ([ADR-0115](adr/0115-yadm-git-crypt-one-passphrase.md)).
`tailscale up --qr` prints a URL and a QR code, and `gh auth login --web` with `GH_BROWSER=true` prints a code for `github.com/login/device`; the phone or any machine with a signed-in browser approves either, so a headless machine is set up the same way.
`new-machine` runs both when a person is at its terminal, between its two bootstrap passes; hooks, CI and the post-update run only see the warnings.
