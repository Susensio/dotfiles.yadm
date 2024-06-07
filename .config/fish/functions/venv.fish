function venv --description 'Creates a new environment and activates it'
  # Check if we are inside a git repository
  if git rev-parse --show-toplevel &>/dev/null
    set dir (realpath (git rev-parse --show-toplevel))
  else
    set dir (pwd)
  end

  set -l venv_dir $dir/.venv

  if test -d $venv_dir
    echo "Environment already exists in $dir/.venv" >&2
  else
    echo "Creating a new environment in $dir/.venv ..." >&2
    python3 -m venv $dir/.venv
  end

  if test "$VIRTUAL_ENV" = $venv_dir
    echo "Environment already activated" >&2
  else
    echo "Activating the environment ..." >&2
    source $dir/.venv/bin/activate.fish
  end
end
