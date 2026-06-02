function ln --wraps=ln --description "Just like ln but with sensible absolute paths"
    argparse --move-unknown -- $argv
    if count $argv >/dev/null
        set argv (realpath --no-symlinks $argv)
    end
    command ln $argv_opts $argv
end
