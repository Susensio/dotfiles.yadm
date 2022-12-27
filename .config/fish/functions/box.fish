function box --wraps='boxes -d shell' --description 'alias box=boxes -d shell'
  set --local cmd 'boxes -d shell '
  if isatty stdin
    printfn "$argv"'\033[00m' | eval $cmd
  else
    read -l text
    printfn "$text"'\033[00m' | eval $cmd
  end
end
