# Shows ~/.config/yadm/unignore files as untracked

function yadm --description 'YADM with smart unignore'
    if test "$argv[1]" = 'unignore'
        # First, remove previously intent-to-added files
        # or added and deleted
        command yadm diff --name-only --diff-filter=AD -z | 
            # ignore blanks and prepend repo root folder
            awk 'BEGIN {RS="\0";OFS="\n"} NF {print "\":/" $0 "\""}' |
            # remove from index
            xargs -r yadm reset -q --

        # Second, add possible new files
        set -l unignore "$XDG_CONFIG_HOME/yadm/unignore"
        # If such config file exists
        test -r "$unignore" && cat "$unignore" | 
            # environment variable substitution
            envsubst | 
            # expand globs
            xargs -i -- /bin/sh -c 'ls -1 $1 2> /dev/null' _X_ {} |
            # mark files as intent to add
            command yadm add --intent-to-add --pathspec-from-file=-
        
        # Finally, show results
        command yadm status
        return
    end

    command yadm $argv
end
