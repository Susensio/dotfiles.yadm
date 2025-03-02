# Same opts as system fzf

set fzf_fd_opts (string split -- ' ' $FZF_FD_OPTS)

# Better dir and file previews
set fzf_preview_dir_cmd preview
set fzf_preview_file_cmd preview

# Edit with nvim on search-directory
set fzf_directory_opts --bind "ctrl-e:abort+execute($EDITOR {} &> /dev/tty)"

# Exclude the command timestamp from the search scope when in Search History
set fzf_history_opts "--nth=4.."

# Make history respect chronological order
set fzf_history_opts --no-sort

# Not neccesary if not interactive, besides this guards on bootstrap
if not status is-interactive
  exit
end

# Default bindings but bind Search Directory to Ctrl+F and Search Variables to Ctrl+Alt+V prepending $
if not fisher list fzf >/dev/null then
  echo "fzf.fish not found" >&2
  exit 1
end

fzf_configure_bindings --directory=\cf --variables=
function _fzf_search_variables_prepend
  if not string match -q 'set*' (commandline) && test (commandline -t) != '$'
    commandline --append '$'
    commandline --cursor (math (commandline --cursor) + 1)
  end
  eval $_fzf_search_vars_command
  if test (commandline) = '$'
    commandline --replace ''
  end
end
bind \e\cv _fzf_search_variables_prepend


# custom script that greps like inside neovim
function _fzf_search_grep
  set -f file_paths_selected ($HOME/bin/sd/fzf/rg)

  if test $status -eq 0
    commandline --append $file_paths_selected
  end
  commandline --function repaint
end
bind \cg _fzf_search_grep
# bind \cg '$HOME/bin/sd/fzf/rg; commandline -f repaint'
# bind \e\cv "commandline --append '\$'; $_fzf_search_vars_command"
