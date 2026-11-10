# Access

How to reach each machine, and with what credential.
[ADR-0109](adr/0109-tailscale-ssh-mesh-per-machine-signing-keys.md) records why the mesh is Tailscale SSH rather than keys, and why a signing key never doubles as an authentication key.

## The matrix

| From | To | Path | Credential |
|---|---|---|---|
| `dell` | `nuc` | tailnet name, `ssh nuc` | Tailscale identity |
| `dell` | `nuc` | `192.168.1.103`, port 22 | `dell`'s signing key in `~/.ssh/authorized_keys` |
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

Nothing needs an authentication key on GitHub: every machine pushes over HTTPS with `gh`'s token, including `nuc`, whose yadm and homelab remotes are both `https://` and whose `gh auth status` reports the `https` protocol.
The account therefore holds signing keys only, one per machine, so the two slots stay 1:1: a machine's single keypair is registered once, for signatures.
The slots differ only in what a stolen private half buys. As a signing key it forges commits, which GitHub's persistent verification records keep from rewriting history, and it cannot push or open a shell. As an authentication key it can push to every repository.

A machine that later needs `git@github.com:` clones registers that same keypair in the authentication slot too; one keypair filling both is expected, and it is not the shared-key anti-pattern, which is about a key opening shells on many hosts.

## Signing keys

Each machine mints its own passphraseless `<machine>-signing` key and registers its public half on GitHub.
`35_signing_key.sh` does that, and refuses to generate on a machine whose root is not encrypted, since [ADR-0100](adr/0100-passphraseless-signing-key.md) accepted a passphraseless key only because LUKS covers it at rest.
A new machine's line in `git/allowed_signers` is printed for a person to commit, because that file is this fleet's trust list and a bootstrap step has no business rewriting it.

## Logins a step cannot do

A login needs a browser, so no step starts one.
On every run a step that needs a login warns with the exact command and exits, and the warning reaches `~/.local/state/yadm/bootstrap.log` for `maintenance` to replay ([ADR-0111](adr/0111-rerun-checked-by-state-logins-warn.md)).
