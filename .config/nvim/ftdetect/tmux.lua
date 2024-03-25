vim.filetype.add({
  pattern = {
    ["${XDG_CONFIG_HOME}/tmux/[^/]+%.conf"] = 'tmux',
  }
})
