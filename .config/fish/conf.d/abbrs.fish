# ... -> ../../
function _multicd
    echo (string repeat -n (math (string length -- $argv[1]) - 1) ../)
end
abbr --add dotdot --position anywhere --regex '^\.\.+$' --function _multicd

# sudo !!
function _last_history_item
    echo $history[1]
end
abbr --add !! --position anywhere --function _last_history_item

abbr --add h hx
abbr --add l ll
abbr --add g git
abbr --add cb clipboard

abbr --add lg lazygit
abbr --add ly lazyyadm
abbr --add lc lazycidm

abbr --add ld lazydocker

abbr --add y yadm
abbr --add yc --set-cursor 'yadm commit -m "%"'

abbr --add dc docker-compose

abbr --add t todo

# Common mistakes
abbr --add please fix
abbr --add howto howdoi
abbr --add ipy ipython
