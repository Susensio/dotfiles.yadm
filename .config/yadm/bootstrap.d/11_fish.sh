#!/usr/bin/env bash
# fail on error and report it, debug all lines
set -eu -o pipefail

# Add repo if not present
if ! compgen -G "/etc/apt/sources.list.d/*fish*.list" &> /dev/null; then
  echo "Adding fish shell repository..." >&2
  distro=$(lsb_release -is)
  release=$(lsb_release -rs)
  # If running debian testing, release is not set. Get stable number instead
  if [ "$distro" = "Debian" ] && [ "$release" = "n/a" ]; then
    release=$(curl -s https://ftp.debian.org/debian/dists/stable/Release | sponge | sed '4q;d' | cut -d ' ' -f 2 | cut -d '.' -f 1)
  fi

  # from https://software.opensuse.org/download.html?project=shells%3Afish%3Arelease%3A3&package=fish
  echo "deb http://download.opensuse.org/repositories/shells:/fish:/release:/3/${distro}_${release}/ /" | sudo tee /etc/apt/sources.list.d/shells:fish:release:3.list
  curl -fsSL "https://download.opensuse.org/repositories/shells:fish:release:3/${distro}_${release}/Release.key" | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/shells_fish_release_3.gpg > /dev/null
fi

# if fish is installed, abort
if ! command -v fish &> /dev/null; then
  sudo apt update
  sudo apt install fish
  echo "Fish shell installed" >&2
fi

# set defaults
if [ "$SHELL" != "$(which fish)" ]; then
  echo "Setting fish as default shell for current user..." >&2
  sudo chsh -s "$(which fish)" "$USER"
fi

# update plugins from fish_plugins if changed
if [[ -n $(comm -3 \
    <(fish -c 'fisher list' | tr '[:upper:]' '[:lower:]' | sort) \
    <(cat ~/.config/fish/fish_plugins |tr '[:upper:]' '[:lower:]' | sort) \
    &> /dev/null) ]]; then
  fish -c 'fisher update' &
  # have to wait bc fisher is async
  wait
fi
