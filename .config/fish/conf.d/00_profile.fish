function _source -d "Translate export, path additions and subsequent sources from POSIX file (~/.profile)"
  # export NAME=VALUE -> set -gx NAME VALUE
  # NAME=VALUE        -> set -l NAME VALUE
  # add_path VALUE    -> fish_add_path -g VALUE   # already checks if directory exists
  # source FILE       -> _source FILE          # use recursion
  # also conditional and loops are converted
  set -l file "$argv[1]"
  if test -f $file
    command grep -P '^export|^\s*add_path|^\s*source|^if|^fi$|^\s*for|^\s*done$|^\w+=' $file |
      sed -E 's/^export (\w+)=/set -gx \1 /;
        s/^(\w+)=/set -l \1 /;
        s/\badd_path\b/fish_add_path -g -m/;
        s/\bsource\b/_source/;
        s/;\s*then$//;
        s/^fi$/end/;
        s/\bdone\b/end/;
        s/;\s*do$//;
        s/\$\{([^}]*)\}/$\1/' |
      source
  end
end

# if status is-login
_source $HOME/.profile
_source ~/.config/profile
# end
