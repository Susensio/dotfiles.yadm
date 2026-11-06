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

# The grammar's scanner is C++: pacman's gcc brings c++, Debian's needs g++
command -v c++ >/dev/null || pkg-install g++

# ~/.config/.git points at yadm's bare repo: without a ceiling, a grammar source lacking
# its own .git resolves to it, and helix's fetch rewrites yadm's origin and tags
export GIT_CEILING_DIRECTORIES=${XDG_CONFIG_HOME:-$HOME/.config}

log info "Building Helix's tmux grammar..."
helix --grammar fetch
helix --grammar build
