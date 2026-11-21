# Import systemd user environment variables into Fish
# Interactive: every pane, popup and nested shell is a fresh terminal session
# that must not inherit a stale parent env (ADR-0003's amended trigger).
# Login: kept for non-interactive `fish -lc` script entries, e.g. the SSH
# `clipboard` path on the nuc (ADR-0113).
if status is-interactive; or status is-login; and type -q systemctl
    _env_pull
end
