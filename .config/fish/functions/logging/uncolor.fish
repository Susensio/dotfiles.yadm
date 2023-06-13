function uncolor --description 'Remove color from string'
  set -f text "$argv"
  # If from pipe, get text
  if not isatty stdin
    read -z text
  end
  echo -n "$text" | sed -r 's/\x1B\[[0-9;]*[JKmsu]//g'
end
