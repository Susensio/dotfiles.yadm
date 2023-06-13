function ipython -d "Launch ipython from venv"
  if test -z "$VIRTUAL_ENV"
    venv & command ipython
    deactivate
  else
    command ipython
  end
end
