# Proposal: secrets in sops + age, and new-machine logins approved from a phone

Status: proposed, not accepted. A design write-up, not a decision — see `docs/BACKLOG.md`.
An ADR is written when it is accepted; until then this file changes freely.
The login half is implemented on branch `ccr-b7a9887e-24583a`, untested on a real machine.

## Problem

- API keys sit in untracked `.env` files such as aichat's: one copy per machine, in no backup, on no new machine.
- A new machine needs two logins, `tailscale up` and `gh auth login`, that ADR-0111 has the bootstrap only warn about, so setup takes two bootstrap runs with hand work between them.

## Design

**One key.**
The owner's age key, one line of text, is the root of everything.
A passphrase-protected copy (`age -p`) is committed as `key.age` in the secrets repository, and printed once on paper.
The passphrase is six or seven random words, since every copy rests on it.

**One repository.**
A private GitHub repository, `secrets`, holds sops-encrypted files, all encrypted to the owner's age public key through its `.sops.yaml`:

- one dotenv file per tool that reads one, such as `aichat.env`;
- one `misc.yaml` for loose values;
- each server's age key, kept for its rebuild.

Only secrets that can be rotated go in; recovery material (GitHub 2FA codes, the LUKS passphrase) stays offline.
`sops edit <file>` is how a secret changes, and git is how it reaches other machines.
The homelab repository uses the same tool and names the same age public key as a recipient, so one key edits both.

**Where the owner logs in.**
The secrets go to every account of the owner's, `nuc` included.

| | Encrypted root (`dell`) | Unencrypted root (`nuc`) |
|---|---|---|
| Age key | stored unprotected in `~/.config/sops/age/keys.txt`: no prompts | never stored |
| Writing or refreshing `.env` files | silent | asks the passphrase, holds the key in memory (`SOPS_AGE_KEY`) for that run |

Files a tool insists on reading are declared in one manifest of `source target` lines and written by one bootstrap step when missing, at mode 600.
A change goes through `sops edit`; the file is deleted and the step rerun.
Without the repository or the key the step warns and the rest of the bootstrap is unaffected.
A service account, such as the homelab agent's, never gets the repository or the key.

**New machine: one command, one device the owner has, one passphrase.**
`new-machine` runs the bootstrap, then, at a terminal, loads `environment.d` and runs what is missing:

1. `tailscale up --qr` and `gh auth login` in device-code mode with the local browser suppressed.
   Both are approved on the phone or on a machine with a signed-in browser; with neither, on any browser with the GitHub password and a recovery code.
   A headless machine is no different.
2. Clone `secrets`, decrypt `key.age` with the passphrase, and store the key where the root is encrypted.

Then it runs the bootstrap again, which writes the files.
Bootstrap steps keep ADR-0111's rule: a step never starts a login, so hooks, CI and the post-update run only warn.

**Agents.**
Claude and pi are denied `sops` and `age` outright, and reading the key file.
These are guardrails against accidents, not isolation: an unprotected key is usable by anything running as the owner.

**Checks.**
`maintenance` reports commits in `secrets` not yet pushed.

**Incidents.**
A lost machine: revoke the GitHub CLI's authorization first (every machine logs in again, one device code each), remove the device from the tailnet, make a new age key, `sops updatekeys` and `sops rotate` on every file here and in the homelab repository, replace `key.age`, rotate what that machine could read.
A suspected leak of the key: the same, and rotate everything, since git history keeps old ciphertext.

## The homelab side

Agreed with the homelab repository (`docs/plan-secrets.md` and `docs/plan-hermes-user.md` there):

- `nuc`'s service secrets are sops files in that repository, encrypted to `nuc`'s age key and the owner's.
- Its agent gets a user, a signing key and per-repository deploy keys of its own, and none of the owner's credentials.
- gickup mirrors `secrets` onto `nuc` as it is on GitHub, encrypted, as a backup; `nuc` never holds a key that opens it.
- `nuc` stays the owner's computer, and Tailscale SSH between the owner's devices stays as ADR-0109 set it.

## Accepted costs

- Everything rests on one passphrase; the paper printout is the last copy of the key.
- `key.age` is on GitHub and mirrored to `nuc`, so an account takeover, `nuc`'s disk or its agent can try the passphrase offline.
- sops encrypts values, not names: variable names and file names are readable to anyone who can read the repository.
- On `nuc`, written `.env` files are plaintext on an unencrypted disk and readable by root, which the agent can become.
- `gh` logins cannot be revoked one machine at a time.

## Weighed and dropped

- `pass` with a GPG key: a password manager's commands for looking things up by hand, at the cost of a keyring, an agent and a pinentry beside the sops and age the homelab needs anyway; these secrets are files that tools read.
- Logging in from stored tokens: Tailscale has no credential both long-lived and user-owned (OAuth clients force tags, which break user-identity SSH and Taildrop; auth keys expire in 90 days), and a shared `gh` token cannot be fine-grained without breaking `35_signing_key.sh`'s scope check.
- Pulling the key from another machine over Tailscale SSH, a USB stick with a deploy key, TPM wrapping, a YubiKey, tagging servers out of the SSH mesh: machinery for a yearly event, or doors on the owner that do not contain an agent.
- `yadm encrypt` (one all-or-nothing archive), yadm templates (a failed lookup writes an empty key, 0644 output, decrypts on every pull), passage (unmaintained), a public repository (ciphertext published forever).

## Build

1. Done on the branch, to test on `dell` and merge: the login warnings, `new-machine`'s logins, `sops` and `age` declared, the agent denies, `docs/access.md`.
2. The owner, by hand, outside any AI session: `age-keygen`, `key.age`, the paper copy, the `secrets` repository, moving the `.env` files in.
   Not before the homelab agent has its own deploy keys in place of the owner's `gh` token.
3. Then: the key step in `new-machine`, the manifest step with its passphrase path for unencrypted machines, the `maintenance` check, and the ADR.

Untested: `SOPS_AGE_KEY` carrying the key for one run, and whether `GH_BROWSER=true` keeps `gh` from opening a browser.
