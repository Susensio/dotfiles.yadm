# Add vendor completions folder for user installed programs
set -l vendor_completions $XDG_CONFIG_HOME/fish/completions/vendor

set fish_complete_path $fish_complete_path[1..2] $vendor_completions $fish_complete_path[3..-1]
