# Subfolders for user defined functions and completions

set fish_function_path $fish_function_path[1] (path resolve $__fish_config_dir/functions/*/) $fish_function_path[2..-1]
set fish_complete_path $fish_complete_path[1] (path resolve $__fish_config_dir/completions/*/) $fish_complete_path[2..-1]
