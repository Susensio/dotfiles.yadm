# Subfolders for user defined functions

set fish_function_path $fish_function_path[1] $fish_function_path[1]/*/ $fish_function_path[2..-1]
