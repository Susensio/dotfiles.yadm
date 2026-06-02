# Make bash follow the XDG_CONFIG_HOME specification
_confdir=${XDG_CONFIG_HOME:-$HOME/.config}/bash
_datadir=${XDG_DATA_HOME:-$HOME/.local/share}/bash

# Source settings file
if [ -d "$_confdir" ]; then
    for f in bash_profile bashrc; do
        [ -f "$_confdir/$f" ] && . "$_confdir/$f"
    done
fi

# Change the location of the history file by setting the environment variable
[ ! -d "$_datadir" ] && mkdir -p "$_datadir"
HISTFILE=$_datadir/history

unset _confdir
unset _datadir
