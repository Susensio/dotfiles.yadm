function upgrade --description 'Upgrade system'
  sudo apt update &&
  sudo apt full-upgrade -y &&
  sudo apt autoremove -y &&
  sudo apt autoclean -y
  purge
end
