function __source -d "Translate export, path additions and subsequent sources from POSIX file (~/.profile)"
  # export NAME=VALUE -> set -gx NAME VALUE
  # PATH=VALUE:$PATH  -> fish_add_path VALUE    # already checks if directory exists
  # source FILE       -> __source FILE          # use recursion
  set -l file "$argv[1]"
  if test -f $file
    command grep '^export\|^\s*PATH\|^source' $file | 
      sed 's/^export /set -gx /;
           s/^\s*PATH/fish_add_path /;
           s/=/ /;
           s/:$PATH//;
           s/^source/__source/' | 
      source
  end
end

__source $HOME/.profile
__source ~/.config/profile


# if test -f ~/.profile
#   replay source ~/.profile
# end
# if test -f ~/.config/profile
#   replay source ~/.config/profile
# end
