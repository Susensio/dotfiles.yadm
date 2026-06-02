set -g fish_greeting
if status is-interactive
    if test "$TERM" = linux
        command -qs ttyscheme && ttyscheme gruvbox_dark
    else
        fish_config theme choose custom
    end
end
