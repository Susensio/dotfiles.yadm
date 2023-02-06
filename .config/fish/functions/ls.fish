function ls --wraps=exa --description 'List contents in directory'
  if command -qs exa
    if isatty stdout
      exa --group-directories-first --icons $argv
    else
      exa $argv
    end
  else
    command ls $argv
  end
end
