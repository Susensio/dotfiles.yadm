#!/bin/bash

# fail on error and report it, debug all lines
set -eu -o pipefail

# script must be run as regular user
if [ "$EUID" -eq 0 ]
  then echo "Please run as NON-root" >&2
  exit
fi

# check for sudo privilege
sudo -n true
test $? -eq 0 || exit 1 "you should have sudo privilege to run this script"


# edit system config files
echo "Non interactive upgrades needrestart" >&2
sudo mkdir -p /etc/needrestart/conf.d/
echo "\$nrconf{restart} = 'a';" | sudo tee /etc/needrestart/conf.d/noninteractive.conf > /dev/null


# update system and install requirements.sys
echo "Updating repositories..." >&2
sudo apt update
echo "Performing a full system upgrade..." >&2
# sudo apt full-upgrade -y
echo "Installing user requirements..." >&2
xargs -a <(awk '! /^ *(#|$)/' ~/.config/yadm/bootstrap.d/requirements.apt) -r -- sudo apt -y --ignore-missing install
# awk '! /^ *(#|$)/' ~/.config/yadm/bootstrap.d/requirements.apt | while read -r package; do
  # sudo apt -y install "$package" || true
# done
echo "Cleaning up..." >&2
sudo apt autoremove -y
sudo apt autoclean -y

echo "Done installing apt packages" >&2
