# systemd merges two environment layers:
# 1. Static (Generators/environment.d)
# 2. Dynamic (D-Bus overrides via systemctl `set-environment` or Script 95)
#
# Dynamic overrides take precedence and "pin" variables in memory, masking
# changes to environment.d files even after a `daemon-reload`. This script
# unsets the dynamic overrides to allow environment.d hot-reloads.

function _env_unpin -d "Ensure environment.d is not overriden"
    set -l GENERATOR /usr/lib/systemd/user-environment-generators/30-systemd-environment-d-generator
    set -l vars ($GENERATOR | string split '=' --fields=1)
    systemctl --user unset-environment $vars
end
