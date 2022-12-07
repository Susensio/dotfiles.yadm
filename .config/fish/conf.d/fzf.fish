# Same opts as system fzf
set fzf_fd_opts --hidden --exclude=.git

# Default bindings but bind Search Directory to Ctrl+F and Search Variables to Ctrl+Alt+V
fzf_configure_bindings --directory=\cf --variables=\e\cv

# Better dir and file previews
set fzf_preview_dir_cmd exa --all --color=always --icons
set fzf_preview_file_cmd __previewer

function __previewer
  set -l cols (math (tput cols) - 2)
  set -l rows (math (tput lines) - 2)
  set -l path "$argv[1]"
  preview $path $cols $rows
end
