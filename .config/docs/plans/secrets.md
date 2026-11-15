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

**Every machine the owner has.**
The owner's machines are trusted alike: the key is stored unprotected in `~/.config/sops/age/keys.txt` on each, `nuc` included, so nothing prompts after setup.
An agent is limited by having an identity of its own, not by rules on the owner's machines.

Files a tool insists on reading are declared in one manifest of `source target` lines and written by one bootstrap step when missing, at mode 600.
A change goes through `sops edit`; the file is deleted and the step rerun.
Without the repository or the key the step warns and the rest of the bootstrap is unaffected.
A service account, such as the homelab agent's, never gets the repository or the key.

**New machine: one command, one device the owner has, one passphrase.**
`new-machine` runs the bootstrap, then, at a terminal, loads `environment.d` and runs what is missing:

1. `tailscale up --qr` and `gh auth login` in device-code mode with the local browser suppressed.
   Both are approved on the phone or on a machine with a signed-in browser; with neither, on any browser with the GitHub password and a recovery code.
   A headless machine is no different.
2. Clone `secrets`, decrypt `key.age` with the passphrase, and store the key.

Then it runs the bootstrap again, which writes the files.
Bootstrap steps keep ADR-0111's rule: a step never starts a login, so hooks, CI and the post-update run only warn.

**Agents.**
Claude and pi are denied `sops` and `age` outright, and reading the key file.
These are guardrails against accidents, not isolation: the key is usable by anything running as the owner, and a written `.env` file is readable by an agent whatever the denies say.

**Signing keys.**
ADR-0100 allowed a key without a passphrase only on an encrypted root, and `nuc`'s signing key already broke that.
The rule is relaxed with this plan's ADR: keys without passphrases on the owner's own machines, disk encryption recommended and not required.

**Checks.**
`maintenance` reports commits in `secrets` not yet pushed.

**Incidents.**
A lost machine: revoke the GitHub CLI's authorization first (every machine logs in again, one device code each), remove the device from the tailnet, make a new age key, `sops updatekeys` and `sops rotate` on every file here and in the homelab repository, replace `key.age`, rotate what that machine could read.
A suspected leak of the key: the same, and rotate everything, since git history keeps old ciphertext.

## The homelab side

Agreed with the homelab repository's plans:

- `nuc`'s service secrets are sops files in that repository, encrypted to `nuc`'s root-only age key and the owner's.
- Its agent gets a Unix user, a GitHub account and a signing key of its own, and none of the owner's credentials; it keeps sudo.
  Commits signed by the owner or by the agent deploy.
- gickup mirrors every repository of the owner's onto `nuc`, `secrets` included, encrypted as on GitHub.
- `nuc` is rebuilt when its backup disk arrives: Debian and ext4 as now, the agent's user from first boot instead of a live migration, disk encryption with TPM unlock if the box has a TPM. Nothing here depends on the encryption.
- Each repository's bootstrap installs Tailscale if it is missing, so neither depends on the other: this one sets up the owner's account, that one the system.

## Accepted costs

- Anything running as the owner, or as root, on any of the owner's machines can read every secret, the homelab agent through sudo included. The answer to a compromise is rotating.
  That is today's exposure for the `.env` files already on each machine; what is new is that one key opens all of them from any machine.
- `key.age` is on GitHub and mirrored to `nuc`, so only the passphrase protects it there.
- sops encrypts values, not names: variable and file names are readable to anyone who can read the repository.
- `gh` logins cannot be revoked one machine at a time.
- Until `nuc` is rebuilt, its agent runs as the owner with the owner's GitHub token.

## Weighed and dropped

- `pass` with a GPG key: a password manager's commands for looking things up by hand, at the cost of a keyring, an agent and a pinentry beside the sops and age the homelab needs anyway; these secrets are files that tools read.
- Logging in from stored tokens: Tailscale has no credential both long-lived and user-owned (OAuth clients force tags, which break user-identity SSH and Taildrop; auth keys expire in 90 days), and a shared `gh` token cannot be fine-grained without breaking `35_signing_key.sh`'s scope check.
- A key per machine with per-file recipients, or keeping the key off unencrypted machines and typing the passphrase per run: special cases for `nuc`, which is the owner's machine like any other.
- Pulling the key from another machine over Tailscale SSH, a USB stick with a deploy key, TPM wrapping, a YubiKey, tagging servers out of the SSH mesh: machinery for a yearly event, or doors on the owner that do not contain an agent.
- `yadm encrypt` (one all-or-nothing archive), yadm templates (a failed lookup writes an empty key, 0644 output, decrypts on every pull), passage (unmaintained), a public repository (ciphertext published forever).

## Build

Nothing below is done until its line says so; `docs/STATE.md` tracks where this stands.

**1. The login half: built on branch `ccr-b7a9887e-24583a`, to test on `dell` and merge.**
It holds the login warnings, `new-machine`'s logins, `sops` and `age` declared, the agent denies and `docs/access.md`.
Checks before merging:

- `tailscale up --qr --ssh --operator=$USER` prints a QR code (on a logged-in machine, read it from `tailscale up --help` instead of logging out).
- `GH_BROWSER=true gh auth login --hostname github.com --git-protocol https --web --scopes admin:ssh_signing_key` prints a code and opens no browser.
- In Claude and in pi, asking the agent to run `sops --version` or `age --version` is refused.

**2. The owner's one-time setup, by hand, outside any AI session.**

    age-keygen -o key.txt                 # prints the public key, age1...
    age -p -o key.age key.txt             # asks the six-or-seven-word passphrase
    # print key.txt on paper, then:
    install -D -m 600 key.txt ~/.config/sops/age/keys.txt && shred -u key.txt

    gh repo create secrets --private --clone && cd secrets
    printf 'creation_rules:\n  - age: age1...\n' > .sops.yaml
    mv ../key.age .
    cp ~/.config/aichat/.env aichat.env && sops -e -i aichat.env    # once per .env file
    git add -A && git commit -m "secrets: first files" && git push

The same `age1...` public key goes to the homelab repository as the administrator's recipient.

**3. The rest, once `secrets` exists.**
The key step in `new-machine`, the manifest step, the `maintenance` check, then the ADR (which also relaxes ADR-0100) and the removal of this file.

Untested: whether `GH_BROWSER=true` keeps `gh` from opening a browser.
