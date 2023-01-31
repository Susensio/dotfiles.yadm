function ly --wraps=lazygit --description 'Lazygit for yadm repo'
  command lazygit --use-config-file "$XDG_CONFIG_HOME/yadm/lazygit.yml,$XDG_CONFIG_HOME/lazygit/config.yml" --work-tree ~ --git-dir ~/.local/share/yadm/repo.git
end
