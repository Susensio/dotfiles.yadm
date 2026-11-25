# ADR-0135: Static provider keys in the encrypted env file, not the login store or pass

Status: Accepted
Date: 2026-11-25

## Context

Pi keeps every provider credential in `pi/agent/auth.json`, a plain `0600` file that Pi rewrites on login and token refresh.
Static API keys (OpenCode Go, Google, Groq, Mistral) were pasted there by hand, so a new machine needed the keys typed in again, and the keys existed nowhere in git.
Codex OAuth needs the same file, because Pi refreshes its tokens in place.

The forces were:

- Keys must travel to a new machine (`nuc`, headless) through the vault, with no manual copy.
- Agents must not read the keys, and a read must not leak them into a transcript.
- Pi and the agents' shells must not inherit the keys as environment variables.
- Adding a provider should take a few steps, not a script run per file.

The alternatives weighed were:

- A `pass` lookup in `models.json` (`!pass show …`): the gpg passphrase prompt recurs without a saved passphrase, and a headless or phone-driven session cannot answer it.
- A `sed` extraction from one env file: a fragile parse of the file, and a second source of truth beside the file it reads.
- One file per key under `pi/agent/keys/`: more files to maintain for the same content.
- Exporting the keys from `environment.d` or mise: every shell and agent `env` would expose them.

## Decision

Static provider keys live in `pi/agent/.env`, a single git-crypted file with one `NAME=value` line per key.
`models.json` gives each keyed provider `"apiKey": "!$PI_CODING_AGENT_DIR/bin/env-key NAME"`, and `bin/env-key` sources the file and prints only that variable.
OAuth logins stay in `auth.json`, which is not encrypted, because Pi rewrites it.
`bin/adopt-keys` moves a key from `/login` into the `.env` and `models.json`.
`maintenance` reports a key left in the login store, a locked or unencrypted `.env`, and a `models.json` entry with no key behind it.

## Consequences

- A fresh clone that is unlocked, or already unlocked, gets working providers with no relogin, and `nuc` needed no extra step.
- The keys sit in plain text under `$HOME` while unlocked, as `auth.json` already did.
- The vault key is now the one that protects the provider keys, so a vault leak exposes them too (ADR-0115).
- Agents are denied `.env` and the login store in both Pi and Claude, with the Claude denies mapped from Pi's list and kept in step by `maintenance`.
- A key that has been read into a transcript must still be rotated by hand; the layout does not undo a leak.
- The file's name is `.env`, which Pi's `*.env` denies already cover. Naming it anything else would have needed a new deny.
- Adding a provider is still two edits: a line in `.env` and an entry in `models.json`, or `adopt-keys` after `/login`.
