function help -d 'Colorize --help with bat'
  eval $argv --help | command batcat --plain --language=help
end
