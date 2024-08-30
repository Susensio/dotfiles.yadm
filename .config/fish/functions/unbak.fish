# By Moritz Kneilmann | github.com/MoritzKn
function unbak --desc "Removes the sufix '.bak' (backup) from files"
  for file in $argv
    if not string match -q "*.bak" $file
      echo "$file does not have a '.bak' suffix."
      return 1
    end

    set original (string replace -r '\.bak$' '' $file)
    mv -i $file $original
  end
end
