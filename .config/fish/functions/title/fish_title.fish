function fish_title
    # # If we're connected via ssh, we print the hostname.
    set -l ssh
    set -q SSH_TTY
    and set ssh "["(prompt_hostname | string sub -l 10 | string collect)"]"
    # # An override for the current command is passed as the first parameter.
    # # This is used by `fg` to show the true process name, among others.
    if set -q argv[1]
        set -l command (string split ' ' $argv[1])
        set -l icon (__title_icon $command[1])
        echo -- $ssh $icon $argv[1]
    else
        # Don't print "fish" because it's redundant
        set -l command (status current-command)
        set -l icon (__title_icon $command[1])
        if test "$command" = fish
            echo -- $ssh $icon (prompt_pwd)
            return
        end
        echo -- $ssh $icon $command
    end
end
