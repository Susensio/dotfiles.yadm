# Secrets

[ADR-0115](adr/0115-yadm-git-crypt-one-passphrase.md) records why secrets are encrypted with yadm's git-crypt and one passphrase.
This file is the working rules.

## What becomes a secret file

Files the owner wrote and tools only read: API keys, OAuth client files, an `.env`.
Never a file a tool rewrites: login tokens such as `gh`'s `hosts.yml`, Claude's credentials, pi's `auth.json`.
A rewritten file churns ciphertext on every change and the tool's own login replaces it anyway.
Recovery material (GitHub 2FA codes, the LUKS passphrase) stays offline.

## Adding one, in the dotfiles

1. If the file sits under a folder `yadm/exclude` ignores, allow it first: re-include the folder, ignore its contents, re-include the file.

       !/.config/foo/
       /.config/foo/*
       !/.config/foo/secret.env

2. If a `.gitignore` line names it, `yadm add-secret` drops that line.
3. `yadm add-secret ~/.config/foo/secret.env`: marks it in the `.gitattributes` beside it, stages it, checks the staged copy is ciphertext and commits.
   It refuses a file already committed in plain; that one needs rotating, not encrypting.
4. The `pre_commit` hook refuses any marked file staged in plain.

## Bringing a repo to the vault key

A private repository the owner fully controls may carry its own secrets under git-crypt, wrapped to the vault key: `gmailctl-config` does, and a candidate must be the owner's alone, with no actor that can become root besides the owner (the homelab's agent can, so its repository never gets this).
Every such repository follows the same procedure, run by hand; an agent never runs git-crypt.

1. Check the repository is clean (`git status`), and that every candidate file has never been committed in plain: a plaintext blob in history needs rotating, not encrypting.
2. `git-crypt init`, then `git-crypt add-gpg-user "secrets vault"` (or the full fingerprint; the command prints the resolved key, so check it before confirming): this commits the key stub (`.git-crypt/keys/default/0/<FPR>.gpg`) at the repository's root.
   The stub is public-key ciphertext, but published for good in that repository, so verify the fingerprint first.
3. Mark the files in a root `.gitattributes` and commit it before staging anything: `printf 'credentials.json filter=git-crypt diff=git-crypt\n' > .gitattributes`.
   git applies the filter at staging time, so a file staged ahead of its mark goes in as plaintext.
4. Stage and commit the files, then check: `git show HEAD:<file>` prints ciphertext or something is wrong.
5. A machine that has the repo already unlocks after a pull with `git-crypt unlock`; a fresh clone does the same with the vault key imported first, and nothing copied by hand.
6. `token.json`-style files stay out: classify per the section above before marking anything.

The same procedure with a different key still applies where the vault key must not reach; keep a different key's repository out of the vault-key flow entirely.

## Keys

The vault's GPG key (in `~/Projects/secrets`, `vault-key.asc` protected by the master passphrase) encrypts the pass store and, through the committed stub, every git-crypt repository above.
A new machine imports it (`gpg --import`), then `yadm git-crypt unlock` with no key file; the stub travels with each clone.
The homelab keeps no git-crypt key in git at all (`docs/plans/secrets.md` in that repository); its restic password is a `pass` entry instead.
Claude and pi are denied `gpg`, `pass`, `age` and `git-crypt`, so those commands are run by hand.

A suspected leak of a key: rotate every secret it covers, then re-add the files under a new key.
A leaked vault key widens to every repository whose stub names it, and stubs stay in history, so that rotation covers them all.
