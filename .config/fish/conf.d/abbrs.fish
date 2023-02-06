# Faster cd
function _multicd
  set -l dots (string match --regex '\.\.+' $argv[1])
  echo cd (string repeat -n (math (string length -- $argv[1]) - 1) ../)
end
abbr --add dotdot --regex '^(?>cd)?\.\.+$' --function _multicd

abbr --add pd prevd
abbr --add nd nextd

# sudo !!
function _last_history_item; echo $history[1]; end
abbr --add !! --position anywhere --function _last_history_item

abbr --add v vim

# taskwarrior
abbr --add t task
abbr --add ta task add
abbr --add ti taski
abbr --add tap --set-cursor task add project:%

abbr --add lg lazygit

# Common mistake
abbr --add please fix
