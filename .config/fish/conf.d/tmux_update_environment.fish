function _tmux_update_environment --on-event="fish_prompt"
  if set -q TMUX
    tmux showenv \
    | string match -re '^.?(?:SSH|DISPLAY)' \
    | string replace -r '^([^-].*?)=(.*)' 'set -gx $1 $2' \
    | string replace -r '^(-)(.*)' 'set -e $2' \
    | source
  end
end
