function cat --wraps=batcat --description 'Run batcat if installed'
  if command -qs bat
    command bat -P -p $argv
  else if command -qs batcat
    command batcat -P -p argv
  else
    command cat $argv
  end
end
