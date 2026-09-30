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
