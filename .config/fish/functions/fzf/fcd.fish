function fcd --description "Fuzzy change directory"
  set -l target (FZF_DEFAULT_COMMAND=$FZF_FD_COMMAND_DIRS FZF_DEFAULT_OPTS=$FZF_OPTS_PREVIEW fzf)
  if test -z $target
    return 1
  end
  cd $target
end

