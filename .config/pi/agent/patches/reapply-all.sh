#!/bin/sh
# Reapply every patch in this library. Called by the pi npm project's postinstall
# (so `pi install`/`pi update` re-patches node_modules) and by the bootstrap step
# that wires that hook (ADR-0066).
# A target a package update moved is rebased onto the new file first (rebase.py),
# which refreshes the kept pristine copy and the patch when the merge is clean.
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
    # Before apply.sh: a drifted target is not byte-identical to the .orig, so
    # apply.sh would refuse it. When the rebase succeeds, apply.sh then applies
    # it in the same run. When it refuses, the only thing apply.sh could add is
    # the same drift warning, so this patch's turn ends here.
    if [ -f "$here/rebase.py" ] && command -v python3 >/dev/null 2>&1; then
        if ! rebase_out=$(python3 "$here/rebase.py" "$name" 2>&1); then
            printf '%s\n' "$rebase_out" >&2
            printf '%s\n' "pi patch '$name' needs attention; see ~/.config/docs/adr/0066" >&2
            continue
        fi
        [ -n "$rebase_out" ] && printf '%s\n' "$rebase_out"
    fi
    if out=$("$here/apply.sh" "$name" 2>&1); then
        case $out in
            *"already applied"*) ;;
            # A rebase is this library repairing itself, not drift: the
            # `rebased:` prefix is how pi-postinstall tells the two apart when it
            # treats any other output as a patch needing attention (ADR-0112).
            *"rebased:"*) printf '%s\n' "$out" ;;
            *) printf '%s\n' "$out" ;;
        esac
    else
        printf '%s\n' "$out" >&2
        printf '%s\n' "pi patch '$name' needs attention; see ~/.config/docs/adr/0066" >&2
    fi
done
exit 0
