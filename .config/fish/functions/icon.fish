function icon -d "Pick an icon for omarchy-tui-install / omarchy-webapp-install and print its argument"
    # Prints a bare theme name for installed icons, or a CDN URL for catalogue ones.
    # The listings are cached; the TTL is in days, `icon --refresh` forces a fetch.
    set -l cache (set -q XDG_CACHE_HOME; and echo $XDG_CACHE_HOME; or echo $HOME/.cache)/icon-picker
    set -l ttl_days 7

    mkdir -p $cache/img

    # Called back by fzf with the highlighted ref; fzf runs previews through `bash -c`.
    if test "$argv[1]" = --preview
        set -l ref $argv[2]
        set -l file
        if string match -q 'http*' -- $ref
            set file $cache/img/(string replace -ra '[^A-Za-z0-9._-]' _ -- $ref)
            if not test -s $file
                curl -fsSL --max-time 10 -o $file $ref 2>/dev/null
            end
            # A missing path still answers 200 with a text body, so check the bytes.
            if not string match -q 'image/*' (file -b --mime-type $file 2>/dev/null)
                rm -f $file
                echo "not an image: $ref"
                return
            end
        else
            # Prefer the vector copy, else the largest raster; find's order is not size order.
            set file (find /usr/share/icons $HOME/.local/share/icons -name $ref.svg -o -name $ref.png 2>/dev/null \
                | string match -r '.*\.svg$' | head -1)
            test -n "$file"; or set file (find /usr/share/icons $HOME/.local/share/icons -name $ref.png 2>/dev/null \
                | sort -t/ -k5 -V | tail -1)
        end

        # No header: text above a sixel makes fzf swap it for a wireframe when it overflows.
        preview $file
        return
    end

    set -l catalogues \
        selfhst selfhst/icons \
        dashboard-icons homarr-labs/dashboard-icons

    for i in (seq 1 2 (count $catalogues))
        set -l tag $catalogues[$i]
        set -l repo $catalogues[(math $i + 1)]
        set -l list $cache/$tag.tsv
        if test "$argv[1]" = --refresh; or not test -s $list; or test -z (find $list -mmin -(math $ttl_days \* 1440) 2>/dev/null)
            # The git tree API lists every file; jsDelivr's flat listing refuses repos over 50 MB.
            if curl -fsS --max-time 30 https://api.github.com/repos/$repo/git/trees/HEAD\?recursive=1 \
                    | jq -r --arg tag $tag --arg repo $repo \
                        '.tree[] | select(.type == "blob") | .path
                         | select(test("^(png|svg)/[^/]+[.](png|svg)$"))
                         | "\($tag)/\(.)\thttps://cdn.jsdelivr.net/gh/\($repo)/\(.)"' >$list.tmp
                mv $list.tmp $list
            else
                rm -f $list.tmp
                echo "icon: could not list $repo, skipping" >&2
            end
        end
    end

    set -l choice (begin
            # Installed names come first, so they win the eye as the cheapest option.
            find /usr/share/icons $HOME/.local/share/icons \( -name '*.png' -o -name '*.svg' \) 2>/dev/null \
                | string replace -r '.*/' '' | string replace -r '\.(png|svg)$' '' \
                | string match -rv -- '-symbolic$' | sort -u \
                | awk '{ printf "installed/%s\t%s\n", $0, $0 }'
            find $cache -maxdepth 1 -name '*.tsv' -exec cat {} +
        end | _fzf --delimiter \t --with-nth 1 --prompt 'icon> ' \
            --preview "fish -c 'icon --preview \$argv' {2}" --preview-window right,50%)
    or return

    string split -f 2 \t -- $choice
end
