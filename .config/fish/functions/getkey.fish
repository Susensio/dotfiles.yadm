function getkey --desc 'Tries to solve the NO_PUBKEY apt problem'
	if test (count $argv) -eq 0
		echo "No arguments supplied"
	else
		sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $argv
	end
end

