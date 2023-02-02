function ls --wraps=exa --description 'List contents in directory'
  if command -qs exa
    if isatty stdout
      exa --group-directories-first --icons $argv
    else
      exa $argv
    end
  else
    source /usr/share/fish/functions/ls.fish
    command ls $argv
  end
end
