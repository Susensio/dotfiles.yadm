#!/usr/bin/env bash
git_config_folder=${XDG_CONFIG_HOME:-$HOME/.config}/git
git_config_local_file=${git_config_folder}/config.local

if [ ! -f $git_config_local_file ]; then
    cat >> $git_config_local_file << EOF
[user]
    email = $USER@$(hostname)
EOF
fi
