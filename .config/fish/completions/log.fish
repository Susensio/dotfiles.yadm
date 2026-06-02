set -l levels debug info warn error success
complete -c log -f
complete -c log -n "not __fish_seen_subcommand_from $levels" -a "$levels"
