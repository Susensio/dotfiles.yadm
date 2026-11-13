# ADR-0114: Keep new-machine logins as phone-assisted commands and secrets in a plain pass vault whose key is copied by hand, instead of ADR-0113's token logins and automated key delivery

Status: Proposed
Date: 2026-11-13

## Context

[ADR-0113](0113-pass-vault-bootstrap-tokens.md) was proposed to spare a new machine its two browser logins, `tailscale up` and `gh auth login`, by keeping their tokens in a pass vault and delivering the vault's key automatically.
Reaching that took a GPG key with an offline primary and P-256 subkeys, a passphrase-protected export in the store, a read-only deploy key, a USB bundle, three sources for the key, loopback plumbing so a bootstrap asked for the passphrase once, and an optional TPM wrap, with several of those parts untested.

Weighed against what it saved, that was a poor trade.
A new machine arrived about once a year, and both logins could already be finished from a phone without a browser on the machine: `gh auth login` offers a device code to type on the phone, and `tailscale up --qr` prints a code to scan.

The automated Tailscale join also had no good credential.
An OAuth client never expires, but every node it joins must be tagged, and a tagged node is owned by the tag rather than the user: the Tailscale SSH rules of [ADR-0109](0109-tailscale-ssh-mesh-per-machine-signing-keys.md) would move from user identity to tags, and Taildrop, which `25_tailscale.sh` sets the operator for so `omarchy tailscale send` and `receive` work, does not reach tagged devices.
An untagged auth key expires within 90 days, so at a yearly bootstrap it would almost always be stale.

The second problem ADR-0113 addressed was real and ongoing: API keys in untracked `.env` files such as aichat's, one copy per machine, in no backup.
That needed a vault, not automated delivery.

## Decision

The login steps keep [ADR-0111](0111-rerun-checked-by-state-logins-warn.md)'s rule unchanged: they never start a login, and they warn every run with the command.
The commands they name are the phone-assisted ones, `gh auth login` with its device code and `tailscale up --qr`, so no browser is needed on the machine.

Secrets a person or a workstation tool uses live in a pass store in a private repository, holding only secrets that can be rotated, with the usual setup: one personal GPG key, and the store cloned once `gh` is logged in.
A new workstation gets the key by hand, from a USB stick or another machine, as pass's own guides describe; nothing in the bootstrap fetches or imports it.
On a workstation whose root is encrypted, the key is held without a passphrase, the trade [ADR-0100](0100-passphraseless-signing-key.md) made for the signing key, so there are no daily prompts.

Files a tool insists on reading, such as aichat's `.env`, are declared in one manifest of `entry target` lines and written by one step only when missing, at mode 600, and only on an encrypted root.
Without the store or the key, the step warns, like the login steps.

Servers hold no pass key.
Their services' secrets belong to the repository that configures them, which decides its own mechanism; this repository's only link to them is the personal GPG key, which such a repository may name as a recipient.

Agents are denied the commands that decrypt (`pass`, `gpg -d` and `--decrypt`) in every harness.

## Consequences

A new machine costs two phone logins and one manual key copy, about a minute once a year, and the bootstrap gains one step and one manifest instead of a delivery system.
Nothing in it depends on untested GPG behaviour or on a TPM.

The tailnet's ownership model, the SSH policy and Taildrop stay as they were, since every node still joins as the user.

The vault solves scattered `.env` files the way most pass users already do, so it inherits their known costs: entry names and change dates are visible to anyone who can read the store's repository, a key without a passphrase is usable by any process running as the user, and a file written from the store drifts silently if edited in place.

If yearly logins ever become frequent, for example with many short-lived machines, ADR-0113's delivery can be layered on this store without changing it.
