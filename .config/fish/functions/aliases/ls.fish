function ls --wraps=eza --description 'List contents in directory'
    if not command -qs eza
        command ls $argv
        return
    end

    if isatty stdout
        eza --group-directories-first (test "$TERM" != linux; and echo --icons) --hyperlink=auto $argv
    else
        eza $argv
    end
end
