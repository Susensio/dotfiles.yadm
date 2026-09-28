#!/bin/sh
# Reapply every patch in this library. Called by the pi npm project's postinstall
# (so `pi install`/`pi update` re-patches node_modules) and by the bootstrap step
# that wires that hook (ADR-0066).
# Silent when nothing changed; a patch needing attention warns instead of
# failing, so it never breaks an install.
# Plain printf rather than the bootstrap `log` helper: npm runs this with no
# ~/bin on PATH.
set -u

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
[ -f "$here/apply.sh" ] || exit 0

for d in "$here"/*/; do
    [ -f "$d/target" ] || continue
    # A missing target means the package is not installed yet, not drift.
    [ -f "$(cat "$d/target")" ] || continue
    name=$(basename "$d")
    if out=$("$here/apply.sh" "$name" 2>&1); then
        case $out in
            *"already applied"*) ;;
            *) printf '%s\n' "$out" ;;
        esac
    else
        printf '%s\n' "$out" >&2
        printf '%s\n' "pi patch '$name' needs attention; see ~/.config/docs/adr/0066" >&2
    fi
done
exit 0
