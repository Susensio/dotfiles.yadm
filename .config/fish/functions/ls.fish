function ls --wraps=exa --description 'List contents in directory'
  if command -qs exa
    exa --group-directories-first --icons $argv
  else
    source /usr/share/fish/functions/ls.fish
    command ls $argv
  end
end
