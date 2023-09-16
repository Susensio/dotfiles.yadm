#!/usr/bin/env bash
set -o nounset
set -o errexit
set -o pipefail

# Disable ~/.sudo_as_admin_successful file
sudo tee /etc/sudoers.d/disable_admin_file &> /dev/null << EOF
# Disable ~/.sudo_as_admin_successful file
Defaults !admin_flag
EOF
