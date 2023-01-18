function fallback --description 'Allow fallback values for variable'
  # Usage: (fallback $EMTPY $MAYBE ... "default")
  for val in $argv
    if test -n "$val"
      echo "$val"
      break
    end
  end
end
