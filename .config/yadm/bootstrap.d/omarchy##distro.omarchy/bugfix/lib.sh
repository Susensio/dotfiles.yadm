# shellcheck shell=bash
# Sourced by the bugfix steps; not executable, so the bootstrap skips it.
# Fallback for a standalone run without ~/bin (the bootstrap exports it).
log() { echo "[$1] $2" >&2; }

# Apply the step's patch to Omarchy's file when the forward patch applies,
# after the reverse applied or nothing did (ADR-0057):
#   already-patched or fixed upstream  -> silent
#   forward applies                    -> sudo patch
#   neither                            -> stale warning, so the PR gets checked
# Usage: apply_omarchy_patch <patch filename in patches/> <target> <patch level, 0 or 1>
apply_omarchy_patch() {
  local patch="${BASH_SOURCE[0]%/*}/patches/$1" target=$2 p=$3 stripargs=()

  [[ $p == 0 ]] || stripargs=(-p"$p")
  if patch "${stripargs[@]}" -R -f -s -F0 --dry-run "$target" <"$patch" &>/dev/null; then
    # Already patched, or the fix shipped upstream
    return 0
  elif ! patch "${stripargs[@]}" -N -f -s -F0 --dry-run "$target" <"$patch" &>/dev/null; then
    log warn "$(basename "$patch") no longer applies to Omarchy: check the PR and drop this step"
  else
    sudo patch "${stripargs[@]}" -N -f -F0 --no-backup-if-mismatch "$target" <"$patch"
  fi
}

# Install a file the PR adds into the user's own tree, never the package's:
# a pacman-unowned file at a path the package later ships fails the update (docs/adr/0082).
#   package ships it -> remove our untouched copy, which would shadow or outdate it;
#                       a locally edited copy stays
#   otherwise        -> install when it differs
# Usage: install_omarchy_file <file in files/> <destination> <mode> <path the package would ship>
install_omarchy_file() {
  local file="${BASH_SOURCE[0]%/*}/files/$1" dest=$2 mode=$3 shipped=$4

  if [[ -e $shipped ]]; then
    if cmp -s "$file" "$dest"; then
      rm -- "$dest"
      log warn "Omarchy ships $(basename "$shipped"): removed the local copy, drop this step"
    fi
  elif ! cmp -s "$file" "$dest"; then
    install -Dv --mode="$mode" "$file" "$dest"
  fi
}
