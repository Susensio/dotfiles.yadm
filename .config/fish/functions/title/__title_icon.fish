function __title_icon
    cat $XDG_CONFIG_HOME/icons.csv | while read --local --delimiter ',' name icon
        if test "$argv" = $name
            echo $icon
            break
        end
    end
end
