function sudo -d "Sudo with fish user functions"
  # Avoid recursion
  if fish_is_root_user
    error "Already using root!"
    return 1
  end

  # if no arguments, run sudo with no arguments
  if test -z "$argv"
    command sudo -Es
    return
  end

  # If command, remove and use system bins with default shell
  # `sudo command ls` -> `sudo ls`
  if test "$argv[1]" = "command"
    set argv $argv[2..-1]
    # command sudo $argv[2..-1]

  # Preserve environment for nvim
  else if contains -- "$argv[1]" "vim" "nvim"
    set argv -E -s $argv

  # If fish function, execute with fish
  # https://gist.github.com/NotTheDr01ds/6357e48b511735c42b94c4cc081ac5dc
  else if functions -q -- "$argv[1]"
    set cmdline (
      for arg in $argv
          printf "\"%s\" " $arg
      end
    )
    set -l function_src (string join "\n" (string escape --style=var (functions "$argv[1]")))
    set argv XDG_CONFIG_HOME=$XDG_CONFIG_HOME fish -c "string unescape --style=var (string split '\n' $function_src) | source; "$cmdline
  end

  command sudo $argv
end
