function lazycidm --wraps=lazygit --description 'Lazygit for cidm repo'
  # Call cidm status to ensure hook execution
  cidm status > /dev/null
  command lazygit --use-config-file "$XDG_CONFIG_HOME/cidm/lazygit.yml,$XDG_CONFIG_HOME/lazygit/config.yml" --work-tree ~ --git-dir ~/.local/share/cidm/repo.git
end
