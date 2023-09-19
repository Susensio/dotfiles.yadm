#!/usr/bin/env bash

if [ ! -f ~/.ssh/authorized_keys ]; then
  echo "Creating authorized_keys file..." >&2
  mkdir ~/.ssh
  chmod 700 ~/.ssh
  touch ~/.ssh/authorized_keys
  chmod 600 ~/.ssh/authorized_keys
fi

curl https://github.com/susensio.keys -o ~/.ssh/authorized_keys &> /dev/null

if ! crontab -l | grep "github.com/susensio.keys" &> /dev/null; then
  echo "Creating crontab for updated ssh keys..."
  (crontab -l 2> /dev/null; echo "* */4 * * * curl https://github.com/susensio.keys -o ~/.ssh/authorized_keys &> /dev/null") | crontab -
fi
