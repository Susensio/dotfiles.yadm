function __prompt_git
    # Cache fields: repository root, rendered Git segment.
    set -l current_root (command git --no-optional-locks rev-parse --show-toplevel 2>/dev/null)
    set -l state $$__prompt_git_state_var
    set -l state_root "$state[1]"
    set -l state_text "$state[2]"

    if test "$state_root" != "$current_root"
        return
    end

    string trim --left -- "$state_text"
end
