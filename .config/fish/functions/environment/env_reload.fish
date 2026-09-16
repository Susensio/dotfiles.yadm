function env_reload -d "Hot-reload environment.d variables into systemctl and current shell"
    if not systemctl --user show-environment >/dev/null
        log error "Cannot reach systemd --user; environment not reloaded."
        return 1
    end

    log info "Unpinning dynamic variables..."
    _env_unpin

    log info "Updating systemctl --user environment..."
    systemctl --user daemon-reload

    log info "Importing variables into current shell..."
    _env_pull

    log info "Pushing variables to tmux server..."
    _env_sync_tmux

    log success "Environment reloaded."
end
