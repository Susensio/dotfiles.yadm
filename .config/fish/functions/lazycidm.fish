function lazycidm --wraps=lazygit --description 'Lazygit for cidm repo'
  # Call cidm status to ensure hook execution
  cidm status > /dev/null
  command lazygit --work-tree ~ --git-dir ~/.local/share/cidm/repo.git
end
