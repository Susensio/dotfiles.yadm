function tree --wraps=eza --description 'Tree contents in directory'
    if command -qs eza
        eza --tree --icons $argv
    else
        command tree $argv
    end
end
