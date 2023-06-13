function upgrade --description 'Upgrade system'
  _info "Upgrading apt..."
  _upgrade_apt
  _purge_apt

  _info "Upgrading fish plugins..."
  fisher update

  _info "Upgrading user installed from github..."
  $HOME/bin/update-repos

  _info "Upgrading nvim plugins..."
#  _packersync_nvim

  _info "Upgrading python venv..."
  _upgrade_venv

  _info "Deleting global pip cache..."
  pip cache purge
end

function _upgrade_apt
  sudo apt update &&
  sudo apt full-upgrade -y &&
  sudo apt autoremove -y &&
  sudo apt autoclean -y
end

function _purge_apt --description 'Purge previously only removed packages'
  dpkg -l | grep '^rc' | awk '{print $2}' | sudo xargs --no-run-if-empty dpkg --purge
end

function _packersync_nvim
  command nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'
end

function _upgrade_venv
  set -l pip_venv $XDG_DATA_HOME/venv/bin/pip
  $pip_venv install --upgrade --requirement "$XDG_CONFIG_HOME/venv/requirements.txt" | sed -n '/^Requirement already satisfied/!p'
  $pip_venv cache purge
end

function _info
  printfn
  printfn (set_color --bold green)$argv | box
end
