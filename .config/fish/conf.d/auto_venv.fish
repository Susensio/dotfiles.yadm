# Based on https://gist.github.com/tommyip/cf9099fa6053e30247e5d0318de2fb9e

# Changes:
# * Instead of overriding cd, we detect directory change. This allows the script to work
#   for other means of cd, such as z.
# * Update syntax to work with new versions of fish.
# * Handle virtualenvs that are not located in the root of a git directory.
# * Traverse up the directory tree to find the closest virtualenv.

function _auto_source_venv --on-variable PWD --description "Activate/Deactivate virtualenv on directory change"
  status --is-command-substitution; and return
  status --is-interactive; or return

  # Check if we are inside a git repository
  if git rev-parse --show-toplevel &>/dev/null
    set stopdir (realpath (git rev-parse --show-toplevel))
  else
    set stopdir "/"
  end

  set -l VENV_DIR_NAMES env .env venv .venv

  # Find the closest virtualenv starting from the current directory.
  set -l cwd (pwd -P)
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
    if functions -q deactivate
      deactivate
    else
      # This is copy-pasted from the original deactivate function, just in case it's missing.
      if test -n "$_OLD_VIRTUAL_PATH"
        set -gx PATH $_OLD_VIRTUAL_PATH
        set -e _OLD_VIRTUAL_PATH
      end
      if test -n "$_OLD_VIRTUAL_PYTHONHOME"
        set -gx PYTHONHOME $_OLD_VIRTUAL_PYTHONHOME
        set -e _OLD_VIRTUAL_PYTHONHOME
      end

      if test -n "$_OLD_FISH_PROMPT_OVERRIDE"
        set -e _OLD_FISH_PROMPT_OVERRIDE
        if functions -q _old_fish_prompt
          functions -e fish_prompt
          functions -c _old_fish_prompt fish_prompt
          functions -e _old_fish_prompt
        end
      end

      set -e VIRTUAL_ENV
      set -e VIRTUAL_ENV_PROMPT
    end
  end
end

_auto_source_venv
