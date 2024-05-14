# Based on https://gist.github.com/tommyip/cf9099fa6053e30247e5d0318de2fb9e

# Changes:
# * Instead of overriding cd, we detect directory change. This allows the script to work
#   for other means of cd, such as z.
# * Update syntax to work with new versions of fish.
# * Handle virtualenvs that are not located in the root of a git directory.
# * Traverse up the directory tree to find the closest virtualenv.

function __auto_source_venv --on-variable PWD --description "Activate/Deactivate virtualenv on directory change"
  status --is-command-substitution; and return

  # Check if we are inside a git repository
  if git rev-parse --show-toplevel &>/dev/null
    set stopdir (realpath (git rev-parse --show-toplevel))
  else
    set stopdir "/"
  end

  set VENV_DIR_NAMES env .env venv .venv

  # Find the closest virtualenv starting from the current directory.
  set cwd (pwd -P)
  while true

    # Find a virtual environment in the directory
    for venv_dir in $cwd/$VENV_DIR_NAMES
      if test -e "$venv_dir/bin/activate.fish"
        if test "$VIRTUAL_ENV" != "$venv_dir"
          source "$venv_dir/bin/activate.fish" &>/dev/null
        end
        return
      end
    end

    if test "$cwd" = "$stopdir"
      break
    end

    set cwd (path dirname "$cwd")
  end

  # No virtualenv found

  # If virtualenv activated but not found nearby, deactivate.
  if test -n "$VIRTUAL_ENV"
    deactivate
  end
end

__auto_source_venv
