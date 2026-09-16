# set -gx only ever adds or overwrites; a var removed from environment.d
# would otherwise stay exported in this shell forever, since nothing ever
# tells fish to erase it. Fetch and set the fresh values FIRST: _env_fetch
# shells out to systemctl, which itself needs vars like PATH and
# DBUS_SESSION_BUS_ADDRESS still in place, so unsetting before fetching
# would permanently break the fetch for the rest of this shell's life.
# _env_pull_managed (non-exported, so it never leaks into a child
# process's own environment) records the names pulled last time, so
# whatever's no longer among the fresh ones can be erased afterward.
function _env_pull -d "Import systemd user environment into fish"
    set -l new_names
    _env_fetch | while read -lz key; and read -lz value
        set -a new_names $key
        set -gx "$key" "$value"
    end

    if set -q _env_pull_managed
        for name in $_env_pull_managed
            if not contains -- $name $new_names
                set -e "$name"
            end
        end
    end
    set -g _env_pull_managed $new_names
end
