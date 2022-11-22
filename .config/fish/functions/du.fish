function du --wraps=duf --description 'Run gdu if installed' 
	if command -qs gdu
		gdu $argv
	else
		command du $argv
	end
end
