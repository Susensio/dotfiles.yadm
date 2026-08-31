set -g fish_prompt_pwd_dir_length 0
set -g fish_prompt_pwd_full_dirs 0

set -g fish_transient_prompt 1

# Faster right prompt with async plugin
set -gx async_prompt_functions fish_git_prompt

# Prettier git prompt
set -g __fish_git_prompt_show_informative_status true
set -g __fish_git_prompt_showcolorhints true
set -g __fish_git_prompt_char_dirtystate (set_color --bold)'*'(printf '\e[22m')
set -g __fish_git_prompt_char_invalidstate (set_color --bold)'#'(printf '\e[22m')
set -g __fish_git_prompt_char_stagedstate (set_color --bold)'+'(printf '\e[22m')
set -g __fish_git_prompt_char_stashstate (set_color --bold)'$'(printf '\e[22m')

function __prompt_last_command_info --on-event fish_postexec
    set -l last_pipestatus $pipestatus
    set -l last_command_info
    set -a last_command_info (__prompt_status $last_pipestatus)
    set -a last_command_info (__prompt_timer)

    if test -n "$last_command_info"
        # Printed from postexec so it lands between Fish's OSC 133 D and the next A,
        # outside the prompt region. tmux acts on only two of the four OSC 133
        # markers, so this placement cannot be handed to tmux instead.
        set -p last_command_info '└───'
        string join --no-empty ' ' $last_command_info
    end
end
