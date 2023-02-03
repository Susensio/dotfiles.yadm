# Adapted from https://www.markhansen.co.nz/auto-start-tmux/
# only run in interactive (not automated SSH for example)
if status is-interactive
and command -qs tmux                          # tmux installed
and not set -q TMUX                           # don't nest inside another tmux
and not pstree -s $fish_pid | grep -wq code   # not called from vscode
  # Adapted from https://unix.stackexchange.com/a/176885/347104
  # Create session 'main' or attach to 'main' if already exists.

  set -l first_unattached (tmux 2> /dev/null ls -F \
        '#{session_attached} #{?#{==:#{session_last_attached},},1,#{session_last_attached}} #{session_id}' |
        awk '/^0/ { if ($2 > t) { t = $2; s = $3 } }; END { if (s) printf "%s", s }')

  if test -n "$first_unattached"
    exec tmux attach -t "$first_unattached"
  else
    exec tmux new-session
    # tmux new-session -A -s main
  end
end
