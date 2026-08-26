# Override /usr/share/fish/vendor_conf.d/flatpak.fish to avoid slow subshell on startup
if type -q flatpak
    set -l installations $HOME/.local/share/flatpak /var/lib/flatpak
    for dir in {$installations[-1..1]}/exports/share
        if test -d $dir; and not contains $dir $XDG_DATA_DIRS
            set -p XDG_DATA_DIRS $dir
        end
    end
end
