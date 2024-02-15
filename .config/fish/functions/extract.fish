# Taken from: https://github.com/dideler/dotfiles/blob/master/functions/extract.fish

function extract --description "Expand or extract bundled & compressed files"
  switch $argv
    case '*.tar'  # non-compressed, just bundled
      tar -xvf $argv
    case '*.tar.gz' '*.tgz'
      tar -zxvf $argv
    case '*.tar.xz'
      tar -xvf $argv
    case '*gz'
      gunzip $argv
    case '*.bz2'  # tar compressed with bzip2
      tar -jxvf $argv
    case '*.rar'
      unrar x $argv
    case '*.zip'
      unzip $argv
    case '*
      echo' "unknown extension"
  end
end
