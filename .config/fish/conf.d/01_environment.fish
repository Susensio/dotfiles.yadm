# Import systemd user environment variables into Fish
if status is-login && type -q systemctl
    _env_pull
end
