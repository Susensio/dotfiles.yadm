function vim --wraps=nvim --description 'Run neovim if installed' 
  if command -qs nvim
    nvim $argv
  else
    command vim $argv
  end
end
