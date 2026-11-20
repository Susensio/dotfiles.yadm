#!/usr/bin/env bash
# Seed authorized_keys from the GitHub account's public keys when a bootstrap
# runs (docs/adr/0117): the account is the directory of who "I" am, read at
# the moments it is already trusted -- a first install and every yadm pull's
# bootstrap rerun.  No timer: a standing pull would make a compromised account
# silent root on this machine within a cycle, and a bootstrap-time read keeps
# the trust window one the machine already bets on (it cloned the account's
# repositories).
set -euo pipefail

# Only a machine whose sshd answers needs one; dell runs none, and a container
# has no systemd to ask.  Debian's unit is ssh, Arch's is sshd.
systemctl is-enabled ssh sshd 2>/dev/null | grep -qx enabled || exit 0

# The endpoint is public, so no token is spent and a machine whose login is
# still pending still seeds; gh names the account only when it is logged in.
user=$(gh api user --jq .login 2>/dev/null) || user=${GITHUB_USER:-Susensio}

keys=$(curl -fsS --max-time 10 "https://api.github.com/users/$user/keys" \
  | jq -r '.[].key' 2>/dev/null) || {
  log warn "authorized_keys: could not fetch $user's keys; run the bootstrap again when GitHub is reachable"
  exit 0
}
# An empty account list must not wipe the file: seed nothing then.
[[ -n $keys ]] || exit 0

install -d -m 700 "$HOME/.ssh"
file=$HOME/.ssh/authorized_keys
# Whole-file replace, not an append: the account is the ground truth (ADR-0117),
# so a revoked key leaves every machine on its next bootstrap, and nothing
# lingers the way an append-only import lets it.
if ! diff -q <(printf '%s\n' "$keys") "$file" &>/dev/null; then
  printf '%s\n' "$keys" >"$file"
  chmod 600 "$file"
  log info "authorized_keys seeded from $user's GitHub keys"
fi
