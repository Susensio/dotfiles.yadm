function rm --wraps=trash --description 'Safer rm alternative with trash' 
	if command -qs trash
		command trash $argv
	else
        echo "WARNING: trash-cli not installed, items will be deleted permantently"
		command rm -i $argv
	end
end
