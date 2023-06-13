# Usefull when tmux splits a new pane to preserve previous venv
if test -n "$VIRTUAL_ENV" && set -q TMUX
  source $VIRTUAL_ENV/bin/activate.fish
end
