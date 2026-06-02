function __prompt_subshell
    set -l max_shlvl 1
    if test -n "$TMUX" || test -n "$ZELLIJ" || test "$TERM_PROGRAM" = vscode
        set max_shlvl (math $max_shlvl + 1)
    end
    if test $SHLVL -gt $max_shlvl
        echo -n (set_color --bold yellow)"⑂"(set_color normal)
    end
end
