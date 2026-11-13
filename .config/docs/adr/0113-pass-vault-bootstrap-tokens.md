# ADR-0113: Keep workstation secrets in a pass store unlocked by one personal GPG key, and let bootstrap log in from its tokens, instead of browser logins, a public store, passage or per-server pass keys

Status: Proposed
Date: 2026-11-13

## Context

A new machine needed two browser logins before its bootstrap could finish: `tailscale up` for `25_tailscale.sh` and `gh auth login` for `35_signing_key.sh`.
[ADR-0111](0111-rerun-checked-by-state-logins-warn.md) had made both steps warn with the command every run rather than start a login, because a step that opens a browser inside a bootstrap other hooks run is a prompt nobody sees.

Machine secrets had no home either.
API keys sat in untracked `.env` files such as aichat's, one copy per machine, in no backup and on no new machine.
Web logins were already in Chrome's password manager, which has no CLI a step could read.

The machines were `dell`, an Omarchy laptop on LUKS whose user logs in sometimes by password and sometimes by fingerprint, and `nuc`, a headless Debian server without LUKS whose services start unattended and whose configuration belongs to the homelab repository.
More were expected: a desktop, a VPS, a router.

Several shapes were weighed and discarded:

- `yadm encrypt` restores one all-or-nothing archive as plaintext files, encrypted with GPG's symmetric mode, and gives a store with no per-secret access.
- yadm `##template.esh` alternates rendering from `pass show`, read from yadm 3.x and esh source and not run: a failed lookup inside `<%= %>` does not stop esh's `set -e`, so a locked agent would overwrite a working `.env` with an empty key; the output takes the template's tracked mode, 0644; and auto-alt re-renders on almost every yadm command, so pulls would decrypt and pop pinentry.
- A single age file of bootstrap tokens covered the two logins and nothing else.
- passage (pass on age) removed GPG's agent and pinentry, but had no release in two years and an unanswered backlog of about 20 pull requests and 30 issues.
- A public store was simpler to reach, since only the key would move, but published entry names, change history and ciphertext open to harvest-now-decrypt-later; a read-only deploy key gave the same "only keys move" property to a private one.
- One pass key per server, generated there and scoped to a `hosts/<name>/` folder, turned out to protect nothing: an unattended server key without a passphrase sits on the same disk as the ciphertext it opens, and the shape forced enrolment, re-encryption with the personal key on the server, and a second repository to keep the personal key out of server clones.
- pam-gnupg and GNOME Keyring unlock only from a typed password, which fingerprint logins never supply, and Omarchy runs no GNOME session.
- A YubiKey would make the key unextractable and the passphrase unattackable offline; it was deferred, not rejected.

## Decision

Secrets a person or a workstation tool uses live in one pass store, in one private repository, and hold only secrets that can be rotated.
Long-lived recovery material (2FA recovery codes, the LUKS passphrase backup, the offline primary key) stays offline.

One personal GPG key opens the store.
Its primary key is kept offline and certifies only; workstations hold its subkeys, made on NIST P-256 so a TPM can wrap them, since TPMs do not implement Curve25519.
A passphrase-protected export sits in the store repository under `.keys/`, where `pass ls` does not list it.

A new machine gets the store and the key from whichever source is available:

- GitHub alone: `gh auth login` with a device code typed on the phone, then a clone.
- A USB stick: the key export plus a read-only deploy key for the store repository, which clones it over SSH; neither changes, so the stick never goes stale.
- Another machine: copied over SSH.

The bootstrap reads the passphrase once and feeds it to every GPG operation through loopback pinentry, so a new machine costs one passphrase.
On a workstation whose root is encrypted, the key is then held without a passphrase, the trade [ADR-0100](0100-passphraseless-signing-key.md) made for the signing key, or wrapped by the TPM with `keytotpm` where that has been shown to work; there are no daily prompts.
Where the root is not encrypted, the key keeps its passphrase.

Servers hold no pass key and no store.
A server's own bootstrap may take the passphrase once, decrypt in RAM what the bootstrap itself needs, such as the tailnet join credential, and keep nothing.
Secrets a server's services consume belong to the repository that configures that server: for `nuc`, the homelab repository, encrypted with sops to the server's age key and to this personal GPG key, with the server's age key kept in this store for rebuilds.

Each secret lives in exactly one place.
A workstation that needs a server's secret reads it from that server's repository with `sops -d`, and never copies it into the store.

[ADR-0111](0111-rerun-checked-by-state-logins-warn.md)'s login rule is narrowed, not reversed: a step still never starts an interactive or browser login, but it may log in non-interactively from a token it decrypts from the store, as in `gh auth login --with-token` and `tailscale up --auth-key`.
A step touches the store only when the state it would fix is missing, so reruns and the unattended post-update hook never decrypt.
With no store or no key, the step warns with the commands for each source and exits 0, as before.

Files a tool insists on reading, such as aichat's `.env`, are declared in one manifest of `entry target` lines and written by one step only when missing, at mode 600, and only on an encrypted root.

Agents are denied the commands that decrypt (`pass`, `gpg -d` and `--decrypt`, `sops -d`) in every harness, because a key without a passphrase is usable by any process running as the user.

## Consequences

A new machine's bootstrap costs one passphrase, plus a device code when GitHub is the only source.
The gh token and the tailnet join credential reach every later machine through the store, so neither login opens a browser.

The passphrase is a single point of failure.
Losing it loses the store unless the offline primary key and its backup are reachable; leaking it, together with the repository, exposes every current secret.
The response is fixed in advance: new subkeys, every secret rotated, the store re-encrypted.

On a workstation, any process running as the user can decrypt, at any time, not only while a cache is warm.
The agent denies are what stand between an AI session and the store, and they cover only the commands they name.

A file written from the store drifts silently if it is edited in place, because the step never overwrites.
A change goes through `pass edit`, the file is deleted, and the step rerun.

pass commits into its own repository, which needs pushing like any other; a `maintenance` check for unpushed store commits is the guard.
A GPG subkey with an expiry date stops new encryption when it lapses.

Entry names, and when each changed, are visible to anyone with read access to the store repository, and so to any machine holding the read-only deploy key.

Several things were reasoned but not run: whether `gpg --import` of the export prompts under loopback, whether the passphrase can be removed through loopback, whether `keytotpm` accepts an empty passphrase on `dell`'s TPM, and whether the distributions ship GnuPG's `tpm2d`.
Until each is tested, the step falls back to keeping the passphrase.

The kind of tailnet join credential was left open: an OAuth client that does not expire but forces tags on every node it joins, which would move the Tailscale SSH policy from user identity to tags, or an auth key that expires within 90 days and so would be stale at most bootstraps.
The homelab agent's own Tailscale OAuth client stays separate, without the `auth_keys` scope, so the agent can never add a node.

CI bootstraps have no passphrase, so they exercise only the warning path.
