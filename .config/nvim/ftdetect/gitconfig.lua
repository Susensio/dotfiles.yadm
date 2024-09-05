vim.filetype.add({
   pattern = {
      ["${XDG_CONFIG_HOME}/git/.+"] = "gitconfig",
      ["${XDG_CONFIG_HOME}/yadm/gitconfig"] = "gitconfig",
      ["${XDG_CONFIG_HOME}/cidm/gitconfig"] = "gitconfig",
   }
})
