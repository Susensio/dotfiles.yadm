# set -gx only ever adds or overwrites; a var removed from environment.d
# would otherwise stay exported in this shell forever, since nothing ever
# tells fish to erase it. _env_pull_managed (a plain, non-exported global,
# so it never leaks into a child process's own environment) records the
# names pulled last time, so those can be erased before the fresh values
# go in.
function _env_pull -d "Import systemd user environment into fish"
    if set -q _env_pull_managed
        for name in $_env_pull_managed
            set -e "$name"
        end
    end

    set -l new_names
    _env_fetch | while read -lz key; and read -lz value
        set -a new_names $key
        set -gx "$key" "$value"
    end
    set -g _env_pull_managed $new_names
end
