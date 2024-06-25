# CTRL-E open nautilus
bind \ee 'nautilus . &'

# If nothing in the commandline, copy the killring to system clipboard (sync)
bind \cx 'test -z "$(commandline)" && echo -n $fish_killring[1] | fish_clipboard_copy || fish_clipboard_copy'

# Accept suggestions like nvim copilot
bind \ce forward-word
# NOT WORKING, waiting for issue https://github.com/fish-shell/fish-shell/issues/10580
bind \cl 'if test "$(commandline --current-buffer)" = "$(commandline --cut-at-cursor)";
    tput reset; clear; commandline -f repaint;
else;
    commandline -f forward-char;
end'
bind \cl 'commandline --current-buffer'
bind \cj forward-char
