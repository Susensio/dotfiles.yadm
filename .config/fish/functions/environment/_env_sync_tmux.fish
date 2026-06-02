function _env_sync_tmux -d "Import systemd user environment into tmux"
    if not set -q TMUX
        return
    end

    set -l tmux_payload
    _env_fetch | while read -lz key; and read -lz value
        set -a tmux_payload "set-environment -g '$key' '$value'"
    end

    set tmux_payload (string join \n $tmux_payload | string collect)

    echo $tmux_payload | tmux source -
    if tmux -L scratchpad run 2>/dev/null
        echo $tmux_payload | tmux -L scratchpad source -
    end
end
