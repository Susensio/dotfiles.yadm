function fish_prompt --description 'Write out the prompt'
  set -l last_pipestatus $pipestatus
  set -l normal (set_color normal)

  # Color the prompt differently when we're root
  set -l color_user $fish_color_user
  set -l color_cwd $fish_color_cwd
  set -l prefix
  set -l suffix '$'
  if fish_is_root_user
    if set -q fish_color_user_root
      set color_user $fish_color_user_root
    end
    if set -q fish_color_cwd_root
      set color_cwd $fish_color_cwd_root
    end
    set suffix '#'
  end

  # set -l pwd (prompt_pwd)
  # If directory is not writable, strikethrough suffix
  # if not test -w $PWD
  #   set suffix (set_color -i)"$suffix"(set_color normal)
  # end

  # If we're running via SSH, change the host color.
  set -l color_host $fish_color_host
  if set -q SSH_TTY
    set color_host $fish_color_host_remote
  end

  # Write pipestatus
  set -l prompt_status (__fish_print_pipestatus " [" "]" "|" (set_color $fish_color_status) (set_color --bold $fish_color_status) $last_pipestatus)

  echo -n -s (set_color $color_user) "$USER" $normal @ (set_color $color_host) (prompt_hostname) $normal ':' (set_color $color_cwd) (prompt_pwd) $normal $prompt_status (echo -n -s -e $suffix) " "
end
