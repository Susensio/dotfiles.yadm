# fd as default in fzf
export FZF_FD_OPTS="--hidden --exclude=.git"
export FZF_FD_OPTS_FILES="--type f $FZF_FD_OPTS"
export FZF_FD_OPTS_DIRS="--type d $FZF_FD_OPTS"

export FZF_FD_COMMAND_FILES="fdfind --strip-cwd-prefix $FZF_FD_OPTS_FILES"
export FZF_FD_COMMAND_DIRS="fdfind --strip-cwd-prefix $FZF_FD_OPTS_DIRS"
export FZF_DEFAULT_COMMAND="$FZF_FD_COMMAND_FILES"
#| sed -r 's/\[1/\[0/g'"

export FZF_BIND_SWITCH_FILES_DIRS="--bind 'ctrl-d:reload($FZF_FD_COMMAND_DIRS)' --bind 'ctrl-f:reload($FZF_FD_COMMAND_FILES)'"

export FZF_DEFAULT_OPTS='--cycle '\
'--layout=reverse '\
'--ansi '\
'--border=bold '\
'--height=50% '\
'--preview-window="right:50%:wrap,<60(down:50%:wrap)" '\
'--marker="*" '\
'--bind tab:toggle+down,btab:toggle+up '\
'--bind "ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down" '\
'--bind "ctrl-y:execute-silent(printf {} | clipboard copy)" '\
'--bind "ctrl-V:transform-query(echo -n {q}; clipboard paste)" '\
'--bind "ctrl-w:backward-kill-word" '\
'--color=fg:#9da9a0,fg+:#e4e1cd,bg:#15191B,bg+:#181C1E,hl:underline:#a7c080,hl+:underline:#a7c080,spinner:#e69875,header:#a7c080,info:#dbbc7f,pointer:#e69e80,marker:#e69875,prompt:#dbbc7f'

export FZF_PREVIEW="--preview='preview {}'"
# # used on fish function that launchs fzf-tmux
# export FZF_TMUX_OPTS="-p90%,60%"
# # non standard
export FZF_OPTS_PREVIEW="$FZF_DEFAULT_OPTS $FZF_PREVIEW"
#
# # zoxide
# export _ZO_FZF_OPTS="$FZF_DEFAULT_OPTS --preview='preview {2..}'"
