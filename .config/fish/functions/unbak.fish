# By Moritz Kneilmann | github.com/MoritzKn
function unbak --desc "Removes the sufix '.bak' (backup) from files"
  for file in $argv
    if not string match -q "*.bak" $file
      echo "$file does not have a '.bak' suffix."
      exit 1
    end

    set original (string replace -r '\.bak$' '' $file)

    if test -e $original
      read -P "mv: overwrite '$original'? " -f response >&2
      not string match -qi 'y*' && exit 0
    end

    rm -fr $original
    mv $file $original
  end
end
