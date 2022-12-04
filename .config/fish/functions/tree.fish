function tree --wraps=tree --description 'Tree contents in directory'
  if command -qs exa
    exa --tree --icons --color always $argv
  else
    command tree $argv
  end
end
