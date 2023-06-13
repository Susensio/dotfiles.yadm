function venv --description 'Activates local python venv'
  if test -d ".venv"
    echo "Activating local venv..."
    set venv_path .venv/bin/activate.fish
  else
    echo "Activating global venv..."
    set venv_path $XDG_DATA_HOME/venv/bin/activate.fish
  end

  source $venv_path

  if set -q argv[1]
    python $argv
    deactivate
  end
end
