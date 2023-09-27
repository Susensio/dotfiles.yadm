# fd as default in fzf
export FZF_FD_OPTS="--hidden --exclude=.git"
export FZF_FD_OPTS_FILES="--type f $FZF_FD_OPTS"
export FZF_FD_OPTS_DIRS="--type d $FZF_FD_OPTS"

export FZF_FD_COMMAND_FILES="fdfind --strip-cwd-prefix $FZF_FD_OPTS_FILES"
export FZF_FD_COMMAND_DIRS="fdfind --strip-cwd-prefix $FZF_FD_OPTS_DIRS"
export FZF_DEFAULT_COMMAND="$FZF_FD_COMMAND_FILES"

export FZF_BIND_SWITCH_FILES_DIRS="--bind 'ctrl-d:reload($FZF_FD_COMMAND_DIRS)' --bind 'ctrl-f:reload($FZF_FD_COMMAND_FILES)'"

export FZF_DEFAULT_OPTS='--cycle --layout=reverse --border=bold --height=50% --preview-window=right:50%:wrap --marker="*" --bind tab:toggle+down,btab:toggle+up'
export FZF_TMUX_OPTS="-p90%,60%"
# non standard
export FZF_OPTS_PREVIEW="$FZF_DEFAULT_OPTS --preview='preview {}'"

# zoxide
export _ZO_FZF_OPTS="$FZF_DEFAULT_OPTS --preview='preview {2..}'"
