function taski -d "Taskwarrior interactive filter with fzf"
  set -l selected (task ls | head -n -2 | tail -n +4 | fzf --multi | sed 's/^ //' | cut -d' ' -f1 | tr '\n' ' ')
  commandline -r "task $selected"
end
