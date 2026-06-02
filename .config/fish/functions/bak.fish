# By Moritz Kneilmann | github.com/MoritzKn
function bak --desc "Adds the sufix '.bak' (backup) to files and folders"
    for file in $argv
        set file (string trim --right --chars=/ $file)
        cp --interactive --recursive "$file" "$file.bak"
    end
end
