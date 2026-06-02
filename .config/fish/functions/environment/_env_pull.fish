function _env_pull -d "Import systemd user environment into fish"
    _env_fetch | while read -lz key; and read -lz value
        set -gx "$key" "$value"
    end
end
