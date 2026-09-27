# Completion for the `omarchy` dispatcher, ported from Omarchy's
# default/bash/completions. Subcommands are discovered from the omarchy-*
# executables next to `omarchy` in PATH (the dispatcher resolves
# `omarchy theme set` to the executable omarchy-theme-set), argument hints
# from each binary's `# omarchy:args=` line, and descriptions from
# `# omarchy:summary=`. The only hardcoded strings are the `commands`
# keyword, its flags and their descriptions, all taken from the
# dispatcher's own usage text; the group descriptions additionally parse
# the dispatcher's GROUP_DESCRIPTIONS table, falling back to a child
# binary's summary if upstream ever renames it.
#
# fish filters the emitted candidates against the token being typed, so
# only the words before the cursor matter here. File completions are
# disabled for the command and emitted explicitly at dynamic placeholder
# positions, so the pager is never polluted with directory listings
# elsewhere.

# Hyphenated executable route (omarchy-a-b) for the words given; flags are
# not part of a route.
function __omarchy_route
    set -l parts
    for word in $argv[2..-1]
        string match -q -- '-*' $word; or set -a parts $word
    end
    if set -q parts[1]
        echo omarchy-(string join - $parts)
    else
        echo omarchy
    end
end

# A token is a placeholder when wrapped in <> or []; its <a|b|c> choices are
# completed, while a bare <name> like <theme-name> stays dynamic and falls
# back to file completion. Anything else is a literal.
function __omarchy_choices
    set -l value (string match -r -g -- '^[<\[]([^ ]*)[>\]]$' $argv[1])
    if set -q value[1]; and string match -q -- '*|*' $value
        string split '|' -- $value
    end
end

function __omarchy_is_placeholder
    string match -q -r -- '^[<\[][^ ]*[>\]]$' $argv[1]
end

function __omarchy_summary --description "Summary metadata line of an omarchy binary"
    command cat $argv[1] 2>/dev/null | string match -r -g -- '^\s*#\s*omarchy:summary=(.*)$' | head -n1
end

# The dispatcher's own descriptions of the first-level groups, as
# alternating name/description lines.
function __omarchy_group_descriptions
    set -l bin (command -v omarchy; or return)
    command cat $bin 2>/dev/null | string match -r -g -- 'GROUP_DESCRIPTIONS\[([^]]*)\]="([^"]*)"'
end

function __omarchy_complete
    set -l bin (command -v omarchy)
    if not set -q bin[1]
        return
    end
    set -l dir (path dirname (path resolve $bin))
    set -l words (commandline -opc)
    set -l gflat (__omarchy_group_descriptions)
    set -l gnames
    set -l gdescs
    for i in (seq 1 2 (count $gflat))
        set -a gnames $gflat[$i]
        set -a gdescs $gflat[(math $i + 1)]
    end

    if test (count $words) -lt 2
        printf 'commands\t%s\n' 'List all commands'
    else if test "$words[2]" = commands
        printf '%s\t%s\n' --all 'Include commands explicitly marked hidden' \
            --json 'Emit machine-readable JSON' \
            --markdown 'Emit a Markdown command table' \
            --check 'Validate command metadata and route collisions'
    end

    set -l base (__omarchy_route $words)
    set -l seen
    for file in $dir/$base-*
        if not test -f $file; or not test -x $file
            continue
        end
        # The next subcommand is the first segment after the known route.
        set -l next (path basename $file | string replace -- "$base-" '' | string split -- -)[1]
        if contains -- $next $seen
            continue
        end
        set -a seen $next

        # Level-1 groups carry the dispatcher's own descriptions; anything
        # deeper takes the summary of its first matching binary.
        set -l desc
        if test (count $words) -lt 2
            set -l idx (contains --index -- $next $gnames)
            if set -q idx[1]
                set desc $gdescs[$idx]
            end
        end
        if not set -q desc[1]
            set desc (__omarchy_summary $file)
        end
        if set -q desc[1]
            printf '%s\t%s\n' $next $desc
        else
            echo $next
        end
    end
    if set -q seen[1]
        return
    end

    __omarchy_args $dir $words
end

# Complete the arguments of the deepest executable the line resolves to.
# A literal token must match what was typed, a <a|b|c> position must match
# one of its choices, a dynamic <name>/[name] position matches anything.
function __omarchy_args --argument-names dir
    set -l words $argv[2..-1]
    set -l count (count $words)
    # Trim the route until it names an executable, so that arguments of
    # `omarchy audio output volume raise <TAB>` complete omarchy-audio-output-volume.
    for n in (seq $count -1 2)
        set -l route (__omarchy_route $words[1..$n])
        if not test -x $dir/$route
            continue
        end
        set -l spec (command cat $dir/$route | string match -r -g -- '^#\s*omarchy:args=(.*)$' | head -n1)
        if test -z "$spec"
            return
        end

        set -l typed (math $count - $n)
        for alternative in (string split ' | ' -- $spec)
            set -l tokens (string split ' ' -- $alternative)
            set -l match true
            for i in (seq 1 $typed)
                set -l token $tokens[$i]
                set -l actual $words[(math $n + $i)]
                if test -z "$token"
                    set match false
                else
                    set -l choices (__omarchy_choices $token)
                    if set -q choices[1]
                        not contains -- "$actual" $choices; and set match false
                    else if not __omarchy_is_placeholder $token
                        and test "$token" != "$actual"
                        set match false
                    end
                end
                if test "$match" = false
                    break
                end
            end

            if test "$match" = true
                set -l token $tokens[(math $typed + 1)]
                if set -q token[1]
                    set -l choices (__omarchy_choices $token)
                    if set -q choices[1]
                        printf '%s\n' $choices
                    else if __omarchy_is_placeholder $token
                        __fish_complete_path (commandline -ct)
                    else
                        echo $token
                    end
                end
            end
        end
        return
    end
end

complete -c omarchy -f -a '(__omarchy_complete)'
