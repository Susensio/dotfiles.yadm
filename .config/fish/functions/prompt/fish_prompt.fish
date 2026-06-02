function fish_prompt --description 'Write out the prompt'
    set -l last_pipestatus $pipestatus
    set -lx __fish_last_status $status
    set -l normal (set_color --reset)

    # Color the prompt differently when we're root
    set -l suffix '>'
    if fish_is_root_user
        if set -q fish_color_user_root
            set -lx fish_color_user $fish_color_user_root
        end
        if set -q fish_color_cwd_root
            set -lx fish_color_cwd $fish_color_cwd_root
        end
        set suffix '#'
    end

    # Last command info is printed ABOVE the prompt
    set -l last_command_info
    if __prompt_is_fresh
        set -a last_command_info (__prompt_status $last_pipestatus)
        set -a last_command_info (__prompt_timer)
    end
    if test -n "$last_command_info"
        set -p last_command_info "└───"
        string join --no-empty ' ' $last_command_info
    end

    # Actual prompt
    echo -n (prompt_login)
    echo -n ' '
    echo -n (set_color $fish_color_cwd)(prompt_pwd)$normal

    echo -n $suffix
    echo -n " "
end
