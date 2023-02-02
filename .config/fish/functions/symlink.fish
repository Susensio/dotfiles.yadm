function symlink --argument _from _to --description 'Create a symbolic link, using absolute paths'
  if test -z "$_from" || test -z "$_to"
    echo "symlink: must provide from and to arguments"
    return 1
  end

  set abs_to (realpath --no-symlinks (string replace '~' "$HOME" $_to))

  if test -d $_to && not test -d $_from
    set to "$abs_to/"(basename $_from)
  else
    set to "$abs_to"
  end

  set from (realpath (string replace '~' "$HOME" $_from))
  
  ln -sf $from $to
end
