#!/usr/bin/env bash

# Create folders if neccesary
mkdir -p "${XDG_CONFIG_HOME:-~./config}/anacron"
mkdir -p "${XDG_STATE_HOME:-~./local/state}/anacron"

if ! crontab -l &> /dev/null; then
  echo "Crontab not present, initializing..." >&2
  cat << EOF | crontab -
# m h  dom mon dow  command
EOF
fi

if ! crontab -l | grep "anacron" &> /dev/null; then
  echo "Creating user crontab for anacron..."
  job='@hourly /usr/sbin/anacron -t "${XDG_CONFIG_HOME:-$HOME/.config}/anacron/anacrontab" -S "${XDG_STATE_HOME:-$HOME/.local/state}/anacron'
  (crontab -l 2> /dev/null; echo "${job}") | crontab -
fi
