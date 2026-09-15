function fd --wraps=fd --description 'Find files without ancestor ignore rules'
    command fd --no-ignore-parent $argv
end
