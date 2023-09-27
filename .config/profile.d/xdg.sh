# python
export PYTHONSTARTUP=$XDG_CONFIG_HOME/python/startup.py
export IPYTHONDIR=$XDG_CONFIG_HOME/ipython
export JUPYTER_CONFIG_DIR=$XDG_CONFIG_HOME/jupyter

# nvim
export VIMINIT='let $MYVIMRC = !has("nvim") ? "$XDG_CONFIG_HOME/vim/vimrc" : "$XDG_CONFIG_HOME/nvim/init.lua" | so $MYVIMRC'

# vscode
export VSCODE_EXTENSIONS="$XDG_DATA_HOME/code/extensions"

export GNUPGHOME="$XDG_DATA_HOME"/gnupg

export _JAVA_OPTIONS=-Djava.util.prefs.userRoot="$XDG_CONFIG_HOME"/java

# wget
export WGETRC="$XDG_CONFIG_HOME/wgetrc"

export ICEAUTHORITY="$XDG_CACHE_HOME"/ICEauthority
#export XAUTHORITY="$XDG_RUNTIME_DIR"/Xauthority

export SQLITE_HISTORY=$XDG_DATA_HOME/sqlite_history
export WINEPREFIX="$XDG_DATA_HOME"/wine

# R
export R_LIBS_USER="$XDG_DATA_HOME/r/%p-library/%v"
export R_PROFILE_USER="$XDG_CONFIG_HOME/R/rprofile"
export R_ENVIRON_USER="$XDG_CONFIG_HOME/R/renviron"

export DOTNET_CLI_HOME="$XDG_CONFIG_HOME/dotnet"

# Rust
export CARGO_HOME="$XDG_DATA_HOME"/cargo
if [ -d "$CARGO_HOME" ] ; then
  add_path "$CARGO_HOME/bin"
fi
export RUSTUP_HOME="$XDG_CONFIG_HOME"/rustup
