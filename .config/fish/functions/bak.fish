# By Moritz Kneilmann | github.com/MoritzKn
function bak --desc "Adds the sufix '.bak' (backup) to files and folders"
    for arg in $argv
		# remove trailing slash if folder
		set file (string replace -r '(.)/$' '$1' -- $arg)
        cp -r $file $file.bak
    end
end
