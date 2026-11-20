#!/usr/bin/env bash
# One passphraseless keypair per machine (docs/adr/0117): minted here,
# registered on GitHub in both slots (signing, and the authentication list
# the fleet's sshd machines seed authorized_keys from), and printed for a
# person to commit to git/allowed_signers.  The upload is the only hosted
# half; a signature or a login needs the private key, which never leaves this
# machine.
set -euo pipefail

key="$HOME/.ssh/id_ed25519"
name="$(hostnamectl --static 2>/dev/null || hostname)"
# Bare machine name on both GitHub lists (docs/adr/0117): the signing list's
# -signing suffix was ADR-0109's, kept when the key was single-purpose; both
# slots now hold the same keypair, and each list reads better naming the
# machine than naming the use.
title="$name"
signers="${XDG_CONFIG_HOME:-$HOME/.config}/git/allowed_signers"

# ADR-0100 accepted a passphraseless key only because LUKS covers it at rest;
# anywhere else this would mint an unprotected total-compromise secret.
# The chain is walked, not the root device inspected: a rebuilt host can sit on
# LVM (or any other layer) above the crypt device, and asking the top device
# alone would refuse a machine that is encrypted.
root=$(findmnt -no SOURCE / | sed 's/\[.*//')
if ! lsblk -sno TYPE "$root" 2>/dev/null | grep -qx crypt; then
  log warn "machine key: root is not encrypted; run 'ssh-keygen -t ed25519 -C \"$title\"' by hand"
  exit 0
fi

# NEVER regenerate over an existing key: its fingerprint is registered on
# GitHub and in allowed_signers, so a new one silently breaks every signature
# already made and leaves the trust list pointing at a key that no longer exists.
if [[ ! -f "$key" ]]; then
  log info "Generating machine key $title..."
  install -d -m 700 "$HOME/.ssh"
  ssh-keygen -q -t ed25519 -N '' -C "$title" -f "$key"
fi

# gh holds public halves only, so it can register a signing key but never make one.
# Not a failure when it cannot: signing works locally without GitHub verifying it.
# 30_mise.sh installs gh and the number orders this step after it; the check covers a failed install.
if ! command -v gh &>/dev/null; then
  log warn "machine key: gh is not installed; register $key.pub as a signing key by hand"
  exit 0
fi

# Listing and creating signing keys needs this scope, which gh's default login lacks;
# the authentication half (below) additionally wants admin:public_key, which
# new-machine requests alongside it.
# A step never starts a login, so it only names the command (docs/adr/0111).
# The device flow prints a code any signed-in browser can approve at
# github.com/login/device; GH_BROWSER=true keeps it from opening one here (docs/adr/0115).
scope=admin:ssh_signing_key
if ! gh auth status &>/dev/null; then
  log warn "machine key: gh not logged in; run 'GH_BROWSER=true gh auth login --hostname github.com --git-protocol https --web --scopes $scope' and approve the code at github.com/login/device"
  exit 0
fi
if ! gh api -i user 2>/dev/null | grep -i '^x-oauth-scopes:' | grep -q "$scope"; then
  log warn "machine key: gh lacks the $scope scope; run 'GH_BROWSER=true gh auth refresh --hostname github.com --scopes $scope' and approve the code at github.com/login/device"
  exit 0
fi

# A failed listing must not fall through to a blind POST: GitHub answers a
# duplicate key with 422 and the step would fail the whole bootstrap.
if ! registered=$(gh api user/ssh_signing_keys --jq '.[].key' 2>/dev/null); then
  log warn "machine key: cannot list GitHub signing keys; register $key.pub by hand"
  exit 0
fi

pub=$(cut -d' ' -f1,2 "$key.pub")

if ! grep -qxF "$pub" <<<"$registered"; then
  log info "Registering $title on GitHub..."
  gh api --method POST user/ssh_signing_keys -f title="$title" -f key="$pub" >/dev/null
fi

# The same keypair also fills the authentication slot (docs/adr/0117): the
# account's key list is the fleet's directory, seeded into authorized_keys by
# 36_authorized_keys.sh on every machine whose sshd answers.  A separate
# auth key would buy nothing -- its public half would be published here too.
# The public `user/keys` API needs no token, so the presence check needs no
# scope; only the POST does.  $name is the hostname; the login is what the
# endpoint wants, from gh when it is logged in, the environment otherwise.
login=$(gh api user --jq .login 2>/dev/null) || login=${GITHUB_USER:-Susensio}
if ! curl -fsS --max-time 10 "https://api.github.com/users/$login/keys" 2>/dev/null \
  | grep -qF "$(cut -d' ' -f2 "$key.pub")"; then
  # A step never starts a login, so it only names the command (docs/adr-0111).
  if ! gh api -i user 2>/dev/null | grep -i '^x-oauth-scopes:' | grep -q admin:public_key; then
    log warn "machine key: run 'GH_BROWSER=true gh auth refresh --hostname github.com --scopes admin:public_key' and approve the code at github.com/login/device, so $key.pub joins the account's key list"
  elif ! registered_auth=$(gh api user/keys --jq '.[].key' 2>/dev/null); then
    log warn "machine key: cannot list GitHub authentication keys; register $key.pub by hand"
  elif ! grep -qxF "$pub" <<<"$registered_auth"; then
    log info "Registering $name as an authentication key..."
    gh api --method POST user/keys -f title="$name" -f key="$pub" >/dev/null
  fi
fi

# allowed_signers is a tracked file, so the line is printed rather than written:
# a step that edits it would leave every new machine with a dirty tree.
if ! grep -qF "$(cut -d' ' -f2 "$key.pub")" "$signers" 2>/dev/null; then
  log warn "machine key: add to $signers then commit:"
  printf '\n%s %s\n' "$(git config user.email)" "$(cat "$key.pub")"
fi
