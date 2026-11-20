# ADR-0115: Encrypt dotfiles secrets with yadm's git-crypt and one passphrase on a private keys repository, instead of sops, an age key pair or yadm encrypt

Status: Accepted
Date: 2026-11-16

## Context

API keys sat in untracked `.env` files such as aichat's: one copy per machine, in no backup, on no new machine.
A new machine also needed two logins, `tailscale up` and `gh auth login`, that [ADR-0111](0111-rerun-checked-by-state-logins-warn.md) has the bootstrap only warn about, so setup took two bootstrap runs with hand work between them.

Drafts of the design, written and reversed between 2026-11-14 and 2026-11-16, weighed these and dropped them:

- `pass` with a GPG key: a keyring, an agent and a pinentry for looking secrets up by hand, when these secrets are files that tools read.
- sops files, in the dotfiles or in a `secrets` repository, decrypted by a bootstrap step: a second mechanism beside yadm's own and an edit-then-rerun workflow.
  sops in the homelab repository, decrypted by root into `/run`, protected little because the agent there can become root.
- An age key pair that protects the git-crypt keys, stored unprotected on every machine and backed up on paper: a second secret to guard for one job, a passphrase-locked key file does it with one fewer.
- `yadm encrypt`: one all-or-nothing archive, encrypted by default with a passphrase anyone could guess at offline from a public repository.
- yadm templates (a failed lookup writes an empty key, output is 0644, every pull decrypts) and passage (unmaintained).
- A key per machine with per-file recipients, or keeping the key off unencrypted machines: special cases for `nuc`, which is the owner's machine like any other.
- Pulling the key over Tailscale SSH, a USB stick, TPM wrapping or a YubiKey: machinery for a yearly event.
- Logging in from stored tokens: Tailscale has no credential both long-lived and user-owned (OAuth clients force tags, auth keys expire in 90 days), and a shared `gh` token cannot be narrowed without breaking `35_signing_key.sh`'s scope check.

## Decision

Secrets in the dotfiles are encrypted by yadm's git-crypt support.
A secret file sits plain where its tool reads it, is marked `filter=git-crypt diff=git-crypt` in a `.gitattributes` beside it, and is encrypted in git.
`yadm add-secret <file>` tracks one, and a yadm `pre_commit` hook refuses a marked file staged in plain.
Only files the owner wrote and tools merely read become secrets (API keys, OAuth client files); files a tool rewrites (login tokens such as `gh`'s `hosts.yml`, Claude's credentials, pi's `auth.json`) never do.

The git-crypt key is exported, locked with one passphrase of four or five random words (`age -p`, kept in the owner's browser password manager) and stored as `dotfiles.git-crypt.key.age` in the private `secrets` repository.
That repository holds only the dotfiles' locked key: the dotfiles are public, so a locked key there would let anyone guess at the passphrase offline.
The homelab repository takes the same mechanism with its own key, locked under the same passphrase and kept at that repository's root (`git-crypt.key.age`): it is private, so the locked key is no more exposed there, and its rebuild needs only that repository.
There is no age key pair and no paper copy.

New-machine logins are approved from a phone or a signed-in machine: `new-machine` runs `tailscale up --qr` and the `gh` device-code login between two bootstrap passes.
Steps still never start a login.

Claude and pi are denied `age`, `git-crypt` and reading git-crypt's key.

This relaxes [ADR-0100](0100-passphraseless-signing-key.md): keys without passphrases are accepted on the owner's own machines, disk encryption recommended and not required.
`nuc`'s signing key already broke the old rule.

## Consequences

Editing a secret is editing a file and committing; no decrypt step of ours exists, and a new machine needs one `age -d` and one `yadm git-crypt unlock` (superseded: see Corrections).
Secret contents are public ciphertext, safe while the git-crypt key is; file names stay visible, and the history keeps old ciphertext, so a leaked key means rotating every secret it covers and re-adding the files under a new key, because git-crypt cannot re-key in place.
`dotfiles.git-crypt.key.age` is on GitHub and mirrored to `nuc`, so only the passphrase protects it there; `age -p`'s scrypt makes each guess cost about a second, which four or five random words, used nowhere else, withstand.
A new passphrase means re-locking every key file.
Anything running as the owner or root on any of the owner's machines reads every unlocked secret; the agent denies are guardrails against accidents, not isolation, and the answer to a compromise is rotating.
A file committed in plain before its `.gitattributes` line is published unencrypted, which the hook and `add-secret` exist to prevent.
`gh` logins cannot be revoked one machine at a time.

## Corrections

2026-11-20: the key-keeping paragraphs above no longer describe the live mechanism; `docs/plans/vault.md` was accepted and its migration completed the same day.
The git-crypt key is no longer an age-locked export in a private repository: the vault's GPG key (`~/.local/share/secrets/vault-key.asc`, protected by the master passphrase, the store a tool-read directory rather than a project) wraps it through the committed stub (`git-crypt add-gpg-user`), so a fresh clone needs only `gpg --import` and `yadm git-crypt unlock` — no `age -d`, no key file copied.
The paper copy the Decision declined was replaced on acceptance by a deliberate choice: the master passphrase is held in memory only, verified by an occasional decrypt drill, with no paper copy to lose.
The homelab's own locked key (`git-crypt.key.age` at its repository root) was retired with it: the homelab keeps no secrets in git at all now (its `docs/plans/secrets.md`, accepted 2026-11-18).
The `age` and git-crypt denies for Claude and pi stay — as guardrails against accidents by any secrets tool, not because age is part of this design anymore.
The rest of the record — plain-file marking, `add-secret`, the `pre_commit` guard, the relaxation of ADR-0100 — is unchanged.
