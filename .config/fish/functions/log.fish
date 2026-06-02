function _log_debug
    if test -n "$DEBUG"
        echo -s "[" (set_color magenta) DEBUG (set_color normal) "] " $argv >&2
    end
end

function _log_info
    echo -s "[" (set_color blue) INFO (set_color normal) "] " $argv >&2
end

function _log_warn
    echo -s "[" (set_color yellow) WARN (set_color normal) "] " $argv >&2
end

function _log_error
    echo -s "[" (set_color red) ERROR (set_color normal) "] " $argv >&2
end

function _log_success
    echo -s "[" (set_color green) SUCCESS (set_color normal) "] " $argv >&2
end

function log
    set -l level $argv[1]
    set -l text $argv[2..-1]

    switch "$level"
        case debug
            _log_debug $text
        case info
            _log_info $text
        case warn
            _log_warn $text
        case error
            _log_error $text
        case success
            _log_success $text
        case '*'
            _log_error "Unknown log level: '$level'. Message was: $text"
    end
end
