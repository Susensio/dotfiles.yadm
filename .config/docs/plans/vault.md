# Proposal: a pass vault in the `secrets` repository, and git-crypt unlocked with its GPG key

Status: proposed on 2026-11-18, not built. It would amend [ADR-0115](../adr/0115-yadm-git-crypt-one-passphrase.md) where it says how the git-crypt key is kept; how secrets are encrypted in the dotfiles does not change.

## Problem

Some secrets are not files a tool reads, and not website logins either: the homelab's restic password, the git-crypt key, 2FA recovery codes.
Today they have no proper home: the restic password sits in the browser password manager under a made-up site, and `secrets` holds one locked key file.
The browser password manager stays for website logins; it is not meant for these.

## Two kinds of secret

- Config secrets, files tools read (aichat's `.env`): unchanged, in the dotfiles, encrypted by git-crypt (`docs/secrets.md`).
  Moving them into a vault would need a step on every machine that writes them back out, the template-and-fetch design ADR-0115 dropped.
- Recovery secrets, looked up by hand on a new machine or a rebuild: in a vault.

ADR-0115 dropped `pass` because the secrets then in question were files tools read; these are the ones `pass` is for.

## Design

- `secrets` (private, `~/Projects/secrets`) becomes a `pass` store: one GPG-encrypted file per entry, e.g. `homelab/restic`, `github/recovery-codes`.
- One GPG key, made for this store alone, encrypts it. Its private half is exported protected by the master passphrase and committed in the same repository, so from outside the store is one thing behind one passphrase, like a KeePass file.
- The dotfiles' git-crypt key is added for that GPG key (`yadm git-crypt add-gpg-user <id>`), which commits the git-crypt key encrypted to the GPG public key into the dotfiles. A new machine unlocks with `yadm git-crypt unlock` and no exported key file; `dotfiles.git-crypt.key.age` and age go.
  That committed file is public-key ciphertext: it gives an attacker nothing to guess a passphrase against, unlike a passphrase-locked key file.
- The master passphrase: five or six random words, memorised, with a paper copy at home next to the GitHub recovery codes. Not in the browser password manager.
  GPG protects its private key with a weaker key derivation than age's scrypt or KeePass's Argon2, so each guess is cheaper; the extra words make up for it, and the repository stays private.
- Claude and pi are denied `pass` and `gpg`, as they are denied `age` and `git-crypt` today.

KeePassXC with a `.kdbx` file was the alternative: one file and a passphrase, a GUI, and good phone apps.
`pass` wins here because the store is git-native on Linux, gpg-agent asks once per session, and the same GPG key unlocks git-crypt.
A phone vault was weighed and is not needed: on a new machine the machine itself reads the vault, and the phone only approves logins.

## Friction

| Action | Passphrase |
|---|---|
| Dotfiles commit, pull, checkout | never: git-crypt keeps its key in the repository after the first unlock |
| New machine | once: `gpg --import`, then `yadm git-crypt unlock` |
| `pass show homelab/restic` | once, then gpg-agent caches it for the session |
| Homelab day to day | never |
| Commit signing | unchanged: SSH keys, not GPG |

On `nuc` the GPG key can be deleted from the keyring after the unlock, so the agent's user, which has sudo, does not find even the locked copy there.

## New machine

1. `new-machine`'s logins: Tailscale and GitHub, approved on the phone.
2. Clone `secrets`, `gpg --import` its key, type the passphrase.
3. `yadm git-crypt unlock`: every dotfiles secret is in place.

This replaces the `TODO:` in `new-machine` (clone `secrets`, `age -d`, `yadm git-crypt unlock`).

## Build, once accepted

1. By hand, outside any AI session: make the GPG key, export it protected, `pass init` in `secrets`, move the restic password and recovery codes in, `yadm git-crypt add-gpg-user`, test an unlock in a throwaway clone, then delete `dotfiles.git-crypt.key.age`.
2. `new-machine`: the three steps above; `gnupg` and `pass` in the dependencies; the agent denies.
3. ADR-0115 amended (the key part) and `docs/secrets.md` brought in line.

The homelab side is its own plan (`docs/plans/secrets.md` in that repository): its secrets stay on the box under restic, and only the restic password lives here.
