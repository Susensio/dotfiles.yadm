function upgrade --description 'Upgrade system'
  __info "Upgrading apt..."
  __upgrade_apt
  __purge_apt

  __info "Upgrading fish plugins..."
  fisher update

  __info "Upgrading user installed from github..."
  $HOME/bin/update-repos

  __info "Upgrading nvim plugins..."
  __packersync_nvim

  __info "Upgrading python venv..."
  __upgrade_venv

  __info "Deleting global pip cache..."
  pip cache purge
end

function __upgrade_apt
  sudo apt update &&
  sudo apt full-upgrade -y &&
  sudo apt autoremove -y &&
  sudo apt autoclean -y
end

function __purge_apt --description 'Purge previously only removed packages'
  dpkg -l | grep '^rc' | awk '{print $2}' | sudo xargs --no-run-if-empty dpkg --purge
end

function __packersync_nvim
  command nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'
end

function __upgrade_venv
  set -l pip_venv $XDG_DATA_HOME/venv/bin/pip 
  $pip_venv install --upgrade --requirement "$XDG_CONFIG_HOME/venv/requirements.txt" | sed -n '/^Requirement already satisfied/!p'
  $pip_venv cache purge
end

function __info
  printfn
  printfn (set_color --bold green)$argv | box
end
