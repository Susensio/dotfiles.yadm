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

# Prints the deepest existing directory in the token, then the rest of the token.
function _fzf_split_token
    set -l base_directory (_fzf_existing_directory "$argv[1]")
    echo $base_directory
    string replace -r "^"(string escape --style=regex -- $base_directory)"/?" "" -- $argv[1]
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
    set -l result (set --names | _fzf --prompt="VAR> " --query="$query" --preview=$preview --scheme="path")
    set -l fzf_status $status
    if test $fzf_status -eq 0 && test -n "$result"
        commandline -rt -- \$$result
    end
end

function _fzf_path_widget
    set -l token_parts (_fzf_split_token (commandline --current-token --tokens-expanded))
    set -l base_directory $token_parts[1]
    set -l query (_fzf_anchored_query "$token_parts[2]")

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
                --scheme="path" \
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
        set -l selected_paths
        for entry in $result
            set -l selected_path (path normalize -- $base_directory/$entry)
            # path normalize drops the trailing slash fd puts on directories
            if string match -q '*/' -- $entry
                set selected_path $selected_path/
            end
            set -a selected_paths $selected_path
        end
        commandline -rt -- (string join ' ' (string escape -- $selected_paths))
    end
end

# A wildcard token becomes an rg glob; otherwise some/path/foo greps the entries
# matching some/path/foo*, or inside some/path with foo as the query if none do.
function _fzf_grep_widget
    set -l f_grep_args
    set -l query
    # The expanded token would already have the wildcards resolved by fish
    set -l raw_token (string unescape -- (commandline --current-token))
    if string match -q --regex '[*?[]' -- $raw_token
        set -a f_grep_args --glob=$raw_token
    else
        set -l token_parts (_fzf_split_token (commandline --current-token --tokens-expanded))
        set -l prefix_matches
        if test -n "$token_parts[2]"
            set prefix_matches $token_parts[1]/$token_parts[2]*
        end
        if set -q prefix_matches[1]
            set -a f_grep_args --dir=(path normalize -- $prefix_matches)
        else
            if test "$token_parts[1]" != .
                set -a f_grep_args --dir=$token_parts[1]
            end
            set query $token_parts[2]
        end
    end
    if _fish_command_in helix hx
        set -a f_grep_args --accept-nth=1,2
    end

    set -l result (f-grep $f_grep_args $query)
    set -l fzf_status $status
    if test $fzf_status -eq 0 && test -n "$result"
        commandline -rt -- (string escape -- $result)
    end

    commandline -f repaint
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
