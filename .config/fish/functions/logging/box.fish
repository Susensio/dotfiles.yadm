function box --wraps='boxes -d shell' --description 'alias box=boxes -d shell'
  set --local cmd 'boxes -d shell'
  if isatty stdin
    printfn (string trim -c '\n' "$argv")'\033[00m' | eval $cmd
  else
    read --local --null text
    printfn (string trim -c '\n' "$text")'\033[00m' | eval $cmd
  end
end
