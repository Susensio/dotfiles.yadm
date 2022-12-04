function fd --wraps=fdfind --description 'alias fd=fdfind'
  if isatty stdout
    command fdfind --color always $argv | less
  else
    command fdfind $argv
  end
end
