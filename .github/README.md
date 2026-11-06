# Dotfiles

Personal [yadm](https://yadm.io/) dotfiles, rooted at `$HOME`.

## New machine

One command installs git and yadm, clones this repository and runs `yadm bootstrap`:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Susensio/dotfiles.yadm/master/bin/new-machine)
```

A standard Debian ships wget but not curl; use `wget -qO-` there.
A minimal image with neither needs one first: `sudo apt-get install -y curl`.

On Omarchy the clone stops at the files it already finds. Review them, then rerun with `--checkout`
to take the tracked versions:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Susensio/dotfiles.yadm/master/bin/new-machine) --checkout
```
