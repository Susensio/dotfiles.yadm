function __prompt_job
    if test (jobs | count) -gt 0
        echo -n (set_color --bold cyan)"● "(set_color normal)
    end
end
