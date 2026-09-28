#!/bin/sh
# Postinstall transform: give each screened package a prebuilt bundle.
# bundle.mjs runs the screen itself and refuses to touch node_modules when the
# screen is unhappy, so the gate cannot be skipped by invoking it directly and the
# graph cannot change between screening and building.
# Runs after the patch library, so a bundle carries whatever the patches changed.
# Silent when nothing changed and never fails an install, matching reapply-all.sh.
set -u

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

# npm may run this with a bare PATH; node is the one interpreter it always has.
command -v node >/dev/null 2>&1 || exit 0

if out=$(node "$here/bundle.mjs" --quiet 2>&1); then
    [ -n "$out" ] && printf '%s\n' "$out"
else
    printf '%s\n' "$out" >&2
    printf '%s\n' "pi bundler needs attention; see ~/.config/docs/adr/0067" >&2
fi
exit 0
