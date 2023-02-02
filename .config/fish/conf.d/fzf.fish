# Same opts as system fzf
set fzf_fd_opts (string split -- ' ' $FZF_FD_OPTS)

# Default bindings but bind Search Directory to Ctrl+F and Search Variables to Ctrl+Alt+V
fzf_configure_bindings --directory=\cf --variables=\e\cv

# Better dir and file previews
set fzf_preview_dir_cmd preview
set fzf_preview_file_cmd preview
