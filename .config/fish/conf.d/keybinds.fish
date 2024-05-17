# CTRL-E open nautilus
bind \ce 'nautilus . &'

# If nothing in the commandline, copy the killring to system clipboard (sync)
bind \cx 'test -z "$(commandline)" && echo -n $fish_killring[1] | fish_clipboard_copy || fish_clipboard_copy'
