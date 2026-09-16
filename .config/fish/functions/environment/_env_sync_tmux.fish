# tmux's set-environment only ever adds or overwrites; a var removed from
# environment.d would otherwise stay pinned in tmux forever, since nothing
# ever tells tmux to drop it. The names pushed last time are recorded in
# the @_env_sync_managed user option, so those can be unset before the
# fresh values go in.
function _env_sync_tmux_server -d "Push the fresh env payload to one tmux server, pruning what it no longer manages"
    set -l set_payload $argv[1]
    set -l flag $argv[2..-1]

    set -l old_names (tmux $flag show-options -g -v @_env_sync_managed 2>/dev/null | string split --no-empty ' ')
    set -l unset_payload
    for name in $old_names
        set -a unset_payload "set-environment -gu '$name'"
    end

    echo (string join \n -- $unset_payload $set_payload | string collect) | tmux $flag source -
end

function _env_sync_tmux -d "Import systemd user environment into tmux"
    if not set -q TMUX
        return
    end

    set -l new_names
    set -l set_payload
    _env_fetch | while read -lz key; and read -lz value
        set -a new_names $key
        set -a set_payload "set-environment -g '$key' '$value'"
    end
    set -a set_payload "set-option -g '@_env_sync_managed' '"(string join ' ' -- $new_names)"'"
    set set_payload (string join \n -- $set_payload | string collect)

    _env_sync_tmux_server $set_payload
    if tmux -L scratchpad run 2>/dev/null
        _env_sync_tmux_server $set_payload -L scratchpad
    end
end
