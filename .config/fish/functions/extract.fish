# Taken from: https://github.com/dideler/dotfiles/blob/master/functions/extract.fish

function extract --description "Expand or extract bundled & compressed files"
  switch $argv
    case '*.tar'  # non-compressed, just bundled
      tar -xvf $argv --one-top-level
    case '*.tar.gz' '*.tgz'
      tar -zxvf $argv --one-top-level
    case '*.tar.xz'
      tar -xvf $argv --one-top-level
    case '*gz'
      gunzip $argv
    case '*.bz2'  # tar compressed with bzip2
      tar -jxvf $argv --one-top-level
    case '*.rar'
      unrar x $argv
    case '*.zip'
      unzip $argv
    case '*
      echo' "unknown extension"
  end
end
