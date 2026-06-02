function _fish_command_in
    # Checks if the first token matches any of the provided arguments
    contains -- (commandline -opc)[1] $argv
end
