function cat --wraps=bat --description 'Run batcat if installed'
    # Avoid bat overhead when piped or captured in scripts
    if not isatty stdout
        command cat $argv
        return
    end

    if command -qs bat
        command bat -P -p $argv
    else if command -qs batcat
        command batcat -P -p $argv
    else
        command cat $argv
    end
end
