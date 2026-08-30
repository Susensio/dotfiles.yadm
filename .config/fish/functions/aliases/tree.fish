function tree --wraps=eza --description 'Tree contents in directory'
    if command -qs eza
        # Do not show and empty tree for git-ignored root dir, only hide subdirs
        set -l git_ignore
        if not git check-ignore -- . $argv >/dev/null 2>&1
            set git_ignore --git-ignore
        end

        eza --tree --group-directories-first --icons $git_ignore $argv
    else
        command tree $argv
    end
end
