function sufi -d "Login as root using fish shell with user config"
  if fish_is_root_user
    echo "Already using root!"
    return 1
  end    
  # Maybe this XDG_CONFIG_HOME has some caveats... idk
  #command sudo -i (which sh) -c "XDG_CONFIG_HOME=$HOME/.config $(which fish)"
  command sudo -sE
end
