# Proposal: secrets with yadm and git-crypt, one age key, and new-machine logins approved from a phone

Status: proposed, not accepted. A design write-up, not a decision — see `docs/BACKLOG.md`.
An ADR is written when it is accepted; until then this file changes freely.
The login half is implemented on branch `ccr-b7a9887e-24583a`, untested on a real machine.

## Problem

- API keys sit in untracked `.env` files such as aichat's: one copy per machine, in no backup, on no new machine.
- A new machine needs two logins, `tailscale up` and `gh auth login`, that ADR-0111 has the bootstrap only warn about, so setup takes two bootstrap runs with hand work between them.

## Design

**The secrets live beside their configs, encrypted by git-crypt through yadm.**
A file such as `~/.config/aichat/.env` is tracked by yadm and marked in a `.gitattributes` beside it (`~/.config/aichat/.gitattributes`: `.env filter=git-crypt diff=git-crypt`).
On the owner's machines it is plain, where its tool expects it; in the repository, and so on GitHub, it is encrypted; git does both on every commit and checkout.
A secret changes by editing the file and committing, like any other config.
git-crypt's key is a random key file, so the public ciphertext cannot be guessed at; file names stay visible, contents do not.
This is yadm's own supported mechanism (`yadm git-crypt`), and it needs no decrypt step of ours.
Only secrets that can be rotated go in; recovery material (GitHub 2FA codes, the LUKS passphrase) stays offline.

**One age key opens everything.**
The owner's age key, one line of text, is stored unprotected in `~/.config/age/key.txt` on every machine of the owner's, `nuc` included, so nothing prompts after setup.
It does one job: it protects the git-crypt keys.
A private repository, `secrets`, holds the keys and nothing else:

- `key.age`: the age key, protected with a passphrase of four or five random words, not reused anywhere (`age -p`, whose scrypt makes each guess cost about a second, so an attacker holding the file manages thousands of guesses a second, not billions);
- `dotfiles.git-crypt.key.age`: the dotfiles' git-crypt key, encrypted to the age key;
- `homelab.git-crypt.key.age`: the homelab repository's git-crypt key, encrypted to the age key.

Each repository has its own git-crypt key, so a compromised `nuc` leaks the homelab's secrets and not the dotfiles'.

One passphrase therefore unlocks everything, and it is kept in the owner's browser password manager, so it cannot be forgotten; reading the secrets then needs both the Google and the GitHub account.
There is no paper copy: every machine of the owner's holds the key in plain, and losing all of them together with GitHub would cost rotating the API keys, which are rotatable by rule, not data.
The homelab repository uses git-crypt the same way, with its own key: its secret files are plain in the checkout where compose reads them, and encrypted in git.
An agent is limited by having an identity of its own, not by rules on the owner's machines.
A service account, such as the homelab agent's, never gets the key or the repository.

**New machine: one command, one device the owner has, one passphrase.**
`new-machine` runs the bootstrap, then, at a terminal, loads `environment.d` and runs what is missing:

1. `tailscale up --qr` and `gh auth login` in device-code mode with the local browser suppressed.
   Both are approved on the phone or on a machine with a signed-in browser; with neither, on any browser with the GitHub password and a recovery code.
   A headless machine is no different.
2. Clone `secrets`, decrypt `key.age` with the passphrase into `~/.config/age/key.txt`, decrypt `dotfiles.git-crypt.key.age` with it, and `yadm git-crypt unlock` the dotfiles with that key, which puts every secret in place.

Then it runs the bootstrap again.
Bootstrap steps keep ADR-0111's rule: a step never starts a login, so hooks, CI and the post-update run only warn.

**Agents.**
Claude and pi are denied `age` and `git-crypt` outright, and reading the age key file and the git-crypt key yadm keeps under its repository.
These are guardrails against accidents, not isolation: the keys are usable by anything running as the owner, and an unlocked secret file is readable by an agent whatever the denies say.

**Signing keys.**
ADR-0100 allowed a key without a passphrase only on an encrypted root, and `nuc`'s signing key already broke that.
The rule is relaxed with this plan's ADR: keys without passphrases on the owner's own machines, disk encryption recommended and not required.

**Checks.**
`yadm add-secret <file>` (`bin/git-add-secret`, which git runs for an unknown `add-secret` command) is how a secret file is tracked: it marks the file in the `.gitattributes` beside it, drops a `.gitignore` line that named it, stages it, checks the staged copy is ciphertext, and commits; it refuses a file already committed in plain, which would need rotating rather than encrypting.
A yadm pre-commit hook refuses a commit that would store a file marked for git-crypt in plain (`git-crypt status -e`): a file committed before its `.gitattributes` line is published unencrypted.
`maintenance` reports commits in `secrets` not yet pushed.

**Incidents.**
A lost machine: revoke the GitHub CLI's authorization first (every machine logs in again, one device code each), remove the device from the tailnet, then rotate what that machine could read.
A suspected leak of a key: rotate every secret it protects, since git history keeps the old ciphertext; git-crypt cannot re-key a repository in place, so a new git-crypt key means re-adding the files under it; a new age key means re-encrypting the files in `secrets` to it.

## The homelab side

Agreed with the homelab repository's plans:

- `nuc`'s service secrets are files in that repository encrypted by git-crypt with the homelab's own key, plain in the box's checkout where compose reads them.
- Its agent gets a Unix user and a signing key of its own, so its commits are told from the owner's; it keeps sudo, and works on GitHub with a token of the owner's.
  A GitHub account of its own is the step to take if it starts opening pull requests on other people's repositories.
  Commits signed by the owner or by the agent deploy.
- gickup mirrors every repository of the owner's onto `nuc`, `secrets` and the dotfiles included, encrypted as on GitHub.
- `nuc` is rebuilt when its backup disk arrives: Debian and ext4 as now, the agent's user from first boot instead of a live migration, disk encryption with TPM unlock (the box has a TPM 2.0).
- Each repository's bootstrap installs Tailscale if it is missing, so neither depends on the other: this one sets up the owner's account, that one the system.

## Accepted costs

- Anything running as the owner, or as root, on any of the owner's machines can read every secret, the homelab agent through sudo included. The answer to a compromise is rotating.
  That is today's exposure for the `.env` files already on each machine; what is new is that one key opens all of them from any machine.
- The encrypted secret files are public forever in the dotfiles' history; they are safe while the git-crypt key is, and the answer to a leaked key is rotating the secrets.
- File names of secrets are public.
- `key.age` is on GitHub and mirrored to `nuc`, so only the passphrase protects it there.
- `gh` logins cannot be revoked one machine at a time.
- The homelab agent acts on GitHub as the owner, and until `nuc` is rebuilt it also runs as the owner.

## Weighed and dropped

- `pass` with a GPG key: a password manager's commands for looking things up by hand, at the cost of a keyring, an agent and a pinentry beside the sops and age the homelab needs anyway; these secrets are files that tools read.
- Logging in from stored tokens: Tailscale has no credential both long-lived and user-owned (OAuth clients force tags, which break user-identity SSH and Taildrop; auth keys expire in 90 days), and a shared `gh` token cannot be fine-grained without breaking `35_signing_key.sh`'s scope check.
- A key per machine with per-file recipients, or keeping the key off unencrypted machines and typing the passphrase per run: special cases for `nuc`, which is the owner's machine like any other.
- Pulling the key from another machine over Tailscale SSH, a USB stick with a deploy key, TPM wrapping, a YubiKey, tagging servers out of the SSH mesh: machinery for a yearly event, or doors on the owner that do not contain an agent.
- sops files in the dotfiles or in the `secrets` repository, decrypted by a bootstrap step: a second mechanism beside yadm's own, and an edit-then-rerun workflow.
- sops in the homelab repository, decrypted by root into `/run` so the agent's checkout stays encrypted: the agent can become root, so that wall protected little, and one tool in both repositories was preferred (2026-11-16).
- `yadm encrypt`: one all-or-nothing archive, encrypted by default with a passphrase that anyone could guess at offline in a public repository.
- yadm templates (a failed lookup writes an empty key, 0644 output, decrypts on every pull), passage (unmaintained).

## Build

Nothing below is done until its line says so; `docs/STATE.md` tracks where this stands.

**1. The login half: built on branch `ccr-b7a9887e-24583a`, to test on `dell` and merge.**
It holds the login warnings, `new-machine`'s logins, `sops` and `age` declared, the agent denies and `docs/access.md`.
Checks before merging:

- `tailscale up --qr --ssh --operator=$USER` prints a QR code (on a logged-in machine, read it from `tailscale up --help` instead of logging out).
- `GH_BROWSER=true gh auth login --hostname github.com --git-protocol https --web --scopes admin:ssh_signing_key` prints a code and opens no browser.
- In Claude and in pi, asking the agent to run `sops --version` or `age --version` is refused.

**2. The owner's one-time setup, by hand, outside any AI session.**
Not done before step 3's pre-commit hook exists, so a plain secret cannot slip into the public repository.

    age-keygen -o key.txt                       # prints the public key, age1...
    age -p -o key.age key.txt                   # asks the passphrase: four or five random words
    # save the passphrase in the browser's password manager, then:
    install -D -m 600 key.txt ~/.config/age/key.txt && shred -u key.txt

    yadm git-crypt init
    yadm git-crypt export-key gc.key
    age -r age1... -o dotfiles.git-crypt.key.age gc.key && shred -u gc.key

    gh repo create secrets --private --clone && cd secrets
    mv ../key.age ../dotfiles.git-crypt.key.age .
    git add -A && git commit -m "secrets: keys" && git push

    # then, for each secret file:
    yadm add-secret ~/.config/aichat/.env
    yadm push

**3. The rest, once `secrets` exists.**
Before step 2, built on branch `ccr-b7a9887e-24583a`: `git-crypt` declared and `sops` dropped, the pre-commit hook (`yadm/hooks/pre_commit`, which refuses when `git-crypt status -e` fails), the agent denies for `git-crypt` and the keys. Debian 13 ships git-crypt 0.7.0. After it: the key step in `new-machine`, the `maintenance` check, then the ADR (which also relaxes ADR-0100) and the removal of this file.

Untested: whether `GH_BROWSER=true` keeps `gh` from opening a browser.
