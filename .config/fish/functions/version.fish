function version -d "Display linux version and system info"
  if type -q neofetch
    neofetch
  else
    lsb_release -a
  end
end

