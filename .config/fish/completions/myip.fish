complete -c myip --no-files
# exclusive flags
complete -c myip -s l -l local -n "not __fish_contains_opt p public" -d "Show local IP address"
complete -c myip -s p -l public -n "not __fish_contains_opt l local" -d "Get public IP from DNS"
