function __prompt_subshell
    if not set -q __prompt_subshell_parent
        set -l ppid (ps -o ppid= -p $fish_pid | string trim)
        set -g __prompt_subshell_parent (ps -o comm= -p $ppid | string trim)
    end
    if contains -- $__prompt_subshell_parent fish bash zsh sh
        echo -n (set_color --bold yellow)"⑂"(set_color normal)
    end
end
