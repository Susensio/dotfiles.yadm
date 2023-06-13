function version -d "Display linux version and system info"
  if command -q neowofetch
    neowofetch
  else if command -q neofetch
    neofetch
  else
    lsb_release -a
  end
end

