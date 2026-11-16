# Secrets

[ADR-0115](adr/0115-yadm-git-crypt-one-passphrase.md) records why secrets are encrypted with yadm's git-crypt and one passphrase.
This file is the working rules.

## What becomes a secret file

Files the owner wrote and tools only read: API keys, OAuth client files, an `.env`.
Never a file a tool rewrites: login tokens such as `gh`'s `hosts.yml`, Claude's credentials, pi's `auth.json`.
A rewritten file churns ciphertext on every change and the tool's own login replaces it anyway.
Recovery material (GitHub 2FA codes, the LUKS passphrase) stays offline.

## Adding one

1. If the file sits under a folder `yadm/exclude` ignores, allow it first: re-include the folder, ignore its contents, re-include the file.

       !/.config/foo/
       /.config/foo/*
       !/.config/foo/secret.env

2. If a `.gitignore` line names it, `yadm add-secret` drops that line.
3. `yadm add-secret ~/.config/foo/secret.env`: marks it in the `.gitattributes` beside it, stages it, checks the staged copy is ciphertext and commits.
   It refuses a file already committed in plain; that one needs rotating, not encrypting.
4. The `pre_commit` hook refuses any marked file staged in plain.

## Keys

The git-crypt key lives only as `dotfiles.git-crypt.key.age` in the private `secrets` repository (`~/Projects/secrets`), locked by the one passphrase.
The homelab's locked key lives at that repository's root, not here.
A new machine runs `age -d` on it with the passphrase, then `yadm git-crypt unlock <key>`.
Claude and pi are denied `age`, `git-crypt` and git-crypt's key, so those commands are run by hand.

A suspected leak of a key: rotate every secret it covers, then re-add the files under a new key.
