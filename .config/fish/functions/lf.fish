# Change working dir in fish to last dir in lf on exit (adapted from ranger).
# https://github.com/gokcehan/lf/blob/master/etc/lfcd.fish

function lf
  set tmp (mktemp)
  command lf -last-dir-path=$tmp $argv
  if test -f "$tmp"
    set dir (cat $tmp)
    command rm -f $tmp
    if test -d "$dir"
      if test "$dir" != (pwd)
        cd $dir
      end
    end
  end
end
