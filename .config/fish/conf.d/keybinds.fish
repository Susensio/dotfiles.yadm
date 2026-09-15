bind ctrl-z 'fg; commandline --function repaint'
bind alt-c 'fish_commandline_append " &| clipboard"'

bind ctrl-f _fzf_smart_widget
bind ctrl-g 'commandline -i (f-grep (if _fish_command_in "hx"; echo "--accept-nth=1,2"; end))'
