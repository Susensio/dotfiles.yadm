set -gx fish_prompt_pwd_dir_length 0
set -gx fish_prompt_pwd_full_dirs 0

# Faster right prompt with async plugin
set -gx async_prompt_functions fish_git_prompt

# Prettier git prompt
set -gx __fish_git_prompt_show_informative_status true
set -gx __fish_git_prompt_showcolorhints true
