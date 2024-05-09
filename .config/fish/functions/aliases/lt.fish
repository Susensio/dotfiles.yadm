function lt --wraps ll --description "List contents of directory using tree format"
    ll --tree --git --ignore-glob=".git|.venv" --git-ignore $argv
end
