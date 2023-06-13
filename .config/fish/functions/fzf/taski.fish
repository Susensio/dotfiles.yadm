function taski -d "Taskwarrior interactive filter with fzf"
  
  set -l task_cmd task rc.defaultwidth=0 rc.defaultheight=0 rc.verbose=nothing
  set -l selected ($task_cmd ls | head -n -2 | tail -n +4 | fzf --multi --query="$argv" | sed 's/^ //' | cut -d' ' -f1 | tr '\n' ' ')
  commandline -r "task $selected"
end
