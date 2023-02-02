function fzf --wraps fzf --description 'FZF using tmux popup if available'
  if command -vq tmux && set -q TMUX
    command fzf-tmux $FZF_TMUX_OPTS -- $argv
  else
    command fzf $argv
  end
end
