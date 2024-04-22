#!/usr/bin/env bash
set -o nounset
set -o errexit
set -o pipefail

### ROOT SPACE

etc_bashrc_file="/etc/bash.bashrc"
etc_bashrcd_folder="/etc/bash/bashrc.d"
etc_bashrc_xdg="${etc_bashrcd_folder}/xdg.sh"
etc_profiled_folder="/etc/profile.d"
etc_profile_xdg="${etc_profiled_folder}/bash_xdg.sh"

# If bash not reading `bashrc.d/` config folder
grep --quiet ${etc_bashrcd_folder} ${etc_bashrc_file} \
  || sudo tee --append ${etc_bashrc_file} << EOF

# Load profiles from ${etc_bashrcd_folder}
if [ -d ${etc_bashrcd_folder}/ ]; then
    for f in ${etc_bashrcd_folder}/*.sh; do
        [ -r "\$f" ] && . "\$f"
    done
    unset f
fi
EOF

# Create directory if not exists
sudo mkdir --parents -- ${etc_bashrcd_folder}

# Write config file if not exists
[[ -f ${etc_bashrc_xdg} ]] \
  || sudo tee ${etc_bashrc_xdg} << EOF
# Make bash follow the XDG_CONFIG_HOME specification
_confdir=\${XDG_CONFIG_HOME:-\$HOME/.config}/bash
_datadir=\${XDG_DATA_HOME:-\$HOME/.local/share}/bash

[[ -r "\$_confdir/bashrc" ]] && . "\$_confdir/bashrc"

[[ ! -d "\$_datadir" ]] && mkdir -p "\$_datadir"
HISTFILE=\$_datadir/history

unset _confdir
unset _datadir
EOF

# Write config file if not exists
[[ -f ${etc_profile_xdg} ]] \
  || sudo tee ${etc_profile_xdg} << EOF
# Make bash follow the XDG_CONFIG_HOME specification
_confdir=\${XDG_CONFIG_HOME:-\$HOME/.config}/bash
_datadir=\${XDG_DATA_HOME:-\$HOME/.local/share}/bash

# Source settings file
if [ -d "\$_confdir" ]; then
    for f in bash_profile bashrc; do
        [ -f "\$_confdir/\$f" ] && . "\$_confdir/\$f"
    done
fi

# Change the location of the history file by setting the environment variable
[ ! -d "\$_datadir" ] && mkdir -p "\$_datadir"
HISTFILE=\$_datadir/history

unset _confdir
unset _datadir
EOF


### USER SPACE

# Now move the actual files
confdir="${XDG_CONFIG_HOME:-$HOME/.config}/bash"
datadir="${XDG_DATA_HOME:-\$HOME/.local/share}/bash"
histfile="${HOME}/.bash_history"
files="${HOME}/.bash*"

mkdir --parents -- "${confdir}"
mkdir --parents -- "${datadir}"

# First move .bash_history, it goes to different folder
[[ -f ${histfile} ]] && mv -- "${histfile}" "${datadir}/history"

# Now the remaining .bash* files
# Check if glob gives results
if compgen -G "${files}" > /dev/null; then
    for file in ${files}; do
    base=$(basename "${file}")
        # Update possible references to ~/.bash_aliases in .bashrc
        if [[ ${base} == ".bashrc" ]]; then
            sed --in-place "s|~/.bash_aliases|${XDG_CONFIG_HOME:-$HOME/.config}/bash/bash_aliases|g" "${file}"
        fi
        # remove dot with :1
    dest="${confdir}/${base:1}"

    if [[ ! -f $dest ]]; then
        mv -- "${file}" "${dest}"
    else
        mv -- "${file}" "${file}.bak"
        echo "File ${dest} already exists. Renamed to ${file}.bak"
    fi

    done
fi
