set -g fish_greeting
if status is-interactive
    if test "$TERM" = linux
        if command -qs ttyscheme
            ttyscheme gruvbox_dark
        end
    else
        set -l theme_file $__fish_config_dir/themes/custom.theme
        set -l theme_mtime (path mtime $theme_file 2>/dev/null)
        if test -z "$theme_mtime"
            set theme_mtime 0
        end
        if test "$theme_mtime" != "$_custom_theme_mtime"
            fish_config theme choose custom
            set -U _custom_theme_mtime $theme_mtime
        end
    end
end
