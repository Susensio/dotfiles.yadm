function _source -d "Translate export, path additions and subsequent sources from POSIX file (~/.profile)"
  # export NAME=VALUE -> set -gx NAME VALUE
  # NAME=VALUE        -> set -l NAME VALUE
  # add_path VALUE    -> fish_add_path -g VALUE   # already checks if directory exists
  # source FILE       -> _source FILE          # use recursion
  # also conditional and loops are converted
  argparse 'd/dryrun' -- $argv
  set -l cmd source
  if set -q _flag_dryrun
    set cmd cat
  end

  set -l file "$argv[1]"
  if test -f $file
    awk '{if (sub(/\\\$/,"")) printf "%s", $0; else print $0}' $file |
      command grep -P '^export|^\s*add_path|^\s*source|^if|^fi$|^\s*for|^\s*done$|^\w+=' |
      sed -E 's/^export (\w+)=/set -gx \1 /;
        s/^(\w+)=/set -l \1 /;
        s/\badd_path\b/fish_add_path -g -m/;
        s/\bsource\b/_source/;
        s/;\s*then$//;
        s/^fi$/end/;
        s/\bdone\b/end/;
        s/;\s*do$//;
        s/\$\{([^}]*)\}/$\1/' |
      $cmd
  end
end

set -gx fisher_path $(fallback $XDG_DATA_HOME $HOME/.local/share)/fish/fisher
set fish_function_path $fish_function_path[1] $fisher_path/functions $fish_function_path[2..-1]
set fish_complete_path $fish_complete_path[1] $fisher_path/completions $fish_complete_path[2..-1]

if status is-login
  if functions -q fenv
    fenv source (fallback $XDG_CONFIG_HOME $HOME/.config)/profile
  else
    exec "bash -l -c 'exec fish -i'"
  end
end
