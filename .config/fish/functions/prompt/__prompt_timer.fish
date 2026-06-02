function __prompt_timer
    set --local THRESHOLD 1000
    if test $CMD_DURATION -gt $THRESHOLD && test $status_generation -gt 0
        set -l num_color (set_color --bold brwhite)
        set -l unit_color (set_color brwhite)
        set -l brackets_color (set_color white)
        set -l normal (set_color --reset)

        set -l SEC 1000
        set -l MIN 60000
        set -l HOUR 3600000

        set -l hours (math --scale=0 "$CMD_DURATION / $HOUR")
        set -l mins (math --scale=0 "$CMD_DURATION % $HOUR / $MIN")

        set -l millis 0
        if test $hours -eq 0; and test $mins -eq 0
            set millis 1
        end
        set -l secs (math --scale="$millis" "$CMD_DURATION % $MIN / $SEC")

        set -l out
        if test $hours -gt 0
            set --append out {$num_color}{$hours}{$normal}{$unit_color}"h"{$normal}
        end
        if test $mins -gt 0
            set --append out {$num_color}{$mins}{$normal}{$unit_color}"m"{$normal}
        end
        set --append out {$num_color}{$secs}{$normal}{$unit_color}"s"{$normal}

        echo -n {$brackets_color}'('(string join '' $out){$brackets_color}')'{$normal}
    end
end
