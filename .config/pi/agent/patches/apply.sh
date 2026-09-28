#!/bin/sh
# Reapply a local patch from this library onto pi's node_modules.
# Usage: apply.sh <patch-name>
#
# Layout per patch dir (<name>/):
#   target    absolute path of the file the patch applies to
#   marker    a string present only in the patched form (applied-detection)
#   *.orig    pristine upstream copy
#   *.patch   unified diff against the pristine file, bare "store.ts" headers
#
# Exit 0: applied (or already applied). Exit 1: drifted/missing - patch needs
# a manual rebase against the .orig in this directory.
set -eu

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
name=${1:?usage: apply.sh <patch-name>}
dir="$here/$name"

for f in target marker; do
    [ -f "$dir/$f" ] || { echo "apply.sh: $dir/$f missing" >&2; exit 1; }
done
target=$(cat "$dir/target")
orig=$(cat "$dir/orig" 2>/dev/null || echo store.ts.orig)
orig_path="$dir/$orig"
marker=$(cat "$dir/marker")
# POSIX sh never globs a redirection word, so expand into $patch_file first.
set -- "$dir"/*.patch
patch_file=$1

if [ ! -f "$target" ]; then
    echo "apply.sh [$name]: WARNING target missing: $target (upstream layout changed?)" >&2
    exit 1
fi

if grep -q "$marker" "$target"; then
    echo "apply.sh [$name]: already applied"
    exit 0
fi

if [ ! -f "$orig_path" ] || ! cmp -s "$target" "$orig_path"; then
    echo "apply.sh [$name]: WARNING target no longer matches the kept pristine copy" >&2
    echo "  diff $target $orig_path, then refresh $orig and regenerate the patch" >&2
    exit 1
fi

cp "$orig_path" "$target"
patch -d "$(dirname "$target")" -p0 --forward --quiet < "$patch_file"
echo "apply.sh [$name]: applied"
