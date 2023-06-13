function ly --wraps=lazygit --description 'Lazygit for yadm repo'
  # Call yadm status to ensure hook execution
  yadm status > /dev/null
  command lazygit --use-config-file "$XDG_CONFIG_HOME/yadm/lazygit.yml,$XDG_CONFIG_HOME/lazygit/config.yml" --work-tree ~ --git-dir ~/.local/share/yadm/repo.git
end
