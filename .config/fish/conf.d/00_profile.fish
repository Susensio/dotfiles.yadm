function _source -d "Translate export, path additions and subsequent sources from POSIX file (~/.profile)"
  # export NAME=VALUE -> set -gx NAME VALUE
  # PATH=VALUE:$PATH  -> fish_add_path VALUE   # already checks if directory exists
  # source FILE       -> _source FILE          # use recursion
  set -l file "$argv[1]"
  if test -f $file
    command grep '^export\|^\s*PATH\|^source' $file | 
      sed 's/^export /set -gx /;
           s/^\s*PATH/fish_add_path /;
           s/=/ /;
           s/:$PATH//;
           s/^source/_source/' | 
      source
  end
end

if status is-login
  _source $HOME/.profile
  _source ~/.config/profile
end

# if test -f ~/.profile
#   replay source ~/.profile
# end
# if test -f ~/.config/profile
#   replay source ~/.config/profile
# end
