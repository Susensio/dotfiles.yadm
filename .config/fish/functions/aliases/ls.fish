function ls --wraps=eza --description 'List contents in directory'
  if command -qs eza
    if isatty stdout
      eza --group-directories-first --icons --hyperlink $argv
    else
      eza $argv
    end
  else
    command ls $argv
  end
end
