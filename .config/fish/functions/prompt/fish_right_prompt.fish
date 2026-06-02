function fish_right_prompt -d "Write out the right prompt"
    set --local THRESHOLD 1000 # ms
    set -l last_pipestatus $pipestatus

    # Gather components
    set -l components

    # Transient info next to the cursor
    if not __prompt_is_final $argv
        set -a components (__prompt_git)
        set -a components (__prompt_venv)
        set -a components (__prompt_job)
        set -a components (__prompt_subshell)
    end

    # # Sticky last command info
    # if __prompt_is_fresh
    #     set -a components (__prompt_timer)
    #     set -a components (__prompt_status $last_pipestatus)
    # end

    string join --no-empty ' ' $components

    if __prompt_is_final $argv
        set --global __last_status_generation $status_generation
    end
end
