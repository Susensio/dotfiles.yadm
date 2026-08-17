# Dynamic systemd overrides (D-Bus `set-environment`, Script 95) pin
# variables in memory and keep masking environment.d edits even after a
# `daemon-reload`. This script unsets them so environment.d wins again.
# rationale: docs/adr/0002-unset-systemd-overrides.md

function _env_unpin -d "Ensure environment.d is not overriden"
    set -l GENERATOR /usr/lib/systemd/user-environment-generators/30-systemd-environment-d-generator
    set -l vars ($GENERATOR | string split '=' --fields=1)
    systemctl --user unset-environment $vars
end
