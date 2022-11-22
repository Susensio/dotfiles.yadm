function sudo --wraps sudo -d "Sudo with user environment"
	if test (count $argv) -eq 0
		sufi
	else
		if test $argv[1] = !!
			set argv $history[1]
		end
		command sudo -sE $argv
    end
end
