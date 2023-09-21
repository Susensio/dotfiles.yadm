#!/bin/bash

# fail on error and report it, debug all lines
set -eu -o pipefail

# # script must be run as regular user
# if [ "$EUID" -eq 0 ]
#   then echo "Please run as NON-root" >&2
#   exit
# fi
#
# # check for sudo privilege
# sudo -n true
# test $? -eq 0 || exit 1 "you should have sudo privilege to run this script"


# edit system config files
if [[ ! -f /etc/needrestart/conf.d/noninteractive.conf ]]; then
  echo "Non interactive upgrades needrestart" >&2
  sudo mkdir -p /etc/needrestart/conf.d/
  echo "\$nrconf{restart} = 'a';" | sudo tee /etc/needrestart/conf.d/noninteractive.conf > /dev/null
fi

# list packages that are available in apt
required="$(awk '! /^ *(#|$)/' ~/.config/yadm/bootstrap.d/requirements.apt)"
available="$(apt-cache madison ${required} 2>/dev/null | awk -F '|' '{print $1}' | tr -d '[:blank:]' | uniq)"
missing="$(comm -23 <(echo "${required}" | tr ' ' '\n' | sort) <(echo "${available}" | tr ' ' '\n' | sort))"
[[ -n $missing ]] \
  && echo "WARNING: the following packages are not available: $(echo "${missing}" | tr '\n' ' ')" >&2

# now check if all packages are installed, avoid updating apt if not necessary
not_installed="$(comm -13 <(dpkg -l | awk '/^ii/ {print $2}' | sort) <(echo "$available" | sort))"

if [[ -z "$not_installed" ]]; then
  echo "All packages are installed" >&2
  exit 0
fi

# update system and install requirements.sys
echo "Updating repositories..." >&2
sudo apt update
echo "Installing user requirements..." >&2
echo "${not_installed}" | sudo apt install -y
echo "Done installing apt packages" >&2
