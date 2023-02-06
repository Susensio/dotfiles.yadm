function lt --wraps ll --description "List contents of directory using tree format"
    ll --tree --git --ignore-glob=".git" $argv
end
