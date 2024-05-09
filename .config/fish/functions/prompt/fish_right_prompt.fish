function fish_right_prompt -d "Write out the right prompt"
  set -l elements
  set -lx last_status $status
  set -l max_shlvl 1
  if test -n "$TMUX" || test "$TERM_PROGRAM" = "vscode"
    set max_shlvl 2
  end

  # Print git info
  set --append elements (string trim -l (fish_git_prompt))

  # Print venv
  if test -n "$VIRTUAL_ENV"
    set --append elements '('(set_color blue)(_venv_name)(set_color normal)')'
  end

  # Duration of last command
  set --local threshold 1000 # ms
  if test $CMD_DURATION -gt $threshold && test $status_generation -gt 0
    set --append elements (_format_cmd_duration)
  end

  # Background jobs indicator
  if test (jobs | count) -gt 0
    set --append elements (set_color --bold cyan)"●"(set_color normal)
  end

  # Print a fork symbol when in a subshell
  if test $SHLVL -gt $max_shlvl
    set --append elements (set_color --bold yellow)"⑂"(set_color normal)
  end

  echo -n (string join ' ' $elements)
end

function _venv_name
  set -l venv_name

  if test "$VIRTUAL_ENV" = "$XDG_DATA_HOME/venv"
    set venv_name "/venv"
  else if test (basename "$VIRTUAL_ENV") = ".venv"
    set -l parent (dirname "$VIRTUAL_ENV")
    # if pwd is inside parent, shorten
    if test $parent = (pwd) || string match -q "$parent/*" (pwd)
      set venv_name ".venv"
    else
      set venv_name (basename "$parent")"/.venv"
    end
  else if test (basename "$VIRTUAL_ENV") = "venv"
    set -l parent (dirname "$VIRTUAL_ENV")
    # if pwd is inside parent, shorten
    if test $parent = (pwd) || string match -q "$parent/*" (pwd)
      set venv_name "venv"
    else
      set venv_name (basename "$parent")"/venv"
    end
  else
    set -l venv_name "venv:"(basename "$VIRTUAL_ENV")
  end
  echo -n $venv_name
end

# https://github.com/jichu4n/fish-command-timer
function _format_cmd_duration
  set -l unit_color (set_color 999)
  set -l num_color (set_color --bold brwhite)
  set -l normal (set_color normal)

  set -l SEC 1000
  set -l MIN 60000
  set -l HOUR 3600000

  set -l hours (math --scale=0 "$CMD_DURATION / $HOUR")
  set -l mins (math --scale=0 "$CMD_DURATION % $HOUR / $MIN")

  set -l millis 0
  if test $hours -eq 0; and test $mins -eq 0
    set millis 1
  end
  set -l secs (math --scale="$millis" "$CMD_DURATION % $MIN / $SEC")

  set -l out
  if test $hours -gt 0
    set --append out {$num_color}{$hours}{$normal}{$unit_color}"h"{$normal}
  end
  if test $mins -gt 0
    set --append out {$num_color}{$mins}{$normal}{$unit_color}"m"{$normal}
  end
  set --append out {$num_color}{$secs}{$normal}{$unit_color}"s"{$normal}

  echo -n "["(string join '' $out)"]"
end

# https://github.com/acomagu/fish-async-prompt?tab=readme-ov-file#loading-indicator
function fish_git_prompt_loading_indicator -a last_prompt
    echo -n (set_color brblack)(uncolor "$last_prompt")(set_color normal)
end
