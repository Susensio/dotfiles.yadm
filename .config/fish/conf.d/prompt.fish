set -g fish_prompt_pwd_dir_length 0
set -g fish_prompt_pwd_full_dirs 0

set -g fish_transient_prompt 1

# Faster right prompt with async plugin
set -gx async_prompt_functions fish_git_prompt

# Prettier git prompt
set -g __fish_git_prompt_show_informative_status true
set -g __fish_git_prompt_showcolorhints true
set -g __fish_git_prompt_char_dirtystate (set_color --bold)'*'(printf '\e[22m')
set -g __fish_git_prompt_char_invalidstate (set_color --bold)'#'(printf '\e[22m')
set -g __fish_git_prompt_char_stagedstate (set_color --bold)'+'(printf '\e[22m')
set -g __fish_git_prompt_char_stashstate (set_color --bold)'$'(printf '\e[22m')
