function tree --wraps=eza --description 'Tree contents in directory'
    if not command -qs eza
        command tree $argv
        return
    end

    set -l roots (path filter -- $argv)

    if test -z "$roots"
        set roots .
    end

    set -l options \
        --tree \
        --group-directories-first \
        --icons=auto

    # Avoid an empty tree when the requested root itself is git-ignored.
    if not git check-ignore -q -- $roots 2>/dev/null
        set -a options --git-ignore
    end

    command eza $options $argv
end
