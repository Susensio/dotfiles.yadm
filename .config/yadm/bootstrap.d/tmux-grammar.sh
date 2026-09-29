#!/usr/bin/env bash
# tmux is the one language Helix does not ship a grammar for: Arch's package and
# the upstream tarball carry every built-in grammar, but this one is compiled per
# machine into runtime/grammars, which helix/.gitignore excludes. `use-grammars`
# in languages.toml keeps the fetch to that single grammar.
#
# The name sorts after mise.sh on purpose: locale `sort` ignores punctuation, so
# a `helix.sh` would run before it, and the helix binary arrives with the tools
# that step installs.
set -euo pipefail

command -v helix >/dev/null || exit 0

CONFIG_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/helix
GRAMMAR=$CONFIG_DIR/runtime/grammars/tmux.so
LANGUAGES=$CONFIG_DIR/languages.toml

# Up to date until languages.toml moves; that is also how a rev bump reaches a
# machine that already holds a grammar built from the old revision.
[[ -e $GRAMMAR && ! $LANGUAGES -nt $GRAMMAR ]] && exit 0

log info "Building Helix's tmux grammar..."
helix --grammar fetch
helix --grammar build
