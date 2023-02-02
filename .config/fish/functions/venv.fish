function venv --description 'Activates local python venv'
  if test -d ".venv"
    echo "Activating local venv..."
    source .local/share/venv/bin/activate.fish
  else
    echo "Activating global venv..."
    source $XDG_DATA_HOME/venv/bin/activate.fish
  end
end

