function fd --wraps=fdfind --description 'alias fd=fdfind'
  if isatty stdin
    command fdfind --color always $argv | less -XRF
  else
    command fdfind $argv
  end
end
