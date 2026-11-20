# Proposal: a pass vault in the `secrets` repository, and git-crypt unlocked with its GPG key

Status: built and live (the hand migration passed 2026-11-20 on `dell`, steps 0–6, and the vault proved itself on `nuc`'s rebuild the same night: `pass show homelab/restic` answers there). Entries as built: `homelab/restic`, `homelab/luks`, `dell/luks` (no `github/recovery-codes`; the plan's example name never got used, and the store holds two more entries than the plan sketched — LUKS passphrases under machine names). It amends [ADR-0115](../adr/0115-yadm-git-crypt-one-passphrase.md) where it says how the git-crypt key is kept; how secrets are encrypted in the dotfiles does not change.

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

- `secrets` (private, `~/.local/share/secrets`) becomes a `pass` store: one GPG-encrypted file per entry, e.g. `homelab/restic`, `github/recovery-codes`.
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

## Migration

The old path, `dotfiles.git-crypt.key.age` with its passphrase, stays working until the new one has been proven on two machines.
Every step ends with a check; a failed check stops the migration, and the old path is still there.

**0. Before anything.**
- `gnupg` and `pass` installed on `dell` and `nuc`; the agent denies for `pass` and `gpg` merged first.
- Choose the master passphrase (five or six random words) and write the paper copy first. Type it three times from the paper before using it.
- Note the current state: `yadm status` clean, `sha256sum ~/.config/aichat/.env` written down, `secrets` pushed.

**1. The GPG key, on `dell`.**

       gpg --quick-gen-key "secrets vault" ed25519 cert,sign never     # the master passphrase
       gpg --quick-add-key <FPR> cv25519 encr never

No expiry: an expired subkey stops `pass` and git-crypt from encrypting.
Check: `gpg --list-secret-keys <FPR>` shows the key and its encryption subkey.

**2. The exported key is protected.** The one mistake that cannot be seen later is an export without a passphrase, committed.

       gpg --export-secret-keys --armor <FPR> > ~/.local/share/secrets/vault-key.asc
       G=$(mktemp -d); gpg --homedir "$G" --import ~/.local/share/secrets/vault-key.asc
       echo test | gpg --homedir "$G" --trust-model always -e -r <FPR> | gpg --homedir "$G" -d     # must ask for the passphrase
       rm -rf "$G"

Check: the decrypt asked for the passphrase and printed `test`. Only then `git add vault-key.asc`.

**3. The store.**
`PASSWORD_STORE_DIR=~/.local/share/secrets` in `environment.d`, then `pass init <FPR>`, `pass insert homelab/restic`, the GitHub recovery codes as `github/recovery-codes`.
Check: on `dell`, `pass show homelab/restic | tr -d '\n' | sha256sum`; on `nuc`, `sudo tr -d '\n' </etc/homelab/restic-password | sha256sum`; the two sums are equal. Commit and push `secrets`.

**4. git-crypt for the GPG key.** This commits `.git-crypt/keys/default/0/<FPR>.gpg` into the public dotfiles: public-key ciphertext, safe, but published for good, so check the fingerprint first.

       yadm git-crypt add-gpg-user <FPR>

Check in a throwaway clone with a fresh keyring, nothing from the live machine:

       G=$(mktemp -d); D=$(mktemp -d)
       gpg --homedir "$G" --import ~/.local/share/secrets/vault-key.asc
       git clone -q https://github.com/Susensio/dotfiles.yadm "$D"
       (cd "$D" && GNUPGHOME="$G" git-crypt unlock && sha256sum .config/aichat/.env)
       rm -rf "$G" "$D"

The sum matches the one from step 0. Push the dotfiles.

**5. A second machine.** On `nuc`, as `susensio`: pull `secrets`, `gpg --import vault-key.asc`, `yadm pull`, `yadm git-crypt unlock` (already unlocked: check it decrypts nothing new and `yadm status` stays clean), `pass show homelab/restic`.
Then delete the secret key from `nuc`'s keyring (`gpg --delete-secret-keys <FPR>`), as the design says.

**6. Retire the old path,** only after steps 4 and 5 passed: `git rm dotfiles.git-crypt.key.age` in `secrets`, the made-up restic entry out of the browser password manager, `new-machine` switched to the new steps.
The old key file stays in `secrets`' history; it still opens the same git-crypt key, so the old passphrase must not be reused anywhere.

**Rollback** at any step before 6: delete what the step added (`vault-key.asc`, the store files, the `.git-crypt/keys/default/0/` entry via `git rm`), and the old path still works.
After 6: the old key file is in `secrets`' history (`git show <commit>:dotfiles.git-crypt.key.age`).

## Build after the migration

1. `new-machine`: clone `secrets`, `gpg --import vault-key.asc`, `yadm git-crypt unlock`; `gnupg` and `pass` in the dependencies.
2. ADR-0115 amended (the key part) and `docs/secrets.md` brought in line.

The homelab side is its own plan (`docs/plans/secrets.md` in that repository): its secrets stay on the box under restic, and only the restic password lives here.
