function venv --description 'Activates local python venv'
  set -l venv_path

  for dir in .venv venv
    if test -d $dir
      echo "Local $dir/ found. Activating..."
      set venv_path $dir
      break
    end
  end

  if not set -q venv_path
    echo "Using global venv. Activating..."
    set venv_path $XDG_DATA_HOME/venv
  end

  source $venv_path/bin/activate.fish

  if set -q argv[1]
    python $argv
    deactivate
  end
end
