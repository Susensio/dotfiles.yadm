function upgrade --description 'Upgrade system'
  __upgrade_apt
  __purge_apt
  fisher update
  __packersync_nvim
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
