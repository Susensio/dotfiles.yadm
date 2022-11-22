function bat --wraps=batcat --description 'Alternative to cat, with default options'
    set -l opt --style=auto
	command batcat $opt $argv
end
