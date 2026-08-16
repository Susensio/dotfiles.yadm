function tree --wraps=eza --description 'Tree contents in directory'
    if command -qs eza
        eza --tree --icons --git-ignore $argv
    else
        command tree $argv
    end
end
