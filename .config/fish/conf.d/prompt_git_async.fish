# PID scopes the universal cache to one interactive shell.
set -g __prompt_git_state_var __prompt_git_state_$fish_pid

function __prompt_git_refresh --on-event fish_prompt
    command fish --private --command \
        '__prompt_git_worker $argv[1]' \
        $__prompt_git_state_var &
    # Do not show the just-started refresh job.
    builtin disown
end

function __prompt_git_repaint --on-variable $__prompt_git_state_var
    set -l current_root (command git --no-optional-locks rev-parse --show-toplevel 2>/dev/null)
    set -l state $$__prompt_git_state_var
    set -l state_root "$state[1]"

    if test "$state_root" != "$current_root"
        return
    end

    commandline --function repaint
end

function __prompt_git_cleanup --on-event fish_exit
    set --erase --universal $__prompt_git_state_var
end
