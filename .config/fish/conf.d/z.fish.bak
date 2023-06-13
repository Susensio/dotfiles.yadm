set -U Z_CMD "_z"


function z --wraps _z --description 'jump around'
  if test (count $argv) -eq 0
    # Fzf if no args
    # https://github.com/PatrickF1/fzf.fish/discussions/231

    set current_token (commandline --current-token)

    set command_z (
      z -l | sort -rn | cut -c 12- | _fzf_wrapper --query=$current_token $fzf_jump_directory_opts
    )

    if test $status -eq 0
      cd $command_z
    end

    commandline --function repaint

  else
    _z $argv
  end
end
