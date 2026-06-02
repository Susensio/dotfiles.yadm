function __prompt_status -a last_pipestatus
    __fish_print_pipestatus "[" "]" "|" (set_color $fish_color_status) (set_color --bold $fish_color_status) $last_pipestatus
end
