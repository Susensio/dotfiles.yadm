# Strips `set --show` output down to the bare values
function _fzf_variable_preview
    set -l varname $argv[1]

    set --show $varname |
        string replace --regex '^\$'"$varname" '' |
        string replace ':' '' |
        string replace --regex '\|(.*)\|' '$1' |
        string trim
end
