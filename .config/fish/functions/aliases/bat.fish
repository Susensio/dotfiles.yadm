function bat --wraps=batcat --description 'Alternative to cat, with default options'
  set -l opt --style=auto
  if command -qs bat
    command bat $opt $argv
  else
    command batcat $opt $argv
  end
end
