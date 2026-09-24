function __prompt_git_worker --argument-names state_var
    set -l prompt_root (command git --no-optional-locks rev-parse --show-toplevel 2>/dev/null)
    set -l prompt_text (fish_git_prompt | string collect)
    set -l previous $$state_var
    set -l previous_root "$previous[1]"
    set -l previous_text "$previous[2]"

    if test "$previous_root" = "$prompt_root" -a "$previous_text" = "$prompt_text"
        return
    end

    # Universal scope returns the worker result to the parent shell.
    set --universal $state_var "$prompt_root" "$prompt_text"
end
