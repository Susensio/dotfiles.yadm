function __prompt_is_fresh
    test "$__last_status_generation" != $status_generation
end
