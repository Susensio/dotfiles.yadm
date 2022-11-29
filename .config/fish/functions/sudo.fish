# https://gist.github.com/NotTheDr01ds/6357e48b511735c42b94c4cc081ac5dc

function sudo -d "Sudo with fish user functions"
  # Avoid recursion
  if fish_is_root_user
    echo "Already using root!"
    return 1
  end    

  # Substitute double bang !!
  if test "$argv" = !! 
    # NOT WORKING
    # set argv $history[1]
    # echo "$argv"
  end

  # If fish function, execute with fish
  if functions -q "$argv[1]"
    set cmdline (
      for arg in $argv
          printf "\"%s\" " $arg
      end
    )
    set -x function_src (string join "\n" (string escape --style=var (functions "$argv[1]")))
    set argv fish -c 'string unescape --style=var (string split "\n" $function_src) | source; '$cmdline
    command sudo -E $argv

  # If command, remove and use system bins
  # `sudo command ls` -> `sudo ls`
  else if test "$argv[1]" = "command" 
    command sudo $argv[2..-1]

  else
    command sudo $argv
  end
end
