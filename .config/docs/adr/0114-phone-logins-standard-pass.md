# ADR-0114: Keep new-machine logins as phone-assisted commands and secrets in a standard pass store whose subkeys are copied by hand, instead of ADR-0113's token logins and automated key delivery

Status: Proposed
Date: 2026-11-13

## Context

[ADR-0113](0113-pass-vault-bootstrap-tokens.md) was proposed to make a new machine's logins and its vault key arrive with as little human help as possible.
Its GitHub path still used `gh auth login` with a device code typed on the phone; what it automated was the rest: the Tailscale join, from a stored credential, and the GPG key's delivery, as a passphrase-protected export in the store reached by device code, by a USB stick carrying a read-only deploy key, or from another machine, then imported through loopback plumbing so a bootstrap asked for the passphrase once, with an optional TPM wrap.
Several of those parts were untested.

Weighed against what it saved, that was a poor trade.
A new machine arrived about once a year, and the Tailscale login it removed could already be finished from a phone: `tailscale up --qr` prints the login URL as a code to scan, and the phone completes the identity provider's login.

The automated Tailscale join also had no good credential.
An OAuth client never expires, but every node it joins must be tagged, and Tailscale treats tag ownership and user ownership as exclusive: the Tailscale SSH rules of [ADR-0109](0109-tailscale-ssh-mesh-per-machine-signing-keys.md) would move from user identity to tags, and Taildrop, which `25_tailscale.sh` sets the operator for so `omarchy tailscale send` and `receive` work, does not reach tagged devices.
An untagged auth key expires within 90 days, so at a yearly bootstrap it would almost always be stale.

The second problem ADR-0113 addressed was real and ongoing: API keys in untracked `.env` files such as aichat's, one copy per machine, in no backup.
That needed a store, not automated delivery.

## Decision

The login steps keep [ADR-0111](0111-rerun-checked-by-state-logins-warn.md)'s rule unchanged: they never start a login, and they warn every run with the command.
The commands they name are the phone-assisted ones: `tailscale up --qr`, and `gh auth login --web --scopes admin:ssh_signing_key` (or `gh auth refresh` with the same scope), which prints a device code that the phone can complete.
On a machine with a browser it also opens one; prefixing `GH_BROWSER=/bin/true` keeps the flow on the phone.

Secrets a person or a workstation tool uses live in a standard pass store in a private repository, holding only secrets that can be rotated, cloned once `gh` is logged in.
Among them is each server's recovery key, such as the homelab's age key, so a server rebuild starts from the store.

One personal GPG key opens the store.
Its primary key certifies only and stays offline, with its backup, on media kept apart from every machine; workstations hold only its encryption subkey.
A new workstation receives that subkey by hand, from the offline media or another workstation, as a passphrase-protected export (`gpg --export-secret-subkeys`), so nothing unprotected crosses a USB stick or a network.
After import, the subkey's passphrase is removed only where the workstation's root is encrypted; on any other machine it keeps its passphrase.
Nothing in the bootstrap fetches, imports or re-protects the key.

Files a tool insists on reading, such as aichat's `.env`, are declared in one manifest of `entry target` lines and written by one step only when missing, at mode 600, and only on an encrypted root.
A file is regenerated from the store by deleting it and rerunning that step; changes go through `pass edit`, never into the written file.
Without the store or the key, the step warns, like the login steps.

`maintenance` reports store commits not yet pushed and a subkey that expires within a month.

Servers hold no pass key.
Their services' secrets belong to the repository that configures them, which decides its own mechanism; this repository's only link to them is the personal GPG key, which such a repository may name as a recipient, and the recovery key the store keeps.

Agents are denied the commands that decrypt (`pass`, `gpg -d` and `--decrypt`, `sops -d`) in every harness.

Incidents get a fixed response:

- A lost or retired workstation: revoke its copy's trust by replacing the encryption subkey, re-encrypt the store with `pass init`, and rotate whatever that workstation could read.
- A suspected compromise of the store or a subkey: the same, and rotate every secret in the store, since the git history keeps every ciphertext.
- A lost offline backup of the primary key: create a new key and re-encrypt while a workstation can still decrypt; the store survives as long as one subkey does.

## Consequences

A new machine costs two phone logins and one manual subkey copy, about a minute once a year, and the bootstrap gains one step, one manifest and two `maintenance` checks instead of a delivery system.
The design does not depend on loopback-pinentry automation or TPM integration; the manual export, import and passphrase removal still need exercising once before they are relied on.

The tailnet's ownership model, the SSH policy and Taildrop stay as they were, since every node still joins as the user.

A subkey without a passphrase is a wider exposure than [ADR-0100](0100-passphraseless-signing-key.md)'s signing key, though both rest on LUKS at rest.
A stolen signing key forges commits; a stolen store subkey reads every secret in the store.
That wider blast radius is accepted for the same reason, and because every secret in the store can be rotated.

Any process running as the user can use that subkey.
The agent denies are guardrails against accidental access, not isolation: a compromised or malicious process with the user's uid can read the key file and decrypt without the commands they name.

The store inherits the known costs of pass: entry names and change dates are visible to anyone who can read its repository, and a file written from it drifts silently if edited in place.

If yearly logins ever become frequent, for example with many short-lived machines, ADR-0113's delivery can be layered on this store without changing it.
