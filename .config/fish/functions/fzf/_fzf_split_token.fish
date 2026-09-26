# Prints the deepest existing directory in the token, then the rest of the token.
function _fzf_split_token
    set -l base_directory "$argv[1]"
    if test -z "$base_directory"
        set base_directory .
    end
    while not path is -d $base_directory
        set base_directory (path dirname $base_directory)
    end

    echo $base_directory
    string replace -r "^"(string escape --style=regex -- $base_directory)"/?" "" -- $argv[1]
end
