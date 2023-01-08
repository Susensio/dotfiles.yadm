function _auto_git_fetch --on-variable PWD --description "git fetch automatically wherever inside a git repository"
  if test -d ".git"
    git fetch --quiet &
  end
end
