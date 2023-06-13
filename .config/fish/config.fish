# Everything else is in ./conf.d
# `conf.d/*` is sourced first, `config.fish` later
# so `config.fish` has the last word.

# Safer root usage, just like /root/.bashrc
if fish_is_root_user
    alias rm="command rm -i"
    alias cp="command cp -i"
    alias mv="command mv -i"
end
