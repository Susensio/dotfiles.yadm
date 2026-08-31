function fish_right_prompt -d "Write out the right prompt"
    # Gather components
    set -l components

    # Transient info next to the cursor
    if not __prompt_is_final $argv
        set -a components (__prompt_git)
        set -a components (__prompt_venv)
        set -a components (__prompt_job)
        set -a components (__prompt_subshell)
    end

    string join --no-empty ' ' $components
end
