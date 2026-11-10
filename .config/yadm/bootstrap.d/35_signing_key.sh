#!/usr/bin/env bash
# One passphraseless signing key per machine (docs/adr/0109): generated here,
# uploaded by gh, and printed for a person to commit to git/allowed_signers.
# The upload is the only hosted half; a signature needs the private key, which
# never leaves this machine.
set -euo pipefail

key="$HOME/.ssh/id_ed25519"
name="$(hostnamectl --static 2>/dev/null || hostname)"
title="$name-signing"
signers="${XDG_CONFIG_HOME:-$HOME/.config}/git/allowed_signers"

# ADR-0100 accepted a passphraseless key only because LUKS covers it at rest;
# anywhere else this would mint an unprotected total-compromise secret.
if [[ $(lsblk -dno TYPE "$(findmnt -no SOURCE / | sed 's/\[.*//')" 2>/dev/null) != crypt ]]; then
  log warn "signing key: root is not encrypted; run 'ssh-keygen -t ed25519 -C \"$title\"' by hand"
  exit 0
fi

# NEVER regenerate over an existing key: its fingerprint is registered on
# GitHub and in allowed_signers, so a new one silently breaks every signature
# already made and leaves the trust list pointing at a key that no longer exists.
if [[ ! -f "$key" ]]; then
  log info "Generating signing key $title..."
  install -d -m 700 "$HOME/.ssh"
  ssh-keygen -q -t ed25519 -N '' -C "$title" -f "$key"
fi

# gh holds public halves only, so it can register a signing key but never make one.
# Not a failure when it cannot: signing works locally without GitHub verifying it.
# 30_mise.sh installs gh and the number orders this step after it; the check covers a failed install.
if ! command -v gh &>/dev/null; then
  log warn "signing key: gh is not installed; register $key.pub as a signing key by hand"
  exit 0
fi

# Listing and creating signing keys needs this scope, which gh's default login lacks.
# Login and refresh are browser flows, so they run only with a terminal to show the code.
scope=admin:ssh_signing_key
if ! gh auth status &>/dev/null; then
  fix=(gh auth login --hostname github.com --web --scopes "$scope")
elif ! gh api -i user 2>/dev/null | grep -i '^x-oauth-scopes:' | grep -q "$scope"; then
  fix=(gh auth refresh --hostname github.com --scopes "$scope")
fi
if [[ -n ${fix[*]:-} ]]; then
  if [[ -t 0 ]]; then
    "${fix[@]}" || true
  else
    log warn "signing key: gh needs the $scope scope; run '${fix[*]}'"
    exit 0
  fi
fi

# A failed listing must not fall through to a blind POST: GitHub answers a
# duplicate key with 422 and the step would fail the whole bootstrap.
if ! registered=$(gh api user/ssh_signing_keys --jq '.[].key' 2>/dev/null); then
  log warn "signing key: cannot list GitHub signing keys; register $key.pub by hand"
  exit 0
fi

pub=$(cut -d' ' -f1,2 "$key.pub")

if ! grep -qxF "$pub" <<<"$registered"; then
  log info "Registering $title on GitHub..."
  gh api --method POST user/ssh_signing_keys -f title="$title" -f key="$pub" >/dev/null
fi

# allowed_signers is a tracked file, so the line is printed rather than written:
# a step that edits it would leave every new machine with a dirty tree.
if ! grep -qF "$(cut -d' ' -f2 "$key.pub")" "$signers" 2>/dev/null; then
  log warn "signing key: add to $signers then commit:"
  printf '\n%s %s\n' "$(git config user.email)" "$(cat "$key.pub")"
fi
