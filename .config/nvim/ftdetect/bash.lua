vim.filetype.add({
  pattern ={
    ['${XDG_CONFIG_HOME}/bash/.+'] = 'bash',
    ['${XDG_CONFIG_HOME}/profile'] = 'bash',
    ['${XDG_CONFIG_HOME}/profile.d/.+'] = 'bash',
  }
})
