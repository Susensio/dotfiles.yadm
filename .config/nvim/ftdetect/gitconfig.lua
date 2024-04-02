vim.filetype.add({
  pattern = {
    ["${XDG_CONFIG_HOME}/git/.+"] = "gitconfig",
  }
})
