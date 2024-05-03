function cat --wraps=batcat --description 'Run batcat if installed'
  if command -qs bat
    command bat --paging=never --plain $argv
  else if command -qs batcat
    command batcat --paging=never --plain $argv
  else
    command cat $argv
  end
end
