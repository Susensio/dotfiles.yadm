bind ctrl-z 'fg; commandline --function repaint'
bind alt-c 'fish_commandline_append " &| clipboard"'

bind ctrl-f _fzf_smart_widget
bind ctrl-g _fzf_grep_widget
