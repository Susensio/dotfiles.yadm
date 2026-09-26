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
