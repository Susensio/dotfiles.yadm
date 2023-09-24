#!/usr/bin/env bash
file='/etc/lightdm/lightdm.conf'
conf='user-authority-in-system-dir'

# https://askubuntu.com/questions/960793/whats-the-right-place-to-set-the-xauthority-environment-variable/961459#961459
if [[ -f "${file}" ]]; then
  sudo sed -i -e "/#${conf}/s/^#//g" -e "/${conf}/s/=false/true/g" "${file}"
fi
