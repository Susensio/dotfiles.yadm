function _auto_git_fetch --on-variable PWD --description "git fetch automatically wherever inside a git repository"
  if test -d ".git"
    if test -n (find .git/FETCH_HEAD -mmin -5 2>/dev/null)
      return
    end
    if not ping -c 1 -W 1 1.1.1.1 &>/dev/null
      return
    end
    git fetch --quiet &
  end
end
