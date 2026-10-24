# ADR-0100: Store the Git signing key without a passphrase on the LUKS root and decline PAM auto-unlock

Status: Accepted
Date: 2026-10-24

## Context

Git had an SSH signing key configured (`user.signingkey` pointing at `~/.ssh/id_ed25519.pub`, `gpg.format=ssh`) but no key on disk, and `commit.gpgsign` was never set: of the last 200 commits, 198 carry no signature.
Signing therefore did nothing, and the PR template answer was "No".

A passphrase is the obvious choice, but it is only free if the agent unlocks it without prompting, and the three ways to arrange that each cost something.
`ssh-add` once per boot is one prompt per login and no other change.
`pam_ssh_add` needs the AUR, and PAM auto-unlock through `pam_gnome_keyring` needs a root-owned edit to `/etc/pam.d/sddm`, which today carries `-session optional pam_gnome_keyring.so auto_start` without the `auth` line that actually unlocks the keyring.
Both PAM routes also require the key passphrase to equal the login password, and both stop working if the login is ever satisfied by a fingerprint, which produces no password to unlock with.

What a passphrase protects here is narrower than it looks.
`/home` is a btrfs subvolume inside a LUKS2 mapping, so the key file is already encrypted at rest whenever the machine is off, and `~/.ssh` is outside the yadm allowlist and untracked.
A passphrase adds protection only for copies that leave the machine — backups, a sync target, an accidental archive — and against nothing once the session is running, since an unlocked agent hands the key to any process running as this user.
`AGENTS.md` records the same reasoning for the deferred TPM2 unlock: convenience against a deliberately narrow threat model, decided once rather than per incident.

## Decision

Generate `~/.ssh/id_ed25519` without a passphrase, and set `commit.gpgsign` so signing is the default rather than a flag to remember.
Keep the PAM auto-unlock routes undocumented in configuration — no `/etc/pam.d/sddm` edit, no agent unit enabled — because with no passphrase there is nothing for them to unlock.

The key earns its place as a signing identity, not as push auth: the yadm remote pushes over HTTPS with `gh`'s credential helper, so this key is used for commit signatures and for `ssh` to hosts.

## Consequences

Any copy of `~/.ssh/id_ed25519` that leaves the machine is a total compromise with no cracking step, so it must never enter a backup, a sync target, or an archive.
The protection that remains is the LUKS root, which the machine's own boot path defends ([ADR-0098](0098-luks-discards-header-flag.md) covers the same volume) and which the deferred TPM2 work would narrow further.
Signing works with no agent, no PAM module and no prompt, which is also why it survives a fresh clone on a machine where nothing has been set up yet.
Revisiting this means generating a replacement key with a passphrase and choosing one of the unlock routes above: `ssh-add` per boot is the cheapest, `pam_gnome_keyring` costs a root-owned PAM line and ties the passphrase to the login password, and either is defeated by fingerprint login.
Rotating the key also means re-registering the public half on GitHub as a *signing* key, which is separate from the authentication key slot.
