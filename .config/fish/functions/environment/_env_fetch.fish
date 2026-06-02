function _env_fetch -d "Fetch systemd user environment and parse it"
    # Variables managed by the shell that should not be overwritten
    set -l readonly_vars PWD USER HOME SHELL SHLVL _

    for env_var in (systemctl --user show-environment)
        set -l kv (string split --max 1 = -- "$env_var")
        set -l key $kv[1]

        # Clean value: handle ANSI-C quoting ($'...') and standard quoting
        set -l value $kv[2]
        if string match -q -r "^\$'" "$value"
            set value (string replace -r "^\$'(.*)'\$" '$1' "$value" | string unescape)
        else
            set value (string replace -r '^\$' '' -- "$value" | string unescape )
        end

        # Skip read-only variables
        if contains -- "$key" $readonly_vars
            continue
        end

        string join0 -- "$key" "$value"
    end
end
