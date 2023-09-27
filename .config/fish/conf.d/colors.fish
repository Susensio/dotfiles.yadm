# Update variables when file is modified

# set -l modified (stat --format="%Y" (status --current-filename))
#
# if not set -q colorscheme || test $colorscheme != $modified

    set -U fish_color_autosuggestion brblack
    set -U fish_color_cancel normal
    set -U fish_color_command white --bold
    set -U fish_color_comment red
    set -U fish_color_cwd blue --bold
    set -U fish_color_end green
    set -U fish_color_error red
    set -U fish_color_escape 00a6b2 cyan
    set -U fish_color_history_current normal
    set -U fish_color_host white --bold
    set -U fish_color_host_remote yellow --bold
    set -U fish_color_match normal
    set -U fish_color_normal normal
    set -U fish_color_operator cyan
    set -U fish_color_param white
    set -U fish_color_quote yellow
    set -U fish_color_redirection 00afff brcyan
    set -U fish_color_search_match bryellow
    set -U fish_color_selection white
    set -U fish_color_status red
    set -U fish_color_user green --bold
    set -U fish_color_user_root red --bold
    set -U fish_color_valid_path normal
    set -U fish_greeting
    set -U fish_key_bindings fish_default_key_bindings
    set -U fish_pager_color_completion normal
    set -U fish_pager_color_description B3A06D yellow
    set -U fish_pager_color_prefix white --bold --underline
    set -U fish_pager_color_progress brwhite --background=cyan
    set -U fish_pager_color_selected_background -r

    # set -U colorscheme $modified
# end
