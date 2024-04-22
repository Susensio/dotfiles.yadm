#!/usr/bin/env bash
set -o nounset
set -o errexit
set -o pipefail

### ROOT SPACE

etc_profiled_folder="/etc/profile.d"
etc_profile_xdg="${etc_profiled_folder}/profile_xdg.sh"


# Write config file if not exists
[[ -f ${etc_profile_xdg} ]] \
  || sudo tee ${etc_profile_xdg} << EOF
# Make .profile follow the XDG_CONFIG_HOME specification
_confdir=\${XDG_CONFIG_HOME:-\$HOME/.config}
_profile=\${_confdir}/profile

# Source settings file
[ -f "\${_profile}" ] && . "\$_profile"

unset _confdir
unset _profile
EOF


### USER SPACE

# Now move the actual file
confdir="${XDG_CONFIG_HOME:-$HOME/.config}"
file="${HOME}/.profile"

mkdir --parents -- "${confdir}"

# Check if file exists first
if [[ -f ${file} ]]; then
    base=$(basename "${file}")
    # remove dot with :1
    dest="${confdir}/${base:1}"
    if [[ ! -f $dest ]]; then
        mv -- "${file}" "${dest}"
    else
        mv -- "${file}" "${file}.bak"
        echo "File ${dest} already exists, moved ${file} to ${file}.bak" >&2
    fi
fi
