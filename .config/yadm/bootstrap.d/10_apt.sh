#!/bin/bash

# fail on error and report it, debug all lines
set -eu -o pipefail

# script must be run as regular user
if [ "$EUID" -e 0 ]
  then echo "Please run as NON-root"
  exit
fi

# check for sudo privilege
sudo -n true
test $? -eq 0 || exit 1 "you should have sudo privilege to run this script"


# edit system config files
echo "Non interactive upgrades needrestart"
echo "\$nrconf{restart} = 'a';" | sudo tee /etc/needrestart/conf.d/noninteractive.conf > /dev/null




# update system and install requirements.sys
echo "Updating repositories..."
sudo apt update
echo "Perfodming a full system upgrade..."
sudo apt full-upgrade -y
echo "Installing user requirements..."
xargs -a <(awk '! /^ *(#|$)/' requirements.sys) -r -- sudo apt -y install
echo "Cleaning up..."
sudo apt autoremove -y
sudo apt autoclean -y

# set defaults
echo "Setting fish as default shell for current user..."
chsh -s $(which fish)
sudo update-alternatives --set editor $(which nvim)


echo "DONE"
