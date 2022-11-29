function df --wraps=duf --description 'Run duf if installed' 
  if command -qs duf
    duf $argv
  else
    command df $argv
  end
end
