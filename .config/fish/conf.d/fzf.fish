function _fzf
    command fzf --height=40% --style=minimal --info=hidden --preview-border=rounded $argv
end

function _fzf_anchored_query
    if test -n "$argv[1]"
        echo "^$argv[1] "
    end
end

function _fzf_existing_directory
    set -l directory "$argv[1]"
    if test -z "$directory"
        echo .
        return
    end

    while not path is -d $directory
        set directory (path dirname $directory)
    end

    echo $directory
end

function _set_show_lean
    set -l varname $argv[1]

    set --show $varname |
        string replace --regex '^\$'"$varname" '' |
        string replace ':' '' |
        string replace --regex '\|(.*)\|' '$1' |
        string trim
end

function _fzf_variable_widget
    set -l name_prefix (string sub --start=2 -- $argv[1])
    set -l query (_fzf_anchored_query "$name_prefix")

    set -l preview "fish -c '_set_show_lean {}'"
    set -l result (set --names | _fzf --prompt="VAR> " --query="$query" --preview=$preview)
    set -l fzf_status $status
    if test $fzf_status -eq 0 && test -n "$result"
        commandline -rt -- \$$result
    end
end

function _fzf_path_widget
    set -l path_token (commandline --current-token --tokens-expanded)
    set -l base_directory (_fzf_existing_directory "$path_token")
    set -l relative_query (string replace -r "^"(string escape --style=regex -- $base_directory)"/?" "" -- $path_token)
    set -l query (_fzf_anchored_query "$relative_query")

    set -l entry_type file
    set -l buffer (commandline -b)
    if test -z "$buffer"
        set entry_type directory
    else
        set -l process_tokens (commandline -cxp)
        if test "$process_tokens[1]" = cd
            set entry_type directory
        end
    end
    set -l prompt "FILE> "
    if test "$entry_type" = directory
        set prompt "DIR> "
    end

    set -l fd_args \
        --base-directory=$base_directory \
        --hidden \
        --exclude=.git

    set -l fd_command (string join ' ' -- fd (string escape -- $fd_args))
    set -l preview_command (string join '' 'preview ' (string escape -- $base_directory) '/{}')

    set -l result (
        fd $fd_args --type=$entry_type |
            _fzf \
                --multi \
                --query="$query" \
                --prompt="$prompt" \
                --preview="$preview_command" \
                --bind="ctrl-f:transform:
                    if [[ \$FZF_PROMPT == FILE* ]]; then
                        printf 'change-prompt(DIR> )+reload($fd_command --type=directory)'
                    else
                        printf 'change-prompt(FILE> )+reload($fd_command --type=file)'
                    fi
                "
    )
    set -l fzf_status $status
    if test $fzf_status -eq 0 && test -n "$result"
        set -l selected_path (path normalize -- $base_directory/$result)
        commandline -rt -- (string join ' ' (string escape -- $selected_path))
    end
end

function _fzf_smart_widget
    set -l token (commandline -ct)

    if string match -q '$*' -- $token
        _fzf_variable_widget $token
    else
        _fzf_path_widget
    end

    commandline -f repaint
end
