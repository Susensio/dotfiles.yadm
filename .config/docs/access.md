# Access

How to reach each machine, and with what credential.
[ADR-0109](adr/0109-tailscale-ssh-mesh-per-machine-signing-keys.md) recorded why the mesh is Tailscale SSH rather than keys, and why the account is never read as an `authorized_keys` source; [ADR-0117](adr/0117-one-key-two-slots.md) supersedes its signing/auth separation: one per-machine keypair now fills both GitHub slots where a path needs a key at all.

## The matrix

| From | To | Path | Credential |
|---|---|---|---|
| `dell` | `nuc` | tailnet name, `ssh nuc` | Tailscale identity |
| `dell` | `nuc` | `192.168.1.103`, port 22 | `dell`'s signing key in `~/.ssh/authorized_keys` (the same keypair, per ADR-0117; the rebuild-day wipe erases the old entry, so it is pasted again at the box) |
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

Nothing reads the account as a key directory ([ADR-0109](adr/0109-tailscale-ssh-mesh-per-machine-signing-keys.md) declined it; [ADR-0117](adr/0117-one-key-two-slots.md) keeps it declined): no machine pulls `api.github.com/users/…/keys` into `authorized_keys`, and the account's `admin:public_key` scope therefore stays what it is, a convenience for hand-registrations.
Every machine pushes over HTTPS with `gh`'s token, including `nuc`, whose yadm and homelab remotes are both `https://` and whose `gh auth status` reports the `https` protocol.
The account holds signing keys only, one per machine, so the slots stay 1:1: a machine's single keypair is registered once, for signatures; where it also authenticates a LAN fallback, the paste into `authorized_keys` is hand-made at the box, never fetched.
The slots differ only in what a stolen private half buys. As a signing key it forges commits, which GitHub's persistent verification records keep from rewriting history; wherever the same keypair also authenticates SSH, it opens that one fallback shell too ([ADR-0117](adr/0117-one-key-two-slots.md)).

## Signing keys

Each machine mints its own passphraseless `<machine>-signing` key and registers its public half on GitHub, in the signing slot only (the authentication slot stays empty unless a LAN fallback needs a paste).
`35_signing_key.sh` does that, and refuses to generate on a machine whose root is not encrypted, since [ADR-0100](adr/0100-passphraseless-signing-key.md) accepted a passphraseless key only because LUKS covers it at rest; after `nuc`'s LUKS rebuild the premise holds fleet-wide.
A new machine's line in `git/allowed_signers` is printed for a person to commit, because that file is this fleet's trust list and a bootstrap step has no business rewriting it.

## Logins a step cannot do

No step starts a login.
On every run a step that needs a login warns with the exact command and exits, and the warning reaches `~/.local/state/yadm/bootstrap.log` for `maintenance` to replay ([ADR-0111](adr/0111-rerun-checked-by-state-logins-warn.md)).

Neither login needs a browser on the machine itself ([ADR-0115](adr/0115-yadm-git-crypt-one-passphrase.md)).
`tailscale up --qr` prints a URL and a QR code, and `gh auth login --web` with `GH_BROWSER=true` prints a code for `github.com/login/device`; the phone or any machine with a signed-in browser approves either, so a headless machine is set up the same way.
`new-machine` runs both when a person is at its terminal, between its two bootstrap passes; hooks, CI and the post-update run only see the warnings.
