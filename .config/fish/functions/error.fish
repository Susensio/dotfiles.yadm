function error --description 'Echo to stderr'
  if isatty stdout
    set argv (set_color brred)"$argv"(set_color normal)
  end
  printfn $argv >&2
  return 1
end
