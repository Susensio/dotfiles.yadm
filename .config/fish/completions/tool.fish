function __fish_tool_list_installed
    tool list --installed --no-header 2>/dev/null | string split --max 1 --fields 1 ' '
end

function __fish_tool_list_all
    tool list | string replace -r '\s*https?://.*$' '' | string replace -r '^(\S+)\s+(.*)$' '$1\t$2'
end

# Disable default file completions
complete -c tool -f

complete -c tool -s h -l help -d 'Show help'

# Install: Suggest all tools from the registry
complete -c tool -n __fish_use_subcommand -a install -d 'Install one or more global tools'
complete -c tool -n "__fish_seen_subcommand_from install" -a "(__fish_tool_list_all)"

# Remove: Only suggest tools that are actually installed
complete -c tool -n __fish_use_subcommand -a remove -d 'Remove one or more global tools'
complete -c tool -n "__fish_seen_subcommand_from remove" -a "(__fish_tool_list_installed)"

# Upgrade: Suggest installed tools (or none for "all")
complete -c tool -n __fish_use_subcommand -a upgrade -d 'Upgrade all or specific global tools'
complete -c tool -n "__fish_seen_subcommand_from upgrade" -a "(__fish_tool_list_installed)"

# List: Handle the --installed flag
complete -c tool -n __fish_use_subcommand -a list -d 'Search for tools, or list installed tools'
complete -c tool -n "__fish_seen_subcommand_from list" -l installed -d 'List only installed global tools'

# Show: Suggest all tools
complete -c tool -n __fish_use_subcommand -a show -d 'Show details about a specific tool'
complete -c tool -n "__fish_seen_subcommand_from show" -a "(__fish_tool_list_all)"
