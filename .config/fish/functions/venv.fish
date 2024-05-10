function venv --description 'Creates a new environment and activates it'
  # Check if we are inside a git repository
  if git rev-parse --show-toplevel &>/dev/null
    set dir (realpath (git rev-parse --show-toplevel))
  else
    set dir (pwd)
  end

  echo "Creating a new environment in $dir/.venv ..." >&2
  python -m venv $dir/.venv

  echo "Activating the environment ..." >&2
  source $dir/.venv/bin/activate.fish
end
