# Everything else is in ./conf.d

# Safer root usage, just like /root/.bashrc
if fish_is_root_user
    alias rm="command rm -i"
    alias cp="command cp -i"
    alias mv="command mv -i"
end
