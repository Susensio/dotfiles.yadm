# Do not pollute fish config folder, use a subfolder
# https://github.com/jorgebucaran/fisher/issues/677

if set -q XDG_DATA_HOME
    set -gx fisher_path $XDG_DATA_HOME/fish/fisher
else
    set -gx fisher_path $HOME/.local/share/fish/fisher
end

set fish_function_path $fish_function_path[1] $fisher_path/functions $fish_function_path[2..-1]
set fish_complete_path $fish_complete_path[1] $fisher_path/completions $fish_complete_path[2..-1]

# Automatic things only in interactive mode
if status is-interactive
    if not functions -q fisher
        echo "Fisher not found, installing..."
        curl -sL https://git.io/fisher | source && fisher update || fisher install jorgebucaran/fisher
    else if test -f $__fish_config_dir/fish_plugins
        # fish_plugins changed under fisher (a pull): update installs and removes to match
        set -l wanted (string match -rv '^\s*$' <$__fish_config_dir/fish_plugins | sort)
        set -l installed (fisher list | sort)
        test "$wanted" = "$installed"; or fisher update
    end
end

for file in $fisher_path/conf.d/*.fish
    source $file
end
